import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  await testApiConnection();
}

Future<void> testApiConnection() async {
  print('=== API Bağlantı Testi ===');
  
  final String baseUrl = 'http://127.0.0.1:5202';
  
  // Test 0: Internet connectivity
  print('\n0. İnternet bağlantısı testi...');
  try {
    final response = await http.get(
      Uri.parse('https://www.google.com'),
    ).timeout(Duration(seconds: 5));
    print('✅ İnternet bağlantısı çalışıyor - Status: ${response.statusCode}');
  } catch (e) {
    print('❌ İnternet bağlantısı hatası: $e');
  }
  
  // Test 1: Basic connectivity
  print('\n1. Temel bağlantı testi...');
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api'),
      headers: {'accept': 'application/json'},
    ).timeout(Duration(seconds: 10));
    
    print('✅ Bağlantı başarılı - Status: ${response.statusCode}');
    print('Response: ${response.body}');
  } catch (e) {
    print('❌ Bağlantı hatası: $e');
    if (e.toString().contains('TimeoutException')) {
      print('   → Sunucu yanıt vermiyor (timeout)');
    } else if (e.toString().contains('SocketException')) {
      print('   → Ağ bağlantısı problemi');
    }
  }
  
  // Test 2: Different ports check
  print('\n2. Farklı portları test etme...');
  final List<int> portsToTest = [5202, 80, 443, 8080, 3000, 5000];
  
  for (int port in portsToTest) {
    try {
      final socket = await Socket.connect('127.0.0.1', port, timeout: Duration(seconds: 3));
      print('✅ Port $port açık');
      socket.destroy();
    } catch (e) {
      print('❌ Port $port kapalı veya erişilemez');
    }
  }
  
  // Test 3: Login endpoint test
  print('\n3. Login endpoint testi...');
  try {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': 'test@example.com',
        'password': 'testpassword'
      }),
    ).timeout(Duration(seconds: 10));
    
    print('✅ Login endpoint erişilebilir - Status: ${response.statusCode}');
    print('Response: ${response.body}');
  } catch (e) {
    print('❌ Login endpoint hatası: $e');
  }
  
  // Test 4: Network reachability
  print('\n4. Network erişilebilirlik testi...');
  try {
    final result = await InternetAddress.lookup('127.0.0.1');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      print('✅ IP adresi DNS\'den çözümlendi: ${result[0].address}');
    }
  } catch (e) {
    print('❌ IP adresi erişilemez: $e');
  }
  
  // Test 5: Alternative endpoints
  print('\n5. Alternatif endpoint testleri...');
  final List<String> endpoints = [
    baseUrl,
    '$baseUrl/',
    '$baseUrl/api',
    '$baseUrl/health',
    '$baseUrl/status',
  ];
  
  for (String endpoint in endpoints) {
    try {
      final response = await http.get(
        Uri.parse(endpoint),
      ).timeout(Duration(seconds: 3));
      
      print('✅ $endpoint - Status: ${response.statusCode}');
    } catch (e) {
      print('❌ $endpoint - Hata: ${e.runtimeType}');
    }
  }
  
  // Test 6: Local network test
  print('\n6. Yerel ağ testi...');
  try {
    final interfaces = await NetworkInterface.list();
    print('Ağ arayüzleri:');
    for (var interface in interfaces) {
      for (var addr in interface.addresses) {
        print('  ${interface.name}: ${addr.address}');
      }
    }
  } catch (e) {
    print('❌ Ağ arayüzleri alınamadı: $e');
  }
}
