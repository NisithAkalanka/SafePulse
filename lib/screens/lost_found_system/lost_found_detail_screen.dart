import 'dart:convert';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'lost_found_service.dart';
import 'lost_item_model.dart';
import 'mock_chat_screen.dart';

const Color lfRed = Color(0xFFE53935);
const Color lfBg = Color(0xFFF6F6F7);
const Color lfTextPrimary = Color(0xFF1E1E1E);
const Color lfTextSecondary = Color(0xFF4B4B4B);
const Color lfTextMuted = Color(0xFF707070);

class LostFoundDetailScreen extends StatefulWidget {
  final LostItem item;

  const LostFoundDetailScreen({super.key, required this.item});

  @override
  State<LostFoundDetailScreen> createState() => _LostFoundDetailScreenState();
}

class _LostFoundDetailScreenState extends State<LostFoundDetailScreen> {
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  Color get pageBg => isDark ? const Color(0xFF121217) : lfBg;
  Color get cardBg => isDark ? const Color(0xFF1B1B22) : Colors.white;
  Color get softBg =>
      isDark ? const Color(0xFF23232B) : const Color(0xFFF3F3F3);
  Color get textPrimary => isDark ? Colors.white : lfTextPrimary;
  Color get textSecondary => isDark ? const Color(0xFFB7BBC6) : lfTextSecondary;
  Color get textMuted => isDark ? const Color(0xFF9EA4B0) : lfTextMuted;
  Color get borderColor =>
      isDark ? const Color(0xFF34343F) : const Color(0xFFE5E7EE);

  Color get editYellowLight1 => const Color(0xFFE7D79A);
  Color get editYellowLight2 => const Color(0xFFCDB46E);
  Color get editYellowDark1 => const Color(0xFFE3CF8A);
  Color get editYellowDark2 => const Color(0xFFB79E57);

  Color get editButtonColor1 => isDark ? editYellowDark1 : editYellowLight1;
  Color get editButtonColor2 => isDark ? editYellowDark2 : editYellowLight2;
  Color get editGlowColor => isDark
      ? const Color(0xFFB79E57).withOpacity(0.28)
      : const Color(0xFFCDB46E).withOpacity(0.24);

  static const Color returnGreen = Color(0xFF2E7D32);

  static const List<String> _editCategories = <String>[
    'Electronics',
    'ID/Documents',
    'Student ID Card',
    'Watch',
    'Keys',
    'Books',
    'Others',
  ];

  static const List<String> _editLocations = <String>[
    'Main Gate',
    'Library',
    'Auditorium',
    'Canteen',
    'Car Park',
    'Main Building',
    'New Building/Block',
    'New Building/G Block',
    'Engineering Building',
    'Business School',
    'Juice Bar',
    'Playground',
    'Bird Nest',
    'William Angliss',
    'Other',
  ];

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

  String get currentName =>
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Student';

