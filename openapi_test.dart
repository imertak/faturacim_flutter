import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  await testApiWithOpenApiSpec();
}

Future<void> testApiWithOpenApiSpec() async {
  print('=== OpenAPI Spesifikasyonuna Göre API Testi ===');
  
  final String baseUrl = 'http://127.0.0.1:5202';
  
  // Test 0: Temel bağlantı
  print('\n🔗 0. Temel bağlantı testi...');
  await testBasicConnectivity(baseUrl);
  
  // Test 1: Auth/register endpoint
  print('\n👤 1. Auth/register endpoint testi...');
  await testRegisterEndpoint(baseUrl);
  
  // Test 2: Auth/login endpoint
  print('\n🔑 2. Auth/login endpoint testi...');
  await testLoginEndpoint(baseUrl);
  
  // Test 3: Invoice endpoints
  print('\n📄 3. Invoice endpoint testleri...');
  await testInvoiceEndpoints(baseUrl);
  
  // Test 4: Validation testleri
  print('\n✅ 4. Validation testleri...');
  await testValidationRules(baseUrl);
}

Future<void> testBasicConnectivity(String baseUrl) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api'),
      headers: {'accept': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    print('✅ Bağlantı başarılı - Status: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    if (response.body.isNotEmpty) {
      print('Response Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Bağlantı hatası: $e');
    if (e.toString().contains('TimeoutException')) {
      print('   → Sunucu yanıt vermiyor - API muhtemelen kapalı');
    }
  }
}

Future<void> testRegisterEndpoint(String baseUrl) async {
  // OpenAPI'ye göre RegisterDto gereksinimleri:
  // - fullName: string (1-100 karakter)
  // - email: string (email formatı)
  // - password: string (minimum 6 karakter)
  
  final validRegisterData = {
    'fullName': 'Test Kullanıcı',
    'email': 'test@example.com', 
    'password': 'test123456'
  };
  
  print('Valid register data: $validRegisterData');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(validRegisterData),
    ).timeout(Duration(seconds: 15));
    
    print('✅ Register endpoint erişilebilir - Status: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      print('✨ Register başarılı!');
    } else if (response.statusCode == 400) {
      print('⚠️ Validation hatası veya kullanıcı zaten mevcut');
    } else if (response.statusCode == 409) {
      print('⚠️ Kullanıcı zaten kayıtlı');
    }
    
  } catch (e) {
    print('❌ Register endpoint hatası: $e');
  }
}

Future<void> testLoginEndpoint(String baseUrl) async {
  // OpenAPI'ye göre LoginDto gereksinimleri:
  // - email: string (email formatı)
  // - password: string
  
  final validLoginData = {
    'email': 'test@example.com',
    'password': 'test123456'
  };
  
  print('Valid login data: $validLoginData');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(validLoginData),
    ).timeout(Duration(seconds: 15));
    
    print('✅ Login endpoint erişilebilir - Status: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      print('✨ Login başarılı!');
      try {
        final responseData = jsonDecode(response.body);
        print('Response Data: $responseData');
        if (responseData.containsKey('token')) {
          print('🎟️ Token alındı: ${responseData['token']}');
        }
      } catch (e) {
        print('⚠️ Response parse edilemedi: $e');
      }
    } else if (response.statusCode == 401) {
      print('⚠️ Unauthorized - Geçersiz credentials');
    } else if (response.statusCode == 400) {
      print('⚠️ Bad Request - Validation hatası');
    }
    
  } catch (e) {
    print('❌ Login endpoint hatası: $e');
  }
}

Future<void> testInvoiceEndpoints(String baseUrl) async {
  // Test 1: GET /api/Invoice/user/{email}
  print('\n📋 Invoice/user endpoint testi...');
  final testEmail = 'test@example.com';
  final encodedEmail = Uri.encodeComponent(testEmail);
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Invoice/user/$encodedEmail?startDate=2024-01-01&endDate=2024-12-31'),
      headers: {'accept': 'application/json'},
    ).timeout(Duration(seconds: 15));
    
    print('✅ Invoice/user endpoint - Status: ${response.statusCode}');
    print('Response: ${response.body}');
    
  } catch (e) {
    print('❌ Invoice/user endpoint hatası: $e');
  }
  
  // Test 2: GET /api/Invoice/{id}
  print('\n📄 Invoice by ID endpoint testi...');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Invoice/1'),
      headers: {'accept': 'application/json'},
    ).timeout(Duration(seconds: 15));
    
    print('✅ Invoice by ID endpoint - Status: ${response.statusCode}');
    print('Response: ${response.body}');
    
  } catch (e) {
    print('❌ Invoice by ID endpoint hatası: $e');
  }
  
  // Test 3: POST /api/Invoice
  print('\n📝 Invoice POST endpoint testi...');
  final invoiceData = {
    'title': 'Test Faturası',
    'amount': 150.75,
    'issueDate': DateTime.now().toIso8601String(),
    'dueDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
    'category': 'Test Kategori',
    'payingStatus': 'Pending',
    'userId': 1
  };
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Invoice'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(invoiceData),
    ).timeout(Duration(seconds: 15));
    
    print('✅ Invoice POST endpoint - Status: ${response.statusCode}');
    print('Response: ${response.body}');
    
  } catch (e) {
    print('❌ Invoice POST endpoint hatası: $e');
  }
}

Future<void> testValidationRules(String baseUrl) async {
  print('\n🔍 Validation kuralları testi...');
  
  // Test 1: Geçersiz email formatı
  print('\n• Geçersiz email formatı testi...');
  try {
    final invalidEmailData = {
      'email': 'invalid-email',
      'password': 'test123'
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(invalidEmailData),
    ).timeout(Duration(seconds: 10));
    
    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');
    
    if (response.statusCode == 400) {
      print('✅ Email validation çalışıyor');
    }
    
  } catch (e) {
    print('❌ Email validation test hatası: $e');
  }
  
  // Test 2: Eksik required field
  print('\n• Eksik required field testi...');
  try {
    final incompleteData = {
      'email': 'test@example.com'
      // password eksik
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(incompleteData),
    ).timeout(Duration(seconds: 10));
    
    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');
    
    if (response.statusCode == 400) {
      print('✅ Required field validation çalışıyor');
    }
    
  } catch (e) {
    print('❌ Required field test hatası: $e');
  }
  
  // Test 3: Çok kısa password (register için)
  print('\n• Kısa password testi...');
  try {
    final shortPasswordData = {
      'fullName': 'Test User',
      'email': 'test2@example.com',
      'password': '123' // 6 karakterden az
    };
    
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(shortPasswordData),
    ).timeout(Duration(seconds: 10));
    
    print('Status: ${response.statusCode}');
    print('Response: ${response.body}');
    
    if (response.statusCode == 400) {
      print('✅ Password length validation çalışıyor');
    }
    
  } catch (e) {
    print('❌ Password validation test hatası: $e');
  }
}
