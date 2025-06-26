import 'dart:io';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';

class EpubReaderScreen extends StatefulWidget {
  final String filePath;

  const EpubReaderScreen({super.key, required this.filePath});

  @override
  State<EpubReaderScreen> createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  late final EpubController _epubController;
  String? _bookTitle;

  @override
  void initState() {
    super.initState();

    final file = File(widget.filePath);
    _epubController = EpubController(
      document: EpubDocument.openFile(file),
    );

    _loadTitle(file);
  }

  Future<void> _loadTitle(File file) async {
    final book = await EpubDocument.openFile(file);
    final title = book.Title;
    setState(() {
      _bookTitle = title ?? 'EPUB Reader';
    });
  }

  @override
  void dispose() {
    _epubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_bookTitle ?? 'Loading...')),
      body: SafeArea(
        child: EpubView(
          controller: _epubController,
          onDocumentLoaded: (document) {
            debugPrint('EPUB loaded');
          },
          onChapterChanged: (value) {
            debugPrint('Chapter changed');
          },
        ),
      ),
    );
  }
}
