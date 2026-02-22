import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/post_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';
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
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _lookingForController = TextEditingController();
  final _preferredAreaController = TextEditingController();
  final _notesController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final post = widget.editPost;
    if (post != null) {
      _testCentreController.text = post.testCentre;
      _dateController.text = post.date;
      _timeController.text = post.time;
      _lookingForController.text = post.lookingFor;
      _preferredAreaController.text = post.preferredArea;
      _notesController.text = post.notes;
    }
  }

  @override
  void dispose() {
    _testCentreController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _lookingForController.dispose();
    _preferredAreaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      _dateController.text =
          '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
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

  static String _initialsFromName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
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
    final date = _dateController.text.trim();
    final time = _timeController.text.trim();
    final lookingFor = _lookingForController.text.trim();
    final preferredArea = _preferredAreaController.text.trim();
    final notes = _notesController.text.trim();

    try {
      if (widget.editPost != null) {
        await PostService.updatePost(
          postId: widget.editPost!.id,
          testCentre: testCentre,
          date: date,
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
      final creatorName = profile?['fullName']?.isNotEmpty == true ? profile!['fullName']! : 'User';
      final creatorInitials = _initialsFromName(creatorName);

      await PostService.createPost(
        testCentre: testCentre,
        date: date,
        time: time,
        lookingFor: lookingFor,
        preferredArea: preferredArea,
        notes: notes,
        creatorName: creatorName,
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
      developer.log('Post create/update failed', name: 'PostAvailabilityPage', error: e, stackTrace: st);
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
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 22),
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
                decoration: _inputDecoration(
                  hint: 'Where is your booked test?',
                  suffixIcon: Icon(Icons.location_on_outlined, color: AppColors.textSecondary, size: 22),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter test centre' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Date'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: _pickDate,
                          decoration: _inputDecoration(
                            hint: 'mm/dd/yyyy',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 22),
                              onPressed: _pickDate,
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Select date' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Time'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _timeController,
                          readOnly: true,
                          onTap: _pickTime,
                          decoration: _inputDecoration(
                            hint: '--:-- --',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.access_time_rounded, color: AppColors.textSecondary, size: 22),
                              onPressed: _pickTime,
                            ),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Select time' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildLabel('What are you looking for?'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _lookingForController,
                decoration: _inputDecoration(
                  hint: 'e.g. Earlier dates',
                  suffixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.textSecondary, size: 22),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter what you\'re looking for' : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('Preferred Area'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _preferredAreaController,
                decoration: _inputDecoration(
                  hint: 'e.g. Within 20 miles',
                  suffixIcon: Icon(Icons.place_outlined, color: AppColors.textSecondary, size: 22),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel('Notes (Optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: _inputDecoration(
                  hint: 'e.g. Need a manual car, willing to travel to Coventry..',
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
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        )
                      : Text(
                          widget.editPost != null ? 'Update Post' : 'Post to Noticeboard',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
        "Tip: Be specific about what you're looking for to find match faster",
        style: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: AppColors.primary.withValues(alpha: 0.95),
        ),
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

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
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
