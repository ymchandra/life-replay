import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_replay/app.dart';
import 'package:life_replay/core/database/database_helper.dart';
import 'package:life_replay/core/providers/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFFF5F4FF),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final db = DatabaseHelper.instance;
  await db.database;
  await db.seedSampleDataIfEmpty();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
      ],
      child: const MyApp(),
    ),
  );
}
