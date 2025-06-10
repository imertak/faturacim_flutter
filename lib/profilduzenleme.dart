import 'package:flutter/material.dart';

class ProfilDuzenleme extends StatefulWidget {
  const ProfilDuzenleme({super.key});

  @override
  _ProfilDuzenlemeState createState() => _ProfilDuzenlemeState();
}

class _ProfilDuzenlemeState extends State<ProfilDuzenleme> {
  final _formKey = GlobalKey<FormState>();

  // Kullanıcı bilgileri kontrolleri
  final TextEditingController _adSoyadController = TextEditingController(
    text: 'Ayşe Yılmaz',
  );
  final TextEditingController _emailController = TextEditingController(
    text: 'ayse.yilmaz@email.com',
  );
  final TextEditingController _telefonController = TextEditingController(
    text: '0555 123 45 67',
  );

  String _secilenCinsiyet = 'Kadın';
  DateTime _secilenTarih = DateTime(1990, 1, 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D6B),
        title: Text('Profili Düzenle'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profil Fotoğrafı
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 70,
                      backgroundImage: NetworkImage(
                        'https://randomuser.me/api/portraits/women/44.jpg',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF2E7D6B),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _fotografSec,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),

                // Ad Soyad Input
                _buildInputAlani(
                  controller: _adSoyadController,
                  etiket: 'Ad Soyad',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ad soyad boş bırakılamaz';
                    }
                    return null;
                  },
                ),

                // E-posta Input
                _buildInputAlani(
                  controller: _emailController,
                  etiket: 'E-posta',
                  icon: Icons.email,
                  klavyeTipi: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta boş bırakılamaz';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),

                // Telefon Input
                _buildInputAlani(
                  controller: _telefonController,
                  etiket: 'Telefon Numarası',
                  icon: Icons.phone,
                  klavyeTipi: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Telefon numarası boş bırakılamaz';
                    }
                    // Türkiye telefon numarası formatı kontrolü
                    if (!RegExp(
                      r'^(05\d{9})$',
                    ).hasMatch(value.replaceAll(' ', ''))) {
                      return 'Geçerli bir telefon numarası girin';
                    }
                    return null;
                  },
                ),

                // Cinsiyet Seçimi
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: Color(0xFF2E7D6B)),
                      SizedBox(width: 10),
                      Text(
                        'Cinsiyet',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      SizedBox(width: 20),
                      DropdownButton<String>(
                        value: _secilenCinsiyet,
                        items:
                            ['Kadın', 'Erkek', 'Diğer']
                                .map(
                                  (cinsiyet) => DropdownMenuItem(
                                    value: cinsiyet,
                                    child: Text(cinsiyet),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _secilenCinsiyet = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Doğum Tarihi Seçimi
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.cake, color: Color(0xFF2E7D6B)),
                      SizedBox(width: 10),
                      Text(
                        'Doğum Tarihi',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      SizedBox(width: 20),
                      TextButton(
                        onPressed: _tarihSec,
                        child: Text(
                          '${_secilenTarih.day}/${_secilenTarih.month}/${_secilenTarih.year}',
                          style: TextStyle(
                            color: Color(0xFF2E7D6B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Kaydet Butonu
                ElevatedButton(
                  onPressed: _profilGuncelle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2E7D6B),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Profili Güncelle',
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
      ),
    );
  }

  Widget _buildInputAlani({
    required TextEditingController controller,
    required String etiket,
    required IconData icon,
    TextInputType klavyeTipi = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: klavyeTipi,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xFF2E7D6B)),
          labelText: etiket,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Color(0xFF2E7D6B), width: 2),
          ),
        ),
      ),
    );
  }

  void _fotografSec() {
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
            children: [
              Text(
                'Profil Fotoğrafı Seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFotoSecButonu(
                    icon: Icons.camera_alt,
                    baslik: 'Kamera',
                    onTap: () {
                      // Kamera işlemleri
                      Navigator.pop(context);
                    },
                  ),
                  _buildFotoSecButonu(
                    icon: Icons.photo_library,
                    baslik: 'Galeri',
                    onTap: () {
                      // Galeri işlemleri
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFotoSecButonu({
    required IconData icon,
    required String baslik,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Color(0xFF2E7D6B).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: Color(0xFF2E7D6B)),
            onPressed: onTap,
          ),
        ),
        SizedBox(height: 10),
        Text(
          baslik,
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  void _tarihSec() async {
    final DateTime? secilen = await showDatePicker(
      context: context,
      initialDate: _secilenTarih,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: Color(0xFF2E7D6B)),
          ),
          child: child!,
        );
      },
    );

    if (secilen != null && secilen != _secilenTarih) {
      setState(() {
        _secilenTarih = secilen;
      });
    }
  }

  void _profilGuncelle() {
    if (_formKey.currentState!.validate()) {
      // Profil güncelleme işlemleri
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profil Başarıyla Güncellendi'),
          backgroundColor: Color(0xFF2E7D6B),
        ),
      );
    }
  }
}
