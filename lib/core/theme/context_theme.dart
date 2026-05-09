import 'package:flutter/material.dart';

extension ContextThemeX on BuildContext {
  ColorScheme get appColors => Theme.of(this).colorScheme;
  TextTheme get appText => Theme.of(this).textTheme;
}
