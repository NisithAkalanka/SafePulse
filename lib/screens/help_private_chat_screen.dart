import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../theme/guardian_ui.dart';

/// Outgoing bubble — coral red (matches Help chat reference UI).
const Color _kOutgoingBubble = Color(0xFFFF5252);
const Color _kChatScreenBg = Color(0xFFEEEEF2);

class HelpPrivateChatScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const HelpPrivateChatScreen({
    super.key,
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

  String get _chatMode =>
      widget.title.toLowerCase().contains('study') ? 'study' : 'general';

  bool get _showStudyTools => _chatMode == 'study';

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      fromMe: false,
      text: 'Hi, can you help?',
      time: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
    _ChatMessage(
      fromMe: true,
      text: "Yes, I accepted. I'm on my way.",
      time: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
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
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          fromMe: true,
          text: text.trim(),
          time: DateTime.now(),
          status: MessageStatus.sent,
        ),
      );
      _helperTyping = true;
    });

    _controller.clear();
    _scrollToBottom();
    _inputFocus.requestFocus();

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      // Local "typing -> reply" simulation (since this chat UI is currently dummy/local).
      final reply = _chatMode == 'study'
          ? const [
              'Sure. Can you share what you tried so far?',
              'I can explain that step-by-step.',
              'Let’s break it down together.',
            ]
          : const [
              'Thanks! I will respond shortly.',
              'Sure — tell me what you need.',
              'Okay, I can help.',
            ];
      final replyText =
          reply[DateTime.now().millisecondsSinceEpoch % reply.length];

      if (!mounted) return;
      setState(() {
        _helperTyping = false;
        // Mark last user message as delivered/read when helper replies.
        for (var i = _messages.length - 1; i >= 0; i--) {
          final m = _messages[i];
          if (m.fromMe) {
            _messages[i] = m.copyWithStatus(MessageStatus.read);
            break;
          }
        }
        _messages.add(
          _ChatMessage(fromMe: false, text: replyText, time: DateTime.now()),
        );
      });
      _scrollToBottom();
    });
  }

  Future<void> _send() => _sendText(_controller.text);

  Future<void> _pickImage(ImageSource source) async {
    if (_isResolved || _isRecording) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatMessage(
          fromMe: true,
          text: _controller.text.trim().isEmpty
              ? null
              : _controller.text.trim(),
          imagePath: picked.path,
          time: DateTime.now(),
          status: MessageStatus.sent,
        ),
      );
      _helperTyping = true;
    });

    _controller.clear();
    _scrollToBottom();
    _inputFocus.requestFocus();

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _helperTyping = false;
        for (var i = _messages.length - 1; i >= 0; i--) {
          final m = _messages[i];
          if (m.fromMe) {
            _messages[i] = m.copyWithStatus(MessageStatus.read);
            break;
          }
        }
        _messages.add(
          _ChatMessage(
            fromMe: false,
            text: _chatMode == 'study'
                ? 'Got it. I’ll check the image and explain the next steps.'
                : 'Thanks for sharing.',
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  Future<void> _showAttachmentSheet() async {
    if (_isResolved || _isRecording) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send attachment',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(
                    Icons.photo_camera_rounded,
                    color: _kOutgoingBubble,
                  ),
                  title: const Text('Camera'),
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
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                // PDF/doc support needs `file_picker` + backend storage. We keep it as a placeholder for now.
                ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file_rounded,
                    color: Colors.grey,
                  ),
                  title: const Text('Document (PDF) - coming soon'),
                  onTap: () => Navigator.of(ctx).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  Future<void> _sendAudioMessage(String audioPath, Duration duration) async {
    if (!mounted) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          fromMe: true,
          text: null,
          imagePath: null,
          audioPath: audioPath,
          audioDuration: duration,
          time: DateTime.now(),
          status: MessageStatus.sent,
        ),
      );
      _helperTyping = true;
    });

    _scrollToBottom();
    _inputFocus.requestFocus();

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _helperTyping = false;
        for (var i = _messages.length - 1; i >= 0; i--) {
          final m = _messages[i];
          if (m.fromMe) {
            _messages[i] = m.copyWithStatus(MessageStatus.read);
            break;
          }
        }
        _messages.add(
          _ChatMessage(
            fromMe: false,
            text: _chatMode == 'study'
                ? 'Got it. I’ll listen and explain the next steps.'
                : 'Thanks for the voice message.',
            time: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    });
  }

  Future<void> _toggleRecording() async {
    if (_isResolved) return;

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
        const SnackBar(content: Text('Microphone permission is required for voice messages.')),
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
    return Scaffold(
      backgroundColor: _kChatScreenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        foregroundColor: GuardianUi.textPrimary,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE8E8EC)),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: GuardianUi.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_showStudyTools) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.timer_outlined,
                          size: 13,
                          color: Color(0xFF9E9E9E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatElapsed(_elapsed),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9E9E9E),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
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
              icon: const Icon(Icons.border_all_rounded),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Whiteboard coming soon.')),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Tooltip(
                message: 'Mark resolved & rate helper',
                child: InkWell(
                  onTap: () async {
              if (_isResolved) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Session already resolved.')),
                );
                return;
              }

              final messenger = ScaffoldMessenger.of(context);
              int rating = 5;
              await showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (ctx) {
                  return StatefulBuilder(
                    builder: (ctx, setStateDialog) {
                      return AlertDialog(
                        title: const Text('Rate the helper'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'How was the study support?',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
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
                                        : Colors.grey,
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
                            child: const Text('Cancel'),
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
                            },
                            child: Text('Submit ($rating)'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (!mounted) return;
              setState(() {
                _isResolved = true;
                _helperTyping = false;
              });

              messenger.showSnackBar(
                SnackBar(
                  content: Text('Thanks! Session resolved. Rating: $rating/5'),
                ),
              );
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1B1B22),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Report / Info',
            icon: const Icon(Icons.error_outline_rounded),
            color: GuardianUi.textPrimary,
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
                final color = m.fromMe ? _kOutgoingBubble : Colors.white;
                final textColor =
                    m.fromMe ? Colors.white : GuardianUi.textPrimary;

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
                          color: Colors.black.withOpacity(0.06),
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
                                    : const Color(0xFF757575),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Helper is typing…',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, -3),
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
                          _quickChip('Can you explain more?', 'explain_more'),
                          _quickChip("I’m stuck on this part.", 'stuck'),
                          _quickChip('Understood, thank you!', 'thanks'),
                          _quickChip('Send me the solution.', 'solution'),
                          _quickChip('Insert code block', 'code_block'),
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
                              : const Color(0xFF9E9E9E),
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
                          textInputAction: TextInputAction.send,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) {
                            if (!_isRecording) _send();
                          },
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFEFEFEF),
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
                            ? const Color(0xFF9E9E9E)
                            : const Color(0xFFE0E0E0),
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
                                  : const Color(0xFFBDBDBD),
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

  Widget _quickChip(String label, String id) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _kOutgoingBubble.withOpacity(0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: _kOutgoingBubble.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
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
