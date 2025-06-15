import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:flutter/material.dart';

class FaturaDetaySayfasi extends StatelessWidget {
  final Map<String, dynamic> faturaDetaylari;

  const FaturaDetaySayfasi({super.key, required this.faturaDetaylari});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D6B),
        title: Text('DETAY'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              // Fatura indirme işlemi
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Fatura İndirildi')));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fatura Kartı
              _buildFaturaKarti(),

              SizedBox(height: 30),

              // Detaylı Bilgiler
              _buildBilgiSatiri('Şirket', faturaDetaylari['company']),
              _buildBilgiSatiri('Fatura Türü', faturaDetaylari['type']),
              _buildBilgiSatiri('Tarih', faturaDetaylari['date']),
              _buildBilgiSatiri('Kategori', faturaDetaylari['category']),

              SizedBox(height: 30),

              // Ödeme Bilgileri
              Text(
                'Ödeme Bilgileri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D6B),
                ),
              ),
              Divider(color: Colors.grey[300]),

              _buildOdemeSatiri(
                'Toplam Tutar',
                '${faturaDetaylari['amount']} TL',
              ),
              _buildOdemeSatiri('Ödeme Durumu', faturaDetaylari['status']),

              SizedBox(height: 30),

              // Fatura Görüntüsü - Düzeltildi
              Center(
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      // Fatura görselini göster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: _buildFaturaGorseli(),
                      ),
                      // Büyütme butonu
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Fatura büyütme işlemi
                            _showFullScreenFatura(context);
                          },
                          icon: Icon(Icons.zoom_in, color: Colors.white),
                          label: Text(
                            'Büyüt',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2E7D6B).withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 30),

              // İşlem Butonu
              ElevatedButton(
                onPressed: () {
                  // Ödeme işlemi
                  _showOdemeOnayDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D6B),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Şimdi Öde',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaturaKarti() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF2E7D6B).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Color(0xFF2E7D6B), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Color(0xFF2E7D6B),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              faturaDetaylari['type'] == 'Telefon'
                  ? Icons.phone
                  : faturaDetaylari['type'] == 'Doğalgaz'
                  ? Icons.local_fire_department
                  : faturaDetaylari['type'] == 'Su'
                  ? Icons.water_drop
                  : Icons.electrical_services,
              color: Colors.white,
              size: 30,
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faturaDetaylari['company'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '${faturaDetaylari['amount']} TL',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2E7D6B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color:
                  faturaDetaylari['status'] == 'paid'
                      ? Color(0xFFE8F5E9)
                      : Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              faturaDetaylari['status'],
              style: TextStyle(
                color:
                    faturaDetaylari['status'] == 'paid'
                        ? Color(0xFF2E7D6B)
                        : Color(0xFFFF8A50),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBilgiSatiri(String baslik, String icerik) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            baslik,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            icerik,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOdemeSatiri(String baslik, String icerik) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            baslik,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            icerik,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D6B),
            ),
          ),
        ],
      ),
    );
  }

  // Platform bazlı görsel yükleme metodu - Geliştirildi
  Widget _buildFaturaGorseli() {
    final imagePath = faturaDetaylari['imagePath'];
    print("Image gösterilecek path: |$imagePath|"); // BURADA!

    if (imagePath == null || imagePath.isEmpty) {
      return _buildPlaceholderImage();
    }

    try {
      if (kIsWeb) {
        // Web için network image
        return Image.network(
          imagePath,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Network image error: $error');
            return _buildPlaceholderImage();
          },
        );
      } else {
        // Mobil platformlar için file image
        final file = File(imagePath);

        // Dosya varlığını kontrol et
        if (!file.existsSync()) {
          print('File does not exist: $imagePath');
          return _buildPlaceholderImage();
        }

        return Image.file(
          file,
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('File image error: $error');
            return _buildPlaceholderImage();
          },
        );
      }
    } catch (e) {
      print('Image loading error: $e');
      return _buildPlaceholderImage();
    }
  }

  // Placeholder görsel
  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, color: Colors.grey[500], size: 50),
          SizedBox(height: 10),
          Text(
            'Fatura görseli yüklenemiyor',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Tam ekran görsel gösterme metodu - Geliştirildi
  void _showFullScreenFatura(BuildContext context) {
    final imagePath = faturaDetaylari['imagePath'];

    if (imagePath == null || imagePath.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fatura görseli bulunamadı')));
      return;
    }

    // Mobil platformlarda dosya varlığını kontrol et
    if (!kIsWeb) {
      final file = File(imagePath);
      if (!file.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fatura görseli dosyası bulunamadı')),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black,
            child: Stack(
              children: [
                Center(
                  child:
                      kIsWeb
                          ? Image.network(
                            imagePath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  'Görsel yüklenemiyor',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            },
                          )
                          : Image.file(
                            File(imagePath),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  'Görsel yüklenemiyor',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            },
                          ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showOdemeOnayDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Ödeme Onayı'),
            content: Text(
              '${faturaDetaylari['amount']} TL tutarındaki faturayı ödemek istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Ödeme Başarılı')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D6B),
                  foregroundColor: Colors.white,
                ),
                child: Text('Öde'),
              ),
            ],
          ),
    );
  }
}

// Kullanım Örneği - imagePath parametresi eklendi
// Navigator.push(
//   context, 
//   MaterialPageRoute(
//     builder: (context) => FaturaDetaySayfasi(
//       faturaDetaylari: {
//         'company': 'Türk Telekom',
//         'amount': '245,80',
//         'date': '15 Mayıs 2025',
//         'type': 'İletişim',
//         'status': 'paid',
//         'category': 'İletişim',
//         'imagePath': '/data/user/0/com.example.flutter_application_1/app_flutter/faturalar/1749997652944.jpg'
//       }
//     )
//   )
// );