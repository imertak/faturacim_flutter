import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:faturacim/globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfilDuzenleme extends StatefulWidget {
  const ProfilDuzenleme({super.key});

  @override
  _ProfilDuzenlemeState createState() => _ProfilDuzenlemeState();
}

class _ProfilDuzenlemeState extends State<ProfilDuzenleme> {
  final _formKey = GlobalKey<FormState>();

  String _fullName = 'Yükleniyor...';
  String _email = '';
  String _profilResmiUrl = 'https://randomuser.me/api/portraits/women/44.jpg';
  bool _isLoading = true;
  String _phoneNumber = '';
  String _gender = '';
  String _errorMessage = '';

  // Kullanıcı bilgileri kontrolleri
  final TextEditingController _adSoyadController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();

  String _secilenCinsiyet = 'Kadın';
  DateTime _secilenTarih = DateTime(1990, 1, 1);

  // Cinsiyet seçenekleri listesi - "Belirtilmemiş" de eklendi
  final List<String> _cinsiyetSecenekleri = [
    'Belirtilmemiş',
    'Kadın',
    'Erkek',
    'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    // Globals'dan email kontrolü
    if (userEmail == null) {
      setState(() {
        _errorMessage = 'Kullanıcı email bilgisi bulunamadı';
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.userInfo}',
      ).replace(queryParameters: {'email': userEmail});

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 30));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        // 1. rawGender dinamik olarak al
        final dynamic rawGender = userData['gender'];

        // 2. hangi tip gelmişse int olarak elde et
        final int genderCode =
            rawGender is int
                ? rawGender
                : int.tryParse(rawGender.toString()) ?? 0;

        // 3. enum kodunu UI'daki Türkçe string'e eşle
        const Map<int, String> genderMap = {
          0: 'Belirtilmemiş',
          1: 'Erkek',
          2: 'Kadın',
          3: 'Diğer',
        };
        final String genderString = genderMap[genderCode] ?? 'Belirtilmemiş';
        setState(() {
          _fullName = userData['fullName'] ?? 'İsim Yok';
          _email = userData['email'] ?? '';
          _phoneNumber = userData['phoneNumber'] ?? '';
          _gender = genderString;

          // Cinsiyet kontrol edilip listede yoksa varsayılan değer atanıyor
          if (_cinsiyetSecenekleri.contains(genderString)) {
            _secilenCinsiyet = genderString;
          } else {
            _secilenCinsiyet = 'Belirtilmemiş';
          }

          // Doğum tarihi kontrol edilip parse ediliyor
          if (userData['birthDate'] != null &&
              userData['birthDate'].toString().isNotEmpty) {
            try {
              _secilenTarih = DateTime.parse(userData['birthDate'].toString());
            } catch (e) {
              print('Doğum tarihi parse hatası: $e');
              _secilenTarih = DateTime(1990, 1, 1);
            }
          }

          // Kontrollere değer atama
          _adSoyadController.text = _fullName;
          _emailController.text = _email;
          _telefonController.text = _phoneNumber;

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Kullanıcı bilgileri alınamadı: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      _showErrorSnackBar('İstek zaman aşımına uğradı');
    } on SocketException {
      _showErrorSnackBar('Ağ bağlantısı hatası');
    } catch (e) {
      _showErrorSnackBar('Beklenmedik bir hata oluştu: ${e.toString()}');
    }
  }

  Future<void> _profilGuncelle() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      try {
        // UI'daki seçili cinsiyeti string olarak gönder (API string bekliyor)
        const Map<String, String> reverseGenderMap = {
          'Belirtilmemiş': 'Unspecified',
          'Erkek': 'Male',
          'Kadın': 'Female',
          'Diğer': 'Other',
        };
        final String genderToSend =
            reverseGenderMap[_secilenCinsiyet] ?? 'Unspecified';

        final Map<String, dynamic> requestBody = {
          'model': {}, // API'nin beklediği zorunlu model alanı
          'email': _emailController.text.trim(),
          'fullName': _adSoyadController.text.trim(),
          'phoneNumber': _telefonController.text.replaceAll(' ', ''),
          'gender': genderToSend, // String olarak gönderiyoruz
          'birthDate': _secilenTarih.toIso8601String(),
        };

        final response = await http
            .put(
              Uri.parse('${ApiConfig.baseUrl}${ApiConfig.updateProfile}'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: json.encode(requestBody),
            )
            .timeout(Duration(seconds: 30));

        print('Update Response Status Code: ${response.statusCode}');
        print('Update Response Body: ${response.body}');

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profil Başarıyla Güncellendi'),
              backgroundColor: Color(0xFF2E7D6B),
            ),
          );

          await _fetchUserInfo();
        } else {
          final errorData = json.decode(response.body);
          setState(() {
            _errorMessage = errorData['message'] ?? 'Profil güncellenemedi';
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_errorMessage), backgroundColor: Colors.red),
          );
        }
      } on TimeoutException {
        _showErrorSnackBar('İstek zaman aşımına uğradı');
      } on SocketException {
        _showErrorSnackBar('Ağ bağlantısı hatası');
      } catch (e) {
        _showErrorSnackBar('Beklenmedik bir hata oluştu: ${e.toString()}');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = theme == 'dark';

    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkTheme ? Colors.grey[900] : Color(0xFF2E7D6B),
        title: Text(
          'Profili Düzenle',
          style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
        ),
        centerTitle: true,
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: isDarkTheme ? Colors.white : Color(0xFF2E7D6B),
                ),
              )
              : SingleChildScrollView(
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
                              backgroundImage: NetworkImage(_profilResmiUrl),
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
                                  icon: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
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
                              Icon(
                                Icons.person_outline,
                                color: Color(0xFF2E7D6B),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Cinsiyet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 20),
                              DropdownButton<String>(
                                value: _secilenCinsiyet,
                                items:
                                    _cinsiyetSecenekleri
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
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
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

  @override
  void dispose() {
    // Controller'ları temizle
    _adSoyadController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    super.dispose();
  }
}
