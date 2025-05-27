import 'dart:io';
import 'dart:typed_data';
import 'package:faturacim/kamerasayfasi2.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class KameraSayfasi extends StatefulWidget {
  @override
  _KameraSayfasiState createState() => _KameraSayfasiState();
}

class _KameraSayfasiState extends State<KameraSayfasi> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String _imagePath = '';
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(_cameras![0], ResolutionPreset.high);
        await _controller!.initialize();
        if (mounted) setState(() {});
      } else {
        print('Cihazda kamera bulunamadı.');
      }
    } catch (e) {
      print('Kamera başlatılamadı: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<String> getDesktopPath() async {
    if (kIsWeb) {
      // Web'de dosya yolu kullanılamaz
      return '';
    } else {
      final Directory docsDir = await getApplicationDocumentsDirectory();
      final String userDir = Directory(docsDir.path).parent.path;
      final String desktopPath = '$userDir/Desktop/fatura';
      return desktopPath;
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture)
      return;

    setState(() => _isTakingPicture = true);

    try {
      print('Fotoğraf çekiliyor...');
      final XFile rawFile = await _controller!.takePicture();
      print('Fotoğraf çekildi: ${rawFile.name}');

      if (kIsWeb) {
        // Web'de fotoğrafı byte olarak al ve Cloudinary'ye yükle
        Uint8List fileBytes = await rawFile.readAsBytes();
        await _sendImageBytesToServer(fileBytes, rawFile.name);
      } else {
        // ─── DEĞİŞTİRİLMESİ GEREKEN KISIM BAŞLANGICI ───

        // 1️⃣ Uygulama belgeler dizinini alıyoruz
        final Directory docsDir = await getApplicationDocumentsDirectory();

        // 2️⃣ Bu dizin altında 'faturalar' adlı bir klasör tanımlıyoruz
        final String saveDirPath = '${docsDir.path}/faturalar';
        final Directory saveDir = Directory(saveDirPath);

        // 3️⃣ Klasör yoksa oluşturuyoruz
        if (!await saveDir.exists()) {
          await saveDir.create(recursive: true);
        }

        // 4️⃣ Dosya adını ve tam yolu belirleyip kaydediyoruz
        final String filePath =
            '$saveDirPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await rawFile.saveTo(filePath);

        // 5️⃣ Kaydettikten sonra sunucuya gönder
        await _sendImageToServer(filePath);

        // ─── DEĞİŞTİRİLMESİ GEREKEN KISIM SONU ───
      }
    } catch (e, stacktrace) {
      print('Fotoğraf alınırken hata: $e');
      print('Stacktrace: $stacktrace');

      // Hata durumu için örnek data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => KameraSayfasi2(
                imagePath: '', // web'de dosya yolu olmayacak
                faturaData: {
                  'sirket': 'Hata - Örnek Şirket',
                  'tutar': '0,00 TL',
                  'sonOdeme': DateTime.now()
                      .add(Duration(days: 30))
                      .toString()
                      .substring(0, 10),
                  'kategori': 'Diğer',
                  'ocrText': 'Fatura işlenirken hata oluştu',
                },
              ),
        ),
      );
    } finally {
      setState(() => _isTakingPicture = false);
    }
  }

  // Web'de fotoğrafı doğrudan byte olarak upload eden fonksiyon
  Future<void> _sendImageBytesToServer(
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      // ÖNCELİKLE CLOUDINARY'YE YÜKLEYELİM
      print('🌐 Web platformunda Cloudinary yükleme başlıyor...');
      String? cloudinaryUrl = await uploadToCloudinaryBytes(
        fileBytes,
        fileName,
      );

      if (cloudinaryUrl != null) {
        print('✅ Cloudinary yükleme başarılı: $cloudinaryUrl');
      } else {
        print('❌ Cloudinary yükleme başarısız');
      }

      // SONRA API'YE GÖNDERELİM
      final Uri url = Uri.parse(
        'http://invoicetojson-app-1748249131.eastus.azurecontainer.io:8000/api/process-file',
      );

      // Dosya uzantısını kontrol et ve düzenle
      String fileExtension = fileName.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'bmp', 'webp'].contains(fileExtension)) {
        fileExtension = 'jpg'; // Varsayılan olarak jpg yap
        fileName = 'image.$fileExtension';
      }

      var request = http.MultipartRequest('POST', url);
      request.headers['accept'] = 'application/json';

      // Dosya boyutunu ve türünü kontrol et
      print('Dosya Bayt Sayısı: ${fileBytes.length}');
      print('Dosya Adı: $fileName');
      print('Dosya Uzantısı: $fileExtension');

      // Fotoğrafı multipart dosya olarak ekle (fromBytes ile)
      var multipartFile = http.MultipartFile.fromBytes(
        'file', // Sunucunun beklediği alan adı
        fileBytes,
        filename: fileName,
        contentType: MediaType('image', fileExtension),
      );
      request.files.add(multipartFile);

      // İlave hata ayıklama bilgileri
      request.fields['filename'] = fileName;

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Sunucu Yanıt Kodu: ${response.statusCode}');
      print('Sunucu Yanıt Gövdesi: $responseBody');

      if (response.statusCode == 200) {
        final Map<String, dynamic> apiResponse = json.decode(responseBody);

        // Hata durumunu kontrol et
        if (apiResponse['status'] == 'error') {
          throw Exception(apiResponse['message']);
        }

        Map<String, dynamic> faturaData = _parseOCRResults(apiResponse);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => KameraSayfasi2(
                  imagePath: '', // Web'de dosya yolu yok
                  faturaData: faturaData,
                ),
          ),
        );
      } else {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      print('Fatura gönderme hatası detayları: $e');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => KameraSayfasi2(
                imagePath: '',
                faturaData: {
                  'sirket': 'Bağlantı Hatası',
                  'tutar': '0,00 TL',
                  'sonOdeme': DateTime.now()
                      .add(Duration(days: 30))
                      .toString()
                      .substring(0, 10),
                  'kategori': 'Diğer',
                  'ocrText': 'Dosya gönderme hatası: $e',
                },
              ),
        ),
      );
    }
  }

  // WEB İÇİN YENİ CLOUDINARY FONKSİYONU (BYTES İLE)
  Future<String?> uploadToCloudinaryBytes(
    Uint8List fileBytes,
    String fileName,
  ) async {
    try {
      print('📤 Cloudinary yükleme başlatılıyor... (Web - Bytes)');

      // Web için FormData kullanarak yükleme
      final cloudinaryUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/dtrqe9lua/image/upload',
      );

      // Dosya uzantısını kontrol et
      String fileExtension = fileName.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'bmp', 'webp'].contains(fileExtension)) {
        fileExtension = 'jpg';
        fileName = 'image.$fileExtension';
      }

      // Cloudinary için gerekli form verilerini hazırla
      var formData = {
        'upload_preset': 'unsigned_preset',
        'file': base64Encode(fileBytes), // Base64 encode et
      };

      print('⏳ Cloudinary yanıt bekleniyor...');
      var response = await http.post(cloudinaryUrl, body: formData);

      print('📡 Cloudinary yanıt kodu: ${response.statusCode}');

      if (response.statusCode == 200) {
        var result = json.decode(response.body);
        String cloudinaryImageUrl = result['secure_url'];
        print('✅ Cloudinary yükleme başarılı: $cloudinaryImageUrl');
        return cloudinaryImageUrl;
      } else {
        print('❌ Cloudinary yükleme başarısız: ${response.statusCode}');
        print('Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('🛑 Cloudinary hatası: $e');
      return null;
    }
  }

  // DESKTOP/MOBİL İÇİN ESKİ CLOUDINARY FONKSİYONU (DOSYA YOLU İLE)
  Future<String?> uploadToCloudinary(String imagePath) async {
    try {
      print('📤 Cloudinary yükleme başlatılıyor... (Desktop/Mobile - Path)');

      final cloudinaryUrl = Uri.parse(
        'https://api.cloudinary.com/v1_1/dtrqe9lua/image/upload',
      );

      var request = http.MultipartRequest('POST', cloudinaryUrl);
      request.fields['upload_preset'] = 'unsigned_preset';
      request.files.add(await http.MultipartFile.fromPath('file', imagePath));

      print('⏳ Yanıt bekleniyor...');
      var response = await request.send();

      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var result = json.decode(responseBody);
        String cloudinaryImageUrl = result['secure_url'];
        print('✅ Cloudinary yükleme başarılı: $cloudinaryImageUrl');
        return cloudinaryImageUrl;
      } else {
        print('❌ Cloudinary yükleme başarısız: ${response.statusCode}');
        print('Body: $responseBody');
        return null;
      }
    } catch (e) {
      print('🛑 Cloudinary hatası: $e');
      return null;
    }
  }

  Future<void> _sendImageToServer(String imagePath) async {
    try {
      // ÖNCELİKLE CLOUDINARY'YE YÜKLEYELİM
      print('🖥️ Desktop/Mobile platformunda Cloudinary yükleme başlıyor...');
      String? cloudinaryUrl = await uploadToCloudinary(imagePath);

      if (cloudinaryUrl != null) {
        print('✅ Cloudinary yükleme başarılı: $cloudinaryUrl');
      } else {
        print('❌ Cloudinary yükleme başarısız');
      }

      // SONRA API'YE GÖNDERELİM
      final Uri url = Uri.parse(
        'http://invoicetojson-app-1748249131.eastus.azurecontainer.io:8000/api/process-file',
      );

      var request = http.MultipartRequest('POST', url);
      request.headers['accept'] = 'application/json';
      request.headers['Content-Type'] = 'multipart/form-data';

      // Dosyayı multipart olarak ekle
      var file = await http.MultipartFile.fromPath('file', imagePath);
      request.files.add(file);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print('Fatura başarıyla işlendi: $responseBody');

        // API'den gelen response'u parse et
        final Map<String, dynamic> apiResponse = json.decode(responseBody);

        // OCR sonuçlarını parse et
        Map<String, dynamic> faturaData = _parseOCRResults(apiResponse);

        // KameraSayfasi2'ye yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => KameraSayfasi2(
                  imagePath: imagePath,
                  faturaData: faturaData,
                ),
          ),
        );
      } else {
        print('Fatura işlenemedi: ${response.statusCode} - $responseBody');

        // Hata durumunda örnek datayla yönlendir
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => KameraSayfasi2(
                  imagePath: imagePath,
                  faturaData: {
                    'sirket': 'İşleme Hatası',
                    'tutar': '0,00 TL',
                    'sonOdeme': DateTime.now()
                        .add(Duration(days: 30))
                        .toString()
                        .substring(0, 10),
                    'kategori': 'Diğer',
                    'ocrText': 'Sunucu hatası: ${response.statusCode}',
                  },
                ),
          ),
        );
      }
    } catch (e) {
      print('Fatura gönderme hatası: $e');

      // Hata durumunda örnek datayla yönlendir
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => KameraSayfasi2(
                imagePath: imagePath,
                faturaData: {
                  'sirket': 'Bağlantı Hatası',
                  'tutar': '0,00 TL',
                  'sonOdeme': DateTime.now()
                      .add(Duration(days: 30))
                      .toString()
                      .substring(0, 10),
                  'kategori': 'Diğer',
                  'ocrText': 'Bağlantı hatası: $e',
                },
              ),
        ),
      );
    }
  }

  Map<String, dynamic> _parseOCRResults(Map<String, dynamic> apiResponse) {
    try {
      // API response'undan results array'ini al
      List<dynamic> results = apiResponse['results'] ?? [];

      if (results.isNotEmpty) {
        Map<String, dynamic> firstResult = results[0];
        String ocrText = firstResult['ocr_text'] ?? '';

        // OCR metninden fatura bilgilerini çıkar
        Map<String, dynamic> extractedData = _extractInvoiceInfo(ocrText);

        return {
          'sirket': extractedData['sirket'] ?? 'Tanımlanamadı',
          'tutar': extractedData['tutar'] ?? '0,00 TL',
          'sonOdeme':
              extractedData['sonOdeme'] ??
              DateTime.now()
                  .add(Duration(days: 30))
                  .toString()
                  .substring(0, 10),
          'kategori': extractedData['kategori'] ?? 'Diğer',
          'faturaNumarasi': extractedData['faturaNumarasi'] ?? 'N/A',
          'ocrText': ocrText,
          'imagePath': firstResult['image_path'] ?? '',
          'processId': apiResponse['process_id'] ?? '',
          'timestamp': apiResponse['timestamp'] ?? '',
        };
      }
    } catch (e) {
      print('OCR sonuçları parse edilirken hata: $e');
    }

    // Varsayılan değerler
    return {
      'sirket': 'Tanımlanamadı',
      'tutar': '0,00 TL',
      'sonOdeme': DateTime.now()
          .add(Duration(days: 30))
          .toString()
          .substring(0, 10),
      'kategori': 'Diğer',
      'faturaNumarasi': 'N/A',
      'ocrText': 'OCR metni alınamadı',
    };
  }

  Map<String, dynamic> _extractInvoiceInfo(String ocrText) {
    Map<String, dynamic> info = {};

    // OCR metnini küçük harfe çevir ve satırlara ayır
    String lowerText = ocrText.toLowerCase();
    List<String> lines = ocrText.split('\n');

    // Şirket adını bulmaya çalış (genellikle ilk satırlarda)
    for (int i = 0; i < lines.length && i < 5; i++) {
      if (lines[i].trim().isNotEmpty &&
          !lines[i].toLowerCase().contains('fatura') &&
          !lines[i].toLowerCase().contains('invoice') &&
          !RegExp(r'\d+[.,]\d+').hasMatch(lines[i])) {
        info['sirket'] = lines[i].trim();
        break;
      }
    }

    // Tutarı bulmaya çalış (₺, TL, tl içeren veya para formatındaki sayılar)
    RegExp amountRegex = RegExp(
      r'(\d+[.,]\d+)\s*(₺|tl|türk lirası)',
      caseSensitive: false,
    );
    Match? amountMatch = amountRegex.firstMatch(lowerText);
    if (amountMatch != null) {
      String amount = amountMatch.group(1)!.replaceAll(',', '.');
      info['tutar'] = '$amount TL';
    } else {
      // Alternatif: Sadece para formatındaki sayıları ara
      RegExp numberRegex = RegExp(r'\d+[.,]\d{2}');
      Iterable<Match> matches = numberRegex.allMatches(ocrText);
      if (matches.isNotEmpty) {
        String amount = matches.last.group(0)!.replaceAll(',', '.');
        info['tutar'] = '$amount TL';
      }
    }

    // Tarih bulmaya çalış
    RegExp dateRegex = RegExp(r'\d{1,2}[./\-]\d{1,2}[./\-]\d{2,4}');
    Match? dateMatch = dateRegex.firstMatch(ocrText);
    if (dateMatch != null) {
      info['sonOdeme'] = dateMatch.group(0);
    }

    // Kategori belirleme (OCR metnindeki anahtar kelimelere göre)
    if (lowerText.contains('elektrik') || lowerText.contains('electric')) {
      info['kategori'] = 'Elektrik';
    } else if (lowerText.contains('su') || lowerText.contains('water')) {
      info['kategori'] = 'Su';
    } else if (lowerText.contains('doğalgaz') || lowerText.contains('gaz')) {
      info['kategori'] = 'Doğalgaz';
    } else if (lowerText.contains('telefon') ||
        lowerText.contains('telekom') ||
        lowerText.contains('iletişim')) {
      info['kategori'] = 'İletişim';
    } else if (lowerText.contains('internet')) {
      info['kategori'] = 'İnternet';
    } else {
      info['kategori'] = 'Diğer';
    }

    // Fatura numarası bulmaya çalış
    RegExp invoiceNumberRegex = RegExp(
      r'(fatura|invoice)\s*(:|\s)\s*([A-Z0-9]+)',
      caseSensitive: false,
    );
    Match? invoiceMatch = invoiceNumberRegex.firstMatch(ocrText);
    if (invoiceMatch != null) {
      info['faturaNumarasi'] = invoiceMatch.group(3);
    }

    return info;
  }

  Widget _buildCameraOverlay() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF66B3A0), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 100),
      child: Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF66B3A0),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
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
          'TARA',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Üst bilgi alanı
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              children: [
                const Icon(
                  Icons.receipt_long,
                  size: 32,
                  color: Color(0xFF66B3A0),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Faturayı çerçeve içine alın',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fatura bilgileri otomatik olarak tanınacak',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          // Kamera önizleme alanı
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    CameraPreview(_controller!),
                    _buildCameraOverlay(),
                  ],
                ),
              ),
            ),
          ),

          // Çekilen fotoğraf önizlemesi
          if (_imagePath.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_imagePath),
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fatura başarıyla tarandı',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                        Text(
                          'İşleniyor...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF66B3A0),
                    size: 20,
                  ),
                ],
              ),
            ),

          // Alt buton alanı
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Galeri butonu
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Galeri fonksiyonu
                      },
                      icon: const Icon(
                        Icons.photo_library,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),

                  // Ana çekim butonu
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF66B3A0),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF66B3A0).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: _takePicture,
                        child: Container(
                          width: 70,
                          height: 70,
                          child:
                              _isTakingPicture
                                  ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                  )
                                  : const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                        ),
                      ),
                    ),
                  ),

                  // Flash butonu
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Flash toggle fonksiyonu
                      },
                      icon: const Icon(
                        Icons.flash_off,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
