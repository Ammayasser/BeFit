import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/chat_provider.dart';

class ChatInputArea extends StatefulWidget {
  final double s;
  final VoidCallback onMessageSent;

  const ChatInputArea({
    super.key,
    required this.s,
    required this.onMessageSent,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text;
    if (text.trim().isNotEmpty) {
      HapticFeedback.mediumImpact();
      context.read<ChatProvider>().sendMessage(text);
      _controller.clear();
      widget.onMessageSent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20 * s,
        12 * s,
        20 * s,
        16 * s + bottomInset,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              height: 52 * s,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24 * s),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 15 * s,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: 'Message Chatbot...',
                  hintStyle: GoogleFonts.montserrat(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    fontSize: 15 * s,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20 * s,
                    vertical: 14 * s,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12 * s),
          _SendButton(controller: _controller, onTap: _sendMessage, s: s),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;
  final double s;

  const _SendButton({
    required this.controller,
    required this.onTap,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isEmpty = controller.text.trim().isEmpty;
        final theme = Theme.of(context);

        return GestureDetector(
          onTap: isEmpty ? null : onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52 * s,
            height: 52 * s,
            decoration: BoxDecoration(
              color: isEmpty
                  ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                  : theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_upward_rounded,
              color: isEmpty
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                  : theme.colorScheme.onPrimary,
              size: 24 * s,
            ),
          ),
        );
      },
    );
  }
}
