import 'package:flutter/material.dart';

import '../utils/turkish_text.dart';
import 'theme.dart';
import 'tokens.dart';

/// Büyük harfli, monospace teknik etiket.
class TechLabel extends StatelessWidget {
  const TechLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      turkishUpperCase(text),
      style: context.text.label.copyWith(color: color),
    );
  }
}

/// İçerik gelene kadar yerini tutan soluk blok.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({super.key, this.height});

  /// Verilmezse bulunduğu alanı doldurur.
  final double? height;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: NayaMotion.slow * 2,
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Yükleniyor',
      child: FadeTransition(
        opacity: _pulse,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: context.colors.surfaceRaised,
            borderRadius: const BorderRadius.all(NayaRadius.md),
          ),
        ),
      ),
    );
  }
}

/// Listede gösterilecek bir şey olmadığında ya da yükleme başarısız olduğunda
/// çıkan ortalanmış mesaj.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: NayaSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 28, color: c.textMuted),
              const SizedBox(height: NayaSpace.md),
              Text(
                title,
                style: context.text.heading,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NayaSpace.xs),
              Text(
                message,
                style: context.text.small,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: NayaSpace.lg),
                PrimaryButton(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bölüm başlığı: solda etiket ve başlık, sağda isteğe bağlı bir öğe.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    required this.title,
    this.trailing,
  });

  final String label;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TechLabel(label),
              const SizedBox(height: NayaSpace.xs),
              Text(title, style: context.text.heading),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Olasılık çubuğu. En olası aday vurgu rengiyle, diğerleri platinle.
class ProbabilityBar extends StatelessWidget {
  const ProbabilityBar({
    super.key,
    required this.value,
    this.emphasized = false,
  });

  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: const BorderRadius.all(NayaRadius.pill),
      child: Container(
        height: 4,
        color: c.line,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          heightFactor: 1,
          child: ColoredBox(color: emphasized ? c.accent : c.textMuted),
        ),
      ),
    );
  }
}

/// 1-5 arası önem derecesi; 4 ve üstü uyarı rengiyle.
class SeverityMeter extends StatelessWidget {
  const SeverityMeter(this.level, {super.key});

  final int level;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final active = level >= 4 ? c.danger : c.platinum;
    return Semantics(
      label: 'Önem $level / 5',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            Container(
              width: 3,
              height: 6.0 + i * 2,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: i <= level ? active : c.line,
                borderRadius: const BorderRadius.all(Radius.circular(1)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Kenarlıklı yüzey. Kartların ve panellerin ortak kabı.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(NayaSpace.lg),
    this.raised = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: raised ? c.surfaceRaised : c.surface,
        borderRadius: const BorderRadius.all(NayaRadius.md),
        border: Border.all(color: c.line),
      ),
      child: child,
    );
  }
}

/// Yuvarlak, kenarlıklı ikon düğmesi. Viewer kontrolleri ve üst çubuk için.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? c.accent : c.surface.withValues(alpha: 0.72),
        shape: CircleBorder(side: BorderSide(color: c.line)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(icon, size: 20, color: selected ? c.onAccent : c.text),
          ),
        ),
      ),
    );
  }
}

/// Ana eylem düğmesi.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? null : Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        minimumSize: const Size.fromHeight(52),
        textStyle: context.text.body.copyWith(fontWeight: FontWeight.w600),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(NayaRadius.md),
        ),
      ),
    );
  }
}

/// Kısa öneri ya da filtre çipi.
class SuggestionChip extends StatelessWidget {
  const SuggestionChip(this.label, {super.key, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: c.lineStrong)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: NayaSpace.md,
            vertical: NayaSpace.sm,
          ),
          child: Text(label, style: context.text.small.copyWith(color: c.text)),
        ),
      ),
    );
  }
}
