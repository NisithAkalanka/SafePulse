import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

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

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

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
      text: 'Yes, I accepted. I’m on my way.',
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

    _playerCompleteSub =
        _audioPlayer.onPlayerComplete.listen((_) {
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
    _audioPlayer.dispose();
    _recorder.dispose();
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
      final replyText = reply[DateTime.now().millisecondsSinceEpoch % reply.length];

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
          _ChatMessage(
            fromMe: false,
            text: replyText,
            time: DateTime.now(),
          ),
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
          text: _controller.text.trim().isEmpty ? null : _controller.text.trim(),
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
                  leading: const Icon(Icons.photo_camera_rounded, color: Colors.redAccent),
                  title: const Text('Camera'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: Colors.redAccent),
                  title: const Text('Gallery'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                // PDF/doc support needs `file_picker` + backend storage. We keep it as a placeholder for now.
                ListTile(
                  leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.grey),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFFFEAEA),
              child: Icon(Icons.person_rounded, color: Colors.redAccent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _helperTyping ? 'Typing…' : 'Online',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                ),
                if (_showStudyTools) ...[
                  const SizedBox(width: 10),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _formatElapsed(_elapsed),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
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
          IconButton(
            tooltip: 'Mark resolved & rate helper',
            icon: const Icon(Icons.check_circle_rounded),
            onPressed: () async {
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
                                    color: selected ? Colors.amber : Colors.grey,
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
                              backgroundColor: Colors.redAccent,
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
                SnackBar(content: Text('Thanks! Session resolved. Rating: $rating/5')),
              );
            },
          ),
          IconButton(
            tooltip: 'Report / Block (placeholder)',
            icon: const Icon(Icons.report_gmailerrorred_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report/Block not implemented in demo UI yet.')),
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[_messages.length - 1 - index];
                final alignment =
                    m.fromMe ? Alignment.centerRight : Alignment.centerLeft;
                final color = m.fromMe ? Colors.redAccent : Colors.white;
                final textColor = m.fromMe ? Colors.white : Colors.black87;

                return Align(
                  alignment: alignment,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: m.fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                            ((m.audioPath != null) || (m.text?.isNotEmpty ?? false)))
                          const SizedBox(height: 8),
                        if (m.audioPath != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: m.fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                icon: Icon(
                                  (_playingAudioPath == m.audioPath && _isPlayingAudio)
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: textColor,
                                ),
                                onPressed: () => _togglePlayAudio(m.audioPath!),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Voice message',
                                style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                              if (m.audioDuration != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  _formatElapsed(m.audioDuration!),
                                  style: TextStyle(color: textColor.withOpacity(0.9), fontWeight: FontWeight.w700, fontSize: 11),
                                ),
                              ],
                            ],
                          ),
                        if (m.audioPath != null && (m.text?.isNotEmpty ?? false))
                          const SizedBox(height: 8),
                        if (m.text != null && m.text!.isNotEmpty)
                          Text(
                            m.text!,
                            style: TextStyle(color: textColor, height: 1.25),
                          ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment:
                              m.fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(m.time),
                              style: TextStyle(
                                fontSize: 11,
                                color: m.fromMe ? Colors.white70 : Colors.grey.shade600,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (m.fromMe) ...[
                              const SizedBox(width: 8),
                              Icon(
                                m.status == MessageStatus.read
                                    ? Icons.done_all_rounded
                                    : Icons.check_rounded,
                                size: 16,
                                color: m.status == MessageStatus.read
                                    ? Colors.white
                                    : Colors.white70,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, -4),
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
                        icon: const Icon(Icons.attach_file_rounded, color: Colors.redAccent),
                      ),
                      IconButton(
                        tooltip: 'Voice note',
                        onPressed: _isResolved ? null : _toggleRecording,
                        icon: Icon(
                          _isRecording ? Icons.stop_rounded : Icons.mic_none_rounded,
                          color: _isRecording ? Colors.redAccent : Colors.grey,
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
                              color: Colors.redAccent,
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
                            hintText: 'Type a message…',
                            filled: true,
                            fillColor: const Color(0xFFF5F5F7),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: (_canSend && !_isRecording) ? _send : null,
                          child: const Icon(Icons.send_rounded, size: 18),
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
          border: Border.all(color: Colors.redAccent.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.redAccent.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.redAccent),
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

