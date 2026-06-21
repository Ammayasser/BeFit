// lib/core/widgets/content_wrapper.dart

import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ContentWrapper extends StatelessWidget {
  final Widget child;
  final bool addHorizontalPadding;

  const ContentWrapper({
    super.key,
    required this.child,
    this.addHorizontalPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = Responsive.contentMaxWidth(context);
    final hPad = addHorizontalPadding
        ? Responsive.horizontalPadding(context)
        : 0.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: child,
        ),
      ),
    );
  }
}
