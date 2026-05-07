import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_replay/core/database/database_helper.dart';

final databaseProvider = Provider<DatabaseHelper>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main.dart');
});
