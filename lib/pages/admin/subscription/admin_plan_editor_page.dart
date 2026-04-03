import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/services/subscription_plan_service.dart';
import '../../../core/theme/app_colors.dart';

class AdminPlanEditorPage extends StatefulWidget {
  const AdminPlanEditorPage({super.key, this.existing});

  final SubscriptionPlan? existing;

  @override
  State<AdminPlanEditorPage> createState() => _AdminPlanEditorPageState();
}

class _AdminPlanEditorPageState extends State<AdminPlanEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idController;
  late final TextEditingController _titleController;
  late final TextEditingController _priceController;
  late final TextEditingController _periodController;
  late final TextEditingController _currencyController;
  late final TextEditingController _featuresController;
  late final TextEditingController _savePercentController;
  late final TextEditingController _sortOrderController;

  late bool _popular;
  late bool _isGreenCheck;
  late bool _isActive;
  late String _selectedIconKey;
  bool _isGeneratingId = false;

  static const _iconOptions = [
    ('bolt', 'Bolt'),
    ('workspace', 'Premium'),
    ('star', 'Star'),
    ('calendar', 'Calendar'),
  ];

  @override
  void initState() {
    super.initState();
    final plan = widget.existing;
    _idController = TextEditingController(text: plan?.id ?? '');
    _titleController = TextEditingController(text: plan?.title ?? '');
    _priceController = TextEditingController(text: plan?.price ?? '');
    _periodController = TextEditingController(
      text: plan?.durationInMonths.toString() ?? '',
    );
    _currencyController = TextEditingController(text: plan?.currency ?? 'gbp');
    _featuresController = TextEditingController(
      text: plan?.features.join('\n') ?? '',
    );
    _savePercentController = TextEditingController(
      text: plan?.savePercent?.toString() ?? '',
    );
    _sortOrderController = TextEditingController(
      text: (plan?.sortOrder ?? 0).toString(),
    );
    _popular = plan?.popular ?? false;
    _isGreenCheck = plan?.isGreenCheck ?? false;
    _isActive = plan?.isActive ?? true;
    _selectedIconKey = plan?.iconKey ?? 'workspace';
    if (plan == null) {
      _loadGeneratedPlanId();
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _priceController.dispose();
    _periodController.dispose();
    _currencyController.dispose();
    _featuresController.dispose();
    _savePercentController.dispose();
    _sortOrderController.dispose();
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
          widget.existing == null ? 'Create Plan' : 'Edit Plan',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _field(
                  _idController,
                  'Plan ID',
                  enabled: false,
                  hint: _isGeneratingId ? 'Generating...' : null,
                ),
                _field(_titleController, 'Title'),
                _field(
                  _priceController,
                  'Price',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                ),
                _field(
                  _periodController,
                  'Months',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                // _field(_currencyController, 'Currency'),
                _field(
                  _featuresController,
                  'Features',
                  maxLines: 5,
                  hint: 'One feature per line',
                ),
                _field(
                  _savePercentController,
                  'Save percent',
                  hint: 'Optional',
                  keyboardType: TextInputType.number,
                  required: false,
                ),
                _field(
                  _sortOrderController,
                  'Sort order',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedIconKey,
                  decoration: _inputDecoration('Icon'),
                  items: _iconOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.$1,
                          child: Text(option.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedIconKey = value);
                    }
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Most popular'),
                  value: _popular,
                  onChanged: (value) => setState(() => _popular = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use green checks'),
                  value: _isGreenCheck,
                  onChanged: (value) => setState(() => _isGreenCheck = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active for users'),
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: const Text('Save Plan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadGeneratedPlanId() async {
    setState(() => _isGeneratingId = true);
    try {
      final id = await SubscriptionPlanService.generateUniquePlanId();
      if (!mounted) return;
      _idController.text = id;
    } finally {
      if (mounted) {
        setState(() => _isGeneratingId = false);
      }
    }
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool enabled = true,
    bool required = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: _inputDecoration(label, hint: hint),
        validator: (value) {
          if (!required) return null;
          if (value == null || value.trim().isEmpty) {
            return 'Enter $label';
          }
          if (label == 'Price' &&
              !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value.trim())) {
            return 'Enter a valid numeric price';
          }
          if (label == 'Months' && !RegExp(r'^\d+$').hasMatch(value.trim())) {
            return 'Enter month count in numbers';
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_idController.text.trim().isEmpty) return;
    final features = _featuresController.text
        .split('\n')
        .map((feature) => feature.trim())
        .where((feature) => feature.isNotEmpty)
        .toList();
    final savePercent = int.tryParse(_savePercentController.text.trim());
    final sortOrder = int.tryParse(_sortOrderController.text.trim()) ?? 0;
    Get.back(
      result: SubscriptionPlan(
        id: _idController.text.trim(),
        iconKey: _selectedIconKey,
        title: _titleController.text.trim(),
        price: _priceController.text.trim(),
        period: _periodController.text.trim(),
        currency: _currencyController.text.trim().toLowerCase(),
        features: features,
        popular: _popular,
        savePercent: savePercent,
        isGreenCheck: _isGreenCheck,
        isActive: _isActive,
        sortOrder: sortOrder,
      ),
    );
  }
}
