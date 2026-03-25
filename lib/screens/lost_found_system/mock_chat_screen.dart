import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lost_found_service.dart';

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

  static const Color spRed = Color(0xFFE53935);

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  String get _myName =>
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Student';

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

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

  Future<void> _sendMessage() async {
    final error = _validateMessage(_msgController.text);
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final text = _msgController.text.trim();
    _msgController.clear();

    await LostFoundService().sendMessage(
      itemId: widget.itemId,
      senderId: _myUid,
      senderName: _myName,
      text: text,
    );

    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });

    if (mounted) {
      setState(() {});
    }
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

  Widget _buildChatHeader(Color textPrimary) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF4B4B), Color(0xFFB31217), Color(0xFF1B1B1B)],
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
                  widget.otherUserName,
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

  Widget _buildInputBar(Color inputBg, Color textPrimary, Color textSecondary) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        color: _isDark ? const Color(0xFF121217) : const Color(0xFFF6F6F7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                      onPressed: () {},
                      splashRadius: 22,
                      icon: Icon(
                        Icons.add_photo_alternate_outlined,
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
                      onPressed: () {},
                      splashRadius: 22,
                      icon: Icon(Icons.mic_none_rounded, color: textSecondary),
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
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
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
      body: Column(
        children: [
          _buildChatHeader(textPrimary),
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
                        "Private chat opened for return coordination.",
                        style: TextStyle(
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final msg = docs[index].data();
                    final isMe = msg['senderId'] == _myUid;
                    final text = (msg['text'] ?? '').toString();
                    final senderName = (msg['senderName'] ?? '').toString();
                    final ts = msg['timestamp'];
                    final time = _formatTime(ts);

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
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
                                    color: isMe
                                        ? myBubbleText
                                        : otherBubbleText,
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
                                    if (isMe)
                                      _buildDoubleTick(isMe, myTickColor),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(inputBg, textPrimary, textSecondary),
        ],
      ),
    );
  }
}
