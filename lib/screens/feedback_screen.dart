import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/feedback_config.dart';
import '../state/feedback_prompt_provider.dart';
import '../theme/app_theme.dart';
import '../utils/open_link.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "We'd love to hear from you",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _FeedbackButton(
                    icon: Icons.star_rounded,
                    title: 'Leave a Review',
                    subtitle: 'Rate the app and tell us what you think',
                    color: AppTheme.accent,
                    onPressed: () => _openReview(context),
                  ),
                  const SizedBox(height: 16),
                  _FeedbackButton(
                    icon: Icons.lightbulb_outline,
                    title: 'Make a Suggestion',
                    subtitle:
                        'Report a problem, a wrong value, or request a feature',
                    color: AppTheme.primary,
                    onPressed: () => _openSuggestion(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReview(BuildContext context) async {
    final feedbackProvider = context.read<FeedbackPromptProvider>();
    final opened = await openLink(reviewFormUrl);
    if (!context.mounted) return;
    if (opened) {
      await feedbackProvider.markReviewed();
    } else {
      _showOpenFailure(context);
    }
  }

  Future<void> _openSuggestion(BuildContext context) async {
    final opened = await openLink(suggestionFormUrl);
    if (!context.mounted) return;
    if (!opened) _showOpenFailure(context);
  }

  void _showOpenFailure(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Couldn't open the form. Please try again."),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: onPressed,
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
