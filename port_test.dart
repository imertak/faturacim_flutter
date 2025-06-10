import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  await quickPortScan();
}

Future<void> quickPortScan() async {
  print('=== Hızlı Port Tarama ===');
  
  final String host = '127.0.0.1';
  final List<int> commonPorts = [
    80, 443, 3000, 5000, 5001, 5202, 8080, 8081, 8000, 9000, 3001
  ];
  
  print('Host: $host');
  print('Taranacak portlar: $commonPorts\n');
  
  for (int port in commonPorts) {
    try {
      print('Port $port test ediliyor...');
      final socket = await Socket.connect(host, port, timeout: Duration(seconds: 2));
      print('✅ Port $port AÇIK');
      socket.destroy();
      
      // Eğer port açıksa, HTTP testi yap
      try {
        final response = await http.get(
          Uri.parse('http://$host:$port'),
        ).timeout(Duration(seconds: 3));
        print('   HTTP Response: ${response.statusCode}');
        if (response.body.length < 200) {
          print('   Body: ${response.body}');
        } else {
          print('   Body: ${response.body.substring(0, 100)}...');
        }
      } catch (e) {
        print('   HTTP Test Failed: ${e.runtimeType}');
      }
      print('');
      
    } catch (e) {
      print('❌ Port $port kapalı');
    }
  }
}
