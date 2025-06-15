import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('=== OpenAPI Spesifikasyonuna Göre API Uyumluluk Testi ===\n');
  
  final String baseUrl = 'http://127.0.0.1:5202';
  
  // Test 1: Temel bağlantı kontrolü
  print('🔗 1. TEMEL BAĞLANTI KONTROLÜ');
  print('─' * 50);
  await testBasicConnection(baseUrl);
  
  // Test 2: Auth endpoints OpenAPI uyumluluğu
  print('\n👤 2. AUTH ENDPOINTS UYUMLULUK TESTİ');
  print('─' * 50);
  await testAuthEndpoints(baseUrl);
  
  // Test 3: Invoice endpoints OpenAPI uyumluluğu  
  print('\n📄 3. INVOICE ENDPOINTS UYUMLULUK TESTİ');
  print('─' * 50);
  await testInvoiceEndpoints(baseUrl);
  
  // Test 4: Validation kuralları
  print('\n✅ 4. VALIDATION KURALLARI TESTİ');
  print('─' * 50);
  await testValidationRules(baseUrl);
  
  print('\n🏁 TEST TAMAMLANDI');
}

Future<void> testBasicConnection(String baseUrl) async {
  try {
    print('Sunucu bağlantısı test ediliyor: $baseUrl');
    
    final response = await http.get(
      Uri.parse('$baseUrl/api'),
      headers: {'accept': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    print('✅ Sunucu erişilebilir - HTTP ${response.statusCode}');
    print('Content-Type: ${response.headers['content-type'] ?? 'Belirtilmemiş'}');
    
  } catch (e) {
    print('❌ Sunucu erişilemiyor: ${e.runtimeType}');
    if (e.toString().contains('TimeoutException')) {
      print('   → Zaman aşımı: Sunucu muhtemelen kapalı veya port engellenmiş');
    } else if (e.toString().contains('SocketException')) {
      print('   → Ağ hatası: IP adresi veya port erişilemez');
    }
    print('   → Bu durumda gerçek API testleri yapılamaz');
    return;
  }
}

Future<void> testAuthEndpoints(String baseUrl) async {
  // Register endpoint testi - OpenAPI spec uyumluluğu
  print('\n📝 Register Endpoint (/api/Auth/register):');
  
  // OpenAPI'de belirtilen RegisterDto yapısı:
  // - fullName: string (1-100 karakter, required)
  // - email: string (email format, required) 
  // - password: string (min 6 karakter, required)
  
  final registerData = {
    'fullName': 'Test Kullanıcısı',
    'email': 'test.user@example.com',
    'password': 'testpassword123'
  };
  
  print('   Test verisi: $registerData');
  print('   ✓ fullName: string, 1-100 karakter ✓');
  print('   ✓ email: geçerli email formatı ✓'); 
  print('   ✓ password: 6+ karakter ✓');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(registerData),
    ).timeout(Duration(seconds: 15));
    
    print('   → HTTP Status: ${response.statusCode}');
    print('   → Response: ${response.body}');
    
    // OpenAPI'ye göre 200 OK bekleniyor
    if (response.statusCode == 200) {
      print('   ✅ OpenAPI spec uyumlu - 200 OK');
    } else if (response.statusCode == 400) {
      print('   ⚠️ Validation hatası veya kullanıcı mevcut');
    } else {
      print('   ❌ Beklenmeyen status code');
    }
    
  } catch (e) {
    print('   ❌ Register endpoint erişilemiyor: ${e.runtimeType}');
  }
  
  // Login endpoint testi
  print('\n🔑 Login Endpoint (/api/Auth/login):');
  
  // OpenAPI'de belirtilen LoginDto yapısı:
  // - email: string (email format, required)
  // - password: string (required)
  
  final loginData = {
    'email': 'test.user@example.com',
    'password': 'testpassword123'
  };
  
  print('   Test verisi: $loginData');
  print('   ✓ email: geçerli email formatı ✓');
  print('   ✓ password: string ✓');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(loginData),
    ).timeout(Duration(seconds: 15));
    
    print('   → HTTP Status: ${response.statusCode}');
    print('   → Response: ${response.body}');
    
    if (response.statusCode == 200) {
      print('   ✅ OpenAPI spec uyumlu - 200 OK');
      
      // Token kontrolü (genellikle login response'unda bulunur)
      try {
        final responseData = jsonDecode(response.body);
        if (responseData is Map && responseData.containsKey('token')) {
          print('   ✅ Token başarıyla alındı');
        }
      } catch (e) {
        print('   ⚠️ Response JSON parse edilemedi');
      }
    } else if (response.statusCode == 401) {
      print('   ⚠️ Unauthorized - Kullanıcı bulunamadı veya yanlış şifre');
    } else {
      print('   ❌ Beklenmeyen status code');
    }
    
  } catch (e) {
    print('   ❌ Login endpoint erişilemiyor: ${e.runtimeType}');
  }
}

