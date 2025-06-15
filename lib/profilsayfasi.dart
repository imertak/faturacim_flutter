import 'dart:async';
import 'dart:io';

import 'package:faturacim/globals.dart';
import 'package:faturacim/profilduzenleme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilSayfasi extends StatefulWidget {
  const ProfilSayfasi({Key? key}) : super(key: key);

  @override
  _ProfilSayfasiState createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  bool _bildirimAyari = true;
  bool _karanlikMod = false;

  // Kullanıcı bilgileri için değişkenler
  String _fullName = 'Yükleniyor...';
  String _email = '';
  String _profilResmiUrl = 'https://randomuser.me/api/portraits/women/44.jpg';
  bool _isLoading = true;
  String _errorMessage = '';

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
        // Token gerekiyorsa ekleyin
        // 'Authorization': 'Bearer $token',
      };

      // GET metodunda body kullanılmaz
      final response = await http
          .get(url, headers: headers)
          .timeout(Duration(seconds: 30));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Başarılı yanıt
        final userData = json.decode(response.body);

        setState(() {
          _fullName = userData['fullName'] ?? 'İsim Yok';
          _email = userData['email'] ?? '';
          _isLoading = false;
        });
      } else {
        // Hata durumu
        setState(() {
          _errorMessage =
              'Kullanıcı bilgileri alınamadı: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on TimeoutException {
      setState(() {
        _errorMessage = 'İstek zaman aşımına uğradı';
        _isLoading = false;
      });
    } on SocketException {
      setState(() {
        _errorMessage = 'Ağ bağlantısı hatası';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Beklenmedik bir hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = theme == 'dark';

    // Loading durumu
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDarkTheme ? Colors.black : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: isDarkTheme ? Colors.white : Color(0xFF2E7D6B),
          ),
        ),
      );
    }

    // Hata durumu
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: isDarkTheme ? Colors.black : Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage,
                style: TextStyle(
                  color: isDarkTheme ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchUserInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkTheme ? Colors.grey[800] : Color(0xFF2E7D6B),
                ),
                child: Text(
                  'Tekrar Dene',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Mevcut profil sayfası UI'ı
    return Scaffold(
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkTheme ? Colors.grey[900] : Color(0xFF2E7D6B),
        title: Text(
          'PROFİLİM',
          style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
            onPressed: _profilDuzenle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(_profilResmiUrl),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        isDarkTheme ? Colors.grey[800] : Color(0xFF2E7D6B),
                    child: Icon(
                      Icons.camera_alt,
                      color: isDarkTheme ? Colors.white : Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                _fullName,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkTheme ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                _email,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkTheme ? Colors.white : Colors.grey[600],
                ),
              ),
              SizedBox(height: 30),

              // Ayarlar Bölümü
              _buildAyarSatiri(
                icon: Icons.notifications,
                baslik: 'Bildirimler',
                widget: CupertinoSwitch(
                  value: _bildirimAyari,
                  activeTrackColor:
                      isDarkTheme ? Colors.grey[800] : Color(0xFF2E7D6B),
                  onChanged: (bool value) {
                    setState(() {
                      _bildirimAyari = value;
                    });
                  },
                ),
              ),

              _buildAyarSatiri(
                icon: Icons.dark_mode,
                baslik: 'Karanlık Mod',
                widget: CupertinoSwitch(
                  value: _karanlikMod,
                  activeTrackColor:
                      isDarkTheme ? Colors.grey[800] : Color(0xFF2E7D6B),
                  onChanged: (bool value) {
                    setState(() {
                      _karanlikMod = value;
                    });
                    theme = _karanlikMod ? 'dark' : 'light';
                  },
                ),
              ),

              _buildAyarSatiri(
                icon: Icons.language,
                baslik: 'Dil Seçimi',
                widget: Text(
                  'Türkçe',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.grey[600],
                  ),
                ),
                onTap: _dilSecenekleri,
              ),

              _buildAyarSatiri(
                icon: Icons.security,
                baslik: 'Güvenlik',
                widget: Icon(
                  Icons.chevron_right,
                  color: isDarkTheme ? Colors.grey[400] : Colors.grey[600],
                ),
                onTap: _guvenlikAyarlari,
              ),

              SizedBox(height: 30),

              // Çıkış Butonu
              ElevatedButton(
                onPressed: _cikisYap,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkTheme ? Colors.red[800] : Color(0xFFFF6B6B),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: isDarkTheme ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAyarSatiri({
    required IconData icon,
    required String baslik,
    Widget? widget,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Color(0xFF2E7D6B)),
      ),
      title: Text(
        baslik,
        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
      ),
      trailing: widget ?? SizedBox.shrink(),
    );
  }

  void _profilDuzenle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfilDuzenleme()),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Profil Düzenleme Sayfası')));
  }

  void _dilSecenekleri() {
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
                'Dil Seçimi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              _buildDilSecenegi('Türkçe', true),
              _buildDilSecenegi('İngilizce', false),
              _buildDilSecenegi('Almanca', false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDilSecenegi(String dil, bool secili) {
    final isDarkTheme = theme == 'dark';

    return ListTile(
      title: Text(
        dil,
        style: TextStyle(color: isDarkTheme ? Colors.white : Colors.black),
      ),
      trailing: secili ? Icon(Icons.check, color: Color(0xFF2E7D6B)) : null,
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  void _guvenlikAyarlari() {
    // Güvenlik ayarları sayfasına yönlendirme
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Güvenlik Ayarları Sayfası')));
  }

  void _cikisYap() {
    // Çıkış işlemleri
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Çıkış Yap'),
            content: Text(
              'Uygulamadan çıkış yapmak istediğinizden emin misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Çıkış işlemleri burada yapılacak
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B6B),
                ),
                child: Text('Çıkış Yap'),
              ),
            ],
          ),
    );
  }
}
