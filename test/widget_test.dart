import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:drivingtestswap/pages/auth/forgot_password_page.dart';
import 'package:drivingtestswap/pages/auth/login_page.dart';
import 'package:drivingtestswap/routes/app_routes.dart';

void main() {
  testWidgets('Login page opens the forgot password screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.login,
        getPages: [
          GetPage<LoginPage>(
            name: AppRoutes.login,
            page: () => const LoginPage(),
          ),
          GetPage<ForgotPasswordPage>(
            name: AppRoutes.forgotPassword,
            page: () => const ForgotPasswordPage(),
          ),
        ],
      ),
    );

    expect(find.text('Forgot password?'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordPage), findsOneWidget);
    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
  });
}
