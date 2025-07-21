import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'cards.dart';

class RTSPCard extends StatefulWidget {
  final String url;

  const RTSPCard({super.key, required this.url});

  @override
  State<StatefulWidget> createState() => _RTSPCard();
}

class _RTSPCard extends State<RTSPCard>{
  late final player = Player();
  late final controller = VideoController(player);
  Uint8List? capturedImage;

  @override
  void initState() {
    super.initState();
    player.open(Media(widget.url));
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> takeSnapshot() async {
    final Uint8List? bytes = (await player.screenshot(format: 'image/png'));
    if(bytes != null){
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Snapshot Taken"),
            content: Image.memory(bytes),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close')
              )
            ],
          )
      );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture snapshot'))
      );
    }
    setState(() {
      capturedImage = bytes;
    });
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
          child: Video(controller: controller),
        ),
        ElevatedButton(onPressed: takeSnapshot, child: Icon(Icons.camera))
      ],
    );
  }
}