import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:life_replay/core/theme/context_theme.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool centerTitle;
  final bool autoLeading;

  const AppScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions = const [],
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.centerTitle = false,
    this.autoLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: backgroundColor ?? context.appColors.background,
      appBar: title == null
      && titleWidget == null
          ? null
          : AppBar(
              title: titleWidget ?? Text(title!),
              centerTitle: centerTitle,
              automaticallyImplyLeading: false,
              leading: autoLeading && canPop
                  ? IconButton(
                      icon: const Icon(Iconsax.arrow_left_2),
                      onPressed: () => Navigator.of(context).maybePop(),
                    )
                  : null,
              actions: actions,
            ),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
