import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:epubx/epubx.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class Ebook {
  final String title;
  final File file;

  Ebook({required this.title, required this.file});
}

class EbookLocalLoader {
  static Future<List<Ebook>> getLocalEbooks() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();

    final ebookFiles = files
        .whereType<File>()
        .where((file) =>
    file.path.endsWith('.epub') || file.path.endsWith('.pdf'))
        .toList();

    List<Ebook> ebooks = [];

    for (final file in ebookFiles) {
      String title;

      try {
        if (file.path.endsWith('.epub')) {
          final bytes = await file.readAsBytes();
          final book = await EpubReader.readBook(bytes);
          title = book.Title ?? file.path.split('/').last;
        } else if (file.path.endsWith('.pdf')) {
          final bytes = await file.readAsBytes();
          final document = PdfDocument(inputBytes: bytes);
          title = document.documentInformation.title ?? file.path.split('/').last;
          document.dispose();
        } else {
          title = file.path.split('/').last;
        }
      } catch (e) {
        title = file.path.split('/').last; // Fallback on error
      }

      ebooks.add(Ebook(title: title, file: file));
    }

    return ebooks;
  }
}
