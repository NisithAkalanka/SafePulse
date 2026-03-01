import 'package:flutter/material.dart';

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
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
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

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(fromMe: true, text: text, time: DateTime.now()));
    });
    _controller.clear();
    _scrollToBottom();
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        foregroundColor: Colors.black,
        title: Column(
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
                    child: Text(
                      m.text,
                      style: TextStyle(color: textColor, height: 1.25),
                    ),
                  ),
                );
              },
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
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _inputFocus,
                      textInputAction: TextInputAction.send,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: const Color(0xFFF5F5F7),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                      onPressed: _canSend ? _send : null,
                      child: const Icon(Icons.send_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool fromMe;
  final String text;
  final DateTime time;

  const _ChatMessage({
    required this.fromMe,
    required this.text,
    required this.time,
  });
}

