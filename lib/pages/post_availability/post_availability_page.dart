import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';

class PostAvailabilityPage extends StatefulWidget {
  const PostAvailabilityPage({super.key});

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

  void _onPost() {
    if (_formKey.currentState?.validate() ?? false) {
      Get.back();
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
                readOnly: true,
                onTap: () {},
                decoration: _inputDecoration(
                  hint: 'Where is your booked test?',
                  suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                ),
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
              ),
              const SizedBox(height: 20),
              _buildLabel('Preferred Area'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _preferredAreaController,
                readOnly: true,
                onTap: () {},
                decoration: _inputDecoration(
                  hint: 'e.g. Within 20 miles',
                  suffixIcon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
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
                  onPressed: _onPost,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Post to Noticeboard',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
