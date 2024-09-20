import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

enum Language { english, indonesian }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Classification Batik Bakaran'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  List<dynamic>? _results;
  String _predictedLabel = "Label"; // Default label
  Language _selectedLanguage = Language.indonesian;
  bool _isLoading = false; // Indicator loading

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    String? res = await Tflite.loadModel(
      model: "assets/model9079.tflite",
      labels: "assets/labels.txt",
    );
    // ignore: avoid_print
    print(res);
  }

  Future<void> _accessCameraAndClassify() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      if (_isValidImageFormat(photo.path)) {
        setState(() {
          _imageFile = File(photo.path);
          _isLoading = true; // Start loading indicator
        });
        await classifyImage(_imageFile!);
        setState(() {
          _isLoading = false; // Stop loading indicator
        });
      } else {
        _showInvalidFormatDialog();
      }
    }
  }

  Future<void> _accessGalleryAndClassify() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null) {
      if (_isValidImageFormat(photo.path)) {
        setState(() {
          _imageFile = File(photo.path);
          _isLoading = true; // Start loading indicator
        });
        await classifyImage(_imageFile!);
        setState(() {
          _isLoading = false; // Stop loading indicator
        });
      } else {
        _showInvalidFormatDialog();
      }
    }
  }

  bool _isValidImageFormat(String path) {
    final validExtensions = ['jpg', 'jpeg', 'png'];
    final extension = path.split('.').last.toLowerCase();
    return validExtensions.contains(extension);
  }

  void _showInvalidFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_translate('invalid_format')),
        content: Text(_translate('invalid_format_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_translate('ok')),
          ),
        ],
      ),
    );
  }

  Future<void> classifyImage(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.5,
    );

    // ignore: avoid_print
    print(recognitions); // Tambahkan log untuk melihat hasil klasifikasi

    if (recognitions != null && recognitions.isNotEmpty) {
      setState(() {
        _results = recognitions;
        _predictedLabel = _results![0]["label"];
      });
    } else {
      setState(() {
        _predictedLabel = _selectedLanguage == Language.english
            ? "No results"
            : "Tidak ada hasil"; // Tambahkan pesan default jika tidak ada hasil
      });
    }
  }

  void _changeLanguage(Language language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  String _translate(String key) {
    Map<String, Map<Language, String>> translations = {
      'selected_image': {
        Language.english: 'Selected Image:',
        Language.indonesian: 'Gambar yang dipilih:',
      },
      'no_image_selected': {
        Language.english: 'No image selected. Use (.jpg, .png, .jpeg) formats',
        Language.indonesian:
            'Belum ada gambar yang dipilih. Gunakan format (.jpg, .png, .jpeg)',
      },
      'result': {
        Language.english: 'Result: ',
        Language.indonesian: 'Hasil: ',
      },
      'access_camera': {
        Language.english: 'Access Camera',
        Language.indonesian: 'Akses Kamera',
      },
      'access_gallery': {
        Language.english: 'Access Gallery',
        Language.indonesian: 'Akses Galeri',
      },
      'change_language': {
        Language.english: 'Change Language',
        Language.indonesian: 'Ubah Bahasa',
      },
      'english': {
        Language.english: 'English',
        Language.indonesian: 'Bahasa Inggris',
      },
      'indonesian': {
        Language.english: 'Indonesian',
        Language.indonesian: 'Bahasa Indonesia',
      },
      'invalid_format': {
        Language.english: 'Invalid Format',
        Language.indonesian: 'Format Tidak Valid',
      },
      'invalid_format_message': {
        Language.english: 'Please select an image in .jpg, .png, or .jpeg format.',
        Language.indonesian: 'Silakan pilih gambar dalam format .jpg, .png, atau .jpeg.',
      },
      'ok': {
        Language.english: 'OK',
        Language.indonesian: 'OK',
      },
    };

    return translations[key]?[_selectedLanguage] ?? key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          PopupMenuButton<Language>(
            icon: const Icon(Icons.language),
            onSelected: _changeLanguage,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Language>>[
              PopupMenuItem<Language>(
                value: Language.english,
                child: Text(_translate('english')),
              ),
              PopupMenuItem<Language>(
                value: Language.indonesian,
                child: Text(_translate('indonesian')),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 100), // Jarak dari atas layar
            Text(
              _translate('selected_image'),
            ),
            const SizedBox(height: 20), // Jarak antara teks dan gambar
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Center(
                      child: Center(
                        child: Text(
                          _translate('no_image_selected'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20), // Jarak antara gambar dan hasil klasifikasi
            if (_isLoading)
              const CircularProgressIndicator() // Tampilkan loading indicator
            else
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  '${_translate('result')} $_predictedLabel',
                  textAlign: TextAlign.center,
                ),
              ),
            const Spacer(), // Mengisi sisa ruang di bawah gambar
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                '© Teknik Informatika UNISSULA',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _accessCameraAndClassify,
            tooltip: _translate('access_camera'),
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _accessGalleryAndClassify,
            tooltip: _translate('access_gallery'),
            child: const Icon(Icons.photo_library),
          ),
        ],
      ),
    );
  }
}