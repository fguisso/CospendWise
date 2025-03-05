import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/cospend_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCurrentUser() async {
    debugPrint('UserProvider - Loading current user');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // First check if we have stored credentials
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('cospend_url');
      final username = prefs.getString('cospend_username');
      final password = prefs.getString('cospend_password');

      debugPrint('UserProvider - Checking stored credentials');
      debugPrint('- URL exists: ${url != null}');
      debugPrint('- Username exists: ${username != null}');
      debugPrint('- Password exists: ${password != null}');

      if (url == null || username == null || password == null) {
        throw Exception('Missing login credentials. Please log in again.');
      }

      debugPrint('UserProvider - Attempting to load user from API');
      _currentUser = await CospendApiService.getCurrentUser();
      
      if (_currentUser == null) {
        throw Exception('Failed to load user data');
      }
      
      debugPrint('UserProvider - Successfully loaded user: ${_currentUser?.name}');
      _error = null;
    } catch (e, stackTrace) {
      debugPrint('UserProvider - Error loading user: $e');
      debugPrint('Stack trace: $stackTrace');
      _error = e.toString();
      _currentUser = null;
      
      // If credentials are invalid, clear them
      if (e.toString().contains('401') || e.toString().contains('unauthorized')) {
        debugPrint('UserProvider - Clearing invalid credentials');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('cospend_url');
        await prefs.remove('cospend_username');
        await prefs.remove('cospend_password');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setUser(User user) {
    debugPrint('UserProvider - Setting user: ${user.name}');
    _currentUser = user;
    _error = null;
    notifyListeners();
  }

  void clearUser() {
    debugPrint('UserProvider - Clearing user');
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void setError(String error) {
    debugPrint('UserProvider - Setting error: $error');
    _error = error;
    notifyListeners();
  }
} 