import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_area.dart';
import '../widgets/typing_indicator.dart';
import '../../domain/models/chat_message.dart';
import 'chat_history_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();
    if (auth.userId != null && !chat.hasMessages) {
      chat.initForUser(auth.userId!, context);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().refreshContext(context);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
    }
  }

  Future<void> _sendQuick(String prompt) async {
    HapticFeedback.selectionClick();
    await context.read<ChatProvider>().sendMessage(prompt);
    if (mounted) _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Aesthetic
          Positioned(
            top: -100 * s,
            right: -100 * s,
            child: Container(
              width: 300 * s,
              height: 300 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.08 : 0.05),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  _Header(s: s),
                  Expanded(
                    child: Consumer<ChatProvider>(
                      builder: (context, chat, child) {
                        final hasMessages = chat.messages.isNotEmpty;

                        if (!hasMessages) {
                          return _DiscoveryView(
                            s: s,
                            onTopic: _sendQuick,
                          );
                        }

                        final bool showTyping =
                            chat.isTyping &&
                            (chat.messages.isEmpty ||
                                chat.messages.last.role != MessageRole.assistant);
                        final int itemCount =
                            chat.messages.length + (showTyping ? 1 : 0) + 1;

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 20 * s),
                          physics: const BouncingScrollPhysics(),
                          itemCount: itemCount,
                          itemBuilder: (context, index) {
                            if (index == itemCount - 1) {
                              return const SizedBox(height: 20);
                            }

                            if (showTyping && index == 0) {
                              return const TypingIndicator();
                            }

                            final int messageOffset = showTyping ? 1 : 0;
                            final int messageIndex =
                                chat.messages.length -
                                1 -
                                 (index - messageOffset);

                            if (messageIndex >= 0 &&
                                messageIndex < chat.messages.length) {
                              return ChatBubble(
                                message: chat.messages[messageIndex],
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  ),
                  ChatInputArea(s: s, onMessageSent: _scrollToBottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double s;
  const _Header({required this.s});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(24 * s, 12 * s, 24 * s, 16 * s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BeFit Coach',
                  style: GoogleFonts.montserrat(
                    color: theme.colorScheme.onSurface,
                    fontSize: 28 * s,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Your personal fitness expert',
                  style: GoogleFonts.montserrat(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14 * s,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _CircularAction(
            icon: Icons.add_rounded,
            onTap: () {
              HapticFeedback.mediumImpact();
              context.read<ChatProvider>().startNewChat();
            },
            s: s,
          ),
          SizedBox(width: 12 * s),
          _CircularAction(
            icon: Icons.history_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatHistoryScreen(),
              ),
            ),
            s: s,
          ),
        ],
      ),
    );
  }
}

class _CircularAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double s;

  const _CircularAction({
    required this.icon,
    required this.onTap,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44 * s,
          height: 44 * s,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark 
                ? theme.colorScheme.outline.withValues(alpha: 0.1) 
                : theme.colorScheme.outline.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurface,
            size: 22 * s,
          ),
        ),
      ),
    );
  }
}

class _DiscoveryView extends StatelessWidget {
  final double s;
  final Function(String) onTopic;

