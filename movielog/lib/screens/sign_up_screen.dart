import 'package:flutter/material.dart';

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

  String? validateNickname(String? value) {
    final nickname = value?.trim() ?? '';

    if (nickname.isEmpty) {
      return '닉네임을 입력해주세요.';
    }

    if (nickname.length < 2) {
      return '닉네임은 2자 이상이어야 합니다.';
    }

    return null;
  }

  String? validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return '이메일을 입력해주세요.';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      return '올바른 이메일 형식이 아닙니다.';
    }

    return null;
  }

  String? validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }

    if (password.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }

    return null;
  }

  bool get canSubmit {
    return validateNickname(nicknameController.text) == null &&
        validateEmail(emailController.text) == null &&
        validatePassword(passwordController.text) == null &&
        agreedToTerms;
  }

  void submit() {
    final isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    FocusScope.of(context).unfocus();

    // 2주차에서는 실제 API를 연결하지 않음
    debugPrint('회원가입 Form 검증 성공');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: CommonAppBar(
        title: '회원가입',
        centerTitle: true,
        onBack: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        titleStyle: AppTextStyles.titleLarge.copyWith(color: AppColors.violet),
      ),
      body: SafeArea(
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

                              SignUpField(
                                label: '닉네임',
                                hintText: '닉네임을 입력해주세요',
                                controller: nicknameController,
                                validator: validateNickname,
                                touched: nicknameTouched,
                                onChanged: (_) {
                                  setState(() {
                                    nicknameTouched = true;
                                  });
                                },
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) {
                                  emailFocusNode.requestFocus();
                                },
                              ),

                              const SizedBox(height: 16),

                              SignUpField(
                                label: '이메일',
                                hintText: '이메일 주소를 입력해주세요',
                                controller: emailController,
                                focusNode: emailFocusNode,
                                validator: validateEmail,
                                touched: emailTouched,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) {
                                  setState(() {
                                    emailTouched = true;
                                  });
                                },
                                onFieldSubmitted: (_) {
                                  passwordFocusNode.requestFocus();
                                },
                              ),

                              const SizedBox(height: 16),

                              SignUpField(
                                label: '비밀번호',
                                hintText: '비밀번호를 입력해주세요',
                                controller: passwordController,
                                focusNode: passwordFocusNode,
                                validator: validatePassword,
                                touched: passwordTouched,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) {
                                  setState(() {
                                    passwordTouched = true;
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
    );
  }

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
