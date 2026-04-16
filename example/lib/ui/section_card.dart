import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// A card that groups a titled section with an icon and optional
/// description. Used heavily on the onboarding and invoice screens
/// to bring visual hierarchy to long forms.
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget child;
  final Widget? trailing;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Gaps.md,
              vertical: Gaps.sm,
            ),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                Gaps.wSm,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            description!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[Gaps.wSm, trailing!],
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(Gaps.md), child: child),
        ],
      ),
    );
  }
}

/// Small uppercase caption used within cards to subdivide.
class Subheading extends StatelessWidget {
  final String text;
  const Subheading(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gaps.sm, bottom: Gaps.xs),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).hintColor,
      ),
    ),
  );
}
