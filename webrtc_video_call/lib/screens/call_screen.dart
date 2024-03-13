import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../services/signalling_service.dart';

class CallScreen extends StatefulWidget {
  final String callerId, calleeId;
  final dynamic offer;

  const CallScreen({
    Key? key,
    this.offer,
    required this.callerId,
    required this.calleeId,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // Socket instance
  final socket = SignallingService.instance.socket;

  // Video renderer for localPeer
  final _localRTCVideoRenderer = RTCVideoRenderer();

  // Video renderer for remotePeer
  final _remoteRTCVideoRenderer = RTCVideoRenderer();

  // Media stream for localPeer
  MediaStream? _localStream;

  // RTC peer connection
  RTCPeerConnection? _rtcPeerConnection;

  // List of RTCIceCandidates to be sent over signalling
  List<RTCIceCandidate> rtcIceCandidates = [];

  // Media status
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;

  // For Full Screen Video view
  bool isFullScreenLocal = false;

  @override
  void initState() {
    super.initState();

    // Initializing renderers
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();

    // Setup Peer Connection
    _setupPeerConnection();
  }

  @override
  void dispose() {
    // Dispose renderers, stream, and connection
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();

    super.dispose();
  }

  void _setupPeerConnection() async {
    // Create peer connection
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': [
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
          ],
          'videoCodec': 'VP8',
          // ['VP8', 'VP9', 'H264', 'AV1']
        }
      ]
    });

    // Listen for remotePeer mediaTrack event
    _rtcPeerConnection!.onTrack = (event) {
      if (event.track.kind == 'video') {
        _remoteRTCVideoRenderer.srcObject = event.streams[0];
      }
      setState(() {});
    };

    // Get localStream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {
              'mandatory': {
                'minWidth': '1920',
                'minHeight': '1080',
                'minFrameRate': '30',
              },

              // 'mandatory': {
              //   'minWidth': '3840',
              //   'minHeight': '2160',
              //   'minFrameRate': '60',
              // },
            }
          : null
    });

    // Add mediaTracks to peerConnection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // Set source for local video renderer
    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    // For incoming call
    if (widget.offer != null) {
      // Listen for remote IceCandidate
      socket!.on('IceCandidate', (data) {
        String candidate = data['iceCandidate']['candidate'];
        String sdpMid = data['iceCandidate']['id'];
        int sdpMLineIndex = data['iceCandidate']['label'];

        // Add IceCandidate
        _rtcPeerConnection!.addCandidate(RTCIceCandidate(
          candidate,
          sdpMid,
          sdpMLineIndex,
        ));
      });

      // Set SDP offer as remoteDescription for peerConnection
      await _rtcPeerConnection!.setRemoteDescription(
        RTCSessionDescription(widget.offer['sdp'], widget.offer['type']),
      );

      // Create SDP answer
      RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();

      // Set SDP answer as localDescription for peerConnection
      _rtcPeerConnection!.setLocalDescription(answer);

      // Send SDP answer to remote peer over signalling
      socket!.emit('answerCall', {
        'callerId': widget.callerId,
        'sdpAnswer': answer.toMap(),
      });
    }
    // For outgoing call
    else {
      // Listen for local IceCandidate and add it to the list of IceCandidates
      _rtcPeerConnection!.onIceCandidate =
          (RTCIceCandidate candidate) => rtcIceCandidates.add(candidate);

      // When call is accepted by remote peer
      socket!.on('callAnswered', (data) async {
        // Set SDP answer as remoteDescription for peerConnection
        await _rtcPeerConnection!.setRemoteDescription(
          RTCSessionDescription(
            data['sdpAnswer']['sdp'],
            data['sdpAnswer']['type'],
          ),
        );

        // Send IceCandidates generated to remote peer over signalling
        for (RTCIceCandidate candidate in rtcIceCandidates) {
          socket!.emit('IceCandidate', {
            'calleeId': widget.calleeId,
            'iceCandidate': {
              'id': candidate.sdpMid,
              'label': candidate.sdpMLineIndex,
              'candidate': candidate.candidate,
            },
          });
        }
      });

      // Create SDP Offer
      RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();

      // Set SDP offer as localDescription for peerConnection
      await _rtcPeerConnection!.setLocalDescription(offer);

      // Make a call to remote peer over signalling
      socket!.emit('makeCall', {
        'calleeId': widget.calleeId,
        'sdpOffer': offer.toMap(),
      });
    }
  }

  void _leaveCall() {
    Navigator.pop(context);
  }

  // void _toggleMic() {
  //   // Change status
  //   isAudioOn = !isAudioOn;
  //
  //   if (Platform.isIOS) {
  //     _localStream?.getAudioTracks().forEach((track) {
  //       // track.enableSpeakerphone(true);
  //       track.onUnMute;
  //     });
  //   }
  //   // Enable or disable audio track
  //   _localStream?.getAudioTracks().forEach((track) {
  //     track.enabled = isAudioOn;
  //   });
  //
  //   setState(() {});
  // }

  void _toggleMic() {
    // Change status
    isAudioOn = !isAudioOn;

    // Check if _localStream is not null and has audio tracks
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      if (Platform.isIOS) {
        _localStream!.getAudioTracks()[0].enableSpeakerphone(true);
      }

      // Enable or disable audio track
      _localStream!.getAudioTracks().forEach((track) {
        track.enabled = isAudioOn;
      });
    } else {
      // Handle the case where there are no audio tracks
      print("No audio tracks available in _localStream.");
    }

    setState(() {});
  }

  void _toggleCamera() {
    // Change status
    isVideoOn = !isVideoOn;

    // Enable or disable video track
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = isVideoOn;
    });

    setState(() {});
  }

  void _switchCamera() {
    // Change status
    isFrontCameraSelected = !isFrontCameraSelected;

    // Switch camera
    _localStream?.getVideoTracks().forEach((track) {
      // ignore: deprecated_member_use
      track.switchCamera();
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('P2P Call App'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  RTCVideoView(
                    isFullScreenLocal ? _localRTCVideoRenderer : _remoteRTCVideoRenderer,
                    // mirror: isFullScreenLocal
                    //     ? isFrontCameraSelected
                    //         ? true
                    //         : false
                    //     : false,
                    filterQuality: FilterQuality.medium,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: SizedBox(
                      width: 120,
                      height: 200,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isFullScreenLocal = !isFullScreenLocal;
                          });
                          print('on Screen Change Status>>>>>>>>>>>>>>>>>$isFullScreenLocal');
                        },
                        child: Stack(
                          children: [
                            RTCVideoView(
                              !isFullScreenLocal ? _localRTCVideoRenderer : _remoteRTCVideoRenderer,
                              // mirror: isFullScreenLocal
                              //     ? isFrontCameraSelected
                              //         ? true
                              //         : false
                              //     : false,
                              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                            ),
                            if (isFullScreenLocal)
                              Icon(
                                isAudioOn ? Icons.mic : Icons.mic_off,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(
                      isAudioOn ? Icons.mic : Icons.mic_off,
                    ),
                    onPressed: _toggleMic,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.call_end,
                    ),
                    iconSize: 30,
                    onPressed: _leaveCall,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.flip_camera_android_rounded,
                    ),
                    onPressed: _switchCamera,
                  ),
                  IconButton(
                    icon: Icon(
                      isVideoOn ? Icons.videocam : Icons.videocam_off,
                    ),
                    onPressed: _toggleCamera,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
