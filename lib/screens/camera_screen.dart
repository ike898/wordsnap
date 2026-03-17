import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/word_entry.dart';
import '../providers/word_provider.dart';
import '../services/dictionary_service.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  final ImageLabeler _labeler = ImageLabeler(
    options: ImageLabelerOptions(confidenceThreshold: 0.7),
  );
  final FlutterTts _tts = FlutterTts();
  List<ImageLabel> _labels = [];
  bool _isProcessing = false;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _tts.setLanguage('en-US');
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {});

      _controller!.startImageStream(_processImage);
    } catch (e) {
      // Camera not available (simulator, etc.)
    }
  }

  void _processImage(CameraImage image) {
    _frameCount++;
    // Process every 5th frame (~6 fps)
    if (_frameCount % 5 != 0 || _isProcessing) return;
    _isProcessing = true;

    final inputImage = _convertCameraImage(image);
    if (inputImage == null) {
      _isProcessing = false;
      return;
    }

    _labeler.processImage(inputImage).then((labels) {
      if (mounted) {
        setState(() => _labels = labels);
      }
      _isProcessing = false;
    }).catchError((_) {
      _isProcessing = false;
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(
        _controller!.description.sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _labeler.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetLang = ref.watch(targetLanguageProvider);
    final theme = Theme.of(context);

    return Stack(
      children: [
        // Camera preview
        if (_controller != null && _controller!.value.isInitialized)
          SizedBox.expand(
            child: CameraPreview(_controller!),
          )
        else
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt, size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('Camera not available',
                    style: theme.textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('Use a physical device to scan objects',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),

        // Label overlay at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_labels.isEmpty)
                  const Text('Point camera at an object',
                      style: TextStyle(color: Colors.white, fontSize: 16))
                else
                  ..._labels.take(3).map((label) {
                    final english = label.label.toLowerCase();
                    final translated =
                        DictionaryService.translate(english, targetLang);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  english,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (translated != null)
                                  Text(
                                    translated,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${(label.confidence * 100).toInt()}%',
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.volume_up,
                                color: Colors.white),
                            onPressed: () => _tts.speak(english),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle,
                                color: Colors.greenAccent),
                            onPressed: translated != null
                                ? () => _saveWord(
                                    english, translated, targetLang,
                                    label.confidence)
                                : null,
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _saveWord(
      String english, String translated, String lang, double confidence) {
    ref.read(wordsProvider.notifier).addWord(WordEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          englishWord: english,
          translatedWord: translated,
          targetLanguage: lang,
          confidence: confidence,
          learnedAt: DateTime.now(),
        ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: $english → $translated')),
    );
  }
}
