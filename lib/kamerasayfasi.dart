import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart'; // path_provider import et

class KameraSayfasi extends StatefulWidget {
  @override
  _KameraSayfasiState createState() => _KameraSayfasiState();
}

class _KameraSayfasiState extends State<KameraSayfasi> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  late CameraDescription _camera;
  String _imagePath = "";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Kamerayı başlatma
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _camera = _cameras![0];

    _controller = CameraController(_camera, ResolutionPreset.high);

    await _controller!.initialize();

    if (mounted) {
      setState(() {});
    }
  }

  // Fotoğraf çekme ve kaydetme
  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) {
      return;
    }

    try {
      // Android için geçerli dizin
      final Directory appDirectory = await getApplicationDocumentsDirectory();

      // Fotoğrafı kaydetmek için dosya yolu oluşturma
      final String filePath =
          '${appDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.png';

      await _controller!.takePicture().then((XFile file) {
        setState(() {
          _imagePath = file.path;
        });

        // Fotoğrafı kaydetme
        File savedImage = File(file.path);
        savedImage.copy(filePath);

        // Fotoğrafı API'ye gönderme
        _sendImageToServer(filePath);
      });
    } catch (e) {
      print("Error while taking picture: $e");
    }
  }

  // Fotoğrafı API'ye gönderme
  Future<void> _sendImageToServer(String imagePath) async {
    try {
      final Uri url = Uri.parse(
        'https://your-api-url.com/upload',
      ); // API URL'nizi buraya yazın.
      final File imageFile = File(imagePath);
      final bytes = imageFile.readAsBytesSync();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'image': base64Encode(
            bytes,
          ), // Görüntüyü base64 formatında gönderiyoruz
        }),
      );

      if (response.statusCode == 200) {
        print("Resim başarıyla gönderildi");
      } else {
        print("Resim gönderilemedi: ${response.statusCode}");
      }
    } catch (e) {
      print("Error while sending image: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Kamera Sayfası')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Kamera görüntüsünü gösterme
          SizedBox(
            height: 300,
            width: double.infinity,
            child: CameraPreview(_controller!),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _takePicture,
            child: Text('Fotoğraf Çek'),
            style: ElevatedButton.styleFrom(
              shape: CircleBorder(),
              padding: EdgeInsets.all(20),
            ),
          ),
          SizedBox(height: 20),
          // Çekilen fotoğrafın yolunu gösterme
          if (_imagePath.isNotEmpty)
            Image.file(File(_imagePath), height: 200, width: 200),
        ],
      ),
    );
  }
}
