import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfReaderScreen extends StatefulWidget {
  final String filePath;

  const PdfReaderScreen({super.key, required this.filePath});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  String? _pdfTitle;

  @override
  void initState() {
    super.initState();
    _loadTitle();
  }

  Future<void> _loadTitle() async {
    final bytes = await File(widget.filePath).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final title = document.documentInformation.title;
    document.dispose();

    setState(() {
      _pdfTitle = title ?? 'PDF Reader';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_pdfTitle ?? 'Loading...')),
      body: SfPdfViewer.file(File(widget.filePath)),
    );
  }
}
