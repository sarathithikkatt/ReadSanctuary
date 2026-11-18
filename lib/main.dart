import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/utils/image_storage_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ImageStorageHelper().getMediaDirectory();
  } catch (_) {}
  runApp(
    const ProviderScope(
      child: ReadSanctuaryApp(),
    ),
  );
}
