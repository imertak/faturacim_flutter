import 'package:faturacim/faturadetaysayfasi.dart';
import 'package:flutter/material.dart';

class GecmisFaturalarSayfasi extends StatefulWidget {
  @override
  _GecmisFaturalarSayfasiState createState() => _GecmisFaturalarSayfasiState();
}

class _GecmisFaturalarSayfasiState extends State<GecmisFaturalarSayfasi> {
  final List<Map<String, dynamic>> tumFaturalar = [
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
    {
      'company': 'Vodafone',
      'amount': '135,50',
      'date': '05 Mayıs 2025',
      'type': 'Telefon',
      'status': 'paid',
      'category': 'İletişim',
    },
    {
      'company': 'AYEDAŞ',
      'amount': '215,75',
      'date': '02 Mayıs 2025',
      'type': 'Elektrik',
      'status': 'paid',
      'category': 'Enerji',
    },
  ];

  List<Map<String, dynamic>> _filtrelenmisFaturalar = [];
  String _secilenKategori = 'Tümü';

  @override
  void initState() {
    super.initState();
    _filtrelenmisFaturalar = tumFaturalar;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D6B),
        title: Text('Geçmiş Faturalar'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Kategori Filtre Scroll
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
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _filtrelenmisFaturalar.length,
              itemBuilder: (context, index) {
                return _buildFaturaCard(_filtrelenmisFaturalar[index]);
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
            builder:
                (context) => FaturaDetaySayfasi(
                  faturaDetaylari: {
                    'company': 'Türk Telekom',
                    'amount': '245,80',
                    'date': '15 Mayıs 2025',
                    'type': 'İletişim',
                    'status': 'paid',
                    'category': 'İletişim',
                  },
                ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12), // Ripple sınırı
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
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
