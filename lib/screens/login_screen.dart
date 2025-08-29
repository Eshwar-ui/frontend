import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/utils/constants.dart';
import 'package:quantum_dashboard/widgets/custom_button.dart';
import 'package:quantum_dashboard/widgets/custom_floating_container.dart';
import '../providers/auth_provider.dart';
import '../utils/connectivity_checker.dart';
import '../utils/network_config.dart';
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
  String? _connectivityMessage;

  @override
  void initState() {
    super.initState();
    // Check connectivity when the login screen loads
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    setState(() {
      _isCheckingConnectivity = true;
      _connectivityMessage = null;
    });

    try {
      // Print diagnostic info to console
      await ConnectivityChecker.printDiagnosticInfo();

      final canConnect = await ConnectivityChecker.canConnectToBackend();

      setState(() {
        _isCheckingConnectivity = false;
        if (!canConnect) {
          _connectivityMessage =
              'Cannot connect to server. Please check your network settings.';
        }
      });
    } catch (e) {
      setState(() {
        _isCheckingConnectivity = false;
        _connectivityMessage = 'Error checking connectivity: $e';
      });
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
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
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
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
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
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: 'Enter Password',
                                fillColor: Colors.grey.shade100,
                                filled: true,
                              ),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                if (authProvider.isLoading ||
                                    _isCheckingConnectivity) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                return Column(
                                  children: [
                                    CustomButton(
                                      text: 'Login',
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          authProvider.login(
                                            _emailController.text,
                                            _passwordController.text,
                                          );
                                        }
                                      },
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
                                    if (!NetworkConfig.isUsingProduction)
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
                                );
                              },
                            ),
                            if (context.watch<AuthProvider>().error != null)
                              Padding(
                                padding: EdgeInsets.only(top: 10),
                                child: Text(
                                  context.watch<AuthProvider>().error!,
                                  style: TextStyle(color: Colors.red),
                                ),
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
