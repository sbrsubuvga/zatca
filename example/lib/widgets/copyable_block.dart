import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ui/breakpoints.dart';

/// Bordered monospace block with a one-tap copy button. Used on
/// the result screen to make hashes, PEMs, and XML copy-pasteable.
class CopyableBlock extends StatefulWidget {
  final String title;
  final String content;
  final int? maxLines;
  final String? subtitle;

  const CopyableBlock({
    super.key,
    required this.title,
    required this.content,
    this.maxLines,
    this.subtitle,
  });

  @override
  State<CopyableBlock> createState() => _CopyableBlockState();
}

class _CopyableBlockState extends State<CopyableBlock> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: Gaps.xs),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gaps.sm, Gaps.sm, Gaps.xs, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (widget.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.subtitle!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _copied ? Icons.check : Icons.copy_outlined,
                      key: ValueKey(_copied),
                      size: 18,
                      color: _copied ? Colors.green : null,
                    ),
                  ),
                  tooltip: _copied ? 'Copied!' : 'Copy',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.content),
                    );
                    if (!mounted) return;
                    setState(() => _copied = true);
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) setState(() => _copied = false);
                    });
                  },
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              Gaps.sm,
              Gaps.xs,
              Gaps.sm,
              Gaps.sm,
            ),
            child: SelectableText(
              widget.content,
              maxLines: widget.maxLines,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.4,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
