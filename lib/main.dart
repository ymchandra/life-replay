import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_replay/app.dart';
import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/providers/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E1A16),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final db = DatabaseHelper.instance;
  await db.database;

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const MyApp(),
    ),
  );
}
