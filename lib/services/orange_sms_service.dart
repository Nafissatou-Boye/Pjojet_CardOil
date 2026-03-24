// lib/services/orange_sms_service.dart
//
// ✅ Service OTP complet avec Orange SMS Pro
// Architecture :
//   1. Génère un code OTP à 6 chiffres localement
//   2. Envoie via API Orange SMS Pro (HTTP direct depuis Flutter)
//   3. Stocke le code + expiration dans Firestore pour vérification
//   4. Vérifie le code saisi par l'utilisateur
//
// ⚠️  IMPORTANT SÉCURITÉ :
//   - Ne mettez PAS votre API key en dur dans le code en production
//   - Utilisez flutter_dotenv ou Firebase Remote Config pour la stocker
//   - Ce fichier montre la structure — remplacez les valeurs par les vôtres

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class OrangeSmsService {
  static final OrangeSmsService _instance = OrangeSmsService._internal();
  factory OrangeSmsService() => _instance;
  OrangeSmsService._internal();

  // ── Remplacez par vos vraies credentials Orange SMS Pro ──────────────
  static const String _clientId = 'VOTRE_CLIENT_ID';
  static const String _clientSecret = 'VOTRE_CLIENT_SECRET';
  static const String _senderName = 'GPay';    // Nom affiché sur le SMS
  static const String _senderNumber = '+221XXXXXXXXX'; // Votre numéro Orange

  // URLs API Orange
  static const String _tokenUrl =
      'https://api.orange.com/oauth/v3/token';
  static const String _smsUrl =
      'https://api.orange.com/smsmessaging/v1/outbound/tel%3A%2B221XXXXXXXXX/requests';

  // ── Obtenir un token OAuth2 ───────────────────────────────────────────
  Future<String?> _getAccessToken() async {
    try {
      final credentials =
          base64Encode(utf8.encode('$_clientId:$_clientSecret'));

      final response = await http.post(
        Uri.parse(_tokenUrl),
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: 'grant_type=client_credentials',
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['access_token'] as String?;
      }
      print('❌ Token error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('❌ Token exception: $e');
      return null;
    }
  }

  // ── Générer un code OTP à 6 chiffres ─────────────────────────────────
  String _generateOtp() {
    final rng = Random.secure();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }

  // ── Envoyer OTP par SMS ───────────────────────────────────────────────
  Future<OtpResult> sendOtp({required String phoneNumber}) async {
    try {
      // 1. Normaliser le numéro (ex: 0771234567 → +2210771234567)
      final normalizedPhone = _normalizePhone(phoneNumber);
      if (normalizedPhone == null) {
        return OtpResult.error('Numéro de téléphone invalide');
      }

      // 2. Générer le code OTP
      final otp = _generateOtp();
      final expiresAt =
          DateTime.now().add(const Duration(minutes: 10));

      // 3. Sauvegarder dans Firestore AVANT d'envoyer
      await FirebaseFirestore.instance
          .collection('otp_codes')
          .doc(normalizedPhone)
          .set({
        'code': otp,
        'phone': normalizedPhone,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
        'verified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Obtenir le token Orange
      final token = await _getAccessToken();
      if (token == null) {
        return OtpResult.error(
            'Impossible de contacter Orange SMS Pro. Vérifiez vos credentials.');
      }

      // 5. Envoyer le SMS
      final message =
          'Votre code GPay : $otp\nValable 10 minutes. Ne le partagez pas.';

      final smsResponse = await http.post(
        Uri.parse(_smsUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'outboundSMSMessageRequest': {
            'address': 'tel:$normalizedPhone',
            'senderAddress': 'tel:$_senderNumber',
            'senderName': _senderName,
            'outboundSMSTextMessage': {'message': message},
          }
        }),
      ).timeout(const Duration(seconds: 15));

      if (smsResponse.statusCode == 201 ||
          smsResponse.statusCode == 200) {
        print('✅ SMS OTP envoyé à $normalizedPhone');
        return OtpResult.success(normalizedPhone);
      } else {
        print(
            '❌ SMS error: ${smsResponse.statusCode} - ${smsResponse.body}');
        // ✅ Supprimer le code Firestore si l'envoi échoue
        await FirebaseFirestore.instance
            .collection('otp_codes')
            .doc(normalizedPhone)
            .delete();
        return OtpResult.error(
            'Échec d\'envoi SMS (${smsResponse.statusCode})');
      }
    } catch (e) {
      return OtpResult.error('Erreur réseau: $e');
    }
  }

  // ── Vérifier le code OTP saisi ────────────────────────────────────────
  Future<OtpVerifyResult> verifyOtp({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final normalizedPhone = _normalizePhone(phoneNumber) ?? phoneNumber;

      final doc = await FirebaseFirestore.instance
          .collection('otp_codes')
          .doc(normalizedPhone)
          .get();

      if (!doc.exists) {
        return OtpVerifyResult.error('Code introuvable. Demandez un nouveau code.');
      }

      final data = doc.data()!;

      // Vérifier expiration
      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        await doc.reference.delete();
        return OtpVerifyResult.error('Code expiré. Demandez un nouveau code.');
      }

      // Vérifier tentatives (max 5)
      final attempts = (data['attempts'] ?? 0) as int;
      if (attempts >= 5) {
        await doc.reference.delete();
        return OtpVerifyResult.error(
            'Trop de tentatives. Demandez un nouveau code.');
      }

      // Vérifier le code
      if (data['code'] != code.trim()) {
        // Incrémenter les tentatives
        await doc.reference.update({
          'attempts': FieldValue.increment(1),
        });
        final remaining = 4 - attempts;
        return OtpVerifyResult.error(
            'Code incorrect. $remaining tentative${remaining > 1 ? 's' : ''} restante${remaining > 1 ? 's' : ''}.');
      }

      // ✅ Code correct → marquer comme vérifié
      await doc.reference.update({'verified': true});

      return OtpVerifyResult.success(normalizedPhone);
    } catch (e) {
      return OtpVerifyResult.error('Erreur de vérification: $e');
    }
  }

  // ── Normaliser numéro sénégalais ──────────────────────────────────────
  String? _normalizePhone(String phone) {
    // Supprimer espaces, tirets, parenthèses
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Déjà au format international
    if (cleaned.startsWith('+221') && cleaned.length == 12) {
      return cleaned;
    }
    // Format 00221...
    if (cleaned.startsWith('00221') && cleaned.length == 13) {
      return '+${cleaned.substring(2)}';
    }
    // Format local 7X XXX XX XX (Sénégal)
    if (cleaned.length == 9 &&
        (cleaned.startsWith('7') || cleaned.startsWith('3'))) {
      return '+221$cleaned';
    }
    // Format local 07X XXX XX XX
    if (cleaned.length == 10 && cleaned.startsWith('0')) {
      return '+221${cleaned.substring(1)}';
    }

    return null; // Invalide
  }
}

// ── Résultats typés ──────────────────────────────────────────────────────

class OtpResult {
  final bool success;
  final String? phoneNormalized;
  final String? errorMessage;

  OtpResult._({required this.success, this.phoneNormalized, this.errorMessage});

  factory OtpResult.success(String phone) =>
      OtpResult._(success: true, phoneNormalized: phone);

  factory OtpResult.error(String message) =>
      OtpResult._(success: false, errorMessage: message);
}

class OtpVerifyResult {
  final bool success;
  final String? phoneNormalized;
  final String? errorMessage;

  OtpVerifyResult._(
      {required this.success, this.phoneNormalized, this.errorMessage});

  factory OtpVerifyResult.success(String phone) =>
      OtpVerifyResult._(success: true, phoneNormalized: phone);

  factory OtpVerifyResult.error(String message) =>
      OtpVerifyResult._(success: false, errorMessage: message);
}