Future<void> testInvoiceEndpoints(String baseUrl) async {
  // GET /api/Invoice/user/{email} testi
  print('\n📋 User Invoices Endpoint (/api/Invoice/user/{email}):');
  
  final testEmail = 'test.user@example.com';
  final encodedEmail = Uri.encodeComponent(testEmail);
  final url = '$baseUrl/api/Invoice/user/$encodedEmail?startDate=2024-01-01T00:00:00Z&endDate=2024-12-31T23:59:59Z';
  
  print('   Test URL: $url');
  print('   ✓ email parameter: path\'de encode edildi ✓');
  print('   ✓ startDate: ISO 8601 format ✓');
  print('   ✓ endDate: ISO 8601 format ✓');
  
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {'accept': 'application/json'},
    ).timeout(Duration(seconds: 15));
    
    print('   → HTTP Status: ${response.statusCode}');
    print('   → Response: ${response.body}');
    
    if (response.statusCode == 200) {
      print('   ✅ OpenAPI spec uyumlu - 200 OK');
    }
    
  } catch (e) {
    print('   ❌ User invoices endpoint erişilemiyor: ${e.runtimeType}');
  }
  
  // GET /api/Invoice/{id} testi
  print('\n📄 Invoice by ID Endpoint (/api/Invoice/{id}):');
  
  final testId = 1;
  final idUrl = '$baseUrl/api/Invoice/$testId';
  
  print('   Test URL: $idUrl');
  print('   ✓ id parameter: integer format ✓');
  
  try {
    final response = await http.get(
      Uri.parse(idUrl),
      headers: {'accept': 'application/json'},
    ).timeout(Duration(seconds: 15));
    
    print('   → HTTP Status: ${response.statusCode}');
    print('   → Response: ${response.body}');
    
    if (response.statusCode == 200) {
      print('   ✅ OpenAPI spec uyumlu - 200 OK');
    } else if (response.statusCode == 404) {
      print('   ⚠️ Invoice bulunamadı - Normal durum');
    }
    
  } catch (e) {
    print('   ❌ Invoice by ID endpoint erişilemiyor: ${e.runtimeType}');
  }
  
  // POST /api/Invoice testi
  print('\n📝 Create Invoice Endpoint (/api/Invoice):');
  
  // OpenAPI'de belirtilen Invoice yapısı:
  // Required: amount, title, userId
  // Optional: issueDate, dueDate, category, imagePath, payingStatus
  
  final invoiceData = {
    'title': 'Test Faturası - OpenAPI Uyumluluk',
    'amount': 125.50,
    'userId': 1,
    'issueDate': DateTime.now().toIso8601String(),
    'dueDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
    'category': 'Test Kategori',
    'payingStatus': 'Pending'
  };
  
  print('   Test verisi: $invoiceData');
  print('   ✓ title: string (1-150 karakter) ✓');
  print('   ✓ amount: double/number ✓');
  print('   ✓ userId: integer ✓');
  print('   ✓ issueDate: ISO 8601 datetime ✓');
  print('   ✓ dueDate: ISO 8601 datetime (nullable) ✓');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Invoice'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(invoiceData),
    ).timeout(Duration(seconds: 15));
    
    print('   → HTTP Status: ${response.statusCode}');
    print('   → Response: ${response.body}');
    
    if (response.statusCode == 200) {
      print('   ✅ OpenAPI spec uyumlu - 200 OK');
    } else if (response.statusCode == 201) {
      print('   ✅ Resource created - 201 Created');
    } else if (response.statusCode == 400) {
      print('   ⚠️ Validation hatası');
    }
    
  } catch (e) {
    print('   ❌ Create invoice endpoint erişilemiyor: ${e.runtimeType}');
  }
}

Future<void> testValidationRules(String baseUrl) async {
  // Email format validation
  print('\n📧 Email Format Validation:');
  
  final invalidEmailData = {
    'email': 'invalid-email-format',
    'password': 'testpassword'
  };
  
  print('   Geçersiz email: ${invalidEmailData['email']}');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(invalidEmailData),
    ).timeout(Duration(seconds: 10));
    
    print('   → HTTP Status: ${response.statusCode}');
    
    if (response.statusCode == 400) {
      print('   ✅ Email validation çalışıyor - 400 Bad Request');
    } else {
      print('   ❌ Email validation çalışmıyor');
    }
    
  } catch (e) {
    print('   ❌ Email validation test edilemedi: ${e.runtimeType}');
  }
  
  // Password length validation (Register)
  print('\n🔒 Password Length Validation:');
  
  final shortPasswordData = {
    'fullName': 'Test User',
    'email': 'test.short@example.com',
    'password': '123' // 6 karakterden az
  };
  
  print('   Kısa şifre: "${shortPasswordData['password']}" (${shortPasswordData['password']!.length} karakter)');
  print('   OpenAPI spec: minimum 6 karakter gerekli');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(shortPasswordData),
    ).timeout(Duration(seconds: 10));
    
    print('   → HTTP Status: ${response.statusCode}');
    
    if (response.statusCode == 400) {
      print('   ✅ Password length validation çalışıyor - 400 Bad Request');
    } else {
      print('   ❌ Password length validation çalışmıyor');
    }
    
  } catch (e) {
    print('   ❌ Password validation test edilemedi: ${e.runtimeType}');
  }
  
  // Required field validation
  print('\n📋 Required Field Validation:');
  
  final incompleteData = {
    'email': 'test.incomplete@example.com'
    // password field eksik
  };
  
  print('   Eksik field: password');
  
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(incompleteData),
    ).timeout(Duration(seconds: 10));
    
    print('   → HTTP Status: ${response.statusCode}');
    
    if (response.statusCode == 400) {
      print('   ✅ Required field validation çalışıyor - 400 Bad Request');
    } else {
      print('   ❌ Required field validation çalışmıyor');
    }
    
  } catch (e) {
    print('   ❌ Required field validation test edilemedi: ${e.runtimeType}');
  }
}
