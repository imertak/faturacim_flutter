import 'package:flutter/material.dart';

class VergiHesaplaSayfasi extends StatefulWidget {
  const VergiHesaplaSayfasi({super.key});

  @override
  _VergiHesaplaSayfasiState createState() => _VergiHesaplaSayfasiState();
}

class _VergiHesaplaSayfasiState extends State<VergiHesaplaSayfasi> {
  final TextEditingController _tutarController = TextEditingController();
  String selectedTaxType = 'KDV %18';
  double calculatedTax = 0.0;
  double totalAmount = 0.0;
  double netAmount = 0.0;

  final Map<String, double> taxRates = {
    'KDV %1': 0.01,
    'KDV %8': 0.08,
    'KDV %18': 0.18,
    'ÖTV %15': 0.15,
    'ÖTV %20': 0.20,
    'Stopaj %15': 0.15,
    'Stopaj %20': 0.20,
  };

  void _calculateTax() {
    if (_tutarController.text.isEmpty) return;

    double amount =
        double.tryParse(_tutarController.text.replaceAll(',', '.')) ?? 0.0;
    double rate = taxRates[selectedTaxType] ?? 0.18;

    setState(() {
      netAmount = amount;
      calculatedTax = amount * rate;
      totalAmount = amount + calculatedTax;
    });
  }

  void _clearAll() {
    setState(() {
      _tutarController.clear();
      calculatedTax = 0.0;
      totalAmount = 0.0;
      netAmount = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
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
          'HESAPLA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _clearAll,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hesaplama formu
            Container(
              margin: const EdgeInsets.all(16),
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
                    'Vergi Hesaplama',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tutar girişi
                  const Text(
                    'Net Tutar (TL)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tutarController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '0,00',
                      prefixIcon: const Icon(
                        Icons.attach_money,
                        color: Color(0xFF66B3A0),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF66B3A0)),
                      ),
                    ),
                    onChanged: (value) => _calculateTax(),
                  ),

                  const SizedBox(height: 20),

                  // Vergi türü seçimi
                  const Text(
                    'Vergi Türü',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedTaxType,
                        isExpanded: true,
                        items:
                            taxRates.keys.map((String taxType) {
                              return DropdownMenuItem<String>(
                                value: taxType,
                                child: Text(taxType),
                              );
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedTaxType = newValue!;
                            _calculateTax();
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Hesapla butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _calculateTax,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66B3A0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hesapla',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sonuç kartları
            if (totalAmount > 0) ...[
              // Net tutar
              _buildResultCard(
                'Net Tutar',
                '${netAmount.toStringAsFixed(2)} TL',
                Colors.blue,
                Icons.money,
              ),

              // Vergi tutarı
              _buildResultCard(
                'Vergi Tutarı ($selectedTaxType)',
                '${calculatedTax.toStringAsFixed(2)} TL',
                Colors.orange,
                Icons.receipt,
              ),

              // Toplam tutar
              _buildResultCard(
                'Toplam Tutar',
                '${totalAmount.toStringAsFixed(2)} TL',
                const Color(0xFF66B3A0),
                Icons.calculate,
              ),
            ],

            // Vergi oranları tablosu
            Container(
              margin: const EdgeInsets.all(16),
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
                      'Vergi Oranları',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: taxRates.length,
                    separatorBuilder:
                        (context, index) =>
                            Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (context, index) {
                      String taxType = taxRates.keys.elementAt(index);
                      double rate = taxRates[taxType]!;

                      return ListTile(
                        leading: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                selectedTaxType == taxType
                                    ? const Color(0xFF66B3A0)
                                    : Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        title: Text(
                          taxType,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                selectedTaxType == taxType
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        trailing: Text(
                          '%${(rate * 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                selectedTaxType == taxType
                                    ? const Color(0xFF66B3A0)
                                    : Colors.grey[600],
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedTaxType = taxType;
                            _calculateTax();
                          });
                        },
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

  Widget _buildResultCard(
    String title,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tutarController.dispose();
    super.dispose();
  }
}
