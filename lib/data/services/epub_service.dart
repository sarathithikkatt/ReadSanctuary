import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

/// Represents a single chapter or section in an EPUB book.
class EpubChapter {
  final String title;
  final List<String> paragraphs;
  final int index;

  const EpubChapter({
    required this.title,
    required this.paragraphs,
    required this.index,
  });

  /// Approximate word count for this chapter.
  int get wordCount => paragraphs.fold(
      0, (sum, p) => sum + p.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length);
}

/// Represents an unpacked and parsed EPUB eBook.
class EpubBook {
  final String title;
  final String author;
  final Uint8List? coverBytes;
  final List<EpubChapter> chapters;

  const EpubBook({
    required this.title,
    required this.author,
    this.coverBytes,
    required this.chapters,
  });

  int get totalChapters => chapters.length;

  int get totalWordCount => chapters.fold(0, (sum, c) => sum + c.wordCount);
}

/// Pure Dart EPUB parser using `package:archive` and `package:xml`.
/// Avoids external dependencies that introduce image/codec version conflicts.
class EpubService {
  /// Parses raw EPUB bytes (.epub archive) into an [EpubBook].
  Future<EpubBook> parseEpubBytes(List<int> bytes) async {
    final archive = ZipDecoder().decodeBytes(bytes);

    // 1. Map archive entries by lowercase normalized path for easy lookup
    final entries = <String, ArchiveFile>{};
    for (final file in archive) {
      if (!file.isFile) continue;
      final normalized = file.name.replaceAll(r'\', '/').replaceAll('//', '/');
      entries[normalized.toLowerCase()] = file;
    }

    // 2. Locate META-INF/container.xml to find the OPF package file
    final containerFile = entries['meta-inf/container.xml'];
    if (containerFile == null) {
      throw const FormatException('Invalid EPUB: META-INF/container.xml not found');
    }

    final containerXml = utf8.decode(containerFile.content as List<int>);
    final containerDoc = XmlDocument.parse(containerXml);
    final rootfileElem = containerDoc
        .findAllElements('rootfile')
        .firstWhere((e) => e.getAttribute('full-path') != null);

    final opfFullPath = rootfileElem.getAttribute('full-path')!;
    final opfDir = p.dirname(opfFullPath) == '.' ? '' : p.dirname(opfFullPath);

    // 3. Locate and parse OPF package file
    final opfFile = entries[opfFullPath.toLowerCase()];
    if (opfFile == null) {
      throw FormatException('Invalid EPUB: OPF package not found at $opfFullPath');
    }

    final opfXml = utf8.decode(opfFile.content as List<int>);
    final opfDoc = XmlDocument.parse(opfXml);

    // 4. Extract Title and Creator / Author
    String title = 'Untitled Book';
    final titleElem = opfDoc.findAllElements('title').firstOrNull ??
        opfDoc.findAllElements('dc:title').firstOrNull;
    if (titleElem != null && titleElem.innerText.trim().isNotEmpty) {
      title = titleElem.innerText.trim();
    }

    String author = 'Unknown Author';
    final creatorElem = opfDoc.findAllElements('creator').firstOrNull ??
        opfDoc.findAllElements('dc:creator').firstOrNull;
    if (creatorElem != null && creatorElem.innerText.trim().isNotEmpty) {
      author = creatorElem.innerText.trim();
    }

    // 5. Parse Manifest items: id -> href path relative to root
    final manifestItems = <String, _ManifestItem>{};
    for (final item in opfDoc.findAllElements('item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type') ?? '';
      final properties = item.getAttribute('properties') ?? '';

      if (id != null && href != null) {
        // Resolve href relative to OPF file location
        final resolvedPath = opfDir.isNotEmpty
            ? p.normalize(p.join(opfDir, href)).replaceAll(r'\', '/')
            : href;
        manifestItems[id] = _ManifestItem(
          id: id,
          href: resolvedPath,
          mediaType: mediaType,
          properties: properties,
        );
      }
    }

    // 6. Extract Cover Image if available
    Uint8List? coverBytes;
    // Method A: Check for properties="cover-image"
    final coverItem = manifestItems.values.firstWhere(
      (m) =>
          m.properties.contains('cover-image') ||
          m.id == 'cover' ||
          m.id == 'cover-image',
      orElse: () => const _ManifestItem(id: '', href: '', mediaType: '', properties: ''),
    );

    if (coverItem.href.isNotEmpty) {
      final file = entries[coverItem.href.toLowerCase()];
      if (file != null) {
        coverBytes = Uint8List.fromList(file.content as List<int>);
      }
    }

    // 7. Parse Spine order
    final spineItems = <_ManifestItem>[];
    for (final itemref in opfDoc.findAllElements('itemref')) {
      final idref = itemref.getAttribute('idref');
      if (idref != null && manifestItems.containsKey(idref)) {
        final item = manifestItems[idref]!;
        if (item.mediaType.contains('html') ||
            item.href.endsWith('.xhtml') ||
            item.href.endsWith('.html') ||
            item.href.endsWith('.htm')) {
          spineItems.add(item);
        }
      }
    }

    // 8. Extract Chapters
    final chapters = <EpubChapter>[];
    int chapterIndex = 0;

    for (final item in spineItems) {
      final file = entries[item.href.toLowerCase()];
      if (file == null) continue;

      String htmlContent;
      try {
        htmlContent = utf8.decode(file.content as List<int>);
      } catch (_) {
        htmlContent = latin1.decode(file.content as List<int>);
      }

      final chapter = _parseChapterHtml(htmlContent, chapterIndex);
      if (chapter.paragraphs.isNotEmpty) {
        chapters.add(chapter);
        chapterIndex++;
      }
    }

    return EpubBook(
      title: title,
      author: author,
      coverBytes: coverBytes,
      chapters: chapters,
    );
  }

  /// Parses raw HTML/XHTML content of a single chapter into clean paragraphs and heading.
  EpubChapter _parseChapterHtml(String html, int index) {
    String chapterTitle = '';

    // Extract title from <title>
    final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>', caseSensitive: false, dotAll: true)
        .firstMatch(html);
    if (titleMatch != null) {
      chapterTitle = _cleanHtmlText(titleMatch.group(1) ?? '');
    }

    // Extract body content if present
    String bodyContent = html;
    final bodyMatch = RegExp(r'<body[^>]*>(.*?)</body>', caseSensitive: false, dotAll: true)
        .firstMatch(html);
    if (bodyMatch != null) {
      bodyContent = bodyMatch.group(1) ?? html;
    }

    // Look for top heading <h1>, <h2>, or <h3>
    final headingMatch = RegExp(r'<(h[1-3])[^>]*>(.*?)</\1>', caseSensitive: false, dotAll: true)
        .firstMatch(bodyContent);
    if (headingMatch != null) {
      final headingText = _cleanHtmlText(headingMatch.group(2) ?? '');
      if (chapterTitle.isEmpty || chapterTitle.toLowerCase().contains('untitled')) {
        chapterTitle = headingText;
      }
      // Remove this top heading so it is not duplicated in paragraphs
      bodyContent = bodyContent.replaceFirst(headingMatch.group(0)!, '');
    }

    if (chapterTitle.isEmpty) {
      chapterTitle = 'Chapter ${index + 1}';
    }

    // Replace paragraph and break tags with deliberate paragraph delimiters
    bodyContent = bodyContent
        .replaceAll(RegExp(r'</?(?:p|div|blockquote|h[1-6]|section|article)[^>]*>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');

    // Strip remaining HTML tags
    bodyContent = _cleanHtmlText(bodyContent);

    // Split on double newlines and filter out whitespace-only items
    final rawParagraphs = bodyContent.split(RegExp(r'\n{2,}'));
    final paragraphs = <String>[];

    for (final raw in rawParagraphs) {
      final p = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (p.isNotEmpty) {
        paragraphs.add(p);
      }
    }

    return EpubChapter(
      title: chapterTitle,
      paragraphs: paragraphs,
      index: index,
    );
  }

  /// Strips HTML tags and unescapes standard XML/HTML entities.
  static String _cleanHtmlText(String input) {
    var text = input.replaceAll(RegExp(r'<[^>]*>'), '');

    // Common entities
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&mdash;', '—')
        .replaceAll('&#8212;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&#8211;', '–')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&#8220;', '"')
        .replaceAll('&#8221;', '"')
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&#8216;', "'")
        .replaceAll('&#8217;', "'");

    // Numeric decimal entities: &#123;
    text = text.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
      final code = int.tryParse(match.group(1) ?? '');
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });

    // Numeric hex entities: &#x1a;
    text = text.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (match) {
      final code = int.tryParse(match.group(1) ?? '', radix: 16);
      return code != null ? String.fromCharCode(code) : match.group(0)!;
    });

    return text.trim();
  }
}

class _ManifestItem {
  final String id;
  final String href;
  final String mediaType;
  final String properties;

  const _ManifestItem({
    required this.id,
    required this.href,
    required this.mediaType,
    required this.properties,
  });
}

final epubServiceProvider = Provider<EpubService>((ref) {
  return EpubService();
});
