import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../services/cospend_api_service.dart';
import '../providers/user_provider.dart';
import '../widgets/widgets.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  bool _isLoading = true;
  User? _currentUser;
  String? _cospendUrl;
  String? _cospendUsername;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final url = prefs.getString('cospend_url');
      final username = prefs.getString('cospend_username');
      
      final user = await CospendApiService.getCurrentUser();
      
      setState(() {
        _currentUser = user;
        _cospendUrl = url;
        _cospendUsername = username;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user info: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user info: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all stored preferences
      
      if (mounted) {
        // Reset user provider state
        context.read<UserProvider>().clearUser();
        
        // Navigate to login screen and clear navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during logout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User avatar or icon
                  Center(
                    child: UserAvatar(
                      user: _currentUser,
                      radius: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // User details
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            'Name',
                            _currentUser?.name ?? 'Not available',
                            Icons.person,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Email',
                            _currentUser?.email ?? 'Not available',
                            Icons.email,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Cospend URL',
                            _cospendUrl ?? 'Not available',
                            Icons.link,
                          ),
                          const Divider(),
                          _buildInfoRow(
                            'Username',
                            _cospendUsername ?? 'Not available',
                            Icons.account_circle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 