import 'dart:async';

import 'package:flutter/material.dart';
import 'package:voicescribe_mobile/data/services/sync/sync_queue_service.dart';
import 'package:voicescribe_mobile/l10n/app_localizations.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';

class GlobalSyncFeedbackHost extends StatefulWidget {
  const GlobalSyncFeedbackHost({
    required this.syncQueueService,
    required this.child,
    super.key,
  });

  final SyncQueueService syncQueueService;
  final Widget child;

  @override
  State<GlobalSyncFeedbackHost> createState() => _GlobalSyncFeedbackHostState();
}

class _GlobalSyncFeedbackHostState extends State<GlobalSyncFeedbackHost> {
  StreamSubscription<SyncEvent>? _subscription;
  SyncEvent? _activeEvent;
  bool _visible = false;
  Timer? _hideTimer;
  Timer? _removeTimer;

  static const _bannerDisplayDuration = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(covariant GlobalSyncFeedbackHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.syncQueueService != widget.syncQueueService) {
      unawaited(_subscription?.cancel());
      _subscribe();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeTimer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEvent = _activeEvent;
    if (activeEvent == null) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: IgnorePointer(
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: AnimatedSlide(
                offset: _visible ? Offset.zero : const Offset(0, -1),
                duration: _animationDuration,
                curve: Curves.easeOutCubic,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: _animationDuration,
                  curve: Curves.easeOutCubic,
                  child: _SyncMiniBanner(event: activeEvent),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _subscribe() {
    _subscription = widget.syncQueueService.syncEvents.listen((event) {
      if (!_shouldShowBanner(event)) {
        return;
      }
      _hideTimer?.cancel();
      _removeTimer?.cancel();
      setState(() {
        _activeEvent = event;
        _visible = true;
      });
      _hideTimer = Timer(_bannerDisplayDuration, () {
        if (!mounted) {
          return;
        }
        setState(() => _visible = false);
        _removeTimer = Timer(_animationDuration, () {
          if (!mounted) {
            return;
          }
          setState(() => _activeEvent = null);
        });
      });
    });
  }

  bool _shouldShowBanner(SyncEvent event) {
    if (event.type != SyncEventType.success) {
      return false;
    }

    if (event.trigger == SyncTrigger.manual ||
        event.trigger == SyncTrigger.refresh) {
      return true;
    }

    return event.metrics.totalChanged > 0;
  }

  Duration get _animationDuration {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Duration.zero : AppMotion.normal;
  }
}

class _SyncMiniBanner extends StatelessWidget {
  const _SyncMiniBanner({required this.event});

  final SyncEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final subtitle = _subtitleForEvent(l10n, event);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              scheme.primaryContainer.withValues(alpha: 0.96),
              scheme.tertiaryContainer.withValues(alpha: 0.92),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.28)),
          boxShadow: AppElevation.soft(scheme.primary),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_done_outlined,
                color: AppTheme.teal,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.syncBannerTitle,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitleForEvent(AppLocalizations l10n, SyncEvent event) {
    final metrics = event.metrics;
    if (metrics.totalChanged == 0) {
      return l10n.syncBannerSuccess;
    }
    return l10n.syncBannerSuccessWithCounts(
      metrics.pushed,
      metrics.pulled,
      metrics.cleaned,
    );
  }
}
