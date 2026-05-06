import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/admin_screens/admin_offer_template_screen.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/services/attendance_settings_service.dart';
import 'package:quantum_dashboard/services/employee_service.dart';
import 'package:quantum_dashboard/utils/download_saver.dart';
import 'package:quantum_dashboard/utils/payslip_access_utils.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';
import 'package:quantum_dashboard/widgets/error_widget.dart';

class AdminOfferLettersScreen extends StatefulWidget {
  final Future<AttendanceSettings>? offerAccessFuture;

  const AdminOfferLettersScreen({super.key, this.offerAccessFuture});

  @override
  State<AdminOfferLettersScreen> createState() =>
      _AdminOfferLettersScreenState();
}

class _AdminOfferLettersScreenState extends State<AdminOfferLettersScreen> {
  final EmployeeService _employeeService = EmployeeService();
  late final Future<AttendanceSettings> _offerAccessFuture;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();

  bool _isCreating = false;
  bool _isSending = false;
  bool _isLoadingOffers = false;
  String? _lastCreatedOfferId;
  PlatformFile? _selectedPdf;
  List<Map<String, dynamic>> _offers = const [];
  final Set<String> _deletingOfferIds = <String>{};
  final Set<String> _viewingPdfIds = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _offerAccessFuture =
        widget.offerAccessFuture ??
        AttendanceSettingsService().getAttendanceSettings();
    _bootstrapOffers();
  }

  Future<void> _bootstrapOffers() async {
    try {
      final settings = await _offerAccessFuture;
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!canManageAdminOffers(authProvider.user, settings)) return;
      await _loadOffers();
    } catch (_) {}
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null || file.bytes!.isEmpty) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Unable to read selected PDF file.');
      return;
    }
    setState(() {
      _selectedPdf = file;
    });
  }

  Future<void> _previewSelectedPdf() async {
    final file = _selectedPdf;
    if (file == null || file.bytes == null) {
      SnackbarUtils.showError(context, 'Please select a PDF file first.');
      return;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final outFile = File(path);
      await outFile.writeAsBytes(file.bytes!, flush: true);
      await OpenFilex.open(outFile.path);
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Unable to preview PDF: $e');
    }
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoadingOffers = true;
    });
    try {
      final offers = await _employeeService.getOfferLetters();
      if (!mounted) return;
      setState(() {
        _offers = offers;
      });
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingOffers = false;
        });
      }
    }
  }

  Future<void> _createEmployeeWithOffer() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final file = _selectedPdf;

    if (name.isEmpty || email.isEmpty) {
      SnackbarUtils.showError(context, 'Name and email are required.');
      return;
    }
    if (file == null || file.bytes == null) {
      SnackbarUtils.showError(context, 'Please select a PDF offer letter.');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final result = await _employeeService.createEmployeeWithOffer(
        name: name,
        email: email,
        offerBytes: Uint8List.fromList(file.bytes!),
        fileName: file.name,
      );

      final createdId =
          result['offerId']?.toString() ?? result['employeeId']?.toString();
      setState(() {
        _lastCreatedOfferId = createdId;
        if (createdId != null && createdId.isNotEmpty) {
          _employeeIdController.text = createdId;
        }
      });

      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        result['message']?.toString() ?? 'Employee created with offer letter.',
      );
      await _loadOffers();
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _sendOfferEmail() async {
    final offerId = _employeeIdController.text.trim();
    if (offerId.isEmpty) {
      SnackbarUtils.showError(context, 'Offer ID is required.');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final result = await _employeeService.sendOfferLetter(offerId);
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        result['message']?.toString() ?? 'Offer email sent successfully.',
      );
      await _loadOffers();
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _deleteOffer(String offerId) async {
    if (offerId.isEmpty || _deletingOfferIds.contains(offerId)) {
      return;
    }

    setState(() {
      _deletingOfferIds.add(offerId);
    });

    try {
      final result = await _employeeService.deleteOfferLetter(offerId);
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        result['message']?.toString() ?? 'Offer deleted successfully.',
      );
      await _loadOffers();
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _deletingOfferIds.remove(offerId);
        });
      }
    }
  }

  Future<void> _viewOfferPdf(String offerId, String candidateName) async {
    if (offerId.isEmpty || _viewingPdfIds.contains(offerId)) return;

    setState(() {
      _viewingPdfIds.add(offerId);
    });

    try {
      final bytes = await _employeeService.getOfferPdfBytes(offerId);
      if (!mounted) return;

      final safeName = candidateName
          .replaceAll(RegExp(r'[^\w\s-]'), '_')
          .trim();
      final download = await DownloadSaver.saveBytesToDownloads(
        bytes: bytes,
        fileName:
            'offer_${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        mimeType: 'application/pdf',
      );

      if (!mounted) return;
      DownloadSaver.showSavedSnackBar(
        context: context,
        download: download,
        message: 'Offer letter downloaded successfully',
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _viewingPdfIds.remove(offerId);
        });
      }
    }
  }

  Future<void> _confirmDeleteOffer(String offerId, String candidateName) async {
    if (offerId.isEmpty || _deletingOfferIds.contains(offerId)) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Offer Record'),
          content: Text(
            'Are you sure you want to delete the offer record for $candidateName?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteOffer(offerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return FutureBuilder<AttendanceSettings>(
      future: _offerAccessFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: ErrorStateWidget(
              title: 'Unable to verify offer access',
              message:
                  'Please refresh the app or contact an administrator if this keeps happening.',
            ),
          );
        }

        final settings = snapshot.data;
        final canAccess =
            settings != null &&
            canManageAdminOffers(authProvider.user, settings);

        if (!canAccess) {
          return const Scaffold(
            body: ErrorStateWidget(
              title: 'Offer access denied',
              message: 'Your account is not allowed to manage offer letters.',
              icon: Icons.lock_outline,
            ),
          );
        }

        return _buildAllowedScreen(context);
      },
    );
  }

  Widget _buildAllowedScreen(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offer Letters',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Email Template',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminOfferTemplateScreen(
                    offerAccessFuture: _offerAccessFuture,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit_note),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Employee + Upload Offer PDF',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Employee Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isCreating ? null : _pickPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Choose PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: (_isCreating || _selectedPdf == null)
                          ? null
                          : _previewSelectedPdf,
                      icon: const Icon(Icons.visibility),
                      label: const Text('Preview PDF'),
                    ),
                    if (_selectedPdf != null)
                      Text(
                        _selectedPdf!.name,
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _createEmployeeWithOffer,
                    icon: _isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_file),
                    label: Text(
                      _isCreating ? 'Creating...' : 'Create Employee',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Offer Email',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(
                    labelText: 'Offer ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_lastCreatedOfferId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Last created offer ID: $_lastCreatedOfferId',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendOfferEmail,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSending ? 'Sending...' : 'Send Offer Email'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Offer Records (Separate List)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _isLoadingOffers ? null : _loadOffers,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_isLoadingOffers)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_offers.isEmpty)
                  Text(
                    'No offer records found.',
                    style: GoogleFonts.poppins(fontSize: 13),
                  )
                else
                  ..._offers.map((offer) {
                    final id = offer['_id']?.toString() ?? '';
                    final name = offer['name']?.toString() ?? '-';
                    final email = offer['email']?.toString() ?? '-';
                    final status = offer['status']?.toString() ?? 'pending';
                    final isDeleting = _deletingOfferIds.contains(id);
                    final isViewingPdf = _viewingPdfIds.contains(id);
                    final expiry = offer['offerTokenExpiry']?.toString();
                    final expiryLabel = expiry == null
                        ? '-'
                        : DateFormat('dd MMM yyyy, hh:mm a').format(
                            DateTime.tryParse(expiry)?.toLocal() ??
                                DateTime.now(),
                          );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      (_isSending ||
                                          isDeleting ||
                                          isViewingPdf ||
                                          id.isEmpty)
                                      ? null
                                      : () => _viewOfferPdf(id, name),
                                  icon: isViewingPdf
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.visibility_outlined),
                                  tooltip: 'View PDF',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Offer ID: $id',
                              style: GoogleFonts.poppins(fontSize: 11),
                            ),
                            Text(
                              'Status: $status',
                              style: GoogleFonts.poppins(fontSize: 11),
                            ),
                            Text(
                              'Token Expiry: $expiryLabel',
                              style: GoogleFonts.poppins(fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        (_isSending || isDeleting || id.isEmpty)
                                        ? null
                                        : () {
                                            _employeeIdController.text = id;
                                            _sendOfferEmail();
                                          },
                                    icon: const Icon(Icons.send, size: 18),
                                    label: const Text(
                                      'Send Offer',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed:
                                        (isDeleting || _isSending || id.isEmpty)
                                        ? null
                                        : () => _confirmDeleteOffer(id, name),
                                    icon: isDeleting
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                          ),
                                    label: Text(
                                      isDeleting ? 'Deleting...' : 'Delete',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
