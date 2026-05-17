import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:voicescribe_mobile/data/services/whisper_service.dart';
import 'package:voicescribe_mobile/ui/core/i18n/l10n.dart';
import 'package:voicescribe_mobile/ui/core/theme/app_theme.dart';
import 'package:voicescribe_mobile/ui/core/utils/model_download_formatters.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_button.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_card.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_page.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_section.dart';
import 'package:voicescribe_mobile/ui/core/widgets/app_text_field.dart';
import 'package:voicescribe_mobile/ui/core/widgets/premium_widgets.dart';
import 'package:voicescribe_mobile/ui/features/auth/bloc/auth_bloc.dart';
import 'package:voicescribe_mobile/ui/features/bootstrap/bloc/bootstrap_bloc.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

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

    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.isAuthenticated != current.isAuthenticated ||
          previous.errorMessage != current.errorMessage ||
          previous.passwordlessDebugAuth != current.passwordlessDebugAuth,
      builder: (context, authState) {
        final submitting = authState.status == AuthStatus.submitting;
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.authTitle),
            bottom: authState.isAuthenticated
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
            child: authState.isAuthenticated
                ? _AuthenticatedView(submitting: submitting)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _AuthForm(
                        emailController: _loginEmailController,
                        passwordController: _loginPasswordController,
                        submitting: submitting,
                        error: authState.errorMessage,
                        buttonLabel: l10n.login,
                        onSubmit: _login,
                        showPassword: !authState.passwordlessDebugAuth,
                      ),
                      _AuthForm(
                        emailController: _registerEmailController,
                        passwordController: _registerPasswordController,
                        submitting: submitting,
                        error: authState.errorMessage,
                        buttonLabel: l10n.register,
                        onSubmit: _register,
                        showPassword: !authState.passwordlessDebugAuth,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _login() {
    context.read<AuthBloc>().add(
      AuthLoginSubmitted(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      ),
    );
  }

  void _register() {
    context.read<AuthBloc>().add(
      AuthRegisterSubmitted(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      ),
    );
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
  final VoidCallback onSubmit;
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
                onSubmitted: (_) {
                  if (!submitting) {
                    onSubmit();
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
  const _AuthenticatedView({required this.submitting});

  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isReady = context.select<BootstrapBloc, bool>(
      (bloc) => bloc.state.isReady,
    );
    final modelState = context.select<BootstrapBloc, ModelBootstrapState>(
      (bloc) => bloc.state.modelState,
    );
    final downloadProgress = context.select<BootstrapBloc, ModelDownloadProgress?>(
      (bloc) => bloc.state.downloadProgress,
    );
    final bootstrapError = context.select<BootstrapBloc, String?>(
      (bloc) => bloc.state.errorMessage,
    );

    return AppPageListView(
      children: [
        if (!isReady) _ModelSetupCard(
          state: modelState,
          progress: downloadProgress,
          error: bootstrapError,
        ),
        if (!isReady) const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.logout,
          icon: Icons.logout,
          onPressed: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
          variant: AppButtonVariant.text,
          isLoading: submitting,
        ),
      ],
    );
  }
}

class _ModelSetupCard extends StatelessWidget {
  const _ModelSetupCard({
    required this.state,
    required this.progress,
    this.error,
  });

  final ModelBootstrapState state;
  final ModelDownloadProgress? progress;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final percent = progress?.percent;
    final isFailed = state == ModelBootstrapState.failed;

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
          progress == null
              ? l10n.modelDownloading
              : formatModelDownloadProgress(l10n, progress!),
        ),
        if (isFailed) ...[
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.retrySetup,
            icon: Icons.refresh,
            onPressed: () =>
                context.read<BootstrapBloc>().add(const BootstrapRetried()),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          AppErrorText(message: error!),
        ],
      ],
    );
  }
}
