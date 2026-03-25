import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lost_item_model.dart';
import 'lost_found_service.dart';

class CreateItemScreen extends StatefulWidget {
  final String postType; // 'Lost' or 'Found'
  const CreateItemScreen({super.key, required this.postType});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _otherLocationController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  String _selectedCategory = 'Electronics';
  String _selectedLocation = 'Main Gate';

  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  static const Color spRed = Color(0xFFE53935);
  static const Color spRedDark = Color(0xFFB71C1C);

  final List<String> categories = const [
    'Electronics',
    'ID/Documents',
    'Student ID Card',
    'Watch',
    'Keys',
    'Books',
    'Others',
  ];

  final List<String> locations = const [
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

  bool get _isOtherLocationSelected => _selectedLocation == 'Other';

  String get _finalLocation {
    if (_isOtherLocationSelected) {
      return _otherLocationController.text.trim();
    }
    return _selectedLocation;
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get pageBg =>
      _isDark ? const Color(0xFF121217) : const Color(0xFFF4F2F3);
  Color get cardBg => _isDark ? const Color(0xFF1B1B22) : Colors.white;
  Color get formBg =>
      _isDark ? const Color(0xFF23232B) : const Color(0xFFF3F3F4);
  Color get textDark => _isDark ? Colors.white : const Color(0xFF111111);
  Color get textSecondary =>
      _isDark ? const Color(0xFFB7BBC6) : const Color(0xFF5E6470);
  Color get borderSoft =>
      _isDark ? const Color(0xFF34343F) : const Color(0xFFE4E4E7);
  Color get iconColor => _isDark ? Colors.white : Colors.black87;

  bool get _isFormReady {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final otherLoc = _otherLocationController.text.trim();

    final lettersOnly = RegExp(r'^[a-zA-Z\s]+$');
    final titleReg = RegExp(r'^[a-zA-Z0-9\s]+$');
    final otherLocReg = RegExp(r'^[a-zA-Z0-9\s]+$');

    final firstOk = first.isNotEmpty && lettersOnly.hasMatch(first);
    final lastOk = last.isNotEmpty && lettersOnly.hasMatch(last);
    final titleOk = title.isNotEmpty && titleReg.hasMatch(title);
    final descOk = desc.isNotEmpty;

    final locationOk = _isOtherLocationSelected
        ? otherLoc.isNotEmpty && otherLocReg.hasMatch(otherLoc)
        : _selectedLocation.trim().isNotEmpty;

    return firstOk && lastOk && titleOk && descOk && locationOk;
  }

  @override
  void initState() {
    super.initState();
    _firstNameController.addListener(_refreshFormState);
    _lastNameController.addListener(_refreshFormState);
    _titleController.addListener(_refreshFormState);
    _descController.addListener(_refreshFormState);
    _otherLocationController.addListener(_refreshFormState);
  }

  void _refreshFormState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _firstNameController.removeListener(_refreshFormState);
    _lastNameController.removeListener(_refreshFormState);
    _titleController.removeListener(_refreshFormState);
    _descController.removeListener(_refreshFormState);
    _otherLocationController.removeListener(_refreshFormState);

    _firstNameController.dispose();
    _lastNameController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _otherLocationController.dispose();
    super.dispose();
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'Electronics':
        return Icons.devices_outlined;
      case 'ID/Documents':
        return Icons.description_outlined;
      case 'Student ID Card':
        return Icons.badge_outlined;
      case 'Watch':
        return Icons.watch_outlined;
      case 'Keys':
        return Icons.key_outlined;
      case 'Books':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 10,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2024),
      lastDate: now,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Theme(
            data: Theme.of(context).copyWith(
              dialogBackgroundColor: isDark
                  ? const Color(0xFF1B1B22)
                  : Colors.white,
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: spRed,
                      onPrimary: Colors.white,
                      onSurface: Colors.white,
                      surface: Color(0xFF1B1B22),
                    )
                  : const ColorScheme.light(
                      primary: spRed,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                      surface: Colors.white,
                    ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: spRed),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;

        final pickedDateTime = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        if (pickedDateTime.isAfter(now)) {
          _selectedTime = TimeOfDay.fromDateTime(now);
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.input,
      switchToTimerEntryModeIcon: const Icon(Icons.access_time),
      switchToInputEntryModeIcon: const Icon(Icons.keyboard_outlined),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Theme(
            data: Theme.of(context).copyWith(
              dialogBackgroundColor: isDark
                  ? const Color(0xFF1B1B22)
                  : Colors.white,
              timePickerTheme: TimePickerThemeData(
                backgroundColor: isDark
                    ? const Color(0xFF1B1B22)
                    : Colors.white,
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                dayPeriodShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                dayPeriodColor: isDark
                    ? const Color(0xFF3A1E1E)
                    : const Color(0xFFFFE5E5),
                dayPeriodTextColor: spRed,
                dayPeriodBorderSide: const BorderSide(color: spRedDark),
                dayPeriodTextStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: spRed,
                ),
                dialBackgroundColor: isDark
                    ? const Color(0xFF23232B)
                    : const Color(0xFFF8F8F8),
                hourMinuteTextColor: isDark ? Colors.white : Colors.black,
                dialHandColor: spRed,
                dialTextColor: isDark ? Colors.white : Colors.black,
                entryModeIconColor: isDark ? Colors.white70 : Colors.black87,
                helpTextStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w700,
                ),
                hourMinuteTextStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 44,
                  fontWeight: FontWeight.w500,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                labelStyle: const TextStyle(
                  color: spRed,
                  fontWeight: FontWeight.w500,
                ),
                floatingLabelStyle: const TextStyle(
                  color: spRed,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF23232B) : Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF34343F)
                        : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: spRed, width: 1.4),
                ),
              ),
              colorScheme: isDark
                  ? const ColorScheme.dark(
                      primary: spRed,
                      onPrimary: Colors.white,
                      onSurface: Colors.white,
                      surface: Color(0xFF1B1B22),
                      secondary: spRed,
                    )
                  : const ColorScheme.light(
                      primary: spRed,
                      onPrimary: Colors.white,
                      onSurface: Colors.black,
                      surface: Colors.white,
                      secondary: spRed,
                    ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(foregroundColor: spRed),
              ),
            ),
            child: MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(alwaysUse24HourFormat: false),
              child: child!,
            ),
          ),
        );
      },
    );

    if (picked != null) {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        picked.hour,
        picked.minute,
      );

      if (selectedDateTime.isAfter(now)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Future time cannot be selected')),
        );
        return;
      }

      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _showCategoryPicker() async {
    final selected = await showGeneralDialog<String>(
      context: context,
      barrierLabel: "Category",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.18),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B1B22) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Select category',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                        ...categories.map(
                          (category) => InkWell(
                            onTap: () => Navigator.pop(context, category),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              color: _selectedCategory == category
                                  ? (isDark
                                        ? const Color(0xFF23232B)
                                        : const Color(0xFFF4F4F4))
                                  : (isDark
                                        ? const Color(0xFF1B1B22)
                                        : Colors.white),
                              child: Row(
                                children: [
                                  Icon(
                                    _iconForCategory(category),
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black87,
                                    size: 21,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (_selectedCategory == category)
                                    const Icon(
                                      Icons.check,
                                      color: spRed,
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
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
        return FadeTransition(opacity: animation, child: child);
      },
    );

    if (selected != null) {
      setState(() => _selectedCategory = selected);
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _formatDate(DateTime date) {
    const months = [
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
    const weekdays = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final weekday = weekdays[date.weekday];
    final month = months[date.month];
    return '$weekday, $month ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String? _validateLettersOnly(String? value, String fieldName) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return '$fieldName is required';

    final reg = RegExp(r'^[a-zA-Z\s]+$');
    if (!reg.hasMatch(v)) {
      return '$fieldName can contain letters only';
    }
    return null;
  }

  String? _validateTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Item name is required';

    final reg = RegExp(r'^[a-zA-Z0-9\s]+$');
    if (!reg.hasMatch(v)) {
      return 'Special characters are not allowed';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Description is required';
    return null;
  }

  String? _validateOtherLocation(String? value) {
    if (!_isOtherLocationSelected) return null;

    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please type the location';

    final reg = RegExp(r'^[a-zA-Z0-9\s]+$');
    if (!reg.hasMatch(v)) {
      return 'Only letters and numbers are allowed';
    }
    return null;
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_finalLocation.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Location is required')));
      return;
    }

    final reportedDateTime = _combineDateAndTime(_selectedDate, _selectedTime);
    if (reportedDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Future date and time cannot be selected'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final newItem = LostItem(
        id: '',
        userId: user?.uid ?? 'unknown',
        userName: user?.email?.split('@')[0] ?? 'Student',
        type: widget.postType,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        description: _descController.text.trim(),
        location: _finalLocation,
        imageUrl: '',
        status: 'Active',
        timestamp: DateTime.now(),
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        reportedDateTime: reportedDateTime,
      );

      await LostFoundService().createPost(newItem, _selectedImage);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _isDark ? const Color(0xFFB7BBC6) : Colors.grey.shade500,
      ),
      prefixIcon: Icon(icon, color: iconColor),
      filled: true,
      fillColor: formBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: spRed, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      counterStyle: TextStyle(
        color: _isDark ? Colors.white70 : Colors.black87,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _sectionLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textDark,
          ),
        ),
      ],
    );
  }

  Widget _dateTimeCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: formBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderSoft),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: textDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                color: _isDark ? Colors.white54 : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderChip() {
    return Container(
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF1B1B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: spRed,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: spRed.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.inventory_2_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.postType == 'Lost'
                      ? 'Report Lost Item'
                      : 'Report Found Item',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 108, 18, 20),
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
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.postType == 'Lost'
                ? 'Post your lost item details clearly.'
                : 'Post your found item details clearly.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          _buildHeaderChip(),
        ],
      ),
    );
  }

  Widget _buildLocationChip(String location) {
    final bool isSelected = _selectedLocation == location;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            setState(() {
              _selectedLocation = location;
              if (location != 'Other') {
                _otherLocationController.clear();
              }
            });
          },
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF4B4B), Color(0xFFD81B1B)],
                    )
                  : null,
              color: isSelected ? null : formBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF5A5A)
                    : (_isDark
                          ? const Color(0xFF34343F)
                          : const Color(0xFFD4D4D8)),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: spRed.withOpacity(0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              location,
              style: TextStyle(
                color: isSelected ? Colors.white : textDark,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _showCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: formBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderSoft),
        ),
        child: Row(
          children: [
            Icon(Icons.category_outlined, color: iconColor),
            const SizedBox(width: 12),
            Icon(
              _iconForCategory(_selectedCategory),
              color: iconColor,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _selectedCategory,
                style: TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: _isDark ? Colors.white54 : Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Location',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: locations.map(_buildLocationChip).toList(),
          ),
          if (_isOtherLocationSelected) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _otherLocationController,
              style: TextStyle(color: textDark, fontWeight: FontWeight.w500),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\s]')),
              ],
              decoration: _fieldDecoration(
                hint: 'Type other location',
                icon: Icons.edit_location_alt_outlined,
              ),
              validator: _validateOtherLocation,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final enabled = !_isLoading && _isFormReady;

    return Opacity(
      opacity: enabled ? 1 : 0.72,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: spRed.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: enabled ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: spRed,
              disabledBackgroundColor: spRed.withOpacity(0.45),
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 12),
                Text(
                  _isLoading ? 'SUBMITTING...' : 'SUBMIT REPORT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLost = widget.postType == 'Lost';

    return Scaffold(
      backgroundColor: pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          isLost ? 'Report Lost Item' : 'Report Found Item',
          style: const TextStyle(
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel(Icons.person_outline, 'Reporter details'),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _firstNameController,
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w500,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\s]'),
                          ),
                        ],
                        decoration: _fieldDecoration(
                          hint: 'First name',
                          icon: Icons.badge_outlined,
                        ),
                        validator: (val) =>
                            _validateLettersOnly(val, 'First name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastNameController,
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w500,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z\s]'),
                          ),
                        ],
                        decoration: _fieldDecoration(
                          hint: 'Last name',
                          icon: Icons.person_outline,
                        ),
                        validator: (val) =>
                            _validateLettersOnly(val, 'Last name'),
                      ),
                      const SizedBox(height: 18),
                      _sectionLabel(
                        Icons.calendar_month_outlined,
                        'Date you lost it',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _dateTimeCard(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date',
                            value: _formatDate(_selectedDate),
                            onTap: _pickDate,
                          ),
                          const SizedBox(width: 12),
                          _dateTimeCard(
                            icon: Icons.access_time,
                            label: 'Time',
                            value: _formatTime(_selectedTime),
                            onTap: _pickTime,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _sectionLabel(Icons.inventory_2_outlined, 'Item details'),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 180,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: formBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderSoft),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      size: 44,
                                      color: spRed.withOpacity(0.85),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Tap to upload photo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Optional',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w500,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9\s]'),
                          ),
                        ],
                        decoration: _fieldDecoration(
                          hint: 'What is it?',
                          icon: Icons.shopping_bag_outlined,
                        ),
                        validator: _validateTitle,
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryField(),
                      const SizedBox(height: 12),
                      _buildLocationSelector(),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descController,
                        style: TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 4,
                        maxLength: 300,
                        decoration: _fieldDecoration(
                          hint: 'Description (marks, color...)',
                          icon: Icons.description_outlined,
                        ),
                        validator: _validateDescription,
                      ),
                      const SizedBox(height: 18),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
