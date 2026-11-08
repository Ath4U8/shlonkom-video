import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

// شلونكم فيديو - نص الى فيديو - شخص يحجي
// نسخة 1 - مجانية - شخصية
// تكتب نص عراقي - تختار صورة - الصورة تحجي وتتحرك

void main() {
  runApp(const ShlonkomVideoApp());
}

class ShlonkomVideoApp extends StatelessWidget {
  const ShlonkomVideoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'شلونكم فيديو',
      home: const VideoHome(),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
    );
  }
}

class VideoHome extends StatefulWidget {
  const VideoHome({super.key});
  @override
  State<VideoHome> createState() => _VideoHomeState();
}

class _VideoHomeState extends State<VideoHome> with SingleTickerProviderStateMixin {
  final _textCtrl = TextEditingController(text: 'هلا شلونكم شخباركم اليوم ان شاء الله بخير');
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _talking = false;
  bool _mouthOpen = false;
  double _headAngle = 0;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _anim.addListener(() {
      if (mounted) setState(() {});
    });
    _setupTts();
  }

  Future<void> _setupTts() async {
    await _tts.setLanguage('ar-IQ');
    await _tts.setSpeechRate(0.85);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _tts.setStartHandler(() {
      if (mounted) setState(() => _talking = true);
      _startMouth();
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() {
        _talking = false;
        _mouthOpen = false;
        _headAngle = 0;
      });
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _talking = false);
    });
  }

  void _startMouth() async {
    final rnd = Random();
    while (_talking && mounted) {
      await Future.delayed(Duration(milliseconds: 120 + rnd.nextInt(120)));
      if (!mounted || !_talking) break;
      setState(() {
        _mouthOpen = !_mouthOpen;
        _headAngle = (rnd.nextDouble() - 0.5) * 0.08;
      });
    }
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null && mounted) {
      setState(() => _image = File(x.path));
    }
  }

  Future<void> _takePhoto() async {
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x != null && mounted) {
      setState(() => _image = File(x.path));
    }
  }

  Future<void> _speak() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب النص اول')));
      return;
    }
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختار صورة اول')));
      return;
    }
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) {
      setState(() {
        _talking = false;
        _mouthOpen = false;
        _headAngle = 0;
      });
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _tts.stop();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _talking ? 1.03 + (_mouthOpen ? 0.01 : 0) : 1.0;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        title: const Text('شلونكم فيديو - شخص يحجي'),
        backgroundColor: const Color(0xFF0B4ED8),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // شاشة الفيلم
          Container(
            width: double.infinity,
            height: 380,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF0B4ED8), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(children: [
                if (_image != null)
                  Center(
                    child: Transform.rotate(
                      angle: _headAngle,
                      child: Transform.scale(
                        scale: scale,
                        child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      ),
                    ),
                  )
                else
                  const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.person, size: 100, color: Colors.white30),
                      SizedBox(height: 8),
                      Text('اختار صورة الشخص', style: TextStyle(color: Colors.white70)),
                    ]),
                  ),
                // فم متحرك - يحاكي الكلام
                if (_image != null && _talking)
                  Positioned(
                    bottom: 90,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: _mouthOpen ? 70 : 40,
                        height: _mouthOpen ? 22 : 6,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                // ترجمة مثل الافلام
                if (_talking)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(10)),
                      child: Text(_textCtrl.text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                // اشارة يحجي
                if (_talking)
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: Row(children: [
                      Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('يحجي الان...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo_library),
                label: const Text('من الاستوديو'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0B4ED8), foregroundColor: Colors.white),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('كاميرا'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0B4ED8)),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: _textCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'اكتب النص بالعراقي',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'مثال: هلا شلونكم...',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _talking ? _stop : _speak,
              icon: Icon(_talking ? Icons.stop : Icons.play_arrow),
              label: Text(_talking ? 'وقف' : 'شغل الفيلم - خليه يحجي'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _talking ? Colors.red : const Color(0xFF00C950),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'سجل الشاشة وانت مشغل الفيلم حتى تحفظه MP4 - النسخة 1 مجانية وشخصية',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 8),
          const Text('Designed by: Atheer Sami', style: TextStyle(color: Colors.white38, fontSize: 12)),
        ]),
      ),
    );
  }
}
