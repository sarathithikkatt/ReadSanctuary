import 'dart:convert';
import 'package:drift/drift.dart';
import '../../../domain/entities/book_entity.dart';
import '../../../domain/entities/book_note_entity.dart';
import '../../../domain/entities/reading_session_entity.dart';
import '../../../domain/entities/shelf_entity.dart';
import '../../../domain/entities/shelf_item_entity.dart';
import '../database.dart';

/// Extension mappers converting Drift database models to pure Domain entities and vice versa.
extension BookMapper on Book {
  BookEntity toEntity() {
    List<String> parsedAuthors = [];
    try {
      final decoded = jsonDecode(authors);
      if (decoded is List) {
        parsedAuthors = decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      if (authors.isNotEmpty) parsedAuthors = [authors];
    }

    return BookEntity(
      id: id,
      isbn13: isbn13,
      title: title,
      subtitle: subtitle,
      description: description,
      publisher: publisher,
      publishYear: publishYear,
      authors: parsedAuthors,
      pageCount: pageCount,
      format: format,
      status: status,
      finishedAt: finishedAt,
      seriesName: seriesName,
      seriesIndex: seriesIndex,
      coverPath: coverPath,
      backCoverPath: backCoverPath,
      customSpinePath: customSpinePath,
      pdfPath: pdfPath,
      lastReadPage: lastReadPage,
      spineColorHex: spineColorHex,
      spineTextHex: spineTextHex,
      rating: rating,
      ratingPlot: ratingPlot,
      ratingCharacters: ratingCharacters,
      ratingWriting: ratingWriting,
      ratingPacing: ratingPacing,
      lastReadAt: lastReadAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension BookEntityMapper on BookEntity {
  BooksCompanion toCompanion() {
    return BooksCompanion(
      id: Value(id),
      isbn13: Value(isbn13),
      title: Value(title),
      subtitle: Value(subtitle),
      description: Value(description),
      publisher: Value(publisher),
      publishYear: Value(publishYear),
      authors: Value(jsonEncode(authors)),
      pageCount: Value(pageCount),
      format: Value(format),
      status: Value(status),
      finishedAt: Value(finishedAt),
      seriesName: Value(seriesName),
      seriesIndex: Value(seriesIndex),
      coverPath: Value(coverPath),
      backCoverPath: Value(backCoverPath),
      customSpinePath: Value(customSpinePath),
      pdfPath: Value(pdfPath),
      lastReadPage: Value(lastReadPage),
      spineColorHex: Value(spineColorHex),
      spineTextHex: Value(spineTextHex),
      rating: Value(rating),
      ratingPlot: Value(ratingPlot),
      ratingCharacters: Value(ratingCharacters),
      ratingWriting: Value(ratingWriting),
      ratingPacing: Value(ratingPacing),
      lastReadAt: Value(lastReadAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
    );
  }
}

extension ShelfMapper on Shelf {
  ShelfEntity toEntity() {
    return ShelfEntity(
      id: id,
      name: name,
      woodThemeId: woodThemeId,
      wallThemeId: wallThemeId,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
    );
  }
}

extension ShelfEntityMapper on ShelfEntity {
  ShelvesCompanion toCompanion() {
    return ShelvesCompanion(
      id: Value(id),
      name: Value(name),
      woodThemeId: Value(woodThemeId),
      wallThemeId: Value(wallThemeId),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: Value(deletedAt),
    );
  }
}

extension ShelfItemMapper on ShelfItem {
  ShelfItemEntity toEntity() {
    return ShelfItemEntity(
      id: id,
      shelfId: shelfId,
      itemType: itemType,
      bookId: bookId,
      propAssetId: propAssetId,
      displayMode: displayMode,
      positionIndex: positionIndex,
    );
  }
}

extension ShelfItemEntityMapper on ShelfItemEntity {
  ShelfItemsCompanion toCompanion() {
    return ShelfItemsCompanion(
      id: Value(id),
      shelfId: Value(shelfId),
      itemType: Value(itemType),
      bookId: Value(bookId),
      propAssetId: Value(propAssetId),
      displayMode: Value(displayMode),
      positionIndex: Value(positionIndex),
    );
  }
}

extension ReadingSessionMapper on ReadingSession {
  ReadingSessionEntity toEntity() {
    return ReadingSessionEntity(
      id: id,
      bookId: bookId,
      startTime: startTime,
      durationSeconds: durationSeconds,
      startPage: startPage,
      endPage: endPage,
    );
  }
}

extension ReadingSessionEntityMapper on ReadingSessionEntity {
  ReadingSessionsCompanion toCompanion() {
    return ReadingSessionsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      startTime: Value(startTime),
      durationSeconds: Value(durationSeconds),
      startPage: Value(startPage),
      endPage: Value(endPage),
    );
  }
}

extension BookNoteMapper on BookNote {
  BookNoteEntity toEntity() {
    return BookNoteEntity(
      id: id,
      bookId: bookId,
      noteType: noteType,
      content: content,
      pageNumber: pageNumber,
      createdAt: createdAt,
    );
  }
}

extension BookNoteEntityMapper on BookNoteEntity {
  BookNotesCompanion toCompanion() {
    return BookNotesCompanion(
      id: Value(id),
      bookId: Value(bookId),
      noteType: Value(noteType),
      content: Value(content),
      pageNumber: Value(pageNumber),
      createdAt: Value(createdAt),
    );
  }
}
