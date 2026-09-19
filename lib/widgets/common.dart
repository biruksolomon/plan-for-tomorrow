import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Masthead used at the top of every main screen: oversized condensed word,
/// a quiet date line under it, and an optional counter to the right.
class PageMasthead extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PageMasthead({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(title.toUpperCase(), style: AppTheme.display(58)),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: AppTheme.body(15, color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        Container(height: 3, color: AppColors.ink),
      ],
    );
  }
}

/// Circular counter that sits beside the masthead.
class CounterBadge extends StatelessWidget {
  final String value;
  final String label;

  const CounterBadge({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: 2.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: AppTheme.display(28, color: AppColors.accent)),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.body(9, color: AppColors.muted, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// A single task line. Read-only unless [onToggle] is provided.
class TickRow extends StatelessWidget {
  final int index;
  final String title;
  final bool isDone;
  final VoidCallback? onToggle;

  const TickRow({
    super.key,
    required this.index,
    required this.title,
    required this.isDone,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final filled = isDone;
    final textColor = filled ? AppColors.accentTint : AppColors.ink;

    return Semantics(
      button: onToggle != null,
      checked: isDone,
      label: title,
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : AppColors.paper2,
            border: Border.all(color: filled ? AppColors.accent : AppColors.ink, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  index.toString().padLeft(2, '0'),
                  style: AppTheme.display(
                    18,
                    color: filled ? AppColors.accentTint : AppColors.muted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.body(
                    15,
                    color: textColor,
                    weight: FontWeight.w600,
                    decoration: filled ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.accentTint : Colors.transparent,
                  border: Border.all(
                    color: filled ? AppColors.accentTint : AppColors.muted,
                    width: 2,
                  ),
                ),
                child: filled
                    ? const Icon(Icons.check, size: 17, color: AppColors.accent)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty screens are an invitation to act, so each one states the next move.
class EmptyNote extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyNote({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.muted, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTheme.body(15, color: AppColors.muted)),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            PrimaryButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.35),
          foregroundColor: AppColors.accentTint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(
          label,
          style: AppTheme.body(
            15,
            color: enabled ? AppColors.accentTint : AppColors.paper,
            weight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// Italic line with a gold rule, carried over from the printed sheets.
class QuoteLine extends StatelessWidget {
  final String text;
  const QuoteLine(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 14),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: AppColors.gold, width: 3),
        ),
      ),
      child: Text(
        text,
        style: AppTheme.body(14, color: AppColors.muted).copyWith(
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
