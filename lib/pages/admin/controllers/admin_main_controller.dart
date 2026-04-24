import 'package:get/get.dart';

class AdminMainController extends GetxController {
  static const int dashboardIndex = 0;
  static const int usersIndex = 1;
  static const int postsIndex = 2;
  static const int swapsIndex = 3;
  static const int messagesIndex = 4;
  static const int settingsIndex = 5;
  static const int paymentsIndex = 6;
  static const int subscriptionsIndex = 7;
  static const int couponsIndex = 8;

  final RxInt currentIndex = 0.obs;

  void setIndex(int index) {
    currentIndex.value = index;
  }
}
