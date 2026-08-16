import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const AppScaffold({
    super.key,
    required this.body,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.appBar,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorScheme.of(context);
    final bg = backgroundColor ?? colors.background;

    Widget content = Padding(
      padding: padding,
      child: body,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: bottomNavigationBar != null ? 20 : 60,
        ),
        child: Padding(
          padding: padding,
          child: body,
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: appBar,
      body: SafeArea(
        child: scrollable ? content : Padding(padding: padding, child: body),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
