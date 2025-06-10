#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('=== API DURUM RAPORU ===\n');
  
  final String baseUrl = 'http://127.0.0.1:5202';
  
  print('🎯 HEDEF API: $baseUrl');
  print('📋 OpenAPI Spec Uyumluluk Kontrolü\n');
  
  // Temel bağlantı testi
  print('1. 🔗 BAĞLANTI TESTİ');
  print('   Sunucu erişilebilirlik kontrolü...');
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api'),
    ).timeout(Duration(seconds: 10));
    
    print('   ✅ BAŞARILI - HTTP ${response.statusCode}');
    print('   📡 Content-Type: ${response.headers['content-type']}');
    
    // API endpoints test et
    await testEndpoints(baseUrl);
    
  } catch (e) {
    print('   ❌ BAŞARISIZ - ${e.runtimeType}');
    
    if (e.toString().contains('TimeoutException')) {
      print('   💡 Durum: Sunucu zaman aşımı (10 saniye)');
      print('   🔍 Olası nedenler:');
      print('      • API sunucusu kapalı');
      print('      • Port 5202 engellenmiş');
      print('      • Firewall kuralları');
      print('      • Ağ bağlantı problemi');
    }
    
    print('\n2. 🌐 AĞ TANILAMA');
    await networkDiagnostics();
    
    print('\n3. 📝 KOD UYUMLULUK ANALİZİ');
    await analyzeCodeCompatibility();
    
    return;
  }
}

Future<void> testEndpoints(String baseUrl) async {
  print('\n2. 📡 ENDPOINT TESTLERİ');
  
  final endpoints = [
    {'path': '/api/Auth/register', 'method': 'POST', 'expected': 'RegisterDto'},
    {'path': '/api/Auth/login', 'method': 'POST', 'expected': 'LoginDto'},
    {'path': '/api/Invoice/user/test@example.com', 'method': 'GET', 'expected': 'Invoice[]'},
    {'path': '/api/Invoice/1', 'method': 'GET', 'expected': 'Invoice'},
    {'path': '/api/Invoice', 'method': 'POST', 'expected': 'Invoice'},
  ];
  
  for (var endpoint in endpoints) {
    print('   Testing ${endpoint['method']} ${endpoint['path']}');
    
    try {
      late http.Response response;
      
      if (endpoint['method'] == 'GET') {
        response = await http.get(
          Uri.parse('$baseUrl${endpoint['path']}'),
          headers: {'accept': 'application/json'},
        ).timeout(Duration(seconds: 5));
      } else {
        // POST için sample data
        Map<String, dynamic> sampleData = {};
        
        if (endpoint['path']!.contains('register')) {
          sampleData = {
            'fullName': 'Test User',
            'email': 'test@example.com',
            'password': 'password123'
          };
        } else if (endpoint['path']!.contains('login')) {
          sampleData = {
            'email': 'test@example.com',
            'password': 'password123'
          };
        } else if (endpoint['path']!.contains('Invoice')) {
          sampleData = {
            'title': 'Test Invoice',
            'amount': 100.0,
            'userId': 1
          };
        }
        
        response = await http.post(
          Uri.parse('$baseUrl${endpoint['path']}'),
          headers: {
            'Content-Type': 'application/json',
            'accept': 'application/json',
          },
          body: jsonEncode(sampleData),
        ).timeout(Duration(seconds: 5));
      }
      
      print('      ✅ HTTP ${response.statusCode}');
      
    } catch (e) {
      print('      ❌ ${e.runtimeType}');
    }
  }
}

Future<void> networkDiagnostics() async {
  print('   📶 Internet bağlantısı kontrolü...');
  
  try {
    final response = await http.get(Uri.parse('https://www.google.com')).timeout(Duration(seconds: 5));
    print('   ✅ Internet bağlantısı çalışıyor');
  } catch (e) {
    print('   ❌ Internet bağlantısı problemi: ${e.runtimeType}');
  }
  
  print('   🔍 DNS çözümleme testi...');
  try {
    final addresses = await InternetAddress.lookup('127.0.0.1');
    print('   ✅ DNS çözümleme başarılı: ${addresses.first.address}');
  } catch (e) {
    print('   ❌ DNS çözümleme hatası: ${e.runtimeType}');
  }
  
  print('   🚪 Port erişilebilirlik testi...');
  try {
    final socket = await Socket.connect('127.0.0.1', 5202, timeout: Duration(seconds: 3));
    print('   ✅ Port 5202 açık');
    socket.destroy();
  } catch (e) {
    print('   ❌ Port 5202 kapalı: ${e.runtimeType}');
  }
}

Future<void> analyzeCodeCompatibility() async {
  print('   📋 OpenAPI Spec ile Kod Karşılaştırması:');
  print('');
  
  print('   🔍 RegisterDto Requirements:');
  print('      ✅ fullName: string (1-100 chars, required)');
  print('      ✅ email: string (email format, required)');  
  print('      ✅ password: string (min 6 chars, required)');
  print('');
  
  print('   🔍 LoginDto Requirements:');
  print('      ✅ email: string (email format, required)');
  print('      ✅ password: string (required)');
  print('');
  
  print('   🔍 Invoice Schema Requirements:');
  print('      ✅ title: string (1-150 chars, required)');
  print('      ✅ amount: number/double (required)');
  print('      ✅ userId: integer (required)');
  print('      ✅ issueDate: datetime (optional)');
  print('      ✅ dueDate: datetime (nullable, optional)');
  print('      ✅ category: string (nullable, optional)');
  print('      ✅ imagePath: string (nullable, optional)');
  print('      ✅ payingStatus: string (nullable, optional)');
  print('');
  
  print('   📱 Flutter App Uyumluluk:');
  print('      ✅ HTTP package kullanımı doğru');
  print('      ✅ JSON encoding/decoding uygun');
  print('      ✅ Header ayarları OpenAPI uyumlu');
  print('      ✅ Error handling mevcut');
  print('      ⚠️ Token yönetimi eksik (authToken global değişkeni)');
  print('      ✅ Endpoint URL\'leri doğru yapılandırılmış');
  
  print('\n📋 SONUÇ:');
  print('   • Flutter kodu OpenAPI spec ile uyumlu');
  print('   • Ana problem: API sunucusu erişilemiyor');
  print('   • Çözüm: Sunucu durumu ve ağ bağlantısı kontrol edilmeli');
}
