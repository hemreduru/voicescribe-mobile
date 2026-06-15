import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:voicescribe_mobile/data/repositories/chat_repository.dart';
import 'package:voicescribe_mobile/domain/models/chat.dart';
import 'package:voicescribe_mobile/domain/models/domain.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/theme/premium_tokens.dart';
import 'package:voicescribe_mobile/ui/core/widgets/adaptive_master_detail.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_page.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_skeleton.dart';
import 'package:voicescribe_mobile/ui/core/widgets/premium_widgets.dart';
import 'package:voicescribe_mobile/ui/features/ai/bloc/chat_list_cubit.dart';
import 'package:voicescribe_mobile/ui/features/ai/views/conversation_view.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatListCubit>(
      create: (ctx) => ChatListCubit(ctx.read<ChatRepository>())..load(),
      child: const _AiView(),
    );
  }
}

class _AiView extends StatefulWidget {
  const _AiView();

  @override
  State<_AiView> createState() => _AiViewState();
}

class _AiViewState extends State<_AiView> {
  int? _selectedSessionId;
  bool _composingNew = false;

  void _reload() => context.read<ChatListCubit>().load();

  void _openSession(int id, {required bool twoPane}) {
    if (twoPane) {
      setState(() {
        _selectedSessionId = id;
        _composingNew = false;
      });
    } else {
      _pushConversation(sessionId: id);
    }
  }

  void _newChat({required bool twoPane}) {
    if (twoPane) {
      setState(() {
        _composingNew = true;
        _selectedSessionId = null;
      });
    } else {
      _pushConversation(sessionId: null);
    }
  }

  Future<void> _pushConversation({required int? sessionId}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ConversationPage(
          repository: context.read<ChatRepository>(),
          sessionId: sessionId,
        ),
      ),
    );
    if (mounted) {
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoPane = constraints.maxWidth >= AppPanes.twoPaneBreakpoint;
        final master = _SessionsPane(
          selectedId: twoPane ? _selectedSessionId : null,
          composingNew: twoPane && _composingNew,
          onSelect: (id) => _openSession(id, twoPane: twoPane),
          onNewChat: () => _newChat(twoPane: twoPane),
        );

        if (!twoPane) {
          return Scaffold(body: master);
        }

        final selectionKey = _composingNew
            ? 'new'
            : (_selectedSessionId == null
                  ? null
                  : 'session-$_selectedSessionId');

        return Scaffold(
          body: AdaptiveMasterDetail<String>(
            isTwoPane: true,
            selected: selectionKey,
            master: master,
            emptyState: const _NoSelectionState(),
            detailBuilder: (context, _) => ConversationView(
              key: ValueKey(selectionKey),
              sessionId: _composingNew ? null : _selectedSessionId,
              onSessionTouched: (_) => _reload(),
            ),
          ),
        );
      },
    );
  }
}

class _SessionsPane extends StatelessWidget {
  const _SessionsPane({
    required this.selectedId,
    required this.composingNew,
    required this.onSelect,
    required this.onNewChat,
  });

  final int? selectedId;
  final bool composingNew;
  final ValueChanged<int> onSelect;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SafeArea(
      child: BlocBuilder<ChatListCubit, ChatListState>(
        builder: (context, state) {
          return AppPageListView(
            children: [
              SectionHeader(title: l10n.aiTitle, subtitle: l10n.aiSubtitle),
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.chatNewChat,
                icon: Icons.add,
                onPressed: onNewChat,
                expanded: true,
                variant: composingNew
                    ? AppButtonVariant.primary
                    : AppButtonVariant.tonal,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (state.loading && state.sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.lg),
                  child: AppSkeletonList(itemCount: 4, lineCount: 1),
                )
              else if (state.sessions.isEmpty)
                const _EmptyChatGuidance()
              else
                ...state.sessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SessionCard(
                      session: session,
                      selected: session.id == selectedId,
                      onTap: () => onSelect(session.id),
                      onDelete: () => _confirmDelete(context, session),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ChatSession session) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatDeleteTitle),
        content: Text(l10n.chatDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && context.mounted) {
      await context.read<ChatListCubit>().delete(session.id);
    }
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });

  final ChatSession session;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final when = session.lastMessageAt ?? session.createdAt;
    final subtitle = when == null
        ? null
        : DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).add_Hm().format(when);

    return AppCard(
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.forum_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title.trim().isEmpty
                      ? l10n.chatUntitled
                      : session.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.delete,
            icon: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Picks the right empty state: a "record something first" nudge when the user
/// has no transcripts (the assistant answers from them), otherwise the standard
/// "no conversations yet" state. Defaults to the latter while loading so the
/// nudge never flashes for users who do have recordings.
class _EmptyChatGuidance extends StatelessWidget {
  const _EmptyChatGuidance();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TranscriptSnapshot>(
      future: context.read<TranscriptRepository>().loadSnapshot(),
      builder: (context, snapshot) {
        final hasTranscripts = snapshot.data?.transcripts.isNotEmpty ?? true;
        return hasTranscripts
            ? const _NoSessionsState()
            : const _NoTranscriptsState();
      },
    );
  }
}

class _NoTranscriptsState extends StatelessWidget {
  const _NoTranscriptsState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          Icon(Icons.mic_none, size: 44, color: theme.colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.chatNeedsRecordingTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.chatNeedsRecordingMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSessionsState extends StatelessWidget {
  const _NoSessionsState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          Icon(
            Icons.forum_outlined,
            size: 44,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.chatNoSessionsTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.chatNoSessionsMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoSelectionState extends StatelessWidget {
  const _NoSelectionState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.chatSelectOrNew,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen conversation for compact (phone) layouts.
class _ConversationPage extends StatelessWidget {
  const _ConversationPage({required this.repository, required this.sessionId});

  final ChatRepository repository;
  final int? sessionId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RepositoryProvider<ChatRepository>.value(
      value: repository,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.aiTitle)),
        body: ConversationView(sessionId: sessionId),
      ),
    );
  }
}
