import 'dart:math';
import 'package:flutter/material.dart';
import 'package:webrtc_video_call/screens/join_screen.dart';
import 'package:webrtc_video_call/services/signalling_service.dart';
import 'package:webrtc_video_call/test_screen.dart';

void main() {
  // start videoCall app
  runApp(
    VideoCallApp(),
  );
}

class VideoCallApp extends StatelessWidget {
  VideoCallApp({super.key});

  // signalling server url
  final String websocketUrl = "http://192.168.1.20:3230";

  // generate callerID of local user
  final String selfCallerID = Random().nextInt(999999).toString().padLeft(6, '0');

  @override
  Widget build(BuildContext context) {
    // //init signalling service
    SignallingService.instance.init(
      websocketUrl: websocketUrl,
      selfCallerID: selfCallerID,
    );

    return MaterialApp(
      darkTheme: ThemeData.dark().copyWith(
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(),
      ),
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home:
          // TestingScreen()
          JoinScreen(
        selfCallerId: selfCallerID,
      ),
    );
  }
}
