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
  const KameraSayfasi({super.key});

  @override
  _KameraSayfasiState createState() => _KameraSayfasiState();
}

class _KameraSayfasiState extends State<KameraSayfasi> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  final String _imagePath = '';
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

  Future<String> getAccessibleStoragePath() async {
    if (kIsWeb) {
      return '';
    } else {
      Directory? extDir =
          await getExternalStorageDirectory(); // Android için daha görünür
      if (extDir != null) {
        final String invoiceDir = '${extDir.path}/Faturalar';
        final Directory dir = Directory(invoiceDir);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
        return invoiceDir;
      } else {
        // fallback
        final Directory docsDir = await getApplicationDocumentsDirectory();
        final String fallbackDir = '${docsDir.path}/faturalar';
        final Directory fallback = Directory(fallbackDir);
        if (!await fallback.exists()) {
          await fallback.create(recursive: true);
        }
        return fallbackDir;
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

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
        final String saveDirPath = await getAccessibleStoragePath();

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

    try {
      // 1. Toplam tutarı çıkar (öncelik sırasına göre)
      String totalAmount = _extractTotalAmount(ocrText);

      // 2. Menu itemlarını çıkar
      List<Map<String, String>> menuItems = _extractMenuItems(ocrText);

      // 3. Ödeme bilgilerini çıkar
      Map<String, String> paymentInfo = _extractPaymentInfo(ocrText);

      // 4. Şirket/İşletme adını belirle
      String companyName = _determineBusinessName(menuItems, ocrText);

      // 5. Kategori belirle
      String category = _determineBusinessCategory(menuItems, companyName);

      // 6. Fatura numarası oluştur
      String invoiceNumber = _generateInvoiceNumber();

      // 7. Son ödeme tarihi
      String dueDate = _calculateDueDate();

      info['sirket'] = companyName;
      info['tutar'] = totalAmount;
      info['kategori'] = category;
      info['faturaNumarasi'] = invoiceNumber;
      info['sonOdeme'] = dueDate;

      // Debug için ek bilgiler
      info['_menuItemCount'] = menuItems.length;
      info['_paymentMethod'] = paymentInfo['method'] ?? 'unknown';
    } catch (e) {
      print('Invoice info extraction error: $e');
    }

    return info;
  }

  String _extractTotalAmount(String ocrText) {
    try {
      // Öncelik 1: <s_total_price> - Ana toplam
      RegExp totalPriceRegex = RegExp(
        r'<s_total_price>\s*([\d,.\s]+)\s*</s_total_price>',
      );
      Match? totalMatch = totalPriceRegex.firstMatch(ocrText);

      if (totalMatch != null) {
        String amount = totalMatch.group(1)?.trim() ?? '';
        String formattedAmount = _formatAmount(amount);
        if (formattedAmount != '0,00 TL') {
          return formattedAmount;
        }
      }

      // Öncelik 2: <s_subtotal_price> - Alt toplam
      RegExp subTotalRegex = RegExp(
        r'<s_subtotal_price>\s*([\d,.\s]+)\s*</s_subtotal_price>',
      );
      Match? subTotalMatch = subTotalRegex.firstMatch(ocrText);

      if (subTotalMatch != null) {
        String amount = subTotalMatch.group(1)?.trim() ?? '';
        String formattedAmount = _formatAmount(amount);
        if (formattedAmount != '0,00 TL') {
          return formattedAmount;
        }
      }

      // Öncelik 3: <s_cashprice> - Nakit ödeme
      RegExp cashPriceRegex = RegExp(
        r'<s_cashprice>\s*([\d,.\s]+)\s*</s_cashprice>',
      );
      Match? cashMatch = cashPriceRegex.firstMatch(ocrText);

      if (cashMatch != null) {
        String amount = cashMatch.group(1)?.trim() ?? '';
        String formattedAmount = _formatAmount(amount);
        if (formattedAmount != '0,00 TL') {
          return formattedAmount;
        }
      }

      // Öncelik 4: <s_creditcardprice> - Kredi kartı ödeme
      RegExp creditCardRegex = RegExp(
        r'<s_creditcardprice>\s*([\d,.\s]+)\s*</s_creditcardprice>',
      );
      Match? creditMatch = creditCardRegex.firstMatch(ocrText);

      if (creditMatch != null) {
        String amount = creditMatch.group(1)?.trim() ?? '';
        String formattedAmount = _formatAmount(amount);
        if (formattedAmount != '0,00 TL') {
          return formattedAmount;
        }
      }

      // Öncelik 5: Menu itemlarının fiyatlarını topla
      List<Map<String, String>> menuItems = _extractMenuItems(ocrText);
      double totalFromItems = 0;

      for (Map<String, String> item in menuItems) {
        String? price = item['price'];
        if (price != null) {
          double? itemPrice = _parseAmount(price);
          if (itemPrice != null) {
            totalFromItems += itemPrice;
          }
        }
      }

      if (totalFromItems > 0) {
        return _formatAmountFromDouble(totalFromItems);
      }
    } catch (e) {
      print('Total amount extraction error: $e');
    }

    return '0,00 TL';
  }

  List<Map<String, String>> _extractMenuItems(String ocrText) {
    List<Map<String, String>> items = [];

    try {
      // <s_menu> bloğunu bul
      RegExp menuRegex = RegExp(r'<s_menu>(.*?)</s_menu>', dotAll: true);
      Match? menuMatch = menuRegex.firstMatch(ocrText);

      if (menuMatch != null) {
        String menuContent = menuMatch.group(1) ?? '';

        // <sep/> ile ayrılmış itemları ayır
        List<String> itemBlocks = menuContent.split('<sep/>');

        for (String block in itemBlocks) {
          if (block.trim().isEmpty) continue;

          Map<String, String> item = {};

          // Ürün adını çıkar
          RegExp nameRegex = RegExp(r'<s_nm>\s*(.*?)\s*</s_nm>');
          Match? nameMatch = nameRegex.firstMatch(block);
          if (nameMatch != null) {
            String name = nameMatch.group(1)?.trim() ?? '';
            if (name.isNotEmpty) {
              item['name'] = name;
            }
          }

          // Adet bilgisini çıkar
          RegExp countRegex = RegExp(r'<s_cnt>\s*(.*?)\s*</s_cnt>');
          Match? countMatch = countRegex.firstMatch(block);
          if (countMatch != null) {
            String count = countMatch.group(1)?.trim() ?? '';
            item['count'] = count;
          }

          // Fiyat bilgisini çıkar
          RegExp priceRegex = RegExp(r'<s_price>\s*(.*?)\s*</s_price>');
          Match? priceMatch = priceRegex.firstMatch(block);
          if (priceMatch != null) {
            String price = priceMatch.group(1)?.trim() ?? '';
            item['price'] = price;
          }

          // Birim fiyat varsa çıkar
          RegExp unitPriceRegex = RegExp(
            r'<s_unitprice>\s*(.*?)\s*</s_unitprice>',
          );
          Match? unitPriceMatch = unitPriceRegex.firstMatch(block);
          if (unitPriceMatch != null) {
            String unitPrice = unitPriceMatch.group(1)?.trim() ?? '';
            item['unitPrice'] = unitPrice;
          }

          // Alt bilgi varsa çıkar (=*MEDIUM*= gibi)
          RegExp subInfoRegex = RegExp(
            r'<s_sub>\s*<s_nm>\s*(.*?)\s*</s_nm>\s*</s_sub>',
          );
          Match? subInfoMatch = subInfoRegex.firstMatch(block);
          if (subInfoMatch != null) {
            String subInfo = subInfoMatch.group(1)?.trim() ?? '';
            item['subInfo'] = subInfo;
          }

          // En az ürün adı varsa listeye ekle
          if (item.containsKey('name') && item['name']!.isNotEmpty) {
            items.add(item);
          }
        }
      }
    } catch (e) {
      print('Menu items extraction error: $e');
    }

    return items;
  }

  Map<String, String> _extractPaymentInfo(String ocrText) {
    Map<String, String> paymentInfo = {};

    try {
      // Nakit ödeme kontrolü
      RegExp cashRegex = RegExp(
        r'<s_cashprice>\s*([\d,.\s]+)\s*</s_cashprice>',
      );
      if (cashRegex.hasMatch(ocrText)) {
        paymentInfo['method'] = 'cash';

        // Para üstü varsa
        RegExp changeRegex = RegExp(
          r'<s_changeprice>\s*([\d,.\s]+)\s*</s_changeprice>',
        );
        Match? changeMatch = changeRegex.firstMatch(ocrText);
        if (changeMatch != null) {
          paymentInfo['change'] = changeMatch.group(1)?.trim() ?? '';
        }
      }

      // Kredi kartı ödeme kontrolü
      RegExp creditCardRegex = RegExp(
        r'<s_creditcardprice>\s*([\d,.\s]+)\s*</s_creditcardprice>',
      );
      if (creditCardRegex.hasMatch(ocrText)) {
        paymentInfo['method'] = 'credit_card';
      }

      // Servis ücreti
      RegExp serviceRegex = RegExp(
        r'<s_service_price>\s*([\d,.\s]+)\s*</s_service_price>',
      );
      Match? serviceMatch = serviceRegex.firstMatch(ocrText);
      if (serviceMatch != null) {
        paymentInfo['service'] = serviceMatch.group(1)?.trim() ?? '';
      }

      // Vergi
      RegExp taxRegex = RegExp(r'<s_tax_price>\s*([\d,.\s]+)\s*</s_tax_price>');
      Match? taxMatch = taxRegex.firstMatch(ocrText);
      if (taxMatch != null) {
        paymentInfo['tax'] = taxMatch.group(1)?.trim() ?? '';
      }
    } catch (e) {
      print('Payment info extraction error: $e');
    }

    return paymentInfo;
  }

  String _determineBusinessName(
    List<Map<String, String>> menuItems,
    String ocrText,
  ) {
    try {
      if (menuItems.isEmpty) return 'İşletme';

      // Menu item isimlerinden işletme türünü analiz et
      List<String> itemNames =
          menuItems.map((item) => item['name'] ?? '').toList();
      String allItems = itemNames.join(' ').toLowerCase();

      // Spesifik marka/restoran isimleri
      if (allItems.contains('dumdum')) {
        return 'DumDum Tea';
      }

      // Japonca/Asya terimleri (ocha, wagyu, harami)
      if (allItems.contains('ocha') ||
          allItems.contains('wagyu') ||
          allItems.contains('harami') ||
          allItems.contains('jyo')) {
        return 'Japon Restoranı';
      }

      // Endonezya mutfağı (ikan, cumi, lumpia)
      if (allItems.contains('ikan') ||
          allItems.contains('cumi') ||
          allItems.contains('lumpia') ||
          allItems.contains('pocai')) {
        return 'Endonezya Restoranı';
      }

      // Thai mutfağı
      if (allItems.contains('thai')) {
        return 'Thai Restoranı';
      }

      // Kahve/çay evi
      if (allItems.contains('tea') ||
          allItems.contains('coffee') ||
          allItems.contains('iced') &&
              (allItems.contains('tea') || allItems.contains('green'))) {
        return 'Kafe/Çay Evi';
      }

      // Pastane/bakery
      if (allItems.contains('cream') && allItems.contains('cheese') ||
          allItems.contains('almond')) {
        return 'Pastane';
      }

      // Et restoranı
      if (allItems.contains('wagyu') ||
          allItems.contains('steak') ||
          allItems.contains('sirloin') ||
          allItems.contains('beef')) {
        return 'Et Restoranı';
      }

      // Deniz ürünleri
      if (allItems.contains('ikan') ||
          allItems.contains('cumi') ||
          allItems.contains('fish') ||
          allItems.contains('seafood')) {
        return 'Deniz Ürünleri Restoranı';
      }

      // Genel restoran/cafe
      if (itemNames.length > 1) {
        return 'Restoran/Kafe';
      }

      return 'İşletme';
    } catch (e) {
      print('Business name determination error: $e');
      return 'İşletme';
    }
  }

  String _determineBusinessCategory(
    List<Map<String, String>> menuItems,
    String businessName,
  ) {
    try {
      String lowerBusinessName = businessName.toLowerCase();

      // İşletme adından kategori belirle
      if (lowerBusinessName.contains('kafe') ||
          lowerBusinessName.contains('çay') ||
          lowerBusinessName.contains('coffee') ||
          lowerBusinessName.contains('tea')) {
        return 'Kafe/Bar';
      }

      if (lowerBusinessName.contains('restoran') ||
          lowerBusinessName.contains('restaurant')) {
        return 'Restoran';
      }

      if (lowerBusinessName.contains('pastane') ||
          lowerBusinessName.contains('bakery') ||
          lowerBusinessName.contains('fırın')) {
        return 'Gıda/Market';
      }

      // Menu itemlarından kategori belirle
      if (menuItems.isNotEmpty) {
        List<String> itemNames =
            menuItems.map((item) => item['name'] ?? '').toList();
        String allItems = itemNames.join(' ').toLowerCase();

        // Yemek/içecek kategorileri
        bool hasFood =
            allItems.contains('rice') ||
            allItems.contains('steak') ||
            allItems.contains('salad') ||
            allItems.contains('soup') ||
            allItems.contains('ikan') ||
            allItems.contains('cumi') ||
            allItems.contains('lumpia') ||
            allItems.contains('nasi');

        bool hasDrinks =
            allItems.contains('tea') ||
            allItems.contains('coffee') ||
            allItems.contains('aqua') ||
            allItems.contains('iced');

        if (hasFood && hasDrinks) {
          return 'Restoran';
        } else if (hasFood) {
          return 'Restoran';
        } else if (hasDrinks) {
          return 'Kafe/Bar';
        }
      }

      // Varsayılan
      return 'Yemek/İçecek';
    } catch (e) {
      print('Business category determination error: $e');
      return 'Yemek/İçecek';
    }
  }

  String _generateInvoiceNumber() {
    try {
      // Tarih bazlı unique fatura numarası
      DateTime now = DateTime.now();
      String datePrefix =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      String timePrefix =
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      int randomSuffix = (now.millisecond * now.second) % 10000;

      return 'INV$datePrefix$timePrefix${randomSuffix.toString().padLeft(4, '0')}';
    } catch (e) {
      print('Invoice number generation error: $e');
      return 'INV${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }
  }

  String _calculateDueDate() {
    try {
      // 30 gün sonra son ödeme tarihi
      DateTime dueDate = DateTime.now().add(Duration(days: 30));
      return '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Due date calculation error: $e');
      return DateTime.now().add(Duration(days: 30)).toString().substring(0, 10);
    }
  }

  String _formatAmount(String rawAmount) {
    try {
      // Sadece sayı, nokta ve virgül karakterlerini bırak
      String cleanAmount = rawAmount.replaceAll(RegExp(r'[^\d,.]'), '');

      if (cleanAmount.isEmpty) return '0,00 TL';

      // Virgül ve nokta durumlarını handle et
      if (cleanAmount.contains(',') && cleanAmount.contains('.')) {
        // Hem virgül hem nokta varsa, son olanı ondalık ayırıcı olarak kabul et
        int lastComma = cleanAmount.lastIndexOf(',');
        int lastDot = cleanAmount.lastIndexOf('.');

        if (lastComma > lastDot) {
          // Virgül son ise, noktaları kaldır
          cleanAmount = cleanAmount.replaceAll('.', '');
          cleanAmount = cleanAmount.replaceAll(',', '.');
        } else {
          // Nokta son ise, virgülleri kaldır
          cleanAmount = cleanAmount.replaceAll(',', '');
        }
      } else if (cleanAmount.contains(',')) {
        // Sadece virgül var
        int commaCount = ','.allMatches(cleanAmount).length;
        if (commaCount == 1) {
          // Tek virgül varsa ondalık ayırıcı
          cleanAmount = cleanAmount.replaceAll(',', '.');
        } else {
          // Birden fazla virgül varsa son olanı ondalık ayırıcı
          int lastComma = cleanAmount.lastIndexOf(',');
          String beforeLastComma = cleanAmount
              .substring(0, lastComma)
              .replaceAll(',', '');
          String afterLastComma = cleanAmount.substring(lastComma + 1);
          cleanAmount = '$beforeLastComma.$afterLastComma';
        }
      }

      double? amount = double.tryParse(cleanAmount);
      if (amount != null && amount > 0) {
        return _formatAmountFromDouble(amount);
      }
    } catch (e) {
      print('Amount formatting error: $e');
    }

    return '0,00 TL';
  }

  String _formatAmountFromDouble(double amount) {
    // Türk Lirası formatında formatla (1.234,56 TL)
    String formatted = amount.toStringAsFixed(2);
    List<String> parts = formatted.split('.');

    String integerPart = parts[0];
    String decimalPart = parts[1];

    // Binlik ayırıcıları ekle
    if (integerPart.length > 3) {
      String reversed = integerPart.split('').reversed.join();
      List<String> chunks = [];
      for (int i = 0; i < reversed.length; i += 3) {
        int end = (i + 3 < reversed.length) ? i + 3 : reversed.length;
        chunks.add(reversed.substring(i, end));
      }
      integerPart = chunks.join('.').split('').reversed.join();
    }

    return '$integerPart,$decimalPart TL';
  }

  double? _parseAmount(String rawAmount) {
    try {
      String cleanAmount = rawAmount.replaceAll(RegExp(r'[^\d,.]'), '');

      if (cleanAmount.contains(',') && cleanAmount.contains('.')) {
        int lastComma = cleanAmount.lastIndexOf(',');
        int lastDot = cleanAmount.lastIndexOf('.');

        if (lastComma > lastDot) {
          cleanAmount = cleanAmount.replaceAll('.', '');
          cleanAmount = cleanAmount.replaceAll(',', '.');
        } else {
          cleanAmount = cleanAmount.replaceAll(',', '');
        }
      } else if (cleanAmount.contains(',')) {
        cleanAmount = cleanAmount.replaceAll(',', '.');
      }

      return double.tryParse(cleanAmount);
    } catch (e) {
      return null;
    }
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Ekran genişliğine göre boyutlandır
                double width = constraints.maxWidth;
                double height = width * (16 / 9); // 16:9 aspect ratio

                return Container(
                  width: width,
                  height: height,
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
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(_controller!),
                        _buildCameraOverlay(),
                      ],
                    ),
                  ),
                );
              },
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
                        child: SizedBox(
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
