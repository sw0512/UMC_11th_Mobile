import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/sign_up_view_model.dart';
import '../widgets/movielog_button.dart';
import '../data/models/create_member_request.dart';
import '../view_models/learning_member_session.dart';
import '../view_models/submit_status.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/sign_up/login_guide.dart';
import '../widgets/sign_up/sign_up_field.dart';
import '../widgets/sign_up/sign_up_intro.dart';
import '../widgets/sign_up/terms_and_submit_section.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();

  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool agreedToTerms = false;

  bool nicknameTouched = false;
  bool emailTouched = false;
  bool passwordTouched = false;

  String? validateNickname(String? value) =>
      SignUpViewModel.validateNickname(value);
  String? validateEmail(String? value) => SignUpViewModel.validateEmail(value);

  String? validatePassword(String? value) =>
      SignUpViewModel.validatePassword(value);

  bool get canSubmit {
    return validateNickname(nicknameController.text) == null &&
        validateEmail(emailController.text) == null &&
        validatePassword(passwordController.text) == null &&
        agreedToTerms &&
        context.read<SignUpViewModel>().checksAvailable &&
        !context.read<SignUpViewModel>().isSubmitting;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false) || !canSubmit) return;
    FocusScope.of(context).unfocus();
    final vm = context.read<SignUpViewModel>();
    await vm.submit(
      CreateMemberRequest(
        email: emailController.text,
        password: passwordController.text,
        nickname: nicknameController.text,
      ),
    );
    if (!mounted) return;
    if (vm.submitStatus == SubmitStatus.success && vm.createdMemberId != null) {
      context.read<LearningMemberSession>().setMemberId(vm.createdMemberId!);
      passwordController.clear();
      context.go('/movies');
    } else if (vm.snackbarMessage != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(vm.snackbarMessage!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SignUpViewModel>();
    return PopScope(
      canPop: !viewModel.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.warmWhite,
        appBar: CommonAppBar(
          title: '회원가입',
          centerTitle: true,
          onBack: () {
            if (viewModel.isSubmitting) return;
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          titleStyle: AppTextStyles.titleLarge.copyWith(
            color: AppColors.violet,
          ),
        ),
        body: AbsorbPointer(
          absorbing: viewModel.isSubmitting,
          child: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxFormWidth = constraints.maxWidth >= 700
                    ? 560.0
                    : double.infinity;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxFormWidth),
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: IntrinsicHeight(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                            child: Form(
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SignUpIntro(),

                                  const SizedBox(height: 48),

                                  _checkedField(
                                    field: MovieLogTextFormField(
                                      label: '닉네임',
                                      serverErrorText:
                                          viewModel.nicknameErrorText,
                                      serverAvailable:
                                          viewModel.nicknameCheckStatus ==
                                          CheckStatus.available,
                                      hintText: '닉네임을 입력해주세요',
                                      controller: nicknameController,
                                      validator: validateNickname,
                                      touched: nicknameTouched,
                                      onChanged: (value) {
                                        viewModel.onNicknameChanged(value);
                                        setState(() {
                                          nicknameTouched = true;
                                        });
                                      },
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) {
                                        emailFocusNode.requestFocus();
                                      },
                                    ),
                                    label: '닉네임',
                                    status: viewModel.nicknameCheckStatus,
                                    canCheck: viewModel.canCheckNickname,
                                    onCheck: () => viewModel.checkNickname(
                                      nicknameController.text,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  _checkedField(
                                    field: MovieLogTextFormField(
                                      label: '이메일',
                                      serverErrorText: viewModel.emailErrorText,
                                      serverAvailable:
                                          viewModel.emailCheckStatus ==
                                          CheckStatus.available,
                                      hintText: '이메일 주소를 입력해주세요',
                                      controller: emailController,
                                      focusNode: emailFocusNode,
                                      validator: validateEmail,
                                      touched: emailTouched,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (value) {
                                        viewModel.onEmailChanged(value);
                                        setState(() {
                                          emailTouched = true;
                                        });
                                      },
                                      onFieldSubmitted: (_) {
                                        passwordFocusNode.requestFocus();
                                      },
                                    ),
                                    label: '이메일',
                                    status: viewModel.emailCheckStatus,
                                    canCheck: viewModel.canCheckEmail,
                                    onCheck: () => viewModel.checkEmail(
                                      emailController.text,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  MovieLogTextFormField(
                                    label: '비밀번호',
                                    serverErrorText:
                                        viewModel.passwordErrorText,
                                    hintText: '비밀번호를 입력해주세요',
                                    controller: passwordController,
                                    focusNode: passwordFocusNode,
                                    validator: validatePassword,
                                    touched: passwordTouched,
                                    obscureText: true,
                                    enableObscureTextToggle: true,
                                    textInputAction: TextInputAction.done,
                                    onChanged: (_) {
                                      setState(() {
                                        passwordTouched = true;
                                        viewModel.onPasswordChanged();
                                      });
                                    },
                                    onFieldSubmitted: (_) {
                                      passwordFocusNode.unfocus();
                                    },
                                  ),

                                  const Spacer(),

                                  const SizedBox(height: 32),

                                  TermsAndSubmitSection(
                                    agreedToTerms: agreedToTerms,
                                    canSubmit: canSubmit,
                                    isSubmitting: viewModel.isSubmitting,
                                    onTermsChanged: (value) {
                                      setState(() {
                                        agreedToTerms = value ?? false;
                                      });
                                    },
                                    onSubmit: submit,
                                  ),

                                  const SizedBox(height: 24),

                                  const LoginGuide(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkedField({
    required Widget field,
    required String label,
    required CheckStatus status,
    required bool canCheck,
    required VoidCallback onCheck,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: field),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: MovieLogButton(
              label: '중복 확인',
              isLoading: status == CheckStatus.checking,
              onPressed: canCheck ? onCheck : null,
            ),
          ),
        ],
      ),
      if (status == CheckStatus.available)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '사용할 수 있는 $label입니다.',
            style: const TextStyle(color: Colors.green, fontSize: 12),
          ),
        ),
      if (status == CheckStatus.checking)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '$label 사용 가능 여부를 확인 중입니다.',
            style: const TextStyle(color: Colors.blue, fontSize: 12),
          ),
        ),
    ],
  );

  @override
  void dispose() {
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();

    emailFocusNode.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }
}
