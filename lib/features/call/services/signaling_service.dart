import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class SignalingService {
  // STUN + free TURN servers (openrelay.metered.ca)
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ]
      },
      {
        'urls': 'turn:openrelay.metered.ca:80',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
      {
        'urls': 'turn:openrelay.metered.ca:443?transport=tcp',
        'username': 'openrelayproject',
        'credential': 'openrelayproject',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? _remoteStream;

  StreamSubscription<DatabaseEvent>? _answerSub;
  StreamSubscription<DatabaseEvent>? _callerCandidatesSub;
  StreamSubscription<DatabaseEvent>? _calleeCandidatesSub;
  StreamSubscription<DatabaseEvent>? _statusSub;

  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _remoteDescSet = false;
  bool _isClosed = false;
  bool _connectedFired = false;

  // ───────────── OPEN MEDIA ─────────────
  Future<void> openUserMedia(
    RTCVideoRenderer localRenderer,
    RTCVideoRenderer remoteRenderer,
  ) async {
    await _cleanupLocalStream();

    try {
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        },
      });
    } catch (e) {
      debugPrint('getUserMedia video failed: $e, trying audio only');
      try {
        localStream = await navigator.mediaDevices.getUserMedia({
          'audio': true,
          'video': false,
        });
      } catch (e2) {
        debugPrint('getUserMedia audio also failed: $e2');
      }
    }

    if (localStream != null) {
      localRenderer.srcObject = localStream;
      for (final t in localStream!.getTracks()) {
        t.enabled = true;
      }
    }

    try {
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          Helper.setSpeakerphoneOn(true);
        } catch (_) {}
      });
    } catch (_) {}
  }

  // ───────────── CALLER: CREATE ROOM ─────────────
  Future<String> createRoom(
    String roomId,
    RTCVideoRenderer remoteRenderer, {
    VoidCallback? onConnected,
    VoidCallback? onEnded,
    VoidCallback? onRemoteStream,
  }) async {
    _isClosed = false;
    _connectedFired = false;
    _pendingCandidates.clear();
    _remoteDescSet = false;

    final roomRef = FirebaseDatabase.instance.ref('calls/$roomId');

    // Clear old room data
    try { await roomRef.remove(); } catch (_) {}

    _peerConnection = await createPeerConnection(_configuration);
    _registerListeners(remoteRenderer, onConnected, onEnded, onRemoteStream);

    // Add local tracks BEFORE creating offer
    if (localStream != null) {
      for (final track in localStream!.getTracks()) {
        track.enabled = true;
        try { await _peerConnection!.addTrack(track, localStream!); } catch (e) {
          debugPrint('addTrack error: $e');
        }
      }
    }

    // ICE candidate handler — set before createOffer
    _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
      if (candidate == null || _isClosed) return;
      debugPrint('Caller ICE candidate: ${candidate.candidate?.substring(0, 30)}...');
      roomRef.child('callerCandidates').push().set(candidate.toMap());
    };

    // Create offer + set local description
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': true,
    });
    await _peerConnection!.setLocalDescription(offer);
    debugPrint('Caller: local desc set');

    // Write offer to Firebase
    await roomRef.set({
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'status': 'calling',
      'createdAt': ServerValue.timestamp,
    });

    // ── Listen for answer (remote description) ──
    _answerSub = roomRef.child('answer').onValue.listen((event) async {
      if (_isClosed || !event.snapshot.exists || event.snapshot.value == null) return;
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final sdp = data['sdp']?.toString();
        final type = data['type']?.toString();
        if (sdp == null || type == null) return;

        final sigState = _peerConnection?.signalingState;
        if (sigState == RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
          debugPrint('Caller: setting remote desc (answer)');
          await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(sdp, type),
          );
          _remoteDescSet = true;
          await _flushPendingCandidates();
        }
      } catch (e) {
        debugPrint('Caller: set remote desc error: $e');
      }
    });

    // ── Listen for callee ICE candidates ──
    _calleeCandidatesSub = roomRef.child('calleeCandidates').onChildAdded.listen((event) async {
      if (_isClosed || !event.snapshot.exists || event.snapshot.value == null) return;
      try {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        await _addOrQueueCandidate(RTCIceCandidate(
          data['candidate']?.toString() ?? '',
          data['sdpMid']?.toString(),
          (data['sdpMLineIndex'] as num?)?.toInt() ?? 0,
        ));
      } catch (e) {
        debugPrint('Caller: add callee candidate error: $e');
      }
    });

    // ── Listen for status changes ──
    _statusSub = roomRef.child('status').onValue.listen((event) {
      if (_isClosed || !event.snapshot.exists) return;
      final val = event.snapshot.value?.toString();
      debugPrint('Caller: status = $val');
      if (val == 'connected') {
        // Receiver answered — fire onConnected as backup if ICE event didn't fire
        _fireConnected(onConnected);
      } else if (val == 'ended') {
        if (onEnded != null) onEnded();
      }
    });

    return roomId;
  }

  // ───────────── RECEIVER: JOIN ROOM ─────────────
  Future<void> joinRoom(
    String roomId,
    RTCVideoRenderer remoteRenderer, {
    VoidCallback? onConnected,
    VoidCallback? onEnded,
    VoidCallback? onRemoteStream,
  }) async {
    _isClosed = false;
    _connectedFired = false;
    _pendingCandidates.clear();
    _remoteDescSet = false;

    final roomRef = FirebaseDatabase.instance.ref('calls/$roomId');
    final snapshot = await roomRef.get();

    if (!snapshot.exists || snapshot.value == null || snapshot.value is! Map) {
      debugPrint('joinRoom: room not found');
      if (onEnded != null) onEnded();
      return;
    }

    try {
      final roomData = Map<String, dynamic>.from(snapshot.value as Map);
      final offerRaw = roomData['offer'];
      if (offerRaw == null) {
        debugPrint('joinRoom: no offer in room');
        if (onEnded != null) onEnded();
        return;
      }

      _peerConnection = await createPeerConnection(_configuration);
      _registerListeners(remoteRenderer, onConnected, onEnded, onRemoteStream);

      // Add local tracks BEFORE setting remote description
      if (localStream != null) {
        for (final track in localStream!.getTracks()) {
          track.enabled = true;
          try { await _peerConnection!.addTrack(track, localStream!); } catch (e) {
            debugPrint('addTrack error: $e');
          }
        }
      }

      // ICE candidate handler — set BEFORE setRemoteDescription
      _peerConnection!.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate == null || _isClosed) return;
        debugPrint('Receiver ICE candidate: ${candidate.candidate?.substring(0, 30)}...');
        roomRef.child('calleeCandidates').push().set(candidate.toMap());
      };

      // Set remote description (offer) — triggers ICE gathering on receiver too
      final offerMap = Map<String, dynamic>.from(offerRaw as Map);
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(
          offerMap['sdp']?.toString() ?? '',
          offerMap['type']?.toString() ?? 'offer',
        ),
      );
      _remoteDescSet = true;
      debugPrint('Receiver: remote desc set');

      // Flush any queued candidates (none at this point, but safe)
      await _flushPendingCandidates();

      // Create answer + set local description
      final answer = await _peerConnection!.createAnswer({
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': true,
      });
      await _peerConnection!.setLocalDescription(answer);
      debugPrint('Receiver: local desc set');

      // Write answer to Firebase
      await roomRef.update({
        'answer': {'sdp': answer.sdp, 'type': answer.type},
        'status': 'connected',
      });
      debugPrint('Receiver: wrote answer + status=connected');

      // Fire onConnected immediately on receiver side (signaling complete)
      _fireConnected(onConnected);

      // ── Listen for caller ICE candidates ──
      _callerCandidatesSub = roomRef.child('callerCandidates').onChildAdded.listen((event) async {
        if (_isClosed || !event.snapshot.exists || event.snapshot.value == null) return;
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          await _addOrQueueCandidate(RTCIceCandidate(
            data['candidate']?.toString() ?? '',
            data['sdpMid']?.toString(),
            (data['sdpMLineIndex'] as num?)?.toInt() ?? 0,
          ));
        } catch (e) {
          debugPrint('Receiver: add caller candidate error: $e');
        }
      });

      // ── Listen for status changes ──
      _statusSub = roomRef.child('status').onValue.listen((event) {
        if (_isClosed || !event.snapshot.exists) return;
        final val = event.snapshot.value?.toString();
        if (val == 'ended') {
          if (onEnded != null) onEnded();
        }
      });

    } catch (e, stack) {
      debugPrint('joinRoom error: $e\n$stack');
      if (onEnded != null) onEnded();
    }
  }

  // ───────────── PEER CONNECTION LISTENERS ─────────────
  void _registerListeners(
    RTCVideoRenderer remoteRenderer,
    VoidCallback? onConnected,
    VoidCallback? onEnded,
    VoidCallback? onRemoteStream,
  ) {
    _peerConnection?.onTrack = (RTCTrackEvent event) async {
      debugPrint('onTrack: kind=${event.track.kind}, streams=${event.streams.length}');
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams[0];
      } else {
        _remoteStream ??= await createLocalMediaStream('remote');
        await _remoteStream!.addTrack(event.track);
        remoteRenderer.srcObject = _remoteStream;
      }
      if (onRemoteStream != null) onRemoteStream();
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('ICE state: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _fireConnected(onConnected);
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint('ICE failed — restarting ICE');
        try { _peerConnection?.restartIce(); } catch (_) {}
      }
      // Ignore 'disconnected' — it's transient on mobile
    };

    _peerConnection?.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('PC state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _fireConnected(onConnected);
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        debugPrint('PC failed — restarting ICE');
        try { _peerConnection?.restartIce(); } catch (_) {}
      }
      // Do NOT call onEnded on 'disconnected' — too aggressive on mobile
    };

    _peerConnection?.onSignalingState = (RTCSignalingState state) {
      debugPrint('Signaling state: $state');
    };
  }

  /// Fires onConnected exactly once (prevents duplicate timer starts)
  void _fireConnected(VoidCallback? onConnected) {
    if (_connectedFired || _isClosed) return;
    _connectedFired = true;
    if (onConnected != null) onConnected();
  }

  // ───────────── ICE CANDIDATE HELPERS ─────────────
  Future<void> _addOrQueueCandidate(RTCIceCandidate candidate) async {
    if (_remoteDescSet && _peerConnection != null) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint('addCandidate error: $e');
      }
    } else {
      _pendingCandidates.add(candidate);
    }
  }

  Future<void> _flushPendingCandidates() async {
    _remoteDescSet = true;
    final toProcess = List<RTCIceCandidate>.from(_pendingCandidates);
    _pendingCandidates.clear();
    for (final c in toProcess) {
      try {
        await _peerConnection?.addCandidate(c);
      } catch (e) {
        debugPrint('flush candidate error: $e');
      }
    }
  }

  // ───────────── MEDIA CONTROLS ─────────────
  void toggleAudio(bool isMuted) {
    localStream?.getAudioTracks().forEach((t) => t.enabled = !isMuted);
  }

  void toggleVideo(bool isVideoOff) {
    localStream?.getVideoTracks().forEach((t) => t.enabled = !isVideoOff);
  }

  Future<void> switchCamera() async {
    final videoTracks = localStream?.getVideoTracks() ?? [];
    if (videoTracks.isNotEmpty) {
      try {
        await Helper.switchCamera(videoTracks.first);
      } catch (e) {
        debugPrint('switchCamera error: $e');
      }
    }
  }

  // ───────────── HANG UP ─────────────
  Future<void> hangUp(
    String roomId, {
    RTCVideoRenderer? localRenderer,
    RTCVideoRenderer? remoteRenderer,
  }) async {
    _isClosed = true;

    try { await _answerSub?.cancel(); } catch (_) {}
    try { await _callerCandidatesSub?.cancel(); } catch (_) {}
    try { await _calleeCandidatesSub?.cancel(); } catch (_) {}
    try { await _statusSub?.cancel(); } catch (_) {}

    try {
      await FirebaseDatabase.instance.ref('calls/$roomId/status').set('ended');
    } catch (_) {}

    try { localRenderer?.srcObject = null; } catch (_) {}
    try { remoteRenderer?.srcObject = null; } catch (_) {}

    await _cleanupLocalStream();

    if (_remoteStream != null) {
      try { await _remoteStream!.dispose(); } catch (_) {}
      _remoteStream = null;
    }

    if (_peerConnection != null) {
      try { await _peerConnection!.close(); } catch (_) {}
      _peerConnection = null;
    }
  }

  // ───────────── PRIVATE CLEANUP ─────────────
  Future<void> _cleanupLocalStream() async {
    if (localStream != null) {
      try {
        for (final t in localStream!.getTracks()) {
          try { t.stop(); } catch (_) {}
        }
        await localStream!.dispose();
      } catch (_) {}
      localStream = null;
    }
  }
}
