import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/services/auth/auth_service.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';
import 'package:voicescribe_mobile/shared/theme/app_theme.dart';
import 'package:voicescribe_mobile/shared/utils/env_config.dart';
import 'package:voicescribe_mobile/shared/widgets/app_button.dart';
import 'package:voicescribe_mobile/shared/widgets/app_card.dart';
import 'package:voicescribe_mobile/shared/widgets/app_page.dart';
import 'package:voicescribe_mobile/shared/widgets/app_section.dart';
import 'package:voicescribe_mobile/shared/widgets/app_text_field.dart';
import 'package:voicescribe_mobile/shared/widgets/premium_widgets.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final app = ref.watch(appControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.authTitle),
        bottom: app.isAuthenticated
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(58),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: AppSurface(
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: l10n.login),
                        Tab(text: l10n.register),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      body: SafeArea(
        child: app.isAuthenticated
            ? _AuthenticatedView(
                app: app,
                onLogout: _logout,
                onRetryModelSetup: _retryModelSetup,
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _AuthForm(
                    emailController: _loginEmailController,
                    passwordController: _loginPasswordController,
                    submitting: _submitting,
                    error: _error,
                    buttonLabel: l10n.login,
                    onSubmit: _login,
                    showPassword: !EnvConfig.isTestEnvironment,
                  ),
                  _AuthForm(
                    emailController: _registerEmailController,
                    passwordController: _registerPasswordController,
                    submitting: _submitting,
                    error: _error,
                    buttonLabel: l10n.register,
                    onSubmit: _register,
                    showPassword: !EnvConfig.isTestEnvironment,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _login() async {
    await _submit(() async {
      await ref
          .read(appControllerProvider)
          .login(
            email: _loginEmailController.text.trim(),
            password: EnvConfig.isTestEnvironment
                ? 'debug'
                : _loginPasswordController.text,
          );
    });
  }

  Future<void> _register() async {
    await _submit(() async {
      await ref
          .read(appControllerProvider)
          .register(
            email: _registerEmailController.text.trim(),
            password: EnvConfig.isTestEnvironment
                ? 'debug'
                : _registerPasswordController.text,
          );
    });
  }

  Future<void> _logout() async {
    await _submit(() async {
      await ref.read(appControllerProvider).logout();
    });
  }

  Future<void> _retryModelSetup() async {
    await _submit(() async {
      await ref.read(appControllerProvider).ensureModelReady();
    });
  }

  Future<void> _submit(Future<void> Function() action) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      setState(() {
        _error = _localizedError(context, error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String _localizedError(BuildContext context, Object error) {
    if (error is VoiceScribeAuthException) {
      return error.message;
    }
    return error.toString();
  }
}

class _AuthForm extends StatelessWidget {
  const _AuthForm({
    required this.emailController,
    required this.passwordController,
    required this.submitting,
    required this.error,
    required this.buttonLabel,
    required this.onSubmit,
    this.showPassword = true,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool submitting;
  final String? error;
  final String buttonLabel;
  final Future<void> Function() onSubmit;
  final bool showPassword;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppPageListView(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      children: [
        AppSectionCard(
          title: buttonLabel,
          subtitle: l10n.authTitle,
          children: [
            AppTextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              labelText: l10n.email,
              prefixIcon: Icons.alternate_email,
            ),
            const SizedBox(height: AppSpacing.md),
            if (showPassword) ...[
              AppTextField(
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) async {
                  if (!submitting) {
                    await onSubmit();
                  }
                },
                labelText: l10n.password,
                prefixIcon: Icons.lock_outline,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (!showPassword) const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: buttonLabel,
              icon: Icons.login,
              onPressed: onSubmit,
              isLoading: submitting,
              expanded: true,
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppErrorText(message: error!),
            ],
          ],
        ),
      ],
    );
  }
}

class _AuthenticatedView extends StatelessWidget {
  const _AuthenticatedView({
    required this.app,
    required this.onLogout,
    required this.onRetryModelSetup,
  });

  final AppController app;
  final Future<void> Function() onLogout;
  final Future<void> Function() onRetryModelSetup;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppPageListView(
      children: [
        if (!app.isModelReady)
          _ModelSetupCard(app: app, onRetry: onRetryModelSetup),
        if (!app.isModelReady) const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.logout,
          icon: Icons.logout,
          onPressed: onLogout,
          variant: AppButtonVariant.text,
        ),
      ],
    );
  }
}

class _ModelSetupCard extends StatelessWidget {
  const _ModelSetupCard({required this.app, required this.onRetry});

  final AppController app;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final progress = app.downloadProgress;
    final percent = progress?.percent;
    final isFailed = app.modelState == ModelBootstrapState.failed;

    return AppSectionCard(
      title: l10n.modelSetupRequired,
      children: [
        Text(
          isFailed ? l10n.modelDownloadFailed : l10n.modelSetupContinueMessage,
        ),
        const SizedBox(height: AppSpacing.md),
        LinearProgressIndicator(value: percent == null ? null : percent / 100),
        const SizedBox(height: AppSpacing.sm),
        Text(
          percent == null
              ? l10n.modelDownloading
              : l10n.modelDownloadingPercent(percent.floor()),
        ),
        if (isFailed) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.retrySetup,
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
        if (app.bootstrapError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppErrorText(message: app.bootstrapError!),
        ],
      ],
    );
  }
}
