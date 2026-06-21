import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../community/domain/models/chat_message.dart';
import '../../../community/presentation/providers/chat_provider.dart';
import '../widgets/workout_ui.dart';

/// Workout-themed AI coach — reuses community chat provider.
class WorkoutAiCoachScreen extends StatefulWidget {
  const WorkoutAiCoachScreen({super.key});

  @override
  State<WorkoutAiCoachScreen> createState() => _WorkoutAiCoachScreenState();
}

class _WorkoutAiCoachScreenState extends State<WorkoutAiCoachScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return WorkoutLightScaffold(
      appBar: AppBar(
        backgroundColor: WorkoutColors.scaffold(context),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: WorkoutColors.lime(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.black, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coach',
                  style: workoutTextStyle(
                    context,
                    size: 16,
                    weight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Always here to help',
                  style: workoutTextStyle(
                    context,
                    size: 11,
                    color: WorkoutColors.onSurfaceMuted(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chat.messages.length,
              itemBuilder: (ctx, i) {
                final msg = chat.messages[i];
                final isUser = msg.role == MessageRole.user;
                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF3B82F6)
                          : WorkoutColors.card(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.content,
                      style: workoutTextStyle(
                        context,
                        size: 14,
                        color: isUser
                            ? Colors.white
                            : WorkoutColors.onSurface(context),
                        weight: FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (chat.messages.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () => context.push(AppRoutes.community),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: WorkoutColors.limeMuted(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: WorkoutColors.lime(context).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center, color: Colors.black),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Try: "Suggest a recovery workout for today"',
                          style: workoutTextStyle(
                            context,
                            size: 13,
                            color: WorkoutColors.onSurfaceMuted(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: WorkoutColors.onSurfaceMuted(context),
                    ),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask your AI coach...',
                        filled: true,
                        fillColor: WorkoutColors.card(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      final text = _controller.text.trim();
                      if (text.isEmpty) return;
                      _controller.clear();
                      await chat.sendMessage(text);
                      _scrollToBottom();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: WorkoutColors.lime(context),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
