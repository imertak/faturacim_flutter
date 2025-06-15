import 'dart:convert';
import 'package:faturacim/globals.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sayfa2.dart';

void main() {
  runApp(FaturaApp());
}

class FaturaApp extends StatelessWidget {
  const FaturaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fatura Uygulaması',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF2E7D6B),
        fontFamily: 'SF Pro Display',
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _message = '';
  bool _isIndividual = true;
  bool _isLoading = false;
  Future<void> _login() async {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'E-posta ve şifre boş olamaz.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
    });

    final Uri url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authLogin}');

    // Detaylı header ayarları
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Gerekirse ekstra headerlar
      // 'Authorization': 'Bearer token',
    };

    final Map<String, String> body = {'email': email, 'password': password};
    try {
      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body), // Explicit JSON encode
          )
          .timeout(Duration(seconds: 30)); // Timeout süresi arttırıldı

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData.containsKey('token') &&
            responseData['token'] != null &&
            responseData['token'].toString().isNotEmpty) {
          userEmail = email;
          authToken =
              responseData['token']
                  .toString(); // Token'ı global değişkene kaydet
          setState(() {
            _message = 'Giriş başarılı!';
            _isLoading = false;
          });

          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Sayfa2()),
          );
        } else {
          setState(() {
            _message = 'Geçersiz yanıt. Token bulunamadı.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _message =
              'Giriş başarısız. Hata kodu: ${response.statusCode}\nDetay: ${response.body}';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        if (error.toString().contains('TimeoutException')) {
          _message =
              'Bağlantı zaman aşımına uğradı. Sunucu erişilebilir değil.';
        } else if (error.toString().contains('SocketException')) {
          _message =
              'Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin.';
        } else {
          _message = 'Bağlantı hatası: $error';
        }
        _isLoading = false;
      });
      print('Login error details: $error');
    }
  }

  void _showRegisterModal() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _registerEmailController =
        TextEditingController();
    final TextEditingController _registerPasswordController =
        TextEditingController();
    final TextEditingController _confirmPasswordController =
        TextEditingController();
    final TextEditingController _phoneController = TextEditingController();
    final TextEditingController _birthDateController = TextEditingController();
    String _selectedGender = 'Kadın';
    DateTime _selectedBirthDate = DateTime(1990, 1, 1);
    String _registerMessage = '';
    bool _isRegisterLoading = false;

    Future<void> _register() async {
      final String name = _nameController.text.trim();
      final String email = _registerEmailController.text.trim();
      final String password = _registerPasswordController.text.trim();
      final String confirmPassword = _confirmPasswordController.text.trim();
      final String phone = _phoneController.text.trim();

      // Gelişmiş validasyon
      if (name.isEmpty) {
        setState(() {
          _registerMessage = 'Ad Soyad alanı boş bırakılamaz.';
        });
        return;
      }

      // Email regex doğrulaması
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        setState(() {
          _registerMessage = 'Lütfen geçerli bir e-posta adresi girin.';
        });
        return;
      }
      if (phone.isEmpty) {
        setState(() {
          _registerMessage = 'Telefon numarası boş bırakılamaz.';
        });
        return;
      }
      final phoneRegex = RegExp(r'^(05\d{9})$');
      if (!phoneRegex.hasMatch(phone.replaceAll(' ', ''))) {
        setState(() {
          _registerMessage = 'Geçerli bir telefon numarası girin.';
        });
        return;
      }

      // Doğum tarihi kontrolü
      if (_birthDateController.text.isEmpty) {
        setState(() {
          _registerMessage = 'Doğum tarihi boş bırakılamaz.';
        });
        return;
      }

      if (password.length < 6) {
        setState(() {
          _registerMessage = 'Şifre en az 6 karakter uzunluğunda olmalıdır.';
        });
        return;
      }

      if (password != confirmPassword) {
        setState(() {
          _registerMessage = 'Şifreler eşleşmiyor.';
        });
        return;
      }

      setState(() {
        _isRegisterLoading = true;
      });

      final Uri url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.authRegister}',
      );

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      final Map<String, String> body = {
        'FullName': name,
        'Email': email,
        'Password': password,
        'PhoneNumber': phone.replaceAll(' ', ''),
        'BirthDate': _selectedBirthDate.toIso8601String(),
        'Gender': _selectedGender.toLowerCase(),
      };

      try {
        final response = await http
            .post(url, headers: headers, body: jsonEncode(body))
            .timeout(Duration(seconds: 30));

        print('Response Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          setState(() {
            _registerMessage = 'Kayıt başarılı! Giriş yapabilirsiniz.';
            _isRegisterLoading = false;
          });

          // İsteğe bağlı: Otomatik giriş yapma
          _emailController.text = email;
          _passwordController.text = password;
          Navigator.pop(context); // Kayıt modalını kapat
          _showLoginModal(); // Giriş modalını aç
        } else {
          // Detaylı hata mesajı
          final Map<String, dynamic> errorResponse = jsonDecode(response.body);
          String errorMessage = 'Kayıt başarısız.';

          if (errorResponse.containsKey('errors')) {
            Map<String, dynamic> errors = errorResponse['errors'];

            // Hata mesajlarını birleştir
            errors.forEach((key, value) {
              errorMessage += '\n${value[0]}';
            });
          }

          setState(() {
            _registerMessage = errorMessage;
            _isRegisterLoading = false;
          });
        }
      } catch (error) {
        setState(() {
          _registerMessage = 'Bağlantı hatası: $error';
          _isRegisterLoading = false;
        });
        print('Register error: $error');
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Başlık
                      Text(
                        'Hesap Oluştur',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D6B),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 32),

                      // İsim alanı
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FFFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0F2EF),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Ad Soyad',
                            labelStyle: TextStyle(color: Color(0xFF6B9B8E)),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Color(0xFF6B9B8E),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // E-posta alanı
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FFFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0F2EF),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _registerEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'E-posta Adresi',
                            labelStyle: TextStyle(color: Color(0xFF6B9B8E)),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Color(0xFF6B9B8E),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Şifre alanı
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FFFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0F2EF),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _registerPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            labelStyle: TextStyle(color: Color(0xFF6B9B8E)),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(0xFF6B9B8E),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Şifre onay alanı
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FFFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0F2EF),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Şifre Tekrar',
                            labelStyle: TextStyle(color: Color(0xFF6B9B8E)),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(0xFF6B9B8E),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),
                      // Telefon Numarası
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FFFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0F2EF),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Telefon Numarası',
                            labelStyle: TextStyle(color: Color(0xFF6B9B8E)),
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: Color(0xFF6B9B8E),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Doğum Tarihi
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FFFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0F2EF),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _birthDateController,
                          readOnly: true,
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedBirthDate,
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: Color(0xFF2E7D6B),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );

                            if (pickedDate != null) {
                              setState(() {
                                _selectedBirthDate = pickedDate;
                                _birthDateController.text =
                                    '${pickedDate.day}/${pickedDate.month}/${pickedDate.year}';
                              });
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Doğum Tarihi',
                            labelStyle: TextStyle(color: Color(0xFF6B9B8E)),
                            prefixIcon: Icon(
                              Icons.cake_outlined,
                              color: Color(0xFF6B9B8E),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Cinsiyet Seçimi
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FFFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0F2EF),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: Color(0xFF6B9B8E),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Cinsiyet',
                                style: TextStyle(
                                  color: Color(0xFF6B9B8E),
                                  fontSize: 16,
                                ),
                              ),
                              Spacer(),
                              DropdownButton<String>(
                                value: _selectedGender,
                                underline: SizedBox(),
                                style: TextStyle(color: Color(0xFF2E7D6B)),
                                items:
                                    ['Kadın', 'Erkek']
                                        .map(
                                          (gender) => DropdownMenuItem(
                                            value: gender,
                                            child: Text(gender),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Kayıt butonu
                      SizedBox(height: 16),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isRegisterLoading
                                  ? null
                                  : () async {
                                    await _register();
                                    setModalState(() {});
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2E7D6B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              _isRegisterLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                  : Text(
                                    'Kayıt Ol',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),

                      // Hata/Başarı mesajı
                      if (_registerMessage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  _registerMessage.contains('başarılı')
                                      ? Color(0xFFE8F5E8)
                                      : Color(0xFFFFF4F4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _registerMessage,
                              style: TextStyle(
                                color:
                                    _registerMessage.contains('başarılı')
                                        ? Color(0xFF2E7D6B)
                                        : Color(0xFFD32F2F),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                      SizedBox(height: 16),

                      // Giriş yap linki
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Zaten hesabınız var mı? ',
                            style: TextStyle(color: Colors.grey),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _showLoginModal();
                            },
                            child: Text(
                              'Giriş Yap',
                              style: TextStyle(
                                color: Color(0xFF2E7D6B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLoginModal() {
    _emailController.clear();
    _passwordController.clear();
    setState(() {
      _message = '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Başlık
                      Text(
                        'Hesabınıza Giriş Yapın',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D6B),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 32),

                      // E-posta alanı
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FFFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0F2EF),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'E-posta Adresi',
                            labelStyle: TextStyle(color: Color(0xFF6B9B8E)),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Color(0xFF6B9B8E),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Şifre alanı
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FFFE),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE0F2EF),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Şifre',
                            labelStyle: TextStyle(color: Color(0xFF6B9B8E)),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(0xFF6B9B8E),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 24),

                      // Giriş butonu
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading
                                  ? null
                                  : () async {
                                    await _login();
                                    setModalState(() {});
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2E7D6B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child:
                              _isLoading
                                  ? CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  )
                                  : Text(
                                    'Giriş Yap',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                        ),
                      ),

                      // Hata/Başarı mesajı
                      if (_message.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  _message == 'Giriş başarılı!'
                                      ? Color(0xFFE8F5E8)
                                      : Color(0xFFFFF4F4),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _message,
                              style: TextStyle(
                                color:
                                    _message == 'Giriş başarılı!'
                                        ? Color(0xFF2E7D6B)
                                        : Color(0xFFD32F2F),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                      SizedBox(height: 24),

                      // Şifremi unuttum
                      TextButton(
                        onPressed: () {
                          // Şifremi unuttum işlevi
                        },
                        child: Text(
                          'Şifremi Unuttum',
                          style: TextStyle(
                            color: Color(0xFF6B9B8E),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Üst Kısım
                  Expanded(
                    flex: 7,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(height: 20),

                          // Toggle Buttons
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF0F9F7),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => _isIndividual = true,
                                        ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            _isIndividual
                                                ? Colors.white
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow:
                                            _isIndividual
                                                ? [
                                                  BoxShadow(
                                                    color: Color(
                                                      0xFF2E7D6B,
                                                    ).withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child: Text(
                                        'Bireysel',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight:
                                              _isIndividual
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                          color:
                                              _isIndividual
                                                  ? Color(0xFF2E7D6B)
                                                  : Color(0xFF6B9B8E),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => _isIndividual = false,
                                        ),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            !_isIndividual
                                                ? Colors.white
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(25),
                                        boxShadow:
                                            !_isIndividual
                                                ? [
                                                  BoxShadow(
                                                    color: Color(
                                                      0xFF2E7D6B,
                                                    ).withOpacity(0.1),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 2),
                                                  ),
                                                ]
                                                : null,
                                      ),
                                      child: Text(
                                        'Kurumsal',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight:
                                              !_isIndividual
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                          color:
                                              !_isIndividual
                                                  ? Color(0xFF2E7D6B)
                                                  : Color(0xFF6B9B8E),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 40),

                          // Profil Resmi
                          Stack(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF2E7D6B),
                                      Color(0xFF4A9D8E),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF8A50),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 20),

                          // Hoşgeldin Metni
                          Text(
                            'Merhaba',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Fatura Kullanıcısı',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),

                          SizedBox(height: 30),

                          // Giriş Butonu
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _showLoginModal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF2E7D6B),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          // Giriş Butonu altına ekleyin
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Hesabınız yok mu? ',
                                style: TextStyle(color: Colors.grey),
                              ),
                              GestureDetector(
                                onTap: _showRegisterModal,
                                child: Text(
                                  'Kayıt Ol',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D6B),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Alt Kısım - Gradient Panel
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2E7D6B), Color(0xFF4A9D8E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Column(
                      children: [
                        // İkonlar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBottomIcon(
                              Icons.receipt_long,
                              'Fatura\nOluştur',
                              Color(0xFFFF8A50),
                            ),
                            _buildBottomIcon(
                              Icons.qr_code_scanner,
                              'QR\nTara',
                              Color(0xFF70B7A8),
                            ),
                            _buildBottomIcon(
                              Icons.history,
                              'Fatura\nGeçmişi',
                              Color(0xFFFFB366),
                            ),
                            _buildBottomIcon(
                              Icons.analytics,
                              'Raporlar',
                              Color(0xFF85C4B8),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Vergi bilgisi
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'KDV %20 | ÖTV bilgileri güncel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomIcon(IconData icon, String label, Color iconColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
