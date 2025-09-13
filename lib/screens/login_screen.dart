import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/utils/constants.dart';
import 'package:quantum_dashboard/widgets/custom_button.dart';
import 'package:quantum_dashboard/widgets/custom_floating_container.dart';
import 'package:quantum_dashboard/widgets/loading_dots_animation.dart';
import '../providers/auth_provider.dart';
import '../utils/connectivity_checker.dart';
import '../utils/network_config.dart';
import '../services/credential_storage_service.dart';
import 'network_troubleshoot_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isCheckingConnectivity = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _connectivityMessage;

  @override
  void initState() {
    super.initState();
    // Check connectivity when the login screen loads
    _checkConnectivity();
    // Load saved credentials
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (mounted) {
      setState(() {
        _connectivityMessage = null;
      });
      context.read<AuthProvider>().clearError();
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _loadSavedCredentials() async {
    final credentials = await CredentialStorageService.getSavedCredentials();
    if (credentials != null && mounted) {
      setState(() {
        _emailController.text = credentials['email'] ?? '';
        _passwordController.text = credentials['password'] ?? '';
        _rememberMe = credentials['rememberMe'] ?? false;
      });
    }
  }

  Future<void> _loadSavedCredentialsDialog() async {
    final credentials = await CredentialStorageService.getSavedCredentials();
    if (credentials != null && mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Load Saved Credentials'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Found saved credentials for:'),
                SizedBox(height: 8),
                Text(
                  credentials['email'] ?? '',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Last login: ${_formatLastLogin(credentials['lastLogin'])}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _emailController.text = credentials['email'] ?? '';
                    _passwordController.text = credentials['password'] ?? '';
                    _rememberMe = true;
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Load'),
              ),
              TextButton(
                onPressed: () async {
                  await CredentialStorageService.clearCredentials();
                  Navigator.of(context).pop();
                },
                child: Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        },
      );
    }
  }

  String _formatLastLogin(DateTime? lastLogin) {
    if (lastLogin == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(lastLogin);

    if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    _clearErrors();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      // Save credentials if remember me is checked
      await CredentialStorageService.saveCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      // Navigation will be handled by the main app based on auth state
      print('Login successful, navigating to dashboard');
    }
  }

  Future<void> _checkConnectivity() async {
    if (!mounted) return;

    setState(() {
      _isCheckingConnectivity = true;
      _connectivityMessage = null;
    });

    try {
      await ConnectivityChecker.printDiagnosticInfo();
      final canConnect = await ConnectivityChecker.canConnectToBackend();

      if (mounted) {
        setState(() {
          _isCheckingConnectivity = false;
          _connectivityMessage = canConnect
              ? null
              : 'Cannot connect to server. Please check your network settings.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingConnectivity = false;
          _connectivityMessage = 'Error checking connectivity: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Spacer(),
                SizedBox(height: 100),
                CustomFloatingContainer(
                  width: double.infinity,
                  height:
                      MediaQuery.of(context).size.height *
                      0.8, // Increased height to accommodate warnings

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spacer(),
                      Image.asset(AppAssets.quantumLogoH, height: 50),

                      SizedBox(height: 20),
                      Text(
                        textAlign: TextAlign.center,
                        'Log in to your account and access your personalized dashboard',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Email',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _clearErrors(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF1976D2),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: 'Enter Email',
                                fillColor: const Color.fromARGB(
                                  43,
                                  245,
                                  245,
                                  245,
                                ),
                                filled: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                ).hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => _clearErrors(),
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF1976D2),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: 'Enter Password',
                                fillColor: Colors.grey.shade100,
                                filled: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.grey.shade600,
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Remember Me Checkbox
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: Color(0xFF1976D2),
                                ),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                Spacer(),
                                // Load Saved Credentials Button
                                FutureBuilder<bool>(
                                  future:
                                      CredentialStorageService.hasSavedCredentials(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData &&
                                        snapshot.data == true) {
                                      return TextButton(
                                        onPressed: _loadSavedCredentialsDialog,
                                        child: Text(
                                          'Load Saved',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF1976D2),
                                          ),
                                        ),
                                      );
                                    }
                                    return SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                if (authProvider.isLoading ||
                                    _isCheckingConnectivity) {
                                  return Center(
                                    child: LoadingDotsAnimation(
                                      color: Color(0xFF1976D2),
                                      size: 10,
                                    ),
                                  );
                                }

                                return Column(
                                  children: [
                                    CustomButton(
                                      text: 'Login',
                                      onPressed: _handleLogin,
                                    ),
                                    if (_connectivityMessage != null)
                                      Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Text(
                                          _connectivityMessage!,
                                          style: TextStyle(
                                            color: Colors.orange,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    if (NetworkConfig.showDebugUI)
                                      Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade100,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber.shade700,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.amber.shade800,
                                                size: 16,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Using default IP address. Update in network_config.dart for mobile devices.',
                                                  style: TextStyle(
                                                    color:
                                                        Colors.amber.shade900,
                                                    fontSize: 12,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (NetworkConfig.showDebugUI) ...[
                                      SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TextButton(
                                            onPressed: _checkConnectivity,
                                            child: Text('Check Connection'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      NetworkTroubleshootScreen(),
                                                ),
                                              );
                                            },
                                            child: Text('Network Help'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                if (authProvider.error != null) {
                                  return Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: Colors.red.shade600,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              maxLines: 3,
                                              authProvider.error!,
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.red.shade600,
                                              size: 18,
                                            ),
                                            onPressed: _clearErrors,
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return SizedBox.shrink();
                              },
                            ),
                            SizedBox(height: 20),
                            Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        'If you forgot your password, our HR team is here to help! Contact us at',
                                  ),
                                  TextSpan(
                                    text: ' contact@quantumworks.in',
                                    style: TextStyle(color: Colors.blue),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        launchUrl(
                                          Uri(
                                            scheme: 'mailto',
                                            path: 'contact@quantumworks.in',
                                          ),
                                        );
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                ),
                // Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
