import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  late final VlcPlayerController? _vlcController;
  bool _isPlaying = false;
  bool _isInitialized = false;

  String? _rtspUrl;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    if (widget.url != null) {
      _rtspUrl = widget.url;
    } else {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString('camera_ip') ?? '192.168.33.234';
      _rtspUrl =
          'rtsp://${widget.username}:${widget.password}@$ip:${widget.port}/Streaming/Channels/${widget.channel}/';
    }

    _vlcController = VlcPlayerController.network(
      _rtspUrl!,
      hwAcc: HwAcc.full,
      autoPlay: true,
      options: VlcPlayerOptions(
        rtp: VlcRtpOptions([VlcRtpOptions.rtpOverRtsp(true)]),
      ),
    );

    try {
      await _vlcController?.initialize();
      if (!mounted) return;
    } catch (e) {
      debugPrint('VLC init error: $e');
    }

    _vlcController?.addOnInitListener(() {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });

    _vlcController?.addListener(_vlcListener);
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

  Future<void> sendRoboflowAPI(String base64Image) async {
    try {
      final url = "https://serverless.roboflow.com/koi-fish-8tgj6/1?api_key=U6I7ZQ4Znfzxiubgn1Et";
      final headers = {"Content Type" : "application/x-www-form-urlencoded"};
      final body = {
        "data" : base64Image
      };

      final encodedBody = Uri(queryParameters: body).query;
      final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: encodedBody
      );

      if (response.statusCode == 200){
        print(response.body);
      }else{
        print('Error status code : ${response.statusCode}, Response : ${response.body}');
      }
    } catch (e) {
      print("Error found when calling Roboflow API ${e.toString()}");
    }
  }

  Future<void> takeSnapshot() async {
    if(!_vlcController!.value.isInitialized)return;
    try{
      final bytes = await _vlcController.takeSnapshot();
      if(bytes != null){
        final base64Image = base64Encode(bytes);
        sendRoboflowAPI(base64Image);
      }else{
        print("Bytes is empty");
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Snapshot failed: $e')),
      );
    }
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
        ElevatedButton(
          onPressed: takeSnapshot,
          child: const Icon(Icons.camera),
        ),
      ],
    );
  }
}