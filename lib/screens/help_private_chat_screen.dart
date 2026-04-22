import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/guardian_ui.dart';

/// Outgoing bubble — coral red (matches Help chat reference UI).
const Color _kOutgoingBubble = Color(0xFFFF5252);

class HelpPrivateChatScreen extends StatefulWidget {
  final String requestId;
  final String title;
  final String subtitle;

  const HelpPrivateChatScreen({
    super.key,
    required this.requestId,
    required this.title,
    required this.subtitle,
  });

  @override
  State<HelpPrivateChatScreen> createState() => _HelpPrivateChatScreenState();
}

class _HelpPrivateChatScreenState extends State<HelpPrivateChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  bool _canSend = false;

  bool _helperTyping = false;
  Timer? _typingTimer;

  final AudioPlayer _audioPlayer = AudioPlayer();
  late final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  Duration _recordedDuration = Duration.zero;
  Timer? _recordTimer;

  String? _playingAudioPath;
  bool _isPlayingAudio = false;
  StreamSubscription<void>? _playerCompleteSub;

  Timer? _elapsedTimer;
  Duration _elapsed = Duration.zero;
  bool _isResolved = false;
  late final DateTime _sessionStart = DateTime.now();

  bool _chatProceeded = false;
  String? _requestCreatorUid;
  String? _requestHelperUid;

  bool get _isRequester {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    if (_requestCreatorUid != null) return uid == _requestCreatorUid;
    if (_requestHelperUid != null) return uid != _requestHelperUid;
    // Keep requester-side gate safe until role fields load.
    return true;
  }

  bool get _canCurrentUserSend => _chatProceeded || !_isRequester;

  String get _chatMode =>
      widget.title.toLowerCase().contains('study') ? 'study' : 'general';

  bool get _showStudyTools => _chatMode == 'study';

  final List<_ChatMessage> _messages = [];

  StreamSubscription<DocumentSnapshot>? _reqSub;
  StreamSubscription<QuerySnapshot>? _chatSub;

  @override
  void initState() {
    super.initState();
    _subscribeToChat();
    _controller.addListener(() {
      final next = _controller.text.trim().isNotEmpty;
      if (next != _canSend) {
        setState(() {
          _canSend = next;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(jump: true);
    });

    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlayingAudio = false;
        _playingAudioPath = null;
      });
    });

    _elapsed = DateTime.now().difference(_sessionStart);
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_sessionStart);
      });
    });
  }

  @override
  void dispose() {
    _reqSub?.cancel();
    _chatSub?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    _playerCompleteSub?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _subscribeToChat() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _reqSub = FirebaseFirestore.instance
        .collection('help_requests')
        .doc(widget.requestId)
        .snapshots()
        .listen((reqSnap) {
          if (!mounted) return;
          final data = reqSnap.data();
          if (data != null) {
            setState(() {
              _chatProceeded = data['chatProceeded'] == true;
              _requestCreatorUid = data['creatorUid'] as String?;
              _requestHelperUid = data['helperUid'] as String?;
            });
          }
        });

    _chatSub = FirebaseFirestore.instance
        .collection('help_requests')
        .doc(widget.requestId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          final List<_ChatMessage> updated = snap.docs.map((doc) {
            final data = doc.data();
            final senderUid = data['senderUid'] as String?;
            final createdAt = data['createdAt'];
            DateTime time;
            if (createdAt is Timestamp) {
              time = createdAt.toDate();
            } else if (createdAt is int) {
              time = DateTime.fromMillisecondsSinceEpoch(createdAt);
            } else {
              time = DateTime.now();
            }

            return _ChatMessage(
              fromMe: senderUid == uid,
              text: data['text'] as String?,
              imagePath: data['imagePath'] as String?,
              audioPath: data['audioPath'] as String?,
              audioDuration: data['audioDuration'] != null
                  ? Duration(milliseconds: data['audioDuration'] as int)
                  : null,
              time: time,
              status: senderUid == uid
                  ? MessageStatus.read
                  : MessageStatus.delivered,
            );
          }).toList();

          setState(() {
            _messages.clear();
            _messages.addAll(updated.reversed);
          });
          _scrollToBottom();
        });
  }

  Future<void> _proceedChat() async {
    if (!_isRequester) return;
    await FirebaseFirestore.instance
        .collection('help_requests')
        .doc(widget.requestId)
        .update({
          'chatProceeded': true,
          'chatProceededAt': FieldValue.serverTimestamp(),
        });
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scrollController.hasClients) return;
    // ListView is reversed -> offset 0 is the bottom (latest messages)
    if (jump) {
      _scrollController.jumpTo(0);
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submitRating(int rating) async {
    final messenger = ScaffoldMessenger.of(context);
    final helperUid = _requestHelperUid;

    if (helperUid != null) {
      try {
        final helperRef = FirebaseFirestore.instance
            .collection('users')
            .doc(helperUid);
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(helperRef);
          if (snapshot.exists) {
            final data = snapshot.data();
            if (data == null) return;

            final currentCount =
                (data['helper_rating_count'] as num?)?.toInt() ?? 0;
            final currentAvg =
                (data['helper_rating_avg'] as num?)?.toDouble() ?? 0.0;

            final newCount = currentCount + 1;
            final newAvg = ((currentAvg * currentCount) + rating) / newCount;

            String? newBadge;
            if (newAvg >= 4.5 && newCount >= 15) {
              newBadge = 'Gold';
            } else if (newAvg >= 4.0 && newCount >= 8) {
              newBadge = 'Silver';
            } else if (newAvg >= 3.5 && newCount >= 3) {
              newBadge = 'Bronze';
            }

            final updates = <String, dynamic>{
              'helper_rating_count': newCount,
              'helper_rating_avg': newAvg,
            };
            if (newBadge != null) {
              updates['helper_badge'] = newBadge;
            } else {
              updates['helper_badge'] = FieldValue.delete();
            }

            transaction.update(helperRef, updates);
          }
        });
      } catch (e) {
        debugPrint('Error updating helper rating: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _isResolved = true;
      _helperTyping = false;
    });

    messenger.showSnackBar(
      SnackBar(content: Text('Thanks! Session resolved. Rating: $rating/5')),
    );
  }

  Future<void> _togglePlayAudio(String audioPath) async {
    if (_isResolved) return;

    try {
      if (_playingAudioPath == audioPath) {
        if (_isPlayingAudio) {
          await _audioPlayer.pause();
          if (!mounted) return;
          setState(() {
            _isPlayingAudio = false;
          });
        } else {
          await _audioPlayer.resume();
          if (!mounted) return;
          setState(() {
            _isPlayingAudio = true;
          });
        }
        return;
      }

      await _audioPlayer.stop();
      if (!mounted) return;
      setState(() {
        _playingAudioPath = audioPath;
        _isPlayingAudio = true;
      });
      await _audioPlayer.play(DeviceFileSource(audioPath));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPlayingAudio = false;
        _playingAudioPath = null;
      });
    }
  }

  Future<void> _sendText(String text) async {
    if (_isResolved || _isRecording) return;
    if (!_canCurrentUserSend) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final msg = {
      'senderUid': user.uid,
      'senderName': user.displayName ?? 'User',
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    };

    _controller.clear();
    _scrollToBottom();
    _inputFocus.requestFocus();

    await FirebaseFirestore.instance
        .collection('help_requests')
        .doc(widget.requestId)
        .collection('messages')
        .add(msg);
  }

  Future<void> _send() => _sendText(_controller.text);

  Future<void> _pickImage(ImageSource source) async {
    if (_isResolved || _isRecording) return;
    if (!_canCurrentUserSend) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final msg = {
      'senderUid': user.uid,
      'senderName': user.displayName ?? 'User',
      'imagePath': picked.path,
      'text': _controller.text.trim().isEmpty ? null : _controller.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    _controller.clear();
    _scrollToBottom();
    _inputFocus.requestFocus();

    await FirebaseFirestore.instance
        .collection('help_requests')
        .doc(widget.requestId)
        .collection('messages')
        .add(msg);
  }

  Future<void> _sendAudioMessage(String audioPath, Duration duration) async {
    if (!_canCurrentUserSend) return;
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final msg = {
      'senderUid': user.uid,
      'senderName': user.displayName ?? 'User',
      'audioPath': audioPath,
      'audioDuration': duration.inMilliseconds,
      'createdAt': FieldValue.serverTimestamp(),
    };

    _scrollToBottom();
    _inputFocus.requestFocus();

    await FirebaseFirestore.instance
        .collection('help_requests')
        .doc(widget.requestId)
        .collection('messages')
        .add(msg);
  }

  Future<void> _showAttachmentSheet() async {
    if (_isResolved || _isRecording) return;
    if (!_canCurrentUserSend) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final sheetG = GuardianTheme.of(ctx);
        return Container(
          decoration: BoxDecoration(
            color: sheetG.panelBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Send attachment',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: sheetG.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_camera_rounded,
                      color: _kOutgoingBubble,
                    ),
                    title: Text(
                      'Camera',
                      style: TextStyle(
                        color: sheetG.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_rounded,
                      color: _kOutgoingBubble,
                    ),
                    title: Text(
                      'Gallery',
                      style: TextStyle(
                        color: sheetG.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.insert_drive_file_rounded,
                      color: sheetG.captionGrey,
                    ),
                    title: Text(
                      'Document (PDF) - coming soon',
                      style: TextStyle(
                        color: sheetG.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleRecording() async {
    if (_isResolved) return;
    if (!_canCurrentUserSend) return;

    if (_isRecording) {
      _recordTimer?.cancel();
      setState(() {
        _isRecording = false;
      });

      final audioPath = await _recorder.stop();
      final duration = _recordedDuration;
      _recordedDuration = Duration.zero;

      if (audioPath == null || audioPath.isEmpty) return;
      await _sendAudioMessage(audioPath, duration);
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Microphone permission is required for voice messages.',
          ),
        ),
      );
      return;
    }

    final tempDir = Directory.systemTemp;
    final audioPath =
        '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: audioPath);

    _recordTimer?.cancel();
    setState(() {
      _isRecording = true;
      _recordedDuration = Duration.zero;
    });

    _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _recordedDuration += const Duration(seconds: 1);
      });
    });
  }

  /// Incoming: sharper bottom-left. Outgoing: sharper bottom-right (reference UI).
  BorderRadius _bubbleRadius(bool fromMe) {
    const r = 18.0;
    const tail = 5.0;
    if (fromMe) {
      return const BorderRadius.only(
        topLeft: Radius.circular(r),
        topRight: Radius.circular(r),
        bottomLeft: Radius.circular(r),
        bottomRight: Radius.circular(tail),
      );
    }
    return const BorderRadius.only(
      topLeft: Radius.circular(r),
      topRight: Radius.circular(r),
      bottomRight: Radius.circular(r),
      bottomLeft: Radius.circular(tail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = GuardianTheme.of(context);
    final chatBg = g.isDark ? g.scaffoldBg : const Color(0xFFEEEEF2);

    return Scaffold(
      backgroundColor: chatBg,
      appBar: AppBar(
        backgroundColor: g.panelBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        foregroundColor: g.textPrimary,
        iconTheme: IconThemeData(color: g.textPrimary),
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: g.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: g.chipBorder),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: GuardianUi.redTint,
              child: Icon(
                Icons.person_rounded,
                color: GuardianUi.redPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: g.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: g.captionGrey,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_showStudyTools) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: g.captionGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatElapsed(_elapsed),
                          style: TextStyle(
                            fontSize: 11,
                            color: g.captionGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E9E5A),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _helperTyping ? 'Typing…' : 'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: g.captionGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_chatMode == 'study')
            IconButton(
              tooltip: 'Whiteboard (coming soon)',
              icon: Icon(Icons.border_all_rounded, color: g.textPrimary),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Whiteboard coming soon.')),
                );
              },
            ),
          if (_isRequester)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Tooltip(
                  message: 'Rate the helper',
                  child: InkWell(
                    onTap: () async {
                      if (_isResolved) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Session already resolved.'),
                          ),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);
                      int rating = 5;
                      await showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (ctx) {
                          final dg = GuardianTheme.of(ctx);
                          return StatefulBuilder(
                            builder: (ctx, setStateDialog) {
                              return AlertDialog(
                                backgroundColor: dg.panelBg,
                                title: Text(
                                  'Rate the helper',
                                  style: TextStyle(
                                    color: dg.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'How was the study support?',
                                      style: TextStyle(color: dg.textSecondary),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      children: List.generate(5, (i) {
                                        final idx = i + 1;
                                        final selected = idx <= rating;
                                        return IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 34,
                                            minHeight: 34,
                                          ),
                                          icon: Icon(
                                            selected
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                            color: selected
                                                ? Colors.amber
                                                : dg.starEmpty,
                                            size: 28,
                                          ),
                                          onPressed: () {
                                            setStateDialog(() => rating = idx);
                                          },
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: dg.textSecondary),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kOutgoingBubble,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(ctx).pop();
                                      _submitRating(rating);
                                    },
                                    child: Text('Submit ($rating)'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: g.isDark
                            ? const Color(0xFF8D1218)
                            : GuardianUi.redPrimary,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Rate Helper',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Report / Info',
            icon: Icon(Icons.error_outline_rounded, color: g.textPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report/Block not implemented in demo UI yet.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_chatProceeded && _isRequester) _buildProceedPrompt(g),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[_messages.length - 1 - index];
                final alignment = m.fromMe
                    ? Alignment.centerRight
                    : Alignment.centerLeft;
                final color = m.fromMe ? _kOutgoingBubble : g.panelBg;
                final textColor = m.fromMe ? Colors.white : g.textPrimary;

                return Align(
                  alignment: alignment,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: _bubbleRadius(m.fromMe),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: g.isDark ? 0.35 : 0.06,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: m.fromMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        if (m.imagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              File(m.imagePath!),
                              width: 240,
                              height: 140,
                              fit: BoxFit.cover,
                            ),
                          ),
                        if (m.imagePath != null &&
                            ((m.audioPath != null) ||
                                (m.text?.isNotEmpty ?? false)))
                          const SizedBox(height: 8),
                        if (m.audioPath != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: m.fromMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                icon: Icon(
                                  (_playingAudioPath == m.audioPath &&
                                          _isPlayingAudio)
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: textColor,
                                ),
                                onPressed: () => _togglePlayAudio(m.audioPath!),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Voice message',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              if (m.audioDuration != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  _formatElapsed(m.audioDuration!),
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.9),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        if (m.audioPath != null &&
                            (m.text?.isNotEmpty ?? false))
                          const SizedBox(height: 8),
                        if (m.text != null && m.text!.isNotEmpty)
                          Text(
                            m.text!,
                            style: TextStyle(
                              color: textColor,
                              height: 1.3,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: m.fromMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(m.time),
                              style: TextStyle(
                                fontSize: 11,
                                color: m.fromMe
                                    ? Colors.white.withOpacity(0.92)
                                    : g.captionGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (m.fromMe) ...[
                              const SizedBox(width: 6),
                              Icon(
                                m.status == MessageStatus.read
                                    ? Icons.done_all_rounded
                                    : Icons.check_rounded,
                                size: 15,
                                color: Colors.white.withOpacity(0.95),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_helperTyping)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: g.panelBg,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: g.isDark ? 0.35 : 0.07,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    'Helper is typing…',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: g.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            decoration: BoxDecoration(
              color: g.panelBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: g.isDark ? 0.4 : 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_showStudyTools)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _quickChip(
                            g,
                            'Can you explain more?',
                            'explain_more',
                          ),
                          _quickChip(g, "I’m stuck on this part.", 'stuck'),
                          _quickChip(g, 'Understood, thank you!', 'thanks'),
                          _quickChip(g, 'Send me the solution.', 'solution'),
                          _quickChip(g, 'Insert code block', 'code_block'),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Attachment',
                        onPressed: _showAttachmentSheet,
                        icon: const Icon(
                          Icons.attach_file_rounded,
                          color: _kOutgoingBubble,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Voice note',
                        onPressed: _isResolved ? null : _toggleRecording,
                        icon: Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : Icons.mic_none_rounded,
                          color: _isRecording
                              ? _kOutgoingBubble
                              : g.captionGrey,
                        ),
                      ),
                      if (_isRecording)
                        Padding(
                          padding: const EdgeInsets.only(left: 6, right: 6),
                          child: Text(
                            'Rec ${_formatElapsed(_recordedDuration)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kOutgoingBubble,
                            ),
                          ),
                        ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _inputFocus,
                          enabled: _canCurrentUserSend,
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(color: g.textPrimary),
                          onSubmitted: (_) {
                            if (!_isRecording) _send();
                          },
                          decoration: InputDecoration(
                            hintText: _canCurrentUserSend
                                ? 'Type a message...'
                                : 'Chat request pending...',
                            hintStyle: TextStyle(
                              color: g.textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: g.figmaFieldFill,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(26),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: (_canSend && !_isRecording)
                            ? (g.isDark
                                  ? GuardianUi.redPrimary
                                  : const Color(0xFF9E9E9E))
                            : (g.isDark
                                  ? const Color(0xFF3A3A45)
                                  : const Color(0xFFE0E0E0)),
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: (_canSend && !_isRecording) ? _send : null,
                          child: SizedBox(
                            width: 46,
                            height: 46,
                            child: Icon(
                              Icons.send_rounded,
                              size: 20,
                              color: (_canSend && !_isRecording)
                                  ? Colors.white
                                  : (g.isDark
                                        ? const Color(0xFF6A6A75)
                                        : const Color(0xFFBDBDBD)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickChip(GuardianTheme g, String label, String id) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        // quick one-tap send
        if (_isResolved || _isRecording) return;
        if (id == 'code_block') {
          _sendText('```dart\n// Paste your code here\n```');
          return;
        }
        _sendText(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: g.listItemBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kOutgoingBubble.withOpacity(0.28)),
          boxShadow: g.cardShadow,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _kOutgoingBubble,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _formatElapsed(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Widget _buildProceedPrompt(GuardianTheme g) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: g.panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kOutgoingBubble.withOpacity(0.3)),
        boxShadow: g.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.chat_bubble_outline_rounded,
            color: _kOutgoingBubble,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            "Helper has messaged you.",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: g.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Do you want to proceed with the chat?",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: g.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "CANCEL",
                    style: TextStyle(color: g.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOutgoingBubble,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _proceedChat,
                  child: const Text("PROCEED"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum MessageStatus { sent, delivered, read }

class _ChatMessage {
  final bool fromMe;
  final String? text;
  final String? imagePath;
  final String? audioPath;
  final Duration? audioDuration;
  final DateTime time;
  final MessageStatus status;

  const _ChatMessage({
    required this.fromMe,
    this.text,
    this.imagePath,
    this.audioPath,
    this.audioDuration,
    required this.time,
    this.status = MessageStatus.delivered,
  });

  _ChatMessage copyWithStatus(MessageStatus newStatus) {
    return _ChatMessage(
      fromMe: fromMe,
      text: text,
      imagePath: imagePath,
      audioPath: audioPath,
      audioDuration: audioDuration,
      time: time,
      status: newStatus,
    );
  }
}
