import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 40),
      children: [
        PageMasthead(
          title: 'Settings',
          subtitle: 'Your data stays on this device.',
        ),
        const SizedBox(height: 24),

        _row(
          context,
          label: 'Copy data as CSV',
          detail: 'Puts every task on the clipboard so you can paste it into '
              'a sheet and keep a backup.',
          onTap: () => _export(context),
        ),
        const Divider(height: 1, color: AppColors.paper2),
        _row(
          context,
          label: 'Delete everything',
          detail: 'Clears all plans and history. This cannot be undone.',
          destructive: true,
          onTap: () => _confirmReset(context),
        ),

        const SizedBox(height: 30),
        const QuoteLine(
          'Nothing here is uploaded anywhere. If you uninstall the app, the '
          'history goes with it — export now and then.',
        ),
      ],
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required String detail,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppTheme.body(
                    16,
                    color: destructive ? AppColors.accent : AppColors.ink,
                    weight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: destructive ? AppColors.accent : AppColors.muted,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(detail, style: AppTheme.body(13, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final csv = await context.read<AppState>().exportCsv();
    await Clipboard.setData(ClipboardData(text: csv));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(
          'Copied to clipboard.',
          style: AppTheme.body(14, color: AppColors.paper),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Delete everything?', style: AppTheme.display(22)),
        content: Text(
          'Every plan and all history will be removed from this device.',
          style: AppTheme.body(14, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Keep it', style: AppTheme.body(14, color: AppColors.ink)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: AppTheme.body(14, color: AppColors.accent, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<AppState>().resetEverything();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(
          'Deleted.',
          style: AppTheme.body(14, color: AppColors.paper),
        ),
      ),
    );
  }
}
