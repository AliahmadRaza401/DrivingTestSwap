import 'package:get/get.dart';

class AdminMainController extends GetxController {
  static const int dashboardIndex = 0;
  static const int usersIndex = 1;
  static const int testsIndex = 2;
  static const int messagesIndex = 3;
  static const int settingsIndex = 4;
  static const int paymentsIndex = 5;
  static const int subscriptionsIndex = 6;
  static const int couponsIndex = 7;

  final RxInt currentIndex = 0.obs;

  void setIndex(int index) {
    currentIndex.value = index;
  }
}
