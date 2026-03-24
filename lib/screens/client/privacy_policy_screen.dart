// lib/screens/client/privacy_policy_screen.dart

import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Politique de confidentialité'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo ou icône
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.privacy_tip,
                  size: 40,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Titre principal
            const Text(
              'Politique de confidentialité',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Intro
            const Text(
              'Chez Senpay, nous nous engageons à protéger la confidentialité et la sécurité des informations personnelles de nos utilisateurs. Cette politique de confidentialité décrit la manière dont nous collectons, utilisons et protégeons les informations que vous nous fournissez lorsque vous utilisez nos services.',
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: Color(0xFF4B5563),
              ),
            ),

            const SizedBox(height: 32),

            // Section 1
            _buildSection(
              '1. Informations que nous collectons',
              '''Informations personnelles : Nous pouvons collecter des informations personnelles telles que votre nom, votre adresse e-mail et votre numéro de téléphone lorsque vous créez un compte, effectuez un achat ou rechargez.

Informations d'utilisation : Nous collectons des informations sur la façon dont vous interagissez avec notre application de paiement et de fidélité.''',
            ),

            // Section 2
            _buildSection(
              '2. Comment nous utilisons vos informations',
              '''Pour fournir des services : nous utilisons les informations collectées pour fournir les produits et services que vous avez demandés, y compris le traitement des transactions, la fourniture d'un support client et la gestion de votre compte.

Pour améliorer nos services : nous pouvons utiliser les informations pour analyser les tendances, surveiller les habitudes d'utilisation et améliorer la fonctionnalité et les performances de notre application et de nos services.

Pour communiquer avec vous : nous pouvons vous envoyer des mises à jour importantes, des notifications et du matériel promotionnel lié à nos produits et services. Vous pouvez choisir de ne plus recevoir de communications marketing à tout moment.''',
            ),

            // Section 3
            _buildSection(
              '3. Partage d\'informations',
              'Senpay ne partage pas vos informations avec des prestataires de services tiers.',
            ),

            // Section 4
            _buildSection(
              '4. Sécurité des données',
              'Nous mettons en œuvre des mesures de sécurité standard du secteur pour protéger vos informations personnelles contre tout accès, divulgation, altération ou destruction non autorisés.',
            ),

            // Section 5
            _buildSection(
              '5. Vos choix',
              'Vous avez le droit d\'accéder à vos informations personnelles, de les mettre à jour ou de les supprimer. Vous pouvez gérer les paramètres et préférences de votre compte en contactant notre équipe d\'assistance.',
            ),

            // Section 6
            _buildSection(
              '6. Confidentialité des enfants',
              'Notre application et nos services ne sont pas destinés à être utilisés par des personnes de moins de 18 ans. Nous ne collectons pas sciemment d\'informations personnelles auprès d\'enfants de moins de 18 ans sans le consentement des parents.',
            ),

            // Section 7
            _buildSection(
              '7. Modifications de la présente politique de confidentialité',
              'Nous nous réservons le droit de mettre à jour ou de modifier la présente politique de confidentialité à tout moment. Nous vous informerons de tout changement en publiant la politique révisée sur notre site Web.',
            ),

            // Section 8
            _buildSection(
              '8. Contactez-nous',
              'Si vous avez des questions ou des préoccupations concernant notre politique de confidentialité.\n\nVeuillez nous contacter: contact@senpay.io',
              isLast: true,
            ),

            const SizedBox(height: 32),

            // Bouton Contact
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Ouvrir email ou support
                },
                icon: const Icon(Icons.email),
                label: const Text('Nous contacter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isLast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Color(0xFF4B5563),
          ),
        ),
        if (!isLast) const SizedBox(height: 24),
      ],
    );
  }
}
