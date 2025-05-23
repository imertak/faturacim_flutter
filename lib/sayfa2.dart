// lib/sayfa2.dart
import 'package:faturacim/gecmisfaturalarsayfas%C4%B1.dart';
import 'package:faturacim/kategorianalizisayfasi.dart';
import 'package:faturacim/profilsayfasi.dart';
import 'package:faturacim/vergihesaplasayfasi.dart';
import 'package:flutter/material.dart';
import 'kamerasayfasi.dart';

class Sayfa2 extends StatefulWidget {
  @override
  _Sayfa2State createState() => _Sayfa2State();
}

class _Sayfa2State extends State<Sayfa2> {
  final List<Map<String, dynamic>> recentInvoices = [
    {
      'company': 'Türk Telekom',
      'amount': '245,80',
      'date': '15 Mayıs 2025',
      'type': 'Telefon',
      'status': 'paid',
      'category': 'İletişim',
    },
    {
      'company': 'İGDAŞ',
      'amount': '189,45',
      'date': '12 Mayıs 2025',
      'type': 'Doğalgaz',
      'status': 'pending',
      'category': 'Enerji',
    },
    {
      'company': 'İSKİ',
      'amount': '78,90',
      'date': '10 Mayıs 2025',
      'type': 'Su',
      'status': 'paid',
      'category': 'Enerji',
    },
  ];

  final List<Map<String, String>> quickActions = [
    {'title': 'Fatura\nTara', 'icon': 'camera', 'color': 'orange'},
    {'title': 'Geçmiş\nFaturalar', 'icon': 'history', 'color': 'blue'},
    {'title': 'Kategori\nAnalizi', 'icon': 'chart', 'color': 'green'},
    {'title': 'Vergi\nHesapla', 'icon': 'calculator', 'color': 'purple'},
  ];

  final List<Map<String, String>> economyNews = [
    {
      'title': 'KDV oranları güncellendi',
      'summary': 'Yeni KDV oranları 1 Haziran\'dan itibaren...',
      'time': '2 saat önce',
    },
    {
      'title': 'ÖTV düzenlemesi yapıldı',
      'summary': 'Otomobil ÖTV\'sinde indirim kararı...',
      'time': '5 saat önce',
    },
  ];
  // Kampanyalar için yeni bir liste ekleyelim
  final List<Map<String, dynamic>> campaigns = [
    {
      'title': 'Fatura İndirimi',
      'description': '%20\'ye varan indirim fırsatı!',
      'image': 'assets/campaign1.png',
      'color': Color(0xFF2E7D6B),
    },
    {
      'title': 'Yeni Üye Kampanyası',
      'description': 'İlk faturanda %15 indirim',
      'image': 'assets/campaign2.png',
      'color': Color(0xFFFF8A50),
    },
    {
      'title': 'Dijital Fatura Avantajı',
      'description': 'Dijital faturaya geçenlere özel',
      'image': 'assets/campaign3.png',
      'color': Color(0xFF4A9D8E),
    },
    {
      'title': 'Yeni Üye Kampanyası',
      'description': 'İlk faturanda %15 indirim',
      'image': 'assets/campaign2.png',
      'color': Color(0xFFFF8A50),
    },
    {
      'title': 'Dijital Fatura Avantajı',
      'description': 'Dijital faturaya geçenlere özel',
      'image': 'assets/campaign3.png',
      'color': Color(0xFF4A9D8E),
    },
  ];

