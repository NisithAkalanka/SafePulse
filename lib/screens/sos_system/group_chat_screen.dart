import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;

  const GroupChatScreen({super.key, required this.groupId});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final User? user = FirebaseAuth.instance.currentUser;

  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _groupDocStream;
  late final Stream<QuerySnapshot> _messagesStream;

  bool _isRecording = false;
  bool _isSending = false;
  DateTime? _recordingStartedAt;
  String? _playingMessageId;
  Duration _playingPosition = Duration.zero;
  Duration _playingDuration = Duration.zero;
  String? _replyText;
  String? _replySender;
  String? _replyMessageId;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg =>
      _isDark ? const Color(0xFF0B141A) : const Color(0xFFF5F7FA);
  Color get _appBarColor =>
      _isDark ? const Color(0xFF111B21) : const Color(0xFF1F2C34);
  Color get _myBubbleColor =>
      _isDark ? const Color(0xFF144D43) : const Color(0xFFDFF3EA);
  Color get _otherBubbleColor =>
      _isDark ? const Color(0xFF202C33) : Colors.white;
  Color get _inputBg => _isDark ? const Color(0xFF202C33) : Colors.white;
  Color get _inputHint =>
      _isDark ? const Color(0xFF8696A0) : const Color(0xFF7A8A99);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1F2933);
  Color get _subtleText =>
      _isDark ? const Color(0xFF9FB3C8) : const Color(0xFF6B7C93);
  Color get _accent =>
      _isDark ? const Color(0xFF53BDEB) : const Color(0xFF2F80ED);

  @override
  void initState() {
    super.initState();
    _groupDocStream = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .snapshots();

    _messagesStream = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
    _msgController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() {
        _playingPosition = position;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() {
        _playingDuration = duration;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _playingMessageId = null;
        _playingPosition = Duration.zero;
        _playingDuration = Duration.zero;
      });
    });
  }

  String _getShortName(String fullName) {
    if (fullName.trim().isEmpty) return 'User';
    return fullName.trim().split(' ').first;
  }

  String _getDisplaySenderName(dynamic rawSenderName) {
    final sender = (rawSenderName ?? '').toString().trim();

    if (sender.isEmpty) {
      return 'User';
    }

    if (sender.contains('@')) {
      return _getShortName(sender.split('@').first);
    }

    return _getShortName(sender);
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    return DateFormat('h:mm a').format(ts.toDate());
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Duration _messageVoiceDuration(Map<String, dynamic> data) {
    final dynamic rawSeconds = data['voiceDurationSeconds'];

    if (rawSeconds is int) {
      return Duration(seconds: rawSeconds);
    }

    if (rawSeconds is double) {
      return Duration(seconds: rawSeconds.round());
    }

    return Duration.zero;
  }

  bool _isOnlineFromLastSeen(dynamic lastSeen) {
    if (lastSeen is! Timestamp) return false;
    final diff = DateTime.now().difference(lastSeen.toDate()).inMinutes;
    return diff <= 2;
  }

  bool _isSeenByOthers(Map<String, dynamic> data) {
    final List<dynamic> readBy = List<dynamic>.from(
      data['readBy'] ?? const <dynamic>[],
    );
    final senderId = (data['senderId'] ?? '').toString();
    return readBy.any((id) => id.toString() != senderId);
  }

  Future<List<Map<String, dynamic>>> _loadMemberProfiles(
    List<dynamic> memberIds,
  ) async {
    if (memberIds.isEmpty) return <Map<String, dynamic>>[];

    final futures = memberIds.whereType<String>().map(
      (uid) => FirebaseFirestore.instance.collection('users').doc(uid).get(),
    );

    final docs = await Future.wait(futures);

    return docs.map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final fullName =
          (data['full_name'] ?? data['name'] ?? data['student_email'] ?? 'User')
              .toString();
      final email = (data['student_email'] ?? data['email'] ?? '').toString();
      return <String, dynamic>{
        'uid': doc.id,
        'fullName': fullName,
        'shortName': _getShortName(fullName),
        'email': email,
        'online': _isOnlineFromLastSeen(data['last_seen']),
      };
    }).toList();
  }

  Future<void> _markMessagesAsSeen(List<QueryDocumentSnapshot> docs) async {
    if (user == null || docs.isEmpty) return;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final senderId = (data['senderId'] ?? '').toString();
      final readBy = List<String>.from(data['readBy'] ?? const <String>[]);
      final hiddenFor = List<String>.from(
        data['hiddenFor'] ?? const <String>[],
      );

      if (hiddenFor.contains(user!.uid)) continue;

      if (senderId != user!.uid && !readBy.contains(user!.uid)) {
        await doc.reference.update({
          'readBy': FieldValue.arrayUnion([user!.uid]),
        });
      }
    }
  }

  Future<void> _showAddMembersSheet() async {
    if (user == null) return;

    try {
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final currentUserData = currentUserDoc.data() ?? <String, dynamic>{};
      final guardians = List<String>.from(
        currentUserData['guardians'] ?? const <String>[],
      );

      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .get();
      final groupData = groupDoc.data() ?? <String, dynamic>{};
      final currentMembers = List<String>.from(
        groupData['members'] ?? const <String>[],
      );
      final currentMemberEmails = List<String>.from(
        groupData['memberEmails'] ?? const <String>[],
      );

      final guardianProfiles = <Map<String, dynamic>>[];

      for (final guardianEmail in guardians) {
        final cleanEmail = guardianEmail.trim().toLowerCase();
        if (cleanEmail.isEmpty) continue;
        if (currentMemberEmails.contains(cleanEmail)) continue;

        final userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('student_email', isEqualTo: cleanEmail)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) continue;

        final guardianDoc = userQuery.docs.first;
        final guardianData = guardianDoc.data();
        final fullName =
            (guardianData['full_name'] ??
                    guardianData['name'] ??
                    guardianData['student_email'] ??
                    cleanEmail)
                .toString();

        if (currentMembers.contains(guardianDoc.id)) continue;

        guardianProfiles.add({
          'uid': guardianDoc.id,
          'email': cleanEmail,
          'shortName': _getShortName(fullName),
          'online': _isOnlineFromLastSeen(guardianData['last_seen']),
        });
      }

      if (!mounted) return;

      if (guardianProfiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No new guardians available to add.')),
        );
        return;
      }

      final selectedUids = <String>{};
      final selectedEmails = <String>{};

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _isDark ? const Color(0xFF111B21) : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return SafeArea(
                child: FractionallySizedBox(
                  heightFactor: 0.78,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Add Members',
                                    style: TextStyle(
                                      color: _textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Add more guardians to this group.',
                                    style: TextStyle(
                                      color: _subtleText,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFB31217),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: selectedUids.isEmpty
                                  ? null
                                  : () async {
                                      final selectedUidList = selectedUids
                                          .toList();
                                      final selectedEmailList = selectedEmails
                                          .toList();

                                      final groupRef = FirebaseFirestore
                                          .instance
                                          .collection('groups')
                                          .doc(widget.groupId);

                                      await groupRef.update({
                                        'members': FieldValue.arrayUnion(
                                          selectedUidList,
                                        ),
                                        'memberEmails': FieldValue.arrayUnion(
                                          selectedEmailList,
                                        ),
                                        'updatedAt':
                                            FieldValue.serverTimestamp(),
                                      });

                                      for (final profile in guardianProfiles) {
                                        if (!selectedUids.contains(
                                          profile['uid'],
                                        ))
                                          continue;

                                        await groupRef.collection('messages').add({
                                          'text':
                                              '${profile['shortName']} joined the protection circle',
                                          'type': 'system',
                                          'timestamp':
                                              FieldValue.serverTimestamp(),
                                          'senderId': profile['uid'],
                                          'senderName': profile['shortName'],
                                          'readBy': [user!.uid],
                                          'hiddenFor': <String>[],
                                          'edited': false,
                                        });
                                      }

                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                      }

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${selectedUidList.length} member(s) added to the group.',
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.person_add_alt_1_rounded),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: ListView.builder(
                            itemCount: guardianProfiles.length,
                            itemBuilder: (context, index) {
                              final member = guardianProfiles[index];
                              final uid = member['uid'].toString();
                              final email = member['email'].toString();
                              final isOnline = member['online'] == true;
                              final isSelected = selectedUids.contains(uid);

                              return CheckboxListTile(
                                value: isSelected,
                                activeColor: const Color(0xFFB31217),
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                secondary: CircleAvatar(
                                  backgroundColor: isOnline
                                      ? Colors.green.withOpacity(0.16)
                                      : Colors.grey.withOpacity(0.16),
                                  child: Icon(
                                    Icons.person,
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                title: Text(
                                  member['shortName'].toString(),
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  email,
                                  style: TextStyle(color: _subtleText),
                                ),
                                onChanged: (value) {
                                  setSheetState(() {
                                    if (value == true) {
                                      selectedUids.add(uid);
                                      selectedEmails.add(email);
                                    } else {
                                      selectedUids.remove(uid);
                                      selectedEmails.remove(email);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load guardians: $e')));
    }
  }

  Future<void> _showMembersSheet() async {
    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();
    final members = List<dynamic>.from(groupDoc.data()?['members'] ?? const []);
    final profiles = await _loadMemberProfiles(members);
    final onlineCount = profiles.where((m) => m['online'] == true).length;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _isDark ? const Color(0xFF111B21) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.72,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Group Members (${profiles.length})',
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$onlineCount online now',
                              style: TextStyle(
                                color: _subtleText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB31217),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddMembersSheet();
                        },
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.builder(
                      itemCount: profiles.length,
                      itemBuilder: (context, index) {
                        final member = profiles[index];
                        final isOnline = member['online'] == true;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isOnline
                                ? Colors.green.withOpacity(0.16)
                                : Colors.grey.withOpacity(0.16),
                            child: Icon(
                              Icons.person,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          ),
                          title: Text(
                            member['shortName'].toString(),
                            style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            member['email'].toString(),
                            style: TextStyle(color: _subtleText),
                          ),
                          trailing: Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              color: isOnline ? Colors.green : _subtleText,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<String> _getSenderShortName() async {
    if (user == null) return 'User';

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final data = userDoc.data() ?? <String, dynamic>{};
    final fullName = (data['full_name'] ?? data['name'] ?? '')
        .toString()
        .trim();

    if (fullName.isNotEmpty) {
      return _getShortName(fullName);
    }

    final email = (user!.email ?? '').trim();
    if (email.isNotEmpty && email.contains('@')) {
      return email.split('@').first;
    }

    return 'User';
  }

  Future<String> _writeVoiceTempFile(
    String base64Voice,
    String messageId,
  ) async {
    final bytes = base64Decode(base64Voice);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/voice_play_$messageId.m4a');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<void> _toggleVoicePlayback(
    String messageId,
    Map<String, dynamic> data,
  ) async {
    try {
      if (_playingMessageId == messageId) {
        await _audioPlayer.stop();
        if (!mounted) return;
        setState(() {
          _playingMessageId = null;
          _playingPosition = Duration.zero;
          _playingDuration = Duration.zero;
        });
        return;
      }

      final base64Voice = (data['file_data'] ?? '').toString();
      if (base64Voice.isEmpty) return;

      final filePath = await _writeVoiceTempFile(base64Voice, messageId);
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(filePath));

      final storedDuration = _messageVoiceDuration(data);

      if (!mounted) return;
      setState(() {
        _playingMessageId = messageId;
        _playingPosition = Duration.zero;
        _playingDuration = storedDuration;
      });
    } catch (e) {
      debugPrint('Voice playback error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voice playback failed: $e')));
    }
  }

  Future<void> _sendImageBase64({required ImageSource source}) async {
    if (user == null || _isSending) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 25,
        maxWidth: 600,
      );

      if (image == null) return;

      final bytes = await File(image.path).readAsBytes();
      final base64String = base64Encode(bytes);
      final shortName = await _getSenderShortName();

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
            'text': '',
            'file_data': base64String,
            'senderId': user!.uid,
            'senderName': shortName,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'image',
            'readBy': [user!.uid],
            'hiddenFor': <String>[],
            'replyToText': _replyText,
            'replyToSender': _replySender,
            'edited': false,
          });

      _clearReply();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image send failed: $e')));
    }
  }

  Future<void> _openAttachmentSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _isDark ? const Color(0xFF111B21) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attachments',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose what you want to send.',
                  style: TextStyle(
                    color: _subtleText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.14),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.purple,
                    ),
                  ),
                  title: Text(
                    'Gallery',
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Pick a photo from gallery.',
                    style: TextStyle(color: _subtleText),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _sendImageBase64(source: ImageSource.gallery);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.withOpacity(0.14),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.teal,
                    ),
                  ),
                  title: Text(
                    'Camera',
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Take a photo and send it.',
                    style: TextStyle(color: _subtleText),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _sendImageBase64(source: ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendVoiceFile(String path) async {
    if (user == null) return;

    try {
      final audioFile = File(path);
      if (!audioFile.existsSync()) return;

      final bytes = await audioFile.readAsBytes();
      debugPrint("Voice file size: ${bytes.length}");
      final base64Voice = base64Encode(bytes);
      final shortName = await _getSenderShortName();
      final recordingDuration = _recordingStartedAt == null
          ? Duration.zero
          : DateTime.now().difference(_recordingStartedAt!);
      final voiceDurationSeconds = recordingDuration.inSeconds <= 0
          ? 1
          : recordingDuration.inSeconds;

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
            'text': 'Voice message',
            'file_data': base64Voice,
            'senderId': user!.uid,
            'senderName': shortName,
            'type': 'voice',
            'voiceDurationSeconds': voiceDurationSeconds,
            'timestamp': FieldValue.serverTimestamp(),
            'readBy': [user!.uid],
            'hiddenFor': <String>[],
            'replyToText': _replyText,
            'replyToSender': _replySender,
            'edited': false,
          });

      _clearReply();
      _recordingStartedAt = null;
    } catch (e) {
      debugPrint('Error sending voice: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voice send failed: $e')));
    }
  }

  Future<void> _handleVoiceAction() async {
    if (user == null) return;

    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        debugPrint("Stopped file path: $path");
        debugPrint("Recording stopped. File path: $path");
        if (mounted) {
          setState(() => _isRecording = false);
        }

        if (path != null && path.isNotEmpty) {
          await _sendVoiceFile(path);
        } else {
          _recordingStartedAt = null;
        }
        return;
      }

      final hasPermission = await _audioRecorder.hasPermission();

      if (hasPermission) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        // FIX: use simpler config for better compatibility
        const config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: path);
        _recordingStartedAt = DateTime.now();

        debugPrint("Recording started at: $path");

        if (mounted) {
          setState(() {
            _isRecording = true;
          });
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
    } catch (e) {
      debugPrint('Voice recording error: $e');
      if (mounted) {
        setState(() => _isRecording = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voice recording failed: $e')));
    }
  }

  Future<void> _sendMessage() async {
    if (user == null || _msgController.text.trim().isEmpty || _isSending)
      return;

    final messageText = _msgController.text.trim();
    _msgController.clear();

    setState(() {
      _isSending = true;
    });

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      final fullName = userDoc.data()?['full_name'] ?? user!.email ?? 'Unknown';
      final shortName = _getShortName(fullName.toString());

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('messages')
          .add({
            'text': messageText,
            'senderId': user!.uid,
            'senderName': shortName,
            'timestamp': FieldValue.serverTimestamp(),
            'type': 'text',
            'readBy': [user!.uid],
            'hiddenFor': <String>[],
            'replyToText': _replyText,
            'replyToSender': _replySender,
            'edited': false,
          });

      _clearReply();
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _startReply(Map<String, dynamic> data, String docId) {
    setState(() {
      _replyText = (data['type'] == 'image')
          ? 'Photo'
          : (data['text'] ?? '').toString();
      _replySender = (data['senderName'] ?? 'User').toString();
      _replyMessageId = docId;
    });
  }

  void _clearReply() {
    if (!mounted) return;
    setState(() {
      _replyText = null;
      _replySender = null;
      _replyMessageId = null;
    });
  }

  Future<void> _copyMessage(Map<String, dynamic> data) async {
    final text = (data['text'] ?? '').toString();
    if (text.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message copied')));
  }

  Future<void> _editMessage(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final isMe = (data['senderId'] ?? '').toString() == user?.uid;
    final isText = (data['type'] ?? 'text').toString() == 'text';
    final seenByOthers = _isSeenByOthers(data);

    if (!isMe || !isText) return;
    if (seenByOthers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seen message cannot be edited.')),
      );
      return;
    }

    final controller = TextEditingController(
      text: (data['text'] ?? '').toString(),
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _isDark ? const Color(0xFF202C33) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit message', style: TextStyle(color: _textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: _textPrimary),
          decoration: InputDecoration(
            hintText: 'Update your message',
            hintStyle: TextStyle(color: _subtleText),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: _subtleText)),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = controller.text.trim();
              if (updated.isEmpty) return;
              await doc.reference.update({
                'text': updated,
                'edited': true,
                'editedAt': FieldValue.serverTimestamp(),
              });
              if (!mounted) return;
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteForMe(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    await doc.reference.update({
      'hiddenFor': FieldValue.arrayUnion([user!.uid]),
    });
  }

  Future<void> _deleteForEveryone(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final isMe = (data['senderId'] ?? '').toString() == user?.uid;
    final seenByOthers = _isSeenByOthers(data);

    if (!isMe) return;
    if (seenByOthers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seen message cannot be deleted for everyone.'),
        ),
      );
      return;
    }

    await doc.reference.update({
      'deletedForEveryone': true,
      'text': 'This message was deleted',
      'imageUrl': null,
      'type': 'deleted',
      'edited': false,
      'replyToText': null,
      'replyToSender': null,
    });
  }

  Future<void> _showMessageActions(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
  ) async {
    final isMe = (data['senderId'] ?? '').toString() == user?.uid;
    final isText = (data['type'] ?? 'text').toString() == 'text';
    final seenByOthers = _isSeenByOthers(data);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _isDark ? const Color(0xFF111B21) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.reply_rounded),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  _startReply(data, doc.id);
                },
              ),
              if (isText)
                ListTile(
                  leading: const Icon(Icons.copy_rounded),
                  title: const Text('Copy'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _copyMessage(data);
                  },
                ),
              if (isMe && isText)
                ListTile(
                  leading: Icon(
                    Icons.edit_rounded,
                    color: seenByOthers ? Colors.grey : null,
                  ),
                  title: Text(
                    'Edit',
                    style: TextStyle(color: seenByOthers ? Colors.grey : null),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _editMessage(doc, data);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: const Text('Delete for me'),
                onTap: () async {
                  Navigator.pop(context);
                  await _deleteForMe(doc, data);
                },
              ),
              if (isMe)
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_rounded,
                    color: seenByOthers ? Colors.grey : Colors.red,
                  ),
                  title: Text(
                    'Delete for everyone',
                    style: TextStyle(
                      color: seenByOthers ? Colors.grey : Colors.red,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _deleteForEveryone(doc, data);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmLeaveGroup() async {
    if (user == null) return;

    final bool confirm =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _isDark ? const Color(0xFF202C33) : Colors.white,
            title: Text('Leave Group?', style: TextStyle(color: _textPrimary)),
            content: Text(
              'Are you sure you want to leave this protection circle?',
              style: TextStyle(color: _subtleText),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Yes, Leave',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    final myName = await _getSenderShortName();
    final groupRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId);

    await groupRef.collection('messages').add({
      'text': '$myName left the group',
      'type': 'system',
      'timestamp': FieldValue.serverTimestamp(),
      'senderId': user!.uid,
      'senderName': myName,
      'readBy': [user!.uid],
      'hiddenFor': <String>[],
      'edited': false,
    });

    await groupRef.update({
      'members': FieldValue.arrayRemove([user!.uid]),
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildReplyPreview() {
    if (_replyText == null || _replySender == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: _inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: _accent, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replySender!,
                  style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyText!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _textPrimary, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _clearReply,
            icon: Icon(Icons.close_rounded, color: _subtleText, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedReply(Map<String, dynamic> data) {
    final replyText = (data['replyToText'] ?? '').toString();
    final replySender = (data['replyToSender'] ?? '').toString();

    if (replyText.isEmpty || replySender.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: _isDark ? Colors.black26 : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: _accent, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replySender,
            style: TextStyle(
              color: _accent,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            replyText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: _subtleText, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // Edit group name dialog
  Future<void> _editGroupName() async {
    final controller = TextEditingController();

    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .get();

    controller.text = groupDoc.data()?['groupName'] ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Group Name"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .update({'groupName': controller.text.trim()});
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // Pick group image and update
  Future<void> _pickGroupImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25,
        maxWidth: 600,
      );
      if (image == null) return;

      final bytes = await File(image.path).readAsBytes();
      final base64Img = base64Encode(bytes);

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .update({
            'groupImage': base64Img,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Group image update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _appBarColor,
        elevation: 0,
        leadingWidth: 64,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _groupDocStream,
          builder: (context, snapshot) {
            final groupData = snapshot.data?.data();
            final members = List<dynamic>.from(
              groupData?['members'] ?? const [],
            );

            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _loadMemberProfiles(members),
              builder: (context, memberSnapshot) {
                final profiles =
                    memberSnapshot.data ?? const <Map<String, dynamic>>[];
                final onlineCount = profiles
                    .where((m) => m['online'] == true)
                    .length;
                final subtitle = profiles.isEmpty
                    ? 'Guardians\' Group'
                    : '$onlineCount online • ${profiles.length} members';

                return InkWell(
                  onTap: _showMembersSheet,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickGroupImage,
                        child: CircleAvatar(
                          radius: 19,
                          backgroundColor: Colors.white24,
                          backgroundImage: groupData?['groupImage'] != null
                              ? MemoryImage(
                                  base64Decode(groupData!['groupImage']),
                                )
                              : null,
                          child: groupData?['groupImage'] == null
                              ? const Icon(
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: _editGroupName,
                              child: Text(
                                groupData?['groupName'] ?? 'Protection Circle',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.groups_outlined, color: Colors.white),
            onPressed: _showMembersSheet,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: _confirmLeaveGroup,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage('assets/images/chat_bg.png'),
            fit: BoxFit.cover,
            opacity: _isDark ? 0.05 : 0.035,
          ),
          color: _pageBg,
        ),
        child: Column(
          children: [
            Expanded(child: _buildMessageList()),
            _buildReplyPreview(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: _isDark ? Colors.white70 : const Color(0xFF1F2C34),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No messages yet.',
              style: TextStyle(color: _subtleText, fontWeight: FontWeight.w600),
            ),
          );
        }

        final allDocs = snapshot.data!.docs;
        final docs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final hiddenFor = List<String>.from(
            data['hiddenFor'] ?? const <String>[],
          );
          return !hiddenFor.contains(user?.uid);
        }).toList();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _markMessagesAsSeen(docs);
        });

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final isMe = data['senderId'] == user!.uid;
            return _buildMessageBubble(doc, data, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    bool isMe,
  ) {
    final type = (data['type'] ?? 'text').toString();
    final ts = data['timestamp'] as Timestamp?;
    final timeText = _formatTime(ts);
    final seen = isMe && _isSeenByOthers(data);
    final edited = data['edited'] == true;
    final isSystem = type == 'system';
    final voiceDuration = _messageVoiceDuration(data);
    final isPlayingThisVoice = _playingMessageId == doc.id;
    final visibleVoiceDuration =
        isPlayingThisVoice && _playingDuration > Duration.zero
        ? _playingDuration
        : voiceDuration;
    final visibleVoicePosition = isPlayingThisVoice
        ? _playingPosition
        : Duration.zero;

    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (data['text'] ?? '').toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _subtleText,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () => _showMessageActions(doc, data),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? _myBubbleColor : _otherBubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 1)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    _getDisplaySenderName(data['senderName']),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _accent,
                    ),
                  ),
                ),
              _buildQuotedReply(data),
              if (type == 'image' &&
                  (data['file_data'] ?? '').toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    base64Decode(data['file_data'].toString()),
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      alignment: Alignment.center,
                      color: Colors.black12,
                      child: const Text('Image not available'),
                    ),
                  ),
                )
              else if (type == 'voice')
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _toggleVoicePlayback(doc.id, data),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPlayingThisVoice
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: _accent,
                          size: 32,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isPlayingThisVoice
                                  ? 'Playing voice...'
                                  : 'Voice message',
                              style: TextStyle(
                                color: _textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_formatDuration(visibleVoicePosition)} / ${_formatDuration(visibleVoiceDuration)}',
                              style: TextStyle(
                                color: _subtleText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Text(
                  data['text'] ?? '',
                  style: TextStyle(fontSize: 15, color: _textPrimary),
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
                        style: TextStyle(fontSize: 10, color: _subtleText),
                      ),
                    ),
                  Text(
                    timeText,
                    style: TextStyle(fontSize: 11, color: _subtleText),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 5),
                    Icon(
                      seen ? Icons.done_all : Icons.done,
                      size: 16,
                      color: seen ? _accent : _subtleText,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isTyping = _msgController.text.trim().isNotEmpty;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _inputBg,
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 2),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.emoji_emotions_outlined,
                          color: _inputHint,
                        ),
                        onPressed: () {
                          final currentText = _msgController.text;
                          final selection = _msgController.selection;
                          final insertAt = selection.isValid
                              ? selection.start
                              : currentText.length;
                          final newText = currentText.replaceRange(
                            insertAt,
                            insertAt,
                            '😊',
                          );
                          _msgController.value = TextEditingValue(
                            text: newText,
                            selection: TextSelection.collapsed(
                              offset: insertAt + 2,
                            ),
                          );
                        },
                      ),
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          maxLines: null,
                          textInputAction: TextInputAction.newline,
                          style: TextStyle(color: _textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Message',
                            hintStyle: TextStyle(color: _inputHint),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.attach_file, color: _inputHint),
                        tooltip: 'Attachments',
                        onPressed: _openAttachmentSheet,
                      ),
                      IconButton(
                        icon: Icon(Icons.camera_alt, color: _inputHint),
                        tooltip: 'Camera image',
                        onPressed: () =>
                            _sendImageBase64(source: ImageSource.camera),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: isTyping ? _sendMessage : _handleVoiceAction,
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: _isRecording ? Colors.red : _appBarColor,
                  child: Icon(
                    isTyping
                        ? Icons.send
                        : (_isRecording ? Icons.stop_rounded : Icons.mic),
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _msgController.dispose();
    super.dispose();
  }
}
