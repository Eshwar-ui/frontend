import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/connectivity_checker.dart';
import '../utils/network_config.dart';

class NetworkTroubleshootScreen extends StatefulWidget {
  const NetworkTroubleshootScreen({Key? key}) : super(key: key);

  @override
  _NetworkTroubleshootScreenState createState() =>
      _NetworkTroubleshootScreenState();
}

class _NetworkTroubleshootScreenState extends State<NetworkTroubleshootScreen> {
  Map<String, dynamic>? _diagnosticInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiagnosticInfo();
  }

  Future<void> _loadDiagnosticInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final info = await ConnectivityChecker.getDiagnosticInfo();
      if (mounted) {
        setState(() {
          _diagnosticInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Network Troubleshooting')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDiagnosticSection(),
                  SizedBox(height: 24),
                  _buildTroubleshootingGuide(),
                  SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildDiagnosticSection() {
    final canConnect = _diagnosticInfo?['canConnectToBackend'] ?? false;
    final isUsingDevelopment = !NetworkConfig.isUsingProduction;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Network Diagnostic',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (isUsingDevelopment)
              Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade800,
                    ),
                    SizedBox(width: 8),
                    // Expanded(
                    //   child: Text(
                    //     NetworkConfig.ipConfigWarning,
                    //     style: TextStyle(color: Colors.amber.shade900),
                    //   ),
                    // ),
                  ],
                ),
              ),
            _buildDiagnosticItem('Current API URL', NetworkConfig.baseUrl),
            _buildDiagnosticItem(
              'Platform',
              _diagnosticInfo?['platform'] ?? 'Unknown',
            ),
            _buildDiagnosticItem(
              'Server Connection',
              canConnect ? 'Connected ✓' : 'Failed to connect ✗',
              valueColor: canConnect ? Colors.green : Colors.red,
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadDiagnosticInfo,
              child: Text('Refresh Diagnostic Info'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticItem(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Expanded(
                  child: Text(value, style: TextStyle(color: valueColor)),
                ),
                if (label == 'Current API URL')
                  IconButton(
                    icon: Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('URL copied to clipboard')),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingGuide() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Troubleshooting Guide',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildTroubleshootingStep(
              '1',
              'Check Network Connection',
              'Make sure your mobile device is connected to the same WiFi network as your development machine.',
            ),
            _buildTroubleshootingStep(
              '2',
              'Verify Development Machine IP',
              'The default IP (192.168.1.100) needs to be changed to your development machine\'s actual IP address in network_config.dart. To find your IP:\n\n'
                  '• Windows: Open Command Prompt and type "ipconfig"\n'
                  '• macOS: Open Terminal and type "ifconfig"\n'
                  '• Linux: Open Terminal and type "ip addr show"\n\n'
                  'Look for IPv4 Address under your WiFi or Ethernet adapter.',
            ),
            _buildTroubleshootingStep(
              '3',
              'Check Backend Server',
              'Ensure your backend server is running on your development machine.',
            ),
            _buildTroubleshootingStep(
              '4',
              'Firewall Settings',
              'Check that your development machine\'s firewall allows incoming connections on port 5000.',
            ),
            _buildTroubleshootingStep(
              '5',
              'Test Backend Connection',
              'Try accessing the backend directly in your browser: https://quantum-dashboard-backend.onrender.com',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingStep(
    String number,
    String title,
    String description,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Back to Login'),
        ),
      ],
    );
  }
}
