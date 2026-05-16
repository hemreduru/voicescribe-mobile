import 'package:flutter/material.dart';

import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';

class AppConstrainedBody extends StatelessWidget {
  const AppConstrainedBody({
    required this.child,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final resolvedPadding = padding.resolve(textDirection);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = AppLayout.horizontalPadding(
          constraints.maxWidth,
        );
        final maxWidth = AppLayout.maxModalWidth(constraints.maxWidth);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  resolvedPadding.left,
                  resolvedPadding.top,
                  resolvedPadding.right,
                  resolvedPadding.bottom,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppPageListView extends StatelessWidget {
  const AppPageListView({
    required this.children,
    super.key,
    this.padding = EdgeInsets.zero,
    this.controller,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    final resolvedPadding = padding.resolve(textDirection);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = AppLayout.horizontalPadding(
          constraints.maxWidth,
        );
        final maxWidth = AppLayout.maxModalWidth(constraints.maxWidth);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ListView(
                controller: controller,
                padding: EdgeInsets.fromLTRB(
                  resolvedPadding.left,
                  AppLayout.pageTopInset + resolvedPadding.top,
                  resolvedPadding.right,
                  AppLayout.pageBottomInset + resolvedPadding.bottom,
                ),
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}

class AppModalListView extends StatelessWidget {
  const AppModalListView({
    required this.children,
    super.key,
    this.controller,
    this.topPadding = 0,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = AppLayout.horizontalPadding(
          constraints.maxWidth,
        );
        final maxWidth = AppLayout.maxReadableWidth(constraints.maxWidth);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topPadding,
                horizontalPadding,
                AppSpacing.xl,
              ),
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class AppModalBody extends StatelessWidget {
  const AppModalBody({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = AppLayout.horizontalPadding(
          constraints.maxWidth,
        );
        final maxWidth = AppLayout.maxReadableWidth(constraints.maxWidth);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                AppSpacing.xl,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