  void _showCampaignDetails(
    BuildContext context,
    Map<String, dynamic> campaign,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: campaign['color'], width: 3),
                    image: DecorationImage(
                      image: AssetImage(campaign['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                campaign['title'],
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: campaign['color'],
                ),
              ),
              SizedBox(height: 10),
              Text(
                campaign['description'],
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: campaign['color'],
                  ),
                  child: Text('Detayları Gör'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2E7D6B), Color(0xFF4A9D8E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Column(
                    children: [
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.receipt_long,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'FATURACIM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {},
                                icon: Icon(Icons.search, color: Colors.white),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProfilSayfasi(),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFFFF8A50),
                                  child: Text(
                                    'FU',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      // Balance Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bu Ay Toplam',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                Icon(
                                  Icons.visibility_outlined,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '1.247,85 TL',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2E7D6B),
                              ),
                            ),
                            SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE8F5E8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.trending_down,
                                        size: 16,
                                        color: Color(0xFF2E7D6B),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '%15 azaldı',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D6B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  '+3 bekleyen',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kampanyalar Carousel
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            campaigns.map((campaign) {
                              return GestureDetector(
                                onTap: () {
                                  _showCampaignDetails(context, campaign);
                                },
                                child: Container(
                                  margin: EdgeInsets.only(right: 12),
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: campaign['color'],
                                      width: 3,
                                    ),
                                    image: DecorationImage(
                                      image: AssetImage(campaign['image']),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
              // Quick Actions
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hızlı İşlemler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:
                          quickActions.map((action) {
                            return _buildQuickAction(
                              action['title']!,
                              _getIconData(action['icon']!),
                              _getActionColor(action['color']!),
                              () {
                                if (action['icon'] == 'camera') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => KameraSayfasi(),
                                    ),
                                  );
                                } else if (action['icon'] == 'chart') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => KategoriAnaliziSayfasi(),
                                    ),
                                  );
                                } else if (action['icon'] == 'calculator') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VergiHesaplaSayfasi(),
                                    ),
                                  );
                                } else if (action['icon'] == 'history') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => GecmisFaturalarSayfasi(),
                                    ),
                                  );
                                }
                                // Diğer aksiyonlar için else-if ekleyebilirsin
                              },
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Recent Invoices
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Son Faturalar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Tümünü Gör',
                            style: TextStyle(
                              color: Color(0xFF2E7D6B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ...recentInvoices
                        .map((invoice) => _buildInvoiceCard(invoice))
                        .toList(),
                  ],
                ),
              ),

              SizedBox(height: 32),

              // Piyasa & Haberler
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Piyasa & Haberler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Color(0xFFF8FFFE),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Color(0xFFE0F2EF)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildCurrencyItem('USD', '28.45', '+0.12'),
                          _buildCurrencyItem('EUR', '30.89', '-0.05'),
                          _buildCurrencyItem('GBP', '35.67', '+0.23'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    ...economyNews.map((news) => _buildNewsCard(news)).toList(),
                  ],
                ),
              ),

              SizedBox(height: 100), // Alt navigasyon için boşluk
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Ana Sayfa
            GestureDetector(
              onTap: () {},
              child: _buildBottomNavItem(Icons.home, 'Ana Sayfa', true),
            ),

            // Tara → KameraSayfasi
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => KameraSayfasi()),
                );
              },
              child: _buildBottomNavItem(Icons.camera_alt, 'Tara', false),
            ),

            // Geçmiş
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GecmisFaturalarSayfasi()),
                );
              },
              child: _buildBottomNavItem(Icons.history, 'Geçmiş', false),
            ),

            // Profil
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfilSayfasi()),
                );
              },
              child: _buildBottomNavItem(Icons.person, 'Profil', false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 75,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color:
                  invoice['status'] == 'paid'
                      ? Color(0xFFE8F5E8)
                      : Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              invoice['type'] == 'Telefon'
                  ? Icons.phone
                  : invoice['type'] == 'Doğalgaz'
                  ? Icons.local_fire_department
                  : Icons.water_drop,
              color:
                  invoice['status'] == 'paid'
                      ? Color(0xFF2E7D6B)
                      : Color(0xFFFF8A50),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice['company'],
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  '${invoice['category']} • ${invoice['date']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${invoice['amount']} TL',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      invoice['status'] == 'paid'
                          ? Color(0xFFE8F5E8)
                          : Color(0xFFFFF4E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invoice['status'] == 'paid' ? 'Ödendi' : 'Bekliyor',
                  style: TextStyle(
                    color:
                        invoice['status'] == 'paid'
                            ? Color(0xFF2E7D6B)
                            : Color(0xFFFF8A50),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyItem(String currency, String rate, String change) {
    final isPositive = change.startsWith('+');
    return Column(
      children: [
        Text(
          currency,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          rate,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 2),
        Text(
          change,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(Map<String, String> news) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  news['title']!,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
              Text(
                news['time']!,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            news['summary']!,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? Color(0xFF2E7D6B) : Colors.grey[400],
          size: 24,
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Color(0xFF2E7D6B) : Colors.grey[400],
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'camera':
        return Icons.camera_alt;
      case 'history':
        return Icons.history;
      case 'chart':
        return Icons.bar_chart;
      case 'calculator':
        return Icons.calculate;
      default:
        return Icons.help_outline;
    }
  }

  Color _getActionColor(String colorName) {
    switch (colorName) {
      case 'orange':
        return Color(0xFFFF8A50);
      case 'blue':
        return Color(0xFF4A9D8E);
      case 'green':
        return Color(0xFF2E7D6B);
      case 'purple':
        return Color(0xFF8B5A9F);
      default:
        return Color(0xFF2E7D6B);
    }
  }
}
