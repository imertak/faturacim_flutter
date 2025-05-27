import 'package:faturacim/globals.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class KategoriAnaliziSayfasi extends StatefulWidget {
  @override
  _KategoriAnaliziSayfasiState createState() => _KategoriAnaliziSayfasiState();
}

class _KategoriAnaliziSayfasiState extends State<KategoriAnaliziSayfasi> {
  String selectedPeriod = 'Bu Ay';
  final List<String> periods = ['Bu Ay', 'Son 3 Ay', 'Son 6 Ay', 'Bu Yıl'];

  bool isLoading = true;
  String? error;
  List<Invoice> invoices = [];

  Map<String, double> categoryTotals = {};
  double totalAmount = 0.0;
  Map<String, Color> categoryColors = {
    "Telekomünikasyon": Colors.blue,
    "Enerji": Colors.orange,
    "Market": Colors.green,
    "Ulaşım": Colors.purple,
    "Sağlık": Colors.red,
    "Diğer": Colors.grey,
    "Utilities": Colors.teal,
  };

  // Mock veri ile invoices'ı dolduran metod
  Future<void> fetchInvoices() async {
    setState(() {
      isLoading = true;
      error = null;
      invoices = [];
    });

    // Tarih aralığını seçili döneme göre ayarla
    DateTime now = DateTime.now();
    DateTime startDate;
    if (selectedPeriod == 'Bu Ay') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (selectedPeriod == 'Son 3 Ay') {
      startDate = DateTime(now.year, now.month - 2, 1); // 2 ay geri + bu ay
    } else if (selectedPeriod == 'Son 6 Ay') {
      startDate = DateTime(now.year, now.month - 5, 1);
    } else {
      // 'Bu Yıl'
      startDate = DateTime(now.year, 1, 1);
    }
    DateTime endDate = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
    ).add(const Duration(days: 1));

    try {
      // Gerçek API endpoint'inizi buraya yazın
      final url = Uri.parse(
        'http://10.121.6.93:5202/api/invoice/user/$userEmail'
        '?startDate=${startDate.toIso8601String().split("T")[0]}'
        '&endDate=${endDate.toIso8601String().split("T")[0]}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          invoices = data.map((item) => Invoice.fromJson(item)).toList();
          calculateCategoryTotals();
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Sunucu hatası: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Veri alınamadı: $e';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // İlk yüklemede gerçek verileri çek
    fetchInvoices();
  }

  void calculateCategoryTotals() {
    categoryTotals.clear();
    totalAmount = 0.0;
    for (var inv in invoices) {
      totalAmount += inv.amount;
      categoryTotals[inv.category] =
          (categoryTotals[inv.category] ?? 0) + inv.amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Kategori ve yüzdeler hazırlanıyor
    final List<_CategoryStat> stats = [];
    if (totalAmount > 0) {
      categoryTotals.forEach((cat, amt) {
        double pct = (amt / totalAmount) * 100;
        stats.add(
          _CategoryStat(
            name: cat,
            amount: amt,
            percentage: pct,
            color: categoryColors[cat] ?? Colors.grey,
          ),
        );
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D6B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'ANALİZ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text(error!))
              : SingleChildScrollView(
                child: Column(
                  children: [
                    // Dönem seçici
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF66B3A0),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Dönem:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedPeriod,
                                  isExpanded: true,
                                  items:
                                      periods
                                          .map(
                                            (period) =>
                                                DropdownMenuItem<String>(
                                                  value: period,
                                                  child: Text(period),
                                                ),
                                          )
                                          .toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedPeriod = newValue!;
                                    });
                                    fetchInvoices();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toplam tutar kartı
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Toplam Harcama',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${totalAmount.toStringAsFixed(2)} TL',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF66B3A0),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fatura sayısı: ${invoices.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // PieChart
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kategori Dağılımı',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 200,
                            child:
                                stats.isEmpty
                                    ? const Center(child: Text("Veri yok"))
                                    : PieChart(
                                      PieChartData(
                                        sections:
                                            stats
                                                .map(
                                                  (stat) => PieChartSectionData(
                                                    value: stat.percentage,
                                                    title:
                                                        '${stat.percentage.toStringAsFixed(1)}%',
                                                    color: stat.color,
                                                    radius: 80,
                                                    titleStyle: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                        centerSpaceRadius: 0,
                                        sectionsSpace: 2,
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kategori listesi
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'Kategori Detayları',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                          stats.isEmpty
                              ? const Padding(
                                padding: EdgeInsets.only(bottom: 20),
                                child: Center(
                                  child: Text("Kategori verisi yok"),
                                ),
                              )
                              : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: stats.length,
                                separatorBuilder:
                                    (context, index) => Divider(
                                      height: 1,
                                      color: Colors.grey[200],
                                    ),
                                itemBuilder: (context, index) {
                                  final stat = stats[index];
                                  return ListTile(
                                    leading: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: stat.color,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    title: Text(
                                      stat.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${stat.percentage.toStringAsFixed(1)}% toplam harcama',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    trailing: Text(
                                      '${stat.amount.toStringAsFixed(2)} TL',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                  );
                                },
                              ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
    );
  }
}

// JSON'a uygun fatura modeli
class Invoice {
  final int id;
  final String title;
  final double amount;
  final String category;

  Invoice({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
    id: json['id'],
    title: json['title'] ?? '',
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] ?? 'Diğer',
  );
}

// Kategori özet modeli (görsel gösterim için)
class _CategoryStat {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  _CategoryStat({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}
