import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/widgets/custom_button.dart';
import 'package:quantum_dashboard/widgets/loading_dots_animation.dart';
import '../providers/auth_provider.dart';
import '../utils/connectivity_checker.dart';
import '../utils/network_config.dart';
import '../utils/error_handler.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Save references to avoid deactivated widget errors
    if (!mounted) return;

    try {
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
    } catch (e) {
      // Handle case where context is no longer valid
      print('Error accessing provider in didChangeDependencies: $e');
      _authProvider = null;
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

    // No SnackBar for allowed users as per new requirement

    final success = await _authProvider!.login(email, _passwordController.text);

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

    final logoAsset = isDark
        ? 'assets/logos/quantumlogo-h(dark).png'
        : 'assets/logos/quantumlogo-h(light).png';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Row(
        children: [
          // Left Side - Branding (Visible on large screens)
          if (MediaQuery.of(context).size.width >= 900)
            Expanded(
              child: Container(
                color: isDark
                    ? colorScheme.surfaceContainer
                    : colorScheme.primary.withOpacity(0.05),
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(logoAsset, height: 60),
                      const SizedBox(height: 40),
                      Text(
                        'Unlock Your Data\'s Potential',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Experience the next generation of enterprise analytics and dashboarding. Secure, scalable, and stunningly simple.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Add some feature indicators or subtle design elements
                      Row(
                        children: [
                          _buildMiniBadge(
                            Icons.security,
                            'Enterprise Security',
                          ),
                          const SizedBox(width: 20),
                          _buildMiniBadge(
                            Icons.analytics_outlined,
                            'Real-time Insights',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Right Side - Login Form
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 900 ? 80 : 24,
                  vertical: 40,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (MediaQuery.of(context).size.width < 900) ...[
                          Center(child: Image.asset(logoAsset, height: 50)),
                          const SizedBox(height: 48),
                        ],
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter your credentials to access your account',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) => _clearErrors(),
                                decoration: InputDecoration(
                                  labelText: 'Email Address',
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                  ),
                                  hintText: 'name@company.com',
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
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) => _clearErrors(),
                                onFieldSubmitted: (_) => _handleLogin(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: _togglePasswordVisibility,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.7,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  FutureBuilder<bool>(
                                    future:
                                        CredentialStorageService.hasSavedCredentials(),
                                    builder: (context, snapshot) {
                                      if (snapshot.data == true) {
                                        return TextButton(
                                          onPressed:
                                              _loadSavedCredentialsDialog,
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text('Autofill'),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
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

                                  return CustomButton(
                                    text: 'Login',
                                    onPressed: _handleLogin,
                                  );
                                },
                              ),
                              _buildErrorDisplay(),
                              _buildConnectivityDisplay(),
                              const SizedBox(height: 48),
                              Center(
                                child: Text.rich(
                                  textAlign: TextAlign.center,
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Forgot password? Contact ',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                      ),
                                      TextSpan(
                                        text: 'IT Support',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () => launchUrl(
                                            Uri(
                                              scheme: 'mailto',
                                              path: 'contact@quantumworks.in',
                                            ),
                                          ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorDisplay() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final errorText =
            _validationError ??
            (authProvider.error != null
                ? ErrorHandler.getErrorMessage(authProvider.error)
                : null);
        if (errorText != null) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: _clearErrors,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildConnectivityDisplay() {
    if (_connectivityMessage == null && !NetworkConfig.showDebugUI)
      return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          if (_connectivityMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    color: Colors.orange,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _connectivityMessage!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (NetworkConfig.showDebugUI) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _checkConnectivity,
                  child: const Text('Retry Connection'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NetworkTroubleshootScreen(),
                    ),
                  ),
                  child: const Text('Network Help'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
