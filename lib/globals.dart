// lib/globals.dart

// API Configuration
class ApiConfig {
  static const String baseUrl = 'http://127.0.0.1:5202';
  static const String apiVersion = '/api';
  
  // Endpoints
  static const String authRegister = '$apiVersion/Auth/register';
  static const String authLogin = '$apiVersion/Auth/login';
  static const String invoiceUser = '$apiVersion/Invoice/user';
  static const String invoice = '$apiVersion/Invoice';
}

// Global variables
String? userEmail;
String? authToken;
