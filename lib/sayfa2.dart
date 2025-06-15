// lib/sayfa2.dart
import 'dart:convert';
import 'dart:io' as io;
import 'package:faturacim/gecmisfaturalarsayfas%C4%B1.dart';
import 'package:faturacim/globals.dart';
import 'package:faturacim/kategorianalizisayfasi.dart';
import 'package:faturacim/profilsayfasi.dart';
import 'package:faturacim/vergihesaplasayfasi.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'kamerasayfasi.dart';

class Sayfa2 extends StatefulWidget {
  const Sayfa2({super.key});

  @override
  _Sayfa2State createState() => _Sayfa2State();
}

class _Sayfa2State extends State<Sayfa2> {
  List<Map<String, dynamic>> recentInvoices = [];
  bool isLoadingInvoices = true;
  // Döviz kurları için değişkenler
  Map<String, dynamic> exchangeRates = {};
  Map<String, String> previousRates = {};
  bool isLoadingRates = true;
  double monthlyTotal = 0;
  String monthlyTotalText = "";
  String pendingText = 'Tüm faturalar ödendi';

  Future<void> fetchUserInvoices() async {
    try {
      final startDate = DateTime(2020); // çok eski bir tarih
      DateTime now = DateTime.now();

      DateTime endDate = DateTime(
        now.year,
        now.month,
        now.day,
        23,
        59,
        59,
      ).add(const Duration(days: 1)); // bugüne kadar
      final encodedEmail = Uri.encodeComponent(userEmail!);
      final currentMonthUrl = Uri.parse(
        '${ApiConfig.baseUrl}/api/invoice/user/$encodedEmail'
        '?startDate=${startDate.toIso8601String().split("T")[0]}'
        '&endDate=${endDate.toIso8601String().split("T")[0]}',
      );

      final response = await http.get(currentMonthUrl);

      if (response.statusCode == 200) {
        List<dynamic> invoicesData = json.decode(response.body);
        invoicesData =
            invoicesData.reversed.toList(); // En son faturalar en üstte

        // Bekleyen faturaları sayma
        int pendingInvoicesCount =
            invoicesData.where((invoice) {
              return invoice['payingStatus'] == null ||
                  invoice['payingStatus'].toString().toLowerCase() ==
                      'bekliyor';
            }).length;
        setState(() {
          recentInvoices =
              invoicesData
                  .map(
                    (invoice) => {
                      'company': invoice['title'] ?? 'Bilinmeyen Şirket',
                      'amount': (invoice['amount'] ?? 0.0).toStringAsFixed(2),
                      'date': _formatDate(invoice['issueDate']),
                      'type': _determineInvoiceType(invoice['category']),
                      'payingStatus':
                          invoice['payingStatus'] ??
                          'Bekliyor', // Database'den direkt değer
                      'category': invoice['category'] ?? 'Diğer',
                    },
                  )
                  .toList()
                  .take(3)
                  .toList(); // Son 3 faturayı al

          isLoadingInvoices = false;
          monthlyTotal = _calculateMonthlyTotal(invoicesData);
          monthlyTotalText = '${monthlyTotal.toStringAsFixed(2)} TL';
          pendingText =
              pendingInvoicesCount > 0
                  ? '+$pendingInvoicesCount bekleyen'
                  : 'Tüm faturalar ödendi';
        });
      } else {
        print('Fatura çekme hatası: ${response.statusCode}');
        setState(() {
          isLoadingInvoices = false;
        });
      }
    } catch (e) {
      print('Fatura çekme hatası: $e');
      setState(() {
        isLoadingInvoices = false;
      });
    }
  }

