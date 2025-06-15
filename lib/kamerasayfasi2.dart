import 'dart:convert';
import 'package:faturacim/globals.dart';
import 'package:faturacim/sayfa2.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io' as io;

class KameraSayfasi2 extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic>? faturaData;

  const KameraSayfasi2({super.key, required this.imagePath, this.faturaData});

  @override
  _KameraSayfasi2State createState() => _KameraSayfasi2State();
}

class _KameraSayfasi2State extends State<KameraSayfasi2> {
  bool _isProcessing = true;
  late Map<String, dynamic> _faturaVerileri;

  // Ödeme durumu seçenekleri
  final List<Map<String, dynamic>> _odemeDurumlari = [
    {'value': 'Ödendi', 'color': const Color(0xFF66B3A0)},
    {'value': 'Bekliyor', 'color': const Color(0xFFFF9800)},
    {'value': 'Gecikmiş', 'color': const Color(0xFFF44336)},
    {'value': 'İptal', 'color': const Color(0xFF757575)},
  ];

  String _selectedOdemeDurumu = 'Bekliyor';

  @override
  void initState() {
    super.initState();
    _processFaturaData();
  }

  Future<void> _processFaturaData() async {
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _faturaVerileri =
          widget.faturaData ??
          {
            'sirket': 'Türk Telekom',
            'tutar': '245,80 TL',
            'sonOdeme': '15 Mayıs 2025',
            'kategori': 'İletişim',
            'faturaNumarasi': 'TT2025051234',
          };
      _isProcessing = false;
    });
  }

  // Seçilen ödeme durumuna göre renk getir
  Color _getOdemeDurumuColor(String durum) {
    final odemeDurumu = _odemeDurumlari.firstWhere(
      (item) => item['value'] == durum,
      orElse: () => _odemeDurumlari[1], // Default: Bekliyor
    );
    return odemeDurumu['color'];
  }

  // Platform uyumlu görüntü yükleme fonksiyonu
  Widget _platformBasedImage(String imagePath) {
    return kIsWeb ? _buildWebImage(imagePath) : _buildMobileImage(imagePath);
  }

  // Web için görüntü yükleme metodu
  Widget _buildWebImage(String imagePath) {
    return Image.network(
      imagePath,
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
    );
  }

  // Mobil için görüntü yükleme metodu
  Widget _buildMobileImage(String imagePath) {
    print("Gelen imagePath: $imagePath");
    final file = io.File(imagePath);
    print("File exists: ${file.existsSync()}");
    return Image.file(
      io.File(imagePath),
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildErrorImage(),
    );
  }

  // Hata durumunda gösterilecek widget
  Widget _buildErrorImage() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.error, color: Colors.red, size: 50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF66B3A0),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        'DETAY',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () {
            // Share functionality
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProcessingOrCompanyCard(),
          _buildImageContainer(),
          const SizedBox(height: 24),
          if (!_isProcessing) ...[
            _buildDetailSection(),
            const SizedBox(height: 24),
            _buildPaymentSection(),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProcessingOrCompanyCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isProcessing ? _buildProcessingCard() : _buildCompanyCard(),
    );
  }

  Widget _buildImageContainer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _platformBasedImage(widget.imagePath),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    return !_isProcessing
        ? FloatingActionButton.extended(
          onPressed: _uploadInvoice,
          backgroundColor: const Color(0xFF66B3A0),
          icon: const Icon(Icons.upload, color: Colors.white),
          label: const Text(
            'Yükle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        )
        : null;
  }

  Future<void> _uploadInvoice() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Invoice');

    final invoiceData = {
      "title": _faturaVerileri['sirket'] ?? "Fatura",
      "amount":
          double.tryParse(
            _faturaVerileri['tutar']
                    ?.replaceAll(' TL', '')
                    .replaceAll(',', '.') ??
                '0',
          ) ??
          0,
      "issueDate": DateTime.now().toIso8601String(),
      "dueDate": DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      "category": _faturaVerileri['kategori'] ?? "Diğer",
      "imagePath": widget.imagePath,
      "userId": 1,
      "payingStatus": _selectedOdemeDurumu, // Seçilen ödeme durumu eklendi
    };

    try {
      final response = await http.post(
        url,
        headers: {'Accept': '*/*', 'Content-Type': 'application/json'},
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackbar('Fatura başarıyla gönderildi!');
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Sayfa2()),
        );
      } else {
        _showErrorSnackbar('Hata: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Sunucuya ulaşılamadı: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _buildProcessingCard() {
    return Column(
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF66B3A0)),
        ),
        const SizedBox(height: 16),
        const Text(
          'Fatura işleniyor...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lütfen bekleyin',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildCompanyCard() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF66B3A0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text(
              'Tt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _faturaVerileri['sirket'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _faturaVerileri['tutar'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF66B3A0),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getOdemeDurumuColor(_selectedOdemeDurumu).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _selectedOdemeDurumu,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getOdemeDurumuColor(_selectedOdemeDurumu),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Şirket', _faturaVerileri['sirket'] ?? ''),
          _buildDetailRow('Fatura Türü', _faturaVerileri['kategori'] ?? ''),
          _buildDetailRow('Tarih', _faturaVerileri['sonOdeme'] ?? ''),
          _buildDetailRow('Kategori', _faturaVerileri['kategori'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Bilgileri',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF66B3A0),
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Toplam Tutar', _faturaVerileri['tutar'] ?? ''),

          // Ödeme Durumu Seçimi
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ödeme Durumu',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedOdemeDurumu,
                      isDense: true,
                      items:
                          _odemeDurumlari.map((durum) {
                            return DropdownMenuItem<String>(
                              value: durum['value'],
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: durum['color'],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    durum['value'],
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedOdemeDurumu = newValue;
                          });
                        }
                      },
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF66B3A0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF66B3A0).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color(0xFF66B3A0),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bu fatura otomatik olarak tanındı. Bilgileri kontrol edin.',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF66B3A0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
