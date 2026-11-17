import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../view_models/auth_view_model.dart';
import '../view_models/edit_profile_view_model.dart';
import '../widgets/movielog_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final String _original;
  late final TextEditingController _nickname;
  bool _allowPop = false;
  bool _confirming = false;
  bool get _dirty => _nickname.text.trim() != _original;
  @override
  void initState() {
    super.initState();
    _original = context.read<AuthViewModel>().member!.nickname;
    _nickname = TextEditingController(text: _original);
    _nickname.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _leave() async {
    if (_confirming ||
        context.read<EditProfileViewModel>().status ==
            EditProfileStatus.saving) {
      return;
    }
    if (_dirty) {
      _confirming = true;
      final discard = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('변경 내용을 버릴까요?'),
          content: const Text('저장하지 않은 닉네임이 있어요.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 수정'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('나가기'),
            ),
          ],
        ),
      );
      _confirming = false;
      if (discard != true || !mounted) return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/my');
      }
    }
  }

  Future<void> _save() async {
    final vm = context.read<EditProfileViewModel>();
    final success = await vm.save(_nickname.text);
    if (!mounted) return;
    if (success) {
      setState(() => _allowPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('프로필을 수정했어요.')));
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/my');
      }
    } else if (vm.message != null) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(vm.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditProfileViewModel>();
    final saving = vm.status == EditProfileStatus.saving;
    return PopScope(
      canPop: _allowPop || (!_dirty && !saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('프로필 수정'),
          centerTitle: true,
          leading: IconButton(
            onPressed: saving ? null : _leave,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextFormField(
                initialValue: context.read<AuthViewModel>().member?.email,
                enabled: false,
                decoration: const InputDecoration(labelText: '이메일'),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('profile-nickname'),
                controller: _nickname,
                enabled: !saving,
                maxLength: 12,
                decoration: InputDecoration(
                  labelText: '닉네임',
                  errorText: vm.nicknameError,
                ),
              ),
              const SizedBox(height: 40),
              MovieLogButton(
                label: '저장',
                isLoading: saving,
                onPressed: saving ? null : _save,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nickname.removeListener(_changed);
    _nickname.dispose();
    super.dispose();
  }
}
