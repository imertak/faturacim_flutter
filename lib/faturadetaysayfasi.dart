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
              _buildOdemeSatiri(
                'Ödeme Durumu',
                faturaDetaylari['status'] == 'paid' ? 'Ödendi' : 'Bekliyor',
              ),

              SizedBox(height: 30),

              // Fatura Görüntüsü
              Center(
                child: Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[300]!),
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://via.placeholder.com/400x600.png?text=Fatura+Görüntüsü',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
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
              faturaDetaylari['status'] == 'paid' ? 'Ödendi' : 'Bekliyor',
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

  void _showFullScreenFatura(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              width: double.infinity,
              height: 600,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://via.placeholder.com/400x600.png?text=Fatura+Görüntüsü',
                  ),
                  fit: BoxFit.contain,
                ),
              ),
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
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black, // Yazı (ikon vs.) rengi
                ),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Ödeme işlemi
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Ödeme Başarılı')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2E7D6B), // Butonun arka plan rengi
                  foregroundColor: Colors.white, // Yazı (ikon vs.) rengi
                ),
                child: Text('Öde'),
              ),
            ],
          ),
    );
  }
}

// Kullanım Örneği
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
//         'category': 'İletişim'
//       }
//     )
//   )
// );