import 'package:faturacim/profilduzenleme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class ProfilSayfasi extends StatefulWidget {
  @override
  _ProfilSayfasiState createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  bool _bildirimAyari = true;
  bool _karanlikMod = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF2E7D6B),
        foregroundColor: Colors.white,
        title: Text('PROFİLİM'),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.edit), onPressed: _profilDuzenle),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profil Fotoğrafı
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(
                  'https://randomuser.me/api/portraits/women/44.jpg',
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF2E7D6B),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Ayşe Yılmaz',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                'ayse.yilmaz@email.com',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              SizedBox(height: 30),

              // Ayarlar Bölümü
              _buildAyarSatiri(
                icon: Icons.notifications,
                baslik: 'Bildirimler',
                widget: CupertinoSwitch(
                  value: _bildirimAyari,
                  activeColor: Color(0xFF2E7D6B),
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
                  activeColor: Color(0xFF2E7D6B),
                  onChanged: (bool value) {
                    setState(() {
                      _karanlikMod = value;
                    });
                  },
                ),
              ),

              _buildAyarSatiri(
                icon: Icons.language,
                baslik: 'Dil Seçimi',
                widget: Text(
                  'Türkçe',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                onTap: _dilSecenekleri,
              ),

              _buildAyarSatiri(
                icon: Icons.security,
                baslik: 'Güvenlik',
                widget: Icon(Icons.chevron_right, color: Colors.grey[600]),
                onTap: _guvenlikAyarlari,
              ),

              SizedBox(height: 30),

              // Çıkış Butonu
              ElevatedButton(
                onPressed: _cikisYap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF6B6B),
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Çıkış Yap',
                  style: TextStyle(
                    color: Colors.white,
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
    return ListTile(
      title: Text(dil),
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
