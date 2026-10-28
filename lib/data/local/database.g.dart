// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BooksTable extends Books with TableInfo<$BooksTable, Book> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BooksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isbn13Meta = const VerificationMeta('isbn13');
  @override
  late final GeneratedColumn<String> isbn13 = GeneratedColumn<String>(
      'isbn13', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subtitleMeta =
      const VerificationMeta('subtitle');
  @override
  late final GeneratedColumn<String> subtitle = GeneratedColumn<String>(
      'subtitle', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _authorsMeta =
      const VerificationMeta('authors');
  @override
  late final GeneratedColumn<String> authors = GeneratedColumn<String>(
      'authors', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageCountMeta =
      const VerificationMeta('pageCount');
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
      'page_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(250));
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
      'format', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('paperback'));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _seriesNameMeta =
      const VerificationMeta('seriesName');
  @override
  late final GeneratedColumn<String> seriesName = GeneratedColumn<String>(
      'series_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _seriesIndexMeta =
      const VerificationMeta('seriesIndex');
  @override
  late final GeneratedColumn<double> seriesIndex = GeneratedColumn<double>(
      'series_index', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _coverPathMeta =
      const VerificationMeta('coverPath');
  @override
  late final GeneratedColumn<String> coverPath = GeneratedColumn<String>(
      'cover_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _customSpinePathMeta =
      const VerificationMeta('customSpinePath');
  @override
  late final GeneratedColumn<String> customSpinePath = GeneratedColumn<String>(
      'custom_spine_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _spineColorHexMeta =
      const VerificationMeta('spineColorHex');
  @override
  late final GeneratedColumn<int> spineColorHex = GeneratedColumn<int>(
      'spine_color_hex', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _spineTextHexMeta =
      const VerificationMeta('spineTextHex');
  @override
  late final GeneratedColumn<int> spineTextHex = GeneratedColumn<int>(
      'spine_text_hex', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
      'rating', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        isbn13,
        title,
        subtitle,
        authors,
        pageCount,
        format,
        status,
        seriesName,
        seriesIndex,
        coverPath,
        customSpinePath,
        spineColorHex,
        spineTextHex,
        rating,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'books';
  @override
  VerificationContext validateIntegrity(Insertable<Book> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('isbn13')) {
      context.handle(_isbn13Meta,
          isbn13.isAcceptableOrUnknown(data['isbn13']!, _isbn13Meta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('subtitle')) {
      context.handle(_subtitleMeta,
          subtitle.isAcceptableOrUnknown(data['subtitle']!, _subtitleMeta));
    }
    if (data.containsKey('authors')) {
      context.handle(_authorsMeta,
          authors.isAcceptableOrUnknown(data['authors']!, _authorsMeta));
    } else if (isInserting) {
      context.missing(_authorsMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(_pageCountMeta,
          pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta));
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta,
          format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('series_name')) {
      context.handle(
          _seriesNameMeta,
          seriesName.isAcceptableOrUnknown(
              data['series_name']!, _seriesNameMeta));
    }
    if (data.containsKey('series_index')) {
      context.handle(
          _seriesIndexMeta,
          seriesIndex.isAcceptableOrUnknown(
              data['series_index']!, _seriesIndexMeta));
    }
    if (data.containsKey('cover_path')) {
      context.handle(_coverPathMeta,
          coverPath.isAcceptableOrUnknown(data['cover_path']!, _coverPathMeta));
    }
    if (data.containsKey('custom_spine_path')) {
      context.handle(
          _customSpinePathMeta,
          customSpinePath.isAcceptableOrUnknown(
              data['custom_spine_path']!, _customSpinePathMeta));
    }
    if (data.containsKey('spine_color_hex')) {
      context.handle(
          _spineColorHexMeta,
          spineColorHex.isAcceptableOrUnknown(
              data['spine_color_hex']!, _spineColorHexMeta));
    } else if (isInserting) {
      context.missing(_spineColorHexMeta);
    }
    if (data.containsKey('spine_text_hex')) {
      context.handle(
          _spineTextHexMeta,
          spineTextHex.isAcceptableOrUnknown(
              data['spine_text_hex']!, _spineTextHexMeta));
    } else if (isInserting) {
      context.missing(_spineTextHexMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Book map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Book(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      isbn13: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}isbn13']),
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      subtitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subtitle']),
      authors: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}authors'])!,
      pageCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_count'])!,
      format: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      seriesName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}series_name']),
      seriesIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}series_index']),
      coverPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cover_path']),
      customSpinePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}custom_spine_path']),
      spineColorHex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}spine_color_hex'])!,
      spineTextHex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}spine_text_hex'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}rating']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BooksTable createAlias(String alias) {
    return $BooksTable(attachedDatabase, alias);
  }
}

class Book extends DataClass implements Insertable<Book> {
  final String id;
  final String? isbn13;
  final String title;
  final String? subtitle;
  final String authors;
  final int pageCount;
  final String format;
  final String status;
  final String? seriesName;
  final double? seriesIndex;
  final String? coverPath;
  final String? customSpinePath;
  final int spineColorHex;
  final int spineTextHex;
  final double? rating;
  final int createdAt;
  final int updatedAt;
  const Book(
      {required this.id,
      this.isbn13,
      required this.title,
      this.subtitle,
      required this.authors,
      required this.pageCount,
      required this.format,
      required this.status,
      this.seriesName,
      this.seriesIndex,
      this.coverPath,
      this.customSpinePath,
      required this.spineColorHex,
      required this.spineTextHex,
      this.rating,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || isbn13 != null) {
      map['isbn13'] = Variable<String>(isbn13);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || subtitle != null) {
      map['subtitle'] = Variable<String>(subtitle);
    }
    map['authors'] = Variable<String>(authors);
    map['page_count'] = Variable<int>(pageCount);
    map['format'] = Variable<String>(format);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || seriesName != null) {
      map['series_name'] = Variable<String>(seriesName);
    }
    if (!nullToAbsent || seriesIndex != null) {
      map['series_index'] = Variable<double>(seriesIndex);
    }
    if (!nullToAbsent || coverPath != null) {
      map['cover_path'] = Variable<String>(coverPath);
    }
    if (!nullToAbsent || customSpinePath != null) {
      map['custom_spine_path'] = Variable<String>(customSpinePath);
    }
    map['spine_color_hex'] = Variable<int>(spineColorHex);
    map['spine_text_hex'] = Variable<int>(spineTextHex);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  BooksCompanion toCompanion(bool nullToAbsent) {
    return BooksCompanion(
      id: Value(id),
      isbn13:
          isbn13 == null && nullToAbsent ? const Value.absent() : Value(isbn13),
      title: Value(title),
      subtitle: subtitle == null && nullToAbsent
          ? const Value.absent()
          : Value(subtitle),
      authors: Value(authors),
      pageCount: Value(pageCount),
      format: Value(format),
      status: Value(status),
      seriesName: seriesName == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesName),
      seriesIndex: seriesIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesIndex),
      coverPath: coverPath == null && nullToAbsent
          ? const Value.absent()
          : Value(coverPath),
      customSpinePath: customSpinePath == null && nullToAbsent
          ? const Value.absent()
          : Value(customSpinePath),
      spineColorHex: Value(spineColorHex),
      spineTextHex: Value(spineTextHex),
      rating:
          rating == null && nullToAbsent ? const Value.absent() : Value(rating),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Book.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Book(
      id: serializer.fromJson<String>(json['id']),
      isbn13: serializer.fromJson<String?>(json['isbn13']),
      title: serializer.fromJson<String>(json['title']),
      subtitle: serializer.fromJson<String?>(json['subtitle']),
      authors: serializer.fromJson<String>(json['authors']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      format: serializer.fromJson<String>(json['format']),
      status: serializer.fromJson<String>(json['status']),
      seriesName: serializer.fromJson<String?>(json['seriesName']),
      seriesIndex: serializer.fromJson<double?>(json['seriesIndex']),
      coverPath: serializer.fromJson<String?>(json['coverPath']),
      customSpinePath: serializer.fromJson<String?>(json['customSpinePath']),
      spineColorHex: serializer.fromJson<int>(json['spineColorHex']),
      spineTextHex: serializer.fromJson<int>(json['spineTextHex']),
      rating: serializer.fromJson<double?>(json['rating']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'isbn13': serializer.toJson<String?>(isbn13),
      'title': serializer.toJson<String>(title),
      'subtitle': serializer.toJson<String?>(subtitle),
      'authors': serializer.toJson<String>(authors),
      'pageCount': serializer.toJson<int>(pageCount),
      'format': serializer.toJson<String>(format),
      'status': serializer.toJson<String>(status),
      'seriesName': serializer.toJson<String?>(seriesName),
      'seriesIndex': serializer.toJson<double?>(seriesIndex),
      'coverPath': serializer.toJson<String?>(coverPath),
      'customSpinePath': serializer.toJson<String?>(customSpinePath),
      'spineColorHex': serializer.toJson<int>(spineColorHex),
      'spineTextHex': serializer.toJson<int>(spineTextHex),
      'rating': serializer.toJson<double?>(rating),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  Book copyWith(
          {String? id,
          Value<String?> isbn13 = const Value.absent(),
          String? title,
          Value<String?> subtitle = const Value.absent(),
          String? authors,
          int? pageCount,
          String? format,
          String? status,
          Value<String?> seriesName = const Value.absent(),
          Value<double?> seriesIndex = const Value.absent(),
          Value<String?> coverPath = const Value.absent(),
          Value<String?> customSpinePath = const Value.absent(),
          int? spineColorHex,
          int? spineTextHex,
          Value<double?> rating = const Value.absent(),
          int? createdAt,
          int? updatedAt}) =>
      Book(
        id: id ?? this.id,
        isbn13: isbn13.present ? isbn13.value : this.isbn13,
        title: title ?? this.title,
        subtitle: subtitle.present ? subtitle.value : this.subtitle,
        authors: authors ?? this.authors,
        pageCount: pageCount ?? this.pageCount,
        format: format ?? this.format,
        status: status ?? this.status,
        seriesName: seriesName.present ? seriesName.value : this.seriesName,
        seriesIndex: seriesIndex.present ? seriesIndex.value : this.seriesIndex,
        coverPath: coverPath.present ? coverPath.value : this.coverPath,
        customSpinePath: customSpinePath.present
            ? customSpinePath.value
            : this.customSpinePath,
        spineColorHex: spineColorHex ?? this.spineColorHex,
        spineTextHex: spineTextHex ?? this.spineTextHex,
        rating: rating.present ? rating.value : this.rating,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  Book copyWithCompanion(BooksCompanion data) {
    return Book(
      id: data.id.present ? data.id.value : this.id,
      isbn13: data.isbn13.present ? data.isbn13.value : this.isbn13,
      title: data.title.present ? data.title.value : this.title,
      subtitle: data.subtitle.present ? data.subtitle.value : this.subtitle,
      authors: data.authors.present ? data.authors.value : this.authors,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      format: data.format.present ? data.format.value : this.format,
      status: data.status.present ? data.status.value : this.status,
      seriesName:
          data.seriesName.present ? data.seriesName.value : this.seriesName,
      seriesIndex:
          data.seriesIndex.present ? data.seriesIndex.value : this.seriesIndex,
      coverPath: data.coverPath.present ? data.coverPath.value : this.coverPath,
      customSpinePath: data.customSpinePath.present
          ? data.customSpinePath.value
          : this.customSpinePath,
      spineColorHex: data.spineColorHex.present
          ? data.spineColorHex.value
          : this.spineColorHex,
      spineTextHex: data.spineTextHex.present
          ? data.spineTextHex.value
          : this.spineTextHex,
      rating: data.rating.present ? data.rating.value : this.rating,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Book(')
          ..write('id: $id, ')
          ..write('isbn13: $isbn13, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('authors: $authors, ')
          ..write('pageCount: $pageCount, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('seriesName: $seriesName, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('coverPath: $coverPath, ')
          ..write('customSpinePath: $customSpinePath, ')
          ..write('spineColorHex: $spineColorHex, ')
          ..write('spineTextHex: $spineTextHex, ')
          ..write('rating: $rating, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      isbn13,
      title,
      subtitle,
      authors,
      pageCount,
      format,
      status,
      seriesName,
      seriesIndex,
      coverPath,
      customSpinePath,
      spineColorHex,
      spineTextHex,
      rating,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Book &&
          other.id == this.id &&
          other.isbn13 == this.isbn13 &&
          other.title == this.title &&
          other.subtitle == this.subtitle &&
          other.authors == this.authors &&
          other.pageCount == this.pageCount &&
          other.format == this.format &&
          other.status == this.status &&
          other.seriesName == this.seriesName &&
          other.seriesIndex == this.seriesIndex &&
          other.coverPath == this.coverPath &&
          other.customSpinePath == this.customSpinePath &&
          other.spineColorHex == this.spineColorHex &&
          other.spineTextHex == this.spineTextHex &&
          other.rating == this.rating &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class BooksCompanion extends UpdateCompanion<Book> {
  final Value<String> id;
  final Value<String?> isbn13;
  final Value<String> title;
  final Value<String?> subtitle;
  final Value<String> authors;
  final Value<int> pageCount;
  final Value<String> format;
  final Value<String> status;
  final Value<String?> seriesName;
  final Value<double?> seriesIndex;
  final Value<String?> coverPath;
  final Value<String?> customSpinePath;
  final Value<int> spineColorHex;
  final Value<int> spineTextHex;
  final Value<double?> rating;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const BooksCompanion({
    this.id = const Value.absent(),
    this.isbn13 = const Value.absent(),
    this.title = const Value.absent(),
    this.subtitle = const Value.absent(),
    this.authors = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.format = const Value.absent(),
    this.status = const Value.absent(),
    this.seriesName = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.customSpinePath = const Value.absent(),
    this.spineColorHex = const Value.absent(),
    this.spineTextHex = const Value.absent(),
    this.rating = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BooksCompanion.insert({
    required String id,
    this.isbn13 = const Value.absent(),
    required String title,
    this.subtitle = const Value.absent(),
    required String authors,
    this.pageCount = const Value.absent(),
    this.format = const Value.absent(),
    required String status,
    this.seriesName = const Value.absent(),
    this.seriesIndex = const Value.absent(),
    this.coverPath = const Value.absent(),
    this.customSpinePath = const Value.absent(),
    required int spineColorHex,
    required int spineTextHex,
    this.rating = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        authors = Value(authors),
        status = Value(status),
        spineColorHex = Value(spineColorHex),
        spineTextHex = Value(spineTextHex),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<Book> custom({
    Expression<String>? id,
    Expression<String>? isbn13,
    Expression<String>? title,
    Expression<String>? subtitle,
    Expression<String>? authors,
    Expression<int>? pageCount,
    Expression<String>? format,
    Expression<String>? status,
    Expression<String>? seriesName,
    Expression<double>? seriesIndex,
    Expression<String>? coverPath,
    Expression<String>? customSpinePath,
    Expression<int>? spineColorHex,
    Expression<int>? spineTextHex,
    Expression<double>? rating,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (isbn13 != null) 'isbn13': isbn13,
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (authors != null) 'authors': authors,
      if (pageCount != null) 'page_count': pageCount,
      if (format != null) 'format': format,
      if (status != null) 'status': status,
      if (seriesName != null) 'series_name': seriesName,
      if (seriesIndex != null) 'series_index': seriesIndex,
      if (coverPath != null) 'cover_path': coverPath,
      if (customSpinePath != null) 'custom_spine_path': customSpinePath,
      if (spineColorHex != null) 'spine_color_hex': spineColorHex,
      if (spineTextHex != null) 'spine_text_hex': spineTextHex,
      if (rating != null) 'rating': rating,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BooksCompanion copyWith(
      {Value<String>? id,
      Value<String?>? isbn13,
      Value<String>? title,
      Value<String?>? subtitle,
      Value<String>? authors,
      Value<int>? pageCount,
      Value<String>? format,
      Value<String>? status,
      Value<String?>? seriesName,
      Value<double?>? seriesIndex,
      Value<String?>? coverPath,
      Value<String?>? customSpinePath,
      Value<int>? spineColorHex,
      Value<int>? spineTextHex,
      Value<double?>? rating,
      Value<int>? createdAt,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return BooksCompanion(
      id: id ?? this.id,
      isbn13: isbn13 ?? this.isbn13,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      authors: authors ?? this.authors,
      pageCount: pageCount ?? this.pageCount,
      format: format ?? this.format,
      status: status ?? this.status,
      seriesName: seriesName ?? this.seriesName,
      seriesIndex: seriesIndex ?? this.seriesIndex,
      coverPath: coverPath ?? this.coverPath,
      customSpinePath: customSpinePath ?? this.customSpinePath,
      spineColorHex: spineColorHex ?? this.spineColorHex,
      spineTextHex: spineTextHex ?? this.spineTextHex,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (isbn13.present) {
      map['isbn13'] = Variable<String>(isbn13.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subtitle.present) {
      map['subtitle'] = Variable<String>(subtitle.value);
    }
    if (authors.present) {
      map['authors'] = Variable<String>(authors.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (seriesName.present) {
      map['series_name'] = Variable<String>(seriesName.value);
    }
    if (seriesIndex.present) {
      map['series_index'] = Variable<double>(seriesIndex.value);
    }
    if (coverPath.present) {
      map['cover_path'] = Variable<String>(coverPath.value);
    }
    if (customSpinePath.present) {
      map['custom_spine_path'] = Variable<String>(customSpinePath.value);
    }
    if (spineColorHex.present) {
      map['spine_color_hex'] = Variable<int>(spineColorHex.value);
    }
    if (spineTextHex.present) {
      map['spine_text_hex'] = Variable<int>(spineTextHex.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BooksCompanion(')
          ..write('id: $id, ')
          ..write('isbn13: $isbn13, ')
          ..write('title: $title, ')
          ..write('subtitle: $subtitle, ')
          ..write('authors: $authors, ')
          ..write('pageCount: $pageCount, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('seriesName: $seriesName, ')
          ..write('seriesIndex: $seriesIndex, ')
          ..write('coverPath: $coverPath, ')
          ..write('customSpinePath: $customSpinePath, ')
          ..write('spineColorHex: $spineColorHex, ')
          ..write('spineTextHex: $spineTextHex, ')
          ..write('rating: $rating, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShelvesTable extends Shelves with TableInfo<$ShelvesTable, Shelf> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShelvesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _woodThemeIdMeta =
      const VerificationMeta('woodThemeId');
  @override
  late final GeneratedColumn<String> woodThemeId = GeneratedColumn<String>(
      'wood_theme_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('oak'));
  static const VerificationMeta _wallThemeIdMeta =
      const VerificationMeta('wallThemeId');
  @override
  late final GeneratedColumn<String> wallThemeId = GeneratedColumn<String>(
      'wall_theme_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('warm_cream'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, woodThemeId, wallThemeId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelves';
  @override
  VerificationContext validateIntegrity(Insertable<Shelf> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('wood_theme_id')) {
      context.handle(
          _woodThemeIdMeta,
          woodThemeId.isAcceptableOrUnknown(
              data['wood_theme_id']!, _woodThemeIdMeta));
    }
    if (data.containsKey('wall_theme_id')) {
      context.handle(
          _wallThemeIdMeta,
          wallThemeId.isAcceptableOrUnknown(
              data['wall_theme_id']!, _wallThemeIdMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Shelf map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shelf(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      woodThemeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wood_theme_id'])!,
      wallThemeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}wall_theme_id'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $ShelvesTable createAlias(String alias) {
    return $ShelvesTable(attachedDatabase, alias);
  }
}

class Shelf extends DataClass implements Insertable<Shelf> {
  final String id;
  final String name;
  final String woodThemeId;
  final String wallThemeId;
  final int sortOrder;
  const Shelf(
      {required this.id,
      required this.name,
      required this.woodThemeId,
      required this.wallThemeId,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['wood_theme_id'] = Variable<String>(woodThemeId);
    map['wall_theme_id'] = Variable<String>(wallThemeId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ShelvesCompanion toCompanion(bool nullToAbsent) {
    return ShelvesCompanion(
      id: Value(id),
      name: Value(name),
      woodThemeId: Value(woodThemeId),
      wallThemeId: Value(wallThemeId),
      sortOrder: Value(sortOrder),
    );
  }

  factory Shelf.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shelf(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      woodThemeId: serializer.fromJson<String>(json['woodThemeId']),
      wallThemeId: serializer.fromJson<String>(json['wallThemeId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'woodThemeId': serializer.toJson<String>(woodThemeId),
      'wallThemeId': serializer.toJson<String>(wallThemeId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Shelf copyWith(
          {String? id,
          String? name,
          String? woodThemeId,
          String? wallThemeId,
          int? sortOrder}) =>
      Shelf(
        id: id ?? this.id,
        name: name ?? this.name,
        woodThemeId: woodThemeId ?? this.woodThemeId,
        wallThemeId: wallThemeId ?? this.wallThemeId,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  Shelf copyWithCompanion(ShelvesCompanion data) {
    return Shelf(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      woodThemeId:
          data.woodThemeId.present ? data.woodThemeId.value : this.woodThemeId,
      wallThemeId:
          data.wallThemeId.present ? data.wallThemeId.value : this.wallThemeId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shelf(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('woodThemeId: $woodThemeId, ')
          ..write('wallThemeId: $wallThemeId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, woodThemeId, wallThemeId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shelf &&
          other.id == this.id &&
          other.name == this.name &&
          other.woodThemeId == this.woodThemeId &&
          other.wallThemeId == this.wallThemeId &&
          other.sortOrder == this.sortOrder);
}

class ShelvesCompanion extends UpdateCompanion<Shelf> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> woodThemeId;
  final Value<String> wallThemeId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ShelvesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.woodThemeId = const Value.absent(),
    this.wallThemeId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShelvesCompanion.insert({
    required String id,
    required String name,
    this.woodThemeId = const Value.absent(),
    this.wallThemeId = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        sortOrder = Value(sortOrder);
  static Insertable<Shelf> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? woodThemeId,
    Expression<String>? wallThemeId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (woodThemeId != null) 'wood_theme_id': woodThemeId,
      if (wallThemeId != null) 'wall_theme_id': wallThemeId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShelvesCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String>? woodThemeId,
      Value<String>? wallThemeId,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return ShelvesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      woodThemeId: woodThemeId ?? this.woodThemeId,
      wallThemeId: wallThemeId ?? this.wallThemeId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (woodThemeId.present) {
      map['wood_theme_id'] = Variable<String>(woodThemeId.value);
    }
    if (wallThemeId.present) {
      map['wall_theme_id'] = Variable<String>(wallThemeId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShelvesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('woodThemeId: $woodThemeId, ')
          ..write('wallThemeId: $wallThemeId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShelfItemsTable extends ShelfItems
    with TableInfo<$ShelfItemsTable, ShelfItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShelfItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _shelfIdMeta =
      const VerificationMeta('shelfId');
  @override
  late final GeneratedColumn<String> shelfId = GeneratedColumn<String>(
      'shelf_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES shelves (id) ON DELETE CASCADE'));
  static const VerificationMeta _itemTypeMeta =
      const VerificationMeta('itemType');
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
      'item_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES books (id) ON DELETE CASCADE'));
  static const VerificationMeta _propAssetIdMeta =
      const VerificationMeta('propAssetId');
  @override
  late final GeneratedColumn<String> propAssetId = GeneratedColumn<String>(
      'prop_asset_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _displayModeMeta =
      const VerificationMeta('displayMode');
  @override
  late final GeneratedColumn<String> displayMode = GeneratedColumn<String>(
      'display_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('spine'));
  static const VerificationMeta _positionIndexMeta =
      const VerificationMeta('positionIndex');
  @override
  late final GeneratedColumn<int> positionIndex = GeneratedColumn<int>(
      'position_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, shelfId, itemType, bookId, propAssetId, displayMode, positionIndex];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelf_items';
  @override
  VerificationContext validateIntegrity(Insertable<ShelfItem> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('shelf_id')) {
      context.handle(_shelfIdMeta,
          shelfId.isAcceptableOrUnknown(data['shelf_id']!, _shelfIdMeta));
    } else if (isInserting) {
      context.missing(_shelfIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(_itemTypeMeta,
          itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta));
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    }
    if (data.containsKey('prop_asset_id')) {
      context.handle(
          _propAssetIdMeta,
          propAssetId.isAcceptableOrUnknown(
              data['prop_asset_id']!, _propAssetIdMeta));
    }
    if (data.containsKey('display_mode')) {
      context.handle(
          _displayModeMeta,
          displayMode.isAcceptableOrUnknown(
              data['display_mode']!, _displayModeMeta));
    }
    if (data.containsKey('position_index')) {
      context.handle(
          _positionIndexMeta,
          positionIndex.isAcceptableOrUnknown(
              data['position_index']!, _positionIndexMeta));
    } else if (isInserting) {
      context.missing(_positionIndexMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShelfItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShelfItem(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      shelfId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}shelf_id'])!,
      itemType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_type'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id']),
      propAssetId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prop_asset_id']),
      displayMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}display_mode'])!,
      positionIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}position_index'])!,
    );
  }

  @override
  $ShelfItemsTable createAlias(String alias) {
    return $ShelfItemsTable(attachedDatabase, alias);
  }
}

class ShelfItem extends DataClass implements Insertable<ShelfItem> {
  final String id;
  final String shelfId;
  final String itemType;
  final String? bookId;
  final String? propAssetId;
  final String displayMode;
  final int positionIndex;
  const ShelfItem(
      {required this.id,
      required this.shelfId,
      required this.itemType,
      this.bookId,
      this.propAssetId,
      required this.displayMode,
      required this.positionIndex});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['shelf_id'] = Variable<String>(shelfId);
    map['item_type'] = Variable<String>(itemType);
    if (!nullToAbsent || bookId != null) {
      map['book_id'] = Variable<String>(bookId);
    }
    if (!nullToAbsent || propAssetId != null) {
      map['prop_asset_id'] = Variable<String>(propAssetId);
    }
    map['display_mode'] = Variable<String>(displayMode);
    map['position_index'] = Variable<int>(positionIndex);
    return map;
  }

  ShelfItemsCompanion toCompanion(bool nullToAbsent) {
    return ShelfItemsCompanion(
      id: Value(id),
      shelfId: Value(shelfId),
      itemType: Value(itemType),
      bookId:
          bookId == null && nullToAbsent ? const Value.absent() : Value(bookId),
      propAssetId: propAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(propAssetId),
      displayMode: Value(displayMode),
      positionIndex: Value(positionIndex),
    );
  }

  factory ShelfItem.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShelfItem(
      id: serializer.fromJson<String>(json['id']),
      shelfId: serializer.fromJson<String>(json['shelfId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      bookId: serializer.fromJson<String?>(json['bookId']),
      propAssetId: serializer.fromJson<String?>(json['propAssetId']),
      displayMode: serializer.fromJson<String>(json['displayMode']),
      positionIndex: serializer.fromJson<int>(json['positionIndex']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'shelfId': serializer.toJson<String>(shelfId),
      'itemType': serializer.toJson<String>(itemType),
      'bookId': serializer.toJson<String?>(bookId),
      'propAssetId': serializer.toJson<String?>(propAssetId),
      'displayMode': serializer.toJson<String>(displayMode),
      'positionIndex': serializer.toJson<int>(positionIndex),
    };
  }

  ShelfItem copyWith(
          {String? id,
          String? shelfId,
          String? itemType,
          Value<String?> bookId = const Value.absent(),
          Value<String?> propAssetId = const Value.absent(),
          String? displayMode,
          int? positionIndex}) =>
      ShelfItem(
        id: id ?? this.id,
        shelfId: shelfId ?? this.shelfId,
        itemType: itemType ?? this.itemType,
        bookId: bookId.present ? bookId.value : this.bookId,
        propAssetId: propAssetId.present ? propAssetId.value : this.propAssetId,
        displayMode: displayMode ?? this.displayMode,
        positionIndex: positionIndex ?? this.positionIndex,
      );
  ShelfItem copyWithCompanion(ShelfItemsCompanion data) {
    return ShelfItem(
      id: data.id.present ? data.id.value : this.id,
      shelfId: data.shelfId.present ? data.shelfId.value : this.shelfId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      propAssetId:
          data.propAssetId.present ? data.propAssetId.value : this.propAssetId,
      displayMode:
          data.displayMode.present ? data.displayMode.value : this.displayMode,
      positionIndex: data.positionIndex.present
          ? data.positionIndex.value
          : this.positionIndex,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShelfItem(')
          ..write('id: $id, ')
          ..write('shelfId: $shelfId, ')
          ..write('itemType: $itemType, ')
          ..write('bookId: $bookId, ')
          ..write('propAssetId: $propAssetId, ')
          ..write('displayMode: $displayMode, ')
          ..write('positionIndex: $positionIndex')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, shelfId, itemType, bookId, propAssetId, displayMode, positionIndex);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShelfItem &&
          other.id == this.id &&
          other.shelfId == this.shelfId &&
          other.itemType == this.itemType &&
          other.bookId == this.bookId &&
          other.propAssetId == this.propAssetId &&
          other.displayMode == this.displayMode &&
          other.positionIndex == this.positionIndex);
}

class ShelfItemsCompanion extends UpdateCompanion<ShelfItem> {
  final Value<String> id;
  final Value<String> shelfId;
  final Value<String> itemType;
  final Value<String?> bookId;
  final Value<String?> propAssetId;
  final Value<String> displayMode;
  final Value<int> positionIndex;
  final Value<int> rowid;
  const ShelfItemsCompanion({
    this.id = const Value.absent(),
    this.shelfId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.bookId = const Value.absent(),
    this.propAssetId = const Value.absent(),
    this.displayMode = const Value.absent(),
    this.positionIndex = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShelfItemsCompanion.insert({
    required String id,
    required String shelfId,
    required String itemType,
    this.bookId = const Value.absent(),
    this.propAssetId = const Value.absent(),
    this.displayMode = const Value.absent(),
    required int positionIndex,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        shelfId = Value(shelfId),
        itemType = Value(itemType),
        positionIndex = Value(positionIndex);
  static Insertable<ShelfItem> custom({
    Expression<String>? id,
    Expression<String>? shelfId,
    Expression<String>? itemType,
    Expression<String>? bookId,
    Expression<String>? propAssetId,
    Expression<String>? displayMode,
    Expression<int>? positionIndex,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (shelfId != null) 'shelf_id': shelfId,
      if (itemType != null) 'item_type': itemType,
      if (bookId != null) 'book_id': bookId,
      if (propAssetId != null) 'prop_asset_id': propAssetId,
      if (displayMode != null) 'display_mode': displayMode,
      if (positionIndex != null) 'position_index': positionIndex,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShelfItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? shelfId,
      Value<String>? itemType,
      Value<String?>? bookId,
      Value<String?>? propAssetId,
      Value<String>? displayMode,
      Value<int>? positionIndex,
      Value<int>? rowid}) {
    return ShelfItemsCompanion(
      id: id ?? this.id,
      shelfId: shelfId ?? this.shelfId,
      itemType: itemType ?? this.itemType,
      bookId: bookId ?? this.bookId,
      propAssetId: propAssetId ?? this.propAssetId,
      displayMode: displayMode ?? this.displayMode,
      positionIndex: positionIndex ?? this.positionIndex,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (shelfId.present) {
      map['shelf_id'] = Variable<String>(shelfId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (propAssetId.present) {
      map['prop_asset_id'] = Variable<String>(propAssetId.value);
    }
    if (displayMode.present) {
      map['display_mode'] = Variable<String>(displayMode.value);
    }
    if (positionIndex.present) {
      map['position_index'] = Variable<int>(positionIndex.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShelfItemsCompanion(')
          ..write('id: $id, ')
          ..write('shelfId: $shelfId, ')
          ..write('itemType: $itemType, ')
          ..write('bookId: $bookId, ')
          ..write('propAssetId: $propAssetId, ')
          ..write('displayMode: $displayMode, ')
          ..write('positionIndex: $positionIndex, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReadingSessionsTable extends ReadingSessions
    with TableInfo<$ReadingSessionsTable, ReadingSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReadingSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES books (id) ON DELETE CASCADE'));
  static const VerificationMeta _startTimeMeta =
      const VerificationMeta('startTime');
  @override
  late final GeneratedColumn<int> startTime = GeneratedColumn<int>(
      'start_time', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startPageMeta =
      const VerificationMeta('startPage');
  @override
  late final GeneratedColumn<int> startPage = GeneratedColumn<int>(
      'start_page', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endPageMeta =
      const VerificationMeta('endPage');
  @override
  late final GeneratedColumn<int> endPage = GeneratedColumn<int>(
      'end_page', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, bookId, startTime, durationSeconds, startPage, endPage];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_sessions';
  @override
  VerificationContext validateIntegrity(Insertable<ReadingSession> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('start_time')) {
      context.handle(_startTimeMeta,
          startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta));
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('start_page')) {
      context.handle(_startPageMeta,
          startPage.isAcceptableOrUnknown(data['start_page']!, _startPageMeta));
    } else if (isInserting) {
      context.missing(_startPageMeta);
    }
    if (data.containsKey('end_page')) {
      context.handle(_endPageMeta,
          endPage.isAcceptableOrUnknown(data['end_page']!, _endPageMeta));
    } else if (isInserting) {
      context.missing(_endPageMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReadingSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingSession(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      startTime: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_time'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      startPage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}start_page'])!,
      endPage: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}end_page'])!,
    );
  }

  @override
  $ReadingSessionsTable createAlias(String alias) {
    return $ReadingSessionsTable(attachedDatabase, alias);
  }
}

class ReadingSession extends DataClass implements Insertable<ReadingSession> {
  final String id;
  final String bookId;
  final int startTime;
  final int durationSeconds;
  final int startPage;
  final int endPage;
  const ReadingSession(
      {required this.id,
      required this.bookId,
      required this.startTime,
      required this.durationSeconds,
      required this.startPage,
      required this.endPage});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['start_time'] = Variable<int>(startTime);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['start_page'] = Variable<int>(startPage);
    map['end_page'] = Variable<int>(endPage);
    return map;
  }

  ReadingSessionsCompanion toCompanion(bool nullToAbsent) {
    return ReadingSessionsCompanion(
      id: Value(id),
      bookId: Value(bookId),
      startTime: Value(startTime),
      durationSeconds: Value(durationSeconds),
      startPage: Value(startPage),
      endPage: Value(endPage),
    );
  }

  factory ReadingSession.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingSession(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      startTime: serializer.fromJson<int>(json['startTime']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      startPage: serializer.fromJson<int>(json['startPage']),
      endPage: serializer.fromJson<int>(json['endPage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'startTime': serializer.toJson<int>(startTime),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'startPage': serializer.toJson<int>(startPage),
      'endPage': serializer.toJson<int>(endPage),
    };
  }

  ReadingSession copyWith(
          {String? id,
          String? bookId,
          int? startTime,
          int? durationSeconds,
          int? startPage,
          int? endPage}) =>
      ReadingSession(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        startTime: startTime ?? this.startTime,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        startPage: startPage ?? this.startPage,
        endPage: endPage ?? this.endPage,
      );
  ReadingSession copyWithCompanion(ReadingSessionsCompanion data) {
    return ReadingSession(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      startPage: data.startPage.present ? data.startPage.value : this.startPage,
      endPage: data.endPage.present ? data.endPage.value : this.endPage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSession(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('startTime: $startTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, startTime, durationSeconds, startPage, endPage);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingSession &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.startTime == this.startTime &&
          other.durationSeconds == this.durationSeconds &&
          other.startPage == this.startPage &&
          other.endPage == this.endPage);
}

class ReadingSessionsCompanion extends UpdateCompanion<ReadingSession> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<int> startTime;
  final Value<int> durationSeconds;
  final Value<int> startPage;
  final Value<int> endPage;
  final Value<int> rowid;
  const ReadingSessionsCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.startPage = const Value.absent(),
    this.endPage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingSessionsCompanion.insert({
    required String id,
    required String bookId,
    required int startTime,
    required int durationSeconds,
    required int startPage,
    required int endPage,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bookId = Value(bookId),
        startTime = Value(startTime),
        durationSeconds = Value(durationSeconds),
        startPage = Value(startPage),
        endPage = Value(endPage);
  static Insertable<ReadingSession> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<int>? startTime,
    Expression<int>? durationSeconds,
    Expression<int>? startPage,
    Expression<int>? endPage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (startTime != null) 'start_time': startTime,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (startPage != null) 'start_page': startPage,
      if (endPage != null) 'end_page': endPage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingSessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? bookId,
      Value<int>? startTime,
      Value<int>? durationSeconds,
      Value<int>? startPage,
      Value<int>? endPage,
      Value<int>? rowid}) {
    return ReadingSessionsCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      startPage: startPage ?? this.startPage,
      endPage: endPage ?? this.endPage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<int>(startTime.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (startPage.present) {
      map['start_page'] = Variable<int>(startPage.value);
    }
    if (endPage.present) {
      map['end_page'] = Variable<int>(endPage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingSessionsCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('startTime: $startTime, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('startPage: $startPage, ')
          ..write('endPage: $endPage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BookNotesTable extends BookNotes
    with TableInfo<$BookNotesTable, BookNote> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BookNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  @override
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
      'book_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES books (id) ON DELETE CASCADE'));
  static const VerificationMeta _noteTypeMeta =
      const VerificationMeta('noteType');
  @override
  late final GeneratedColumn<String> noteType = GeneratedColumn<String>(
      'note_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _contentMeta =
      const VerificationMeta('content');
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
      'content', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _pageNumberMeta =
      const VerificationMeta('pageNumber');
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
      'page_number', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, bookId, noteType, content, pageNumber, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_notes';
  @override
  VerificationContext validateIntegrity(Insertable<BookNote> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(_bookIdMeta,
          bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta));
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('note_type')) {
      context.handle(_noteTypeMeta,
          noteType.isAcceptableOrUnknown(data['note_type']!, _noteTypeMeta));
    } else if (isInserting) {
      context.missing(_noteTypeMeta);
    }
    if (data.containsKey('content')) {
      context.handle(_contentMeta,
          content.isAcceptableOrUnknown(data['content']!, _contentMeta));
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
          _pageNumberMeta,
          pageNumber.isAcceptableOrUnknown(
              data['page_number']!, _pageNumberMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BookNote map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookNote(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      bookId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}book_id'])!,
      noteType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note_type'])!,
      content: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content'])!,
      pageNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}page_number']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $BookNotesTable createAlias(String alias) {
    return $BookNotesTable(attachedDatabase, alias);
  }
}

class BookNote extends DataClass implements Insertable<BookNote> {
  final String id;
  final String bookId;
  final String noteType;
  final String content;
  final int? pageNumber;
  final int createdAt;
  const BookNote(
      {required this.id,
      required this.bookId,
      required this.noteType,
      required this.content,
      this.pageNumber,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book_id'] = Variable<String>(bookId);
    map['note_type'] = Variable<String>(noteType);
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || pageNumber != null) {
      map['page_number'] = Variable<int>(pageNumber);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  BookNotesCompanion toCompanion(bool nullToAbsent) {
    return BookNotesCompanion(
      id: Value(id),
      bookId: Value(bookId),
      noteType: Value(noteType),
      content: Value(content),
      pageNumber: pageNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(pageNumber),
      createdAt: Value(createdAt),
    );
  }

  factory BookNote.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookNote(
      id: serializer.fromJson<String>(json['id']),
      bookId: serializer.fromJson<String>(json['bookId']),
      noteType: serializer.fromJson<String>(json['noteType']),
      content: serializer.fromJson<String>(json['content']),
      pageNumber: serializer.fromJson<int?>(json['pageNumber']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'bookId': serializer.toJson<String>(bookId),
      'noteType': serializer.toJson<String>(noteType),
      'content': serializer.toJson<String>(content),
      'pageNumber': serializer.toJson<int?>(pageNumber),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  BookNote copyWith(
          {String? id,
          String? bookId,
          String? noteType,
          String? content,
          Value<int?> pageNumber = const Value.absent(),
          int? createdAt}) =>
      BookNote(
        id: id ?? this.id,
        bookId: bookId ?? this.bookId,
        noteType: noteType ?? this.noteType,
        content: content ?? this.content,
        pageNumber: pageNumber.present ? pageNumber.value : this.pageNumber,
        createdAt: createdAt ?? this.createdAt,
      );
  BookNote copyWithCompanion(BookNotesCompanion data) {
    return BookNote(
      id: data.id.present ? data.id.value : this.id,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      noteType: data.noteType.present ? data.noteType.value : this.noteType,
      content: data.content.present ? data.content.value : this.content,
      pageNumber:
          data.pageNumber.present ? data.pageNumber.value : this.pageNumber,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookNote(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('noteType: $noteType, ')
          ..write('content: $content, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, bookId, noteType, content, pageNumber, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookNote &&
          other.id == this.id &&
          other.bookId == this.bookId &&
          other.noteType == this.noteType &&
          other.content == this.content &&
          other.pageNumber == this.pageNumber &&
          other.createdAt == this.createdAt);
}

class BookNotesCompanion extends UpdateCompanion<BookNote> {
  final Value<String> id;
  final Value<String> bookId;
  final Value<String> noteType;
  final Value<String> content;
  final Value<int?> pageNumber;
  final Value<int> createdAt;
  final Value<int> rowid;
  const BookNotesCompanion({
    this.id = const Value.absent(),
    this.bookId = const Value.absent(),
    this.noteType = const Value.absent(),
    this.content = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookNotesCompanion.insert({
    required String id,
    required String bookId,
    required String noteType,
    required String content,
    this.pageNumber = const Value.absent(),
    required int createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        bookId = Value(bookId),
        noteType = Value(noteType),
        content = Value(content),
        createdAt = Value(createdAt);
  static Insertable<BookNote> custom({
    Expression<String>? id,
    Expression<String>? bookId,
    Expression<String>? noteType,
    Expression<String>? content,
    Expression<int>? pageNumber,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bookId != null) 'book_id': bookId,
      if (noteType != null) 'note_type': noteType,
      if (content != null) 'content': content,
      if (pageNumber != null) 'page_number': pageNumber,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookNotesCompanion copyWith(
      {Value<String>? id,
      Value<String>? bookId,
      Value<String>? noteType,
      Value<String>? content,
      Value<int?>? pageNumber,
      Value<int>? createdAt,
      Value<int>? rowid}) {
    return BookNotesCompanion(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      noteType: noteType ?? this.noteType,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (noteType.present) {
      map['note_type'] = Variable<String>(noteType.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookNotesCompanion(')
          ..write('id: $id, ')
          ..write('bookId: $bookId, ')
          ..write('noteType: $noteType, ')
          ..write('content: $content, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BooksTable books = $BooksTable(this);
  late final $ShelvesTable shelves = $ShelvesTable(this);
  late final $ShelfItemsTable shelfItems = $ShelfItemsTable(this);
  late final $ReadingSessionsTable readingSessions =
      $ReadingSessionsTable(this);
  late final $BookNotesTable bookNotes = $BookNotesTable(this);
  late final Index booksIsbn13Idx = Index(
      'books_isbn13_idx', 'CREATE INDEX books_isbn13_idx ON books (isbn13)');
  late final BookDao bookDao = BookDao(this as AppDatabase);
  late final ShelfDao shelfDao = ShelfDao(this as AppDatabase);
  late final SessionDao sessionDao = SessionDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [books, shelves, shelfItems, readingSessions, bookNotes, booksIsbn13Idx];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('shelves',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('shelf_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('books',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('shelf_items', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('books',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('reading_sessions', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('books',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('book_notes', kind: UpdateKind.delete),
            ],
          ),
        ],
      );
}

typedef $$BooksTableCreateCompanionBuilder = BooksCompanion Function({
  required String id,
  Value<String?> isbn13,
  required String title,
  Value<String?> subtitle,
  required String authors,
  Value<int> pageCount,
  Value<String> format,
  required String status,
  Value<String?> seriesName,
  Value<double?> seriesIndex,
  Value<String?> coverPath,
  Value<String?> customSpinePath,
  required int spineColorHex,
  required int spineTextHex,
  Value<double?> rating,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$BooksTableUpdateCompanionBuilder = BooksCompanion Function({
  Value<String> id,
  Value<String?> isbn13,
  Value<String> title,
  Value<String?> subtitle,
  Value<String> authors,
  Value<int> pageCount,
  Value<String> format,
  Value<String> status,
  Value<String?> seriesName,
  Value<double?> seriesIndex,
  Value<String?> coverPath,
  Value<String?> customSpinePath,
  Value<int> spineColorHex,
  Value<int> spineTextHex,
  Value<double?> rating,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$BooksTableReferences
    extends BaseReferences<_$AppDatabase, $BooksTable, Book> {
  $$BooksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShelfItemsTable, List<ShelfItem>>
      _shelfItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.shelfItems,
          aliasName: $_aliasNameGenerator(db.books.id, db.shelfItems.bookId));

  $$ShelfItemsTableProcessedTableManager get shelfItemsRefs {
    final manager = $$ShelfItemsTableTableManager($_db, $_db.shelfItems)
        .filter((f) => f.bookId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_shelfItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReadingSessionsTable, List<ReadingSession>>
      _readingSessionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.readingSessions,
              aliasName:
                  $_aliasNameGenerator(db.books.id, db.readingSessions.bookId));

  $$ReadingSessionsTableProcessedTableManager get readingSessionsRefs {
    final manager =
        $$ReadingSessionsTableTableManager($_db, $_db.readingSessions)
            .filter((f) => f.bookId.id($_item.id));

    final cache =
        $_typedResult.readTableOrNull(_readingSessionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$BookNotesTable, List<BookNote>>
      _bookNotesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.bookNotes,
          aliasName: $_aliasNameGenerator(db.books.id, db.bookNotes.bookId));

  $$BookNotesTableProcessedTableManager get bookNotesRefs {
    final manager = $$BookNotesTableTableManager($_db, $_db.bookNotes)
        .filter((f) => f.bookId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_bookNotesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$BooksTableFilterComposer extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get isbn13 => $composableBuilder(
      column: $table.isbn13, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subtitle => $composableBuilder(
      column: $table.subtitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get authors => $composableBuilder(
      column: $table.authors, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageCount => $composableBuilder(
      column: $table.pageCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesName => $composableBuilder(
      column: $table.seriesName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get seriesIndex => $composableBuilder(
      column: $table.seriesIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get customSpinePath => $composableBuilder(
      column: $table.customSpinePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get spineColorHex => $composableBuilder(
      column: $table.spineColorHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get spineTextHex => $composableBuilder(
      column: $table.spineTextHex, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> shelfItemsRefs(
      Expression<bool> Function($$ShelfItemsTableFilterComposer f) f) {
    final $$ShelfItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shelfItems,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShelfItemsTableFilterComposer(
              $db: $db,
              $table: $db.shelfItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> readingSessionsRefs(
      Expression<bool> Function($$ReadingSessionsTableFilterComposer f) f) {
    final $$ReadingSessionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.readingSessions,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingSessionsTableFilterComposer(
              $db: $db,
              $table: $db.readingSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> bookNotesRefs(
      Expression<bool> Function($$BookNotesTableFilterComposer f) f) {
    final $$BookNotesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookNotes,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookNotesTableFilterComposer(
              $db: $db,
              $table: $db.bookNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BooksTableOrderingComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get isbn13 => $composableBuilder(
      column: $table.isbn13, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subtitle => $composableBuilder(
      column: $table.subtitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get authors => $composableBuilder(
      column: $table.authors, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageCount => $composableBuilder(
      column: $table.pageCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesName => $composableBuilder(
      column: $table.seriesName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get seriesIndex => $composableBuilder(
      column: $table.seriesIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get coverPath => $composableBuilder(
      column: $table.coverPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get customSpinePath => $composableBuilder(
      column: $table.customSpinePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spineColorHex => $composableBuilder(
      column: $table.spineColorHex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get spineTextHex => $composableBuilder(
      column: $table.spineTextHex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BooksTableAnnotationComposer
    extends Composer<_$AppDatabase, $BooksTable> {
  $$BooksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get isbn13 =>
      $composableBuilder(column: $table.isbn13, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subtitle =>
      $composableBuilder(column: $table.subtitle, builder: (column) => column);

  GeneratedColumn<String> get authors =>
      $composableBuilder(column: $table.authors, builder: (column) => column);

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get seriesName => $composableBuilder(
      column: $table.seriesName, builder: (column) => column);

  GeneratedColumn<double> get seriesIndex => $composableBuilder(
      column: $table.seriesIndex, builder: (column) => column);

  GeneratedColumn<String> get coverPath =>
      $composableBuilder(column: $table.coverPath, builder: (column) => column);

  GeneratedColumn<String> get customSpinePath => $composableBuilder(
      column: $table.customSpinePath, builder: (column) => column);

  GeneratedColumn<int> get spineColorHex => $composableBuilder(
      column: $table.spineColorHex, builder: (column) => column);

  GeneratedColumn<int> get spineTextHex => $composableBuilder(
      column: $table.spineTextHex, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> shelfItemsRefs<T extends Object>(
      Expression<T> Function($$ShelfItemsTableAnnotationComposer a) f) {
    final $$ShelfItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shelfItems,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShelfItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.shelfItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> readingSessionsRefs<T extends Object>(
      Expression<T> Function($$ReadingSessionsTableAnnotationComposer a) f) {
    final $$ReadingSessionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.readingSessions,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReadingSessionsTableAnnotationComposer(
              $db: $db,
              $table: $db.readingSessions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> bookNotesRefs<T extends Object>(
      Expression<T> Function($$BookNotesTableAnnotationComposer a) f) {
    final $$BookNotesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.bookNotes,
        getReferencedColumn: (t) => t.bookId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BookNotesTableAnnotationComposer(
              $db: $db,
              $table: $db.bookNotes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$BooksTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BooksTable,
    Book,
    $$BooksTableFilterComposer,
    $$BooksTableOrderingComposer,
    $$BooksTableAnnotationComposer,
    $$BooksTableCreateCompanionBuilder,
    $$BooksTableUpdateCompanionBuilder,
    (Book, $$BooksTableReferences),
    Book,
    PrefetchHooks Function(
        {bool shelfItemsRefs, bool readingSessionsRefs, bool bookNotesRefs})> {
  $$BooksTableTableManager(_$AppDatabase db, $BooksTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BooksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BooksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BooksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String?> isbn13 = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> subtitle = const Value.absent(),
            Value<String> authors = const Value.absent(),
            Value<int> pageCount = const Value.absent(),
            Value<String> format = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> seriesName = const Value.absent(),
            Value<double?> seriesIndex = const Value.absent(),
            Value<String?> coverPath = const Value.absent(),
            Value<String?> customSpinePath = const Value.absent(),
            Value<int> spineColorHex = const Value.absent(),
            Value<int> spineTextHex = const Value.absent(),
            Value<double?> rating = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BooksCompanion(
            id: id,
            isbn13: isbn13,
            title: title,
            subtitle: subtitle,
            authors: authors,
            pageCount: pageCount,
            format: format,
            status: status,
            seriesName: seriesName,
            seriesIndex: seriesIndex,
            coverPath: coverPath,
            customSpinePath: customSpinePath,
            spineColorHex: spineColorHex,
            spineTextHex: spineTextHex,
            rating: rating,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            Value<String?> isbn13 = const Value.absent(),
            required String title,
            Value<String?> subtitle = const Value.absent(),
            required String authors,
            Value<int> pageCount = const Value.absent(),
            Value<String> format = const Value.absent(),
            required String status,
            Value<String?> seriesName = const Value.absent(),
            Value<double?> seriesIndex = const Value.absent(),
            Value<String?> coverPath = const Value.absent(),
            Value<String?> customSpinePath = const Value.absent(),
            required int spineColorHex,
            required int spineTextHex,
            Value<double?> rating = const Value.absent(),
            required int createdAt,
            required int updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BooksCompanion.insert(
            id: id,
            isbn13: isbn13,
            title: title,
            subtitle: subtitle,
            authors: authors,
            pageCount: pageCount,
            format: format,
            status: status,
            seriesName: seriesName,
            seriesIndex: seriesIndex,
            coverPath: coverPath,
            customSpinePath: customSpinePath,
            spineColorHex: spineColorHex,
            spineTextHex: spineTextHex,
            rating: rating,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$BooksTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {shelfItemsRefs = false,
              readingSessionsRefs = false,
              bookNotesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (shelfItemsRefs) db.shelfItems,
                if (readingSessionsRefs) db.readingSessions,
                if (bookNotesRefs) db.bookNotes
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shelfItemsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$BooksTableReferences._shelfItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BooksTableReferences(db, table, p0)
                                .shelfItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.bookId == item.id),
                        typedResults: items),
                  if (readingSessionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$BooksTableReferences
                            ._readingSessionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BooksTableReferences(db, table, p0)
                                .readingSessionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.bookId == item.id),
                        typedResults: items),
                  if (bookNotesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$BooksTableReferences._bookNotesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$BooksTableReferences(db, table, p0).bookNotesRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.bookId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$BooksTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BooksTable,
    Book,
    $$BooksTableFilterComposer,
    $$BooksTableOrderingComposer,
    $$BooksTableAnnotationComposer,
    $$BooksTableCreateCompanionBuilder,
    $$BooksTableUpdateCompanionBuilder,
    (Book, $$BooksTableReferences),
    Book,
    PrefetchHooks Function(
        {bool shelfItemsRefs, bool readingSessionsRefs, bool bookNotesRefs})>;
typedef $$ShelvesTableCreateCompanionBuilder = ShelvesCompanion Function({
  required String id,
  required String name,
  Value<String> woodThemeId,
  Value<String> wallThemeId,
  required int sortOrder,
  Value<int> rowid,
});
typedef $$ShelvesTableUpdateCompanionBuilder = ShelvesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> woodThemeId,
  Value<String> wallThemeId,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$ShelvesTableReferences
    extends BaseReferences<_$AppDatabase, $ShelvesTable, Shelf> {
  $$ShelvesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ShelfItemsTable, List<ShelfItem>>
      _shelfItemsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.shelfItems,
              aliasName:
                  $_aliasNameGenerator(db.shelves.id, db.shelfItems.shelfId));

  $$ShelfItemsTableProcessedTableManager get shelfItemsRefs {
    final manager = $$ShelfItemsTableTableManager($_db, $_db.shelfItems)
        .filter((f) => f.shelfId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_shelfItemsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ShelvesTableFilterComposer
    extends Composer<_$AppDatabase, $ShelvesTable> {
  $$ShelvesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get woodThemeId => $composableBuilder(
      column: $table.woodThemeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get wallThemeId => $composableBuilder(
      column: $table.wallThemeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  Expression<bool> shelfItemsRefs(
      Expression<bool> Function($$ShelfItemsTableFilterComposer f) f) {
    final $$ShelfItemsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shelfItems,
        getReferencedColumn: (t) => t.shelfId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShelfItemsTableFilterComposer(
              $db: $db,
              $table: $db.shelfItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ShelvesTableOrderingComposer
    extends Composer<_$AppDatabase, $ShelvesTable> {
  $$ShelvesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get woodThemeId => $composableBuilder(
      column: $table.woodThemeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get wallThemeId => $composableBuilder(
      column: $table.wallThemeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));
}

class $$ShelvesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShelvesTable> {
  $$ShelvesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get woodThemeId => $composableBuilder(
      column: $table.woodThemeId, builder: (column) => column);

  GeneratedColumn<String> get wallThemeId => $composableBuilder(
      column: $table.wallThemeId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> shelfItemsRefs<T extends Object>(
      Expression<T> Function($$ShelfItemsTableAnnotationComposer a) f) {
    final $$ShelfItemsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.shelfItems,
        getReferencedColumn: (t) => t.shelfId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShelfItemsTableAnnotationComposer(
              $db: $db,
              $table: $db.shelfItems,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ShelvesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShelvesTable,
    Shelf,
    $$ShelvesTableFilterComposer,
    $$ShelvesTableOrderingComposer,
    $$ShelvesTableAnnotationComposer,
    $$ShelvesTableCreateCompanionBuilder,
    $$ShelvesTableUpdateCompanionBuilder,
    (Shelf, $$ShelvesTableReferences),
    Shelf,
    PrefetchHooks Function({bool shelfItemsRefs})> {
  $$ShelvesTableTableManager(_$AppDatabase db, $ShelvesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShelvesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShelvesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShelvesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> woodThemeId = const Value.absent(),
            Value<String> wallThemeId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShelvesCompanion(
            id: id,
            name: name,
            woodThemeId: woodThemeId,
            wallThemeId: wallThemeId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String> woodThemeId = const Value.absent(),
            Value<String> wallThemeId = const Value.absent(),
            required int sortOrder,
            Value<int> rowid = const Value.absent(),
          }) =>
              ShelvesCompanion.insert(
            id: id,
            name: name,
            woodThemeId: woodThemeId,
            wallThemeId: wallThemeId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ShelvesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({shelfItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (shelfItemsRefs) db.shelfItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (shelfItemsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$ShelvesTableReferences._shelfItemsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ShelvesTableReferences(db, table, p0)
                                .shelfItemsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.shelfId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ShelvesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShelvesTable,
    Shelf,
    $$ShelvesTableFilterComposer,
    $$ShelvesTableOrderingComposer,
    $$ShelvesTableAnnotationComposer,
    $$ShelvesTableCreateCompanionBuilder,
    $$ShelvesTableUpdateCompanionBuilder,
    (Shelf, $$ShelvesTableReferences),
    Shelf,
    PrefetchHooks Function({bool shelfItemsRefs})>;
typedef $$ShelfItemsTableCreateCompanionBuilder = ShelfItemsCompanion Function({
  required String id,
  required String shelfId,
  required String itemType,
  Value<String?> bookId,
  Value<String?> propAssetId,
  Value<String> displayMode,
  required int positionIndex,
  Value<int> rowid,
});
typedef $$ShelfItemsTableUpdateCompanionBuilder = ShelfItemsCompanion Function({
  Value<String> id,
  Value<String> shelfId,
  Value<String> itemType,
  Value<String?> bookId,
  Value<String?> propAssetId,
  Value<String> displayMode,
  Value<int> positionIndex,
  Value<int> rowid,
});

final class $$ShelfItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ShelfItemsTable, ShelfItem> {
  $$ShelfItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ShelvesTable _shelfIdTable(_$AppDatabase db) => db.shelves
      .createAlias($_aliasNameGenerator(db.shelfItems.shelfId, db.shelves.id));

  $$ShelvesTableProcessedTableManager get shelfId {
    final manager = $$ShelvesTableTableManager($_db, $_db.shelves)
        .filter((f) => f.id($_item.shelfId));
    final item = $_typedResult.readTableOrNull(_shelfIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $BooksTable _bookIdTable(_$AppDatabase db) => db.books
      .createAlias($_aliasNameGenerator(db.shelfItems.bookId, db.books.id));

  $$BooksTableProcessedTableManager? get bookId {
    if ($_item.bookId == null) return null;
    final manager = $$BooksTableTableManager($_db, $_db.books)
        .filter((f) => f.id($_item.bookId!));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ShelfItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShelfItemsTable> {
  $$ShelfItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get propAssetId => $composableBuilder(
      column: $table.propAssetId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get displayMode => $composableBuilder(
      column: $table.displayMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get positionIndex => $composableBuilder(
      column: $table.positionIndex, builder: (column) => ColumnFilters(column));

  $$ShelvesTableFilterComposer get shelfId {
    final $$ShelvesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shelfId,
        referencedTable: $db.shelves,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShelvesTableFilterComposer(
              $db: $db,
              $table: $db.shelves,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableFilterComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShelfItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShelfItemsTable> {
  $$ShelfItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemType => $composableBuilder(
      column: $table.itemType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get propAssetId => $composableBuilder(
      column: $table.propAssetId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get displayMode => $composableBuilder(
      column: $table.displayMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get positionIndex => $composableBuilder(
      column: $table.positionIndex,
      builder: (column) => ColumnOrderings(column));

  $$ShelvesTableOrderingComposer get shelfId {
    final $$ShelvesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shelfId,
        referencedTable: $db.shelves,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShelvesTableOrderingComposer(
              $db: $db,
              $table: $db.shelves,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableOrderingComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShelfItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShelfItemsTable> {
  $$ShelfItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get propAssetId => $composableBuilder(
      column: $table.propAssetId, builder: (column) => column);

  GeneratedColumn<String> get displayMode => $composableBuilder(
      column: $table.displayMode, builder: (column) => column);

  GeneratedColumn<int> get positionIndex => $composableBuilder(
      column: $table.positionIndex, builder: (column) => column);

  $$ShelvesTableAnnotationComposer get shelfId {
    final $$ShelvesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.shelfId,
        referencedTable: $db.shelves,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ShelvesTableAnnotationComposer(
              $db: $db,
              $table: $db.shelves,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableAnnotationComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ShelfItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ShelfItemsTable,
    ShelfItem,
    $$ShelfItemsTableFilterComposer,
    $$ShelfItemsTableOrderingComposer,
    $$ShelfItemsTableAnnotationComposer,
    $$ShelfItemsTableCreateCompanionBuilder,
    $$ShelfItemsTableUpdateCompanionBuilder,
    (ShelfItem, $$ShelfItemsTableReferences),
    ShelfItem,
    PrefetchHooks Function({bool shelfId, bool bookId})> {
  $$ShelfItemsTableTableManager(_$AppDatabase db, $ShelfItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShelfItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShelfItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShelfItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> shelfId = const Value.absent(),
            Value<String> itemType = const Value.absent(),
            Value<String?> bookId = const Value.absent(),
            Value<String?> propAssetId = const Value.absent(),
            Value<String> displayMode = const Value.absent(),
            Value<int> positionIndex = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ShelfItemsCompanion(
            id: id,
            shelfId: shelfId,
            itemType: itemType,
            bookId: bookId,
            propAssetId: propAssetId,
            displayMode: displayMode,
            positionIndex: positionIndex,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String shelfId,
            required String itemType,
            Value<String?> bookId = const Value.absent(),
            Value<String?> propAssetId = const Value.absent(),
            Value<String> displayMode = const Value.absent(),
            required int positionIndex,
            Value<int> rowid = const Value.absent(),
          }) =>
              ShelfItemsCompanion.insert(
            id: id,
            shelfId: shelfId,
            itemType: itemType,
            bookId: bookId,
            propAssetId: propAssetId,
            displayMode: displayMode,
            positionIndex: positionIndex,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ShelfItemsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({shelfId = false, bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (shelfId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.shelfId,
                    referencedTable:
                        $$ShelfItemsTableReferences._shelfIdTable(db),
                    referencedColumn:
                        $$ShelfItemsTableReferences._shelfIdTable(db).id,
                  ) as T;
                }
                if (bookId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.bookId,
                    referencedTable:
                        $$ShelfItemsTableReferences._bookIdTable(db),
                    referencedColumn:
                        $$ShelfItemsTableReferences._bookIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ShelfItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ShelfItemsTable,
    ShelfItem,
    $$ShelfItemsTableFilterComposer,
    $$ShelfItemsTableOrderingComposer,
    $$ShelfItemsTableAnnotationComposer,
    $$ShelfItemsTableCreateCompanionBuilder,
    $$ShelfItemsTableUpdateCompanionBuilder,
    (ShelfItem, $$ShelfItemsTableReferences),
    ShelfItem,
    PrefetchHooks Function({bool shelfId, bool bookId})>;
typedef $$ReadingSessionsTableCreateCompanionBuilder = ReadingSessionsCompanion
    Function({
  required String id,
  required String bookId,
  required int startTime,
  required int durationSeconds,
  required int startPage,
  required int endPage,
  Value<int> rowid,
});
typedef $$ReadingSessionsTableUpdateCompanionBuilder = ReadingSessionsCompanion
    Function({
  Value<String> id,
  Value<String> bookId,
  Value<int> startTime,
  Value<int> durationSeconds,
  Value<int> startPage,
  Value<int> endPage,
  Value<int> rowid,
});

final class $$ReadingSessionsTableReferences extends BaseReferences<
    _$AppDatabase, $ReadingSessionsTable, ReadingSession> {
  $$ReadingSessionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) => db.books.createAlias(
      $_aliasNameGenerator(db.readingSessions.bookId, db.books.id));

  $$BooksTableProcessedTableManager get bookId {
    final manager = $$BooksTableTableManager($_db, $_db.books)
        .filter((f) => f.id($_item.bookId));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReadingSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startPage => $composableBuilder(
      column: $table.startPage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endPage => $composableBuilder(
      column: $table.endPage, builder: (column) => ColumnFilters(column));

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableFilterComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTime => $composableBuilder(
      column: $table.startTime, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startPage => $composableBuilder(
      column: $table.startPage, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endPage => $composableBuilder(
      column: $table.endPage, builder: (column) => ColumnOrderings(column));

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableOrderingComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReadingSessionsTable> {
  $$ReadingSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get startPage =>
      $composableBuilder(column: $table.startPage, builder: (column) => column);

  GeneratedColumn<int> get endPage =>
      $composableBuilder(column: $table.endPage, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableAnnotationComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReadingSessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReadingSessionsTable,
    ReadingSession,
    $$ReadingSessionsTableFilterComposer,
    $$ReadingSessionsTableOrderingComposer,
    $$ReadingSessionsTableAnnotationComposer,
    $$ReadingSessionsTableCreateCompanionBuilder,
    $$ReadingSessionsTableUpdateCompanionBuilder,
    (ReadingSession, $$ReadingSessionsTableReferences),
    ReadingSession,
    PrefetchHooks Function({bool bookId})> {
  $$ReadingSessionsTableTableManager(
      _$AppDatabase db, $ReadingSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReadingSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReadingSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReadingSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<int> startTime = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> startPage = const Value.absent(),
            Value<int> endPage = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadingSessionsCompanion(
            id: id,
            bookId: bookId,
            startTime: startTime,
            durationSeconds: durationSeconds,
            startPage: startPage,
            endPage: endPage,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bookId,
            required int startTime,
            required int durationSeconds,
            required int startPage,
            required int endPage,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReadingSessionsCompanion.insert(
            id: id,
            bookId: bookId,
            startTime: startTime,
            durationSeconds: durationSeconds,
            startPage: startPage,
            endPage: endPage,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReadingSessionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (bookId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.bookId,
                    referencedTable:
                        $$ReadingSessionsTableReferences._bookIdTable(db),
                    referencedColumn:
                        $$ReadingSessionsTableReferences._bookIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReadingSessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReadingSessionsTable,
    ReadingSession,
    $$ReadingSessionsTableFilterComposer,
    $$ReadingSessionsTableOrderingComposer,
    $$ReadingSessionsTableAnnotationComposer,
    $$ReadingSessionsTableCreateCompanionBuilder,
    $$ReadingSessionsTableUpdateCompanionBuilder,
    (ReadingSession, $$ReadingSessionsTableReferences),
    ReadingSession,
    PrefetchHooks Function({bool bookId})>;
typedef $$BookNotesTableCreateCompanionBuilder = BookNotesCompanion Function({
  required String id,
  required String bookId,
  required String noteType,
  required String content,
  Value<int?> pageNumber,
  required int createdAt,
  Value<int> rowid,
});
typedef $$BookNotesTableUpdateCompanionBuilder = BookNotesCompanion Function({
  Value<String> id,
  Value<String> bookId,
  Value<String> noteType,
  Value<String> content,
  Value<int?> pageNumber,
  Value<int> createdAt,
  Value<int> rowid,
});

final class $$BookNotesTableReferences
    extends BaseReferences<_$AppDatabase, $BookNotesTable, BookNote> {
  $$BookNotesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BooksTable _bookIdTable(_$AppDatabase db) => db.books
      .createAlias($_aliasNameGenerator(db.bookNotes.bookId, db.books.id));

  $$BooksTableProcessedTableManager get bookId {
    final manager = $$BooksTableTableManager($_db, $_db.books)
        .filter((f) => f.id($_item.bookId));
    final item = $_typedResult.readTableOrNull(_bookIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$BookNotesTableFilterComposer
    extends Composer<_$AppDatabase, $BookNotesTable> {
  $$BookNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get noteType => $composableBuilder(
      column: $table.noteType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get pageNumber => $composableBuilder(
      column: $table.pageNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$BooksTableFilterComposer get bookId {
    final $$BooksTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableFilterComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $BookNotesTable> {
  $$BookNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get noteType => $composableBuilder(
      column: $table.noteType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get content => $composableBuilder(
      column: $table.content, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get pageNumber => $composableBuilder(
      column: $table.pageNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$BooksTableOrderingComposer get bookId {
    final $$BooksTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableOrderingComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BookNotesTable> {
  $$BookNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get noteType =>
      $composableBuilder(column: $table.noteType, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
      column: $table.pageNumber, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BooksTableAnnotationComposer get bookId {
    final $$BooksTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.bookId,
        referencedTable: $db.books,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$BooksTableAnnotationComposer(
              $db: $db,
              $table: $db.books,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$BookNotesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BookNotesTable,
    BookNote,
    $$BookNotesTableFilterComposer,
    $$BookNotesTableOrderingComposer,
    $$BookNotesTableAnnotationComposer,
    $$BookNotesTableCreateCompanionBuilder,
    $$BookNotesTableUpdateCompanionBuilder,
    (BookNote, $$BookNotesTableReferences),
    BookNote,
    PrefetchHooks Function({bool bookId})> {
  $$BookNotesTableTableManager(_$AppDatabase db, $BookNotesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BookNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BookNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BookNotesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> bookId = const Value.absent(),
            Value<String> noteType = const Value.absent(),
            Value<String> content = const Value.absent(),
            Value<int?> pageNumber = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BookNotesCompanion(
            id: id,
            bookId: bookId,
            noteType: noteType,
            content: content,
            pageNumber: pageNumber,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String bookId,
            required String noteType,
            required String content,
            Value<int?> pageNumber = const Value.absent(),
            required int createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BookNotesCompanion.insert(
            id: id,
            bookId: bookId,
            noteType: noteType,
            content: content,
            pageNumber: pageNumber,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$BookNotesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({bookId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (bookId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.bookId,
                    referencedTable:
                        $$BookNotesTableReferences._bookIdTable(db),
                    referencedColumn:
                        $$BookNotesTableReferences._bookIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$BookNotesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BookNotesTable,
    BookNote,
    $$BookNotesTableFilterComposer,
    $$BookNotesTableOrderingComposer,
    $$BookNotesTableAnnotationComposer,
    $$BookNotesTableCreateCompanionBuilder,
    $$BookNotesTableUpdateCompanionBuilder,
    (BookNote, $$BookNotesTableReferences),
    BookNote,
    PrefetchHooks Function({bool bookId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BooksTableTableManager get books =>
      $$BooksTableTableManager(_db, _db.books);
  $$ShelvesTableTableManager get shelves =>
      $$ShelvesTableTableManager(_db, _db.shelves);
  $$ShelfItemsTableTableManager get shelfItems =>
      $$ShelfItemsTableTableManager(_db, _db.shelfItems);
  $$ReadingSessionsTableTableManager get readingSessions =>
      $$ReadingSessionsTableTableManager(_db, _db.readingSessions);
  $$BookNotesTableTableManager get bookNotes =>
      $$BookNotesTableTableManager(_db, _db.bookNotes);
}
