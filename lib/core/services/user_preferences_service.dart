import 'package:shared_preferences/shared_preferences.dart';

/// Keys for stored user data and login state.
abstract class UserPrefsKeys {
  static const String loggedIn = 'logged_in';
  static const String uid = 'uid';
  static const String email = 'email';
  static const String fullName = 'full_name';
  static const String dateOfBirth = 'date_of_birth';
  static const String termsResponded = 'terms_responded';
  static const String role = 'role';

  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';
}

/// Saves and reads user details and logged-in state in SharedPreferences.
class UserPreferencesService {
  UserPreferencesService._();

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Saves logged-in state and user profile. Call after successful login.
  static Future<void> saveUserAndLoginState({
    required String uid,
    required String email,
    String fullName = '',
    String dateOfBirth = '',
    String role = UserPrefsKeys.roleUser,
  }) async {
    final prefs = await _instance;
    await prefs.setBool(UserPrefsKeys.loggedIn, true);
    await prefs.setString(UserPrefsKeys.uid, uid);
    await prefs.setString(UserPrefsKeys.email, email);
    await prefs.setString(UserPrefsKeys.fullName, fullName);
    await prefs.setString(UserPrefsKeys.dateOfBirth, dateOfBirth);
    await prefs.setString(UserPrefsKeys.role, role);
  }

  /// Clears user data and logged-in state. Call on logout.
  static Future<void> clearUserAndLoginState() async {
    final prefs = await _instance;
    await prefs.remove(UserPrefsKeys.loggedIn);
    await prefs.remove(UserPrefsKeys.uid);
    await prefs.remove(UserPrefsKeys.email);
    await prefs.remove(UserPrefsKeys.fullName);
    await prefs.remove(UserPrefsKeys.dateOfBirth);
    await prefs.remove(UserPrefsKeys.role);
  }

  /// True if the user has already accepted or declined the terms (show terms only once).
  static Future<bool> hasTermsBeenResponded() async {
    final prefs = await _instance;
    return prefs.getBool(UserPrefsKeys.termsResponded) ?? false;
  }

  /// Call after user taps Accept or Decline on the Terms page so it is not shown again.
  static Future<void> setTermsResponded() async {
    final prefs = await _instance;
    await prefs.setBool(UserPrefsKeys.termsResponded, true);
  }

  /// Update only full name and/or date of birth in local storage (e.g. after Edit Profile).
  static Future<void> updateProfileData({
    String? fullName,
    String? dateOfBirth,
  }) async {
    final prefs = await _instance;
    if (fullName != null) {
      await prefs.setString(UserPrefsKeys.fullName, fullName);
    }
    if (dateOfBirth != null) {
      await prefs.setString(UserPrefsKeys.dateOfBirth, dateOfBirth);
    }
  }

  /// Whether the user is considered logged in (from prefs).
  static Future<bool> isLoggedIn() async {
    final prefs = await _instance;
    return prefs.getBool(UserPrefsKeys.loggedIn) ?? false;
  }

  static Future<String?> get uid async {
    final prefs = await _instance;
    return prefs.getString(UserPrefsKeys.uid);
  }

  static Future<String?> get email async {
    final prefs = await _instance;
    return prefs.getString(UserPrefsKeys.email);
  }

  static Future<String?> get fullName async {
    final prefs = await _instance;
    return prefs.getString(UserPrefsKeys.fullName);
  }

  static Future<String?> get dateOfBirth async {
    final prefs = await _instance;
    return prefs.getString(UserPrefsKeys.dateOfBirth);
  }

  static Future<String?> get role async {
    final prefs = await _instance;
    return prefs.getString(UserPrefsKeys.role);
  }

  static Future<bool> get isAdmin async {
    final prefs = await _instance;
    return prefs.getString(UserPrefsKeys.role) == UserPrefsKeys.roleAdmin;
  }

  /// All stored user fields as a map (for convenience).
  static Future<Map<String, String>> getUserMap() async {
    final prefs = await _instance;
    return {
      UserPrefsKeys.uid: prefs.getString(UserPrefsKeys.uid) ?? '',
      UserPrefsKeys.email: prefs.getString(UserPrefsKeys.email) ?? '',
      UserPrefsKeys.fullName: prefs.getString(UserPrefsKeys.fullName) ?? '',
      UserPrefsKeys.dateOfBirth:
          prefs.getString(UserPrefsKeys.dateOfBirth) ?? '',
      UserPrefsKeys.role:
          prefs.getString(UserPrefsKeys.role) ?? UserPrefsKeys.roleUser,
    };
  }
}
