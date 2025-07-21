import 'package:flutter/material.dart';
import 'package:ezviz_flutter/ezviz_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/pills.dart';

class FishCameraCard extends StatefulWidget {
  final String cameraSerial;
  final int channelNo;
  final String appKey;
  final String appSecret;
  final double averageLengthCm;
  const FishCameraCard({
    super.key,
    required this.cameraSerial,
    this.channelNo = 1,
    required this.appKey,
    required this.appSecret,
    required this.averageLengthCm,
  });

  @override
  State<FishCameraCard> createState() => _FishCameraCardState();
}

class AccessToken {
  String? accessToken;

  AccessToken({this.accessToken});

  AccessToken.fromJson(Map<String, dynamic> json){
    accessToken = json['accessToken'];
  }
}

class _FishCameraCardState extends State<FishCameraCard> {
  late String accessToken = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchAccessToken();
  }

  Future<void> fetchAccessToken() async {
    final response = await http.post(
      Uri.parse('https://open.ezvizlife.com/api/lapp/token/get'),
      headers: {
        'Content-Type':'application/x-www-form-urlencoded',
      },
      body: {
        'appKey': widget.appKey,
        'appSecret': widget.appSecret
      }
    );
    if(response.statusCode == 200){
      final Map<String, dynamic> jsonData = json.decode(response.body);
      print("JSONDATA : \n$jsonData");

      if (jsonData['code'] == 200.toString() || jsonData['data'] != null){
        final token = jsonData['data']['accessToken'];
        if(mounted && token != null){
          setState(() {
            accessToken = token;
          });
          print('SDK Initialization successfully done');
          _initSDK();
        }
      }else{
        print('Error fetching data, ${jsonData['msg']}');
      }
    } else {
      print('Error from HTTP response ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> _initSDK() async {
    final opts = EzvizInitOptions(
      appKey: widget.appKey,
      accessToken: accessToken,
      enableLog: true,
      enableP2P: false,
    );

    try {
      bool ok = await EzvizManager.shared().initSDK(opts);
      print("sdk init ok: $ok");
    } catch (e, st){
      print("Sdk init exception, $e\n$st");
    }
  }

  void _onScreenshot() async {
    final path = await EzvizRecording.capturePicture();
    if (path != null) {
      // TODO: Send 'path' file to Roboflow
      print('Screenshot captured at $path');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: Colors.grey[200],
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Camera: ${widget.cameraSerial}",
                style: const TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 250,
          child: Stack(
            children: [
              EzvizSimplePlayer(
                deviceSerial: widget.cameraSerial,
                channelNo: 0,
                config: EzvizPlayerConfig(
                  appKey: widget.appKey,
                  appSecret: widget.appSecret,
                  accessToken: accessToken,
                  autoPlay: true,
                  enableAudio: true,
                  showControls: false, // we'll use EnhancedPlayerControls
                ),
              ),
              Positioned.fill(
                child: EnhancedPlayerControls(
                  onScreenshot: _onScreenshot,
                  isPlaying: true,
                  isRecording: false,
                  soundEnabled: false,
                  onRecord: () => print('Record pressed'),
                ),

              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InfoPill(
          label: "Panjang Ikan",
          statusText: "${widget.averageLengthCm.toStringAsFixed(0)} cm",
          isSystem: false,
          value: widget.averageLengthCm,
        ),
      ],
    );
  }
}
