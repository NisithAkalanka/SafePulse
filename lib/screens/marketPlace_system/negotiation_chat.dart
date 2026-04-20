import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class NegotiationChat extends StatefulWidget {
  final String? docId;
  final String? itemName;
  final String? itemPrice;
  final String? itemImage;
  final String? initialMessage;
  final String? sellerId;
  final String? buyerId;

  const NegotiationChat({
    super.key,
    this.docId,
    this.itemName,
    this.itemPrice,
    this.itemImage,
    this.initialMessage,
    this.sellerId,
    this.buyerId,
  });

  @override
  State<NegotiationChat> createState() => _NegotiationChatState();
}

class _NegotiationChatState extends State<NegotiationChat> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  bool _isUploading = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentPlayingUrl;
  String? _recordingPath;
  String? _resolvedBuyerId;

  @override
  void initState() {
    super.initState();
    _initChat();
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentPlayingUrl = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _initChat() async {
    _resolvedBuyerId = widget.buyerId;

    if (_resolvedBuyerId == null || _resolvedBuyerId!.isEmpty) {
      if (currentUserId != null &&
          widget.sellerId != null &&
          currentUserId != widget.sellerId) {
        _resolvedBuyerId = currentUserId;
      }
    }

    await _ensureChatRoom();

    if (widget.initialMessage != null &&
        widget.initialMessage!.trim().isNotEmpty &&
        widget.docId != null) {
      await _checkAndSendInitialMessage();
    }
  }

  String? get _chatRoomId {
    if (widget.docId == null ||
        widget.sellerId == null ||
        _resolvedBuyerId == null ||
        _resolvedBuyerId!.isEmpty) {
      return null;
    }
    return "${widget.docId}_${widget.sellerId}_${_resolvedBuyerId}";
  }

  CollectionReference<Map<String, dynamic>>? get _messagesRef {
    final roomId = _chatRoomId;
    if (roomId == null || widget.docId == null) return null;

    return FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.docId)
        .collection('privateChats')
        .doc(roomId)
        .collection('messages');
  }

  DocumentReference<Map<String, dynamic>>? get _chatRoomRef {
    final roomId = _chatRoomId;
    if (roomId == null || widget.docId == null) return null;

    return FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.docId)
        .collection('privateChats')
        .doc(roomId);
  }

  Future<void> _ensureChatRoom() async {
    final roomRef = _chatRoomRef;
    if (roomRef == null || currentUserId == null) return;

    await roomRef.set({
      'listingId': widget.docId,
      'itemName': widget.itemName,
      'itemImage': widget.itemImage,
      'itemPrice': widget.itemPrice,
      'sellerId': widget.sellerId,
      'buyerId': _resolvedBuyerId,
      'participants': [widget.sellerId, _resolvedBuyerId],
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageType': 'text',
    }, SetOptions(merge: true));
  }

  Future<void> _checkAndSendInitialMessage() async {
    final chatRef = _messagesRef;
    if (chatRef == null) return;

    final existingMessages = await chatRef.limit(1).get();
    if (existingMessages.docs.isEmpty && widget.initialMessage != null) {
      await _sendTextMessage(widget.initialMessage!);
    }
  }

  Future<String> _getCurrentUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User";

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] ??
            data['fullName'] ??
            data['username'] ??
            data['first_name'] ??
            user.displayName ??
            user.email?.split('@').first ??
            "User";
      }
    } catch (_) {}

    return user.displayName ?? user.email?.split('@').first ?? "User";
  }

  Future<void> _updateChatRoomPreview({
    required String preview,
    required String type,
  }) async {
    final roomRef = _chatRoomRef;
    if (roomRef == null) return;

    await roomRef.set({
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': preview,
      'lastMessageType': type,
    }, SetOptions(merge: true));
  }

  Future<void> _sendNotification({
    required String preview,
    required String type,
  }) async {
    if (currentUserId == null) return;

    String receiverId = "";
    if (currentUserId == widget.sellerId) {
      receiverId = _resolvedBuyerId ?? "";
    } else {
      receiverId = widget.sellerId ?? "";
    }

    if (receiverId.isEmpty) return;

    final currentUserName = await _getCurrentUserName();

    await FirebaseFirestore.instance.collection('market_notifications').add({
      'userId': receiverId,
      'title':
          "Message from ${currentUserId == widget.sellerId ? 'Seller' : 'Buyer'}",
      'message': preview,
      'senderId': currentUserId,
      'senderName': currentUserName,
      'itemId': widget.docId,
      'itemName': widget.itemName ?? "Item",
      'itemImage': widget.itemImage ?? "",
      'sellerId': widget.sellerId ?? "",
      'buyerId': _resolvedBuyerId ?? "",
      'messageType': type == 'text' ? 'chat' : type,
      'chatRoomId': _chatRoomId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _sendTextMessage(String text) async {
    final chatRef = _messagesRef;
    if (chatRef == null || currentUserId == null) return;
    if (text.trim().isEmpty) return;

    try {
      final currentUserName = await _getCurrentUserName();

      await chatRef.add({
        'senderId': currentUserId,
        'senderName': currentUserName,
        'messageType': 'text',
        'msg': text.trim(),
        'fileUrl': '',
        'fileName': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _updateChatRoomPreview(preview: text.trim(), type: 'text');
      await _sendNotification(preview: text.trim(), type: 'text');

      _msgController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint("Messaging Error: $e");
    }
  }

  Future<String> _uploadFile(File file, String folder) async {
    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}";
    final ref = FirebaseStorage.instance
        .ref()
        .child('marketplace_chat')
        .child(widget.docId ?? 'unknown_listing')
        .child(_chatRoomId ?? 'unknown_room')
        .child(folder)
        .child(fileName);

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _sendImageMessage() async {
    final chatRef = _messagesRef;
    if (chatRef == null || currentUserId == null) return;

    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (picked == null) return;

      setState(() => _isUploading = true);

      final currentUserName = await _getCurrentUserName();
      final imageUrl = await _uploadFile(File(picked.path), 'images');

      await chatRef.add({
        'senderId': currentUserId,
        'senderName': currentUserName,
        'messageType': 'image',
        'msg': '',
        'fileUrl': imageUrl,
        'fileName': p.basename(picked.path),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _updateChatRoomPreview(preview: "📷 Photo", type: 'image');
      await _sendNotification(preview: "📷 Photo", type: 'image');

      _scrollToBottom();
    } catch (e) {
      debugPrint("Image upload error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingPath = path;
        });
      }

      if (path != null) {
        await _sendVoiceMessage(File(path));
      }
      return;
    }

    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _snack("Microphone permission denied");
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        "${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a";

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );

    if (mounted) {
      setState(() {
        _isRecording = true;
        _recordingPath = path;
      });
    }
  }

  Future<void> _sendVoiceMessage(File audioFile) async {
    final chatRef = _messagesRef;
    if (chatRef == null || currentUserId == null) return;

    try {
      setState(() => _isUploading = true);

      final currentUserName = await _getCurrentUserName();
      final audioUrl = await _uploadFile(audioFile, 'voices');

      await chatRef.add({
        'senderId': currentUserId,
        'senderName': currentUserName,
        'messageType': 'audio',
        'msg': '',
        'fileUrl': audioUrl,
        'fileName': p.basename(audioFile.path),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _updateChatRoomPreview(preview: "🎤 Voice message", type: 'audio');
      await _sendNotification(preview: "🎤 Voice message", type: 'audio');

      _scrollToBottom();
    } catch (e) {
      debugPrint("Voice upload error: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _playAudio(String url) async {
    try {
      if (_currentPlayingUrl == url && _isPlaying) {
        await _audioPlayer.stop();
        if (mounted) {
          setState(() {
            _isPlaying = false;
            _currentPlayingUrl = null;
          });
        }
        return;
      }

      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(url));

      if (mounted) {
        setState(() {
          _isPlaying = true;
          _currentPlayingUrl = url;
        });
      }
    } catch (e) {
      debugPrint("Audio play error: $e");
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmAndMarkAsSold() async {
    if (widget.docId == null || currentUserId == null) return;

    try {
      String? buyerId = _resolvedBuyerId;

      if (buyerId == null || buyerId.isEmpty) {
        final roomRef = _chatRoomRef;
        final roomSnap = await roomRef?.get();
        if (roomSnap != null && roomSnap.exists) {
          buyerId = roomSnap.data()?['buyerId'];
        }
      }

      if (buyerId == null || buyerId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Buyer not found for this chat")),
          );
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.docId)
          .update({
            'status': 'Sold',
            'soldAt': FieldValue.serverTimestamp(),
            'buyerId': buyerId,
            'isRated': false,
          });

      await FirebaseFirestore.instance.collection('market_notifications').add({
        'userId': buyerId,
        'title': 'Deal Completed',
        'message':
            'Your purchase for ${widget.itemName ?? "this item"} is complete. You can now rate the seller.',
        'senderId': currentUserId,
        'senderName': 'Seller',
        'itemId': widget.docId,
        'sellerId': widget.sellerId ?? "",
        'buyerId': buyerId,
        'itemName': widget.itemName ?? "Item",
        'itemImage': widget.itemImage ?? "",
        'messageType': 'rate_seller',
        'chatRoomId': _chatRoomId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item marked as sold successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Sold Status Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to mark as sold: $e")));
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    final dt = (timestamp as Timestamp).toDate();
    return DateFormat('hh:mm a').format(dt);
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> data,
    bool isMe,
    bool isDark,
    Color textPrimary,
  ) {
    final String type = data['messageType'] ?? 'text';
    final String senderName = data['senderName'] ?? 'User';

    if (type == 'image') {
      final imageUrl = data['fileUrl'] ?? '';
      return Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              width: 220,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                width: 220,
                height: 220,
                color: Colors.black12,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatTimestamp(data['createdAt']),
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    if (type == 'audio') {
      final audioUrl = data['fileUrl'] ?? '';
      final bool isThisPlaying = _currentPlayingUrl == audioUrl && _isPlaying;

      return Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            senderName,
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withOpacity(0.10)
                  : (isDark
                        ? const Color(0xFF2B2B33)
                        : const Color(0xFFF3F5F7)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _playAudio(audioUrl),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isMe ? Colors.white : gRedMid,
                    child: Icon(
                      isThisPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: isMe ? gRedMid : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Voice message",
                      style: TextStyle(
                        color: isMe ? Colors.white : textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 110,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white60 : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatTimestamp(data['createdAt']),
            style: TextStyle(
              color: isMe ? Colors.white70 : Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          senderName,
          style: TextStyle(
            color: isMe ? Colors.white70 : Colors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          data['msg'] ?? "",
          style: TextStyle(
            color: isMe ? Colors.white : textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatTimestamp(data['createdAt']),
          style: TextStyle(
            color: isMe ? Colors.white70 : Colors.grey,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), duration: const Duration(milliseconds: 900)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color borderColor = isDark
        ? const Color(0xFF34343F)
        : const Color(0xFFE8EAF0);

    final bool isSeller = currentUserId == widget.sellerId;

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gRedStart, gRedMid, gDarkEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.62, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Inquiry Chat",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (_isUploading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            (widget.itemImage != null &&
                                widget.itemImage!.length > 100)
                            ? Image.memory(
                                base64Decode(widget.itemImage!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                color: Colors.white12,
                                child: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemName ?? "Product",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Rs. ${widget.itemPrice ?? "0"}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSeller)
                        ElevatedButton(
                          onPressed: _confirmAndMarkAsSold,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: gRedMid,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text(
                            "MARK SOLD",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _messagesRef == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _messagesRef!
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) {
                          final data = docs[i].data();
                          final bool isMe = data['senderId'] == currentUserId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 290),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? gRedMid
                                    : (isDark
                                          ? const Color(0xFF23232B)
                                          : Colors.white),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: _buildMessageBubble(
                                data,
                                isMe,
                                isDark,
                                textPrimary,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 36),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isUploading ? null : _sendImageMessage,
                  icon: const Icon(Icons.image_outlined),
                  color: gRedMid,
                ),
                IconButton(
                  onPressed: _isUploading ? null : _toggleVoiceRecording,
                  icon: Icon(
                    _isRecording ? Icons.stop_circle_outlined : Icons.mic_none,
                  ),
                  color: _isRecording ? Colors.red : gRedMid,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F0F13)
                          : const Color(0xFFF3F5F7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: textPrimary),
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: _isRecording
                            ? "Recording voice..."
                            : "Enter a message...",
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (_msgController.text.trim().isNotEmpty) {
                      _sendTextMessage(_msgController.text.trim());
                    }
                  },
                  child: const CircleAvatar(
                    backgroundColor: gRedMid,
                    radius: 25,
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
