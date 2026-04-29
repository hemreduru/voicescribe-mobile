import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voicescribe_mobile/shared/i18n/l10n.dart';
import 'package:voicescribe_mobile/shared/services/auth/auth_service.dart';
import 'package:voicescribe_mobile/shared/state/app_controller.dart';

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
            : TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.login),
                  Tab(text: l10n.register),
                ],
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
                  ),
                  _AuthForm(
                    emailController: _registerEmailController,
                    passwordController: _registerPasswordController,
                    submitting: _submitting,
                    error: _error,
                    buttonLabel: l10n.register,
                    onSubmit: _register,
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
            password: _loginPasswordController.text,
          );
    });
  }

  Future<void> _register() async {
    await _submit(() async {
      await ref
          .read(appControllerProvider)
          .register(
            email: _registerEmailController.text.trim(),
            password: _registerPasswordController.text,
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
    final l10n = context.l10n;
    if (error is RegistrationPendingVerificationException) {
      return l10n.authVerifyEmail;
    }
    if (error is AuthException) {
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
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool submitting;
  final String? error;
  final String buttonLabel;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l10n.email),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: l10n.password),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: submitting ? null : onSubmit,
          icon: submitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login),
          label: Text(buttonLabel),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.account_circle),
          title: Text(l10n.authenticatedUser),
          subtitle: Text(app.currentUserEmail ?? '-'),
        ),
        const SizedBox(height: 16),
        if (!app.isModelReady)
          _ModelSetupCard(app: app, onRetry: onRetryModelSetup),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout),
          label: Text(l10n.logout),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.modelSetupRequired,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isFailed
                  ? l10n.modelDownloadFailed
                  : l10n.modelSetupContinueMessage,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: percent == null ? null : percent / 100,
            ),
            const SizedBox(height: 8),
            Text(
              percent == null
                  ? l10n.modelDownloading
                  : l10n.modelDownloadingPercent(percent.floor()),
            ),
            if (isFailed) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retrySetup),
              ),
            ],
            if (app.bootstrapError != null) ...[
              const SizedBox(height: 8),
              Text(
                app.bootstrapError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
