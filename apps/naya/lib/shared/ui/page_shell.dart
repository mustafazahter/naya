import 'package:flutter/material.dart';

import 'components.dart';
import 'theme.dart';
import 'tokens.dart';

/// Ayarlar, giriş ve geçmiş gibi metin ağırlıklı sayfaların iskeleti:
/// geri düğmesi, küçük etiket, büyük başlık ve ortalanmış dar bir sütun.
/// Üst kısım parça sayfasıyla aynı dili konuşur.
class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.label,
    required this.title,
    required this.children,
    this.intro,
    this.onBack,
  });

  final String label;
  final String title;
  final String? intro;
  final List<Widget> children;

  /// Verilmezse bir önceki sayfaya döner.
  final VoidCallback? onBack;

  static const maxWidth = 640.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [c.viewportTop, c.background],
          ),
        ),
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              NayaSpace.gutter,
              NayaSpace.md,
              NayaSpace.gutter,
              NayaSpace.xxxl,
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: RoundIconButton(
                          icon: Icons.arrow_back,
                          tooltip: 'Geri',
                          onPressed:
                              onBack ?? () => Navigator.of(context).maybePop(),
                        ),
                      ),
                      SizedBox(height: wide ? NayaSpace.xxxl : NayaSpace.xl),
                      TechLabel(label, color: c.accent),
                      const SizedBox(height: NayaSpace.sm),
                      Text(
                        title,
                        style: context.text.display.copyWith(
                          fontSize: wide ? 48 : 36,
                          height: 1.04,
                          letterSpacing: wide ? -1.4 : -0.9,
                          color: c.text,
                        ),
                      ),
                      if (intro != null) ...[
                        const SizedBox(height: NayaSpace.md),
                        Text(intro!, style: context.text.body),
                      ],
                      SizedBox(height: wide ? NayaSpace.xxl : NayaSpace.xl),
                      ...children,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uygulamanın her yerinde aynı görünen metin kutusu.
class NayaTextField extends StatelessWidget {
  const NayaTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.enabled = true,
    this.suffix,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(NayaRadius.md),
      borderSide: BorderSide(color: color),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TechLabel(label),
        const SizedBox(height: NayaSpace.xs + 2),
        TextField(
          controller: controller,
          obscureText: obscure,
          enabled: enabled,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autocorrect: false,
          enableSuggestions: !obscure,
          style: context.text.body.copyWith(color: c.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: context.text.body.copyWith(color: c.textMuted),
            filled: true,
            fillColor: c.surface,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: NayaSpace.lg,
              vertical: NayaSpace.md + 2,
            ),
            border: border(c.lineStrong),
            enabledBorder: border(c.lineStrong),
            disabledBorder: border(c.line),
            focusedBorder: border(c.accent),
          ),
        ),
      ],
    );
  }
}
