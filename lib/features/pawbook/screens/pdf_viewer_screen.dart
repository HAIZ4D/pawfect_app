import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfBase64;
  final String title;

  const PdfViewerScreen({
    Key? key,
    required this.pdfBase64,
    required this.title,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  File? _pdfFile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = base64Decode(widget.pdfBase64);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/temp_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);

      setState(() {
        _pdfFile = file;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfFile == null) return;

    try {
      await Share.shareXFiles(
        [XFile(_pdfFile!.path)],
        subject: widget.title,
        text: 'Poisoning Incident Report',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing PDF: $e'),
          backgroundColor: PawfectColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PawfectColors.pawfectCream,
      appBar: AppBar(
        title: Text(widget.title, style: PawfectTextStyles.h3),
        backgroundColor: PawfectColors.error,
        foregroundColor: Colors.white,
        actions: [
          if (_pdfFile != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _sharePdf,
              tooltip: 'Share PDF',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: PawfectColors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading PDF',
                          style: PawfectTextStyles.h4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: PawfectTextStyles.bodySmall.copyWith(
                            color: PawfectColors.textHint,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [PawfectColors.cardShadow],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                size: 80,
                                color: PawfectColors.error,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'PDF Report Ready',
                                style: PawfectTextStyles.h3,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.title,
                                style: PawfectTextStyles.bodyMedium.copyWith(
                                  color: PawfectColors.textHint,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'The PDF report has been generated and saved.',
                                style: PawfectTextStyles.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Location: ${_pdfFile!.path}',
                                style: PawfectTextStyles.bodySmall.copyWith(
                                  color: PawfectColors.textHint,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 32),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _sharePdf,
                                      icon: const Icon(Icons.share),
                                      label: const Text('Share PDF'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: BorderSide(color: PawfectColors.error, width: 2),
                                        foregroundColor: PawfectColors.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.check),
                                      label: const Text('Done'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        backgroundColor: PawfectColors.success,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue[700]),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'View in PawBook',
                                      style: PawfectTextStyles.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[900],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This incident has been saved to your pet\'s medical history in PawBook.',
                                      style: PawfectTextStyles.bodySmall.copyWith(
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    // Clean up temp file
    _pdfFile?.delete().catchError((e) => print('Error deleting temp file: $e'));
    super.dispose();
  }
}
