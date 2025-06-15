// lib/globals.dart

// API Configuration
class ApiConfig {
  static const String baseUrl = 'http://192.168.0.32:5202';
  static const String apiVersion = '/api';

  // Endpoints
  static const String authRegister = '$apiVersion/Auth/register';
  static const String authLogin = '$apiVersion/Auth/login';
  static const String invoiceUser = '$apiVersion/Invoice/user';
  static const String invoice = '$apiVersion/Invoice';
  static const String userInfo = '$apiVersion/Auth/user-info';
  static const String updateProfile = '$apiVersion/Auth/update-profile';
}

// Global variables
String? userEmail;
String? authToken;
String? theme = 'light'; // Default theme
