import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// When a user taps "Replay this Chapter" from the Insights → Chapters tab,
/// this provider is set with the chapter's date range so the Replay screen
/// can pre-load it without any router changes.
final chapterReplayProvider = StateProvider<DateTimeRange?>((ref) => null);

