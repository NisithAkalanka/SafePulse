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

class _MockChatScreenState extends State<MockChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const Color spRed = Color(0xFFE53935);

  bool _isSendingImage = false;
  bool _isRecording = false;
  bool _isSendingAudio = false;
  String? _currentRecordingPath;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  String? _playingMessageId;
  PlayerState _playerState = PlayerState.stopped;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  String get _myName =>
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Student';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();

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

  Widget _buildDoubleTick(bool isMe, Color color) {
    if (!isMe) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.done, size: 14, color: color),
        Transform.translate(
          offset: const Offset(-4, 0),
          child: Icon(Icons.done, size: 14, color: color),
        ),
      ],
    );
  }

  Widget _buildChatHeader(String headerName) {
    return Container(
      decoration: BoxDecoration(
        gradient: _isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF3B3B),
                  Color(0xFFE10613),
                  Color(0xFFB30012),
                  Color(0xFF140910),
                ],
                stops: [0.0, 0.35, 0.72, 1.0],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF4B4B),
                  Color(0xFFB31217),
                  Color(0xFF1B1B1B),
                ],
                stops: [0.0, 0.62, 1.0],
              ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight + 14,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: const Icon(Icons.person_outline, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  headerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
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
    required String senderName,
    required String time,
    required double bubbleMaxWidth,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color myBubbleText,
    required Color otherBubbleText,
    required Color myTickColor,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isMe ? spRed : cardBg,
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? myBubbleText : otherBubbleText,
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(0.88)
                            : textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) const SizedBox(width: 4),
                    if (isMe) _buildDoubleTick(isMe, myTickColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageBubble({
    required bool isMe,
    required String? imageBase64,
    required String senderName,
    required String time,
    required double bubbleMaxWidth,
    required Color cardBg,
    required Color textSecondary,
    required Color myTickColor,
  }) {
    Uint8List? imageBytes;
    try {
      if (imageBase64 != null && imageBase64.isNotEmpty) {
        imageBytes = base64Decode(imageBase64);
      }
    } catch (_) {}

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isMe ? spRed : cardBg,
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 6),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: imageBytes != null
                      ? Image.memory(
                          imageBytes,
                          fit: BoxFit.cover,
                          width: bubbleMaxWidth * 0.88,
                          height: 220,
                        )
                      : Container(
                          width: bubbleMaxWidth * 0.88,
                          height: 220,
                          color: Colors.black12,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, size: 34),
                          ),
                        ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(0.88)
                            : textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) const SizedBox(width: 4),
                    if (isMe) _buildDoubleTick(isMe, myTickColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAudioBubble({
    required String messageId,
    required bool isMe,
    required String? audioBase64,
    required dynamic audioDurationMs,
    required String senderName,
    required String time,
    required double bubbleMaxWidth,
    required Color cardBg,
    required Color textSecondary,
    required Color myTickColor,
  }) {
    final isPlayingThis =
        _playingMessageId == messageId && _playerState == PlayerState.playing;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isMe ? spRed : cardBg,
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
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 11,
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _playOrStopAudio(
                        messageId: messageId,
                        audioBase64: audioBase64,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(isMe ? 0.18 : 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlayingThis ? Icons.stop : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voice message',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatAudioDurationMs(audioDurationMs),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
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
                    Text(
                      time,
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(0.88)
                            : textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isMe) const SizedBox(width: 4),
                    if (isMe) _buildDoubleTick(isMe, myTickColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(Color inputBg, Color textPrimary, Color textSecondary) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        color: _isDark ? const Color(0xFF121217) : const Color(0xFFF6F6F7),
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
                  color: inputBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: _isDark
                        ? const Color(0xFF34343F)
                        : const Color(0xFFE3E4E8),
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
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      'Tap mic again to send',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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
                      color: inputBg,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _isDark
                            ? const Color(0xFF34343F)
                            : const Color(0xFFE3E4E8),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: _isSendingImage ? null : _pickAndSendImage,
                          splashRadius: 22,
                          icon: Icon(
                            _isSendingImage
                                ? Icons.hourglass_top_rounded
                                : Icons.add_photo_alternate_outlined,
                            color: textSecondary,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            maxLength: 500,
                            minLines: 1,
                            maxLines: 4,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Type message...',
                              hintStyle: TextStyle(
                                color: textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isSendingAudio ? null : _toggleRecording,
                          splashRadius: 22,
                          icon: Icon(
                            _isRecording
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none_rounded,
                            color: _isRecording
                                ? Colors.redAccent
                                : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 56,
                  height: 56,
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

  @override
  void dispose() {
    _recordTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double bubbleMaxWidth = MediaQuery.of(context).size.width * 0.76;

    final Color pageBg = _isDark
        ? const Color(0xFF121217)
        : const Color(0xFFF6F6F7);
    final Color cardBg = _isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = _isDark ? Colors.white : Colors.black;
    final Color textSecondary = _isDark
        ? const Color(0xFFB7BBC6)
        : Colors.grey.shade600;
    final Color inputBg = _isDark
        ? const Color(0xFF23232B)
        : const Color(0xFFF3F3F3);
    final Color myBubbleText = Colors.white;
    final Color otherBubbleText = textPrimary;
    final Color myTickColor = Colors.white.withOpacity(0.95);

    return Scaffold(
      backgroundColor: pageBg,
      body: StreamBuilder<LostItem?>(
        stream: LostFoundService().getItemStream(widget.itemId),
        builder: (context, itemSnapshot) {
          final item = itemSnapshot.data;
          final headerName = _headerName(item);

          return Column(
            children: [
              _buildChatHeader(headerName),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: LostFoundService().getMessagesStream(widget.itemId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            'Private chat opened for return coordination.',
                            style: TextStyle(
                              color: textSecondary,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottomSoon();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final msg = doc.data();
                        final isMe = msg['senderId'] == _myUid;
                        final text = (msg['text'] ?? '').toString();
                        final senderName = (msg['senderName'] ?? '').toString();
                        final ts = msg['timestamp'];
                        final time = _formatTime(ts);
                        final type = (msg['type'] ?? 'text').toString();
                        final imageBase64 = msg['image_data'] as String?;
                        final audioBase64 = msg['audio_data'] as String?;
                        final audioDurationMs = msg['audio_duration_ms'];

                        if (type == 'image') {
                          return _buildImageBubble(
                            isMe: isMe,
                            imageBase64: imageBase64,
                            senderName: senderName,
                            time: time,
                            bubbleMaxWidth: bubbleMaxWidth,
                            cardBg: cardBg,
                            textSecondary: textSecondary,
                            myTickColor: myTickColor,
                          );
                        }

                        if (type == 'audio') {
                          return _buildAudioBubble(
                            messageId: doc.id,
                            isMe: isMe,
                            audioBase64: audioBase64,
                            audioDurationMs: audioDurationMs,
                            senderName: senderName,
                            time: time,
                            bubbleMaxWidth: bubbleMaxWidth,
                            cardBg: cardBg,
                            textSecondary: textSecondary,
                            myTickColor: myTickColor,
                          );
                        }

                        return _buildTextBubble(
                          isMe: isMe,
                          text: text,
                          senderName: senderName,
                          time: time,
                          bubbleMaxWidth: bubbleMaxWidth,
                          cardBg: cardBg,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                          myBubbleText: myBubbleText,
                          otherBubbleText: otherBubbleText,
                          myTickColor: myTickColor,
                        );
                      },
                    );
                  },
                ),
              ),
              _buildInputBar(inputBg, textPrimary, textSecondary),
            ],
          );
        },
      ),
    );
  }
}
