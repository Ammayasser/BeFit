import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 24 * s),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _SquareAvatar(s: s),
            SizedBox(width: 12 * s),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * s,
                vertical: 12 * s,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4 * s),
                  topRight: Radius.circular(20 * s),
                  bottomLeft: Radius.circular(20 * s),
                  bottomRight: Radius.circular(20 * s),
                ),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PulseDot(index: 0, s: s),
                  SizedBox(width: 6 * s),
                  _PulseDot(index: 1, s: s),
                  SizedBox(width: 6 * s),
                  _PulseDot(index: 2, s: s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareAvatar extends StatelessWidget {
  final double s;
  const _SquareAvatar({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40 * s,
      height: 40 * s,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10 * s),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 20 * s,
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  final int index;
  final double s;
  const _PulseDot({required this.index, required this.s});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    Future.delayed(Duration(milliseconds: widget.index * 200), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          width: 6 * widget.s,
          height: 6 * widget.s,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2 + (0.8 * _ctrl.value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
