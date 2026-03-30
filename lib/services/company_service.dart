import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/company_model.dart';

class CompanyService {
  static const String _baseUrl = 'https://api.cardoil.io';


  Future<CompanyModel?> getCompany(String companyId, {String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/companies/$companyId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return CompanyModel.fromJson(data);
      }
    } catch (e) {
      print('CompanyService.getCompany error: $e');
    }
    return null;
  }


  Future<List<CompanyModel>> getAllCompanies({String? token}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/companies'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final list = body is List ? body : (body['content'] ?? body['data'] ?? []);
        return (list as List)
            .map((e) => CompanyModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('CompanyService.getAllCompanies error: $e');
    }
    return [];
  }


  Future<Map<String, dynamic>> createCompany({
    required String token,
    required Map<String, dynamic> companyData,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/companies'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(companyData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Erreur (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }


  Future<Map<String, dynamic>> updateCompany({
    required String token,
    required String companyId,
    required Map<String, dynamic> companyData,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/companies/$companyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(companyData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Erreur (${response.statusCode})'};
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }


  Future<bool> deleteCompany({
    required String token,
    required String companyId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/companies/$companyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('CompanyService.deleteCompany error: $e');
      return false;
    }
  }

 
  Stream<CompanyModel?> getCompanyStream(String companyId,
      {String? token}) async* {
    yield await getCompany(companyId, token: token);
  }
}