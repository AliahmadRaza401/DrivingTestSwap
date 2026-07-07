import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/post_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';
import 'widgets/test_centre_picker_sheet.dart';
import '../../routes/app_routes.dart';
import '../main/controllers/main_controller.dart';

class PostAvailabilityPage extends StatefulWidget {
  const PostAvailabilityPage({super.key, this.editPost});

  final SwapPost? editPost;

  @override
  State<PostAvailabilityPage> createState() => _PostAvailabilityPageState();
}

class _PostAvailabilityPageState extends State<PostAvailabilityPage> {
  final _formKey = GlobalKey<FormState>();
  final _testCentreController = TextEditingController();
  final _dateFromController = TextEditingController();
  final _dateToController = TextEditingController();
  final _timeController = TextEditingController();
  final _lookingForController = TextEditingController();
  final _preferredAreaController = TextEditingController();
  final _notesController = TextEditingController();
  double? _selectedTestCentreLat;
  double? _selectedTestCentreLng;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final post = widget.editPost;
    if (post != null) {
      _testCentreController.text = post.testCentre;
      _selectedTestCentreLat = post.testCentreLat;
      _selectedTestCentreLng = post.testCentreLng;
      _dateFromController.text = post.dateFrom;
      _dateToController.text = post.dateTo;
      _timeController.text = post.time;
      _lookingForController.text = post.lookingFor;
      _preferredAreaController.text = post.preferredArea;
      _notesController.text = post.notes;
    }
  }

  @override
  void dispose() {
    _testCentreController.dispose();
    _dateFromController.dispose();
    _dateToController.dispose();
    _timeController.dispose();
    _lookingForController.dispose();
    _preferredAreaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatUkDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _tryParseUkDate(String value) {
    final parts = value.trim().split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    try {
      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDateFrom() async {
    final initial = _tryParseUkDate(_dateFromController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _dateFromController.text = _formatUkDate(picked);
        // Clear dateTo if it is before the new dateFrom
        final currentTo = _tryParseUkDate(_dateToController.text);
        if (currentTo != null && currentTo.isBefore(picked)) {
          _dateToController.clear();
        }
      });
    }
  }

  Future<void> _pickDateTo() async {
    final from = _tryParseUkDate(_dateFromController.text) ?? DateTime.now();
    final initial = _tryParseUkDate(_dateToController.text) ?? from;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(from) ? from : initial,
      firstDate: from,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      _dateToController.text = _formatUkDate(picked);
    }
  }

  Future<void> _pickLookingForDate() async {
    final initial =
        _tryParseUkDate(_lookingForController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      _lookingForController.text = _formatUkDate(picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && mounted) {
      final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      _timeController.text =
          '${h.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')} $period';
    }
  }

  Future<void> _pickTestCentre() async {
    final selected = await showModalBottomSheet<SelectedTestCentre>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => TestCentrePickerSheet(
        initialQuery: _testCentreController.text.trim(),
      ),
    );

    if (selected == null || !mounted) return;

    setState(() {
      _testCentreController.text = selected.displayName;
      _selectedTestCentreLat = selected.latitude;
      _selectedTestCentreLng = selected.longitude;
    });
  }

  static String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _errorMessage(Object e) {
    final s = e.toString();
    if (s.startsWith('Exception: ')) return s.substring(11);
    return s;
  }

  Future<void> _onPost() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final testCentre = _testCentreController.text.trim();
    final dateFrom = _dateFromController.text.trim();
    final dateTo = _dateToController.text.trim();
    final time = _timeController.text.trim();
    final lookingFor = _lookingForController.text.trim();
    final preferredArea = _preferredAreaController.text.trim();
    final notes = _notesController.text.trim();
    final testCentreLat = _selectedTestCentreLat;
    final testCentreLng = _selectedTestCentreLng;

    if (testCentreLat == null || testCentreLng == null) {
      setState(() => _loading = false);
      ToastUtil.error('Please pick a test centre from the location picker.');
      return;
    }

    try {
      if (widget.editPost != null) {
        await PostService.updatePost(
          postId: widget.editPost!.id,
          testCentre: testCentre,
          testCentreLat: testCentreLat,
          testCentreLng: testCentreLng,
          dateFrom: dateFrom,
          dateTo: dateTo,
          time: time,
          lookingFor: lookingFor,
          preferredArea: preferredArea,
          notes: notes,
        );
        if (!mounted) return;
        setState(() => _loading = false);
        ToastUtil.success('Post updated');
        Get.back(result: true);
        return;
      }

      final profile = await AuthService.getCurrentUserProfile();
      // Use username publicly; fall back to fullName then 'User'
      final username = profile?['username']?.isNotEmpty == true
          ? profile!['username']!
          : profile?['fullName']?.isNotEmpty == true
          ? profile!['fullName']!
          : 'User';
      final creatorInitials = _initialsFromName(username);

      await PostService.createPost(
        testCentre: testCentre,
        testCentreLat: testCentreLat,
        testCentreLng: testCentreLng,
        dateFrom: dateFrom,
        dateTo: dateTo,
        time: time,
        lookingFor: lookingFor,
        preferredArea: preferredArea,
        notes: notes,
        creatorName: username,
        creatorInitials: creatorInitials,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ToastUtil.success('Post saved successfully');
      Get.offAllNamed(AppRoutes.home);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.isRegistered<MainController>()) {
          Get.find<MainController>().setIndex(3);
        }
      });
    } catch (e, st) {
      developer.log(
        'Post create/update failed',
        name: 'PostAvailabilityPage',
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      setState(() => _loading = false);
      ToastUtil.error(_errorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Post Availability',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildTipBox(),
              const SizedBox(height: 24),
              _buildLabel('Test Centre'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _testCentreController,
                readOnly: true,
                onTap: _pickTestCentre,
                decoration: _inputDecoration(
                  hint: 'Pick your booked test centre',
                  suffixIcon: IconButton(
                    onPressed: _pickTestCentre,
                    icon: Icon(
                      Icons.location_searching_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Pick a test centre'
                    : null,
              ),
              if (_selectedTestCentreLat != null &&
                  _selectedTestCentreLng != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Coordinates saved for distance matching.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildLabel('Test date'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _lookingForController,
                readOnly: true,
                onTap: _pickLookingForDate,
                decoration: _inputDecoration(
                  hint: 'dd/mm/yyyy',
                  suffixIcon: IconButton(
                    onPressed: _pickLookingForDate,
                    icon: Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Select your test date'
                    : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('Test time'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _timeController,
                readOnly: true,
                onTap: _pickTime,
                decoration: _inputDecoration(
                  hint: '--:-- --',
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.access_time_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: _pickTime,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Select time'
                    : null,
              ),
              const SizedBox(height: 28),
              _buildSectionHeading('Preferred dates'),
              const SizedBox(height: 4),
              Text(
                'The date range you would like to swap into.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _buildLabel('Date From'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _dateFromController,
                readOnly: true,
                onTap: _pickDateFrom,
                decoration: _inputDecoration(
                  hint: 'dd/mm/yyyy',
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.calendar_today,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: _pickDateFrom,
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Select start date'
                    : null,
              ),
              const SizedBox(height: 16),
              _buildLabel('Date To'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _dateToController,
                readOnly: true,
                onTap: _pickDateTo,
                decoration: _inputDecoration(
                  hint: 'dd/mm/yyyy (optional)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.calendar_today_outlined,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                    onPressed: _pickDateTo,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Preferred Area'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _preferredAreaController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _inputDecoration(
                  hint: 'e.g. 20',
                  suffixIcon: Icon(
                    Icons.place_outlined,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Notes (Optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: _inputDecoration(
                  hint:
                      'Write your preferred test centres or anything else, e.g. I have Airdrie but would prefer Grangemouth.',
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: _loading ? null : _onPost,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.editPost != null
                              ? 'Update Post'
                              : 'Post to Noticeboard',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Text(
        "Tip: Be specific about what you're looking for to find a match faster",
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppColors.primary.withValues(alpha: 0.95),
        ),
      ),
    );
  }

  Widget _buildSectionHeading(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
    );
  }
}
