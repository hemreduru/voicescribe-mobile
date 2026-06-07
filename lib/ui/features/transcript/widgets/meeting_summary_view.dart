import 'package:flutter/material.dart';
import 'package:voicescribe_mobile/domain/models/meeting_summary.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/design_system.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_section.dart';
import 'package:voicescribe_mobile/ui/core/widgets/premium_widgets.dart';

/// Renders a structured [MeetingSummary] as titled sections (künye, executive
/// summary, agenda, decisions, action items, open questions, notes) using the
/// shared design-system components.
class MeetingSummaryView extends StatelessWidget {
  const MeetingSummaryView({
    required this.summary,
    required this.providerKey,
    super.key,
  });

  final MeetingSummary summary;
  final String providerKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Only 'local' is on-device; treat any other key (cloud, or a raw backend
    // provider like gemini/openai that slipped through) as cloud.
    final isCloud = providerKey != 'local';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: summary.title.trim().isEmpty
              ? l10n.summarySettings
              : summary.title.trim(),
          subtitle: summary.subtitle,
          trailing: StatusPill(
            icon: isCloud ? Icons.cloud_outlined : Icons.smartphone,
            label: isCloud
                ? l10n.summaryProviderCloudLabel
                : l10n.summaryProviderLocalLabel,
            color: theme.colorScheme.primary,
            compact: true,
          ),
        ),
        if (summary.hasMetadataDetails) ...[
          const SizedBox(height: AppSpacing.md),
          _metadataCard(context),
        ],
        if (summary.executiveSummary.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _bulletSection(
            context,
            title: l10n.summaryExecutiveSummary,
            items: summary.executiveSummary,
            icon: Icons.notes_outlined,
            color: theme.colorScheme.primary,
          ),
        ],
        if (summary.agendaItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _agendaSection(context),
        ],
        if (summary.decisions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _bulletSection(
            context,
            title: l10n.summaryDecisions,
            items: summary.decisions,
            icon: Icons.check_circle_outline,
            color: theme.colorScheme.tertiary,
          ),
        ],
        if (summary.actionItems.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _actionItemsSection(context),
        ],
        if (summary.openQuestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _bulletSection(
            context,
            title: l10n.summaryOpenQuestions,
            items: summary.openQuestions,
            icon: Icons.help_outline,
            color: theme.colorScheme.secondary,
          ),
        ],
        if (summary.notes.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _bulletSection(
            context,
            title: l10n.summaryNotes,
            items: summary.notes,
            icon: Icons.flag_outlined,
            color: theme.colorScheme.error,
          ),
        ],
      ],
    );
  }

  Widget _metadataCard(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final meta = summary.metadata;

    final pills = <Widget>[
      if ((meta.date ?? '').isNotEmpty)
        StatusPill(
          icon: Icons.event_outlined,
          label: meta.date!,
          compact: true,
        ),
      if (_timeRange(meta).isNotEmpty)
        StatusPill(
          icon: Icons.schedule,
          label: _timeRange(meta),
          compact: true,
        ),
      if ((meta.location ?? '').isNotEmpty)
        StatusPill(
          icon: Icons.place_outlined,
          label: meta.location!,
          compact: true,
        ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pills.isNotEmpty)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: pills,
            ),
          if (meta.attendees.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _peopleRow(
              context,
              label: l10n.summaryAttendees,
              people: meta.attendees,
              icon: Icons.person_outline,
              color: theme.colorScheme.tertiary,
            ),
          ],
          if (meta.absentees.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _peopleRow(
              context,
              label: l10n.summaryAbsentees,
              people: meta.absentees,
              icon: Icons.person_off_outlined,
              color: theme.colorScheme.error,
            ),
          ],
        ],
      ),
    );
  }

  Widget _peopleRow(
    BuildContext context, {
    required String label,
    required List<String> people,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: people
              .map(
                (name) => StatusPill(
                  icon: icon,
                  label: name,
                  color: color,
                  compact: true,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _bulletSection(
    BuildContext context, {
    required String title,
    required List<String> items,
    required IconData icon,
    required Color color,
  }) {
    return AppSectionCard(
      title: title,
      showHeaderDivider: true,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          _bulletRow(context, text: items[i], icon: icon, color: color),
        ],
      ],
    );
  }

  Widget _bulletRow(
    BuildContext context, {
    required String text,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
  }

  Widget _agendaSection(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppSectionCard(
      title: l10n.summaryAgenda,
      showHeaderDivider: true,
      children: [
        for (var i = 0; i < summary.agendaItems.length; i++) ...[
          if (i > 0) const PremiumDivider(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.agendaItems[i].title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (summary.agendaItems[i].discussion.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  summary.agendaItems[i].discussion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if ((summary.agendaItems[i].conclusion ?? '')
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                StatusPill(
                  icon: Icons.flag_circle_outlined,
                  label: summary.agendaItems[i].conclusion!,
                  color: theme.colorScheme.tertiary,
                  compact: true,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _actionItemsSection(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AppSectionCard(
      title: l10n.summaryActionItems,
      showHeaderDivider: true,
      children: [
        for (var i = 0; i < summary.actionItems.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.task_alt,
                      size: 18,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      summary.actionItems[i].task,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusPill(
                      icon: Icons.person_outline,
                      label: (summary.actionItems[i].owner ?? '').trim().isEmpty
                          ? l10n.summaryUnassigned
                          : summary.actionItems[i].owner!.trim(),
                      color: theme.colorScheme.secondary,
                      compact: true,
                    ),
                    if ((summary.actionItems[i].dueDate ?? '')
                        .trim()
                        .isNotEmpty)
                      StatusPill(
                        icon: Icons.event_available_outlined,
                        label: summary.actionItems[i].dueDate!.trim(),
                        color: theme.colorScheme.primary,
                        compact: true,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _timeRange(MeetingMetadata meta) {
    final start = (meta.startTime ?? '').trim();
    final end = (meta.endTime ?? '').trim();
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start – $end';
    }
    return start.isNotEmpty ? start : end;
  }
}
