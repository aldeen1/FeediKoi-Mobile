import 'dart:convert';

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

  String? _rtspUrl;

  @override
  void initState() {
    super.initState();
    _initializeController().then((_){
      setState(() {
        _isInitialized = true;
      });
    });
    _initializeYolo();
  }

  Future<void> _initializeController() async {
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
  }

  Future<void> _initializeYolo() async {
    vision = FlutterVision();
    await vision.loadYoloModel(
      labels: "koifish",
      modelPath: "assets/models/model_yolov8.tflite",
      modelVersion: "yolov8",
      numThreads: 1,
      useGpu: true
    );
    setState(() => isLoaded = true);
  }

  void _vlcListener() {
    if (!mounted) return;
    final value = _vlcController!.value;
    print("VLC State: Initialized = ${value.isInitialized}, buffering = ${value.isBuffering}, playing = ${value.playingState}");
    if(value.playingState == PlayingState.error){
      print("Error ${value.errorDescription}");
    }
    setState(() {
      _isPlaying = _vlcController!.value.isPlaying;
    });
  }

  @override
  Future<void> dispose() async {
    _vlcController?.removeListener(_vlcListener);
    await _vlcController?.stopRendererScanning();
    await _vlcController?.dispose();
    super.dispose();
  }

  /*Future<void> sendRoboflowAPI(String base64Image) async {
    try {
      final url = "https://serverless.roboflow.com/feedikoi/2?api_key=U6I7ZQ4Znfzxiubgn1Et";
      final headers = {"Content-Type" : "application/x-www-form-urlencoded"};

      final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: base64Image
      );

      print(jsonDecode(response.body));

      if (response.statusCode == 200){
        final data = jsonDecode(response.body);
        final predictions = data['predictions'] as List;

        if (predictions.isEmpty){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak ada ikan yang dideteksi'))
          );
        }
        if (_lateSnapshotBytes == null) return;

        final originalImage = img.decodeImage(_lateSnapshotBytes!);
        if(originalImage == null) return;

        _croppedDetections.clear();

        for(var prediction in predictions){
          final double x = (prediction['x'] as num).toDouble();
          final double y = (prediction['y'] as num).toDouble();
          final double width = (prediction['width'] as num).toDouble();
          final double height = (prediction['height'] as num).toDouble();

          int cropX = (x - width / 2).round();
          int cropY = (y - height / 2).round();
          int cropWidth = width.round();
          int cropHeight = height.round();

          cropX = cropX.clamp(0, originalImage.width - 1);
          cropY = cropY.clamp(0, originalImage.height - 1);
          if(cropX + cropWidth > originalImage.width){
            cropWidth = originalImage.width - cropX;
          }
          if(cropY + cropHeight > originalImage.height){
            cropHeight = originalImage.height - cropY;
          }

          final cropped = img.copyCrop(originalImage, x: cropX, y: cropY, width: cropWidth, height: cropHeight);

          final jpg = img.encodeJpg(cropped);
          _croppedDetections.add(Uint8List.fromList(jpg));

          _showCarousel();
        }
      }else{
        print('Error status code : ${response.statusCode}, Response : ${response.body}');
      }
    } catch (e) {
      print("Error found when calling Roboflow API ${e.toString()}");
    }
  }*/

  Future<void> takeSnapshot() async {
    if(!_vlcController!.value.isInitialized || _vlcController == null)return;
    try{
      final bytes = await _vlcController!.takeSnapshot();
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Resulted image not found"))
        );
        return;
      };

      final imageList = bytes.buffer.asUint8List();
      final decoded = img.decodeImage(imageList);
      if (decoded == null){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image decoding failed"))
        );
        return;
      }

      final results = await vision.yoloOnImage(
          bytesList: imageList,
          imageHeight: decoded.height,
          imageWidth: decoded.width
      );

      setState(() {
        yoloResults = List<Map<String, dynamic>>.from(results);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snapshot failed: $e')),
      );
    }
  }

  Future<void> pickImageFromCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if(image != null){
      final bytes = await image.readAsBytes();
      final imageList = bytes.buffer.asUint8List();
      if(imageList.isNotEmpty){
        _lateSnapshotBytes = imageList;
        final base64Image = base64Encode(imageList);
        //await sendRoboflowAPI(base64Image);
      }
    }
  }

  Future<void> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image terpilih null"))
      );
      return;
    }

    final bytes = await image.readAsBytes();
    final imageList = bytes.buffer.asUint8List();
    if(imageList.isEmpty) return;

    final decoded = img.decodeImage(imageList);
    if (decoded == null) return;

    final results = await vision.yoloOnImage(
        bytesList: imageList,
        imageHeight: decoded.height,
        imageWidth: decoded.width
    );

    setState(() {
      yoloResults = List<Map<String,dynamic>>.from(results);
    });
    
    _processDetections(decoded);
  }

  void _showCarousel() {
    if (_croppedDetections.isEmpty) return;

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
              final size = result['size'];
              final brightness = result['brightness'];

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  Text("Size: $size px", style: TextStyle(fontSize: 14)),
                  Text("Brightness: ${brightness.toStringAsFixed(2)}",
                      style: TextStyle(fontSize: 14)),
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


  void _processDetections(img.Image decoded){
    _croppedDetections.clear();

    for (var result in yoloResults){
      final box = result['box'];
      if (box == null) continue;

      final x = box[0].toInt();
      final y = box[1].toInt();
      final w = box[2].toInt();
      final h = box[3].toInt();

      final cropped = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      final jpg = img.encodeJpg(cropped);

      final size = w;
      final brightness = _calculateHSV(cropped);

      _croppedDetections.add(Uint8List.fromList(jpg));
      result['size'] = size;
      result['brightness'] = brightness;
    };

    _showCarousel();
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
              onPressed: takeSnapshot,
              child: const Icon(Icons.camera),
            ),
            SizedBox(width: 16),
            ElevatedButton(
                onPressed: pickImageFromCamera,
                child: const Icon(Icons.photo_camera)
            ),
            SizedBox(width: 16,),
            ElevatedButton(onPressed: pickImageFromGallery, child: const Icon(Icons.photo_library))
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