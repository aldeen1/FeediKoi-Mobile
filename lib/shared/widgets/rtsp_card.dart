import 'dart:convert';

import 'package:feedikoi/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data' show Uint8List;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_vision/flutter_vision.dart';

import 'cards.dart';

class RTSPCard extends StatefulWidget {
  final String? url;
  final String username;
  final String password;
  final String channel;
  final int port;

  const RTSPCard({
    super.key,
    this.url,
    this.username = 'admin',
    this.password = 'KQRHXD',
    this.channel = '101',
    this.port = 554,
  });

  @override
  State<StatefulWidget> createState() => _RTSPCard();
}

class _RTSPCard extends State<RTSPCard> {
  VlcPlayerController? _vlcController;
  bool _isPlaying = false;
  bool _isInitialized = false;
  Uint8List? _lateSnapshotBytes;

  late FlutterVision vision;
  List<Uint8List> _croppedDetections = [];
  List<Map<String, dynamic>> yoloResults = [];

  final ImagePicker _picker = ImagePicker();
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeController().then((_){
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }).catchError((error){
  _showErrorSnackBar("VLC Initialization Failed: $error");
    });
    _initializeYolo().catchError((error){
      _showErrorSnackBar("YOLO Model Load Failed: $error");
    });
  }

  Future<void> _initializeController() async {
    try{
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('camera_ip') ?? '192.168.33.234';
      final rtspUrl = widget.url ?? 'rtsp://${widget.username}:${widget.password}@$ip:${widget.port}/Streaming/Channels/${widget.channel}/';

      _vlcController = VlcPlayerController.network(
          rtspUrl,
          hwAcc: HwAcc.full,
          autoPlay: true,
          options: VlcPlayerOptions(
              rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)])
          )
      );

      _vlcController!.addListener(_vlcListener);
      await _vlcController!.initialize();

      if (mounted){
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("VLC Player Initialization Error: ${e.toString()}");
        setState(() {
          _isInitialized = false;
        });
      }
      rethrow;
    }
  }

  Future<void> _initializeYolo() async {
    try{
      vision = FlutterVision();
      await vision.loadYoloModel(
          labels: "assets/models/koifish.txt",
          modelPath: "assets/models/model_yolov8.tflite",
          modelVersion: "yolov8",
          numThreads: 1,
          useGpu: true
      );
      if(mounted){
        setState(() {
          isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar("YOLO Model Loading Error: ${e.toString()}");
        setState(() {
          isLoaded = false;
        });
      }
      rethrow;
    }
  }

  void _vlcListener() {
    if (!mounted || _vlcController == null) return;
    final value = _vlcController!.value;

    if (value.hasError){
      _showErrorSnackBar("VLC Player Error: ${value.errorDescription}");
    }

    if (mounted){
      setState(() {
        _isPlaying = value.isPlaying;
      });
    }
  }

  @override
  Future<void> dispose() async {
    _vlcController?.removeListener(_vlcListener);
    await _vlcController?.stopRendererScanning();
    await _vlcController?.dispose();
    vision.closeYoloModel();
    super.dispose();
  }

  Future<void> _handleSnapshot() async {
    if (_vlcController == null || !_vlcController!.value.isInitialized){
      _showErrorSnackBar("VLC player not ready for snapshot");
      return;
    }
    try {
      final Uint8List imageBytes = await _vlcController!.takeSnapshot();
      if (imageBytes == null || imageBytes.isEmpty){
        _showErrorSnackBar("Failed to take snapshot (resulted image is empty)");
        return;
      }

      final img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        _showErrorSnackBar("failed to decode snapshot image.");
        return;
      }

      await _processImageWithYolo(imageBytes, decodedImage);
    } catch (e) {
      _showErrorSnackBar("Snapshot error: ${e.toString()}");
    }
  }

  Future<void> _handlePickFromGallery() async {
    await _pickAndProcessImage(ImageSource.gallery);
  }

  Future<void> _handlePickFromCamera() async {
    try {
      final XFile? imageFile = await _picker.pickImage(source: ImageSource.camera);
      if (imageFile != null){
        final bytes = await imageFile.readAsBytes();
        if (bytes.isNotEmpty){
          _showInfoSnackBar("Image from camera captured. (Yolo proceessing called)");

          final img.Image? decodedImage = img.decodeImage(bytes);
          if (decodedImage != null){
            await _processImageWithYolo(bytes, decodedImage);
          } else {
            _showErrorSnackBar("Failed to decode image from camera");
          }
        } else {
          _showErrorSnackBar("Image captured from camera is empty.");
        }
      } else {
        _showInfoSnackBar("Image capture from camera cancelled");
      }
    } catch (e) {
      _showErrorSnackBar("Camera picking error: ${e.toString()}");
    }
  }

  Future<void> _pickAndProcessImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (!mounted) return;
      if (pickedFile == null){
        if (mounted) _showInfoSnackBar("No image selected.");
        return;
      }

      final Uint8List imageBytes = await pickedFile.readAsBytes();
      if(imageBytes.isEmpty){
        if (mounted) _showErrorSnackBar("selected image is empty");
        return;
      }

      final img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null){
        if (mounted) _showErrorSnackBar("Failed to decode image.");
        return;
      }

      await _processImageWithYolo(imageBytes, decodedImage);
    } catch (e) {
      if (mounted) _showErrorSnackBar("Error picking / processing image, $e");
    }
  }

  Future<void> _processImageWithYolo(Uint8List imageBytes, img.Image decodedImage) async {
    if (!isLoaded){
      _showErrorSnackBar("YOLO model is not loaded. Cannot process image");
      return;
    }
    if (imageBytes.isEmpty){
      _showErrorSnackBar("Image data is empty.");
      return;
    }

    try{
      final List<Map<String, dynamic>> results = await vision.yoloOnImage(
          bytesList: imageBytes,
          imageHeight: decodedImage.height,
          imageWidth: decodedImage.width
      );

      if(!mounted) return;

      if (results.isEmpty){
        _showInfoSnackBar("No objects detected in the image.");
      }

      setState(() {
        yoloResults = results;
      });

      _prepareDetectionsForCarousel(decodedImage, results);
    } catch (e, s) {
      _showErrorSnackBar("Yolo detection error: ${e.toString()}");
      print("YOLO detection stacktrace: $s");
    }
  }

  void _prepareDetectionsForCarousel(img.Image originalDecodedImage, List<Map<String, dynamic>> detectedResults) {
    if(!mounted) return;
    _croppedDetections.clear();
    List<Map<String, dynamic>> croppedResults = [];

    for(var result in detectedResults){
      final box = result['box'] as List<dynamic>?;
      if(box == null || box.length < 4){
        print("Skipping detection with invalid box data: $result");
        continue;
      }

      final double x0 = (box[0] as num?)?.toDouble() ?? 0.0;
      final double y0 = (box[1] as num?)?.toDouble() ?? 0.0;
      final double x1 = (box[2] as num?)?.toDouble() ?? 0.0;
      final double y1 = (box[3] as num?)?.toDouble() ?? 0.0;

      final int x = x0.toInt();
      final int y = y0.toInt();
      final int w = (x1 - x0).toInt();
      final int h = (y1 - y0).toInt();

      if (w <= 0 || h <= 0){
        print("Skipping detection with invalid width/height: w=$w, h=$h");
        continue;
      }

      try {
        final cropped = img.copyCrop(originalDecodedImage, x: x, y: y, width: w, height: h);
        final jpg = img.encodeJpg(cropped);

        final size = w;
        final brightness = _calculateHSV(cropped);

        _croppedDetections.add(Uint8List.fromList(jpg));
        croppedResults.add({
          ...result,
          'calculated_size': size,
          'calculated_brightness': brightness
        });
      } catch (e) {
        _showErrorSnackBar("Error cropping detection: ${e.toString()}");
        print("Error cropping detection for result: $result");
      }
    }

    setState(() {
      yoloResults = croppedResults;
    });

    if(croppedResults.isNotEmpty){
      _showCarousel();
    }else if (detectedResults.isNotEmpty){
      _showInfoSnackBar("Detections found, but failed to prepare them");
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) { // <<<< KEY CHECK: Check if THIS State object is still mounted
      print("ERROR (_RTSPCard not mounted): $message");
      return;
    }
    // Now it's safe to try and get a context to show the SnackBar
    final BuildContext? scaffoldContext = rootNavigatorKey.currentContext ?? context; // Fallback to local if root is null

    if (scaffoldContext == null) {
      print("ERROR (No valid context for SnackBar): $message");
      return;
    }

    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    print("Error: $message");
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) { // <<<< KEY CHECK: Check if THIS State object is still mounted
      print("INFO (_RTSPCard not mounted): $message");
      return;
    }
    // Now it's safe to try and get a context to show the SnackBar
    final BuildContext? scaffoldContext = rootNavigatorKey.currentContext ?? context; // Fallback to local if root is null

    if (scaffoldContext == null) {
      print("INFO (No valid context for SnackBar): $message");
      return;
    }

    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue),
    );
    print("Info: $message");
  }

  void _showCarousel() {
    if (_croppedDetections.isEmpty || yoloResults.length != _croppedDetections.length){
      _showErrorSnackBar("Data mismatch for carousel or no detections");
      print("Carousel data error");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 350,
          child: CarouselSlider.builder(
            itemCount: _croppedDetections.length,
            itemBuilder: (context, index, realIdx) {
              final bytes = _croppedDetections[index];
              final result = yoloResults[index];
              final size = result['calculated_size'] ?? 'N/A';
              final dynamic brightnessDynamic = result['calculated_brightness'];
              final String brightness = brightnessDynamic is num ? brightnessDynamic.toStringAsFixed(2) : 'N/A';
              final String tag = result['tag'] ?? 'Unknown';
              final double confidence = result['confidence'] ?? 0.0;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("$tag ($confidence)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  Text("Size: $size px", style: TextStyle(fontSize: 14)),
                  Text("Size: $size", style: const TextStyle(fontSize: 14)), // Assuming 'size' is meaningful as is
                  Text("Avg. Brightness: $brightness", style: const TextStyle(fontSize: 14)),
                ],
              );
            },
            options: CarouselOptions(
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              viewportFraction: 0.8,
              height: 330,
            ),
          ),
        ),
      ),
    );
  }

  double _calculateHSV(img.Image cropped){
    final centerX = cropped.width ~/ 2;
    final centerY = cropped.height ~/ 2;

    final sampleSize = 10;
    int count = 0;
    double totalV = 0;

    for (int dx = -sampleSize; dx <= sampleSize; dx++){
      for(int dy = -sampleSize; dy <= sampleSize; dy++){
        final px = (centerX + dx).clamp(0, cropped.width-1);
        final py = (centerY + dy).clamp(0, cropped.height-1);

        final pixel = cropped.getPixel(px, py);

        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        final brightness = 0.299 * r + 0.587 * g + 0.114 * b;
        totalV += brightness;
        count++;
      }
    }

    return totalV / count;
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.all(12),
      children: [
        SizedBox(
          width: double.infinity,
          height: 250,
          child: _vlcController != null && _isInitialized
              ? VlcPlayer(
                  controller: _vlcController!,
                  aspectRatio: 16 / 9,
                  placeholder: const Center(child: CircularProgressIndicator()),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
        Row(
          children: [
            ElevatedButton(
              onPressed: _handleSnapshot,
              child: const Icon(Icons.camera),
            ),
            SizedBox(width: 16),
            ElevatedButton(
                onPressed: _handlePickFromCamera,
                child: const Icon(Icons.photo_camera)
            ),
            SizedBox(width: 16,),
            ElevatedButton(onPressed: _handlePickFromGallery, child: const Icon(Icons.photo_library))
          ]
        )
      ],
    );
  }
}

class DetectionPainter extends CustomPainter{
  final List<Map<String, dynamic>> results;

  DetectionPainter(this.results);

  @override
  void paint(Canvas canvas, Size size){
    final paint = Paint()
        ..color = Colors.red.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr
    );

    for (var result in results){
      final box = result['box'];
      if (box == null) continue;

      final rect = Rect.fromLTWH(
        box[0].toDouble(), box[1].toDouble(), box[2].toDouble(), box[3].toDouble()
      );

      canvas.drawRect(rect, paint);

      final label = "${result['tag']} ${(result['confidence'] * 100).toStringAsFixed(0)}%";
      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 14)
      );
      textPainter.layout();
      textPainter.paint(canvas, rect.topLeft);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}