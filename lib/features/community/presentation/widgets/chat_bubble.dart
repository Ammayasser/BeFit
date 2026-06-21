import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../../domain/models/chat_message.dart';

import 'workout_plan_card.dart';
import 'nutrition_plan_card.dart';
import 'progress_summary_card.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: EdgeInsets.only(bottom: 24 * s),
      child: Semantics(
        label: isUser ? 'Your message' : 'AI Assistant message',
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser) _ModernAIAvatar(s: s),
                if (!isUser) SizedBox(width: 12 * s),
                Flexible(
                  child: _buildMessageContent(context, s, isUser),
                ),
                if (isUser) SizedBox(width: 12 * s),
                if (isUser) _ModernUserAvatar(s: s),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(
                top: 8 * s,
                left: isUser ? 0 : 52 * s,
                right: isUser ? 52 * s : 0,
              ),
              child: Text(
                _fmt(message.timestamp),
                style: GoogleFonts.inter(
                  color: const Color(0xFF6B6E76),
                  fontSize: 10 * s,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, double s, bool isUser) {
    switch (message.messageType) {
      case ChatMessageType.workoutPlan:
        return WorkoutPlanCard(data: message.structuredData!, s: s);
      case ChatMessageType.nutritionPlan:
        return NutritionPlanCard(data: message.structuredData!, s: s);
      case ChatMessageType.progressSummary:
        return ProgressSummaryCard(data: message.structuredData!, s: s);
      default:
        return _buildTextBubble(context, s, isUser);
    }
  }

  Widget _buildTextBubble(BuildContext context, double s, bool isUser) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final custom = context.customColors;

    if (isUser) {
      return Container(
        constraints: BoxConstraints(
          maxWidth: Responsive.contentMaxWidth(context) * 0.82,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
        decoration: BoxDecoration(
          color: custom.surfaceElevated,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16 * s),
            topRight: const Radius.circular(4),
            bottomLeft: Radius.circular(16 * s),
            bottomRight: Radius.circular(16 * s),
          ),
          border: Border.all(
            color: custom.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message.content,
          style: GoogleFonts.inter(
            color: isDark ? Colors.white : const Color(0xFF111827),
            fontSize: 14 * s,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
      );
    } else {
      // Assistant bubble: borderless, transparent background
      if (message.status == MessageStatus.sending || message.content.isEmpty) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 12 * s),
          child: _BubbleTypingIndicator(s: s),
        );
      }

      return Container(
        constraints: BoxConstraints(
          maxWidth: Responsive.contentMaxWidth(context) * 0.85,
        ),
        padding: EdgeInsets.symmetric(vertical: 8 * s),
        child: MarkdownBody(
          data: message.content,
          styleSheet: MarkdownStyleSheet(
            p: GoogleFonts.inter(
              color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1F2937),
              fontSize: 14.5 * s,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
            strong: GoogleFonts.montserrat(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
            listBullet: GoogleFonts.inter(
              color: const Color(0xFF7CA794),
            ),
            h1: GoogleFonts.montserrat(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 17 * s,
              fontWeight: FontWeight.w800,
            ),
            h2: GoogleFonts.montserrat(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 15 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
  }

  String _fmt(DateTime d) {
    final h = d.hour;
    final m = d.minute.toString().padLeft(2, '0');
    final ap = h >= 12 ? 'PM' : 'AM';
    final hr = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hr:$m $ap';
  }
}

class _ModernAIAvatar extends StatelessWidget {
  final double s;
  const _ModernAIAvatar({required this.s});

  @override
  Widget build(BuildContext context) {
    final custom = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40 * s,
      height: 40 * s,
      decoration: BoxDecoration(
        color: custom.surfaceCard,
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: custom.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB5FF4D).withValues(alpha: isDark ? 0.08 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: const Color(0xFFB5FF4D),
          size: 18 * s,
        ),
      ),
    );
  }
}

class _ModernUserAvatar extends StatelessWidget {
  final double s;
  const _ModernUserAvatar({required this.s});

  @override
  Widget build(BuildContext context) {
    final custom = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 40 * s,
      height: 40 * s,
      decoration: BoxDecoration(
        color: custom.surfaceElevated,
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: custom.border),
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          color: isDark ? const Color(0xFFA0A3AB) : const Color(0xFF4B6354),
          size: 18 * s,
        ),
      ),
    );
  }
}

class _BubbleTypingIndicator extends StatefulWidget {
  final double s;
  const _BubbleTypingIndicator({required this.s});

  @override
  State<_BubbleTypingIndicator> createState() => _BubbleTypingIndicatorState();
}

class _BubbleTypingIndicatorState extends State<_BubbleTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final animValue = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
            final scale = 1.0 + (0.3 * (1.0 - (animValue - 0.5).abs() * 2));
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 2.5 * s),
              width: 5 * s * scale,
              height: 5 * s * scale,
              decoration: const BoxDecoration(
                color: Color(0xFF7CA794),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