  bool _isOwner(LostItem item) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == item.userId;
  }

  bool _isRequester(LostItem item) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == item.requesterId;
  }

  bool _isConversationParticipant(LostItem item) {
    return _isOwner(item) || _isRequester(item);
  }

  bool _isActiveStatus(LostItem item) => item.status == 'Active';

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: lfRed, width: 2.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: lfRed.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  InputDecoration _dialogFieldDecoration(String hint, {String? label}) {
    return InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: TextStyle(color: textMuted),
      labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: isDark ? const Color(0xFF24242C) : const Color(0xFFF7F7F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lfRed, width: 1.4),
      ),
    );
  }

  String? _validateQuestion(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Question is required';
    if (v.length < 5) return 'Question must be at least 5 characters';
    if (v.length > 120) return 'Question must be 120 characters or less';
    final RegExp reg = RegExp(r"^[a-zA-Z0-9\s&(),.\-'/?!]+$");
    if (!reg.hasMatch(v)) return 'Question contains invalid characters';
    return null;
  }

  String? _validateAnswer(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Answer is required';
    if (v.length < 2) return 'Answer must be at least 2 characters';
    if (v.length > 150) return 'Answer must be 150 characters or less';
    return null;
  }

  String? _validateRetryMessage(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Message is required';
    if (v.length > 20) return 'Maximum 20 characters only';
    return null;
  }

  String? _requiredField(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  String? _validateLettersAndNumbersOnly(String? value, String label) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return '$label is required';

    final RegExp reg = RegExp(r'^[a-zA-Z0-9\s]+$');
    if (!reg.hasMatch(v)) {
      return '$label can contain letters and numbers only';
    }
    return null;
  }

  String _formatPostedDate(DateTime date) {
    const List<String> months = <String>[
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  String _formatPostedTime(DateTime date) {
    final int hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final String minute = date.minute.toString().padLeft(2, '0');
    final String period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _posterDisplayName(LostItem item) {
    final String first = (item.firstName ?? '').trim();
    final String last = (item.lastName ?? '').trim();
    final String full = '$first $last'.trim();

    if (full.isNotEmpty) return full;
    if (item.userName.trim().isNotEmpty) return item.userName.trim();
    return 'Anonymous';
  }

  Widget _buildImage(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported_outlined, size: 40, color: lfRed),
      );
    }

    try {
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image_outlined, size: 40, color: lfRed),
          );
        },
      );
    } catch (_) {
      return const Center(
        child: Icon(Icons.broken_image_outlined, size: 40, color: lfRed),
      );
    }
  }

  Future<void> _saveEditedItem({
    required LostItem item,
    required String title,
    required String category,
    required String description,
    required String location,
  }) async {
    await LostFoundService().updatePostBasic(
      itemId: item.id,
      title: title,
      category: category,
      description: description,
      location: location,
    );
  }

  Future<void> _showEditDialog(LostItem item) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController titleController = TextEditingController(
      text: item.title,
    );
    final TextEditingController descriptionController = TextEditingController(
      text: item.description,
    );

    final bool itemLocationIsCustom =
        item.location.isNotEmpty && !_editLocations.contains(item.location);

    final TextEditingController otherLocationController = TextEditingController(
      text: itemLocationIsCustom ? item.location : '',
    );

    String selectedCategory = item.category.isNotEmpty
        ? item.category
        : _editCategories.first;

    String selectedLocation = itemLocationIsCustom
        ? 'Other'
        : (item.location.isNotEmpty ? item.location : _editLocations.first);

    await showGeneralDialog(
      context: context,
      barrierLabel: 'Edit item',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.20),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: StatefulBuilder(
                    builder: (context, setLocalState) {
                      return Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 430),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withOpacity(0.16),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                            BoxShadow(
                              color: editGlowColor.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                            child: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: <Color>[
                                              editButtonColor1,
                                              editButtonColor2,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Edit item',
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => Navigator.pop(context),
                                        icon: Icon(
                                          Icons.close_rounded,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Update the item details below.',
                                    style: TextStyle(
                                      color: textMuted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: titleController,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[a-zA-Z0-9\s]'),
                                      ),
                                    ],
                                    validator: (v) =>
                                        _validateLettersAndNumbersOnly(
                                          v,
                                          'Title',
                                        ),
                                    decoration: _dialogFieldDecoration(
                                      'Title',
                                      label: 'Title',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: cardBg,
                                    value:
                                        _editCategories.contains(
                                          selectedCategory,
                                        )
                                        ? selectedCategory
                                        : _editCategories.first,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: textSecondary,
                                    ),
                                    decoration: _dialogFieldDecoration(
                                      '',
                                      label: 'Category',
                                    ),
                                    items: _editCategories
                                        .map(
                                          (String c) =>
                                              DropdownMenuItem<String>(
                                                value: c,
                                                child: Text(c),
                                              ),
                                        )
                                        .toList(),
                                    onChanged: (String? value) {
                                      if (value != null) {
                                        setLocalState(() {
                                          selectedCategory = value;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  DropdownButtonFormField<String>(
                                    dropdownColor: cardBg,
                                    value:
                                        _editLocations.contains(
                                          selectedLocation,
                                        )
                                        ? selectedLocation
                                        : _editLocations.first,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    icon: Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: textSecondary,
                                    ),
                                    validator: (v) =>
                                        _requiredField(v, 'Location'),
                                    decoration: _dialogFieldDecoration(
                                      '',
                                      label: 'Location',
                                    ),
                                    items: _editLocations
                                        .map(
                                          (String location) =>
                                              DropdownMenuItem<String>(
                                                value: location,
                                                child: Text(location),
                                              ),
                                        )
                                        .toList(),
                                    onChanged: (String? value) {
                                      if (value != null) {
                                        setLocalState(() {
                                          selectedLocation = value;
                                          if (selectedLocation != 'Other') {
                                            otherLocationController.clear();
                                          }
                                        });
                                      }
                                    },
                                  ),
                                  if (selectedLocation == 'Other') ...<Widget>[
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: otherLocationController,
                                      style: TextStyle(
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[a-zA-Z0-9\s]'),
                                        ),
                                      ],
                                      validator: (v) {
                                        if (selectedLocation != 'Other')
                                          return null;
                                        return _validateLettersAndNumbersOnly(
                                          v,
                                          'Other location',
                                        );
                                      },
                                      decoration: _dialogFieldDecoration(
                                        'Type other location',
                                        label: 'Other location',
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: descriptionController,
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 4,
                                    decoration: _dialogFieldDecoration(
                                      'Description',
                                      label: 'Description',
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 15,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Container(
                                          height: 52,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: <Color>[
                                                editButtonColor1,
                                                editButtonColor2,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            boxShadow: <BoxShadow>[
                                              BoxShadow(
                                                color: editGlowColor,
                                                blurRadius: 16,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              if (!formKey.currentState!
                                                  .validate()) {
                                                return;
                                              }

                                              await _saveEditedItem(
                                                item: item,
                                                title: titleController.text
                                                    .trim(),
                                                category: selectedCategory,
                                                description:
                                                    descriptionController.text
                                                        .trim(),
                                                location:
                                                    selectedLocation == 'Other'
                                                    ? otherLocationController
                                                          .text
                                                          .trim()
                                                    : selectedLocation.trim(),
                                              );

                                              if (!mounted) return;
                                              Navigator.pop(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(18),
                                              ),
                                            ),
                                            child: const Text(
                                              'Save',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
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
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _showRetryMessageDialog(LostItem item) async {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Send small message',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              maxLength: 20,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
              validator: _validateRetryMessage,
              decoration: _dialogFieldDecoration(
                'Type a short message',
                label: 'Message',
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: lfRed),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                await LostFoundService().ownerSendsRetryMessage(
                  itemId: item.id,
                  message: controller.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Send', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(LostItem item) async {
    final bool? shouldDelete = await showGeneralDialog<bool>(
      context: context,
      barrierLabel: 'Delete',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.25),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: <Widget>[
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: lfRed, width: 2),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.delete_outline,
                          size: 42,
                          color: lfRed,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Delete item',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Are you sure you want to delete?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: lfRed,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
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
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );

    if (shouldDelete != true) return;

    await LostFoundService().deletePost(item.id);

    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<void> _showFoundQuestionDialog(LostItem item) async {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Ask verification question',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              style: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
              validator: _validateQuestion,
              decoration: _dialogFieldDecoration(
                'e.g. Any special marks on the item?',
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: lfRed),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                await LostFoundService().submitFoundReport(
                  itemId: item.id,
                  requesterId: currentUid,
                  requesterName: currentName,
                  question: controller.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showOwnerAnswerDialog(LostItem item) async {
    final TextEditingController controller = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final String question = await LostFoundService().getVerificationQuestion(
      item.id,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Answer verification question',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  question,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: controller,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  validator: _validateAnswer,
                  decoration: _dialogFieldDecoration('Type your answer'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: lfRed),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                await LostFoundService().submitOwnerAnswer(
                  itemId: item.id,
                  answer: controller.text.trim(),
                );

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text(
                'Submit',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendFoundThisRequest(LostItem item) async {
    await LostFoundService().sendLostItemFoundRequest(
      itemId: item.id,
      requesterId: currentUid,
      requesterName: currentName,
    );

    if (!mounted) return;
  }

  Future<void> _cancelMyRequest(LostItem item) async {
    await LostFoundService().rejectChatRequest(item.id);

    if (!mounted) return;
  }

  void _openChat(LostItem item) {
    if (!_isConversationParticipant(item)) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockChatScreen(
          itemId: item.id,
          otherUserName: item.requesterName ?? item.userName,
          itemName: item.title,
        ),
      ),
    );
  }

  Future<void> _markReturnedByRequester(LostItem item) async {
    await LostFoundService().requesterMarksReturned(item.id);

    if (!mounted) return;
  }

  Future<void> _markReceivedByOwner(LostItem item) async {
    await LostFoundService().ownerMarksReceived(item.id);

    if (!mounted) return;
  }

  String _detailDeleteTime(LostItem item) {
    final DateTime? returnedAt = item.returnedAt;
    if (returnedAt == null) return 'Deletes in 1h 0m';

    final DateTime expiry = returnedAt.add(const Duration(hours: 1));
    final Duration remaining = expiry.difference(DateTime.now());

    if (remaining.isNegative) return 'Deleting soon';

    final int hours = remaining.inHours;
    final int minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return 'Deletes in ${hours}h ${minutes}m';
    }
    return 'Deletes in ${minutes}m';
  }

  Widget _buildHeader(LostItem item) {
    final bool isLost = item.type == 'Lost';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 100, 18, 18),
      decoration: BoxDecoration(
        gradient: isDark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFFF3B3B),
                  Color(0xFFE10613),
                  Color(0xFFB30012),
                  Color(0xFF140910),
                ],
                stops: <double>[0.0, 0.35, 0.72, 1.0],
              )
            : const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFFFF4B4B),
                  Color(0xFFB31217),
                  Color(0xFF1B1B1B),
                ],
                stops: <double>[0.0, 0.62, 1.0],
              ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Text(
        isLost
            ? 'Review the lost item details carefully.'
            : 'Review the found item details carefully.',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _statusBadge(LostItem item) {
    Color bg;
    Color fg;

    switch (item.status) {
      case 'Returned':
        bg = const Color(0xFFE8F6EA);
        fg = const Color(0xFF2E7D32);
        break;
      case 'Return Pending':
      case 'Receive Pending':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case 'Claim Pending':
      case 'Verification Pending':
      case 'Chat Request Pending':
      case 'Owner Requested Chat Approval':
      case 'Owner Retry Message Sent':
        bg = const Color(0xFFFFF4DB);
        fg = const Color(0xFFB26A00);
        break;
      case 'Chat Enabled':
      case 'Answer Submitted':
        bg = const Color(0xFFEAF2FF);
        fg = const Color(0xFF1565C0);
        break;
      case 'Owner Chat Rejected':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFC62828);
        break;
      default:
        bg = lfRed.withOpacity(0.08);
        fg = lfRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        item.status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }

  Widget _ownerActionButtons(LostItem item) {
    if (!_isOwner(item) || !_isActiveStatus(item)) {
      return const SizedBox.shrink();
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[editButtonColor1, editButtonColor2],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: editGlowColor,
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showEditDialog(item),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.edit_outlined, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: lfRed,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: lfRed.withOpacity(0.34),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelete(item),
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              label: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailsTopCard(LostItem item) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 230,
            width: double.infinity,
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(22),
            ),
            child: item.imageData != null && item.imageData!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: _buildImage(item.imageData),
                  )
                : item.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) {
                        return const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: lfRed,
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 42,
                      color: lfRed,
                    ),
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              if (_isOwner(item))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lfRed.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'You posted',
                    style: TextStyle(
                      color: lfRed,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(Icons.place_outlined, size: 18, color: textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.location,
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.category,
            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),
          Text(
            'Posted: ${_formatPostedDate(item.timestamp)}',
            style: TextStyle(
              color: textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Time: ${_formatPostedTime(item.timestamp)}',
            style: TextStyle(
              color: textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Text(
                'Status:',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 10),
              _statusBadge(item),
            ],
          ),
          if (item.status == 'Returned') ...<Widget>[
            const SizedBox(height: 10),
            Text(
              _detailDeleteTime(item),
              style: TextStyle(color: textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailSection(String title, String value, IconData icon) {
    return _panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: lfRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: lfRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _greenActionButton({
    required String text,
    required VoidCallback? onTap,
    required IconData icon,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: returnGreen,
          disabledBackgroundColor: returnGreen.withOpacity(0.65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _ownerLostVerificationCard(LostItem item) {
    return _panel(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationQuestion(item.id),
        builder: (context, snap) {
          final String question = snap.data ?? 'Loading question...';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Finder verification request',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question,
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              _primaryButton(
                'ANSWER QUESTION',
                () => _showOwnerAnswerDialog(item),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _finderApprovalCard(LostItem item) {
    return _panel(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationAnswer(item.id),
        builder: (context, snap) {
          final String answer = snap.data ?? 'Loading answer...';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "Owner's verification answer",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                answer,
                style: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await LostFoundService().rejectRequest(item.id);
                        if (!mounted) return;
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: borderColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Reject',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await LostFoundService().enablePrivateChat(item.id);
                        if (!mounted) return;
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lfRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _requesterWaitingCard(
    String text, {
    bool showCancelButton = false,
    VoidCallback? onCancel,
  }) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(Icons.hourglass_top_rounded, color: lfRed),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (showCancelButton && onCancel != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: lfRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Cancel Request',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ownerConfirmReceivedCard(LostItem item) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Returned item confirmation',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.requesterName ?? 'The other user'} marked the item as returned. Did you receive the item safely?',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _greenActionButton(
            text: 'YES, RECEIVED SAFELY',
            icon: Icons.check_circle_outline,
            onTap: () => _markReceivedByOwner(item),
          ),
        ],
      ),
    );
  }

  Widget _requesterFinalThanksCard(LostItem item) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Return confirmation',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thanks for returning the item safely. Tap the green tick button to confirm and complete the return.',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _greenActionButton(
            text: 'CONFIRM RETURN',
            icon: Icons.check,
            onTap: () => _markReturnedByRequester(item),
          ),
        ],
      ),
    );
  }

  Widget _foundRequesterConfirmReceivedCard(LostItem item) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Returned item confirmation',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_posterDisplayName(item)} marked the item as returned. Did you receive the item safely?',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _greenActionButton(
            text: 'YES, RECEIVED SAFELY',
            icon: Icons.check_circle_outline,
            onTap: () => _markReceivedByOwner(item),
          ),
        ],
      ),
    );
  }

  Widget _foundOwnerFinalReturnCard(LostItem item) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Return confirmation',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${item.requesterName ?? 'The other user'} marked the item as received. Tap the green button to confirm and complete the return.',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _greenActionButton(
            text: 'CONFIRM RETURN',
            icon: Icons.check,
            onTap: () => _markReturnedByRequester(item),
          ),
        ],
      ),
    );
  }

  Widget _chatCard(LostItem item) {
    final bool isFoundItem = item.type == 'Found';

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Private chat enabled',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can now coordinate the item return safely.',
            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          _primaryButton('OPEN CHAT', () => _openChat(item)),
          const SizedBox(height: 12),

          // LOST ITEM LOGIC - unchanged
          if (!isFoundItem &&
              _isOwner(item) &&
              !item.ownerMarkedReceived &&
              item.status == 'Chat Enabled')
            _greenActionButton(
              text: 'RECEIVED ITEM',
              icon: Icons.inventory_2_outlined,
              onTap: () => _markReceivedByOwner(item),
            ),

          if (!isFoundItem &&
              !_isOwner(item) &&
              _isRequester(item) &&
              !item.requesterMarkedReturned &&
              item.status == 'Chat Enabled')
            _greenActionButton(
              text: 'RETURNED ITEM',
              icon: Icons.assignment_turned_in_outlined,
              onTap: () => _markReturnedByRequester(item),
            ),

          // FOUND ITEM LOGIC - swapped as requested
          if (isFoundItem &&
              _isOwner(item) &&
              !item.requesterMarkedReturned &&
              item.status == 'Chat Enabled')
            _greenActionButton(
              text: 'RETURNED ITEM',
              icon: Icons.assignment_turned_in_outlined,
              onTap: () => _markReturnedByRequester(item),
            ),

          if (isFoundItem &&
              !_isOwner(item) &&
              _isRequester(item) &&
              !item.ownerMarkedReceived &&
              item.status == 'Chat Enabled')
            _greenActionButton(
              text: 'RECEIVED ITEM',
              icon: Icons.inventory_2_outlined,
              onTap: () => _markReceivedByOwner(item),
            ),
        ],
      ),
    );
  }

  Widget _publicVerificationNoticeCard(LostItem item) {
    String message = 'Verification in progress.';

    if (item.chatEnabled || item.status == 'Chat Enabled') {
      message =
          'Verification in progress. Private chat is visible only to the two users involved.';
    } else if (item.status == 'Chat Request Pending' ||
        item.status == 'Owner Requested Chat Approval' ||
        item.status == 'Owner Retry Message Sent' ||
        item.status == 'Owner Chat Rejected' ||
        item.status == 'Claim Pending' ||
        item.status == 'Verification Pending' ||
        item.status == 'Answer Submitted') {
      message =
          'Verification in progress. Only the users involved can see the private conversation.';
    }

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Verification in progress',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lostItemRequesterCard(LostItem item) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Claim this item',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let the owner know that you found this item and request to open chat.',
            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          _primaryButton('I FOUND THIS', () => _sendFoundThisRequest(item)),
        ],
      ),
    );
  }

  Widget _foundItemMineCard(LostItem item) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Claim this found item',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let the person who posted this found item know that it belongs to you and request to open chat.',
            style: TextStyle(color: textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 14),
          _primaryButton('THIS IS MINE', () => _sendFoundThisRequest(item)),
        ],
      ),
    );
  }

  Widget _ownerReceivedFoundRequestCard(LostItem item) {
    final requesterName = (item.requesterName ?? 'Someone').trim().isEmpty
        ? 'Someone'
        : item.requesterName!.trim();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Request received',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$requesterName clicked a claim button. You can reject this request or ask them to open chat.',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await LostFoundService().rejectChatRequest(item.id);
                    if (!mounted) return;
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await LostFoundService().ownerRequestsChatOpen(item.id);
                    if (!mounted) return;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lfRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Request Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _requesterOwnerAskedForChatCard(LostItem item) {
    final ownerName = _posterDisplayName(item);

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Chat request from owner',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$ownerName sent a request to open chat. If both of you accept, the private chat will open.',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await LostFoundService().requesterRejectsOwnerChatRequest(
                      item.id,
                    );
                    if (!mounted) return;
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await LostFoundService().requesterAcceptsChat(item.id);
                    if (!mounted) return;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lfRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ownerRejectedChatCard(LostItem item) {
    final int retryCount = item.ownerRetryCount;
    final bool canRetry = retryCount < 2;
    final String requesterName = (item.requesterName ?? 'The other user')
        .trim();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Chat request rejected',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${requesterName.isEmpty ? 'The other user' : requesterName} rejected your chat request.',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Retry messages used: $retryCount / 2',
            style: TextStyle(
              color: textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          if (canRetry) ...[
            const SizedBox(height: 14),
            _primaryButton(
              'SEND SMALL MESSAGE',
              () => _showRetryMessageDialog(item),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Retry limit reached.',
              style: TextStyle(color: lfRed, fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _requesterRetryMessageCard(LostItem item) {
    final ownerName = _posterDisplayName(item);
    final String retryMessage = (item.ownerRetryMessage ?? '').trim();

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Message from owner',
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$ownerName sent a small message asking to open chat.',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          if (retryMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                retryMessage,
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await LostFoundService().requesterRejectsOwnerChatRequest(
                      item.id,
                    );
                    if (!mounted) return;
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: borderColor),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Reject',
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await LostFoundService().requesterAcceptsChat(item.id);
                    if (!mounted) return;
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lfRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWorkflowCards(LostItem item) {
    final List<Widget> cards = <Widget>[];
    final bool isOwner = _isOwner(item);
    final bool isRequester = _isRequester(item);
    final bool isParticipant = _isConversationParticipant(item);

    if (item.status == 'Returned') {
      return cards;
    }

    if (!isParticipant &&
        (item.chatEnabled ||
            item.status == 'Chat Enabled' ||
            item.status == 'Chat Request Pending' ||
            item.status == 'Owner Requested Chat Approval' ||
            item.status == 'Owner Retry Message Sent' ||
            item.status == 'Owner Chat Rejected' ||
            item.status == 'Claim Pending' ||
            item.status == 'Verification Pending' ||
            item.status == 'Answer Submitted')) {
      cards.add(_publicVerificationNoticeCard(item));
      return cards;
    }

    if (item.status == 'Return Pending') {
      if (item.type == 'Found') {
        if (isRequester) {
          cards.add(_foundRequesterConfirmReceivedCard(item));
        } else if (isOwner) {
          cards.add(
            _requesterWaitingCard(
              'You marked the item as returned. Please wait for the other user to confirm safe receipt.',
            ),
          );
        }
      } else {
        if (isOwner) {
          cards.add(_ownerConfirmReceivedCard(item));
        } else if (isRequester) {
          cards.add(
            _requesterWaitingCard(
              'You marked the item as returned. Please wait for the owner to confirm safe receipt.',
            ),
          );
        }
      }
      return cards;
    }

    if (item.status == 'Receive Pending') {
      if (item.type == 'Found') {
        if (isOwner) {
          cards.add(_foundOwnerFinalReturnCard(item));
        } else if (isRequester) {
          cards.add(
            _requesterWaitingCard(
              'You marked the item as received. Please wait for the poster to confirm the return.',
            ),
          );
        }
      } else {
        if (isRequester) {
          cards.add(_requesterFinalThanksCard(item));
        } else if (isOwner) {
          cards.add(
            _requesterWaitingCard(
              'You marked the item as received. Please wait for the other user to confirm the return.',
            ),
          );
        }
      }
      return cards;
    }

    if (item.chatEnabled) {
      if (isParticipant) {
        cards.add(_chatCard(item));
      } else {
        cards.add(_publicVerificationNoticeCard(item));
      }
      return cards;
    }

    if (item.type == 'Lost') {
      if (!isOwner && !isRequester && item.status == 'Active') {
        cards.add(_lostItemRequesterCard(item));
      } else if (isOwner && item.status == 'Chat Request Pending') {
        cards.add(_ownerReceivedFoundRequestCard(item));
      } else if (!isOwner &&
          isRequester &&
          item.status == 'Chat Request Pending') {
        cards.add(
          _requesterWaitingCard(
            'Your request was sent to the owner. Please wait for the owner response.',
            showCancelButton: true,
            onCancel: () => _cancelMyRequest(item),
          ),
        );
      } else if (!isOwner &&
          isRequester &&
          item.status == 'Owner Requested Chat Approval') {
        cards.add(_requesterOwnerAskedForChatCard(item));
      } else if (isOwner && item.status == 'Owner Requested Chat Approval') {
        cards.add(
          _requesterWaitingCard(
            'You requested to open chat. Please wait for the requester to accept.',
          ),
        );
      } else if (isOwner && item.status == 'Owner Chat Rejected') {
        cards.add(_ownerRejectedChatCard(item));
      } else if (!isOwner &&
          isRequester &&
          item.status == 'Owner Retry Message Sent') {
        cards.add(_requesterRetryMessageCard(item));
      } else if (isOwner && item.status == 'Owner Retry Message Sent') {
        cards.add(
          _requesterWaitingCard(
            'Your small message was sent. Please wait for the other user to accept or reject.',
          ),
        );
      } else if (isOwner && item.status == 'Claim Pending') {
        cards.add(_ownerLostVerificationCard(item));
      } else if (!isOwner &&
          isRequester &&
          (item.status == 'Claim Pending' ||
              item.status == 'Verification Pending')) {
        cards.add(
          _requesterWaitingCard(
            'Your claim request was sent. Please wait for the owner response.',
          ),
        );
      } else if (!isOwner && isRequester && item.status == 'Answer Submitted') {
        cards.add(_finderApprovalCard(item));
      }
    } else {
      if (!isOwner && !isRequester && item.status == 'Active') {
        cards.add(_foundItemMineCard(item));
      } else if (isOwner && item.status == 'Chat Request Pending') {
        cards.add(_ownerReceivedFoundRequestCard(item));
      } else if (!isOwner &&
          isRequester &&
          item.status == 'Chat Request Pending') {
        cards.add(
          _requesterWaitingCard(
            'Your request was sent to the person who posted this item. Please wait for their response.',
            showCancelButton: true,
            onCancel: () => _cancelMyRequest(item),
          ),
        );
      } else if (!isOwner &&
          isRequester &&
          item.status == 'Owner Requested Chat Approval') {
        cards.add(_requesterOwnerAskedForChatCard(item));
      } else if (isOwner && item.status == 'Owner Requested Chat Approval') {
        cards.add(
          _requesterWaitingCard(
            'You requested to open chat. Please wait for the requester to accept.',
          ),
        );
      } else if (isOwner && item.status == 'Owner Chat Rejected') {
        cards.add(_ownerRejectedChatCard(item));
      } else if (!isOwner &&
          isRequester &&
          item.status == 'Owner Retry Message Sent') {
        cards.add(_requesterRetryMessageCard(item));
      } else if (isOwner && item.status == 'Owner Retry Message Sent') {
        cards.add(
          _requesterWaitingCard(
            'Your small message was sent. Please wait for the other user to accept or reject.',
          ),
        );
      } else if (isOwner &&
          (item.status == 'Verification Pending' ||
              item.status == 'Claim Pending')) {
        cards.add(_ownerLostVerificationCard(item));
      } else if (!isOwner &&
          isRequester &&
          (item.status == 'Verification Pending' ||
              item.status == 'Claim Pending')) {
        cards.add(
          _requesterWaitingCard(
            'Your verification request was sent. Please wait for the owner response.',
          ),
        );
      } else if (!isOwner && isRequester && item.status == 'Answer Submitted') {
        cards.add(_finderApprovalCard(item));
      }
    }

    return cards;
  }

  Widget _buildLoadedScreen(LostItem item) {
    final List<Widget> workflowCards = _buildWorkflowCards(item);

    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _buildHeader(item),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            child: Column(
              children: <Widget>[
                _detailSection(
                  'Posted by',
                  _posterDisplayName(item),
                  Icons.person_outline,
                ),
                const SizedBox(height: 14),
                _detailsTopCard(item),
                const SizedBox(height: 14),
                _detailSection(
                  'Description',
                  item.description,
                  Icons.description_outlined,
                ),
                const SizedBox(height: 14),
                _ownerActionButtons(item),
                if (_isOwner(item) && _isActiveStatus(item))
                  const SizedBox(height: 14),
                ...workflowCards.expand(
                  (Widget w) => <Widget>[w, const SizedBox(height: 14)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Item Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<LostItem?>(
        stream: LostFoundService().getItemStream(widget.item.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text(
                'Item not found or deleted.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }

          final item = snapshot.data!;
          return _buildLoadedScreen(item);
        },
      ),
    );
  }
}
