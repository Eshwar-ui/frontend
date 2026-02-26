import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quantum_dashboard/services/employee_service.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

class AdminOfferTemplateScreen extends StatefulWidget {
  const AdminOfferTemplateScreen({super.key});

  @override
  State<AdminOfferTemplateScreen> createState() => _AdminOfferTemplateScreenState();
}

class _AdminOfferTemplateScreenState extends State<AdminOfferTemplateScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _ccController = TextEditingController();
  final TextEditingController _bccController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _templateController = TextEditingController();

  bool _isLoadingTemplate = false;
  bool _isSavingTemplate = false;

  @override
  void initState() {
    super.initState();
    _loadOfferTemplate();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _imageUrlController.dispose();
    _templateController.dispose();
    super.dispose();
  }

  List<String> _parseEmails(String raw) {
    return raw
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _loadOfferTemplate() async {
    setState(() {
      _isLoadingTemplate = true;
    });

    try {
      final data = await _employeeService.getOfferTemplate();
      if (!mounted) return;

      final cc = (data['cc'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .join(', ');
      final bcc = (data['bcc'] as List? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .join(', ');

      setState(() {
        _subjectController.text = data['subject']?.toString() ?? '';
        _templateController.text =
            data['templateText']?.toString() ??
            data['templateHtml']?.toString() ??
            '';
        _imageUrlController.text = data['imageUrl']?.toString() ?? '';
        _ccController.text = cc;
        _bccController.text = bcc;
      });
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTemplate = false;
        });
      }
    }
  }

  Future<void> _saveOfferTemplate() async {
    final subject = _subjectController.text.trim();
    final templateText = _templateController.text.trim();

    if (subject.isEmpty || templateText.isEmpty) {
      SnackbarUtils.showError(context, 'Subject and template are required.');
      return;
    }

    setState(() {
      _isSavingTemplate = true;
    });

    try {
      final result = await _employeeService.updateOfferTemplate(
        subject: subject,
        templateText: templateText,
        imageUrl: _imageUrlController.text.trim(),
        cc: _parseEmails(_ccController.text),
        bcc: _parseEmails(_bccController.text),
      );

      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        result['message']?.toString() ?? 'Offer email template updated.',
      );
      await _loadOfferTemplate();
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSavingTemplate = false;
        });
      }
    }
  }

  /// Hybrid: plain text stays plain; HTML is detected and rendered as template.
  bool _isHtmlContent(String text) =>
      text.trim().isNotEmpty && RegExp(r'<[a-zA-Z][^>]*>').hasMatch(text.trim());

  String _sanitizeHtmlForPreview(String html) {
    var content = html.trim();
    if (content.isEmpty) return content;

    // flutter_html handles fragments more reliably than full documents.
    content = content.replaceFirst(RegExp(r'<!DOCTYPE[^>]*>', caseSensitive: false), '');
    content = content.replaceAll(
      RegExp(r'<head[\s\S]*?</head>', caseSensitive: false),
      '',
    );

    final bodyMatch = RegExp(
      r'<body[^>]*>([\s\S]*?)</body>',
      caseSensitive: false,
    ).firstMatch(content);

    if (bodyMatch != null) {
      content = (bodyMatch.group(1) ?? '').trim();
    }

    // flutter_html can render gradient backgrounds poorly in some themes.
    content = content.replaceAll(
      RegExp(r'background\s*:\s*linear-gradient\([^;]+;?', caseSensitive: false),
      'background-color:#1e73be;',
    );

    if (!content.contains('<table') && !content.contains('<div')) {
      content = '<div>$content</div>';
    }

    return content;
  }

  String _buildPreviewText() {
    final template = _templateController.text.trim();
    if (template.isEmpty) return '';
    final previewNow = DateTime.now();
    final previewExpiry = previewNow.add(const Duration(days: 2));
    final expiresIn = previewExpiry.difference(previewNow);
    final days = expiresIn.inDays;
    final hours = expiresIn.inHours % 24;
    final minutes = expiresIn.inMinutes % 60;
    final expiresInText = '$days day${days == 1 ? '' : 's'} '
        '$hours hour${hours == 1 ? '' : 's'} '
        '$minutes minute${minutes == 1 ? '' : 's'}';
    final isHtml = _isHtmlContent(template);
    final renderedTemplate = isHtml ? _sanitizeHtmlForPreview(template) : template;
    final rendered = renderedTemplate
        .replaceAll('{{employee_name}}', 'Test Candidate')
        .replaceAll(
          '{{offer_link}}',
          'https://qw-backend-oymh.onrender.com/offer/sample-token',
        )
        .replaceAll(
          '{{offer_expiry_date}}',
          '${previewExpiry.day.toString().padLeft(2, '0')}-'
              '${previewExpiry.month.toString().padLeft(2, '0')}-'
              '${previewExpiry.year}',
        )
        .replaceAll(
          '{{offer_expiry_datetime}}',
          '${previewExpiry.day.toString().padLeft(2, '0')}-'
              '${previewExpiry.month.toString().padLeft(2, '0')}-'
              '${previewExpiry.year} '
              '${(previewExpiry.hour % 12 == 0 ? 12 : previewExpiry.hour % 12).toString().padLeft(2, '0')}:'
              '${previewExpiry.minute.toString().padLeft(2, '0')} '
              '${previewExpiry.hour >= 12 ? 'PM' : 'AM'}',
        )
        .replaceAll('{{offer_expiry_iso}}', previewExpiry.toUtc().toIso8601String())
        .replaceAll('{{offer_expires_in}}', expiresInText);

    final imageUrl = _imageUrlController.text.trim();
    return imageUrl.isEmpty ? rendered : '$rendered\n\nImage: $imageUrl';
  }

  Future<void> _showTemplatePreview() async {
    final previewText = _buildPreviewText();
    if (previewText.isEmpty) {
      SnackbarUtils.showError(context, 'Template is empty.');
      return;
    }

    final isHtml = _isHtmlContent(previewText);

    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 700),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Email Template Preview${isHtml ? ' (HTML)' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Container(
                    color: colorScheme.surface,
                    width: double.infinity,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: isHtml
                          ? Html(
                              data: previewText,
                              style: {
                                '*': Style(
                                  color: colorScheme.onSurface,
                                  fontFamily: GoogleFonts.poppins().fontFamily,
                                ),
                                'body': Style(
                                  backgroundColor: colorScheme.surface,
                                  fontSize: FontSize(13),
                                  lineHeight: const LineHeight(1.6),
                                ),
                              },
                            )
                          : SelectableText(
                              previewText,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                height: 1.6,
                                color: colorScheme.onSurface,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offer Email Template',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: _isLoadingTemplate ? null : _loadOfferTemplate,
            icon: const Icon(Icons.refresh),
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
                  'Use placeholders: {{employee_name}}, {{offer_link}}, {{offer_expiry_date}}, {{offer_expiry_datetime}}, {{offer_expiry_iso}}, {{offer_expires_in}}. Plain text or HTML - HTML is auto-detected and rendered.',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Email Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ccController,
                  decoration: const InputDecoration(
                    labelText: 'CC (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bccController,
                  decoration: const InputDecoration(
                    labelText: 'BCC (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _templateController,
                  minLines: 10,
                  maxLines: 16,
                  decoration: const InputDecoration(
                    labelText: 'Email Template (Plain Text or HTML)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_isSavingTemplate || _isLoadingTemplate)
                            ? null
                            : _showTemplatePreview,
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Preview Template'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_isSavingTemplate || _isLoadingTemplate)
                            ? null
                            : _saveOfferTemplate,
                        icon: (_isSavingTemplate || _isLoadingTemplate)
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(_isSavingTemplate ? 'Saving...' : 'Save Template'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

