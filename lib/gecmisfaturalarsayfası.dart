import 'dart:convert';
import 'dart:io';

import 'package:excel/excel.dart';
import 'package:faturacim/faturadetaysayfasi.dart';
import 'package:faturacim/globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class GecmisFaturalarSayfasi extends StatefulWidget {
  @override
  _GecmisFaturalarSayfasiState createState() => _GecmisFaturalarSayfasiState();
}

class _GecmisFaturalarSayfasiState extends State<GecmisFaturalarSayfasi> {
  List<Map<String, dynamic>> tumFaturalar = [];
  List<Map<String, dynamic>> _filtrelenmisFaturalar = [];
  String _secilenKategori = 'Tümü';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFaturalar();
  }

  Future<void> _fetchFaturalar() async {
    try {
      final encodedEmail = Uri.encodeComponent(userEmail!);
      final url = Uri.parse(
        'http://localhost:5202/api/invoice/user/$encodedEmail',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> invoicesData = json.decode(response.body);

        setState(() {
          tumFaturalar =
              invoicesData.map((invoice) {
                return {
                  'id': invoice['id'],
                  'company': invoice['title'] ?? 'Bilinmeyen Şirket',
                  'amount': (invoice['amount'] ?? 0.0).toStringAsFixed(2),
                  'date': _formatDate(invoice['issueDate']),
                  'type': _determineInvoiceType(invoice['category']),
                  'status':
                      invoice['payingStatus'] == null ? 'pending' : 'paid',
                  'category': invoice['category'] ?? 'Diğer',
                };
              }).toList();

          _filtrelenmisFaturalar = tumFaturalar;
          _isLoading = false;
        });
      } else {
        print('Fatura çekme hatası: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Fatura çekme hatası: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
      case 'elektrik':
        return 'Elektrik';
      default:
        return 'Diğer';
    }
  }

  void _kategoriFiltreleme(String kategori) {
    setState(() {
      _secilenKategori = kategori;
      _filtrelenmisFaturalar =
          kategori == 'Tümü'
              ? tumFaturalar
              : tumFaturalar
                  .where((fatura) => fatura['category'] == kategori)
                  .toList();
    });
  }

  // -------------------- EXCEL AKTAR ---------------------
  Future<void> exportToExcel(List<Map<String, dynamic>> faturalar) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Faturalar'];

    sheetObject.appendRow([
      'ID',
      'Şirket',
      'Tutar',
      'Tarih',
      'Tür',
      'Durum',
      'Kategori',
    ]);

    for (var fatura in faturalar) {
      sheetObject.appendRow([
        fatura['id'],
        fatura['company'],
        fatura['amount'],
        fatura['date'],
        fatura['type'],
        fatura['status'] == 'paid' ? 'Ödendi' : 'Bekliyor',
        fatura['category'],
      ]);
    }

    Directory? directory;
    if (Platform.isAndroid || Platform.isIOS) {
      directory = await getExternalStorageDirectory();
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    String filePath = "${directory!.path}/faturalar.xlsx";
    File file =
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(excel.encode()!);

    // Dosya konumunu kullanıcıya bildir (örn. Snackbar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Excel dosyası indirildi: $filePath")),
    );
  }

  // ------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D6B),
        foregroundColor: Colors.white,
        title: Text('GEÇMİŞ'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.download_rounded),
            tooltip: 'Excel’e Aktar',
            onPressed: () async {
              await exportToExcel(_filtrelenmisFaturalar);
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D6B)),
              )
              : Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _buildKategoriChip('Tümü'),
                        _buildKategoriChip('İletişim'),
                        _buildKategoriChip('Enerji'),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _filtrelenmisFaturalar.isEmpty
                            ? Center(
                              child: Text(
                                'Henüz fatura bulunmamaktadır.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                            : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _filtrelenmisFaturalar.length,
                              itemBuilder: (context, index) {
                                return _buildFaturaCard(
                                  _filtrelenmisFaturalar[index],
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }

  Widget _buildKategoriChip(String kategori) {
    bool isSelected = _secilenKategori == kategori;
    return GestureDetector(
      onTap: () => _kategoriFiltreleme(kategori),
      child: Container(
        margin: EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF2E7D6B) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          kategori,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildFaturaCard(Map<String, dynamic> fatura) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FaturaDetaySayfasi(faturaDetaylari: fatura),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    fatura['status'] == 'paid'
                        ? Color(0xFFE8F5E8)
                        : Color(0xFFFFF4E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                fatura['type'] == 'Telefon'
                    ? Icons.phone
                    : fatura['type'] == 'Doğalgaz'
                    ? Icons.local_fire_department
                    : fatura['type'] == 'Su'
                    ? Icons.water_drop
                    : Icons.electrical_services,
                color:
                    fatura['status'] == 'paid'
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
                    fatura['company'],
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${fatura['category']} • ${fatura['date']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${fatura['amount']} TL',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        fatura['status'] == 'paid'
                            ? Color(0xFFE8F5E8)
                            : Color(0xFFFFF4E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fatura['status'] == 'paid' ? 'Ödendi' : 'Bekliyor',
                    style: TextStyle(
                      color:
                          fatura['status'] == 'paid'
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
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fatura Filtreleme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFilterOption('Tümü', Icons.list),
                  _buildFilterOption('Ödendi', Icons.check_circle),
                  _buildFilterOption('Bekleyen', Icons.pending),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, IconData icon) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          _filtrelenmisFaturalar =
              title == 'Tümü'
                  ? tumFaturalar
                  : tumFaturalar
                      .where(
                        (fatura) =>
                            title == 'Ödendi'
                                ? fatura['status'] == 'paid'
                                : fatura['status'] == 'pending',
                      )
                      .toList();
        });
      },
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(0xFF2E7D6B)),
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
