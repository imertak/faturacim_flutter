// lib/sayfa2.dart
import 'package:flutter/material.dart';
import 'kamerasayfasi.dart'; // Kamera sayfasını import et

class Sayfa2 extends StatelessWidget {
  final List<String> eskiKayitlar = [
    "Fatura #1 - 2025-04-01",
    "Fatura #2 - 2025-04-05",
    "Fatura #3 - 2025-04-10",
    "Fatura #4 - 2025-04-15",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, size: 30),
                SizedBox(width: 10),
                Text(
                  'Faturacım',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            IconButton(
              icon: Icon(Icons.person),
              onPressed: () {
                // Profil sayfasına yönlendirme işlemi
              },
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Eski Kayıtlar',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: eskiKayitlar.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(eskiKayitlar[index]),
                            trailing: Icon(Icons.arrow_forward),
                            onTap: () {
                              // Kayıt seçildiğinde yapılacak işlemler
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 50,
                  icon: Icon(Icons.history),
                  onPressed: () {},
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => KameraSayfasi()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(40),
                  ),
                  child: Icon(Icons.camera_alt, size: 50, color: Colors.white),
                ),
                SizedBox(width: 20),
                IconButton(
                  iconSize: 50,
                  icon: Icon(Icons.settings),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
