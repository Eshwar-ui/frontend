import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/utils/constants.dart';
import 'package:quantum_dashboard/utils/allowed_users.dart';
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
  String? _validationError;
  AuthProvider? _authProvider;
  NavigatorState? _navigator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save references to avoid deactivated widget errors
    if (!mounted) return;

    try {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _navigator = Navigator.of(context);
    } catch (e) {
      // Handle case where context is no longer valid
      print('Error accessing providers/navigator in didChangeDependencies: $e');
      _authProvider = null;
      _navigator = null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Delay async operations until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkConnectivity();
        _loadSavedCredentials();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    if (!mounted || _authProvider == null) return;

    try {
      setState(() {
        _connectivityMessage = null;
        _validationError = null;
      });
      _authProvider!.clearError();
    } catch (e) {
      // Silently handle errors if widget is disposed
      print('Error clearing errors: $e');
    }
  }

  void _togglePasswordVisibility() {
    if (!mounted) return;
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
    if (!mounted) return;

    final credentials = await CredentialStorageService.getSavedCredentials();
    if (!mounted) return;

    if (credentials != null && mounted) {
      final theme = Theme.of(context);
      final colorScheme = theme.colorScheme;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: theme.cardColor,
            title: Text(
              'Load Saved Credentials',
              style: TextStyle(color: colorScheme.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found saved credentials for:',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  credentials['email'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Last login: ${_formatLastLogin(credentials['lastLogin'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (mounted) {
                    setState(() {
                      _emailController.text = credentials['email'] ?? '';
                      _passwordController.text = credentials['password'] ?? '';
                      _rememberMe = true;
                    });
                  }
                  Navigator.of(dialogContext).pop();
                },
                child: Text('Load'),
              ),
              TextButton(
                onPressed: () async {
                  await CredentialStorageService.clearCredentials();
                  if (mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: Text(
                  'Clear',
                  style: TextStyle(color: colorScheme.error),
                ),
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
    if (!mounted || _authProvider == null) return;

    if (!_formKey.currentState!.validate()) return;

    _clearErrors();

    final email = _emailController.text.trim();
    if (!AllowedUsers.emails.contains(email)) {
      if (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
        // Mobile platform, show AlertDialog
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('Login Unauthorized'),
              content: Text('This email is not authorized to login.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Other platforms (web, desktop), use existing error display
        setState(() {
          _validationError = 'This email is not authorized to login.';
        });
      }
      return;
    }

    // No SnackBar for allowed users as per new requirement

    final success = await _authProvider!.login(
      email,
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Save credentials if remember me is checked
      try {
        await CredentialStorageService.saveCredentials(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          rememberMe: _rememberMe,
        );
      } catch (e) {
        // Silently handle save errors
        print('Error saving credentials: $e');
      }

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
      if (!mounted) return;

      final canConnect = await ConnectivityChecker.canConnectToBackend();

      if (!mounted) return;
      setState(() {
        _isCheckingConnectivity = false;
        _connectivityMessage = canConnect
            ? null
            : 'Cannot connect to server. Please check your network settings.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingConnectivity = false;
        _connectivityMessage = 'Error checking connectivity: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Select the logo based on the current theme
    final logoAsset = isDark
        ? 'assets/logos/quantumlogo-h(dark).png' // Your dark theme logo
        : 'assets/logos/quantumlogo-h(light).png'; // Your light theme logo

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      Image.asset(logoAsset, height: 50),
                      SizedBox(height: 20),
                      Text(
                        textAlign: TextAlign.center,
                        'Log in to your account and access your personalized dashboard',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
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
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) => _clearErrors(),
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Enter Email',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ).applyDefaults(theme.inputDecorationTheme),
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
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) => _clearErrors(),
                              onFieldSubmitted: (_) => _handleLogin(),
                              style: TextStyle(color: colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Enter Password',
                                hintStyle: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.6,
                                    ),
                                  ),
                                  onPressed: _togglePasswordVisibility,
                                ),
                              ).applyDefaults(theme.inputDecorationTheme),
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
                                  activeColor: colorScheme.primary,
                                ),
                                Text(
                                  'Remember me',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.8,
                                    ),
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
                                            color: colorScheme.primary,
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
                                      color: colorScheme.primary,
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
                                        child: Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50
                                                .withOpacity(isDark ? 0.2 : 1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.shade300,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.warning_amber_rounded,
                                                color: Colors.orange.shade700,
                                                size: 20,
                                              ),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _connectivityMessage!,
                                                  style: TextStyle(
                                                    color:
                                                        Colors.orange.shade900,
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.left,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (NetworkConfig.showDebugUI)
                                      Padding(
                                        padding: EdgeInsets.only(top: 10),
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.shade100
                                                .withOpacity(isDark ? 0.2 : 1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.amber.shade700,
                                              width: 1,
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
                                            onPressed: () {
                                              if (mounted) {
                                                _checkConnectivity();
                                              }
                                            },
                                            child: Text('Check Connection'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              if (!mounted ||
                                                  _navigator == null) {
                                                return;
                                              }
                                              try {
                                                _navigator!.push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        NetworkTroubleshootScreen(),
                                                  ),
                                                );
                                              } catch (e) {
                                                print(
                                                  'Error navigating to network troubleshoot: $e',
                                                );
                                              }
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
                                final errorText = _validationError ?? authProvider.error;
                                if (errorText != null) {
                                  return Padding(
                                    padding: EdgeInsets.only(top: 10),
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50.withOpacity(
                                          isDark ? 0.2 : 1,
                                        ),
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
                                              errorText,
                                              maxLines: 3,
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
                                        'If you forgot your password, our HR team is here to help! Contact us at ',
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'contact@quantumworks.in',
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontSize: 12,
                                      decoration: TextDecoration.underline,
                                    ),
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