  double _calculateMonthlyTotal(List<dynamic> invoicesData) {
    // Şu anki tarih
    final DateTime now = DateTime.now();

    // 30 gün önceki tarih
    final DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));

    // Son 30 gün içindeki faturaların toplam tutarını hesapla
    return invoicesData.fold(0.0, (total, invoice) {
      // Invoice'ın tarihini parse et
      DateTime? invoiceDate =
          invoice['issueDate'] != null
              ? DateTime.tryParse(invoice['issueDate'])
              : null;

      // Tarih kontrolü ve tutar hesaplama
      if (invoiceDate != null &&
          invoiceDate.isAfter(thirtyDaysAgo) &&
          invoiceDate.isBefore(now)) {
        return total + (invoice['amount'] ?? 0.0);
      }

      return total;
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tarih Yok';

    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return 'Geçersiz Tarih';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return months[month - 1];
  }

  String _determineInvoiceType(String? category) {
    if (category == null) return 'Diğer';

    switch (category.toLowerCase()) {
      case 'telefon':
        return 'Telefon';
      case 'doğalgaz':
        return 'Doğalgaz';
      case 'su':
        return 'Su';
      default:
        return 'Diğer';
    }
  }

  // PayingStatus'a göre renk belirleme fonksiyonu
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'Ödendi':
      case 'paid':
        return Color(0xFF2E7D6B); // Yeşil
      case 'Bekliyor':
      case 'pending':
        return Color(0xFFFF8A50); // Turuncu
      case 'Gecikmiş':
      case 'overdue':
        return Colors.red; // Kırmızı
      default:
        return Color(0xFFFF8A50); // Varsayılan turuncu
    }
  }

  // PayingStatus'a göre arka plan rengi belirleme fonksiyonu
  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'ödendi':
      case 'paid':
        return Color(0xFFE8F5E8); // Açık yeşil
      case 'bekliyor':
      case 'pending':
        return Color(0xFFFFF4E6); // Açık turuncu
      case 'gecikmiş':
      case 'overdue':
        return Color(0xFFFFEBEE); // Açık kırmızı
      default:
        return Color(0xFFFFF4E6); // Varsayılan açık turuncu
    }
  }

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

  final List<Map<String, dynamic>> campaigns = [
    {
      'title': 'Fatura İndirimi',
      'description': '%20\'ye varan indirim fırsatı!',
      'image': 'campaign.jpg',
      'color': Color(0xFF2E7D6B),
    },
    {
      'title': 'Yeni Üye Kampanyası',
      'description': 'İlk faturanda %15 indirim',
      'image': 'campaign2.png',
      'color': Color(0xFFFF8A50),
    },
    {
      'title': 'Dijital Fatura Avantajı',
      'description': 'Dijital faturaya geçenlere özel',
      'image': 'campaign.jpg',
      'color': Color(0xFF4A9D8E),
    },
    {
      'title': 'Yeni Üye Kampanyası',
      'description': 'İlk faturanda %15 indirim',
      'image': 'campaign2.png',
      'color': Color(0xFFFF8A50),
    },
    {
      'title': 'Dijital Fatura Avantajı',
      'description': 'Dijital faturaya geçenlere özel',
      'image': 'campaign.jpg',
      'color': Color(0xFF4A9D8E),
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchUserInvoices();
    fetchExchangeRates();
    _startPeriodicUpdate();
  }

  void _startPeriodicUpdate() {
    Future.delayed(Duration(minutes: 1), () {
      if (mounted) {
        fetchExchangeRates();
        _startPeriodicUpdate();
      }
    });
  }

  Future<void> fetchExchangeRates() async {
    const apiKey = '590cebb3a13a9186fa1309ef';

    try {
      if (exchangeRates.isNotEmpty) {
        previousRates = {
          'USD': exchangeRates['USD']?.toString() ?? '0',
          'EUR': exchangeRates['EUR']?.toString() ?? '0',
          'GBP': exchangeRates['GBP']?.toString() ?? '0',
        };
      }

      final url = Uri.parse(
        'https://v6.exchangerate-api.com/v6/$apiKey/latest/TRY',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['conversion_rates'] != null) {
          final rates = data['conversion_rates'];
          setState(() {
            exchangeRates = {
              'USD': (1 / rates['USD']),
              'EUR': (1 / rates['EUR']),
              'GBP': (1 / rates['GBP']),
            };
            isLoadingRates = false;
          });
        }
      } else {
        print('API isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Döviz kuru çekme hatası: $e');
    }
  }

  String _calculateChange(String currency) {
    if (previousRates.isEmpty || !previousRates.containsKey(currency)) {
      return '+0.00';
    }

    double current = exchangeRates[currency]?.toDouble() ?? 0.0;
    double previous = double.tryParse(previousRates[currency] ?? '0') ?? 0.0;

    if (previous == 0.0) return '+0.00';

    double change = current - previous;
    String sign = change >= 0 ? '+' : '';

    return '$sign${change.toStringAsFixed(2)}';
  }

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
                    foregroundColor: Colors.white,
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
    // Theme kontrolü için gerekli değişken
    final theme =
        MediaQuery.of(context).platformBrightness == Brightness.dark
            ? 'dark'
            : 'light';
    final isDarkTheme = theme == 'dark';

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
                                icon: Icon(
                                  Icons.search,
                                  color:
                                      isDarkTheme ? Colors.white : Colors.black,
                                ),
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
                                  backgroundColor:
                                      isDarkTheme
                                          ? Colors.grey[800]
                                          : Color(0xFFFF8A50),
                                  child: Text(
                                    userEmail != null && userEmail!.isNotEmpty
                                        ? userEmail![0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color:
                                          isDarkTheme
                                              ? Colors.white
                                              : Colors.black,
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
                      SizedBox(height: 8),

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
                              monthlyTotalText,
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
                                  pendingText, // Dinamik olarak değişecek
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
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GecmisFaturalarSayfasi(),
                              ),
                            );
                          },
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
                    ...recentInvoices.map(
                      (invoice) => _buildInvoiceCard(invoice),
                    ),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Piyasa & Haberler',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (isLoadingRates)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E7D6B),
                              ),
                            ),
                          ),
                      ],
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
                          _buildCurrencyItem(
                            'USD',
                            exchangeRates['USD']?.toStringAsFixed(2) ?? '0.00',
                            _calculateChange('USD'),
                          ),
                          _buildCurrencyItem(
                            'EUR',
                            exchangeRates['EUR']?.toStringAsFixed(2) ?? '0.00',
                            _calculateChange('EUR'),
                          ),
                          _buildCurrencyItem(
                            'GBP',
                            exchangeRates['GBP']?.toStringAsFixed(2) ?? '0.00',
                            _calculateChange('GBP'),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Son güncelleme: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ),
                    SizedBox(height: 16),
                    ...economyNews.map((news) => _buildNewsCard(news)),
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
      child: SizedBox(
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
                  invoice['payingStatus'],
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
    final isPositive = change.startsWith('+') && change != '+0.00';
    final isNegative = change.startsWith('-');
    Color changeColor = Colors.grey[600]!;

    if (isPositive) {
      changeColor = Colors.green;
    } else if (isNegative) {
      changeColor = Colors.red;
    }

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
            color: changeColor,
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
