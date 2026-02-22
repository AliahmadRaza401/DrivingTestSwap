import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/user_preferences_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/toast_util.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await AuthService.getCurrentUserProfile();
    if (profile != null) {
      _fullNameController.text = profile['fullName'] ?? '';
      _dateOfBirthController.text = profile['dateOfBirth'] ?? '';
    } else {
      final name = await UserPreferencesService.fullName;
      final dob = await UserPreferencesService.dateOfBirth;
      _fullNameController.text = name ?? '';
      _dateOfBirthController.text = dob ?? '';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final error = await AuthService.updateProfile(
      fullName: _fullNameController.text.trim(),
      dateOfBirth: _dateOfBirthController.text.trim().isEmpty ? null : _dateOfBirthController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) {
      ToastUtil.error(error);
      return;
    }
    ToastUtil.success('Profile updated');
    Get.back();
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
          'Edit Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          children: [
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                labelText: 'Full name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter your name';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _dateOfBirthController,
              decoration: const InputDecoration(
                labelText: 'Date of birth (optional)',
                hintText: 'e.g. DD/MM/YYYY',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
