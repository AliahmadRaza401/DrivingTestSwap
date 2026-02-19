import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onDecline() {
    Get.back();
  }

  void _onAccept() {
    Get.offAllNamed(AppRoutes.choosePlan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Terms & Disclaimer',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(
              'Please read to the end to continue',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Not a Booking Service'),
                  _bullet(
                    'This app connects learners who want to swap driving test dates. We do not manage or book DVSA tests directly.',
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Official Process'),
                  _bullet(
                    'All swaps must be completed on the official GOV.UK "Change driving test appointment" page. We do not perform the change for you.',
                  ),
                  const SizedBox(height: 20),
                  _dvsaRulesSection(),
                  const SizedBox(height: 20),
                  _sectionTitle('Requirement'),
                  _bullet('You must have a valid booked driving test.'),
                  _bullet('You are responsible for ensuring you meet DVSA eligibility rules.'),
                  const SizedBox(height: 20),
                  _sectionTitle('Liability & Privacy'),
                  _bullet(
                    'We do not guarantee that you will find a matching swap. We are not liable for any outcome of using this service.',
                  ),
                  _bullet('By continuing, you agree to our '),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Text(' and ', style: TextStyle(fontSize: 14)),
                        GestureDetector(
                          onTap: () {},
                          child: const Text(
                            'Terms & Conditions',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const Text('.', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _onDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: const TextStyle(
              color: AppColors.bulletRed,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dvsaRulesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.highlightOrange,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.highlightOrangeText.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DVSA Rules (March 2026)',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                height: 1.5,
              ),
              children: [
                const TextSpan(
                  text: 'Under 2026 DVSA rules, swapping counts as a "change". You are limited to ',
                ),
                TextSpan(
                  text: '2',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    backgroundColor: AppColors.highlightOrangeText.withValues(alpha: 0.2),
                  ),
                ),
                const TextSpan(text: ' changes per test from '),
                TextSpan(
                  text: '31 March 2026',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    backgroundColor: AppColors.highlightOrangeText.withValues(alpha: 0.2),
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
