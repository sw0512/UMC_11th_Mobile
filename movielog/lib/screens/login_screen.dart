import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/sign_up_view_model.dart';
import '../services/email_preference.dart';
import '../widgets/movielog_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthViewModel _auth;
  bool _remember = false;
  bool _preferencesLoading = true;
  bool _submitting = false;
  String? _preferenceError;
  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthViewModel>();
    _auth.addListener(_expired);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _expired();
    });
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    try {
      final email = await context.read<EmailPreference>().read();
      if (!mounted) return;
      _email.text = email ?? '';
      _remember = email != null;
    } catch (_) {
      _preferenceError = '저장한 이메일을 읽지 못했어요.';
    }
    if (mounted) setState(() => _preferencesLoading = false);
  }

  void _expired() {
    if (!mounted || !_auth.sessionExpired) return;
    _auth.consumeSessionExpired();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('로그인이 만료됐어요. 다시 로그인해 주세요.')),
          );
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await context.read<EmailPreference>().save(
        _remember ? _email.text : null,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _preferenceError = '이메일 저장에 실패했어요. 로그인은 계속할 수 있어요.');
      }
    }
    if (!mounted) return;
    await _auth.login(_email.text, _password.text);
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final loading = _submitting || auth.status == AuthStatus.authenticating;
    final enabled =
        !loading &&
        !_preferencesLoading &&
        !auth.storageCleanupInProgress &&
        !auth.storageCleanupFailed;
    return PopScope(
      canPop: !loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('로그인'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  SvgPicture.asset(
                    'assets/logos/movielog_logo.svg',
                    width: 84,
                    height: 84,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MovieLog에 로그인',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    key: const Key('login-email'),
                    controller: _email,
                    enabled: enabled,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: '이메일'),
                    validator: SignUpViewModel.validateEmail,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    key: const Key('login-password'),
                    controller: _password,
                    enabled: enabled,
                    obscureText: true,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: '비밀번호'),
                    validator: (v) =>
                        v == null || v.isEmpty ? '비밀번호를 입력해 주세요.' : null,
                    onFieldSubmitted: (_) {
                      if (enabled) _submit();
                    },
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('이메일 저장'),
                    value: _remember,
                    onChanged: enabled
                        ? (v) => setState(() => _remember = v!)
                        : null,
                  ),
                  if (_preferenceError != null) Text(_preferenceError!),
                  if (auth.message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        auth.message!,
                        key: const Key('login-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (auth.storageCleanupFailed)
                    TextButton(
                      onPressed: auth.retryStorageCleanup,
                      child: const Text('저장소 정리 다시 시도'),
                    ),
                  const SizedBox(height: 32),
                  MovieLogButton(
                    label: '로그인',
                    isLoading: loading,
                    width: double.infinity,
                    onPressed: enabled ? _submit : null,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: enabled ? () => context.push('/register') : null,
                    child: const Text('회원가입'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _auth.removeListener(_expired);
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
