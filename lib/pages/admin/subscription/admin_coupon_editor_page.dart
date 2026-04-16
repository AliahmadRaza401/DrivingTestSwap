import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/coupon_service.dart';
import '../../../core/theme/app_colors.dart';

class AdminCouponEditorPage extends StatefulWidget {
  const AdminCouponEditorPage({super.key, this.existing});

  final CouponRecord? existing;

  @override
  State<AdminCouponEditorPage> createState() => _AdminCouponEditorPageState();
}

class _AdminCouponEditorPageState extends State<AdminCouponEditorPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _discountController;
  late final TextEditingController _codeController;
  bool _isActive = true;
  bool _isGenerating = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final coupon = widget.existing;
    _nameController = TextEditingController(text: coupon?.name ?? '');
    _discountController = TextEditingController(
      text: coupon == null ? '' : coupon.discountAmount.toStringAsFixed(2),
    );
    _codeController = TextEditingController(text: coupon?.code ?? '');
    _isActive = coupon?.isActive ?? true;
    if (!_isEditing) {
      _loadGeneratedCouponCode();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _discountController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          _isEditing ? 'Edit Coupon' : 'Create Coupon',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InputLabel('Coupon Name'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          hintText: 'Spring Offer',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a coupon name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      _InputLabel('Discount Price'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _discountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          hintText: '5.00',
                          prefixText: '£ ',
                        ),
                        validator: (value) {
                          final amount = CouponService.normalizeAmount(
                            value ?? '',
                          );
                          if (amount <= 0) {
                            return 'Enter a valid discount price';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InputLabel('Coupon Code'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _codeController,
                        readOnly: true,
                        decoration: _inputDecoration(
                          hintText: 'Auto-generated code',
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _codeController.text.trim().isEmpty
                                    ? null
                                    : _copyCouponCode,
                                icon: const Icon(
                                  Icons.copy_rounded,
                                  color: AppColors.success,
                                ),
                                tooltip: 'Copy code',
                              ),
                              IconButton(
                                onPressed: _isGenerating
                                    ? null
                                    : _loadGeneratedCouponCode,
                                icon: _isGenerating
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded),
                                tooltip: 'Generate new code',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Share this code with users so they can apply the discount during checkout.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: _isActive,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Coupon Active',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          _isActive
                              ? 'Users can apply this coupon.'
                              : 'Users cannot use this coupon right now.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(_isEditing ? 'Save Coupon' : 'Create Coupon'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadGeneratedCouponCode() async {
    setState(() => _isGenerating = true);
    try {
      final code = await CouponService.generateUniqueCouponCode();
      if (!mounted) return;
      _codeController.text = code;
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _copyCouponCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    Get.snackbar(
      'Copied',
      'Coupon code copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success.withValues(alpha: 0.95),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 2),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final code = CouponService.normalizeCode(_codeController.text);
    final discountAmount = CouponService.normalizeAmount(_discountController.text);
    Get.back(
      result: CouponRecord(
        id: code,
        name: _nameController.text.trim(),
        code: code,
        discountAmount: discountAmount,
        currency: 'gbp',
        isActive: _isActive,
        createdAt: widget.existing?.createdAt,
        updatedAt: widget.existing?.updatedAt,
        usageCount: widget.existing?.usageCount ?? 0,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? prefixText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}
