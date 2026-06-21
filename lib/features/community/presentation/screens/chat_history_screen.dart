import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import '../providers/chat_provider.dart';
import '../../domain/models/chat_session.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 24 * s),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: 'Go back',
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44 * s,
                        height: 44 * s,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12 * s),
                          border: Border.all(color: context.customColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20 * s,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * s),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ARCHIVE',
                        style: GoogleFonts.montserrat(
                          color: theme.colorScheme.primary,
                          fontSize: 12 * s,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'Past Sessions',
                        style: GoogleFonts.montserrat(
                          color: theme.colorScheme.onSurface,
                          fontSize: 22 * s,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return FutureBuilder<List<ChatSession>>(
                    future: chatProvider.getAllSessions(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                      }
                      
                      final sessions = snapshot.data ?? [];

                      if (sessions.isEmpty) {
                        return _EmptyHistory(s: s);
                      }

                      return ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 8 * s),
                        physics: const BouncingScrollPhysics(),
                        itemCount: sessions.length,
                        separatorBuilder: (context, i) => SizedBox(height: 12 * s),
                        itemBuilder: (context, index) {
                          return _SessionCard(
                            session: sessions[index],
                            s: s,
                            chatProvider: chatProvider,
                            onDeleted: () => (context as Element).markNeedsBuild(),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  final double s;
  const _EmptyHistory({required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64 * s,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          SizedBox(height: 24 * s),
          Text(
            'No archived sessions',
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 16 * s,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ChatSession session;
  final double s;
  final ChatProvider chatProvider;
  final VoidCallback onDeleted;

  const _SessionCard({
    required this.session,
    required this.s,
    required this.chatProvider,
    required this.onDeleted,
  });

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(dt.year, dt.month, dt.day);

    if (dateToCheck == today) {
      return 'Today, ${DateFormat.jm().format(dt)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(dt)}';
    } else if (now.difference(dt).inDays < 7) {
      return '${DateFormat.EEEE().format(dt)}, ${DateFormat.jm().format(dt)}';
    } else {
      return '${DateFormat.yMMMd().format(dt)}, ${DateFormat.jm().format(dt)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Chat session: ${session.title}',
      hint: 'Tap to load this session',
      child: GestureDetector(
        onTap: () async {
          HapticFeedback.lightImpact();
          await chatProvider.loadChat(session.id);
          if (context.mounted) Navigator.pop(context);
        },
        child: Container(
          padding: EdgeInsets.all(16 * s),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(color: context.customColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40 * s,
                height: 40 * s,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: theme.colorScheme.primary,
                  size: 20 * s,
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: GoogleFonts.montserrat(
                        color: theme.colorScheme.onSurface,
                        fontSize: 15 * s,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4 * s),
                    Text(
                      _formatDateTime(session.updatedAt),
                      style: GoogleFonts.montserrat(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11 * s,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: 'Delete session',
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.colorScheme.error.withValues(alpha: 0.8),
                    size: 20 * s,
                  ),
                  onPressed: () => _showDeleteDialog(context, session.id, chatProvider, onDeleted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showDeleteDialog(BuildContext context, String sessionId, ChatProvider chatProvider, VoidCallback onDeleted) {
  final theme = Theme.of(context);
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Delete Session?',
        style: GoogleFonts.montserrat(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'This session will be permanently removed from your history.', 
        style: GoogleFonts.montserrat(color: theme.colorScheme.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text(
            'CANCEL',
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await chatProvider.deleteChat(sessionId);
            onDeleted();
          },
          child: Text(
            'DELETE',
            style: GoogleFonts.montserrat(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

