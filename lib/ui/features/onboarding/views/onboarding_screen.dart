import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:voicescribe_mobile/data/services/llm/llm_model_service.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/domain/repositories/transcript_repository.dart';
import 'package:voicescribe_mobile/domain/utils/locale_utils.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/widgets/ambient_backdrop.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_segmented_control.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';
import 'package:voicescribe_mobile/ui/features/onboarding/bloc/onboarding_cubit.dart';

/// First-run wizard. Reached via the `/onboarding` route when
/// `hasSeenOnboarding` is false; on finish it persists the chosen preferences
/// and tells [BootstrapBloc] so the router lands on the app.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OnboardingCubit>(
      create: (context) => OnboardingCubit(
        transcriptRepository: context.read<TranscriptRepository>(),
        localLlmModelService: context.read<LocalLlmModelService>(),
        transcriptionService: context.read<TranscriptionService>(),
        deviceLanguageCode: deviceLanguageCode(),
      )..init(),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listenWhen: (p, c) =>
          p.pageIndex != c.pageIndex || p.completed != c.completed,
      listener: (context, state) {
        if (state.completed) {
          // Router redirects to the app once bootstrap reports onboarding done.
          context.read<BootstrapBloc>().add(const BootstrapOnboardingCompleted());
          return;
        }
        if (_controller.hasClients &&
            _controller.page?.round() != state.pageIndex) {
          unawaited(
            _controller.animateToPage(
              state.pageIndex,
              duration: AppMotion.normal,
              curve: AppMotion.standardCurve,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<OnboardingCubit>();
        final isLast = state.pageIndex == OnboardingCubit.pageCount - 1;

        return Scaffold(
          body: AmbientBackdrop(
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        right: AppSpacing.sm,
                        top: AppSpacing.sm,
                      ),
                      child: TextButton(
                        onPressed: state.saving ? null : cubit.finish,
                        child: Text(l10n.onboardingSkip),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _controller,
                      onPageChanged: cubit.goTo,
                      children: [
                        _WelcomeSlide(),
                        _LanguageSlide(state: state),
                        _EngineSlide(state: state),
                        _ThemeSlide(state: state),
                        _PermissionsSlide(),
                      ],
                    ),
                  ),
                  _PageDots(
                    count: OnboardingCubit.pageCount,
                    index: state.pageIndex,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        if (state.pageIndex > 0)
                          Expanded(
                            child: AppButton(
                              label: l10n.onboardingBack,
                              variant: AppButtonVariant.text,
                              onPressed: state.saving ? null : cubit.back,
                            ),
                          ),
                        if (state.pageIndex > 0)
                          const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: isLast
                              ? _AllowAndFinishButton(saving: state.saving)
                              : AppButton(
                                  label: l10n.onboardingNext,
                                  icon: Icons.arrow_forward,
                                  expanded: true,
                                  onPressed: cubit.next,
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
      },
    );
  }
}

class _AllowAndFinishButton extends StatelessWidget {
  const _AllowAndFinishButton({required this.saving});

  final bool saving;

  Future<void> _allowAndFinish(BuildContext context) async {
    final cubit = context.read<OnboardingCubit>();
    // Contextual permission priming: request right as the user finishes setup.
    // Recording still re-requests on demand, so a denial is never a dead-end.
    try {
      await Permission.microphone.request();
      await Permission.notification.request();
    } catch (_) {
      // Platform channel may be unavailable; proceed regardless.
    }
    await cubit.finish();
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: context.l10n.onboardingAllowAndFinish,
      icon: Icons.check_circle_outline,
      expanded: true,
      isLoading: saving,
      onPressed: saving ? null : () => _allowAndFinish(context),
    );
  }
}

/// Shared scaffolding for a slide: big icon, title, and slide body, centered and
/// width-clamped, scrollable so it never overflows on short screens.
class _Slide extends StatelessWidget {
  const _Slide({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppLayout.maxFormWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _WelcomeSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Slide(
      icon: Icons.graphic_eq_rounded,
      title: l10n.onboardingWelcomeTitle,
      children: [
        Text(
          l10n.onboardingWelcomeBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _FeatureRow(icon: Icons.mic, label: l10n.onboardingFeatureRecord),
        _FeatureRow(
          icon: Icons.auto_awesome,
          label: l10n.onboardingFeatureSummary,
        ),
        _FeatureRow(
          icon: Icons.forum_outlined,
          label: l10n.onboardingFeatureChat,
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}

class _LanguageSlide extends StatelessWidget {
  const _LanguageSlide({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<OnboardingCubit>();
    return _Slide(
      icon: Icons.translate,
      title: l10n.onboardingLanguageTitle,
      children: [
        _FieldLabel(l10n.language),
        AppSegmentedControl<String>(
          value: state.draft.localePreference,
          segments: [
            AppSegment(value: 'system', label: l10n.system),
            AppSegment(value: 'en', label: l10n.english),
            AppSegment(value: 'tr', label: l10n.turkish),
          ],
          onChanged: cubit.setAppLanguage,
        ),
        const SizedBox(height: AppSpacing.lg),
        _FieldLabel(l10n.transcriptionLanguage),
        AppSegmentedControl<String>(
          value: state.draft.transcriptionLanguage,
          segments: [
            AppSegment(value: 'auto', label: l10n.automatic),
            AppSegment(value: 'tr', label: l10n.turkish),
            AppSegment(value: 'en', label: l10n.english),
          ],
          onChanged: cubit.setTranscriptionLanguage,
        ),
      ],
    );
  }
}

class _EngineSlide extends StatelessWidget {
  const _EngineSlide({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<OnboardingCubit>();
    final selected = state.draft.summaryProvider;
    return _Slide(
      icon: Icons.psychology_outlined,
      title: l10n.aiLocationTitle,
      children: [
        AppSegmentedControl<String>(
          value: selected,
          minSegmentWidth: 132,
          segments: [
            AppSegment(
              value: 'local',
              label: l10n.aiLocationOnDevice,
              icon: Icons.smartphone_outlined,
              enabled: state.deviceSupportsLocal,
            ),
            AppSegment(
              value: 'cloud',
              label: l10n.aiLocationCloud,
              icon: Icons.cloud_outlined,
            ),
          ],
          onChanged: cubit.setSummaryProvider,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          selected == 'local'
              ? l10n.aiLocationOnDeviceDesc
              : l10n.aiLocationCloudDesc,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          state.deviceSupportsLocal
              ? l10n.onboardingRecommended
              : l10n.aiLocationOnDeviceUnavailable,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

class _ThemeSlide extends StatelessWidget {
  const _ThemeSlide({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<OnboardingCubit>();
    return _Slide(
      icon: Icons.palette_outlined,
      title: l10n.onboardingThemeTitle,
      children: [
        AppSegmentedControl<String>(
          value: state.draft.themeMode,
          segments: [
            AppSegment(value: 'system', label: l10n.system),
            AppSegment(value: 'light', label: l10n.light),
            AppSegment(value: 'dark', label: l10n.dark),
          ],
          onChanged: cubit.setThemeMode,
        ),
      ],
    );
  }
}

class _PermissionsSlide extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _Slide(
      icon: Icons.shield_outlined,
      title: l10n.onboardingPermissionsTitle,
      children: [
        AppCard(
          child: Text(
            l10n.onboardingPermissionsBody,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppMotion.fast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
          ),
      ],
    );
  }
}