  const _DiscoveryView({
    required this.s,
    required this.onTopic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final custom = context.customColors;
    final chatProvider = context.watch<ChatProvider>();
    final ctx = chatProvider.userContext;
    final suggestedQuestions = chatProvider.suggestedQuestions;

    final name = ctx?.name ?? 'Athlete';
    final caloriesToday = ctx?.caloriesToday ?? 0;
    final workoutsThisWeek = ctx?.workoutsThisWeek ?? 0;
    final workoutDaysPerWeek = ctx?.workoutDaysPerWeek ?? 4;
    final currentStreakDays = ctx?.currentStreakDays ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: 24 * s),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section A: User Stats Snapshot
          Container(
            margin: EdgeInsets.fromLTRB(24 * s, 16 * s, 24 * s, 0),
            padding: EdgeInsets.all(18 * s),
            decoration: BoxDecoration(
              color: custom.surfaceCard,
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: custom.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left: Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hey, $name! 👋',
                        style: GoogleFonts.montserrat(
                          fontSize: 18 * s,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4 * s),
                      Text(
                        "Here's your snapshot for today",
                        style: GoogleFonts.inter(
                          fontSize: 12 * s,
                          color: isDark ? const Color(0xFFA0A3AB) : const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: Mini stats grid
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _MiniStat('🔥', '$caloriesToday', 'kcal today', s: s),
                    SizedBox(height: 6 * s),
                    _MiniStat('💪', '$workoutsThisWeek/$workoutDaysPerWeek', 'workouts', s: s),
                    SizedBox(height: 6 * s),
                    _MiniStat('⚡', '${currentStreakDays}d', 'streak', s: s),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 32 * s),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * s),
            child: Text(
              'Personalized Coach Actions',
              style: GoogleFonts.montserrat(
                color: theme.colorScheme.onSurface,
                fontSize: 18 * s,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: 16 * s),

          // Section B: Personalized Quick Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24 * s),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16 * s,
                mainAxisSpacing: 16 * s,
                childAspectRatio: 1.1,
              ),
              itemCount: suggestedQuestions.length,
              itemBuilder: (context, index) {
                final q = suggestedQuestions[index];
                return _TopicCard(
                  q: q,
                  s: s,
                  onTap: () => onTopic(q.text),
                );
              },
            ),
          ),

          // Section C: Preset Prompts
          Padding(
            padding: EdgeInsets.symmetric(vertical: 24 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24 * s),
                  child: Text(
                    'Ask me about...',
                    style: GoogleFonts.montserrat(
                      color: theme.colorScheme.onSurface,
                      fontSize: 15 * s,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(height: 12 * s),
                SizedBox(
                  height: 40 * s,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 20 * s),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      'My workout split',
                      'Protein today',
                      'Recovery tips',
                      'Chest exercises',
                      'How to lose fat',
                      'My progress',
                    ].map((prompt) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8 * s),
                        child: ActionChip(
                          label: Text(
                            prompt,
                            style: GoogleFonts.inter(
                              color: const Color(0xFF7CA794),
                              fontSize: 12 * s,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: custom.surfaceCard,
                          side: BorderSide(color: custom.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20 * s),
                          ),
                          onPressed: () => onTopic(prompt),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final double s;

  const _MiniStat(
    this.emoji,
    this.value,
    this.label, {
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(fontSize: 12 * s)),
        SizedBox(width: 4 * s),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13 * s,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        SizedBox(width: 3 * s),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10 * s,
            color: isDark ? const Color(0xFFA0A3AB) : const Color(0xFF4B5563),
          ),
        ),
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  final SuggestedQuestion q;
  final double s;
  final VoidCallback onTap;

  const _TopicCard({
    required this.q,
    required this.s,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'restaurant':
        return Icons.restaurant_menu_rounded;
      case 'trending_up':
      case 'local_fire_department':
        return Icons.bolt_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _getAccentColor(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return const Color(0xFF10B981);
      case 'restaurant':
        return const Color(0xFFF59E0B);
      case 'trending_up':
      case 'local_fire_department':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF7CA794);
    }
  }

  String _getDescription(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return 'Get a custom workout split...';
      case 'restaurant':
        return 'Meals based on your macros...';
      case 'trending_up':
      case 'local_fire_department':
        return 'Review your stats & recovery...';
      default:
        return 'Get professional coaching...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final iconData = _getIconData(q.icon);
    final accent = _getAccentColor(q.icon);
    final desc = _getDescription(q.icon);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16 * s),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24 * s),
          border: Border.all(
            color: isDark 
              ? theme.colorScheme.outline.withValues(alpha: 0.1) 
              : theme.colorScheme.outline.withValues(alpha: 0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8 * s),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Icon(iconData, color: accent, size: 20 * s),
            ),
            const Spacer(),
            Text(
              q.text,
              style: GoogleFonts.montserrat(
                color: theme.colorScheme.onSurface,
                fontSize: 12 * s,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4 * s),
            Text(
              desc,
              style: GoogleFonts.montserrat(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10 * s,
                height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
