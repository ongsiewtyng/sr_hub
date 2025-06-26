// lib/screens/ebook/ebook_picker_screen.dart
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EbookPickerScreen extends StatefulWidget {
  const EbookPickerScreen({super.key});

  @override
  State<EbookPickerScreen> createState() => _EbookPickerScreenState();
}

class _EbookPickerScreenState extends State<EbookPickerScreen> {
  String? _selectedFile;

  Future<void> _pickFile() async {
    final fileTypeGroup = XTypeGroup(
      label: 'ebooks',
      extensions: ['pdf', 'epub'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [fileTypeGroup]);

    if (file != null) {
      final path = file.path;
      setState(() => _selectedFile = path);
      _openEbook(path);
    }
  }

  void _openEbook(String path) {
    final isPdf = path.toLowerCase().endsWith('.pdf');
    final route = isPdf ? '/reader/pdf' : '/reader/epub';
    context.push(route, extra: path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('eBook Reader')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.folder_open),
          label: const Text('Pick eBook (.pdf or .epub)'),
          onPressed: _pickFile,
        ),
      ),
    );
  }
}
