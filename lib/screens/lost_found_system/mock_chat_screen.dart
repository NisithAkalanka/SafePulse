import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import 'lost_found_service.dart';
import 'lost_item_model.dart';
import 'lost_found_user_badge.dart';

class MockChatScreen extends StatefulWidget {
  final String itemId;
  final String otherUserName;
  final String itemName;

  const MockChatScreen({
    super.key,
    required this.itemId,
    required this.otherUserName,
    required this.itemName,
  });

  @override
  State<MockChatScreen> createState() => _MockChatScreenState();
}

class _MockChatScreenState extends State<MockChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const Color spRed = Color(0xFFE53935);
  static const Color waBlue = Color(0xFF53BDEB);

  bool _isSendingImage = false;
  bool _isRecording = false;
  bool _isSendingAudio = false;
  String? _currentRecordingPath;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  String? _playingMessageId;
  PlayerState _playerState = PlayerState.stopped;

  Timer? _presenceTimer;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  String get _myName =>
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Student';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBg =>
      _isDark ? const Color(0xFF0B141A) : const Color(0xFFECE5DD);

  Color get _headerBg =>
      _isDark ? const Color(0xFF1F2C34) : const Color(0xFFB31217);

  Color get _inputBg => _isDark ? const Color(0xFF202C33) : Colors.white;
  Color get _cardBg => _isDark ? const Color(0xFF202C33) : Colors.white;
  Color get _myBubbleBg =>
      _isDark ? const Color(0xFF005C4B) : const Color(0xFFDCF8C6);
  Color get _otherBubbleBg => _isDark ? const Color(0xFF202C33) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF111B21);
  Color get _textSecondary =>
      _isDark ? const Color(0xFF9FB3C8) : const Color(0xFF667781);

  bool _canAccessChat(LostItem? item) {
    if (item == null) return false;
    final bool isOwner = item.userId == _myUid;
    final bool isRequester = item.requesterId == _myUid;
    return item.chatEnabled && (isOwner || isRequester);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPresenceUpdates();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _playerState = state;
        if (state == PlayerState.stopped || state == PlayerState.completed) {
          _playingMessageId = null;
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateMyPresence(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _updateMyPresence(false);
    }
  }

  Future<void> _updateMyPresence(bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'is_online': online,
        'last_seen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _startPresenceUpdates() {
    _updateMyPresence(true);
    _presenceTimer?.cancel();
    _presenceTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateMyPresence(true);
    });
  }

  String? _validateMessage(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Message cannot be empty';
    if (v.length > 500) return 'Message must be 500 characters or less';
    return null;
  }

  String _formatTime(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    return 'Now';
  }

  String _formatDurationSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatAudioDurationMs(dynamic ms) {
    if (ms is! int || ms <= 0) return '0:00';
    final totalSeconds = (ms / 1000).round();
    return _formatDurationSeconds(totalSeconds);
  }

  String _posterDisplayName(LostItem item) {
    final first = (item.firstName ?? '').trim();
    final last = (item.lastName ?? '').trim();
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    if (item.userName.trim().isNotEmpty) return item.userName.trim();
    return 'Owner';
  }

  String _headerName(LostItem? item) {
    if (item == null) return widget.otherUserName;

    final isOwner = item.userId == _myUid;
    if (isOwner) {
      final requester = (item.requesterName ?? '').trim();
      if (requester.isNotEmpty) return requester;
      return widget.otherUserName;
    }

    return _posterDisplayName(item);
  }

  String _otherUserId(LostItem? item) {
    if (item == null) return '';
    if (item.userId == _myUid) {
      return item.requesterId ?? '';
    }
    return item.userId;
  }

  bool _isOnlineFromData(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['is_online'] == true) return true;

    final lastSeen = data['last_seen'];
    if (lastSeen is Timestamp) {
      final diff = DateTime.now().difference(lastSeen.toDate()).inMinutes;
      return diff <= 2;
    }
    return false;
  }

  String _onlineTextOnly(Map<String, dynamic>? data) {
    return _isOnlineFromData(data) ? 'Online' : '';
  }

  Future<void> _sendTextMessage() async {
    final error = _validateMessage(_msgController.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final text = _msgController.text.trim();
    _msgController.clear();

    await LostFoundService().sendTextMessage(
      itemId: widget.itemId,
      senderId: _myUid,
      senderName: _myName,
      text: text,
    );

    _scrollToBottomSoon();
    if (mounted) setState(() {});
  }

  Future<void> _pickAndSendImage() async {
    if (_isSendingImage) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );

      if (image == null) return;

      setState(() => _isSendingImage = true);

      await LostFoundService().sendImageMessage(
        itemId: widget.itemId,
        senderId: _myUid,
        senderName: _myName,
        imageFile: File(image.path),
      );

      if (!mounted) return;
      _scrollToBottomSoon();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send image: $e')));
    } finally {
      if (mounted) setState(() => _isSendingImage = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopAndSendRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
        return;
      }

      final path =
          '${Directory.systemTemp.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(const RecordConfig(), path: path);

      _currentRecordingPath = path;
      _recordSeconds = 0;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _recordSeconds++;
        });
      });

      if (!mounted) return;
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not start recording: $e')));
    }
  }

  Future<void> _stopAndSendRecording() async {
    if (_isSendingAudio) return;

    try {
      _recordTimer?.cancel();
      final path = await _recorder.stop();

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isSendingAudio = true;
      });

      final actualPath = path ?? _currentRecordingPath;
      if (actualPath == null) {
        throw Exception('Recording file not found.');
      }

      final file = File(actualPath);
      if (!await file.exists()) {
        throw Exception('Recorded file does not exist.');
      }

      await LostFoundService().sendAudioMessage(
        itemId: widget.itemId,
        senderId: _myUid,
        senderName: _myName,
        audioFile: file,
        audioDurationMs: _recordSeconds * 1000,
      );

      if (!mounted) return;
      _scrollToBottomSoon();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send voice message: $e')),
      );
    } finally {
      _currentRecordingPath = null;
      _recordSeconds = 0;
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isSendingAudio = false;
        });
      }
    }
  }

  Future<void> _playOrStopAudio({
    required String messageId,
    required String? audioBase64,
  }) async {
    if (audioBase64 == null || audioBase64.isEmpty) return;

    try {
      if (_playingMessageId == messageId &&
          _playerState == PlayerState.playing) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _playingMessageId = null;
        });
        return;
      }

      final Uint8List bytes = base64Decode(audioBase64);
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(bytes));

      if (!mounted) return;
      setState(() {
        _playingMessageId = messageId;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not play audio: $e')));
    }
  }

  void _scrollToBottomSoon() {
    Future.delayed(const Duration(milliseconds: 180), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  bool _isSeenByOther(Map<String, dynamic> data) {
    final List<dynamic> readBy = List<dynamic>.from(data['readBy'] ?? const []);
    return readBy.any((id) => id.toString() != _myUid);
  }

  Future<void> _markMessagesAsSeen(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    await LostFoundService().markMessagesAsSeen(
      itemId: widget.itemId,
      currentUserId: _myUid,
      docs: docs,
    );
  }

  Future<void> _showMessageActions({
    required String messageId,
    required Map<String, dynamic> data,
  }) async {
    final bool isMine = (data['senderId'] ?? '').toString() == _myUid;
    final String type = (data['type'] ?? 'text').toString();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              if (isMine && type == 'text')
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit message'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _showEditMessageDialog(messageId, data);
                  },
                ),
              if (isMine)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete for me'),
                  onTap: () async {
                    Navigator.pop(context);
                    await LostFoundService().deleteMessageForMe(
                      itemId: widget.itemId,
                      messageId: messageId,
                      currentUserId: _myUid,
                    );
                  },
                ),
              if (isMine)
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Delete for everyone',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await LostFoundService().deleteMessageForEveryone(
                      itemId: widget.itemId,
                      messageId: messageId,
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditMessageDialog(
    String messageId,
    Map<String, dynamic> data,
  ) async {
    final controller = TextEditingController(
      text: (data['text'] ?? '').toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Edit message',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(color: _textPrimary),
            decoration: InputDecoration(
              hintText: 'Type updated message',
              hintStyle: TextStyle(color: _textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: _isDark
                      ? const Color(0xFF34414A)
                      : const Color(0xFFD8DDE3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: waBlue),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: spRed),
              onPressed: () async {
                final updatedText = controller.text.trim();
                if (updatedText.isEmpty) return;
                await LostFoundService().editTextMessage(
                  itemId: widget.itemId,
                  messageId: messageId,
                  updatedText: updatedText,
                );
                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoubleTick(bool seen) {
    final Color tickColor = seen ? waBlue : _textSecondary;

    return SizedBox(
      width: 18,
      height: 12,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Icon(Icons.done_rounded, size: 13.5, color: tickColor),
          ),
          Positioned(
            left: 5.2,
            top: 0,
            child: Icon(Icons.done_rounded, size: 13.5, color: tickColor),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTitleWithBadge({
    required String headerName,
    required String badgeUserId,
  }) {
    return Row(
      children: [
        Flexible(
          child: Text(
            headerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (badgeUserId.trim().isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: LostFoundUserBadge(
              userId: badgeUserId,
              fontSize: 10.5,
              iconSize: 13,
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChatHeader({
    required String headerName,
    required String badgeUserId,
    required String subtitle,
    required bool online,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFF3B3B),
            Color(0xFFE10613),
            Color(0xFFB30012),
            Color(0xFF140910),
          ],
          stops: [0.0, 0.35, 0.72, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight + 18,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.18),
                    width: 1,
                  ),
                ),
                child: const Icon(Icons.person_outline, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderTitleWithBadge(
                      headerName: headerName,
                      badgeUserId: badgeUserId,
                    ),
                    if (online) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF25D366),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextBubble({
    required bool isMe,
    required String text,
    required String time,
    required bool seen,
    required bool edited,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: isMe ? _myBubbleBg : _otherBubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 9, 12, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (edited)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Text(
                        'edited',
                        style: TextStyle(color: _textSecondary, fontSize: 10),
                      ),
                    ),
                  Text(
                    time,
                    style: TextStyle(color: _textSecondary, fontSize: 11),
                  ),
                  if (isMe) const SizedBox(width: 4),
                  if (isMe) _buildDoubleTick(seen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageBubble({
    required bool isMe,
    required String imageBase64,
    required String time,
    required bool seen,
    required bool edited,
  }) {
    Uint8List? bytes;
    try {
      bytes = base64Decode(imageBase64);
    } catch (_) {}

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: isMe ? _myBubbleBg : _otherBubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: bytes != null
                    ? Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        width: 230,
                        height: 250,
                      )
                    : Container(
                        width: 230,
                        height: 250,
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (edited)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Text(
                        'edited',
                        style: TextStyle(color: _textSecondary, fontSize: 10),
                      ),
                    ),
                  Text(
                    time,
                    style: TextStyle(color: _textSecondary, fontSize: 11),
                  ),
                  if (isMe) const SizedBox(width: 4),
                  if (isMe) _buildDoubleTick(seen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioBubble({
    required bool isMe,
    required String messageId,
    required String audioBase64,
    required dynamic audioDurationMs,
    required String time,
    required bool seen,
    required bool edited,
  }) {
    final isPlaying =
        _playingMessageId == messageId && _playerState == PlayerState.playing;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.76,
        ),
        decoration: BoxDecoration(
          color: isMe ? _myBubbleBg : _otherBubbleBg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isMe
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isMe
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => _playOrStopAudio(
                      messageId: messageId,
                      audioBase64: audioBase64,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(isMe ? 0.18 : 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.stop : Icons.play_arrow_rounded,
                        color: isMe ? Colors.white : waBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice message',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAudioDurationMs(audioDurationMs),
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (edited)
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Text(
                        'edited',
                        style: TextStyle(color: _textSecondary, fontSize: 10),
                      ),
                    ),
                  Text(
                    time,
                    style: TextStyle(color: _textSecondary, fontSize: 11),
                  ),
                  if (isMe) const SizedBox(width: 4),
                  if (isMe) _buildDoubleTick(seen),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _inputBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isDark
                        ? const Color(0xFF34414A)
                        : const Color(0xFFD8DDE3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Recording... ${_formatDurationSeconds(_recordSeconds)}',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Tap mic again to send',
                      style: TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _inputBg,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: _isSendingImage ? null : _pickAndSendImage,
                          icon: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: _textSecondary,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            maxLength: 500,
                            minLines: 1,
                            maxLines: 4,
                            style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Message',
                              hintStyle: TextStyle(color: _textSecondary),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isSendingAudio ? null : _toggleRecording,
                          icon: Icon(
                            _isRecording
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none_rounded,
                            color: _isRecording
                                ? Colors.redAccent
                                : _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: spRed,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: spRed.withOpacity(0.28),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _sendTextMessage,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedScreen(
    String headerName,
    Color pageBg,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      children: [
        _buildChatHeader(
          headerName: headerName,
          badgeUserId: '',
          subtitle: '',
          online: false,
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 420),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, color: spRed, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      'Private chat',
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This chat can only be viewed by the two users involved in the conversation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _presenceTimer?.cancel();
    _updateMyPresence(false);
    _msgController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color pageBg = _pageBg;
    final Color cardBg = _cardBg;
    final Color textPrimary = _textPrimary;
    final Color textSecondary = _textSecondary;

    return StreamBuilder<LostItem?>(
      stream: LostFoundService().getItemStream(widget.itemId),
      builder: (context, itemSnap) {
        final LostItem? item = itemSnap.data;
        final String headerName = _headerName(item);
        final bool canAccess = _canAccessChat(item);
        final String otherUserId = _otherUserId(item);

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: pageBg,
          body: !canAccess
              ? _buildAccessDeniedScreen(
                  headerName,
                  pageBg,
                  cardBg,
                  textPrimary,
                  textSecondary,
                )
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: otherUserId.isEmpty
                      ? null
                      : FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .snapshots(),
                  builder: (context, userSnap) {
                    final otherUserData = userSnap.data?.data();
                    final bool online = _isOnlineFromData(otherUserData);
                    final String subtitle = _onlineTextOnly(otherUserData);

                    return Column(
                      children: [
                        _buildChatHeader(
                          headerName: headerName,
                          badgeUserId: otherUserId,
                          subtitle: subtitle,
                          online: online,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: pageBg),
                            child:
                                StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>
                                >(
                                  stream: LostFoundService().getMessagesStream(
                                    widget.itemId,
                                  ),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }

                                    final docs = snapshot.data!.docs.where((
                                      doc,
                                    ) {
                                      final data = doc.data();
                                      final hiddenFor = List<String>.from(
                                        data['hiddenFor'] ?? const [],
                                      );
                                      return !hiddenFor.contains(_myUid);
                                    }).toList();

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          _markMessagesAsSeen(docs);
                                          _scrollToBottomSoon();
                                        });

                                    if (docs.isEmpty) {
                                      return Center(
                                        child: Text(
                                          'No messages yet.',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      controller: _scrollController,
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        12,
                                        12,
                                        8,
                                      ),
                                      itemCount: docs.length,
                                      itemBuilder: (context, index) {
                                        final doc = docs[index];
                                        final data = doc.data();
                                        final bool isMe =
                                            (data['senderId'] ?? '') == _myUid;
                                        final String type =
                                            (data['type'] ?? 'text').toString();
                                        final String time = _formatTime(
                                          data['timestamp'],
                                        );
                                        final bool seen =
                                            isMe && _isSeenByOther(data);
                                        final bool edited =
                                            data['edited'] == true;
                                        final bool deletedForEveryone =
                                            data['deletedForEveryone'] == true;

                                        return GestureDetector(
                                          onLongPress: isMe
                                              ? () => _showMessageActions(
                                                  messageId: doc.id,
                                                  data: data,
                                                )
                                              : null,
                                          child: deletedForEveryone
                                              ? _buildTextBubble(
                                                  isMe: isMe,
                                                  text:
                                                      (data['text'] ??
                                                              'This message was deleted')
                                                          .toString(),
                                                  time: time,
                                                  seen: seen,
                                                  edited: false,
                                                )
                                              : type == 'image'
                                              ? _buildImageBubble(
                                                  isMe: isMe,
                                                  imageBase64:
                                                      (data['image_data'] ?? '')
                                                          .toString(),
                                                  time: time,
                                                  seen: seen,
                                                  edited: edited,
                                                )
                                              : type == 'audio'
                                              ? _buildAudioBubble(
                                                  isMe: isMe,
                                                  messageId: doc.id,
                                                  audioBase64:
                                                      (data['audio_data'] ?? '')
                                                          .toString(),
                                                  audioDurationMs:
                                                      data['audio_duration_ms'],
                                                  time: time,
                                                  seen: seen,
                                                  edited: edited,
                                                )
                                              : _buildTextBubble(
                                                  isMe: isMe,
                                                  text: (data['text'] ?? '')
                                                      .toString(),
                                                  time: time,
                                                  seen: seen,
                                                  edited: edited,
                                                ),
                                        );
                                      },
                                    );
                                  },
                                ),
                          ),
                        ),
                        _buildInputBar(),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}
