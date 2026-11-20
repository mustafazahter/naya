import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sign_in/sign_in.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/page_shell.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Giriş ve kayıt. Misafir kütüphaneyi gezer; yapay zekâ, geçmiş ve kendi
/// dosyaları için hesap gerekir. Başarılı olunca [onDone].
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _register = false;
  var _busy = false;
  var _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    if (email.isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'E-posta ve şifreyi yaz.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await signIn(
        ref,
        email: email,
        password: _password.text,
        register: _register,
      );
      if (!mounted) return;
      TextInput.finishAutofillContext();
      widget.onDone();
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = signInErrorText(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PageShell(
      label: _register ? 'Yeni hesap' : 'Hesap',
      title: _register ? 'Hesap aç' : 'Giriş yap',
      intro:
          'Yapay zekâ teşhisi, sohbet geçmişi ve kendi dosyaların için '
          'hesap gerekiyor. Şablonları giriş yapmadan da gezebilirsin.',
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NayaTextField(
                controller: _email,
                label: 'E-posta',
                hint: 'ad@ornek.com',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                enabled: !_busy,
              ),
              const SizedBox(height: NayaSpace.lg),
              NayaTextField(
                controller: _password,
                label: 'Şifre',
                hint: _register ? 'En az 8 karakter' : null,
                obscure: !_showPassword,
                autofillHints: [
                  _register
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                enabled: !_busy,
                suffix: IconButton(
                  tooltip: _showPassword ? 'Şifreyi gizle' : 'Şifreyi göster',
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: c.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: NayaMotion.base,
          curve: NayaMotion.decelerate,
          child: _error == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: NayaSpace.md),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.error_outline, size: 18, color: c.danger),
                      const SizedBox(width: NayaSpace.sm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: context.text.small.copyWith(color: c.text),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: NayaSpace.xl),
        PrimaryButton(
          label: _busy
              ? 'Bekle…'
              : _register
              ? 'Hesap aç'
              : 'Giriş yap',
          icon: _register ? Icons.person_add_alt : Icons.login,
          onPressed: _busy ? null : _submit,
        ),
        const SizedBox(height: NayaSpace.md),
        Center(
          child: TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _register = !_register;
                    _error = null;
                  }),
            child: Text(
              _register
                  ? 'Hesabın var mı? Giriş yap'
                  : 'Hesabın yok mu? Hesap aç',
              style: context.text.body.copyWith(color: c.accent),
            ),
          ),
        ),
      ],
    );
  }
}
