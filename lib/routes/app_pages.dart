import 'package:get/get.dart';
import '../pages/splash/splash_page.dart';
import '../pages/onboarding/onboarding_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/terms/terms_page.dart';
import '../pages/choose_plan/choose_plan_page.dart';
import '../pages/main/main_page.dart';
import '../pages/swap/swap_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/help_faq/help_faq_page.dart';
import 'app_routes.dart';

/// GetX route definitions.
class AppPages {
  AppPages._();

  static const String initial = AppRoutes.splash;

  static final List<GetPage<dynamic>> routes = <GetPage<dynamic>>[
    GetPage<SplashPage>(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
      transition: Transition.fade,
    ),
    GetPage<OnboardingPage>(
      name: AppRoutes.onboarding,
      page: () => const OnboardingPage(),
      transition: Transition.fadeIn,
    ),
    GetPage<SignupPage>(
      name: AppRoutes.signup,
      page: () => const SignupPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage<LoginPage>(
      name: AppRoutes.login,
      page: () => const LoginPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage<TermsPage>(
      name: AppRoutes.terms,
      page: () => const TermsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage<ChoosePlanPage>(
      name: AppRoutes.choosePlan,
      page: () => const ChoosePlanPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage<MainPage>(
      name: AppRoutes.home,
      page: () => const MainPage(),
      transition: Transition.fade,
    ),
    GetPage<SwapPage>(
      name: AppRoutes.swap,
      page: () => const SwapPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage<SettingsPage>(
      name: AppRoutes.settings,
      page: () => const SettingsPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage<HelpFaqPage>(
      name: AppRoutes.helpFaq,
      page: () => const HelpFaqPage(),
      transition: Transition.rightToLeft,
    ),
  ];
}
