import 'package:flutter/material.dart';
import '../services/cospend_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final formattedUrl = CospendService.formatUrl(_urlController.text);
      debugPrint('Attempting to connect to: $formattedUrl');

      // First check if the URL is valid
      final isValidUrl = await CospendService.isValidUrl(_urlController.text);
      
      if (!isValidUrl) {
        _showError(
          'Invalid Cospend server URL. Please ensure:\n'
          '1. The URL is correct\n'
          '2. The server is running\n'
          '3. Cospend is installed\n'
          '4. The server is accessible'
        );
        return;
      }

      // Then try to login
      final loginStatus = await CospendService.isValidLogin(
        url: _urlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
      );

      if (loginStatus == LoginStatus.ok) {
        // Save credentials securely
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cospend_url', _urlController.text);
        await prefs.setString('cospend_username', _usernameController.text);
        await prefs.setString('cospend_password', _passwordController.text);

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        _showError(_getErrorMessage(loginStatus));
      }
    } catch (e) {
      debugPrint('Login error: $e');
      _showError('An unexpected error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _getErrorMessage(LoginStatus status) {
    switch (status) {
      case LoginStatus.authFailed:
        return 'Invalid username or password';
      case LoginStatus.connectionFailed:
        return 'Could not connect to server';
      case LoginStatus.noNetwork:
        return 'No network connection';
      case LoginStatus.jsonFailed:
        return 'Invalid server response';
      case LoginStatus.serverFailed:
        return 'Server error';
      case LoginStatus.ssoTokenMismatch:
        return 'SSO token mismatch';
      case LoginStatus.reqFailed:
        return 'Request failed';
      default:
        return 'An unexpected error occurred';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Connect to Cospend',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'https://your-nextcloud-instance.com',
                      prefixIcon: Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter server URL';
                      }
                      if (!value.startsWith('http://') && 
                          !value.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword 
                            ? Icons.visibility 
                            : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _isLoading ? null : _login,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('CONNECT'),
                    ),
                  ),
                  if (CospendService.isHttp(_urlController.text)) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Warning: Using unsecure HTTP connection',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 