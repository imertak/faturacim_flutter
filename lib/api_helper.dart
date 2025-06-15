// lib/api_helper.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'globals.dart';

class ApiHelper {
  static Future<bool> testApiConnection() async {
    try {
      print('Testing API connection to: ${ApiConfig.baseUrl}');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}'),
        headers: {'accept': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      print('API Test - Status Code: ${response.statusCode}');
      print('API Test - Response: ${response.body}');
      
      return response.statusCode == 200 || response.statusCode == 404; // 404 da API'nin çalıştığını gösterir
    } catch (e) {
      print('API Test Failed: $e');
      return false;
    }
  }
  
  static Future<bool> testNetworkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Internet connection: OK');
        return true;
      }
    } catch (e) {
      print('No internet connection: $e');
    }
    return false;
  }
  
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final Uri url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authLogin}');
      
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final Map<String, String> body = {'email': email, 'password': password};

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      ).timeout(Duration(seconds: 30));

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'error': error.toString(),
      };
    }
  }
}
