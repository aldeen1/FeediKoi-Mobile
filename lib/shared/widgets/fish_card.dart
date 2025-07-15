import 'package:flutter/material.dart';
import 'package:ezviz_flutter/ezviz_flutter.dart';
import '../../shared/widgets/cards.dart';
import '../../shared/widgets/pills.dart';

class FishCameraCard extends StatefulWidget {
  final String cameraSerial;
  final int channelNo;
  final String appKey;
  final String appSecret;
  final String accessToken;
  final double averageLengthCm;
  const FishCameraCard({
    super.key,
    required this.cameraSerial,
    this.channelNo = 1,
    required this.appKey,
    required this.appSecret,
    required this.accessToken,
    required this.averageLengthCm,
  });

  @override
  State<FishCameraCard> createState() => _FishCameraCardState();
}

class _FishCameraCardState extends State<FishCameraCard> {

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
        Container(
          width: double.infinity,
          height: 250,
          child: Stack(
            children: [
              EzvizSimplePlayer(
                deviceSerial: widget.cameraSerial,
                channelNo: widget.channelNo,
                config: EzvizPlayerConfig(
                  appKey: widget.appKey,
                  appSecret: widget.appSecret,
                  accessToken: widget.accessToken,
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
