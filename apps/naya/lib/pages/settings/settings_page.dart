import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/session/session.dart';
import '../../features/ai_settings/ai_settings.dart';
import '../../features/sign_in/sign_in.dart';
import '../../shared/api/api_client.dart';
import '../../shared/ui/components.dart';
import '../../shared/ui/page_shell.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

/// Ayarlar: hesap, OpenRouter anahtarı ve modellerin görevleri.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final account = session.value;
    return PageShell(
      label: 'Ayarlar',
      title: 'Hesap ve yapay zekâ',
      children: [
        _Section(
          number: 1,
          title: 'Hesap',
          child: switch (session) {
            AsyncLoading() => const SkeletonBlock(height: 72),
            _ when account == null => _GuestCard(onSignIn: onSignIn),
            _ => _AccountCard(account: account),
          },
        ),
        if (account != null) ...[
          const _Section(
            number: 2,
            title: 'OpenRouter anahtarı',
            child: _KeyCard(),
          ),
          const _Section(number: 3, title: 'Modeller', child: _RolesCard()),
        ],
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: NayaSpace.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                number.toString().padLeft(2, '0'),
                style: context.text.mono.copyWith(color: c.accent),
              ),
              const SizedBox(width: NayaSpace.md),
              Text(title, style: context.text.heading),
            ],
          ),
          const SizedBox(height: NayaSpace.md),
          child,
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Misafir olarak geziyorsun. Yapay zekâ için önce giriş yap; '
            'anahtarını ve model seçimini hesabına kaydederiz.',
            style: context.text.body,
          ),
          const SizedBox(height: NayaSpace.lg),
          PrimaryButton(
            label: 'Giriş yap',
            icon: Icons.login,
            onPressed: onSignIn,
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Panel(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: c.accent,
            child: Text(
              account.initial,
              style: context.text.body.copyWith(
                color: c.onAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: NayaSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.email,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.body.copyWith(color: c.text),
                ),
                const SizedBox(height: 2),
                TechLabel(account.isAdmin ? 'Yönetici' : 'Kullanıcı'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => signOut(ref),
            child: Text(
              'Çıkış yap',
              style: context.text.small.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Anahtar girişi. Kayıtlıysa yalnız son dört hanesi görünür; yenisi
/// yazılırsa eskisinin yerine geçer.
class _KeyCard extends ConsumerStatefulWidget {
  const _KeyCard();

  @override
  ConsumerState<_KeyCard> createState() => _KeyCardState();
}

class _KeyCardState extends ConsumerState<_KeyCard> {
  final _key = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      _key.clear();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(done)));
    } on Object catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e is ApiException ? e.message : 'Bir sorun oluştu.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final status = ref.watch(keyStatusProvider);
    return Panel(
      child: switch (status) {
        AsyncError(:final error) => Text(
          error is ApiException ? error.message : 'Anahtar durumu okunamadı.',
          style: context.text.body,
        ),
        AsyncData(:final value) when !value.configured => Text(
          'Sunucuda yapay zekâ kapalı (NAYA_MASTER_KEY tanımlı değil). '
          'Anahtar saklanamıyor.',
          style: context.text.body,
        ),
        AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  value.hasKey ? Icons.verified_outlined : Icons.key_outlined,
                  size: 18,
                  color: value.hasKey ? c.accent : c.textMuted,
                ),
                const SizedBox(width: NayaSpace.sm),
                Expanded(
                  child: Text(
                    value.hasKey
                        ? 'Kayıtlı anahtar ${value.hint ?? ''}'
                              '${value.updatedAt == null ? '' : ' · ${_date(value.updatedAt!)}'}'
                        : 'Henüz anahtar yok.',
                    style: context.text.body.copyWith(color: c.text),
                  ),
                ),
                if (value.hasKey)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () =>
                              _run(() => deleteApiKey(ref), 'Anahtar silindi.'),
                    child: Text(
                      'Sil',
                      style: context.text.small.copyWith(color: c.danger),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: NayaSpace.lg),
            NayaTextField(
              controller: _key,
              label: value.hasKey ? 'Yeni anahtar' : 'Anahtar',
              hint: 'sk-or-v1-…',
              obscure: true,
              enabled: !_busy,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: NayaSpace.sm),
            Text(
              'openrouter.ai/keys sayfasından alınır. Sunucu OpenRouter’a '
              'sorup doğrular, şifreleyip saklar; anahtar bir daha '
              'gösterilmez.',
              style: context.text.small,
            ),
            if (_error != null) ...[
              const SizedBox(height: NayaSpace.md),
              Text(
                _error!,
                style: context.text.small.copyWith(color: c.danger),
              ),
            ],
            const SizedBox(height: NayaSpace.lg),
            PrimaryButton(
              label: _busy ? 'Doğrulanıyor…' : 'Kaydet',
              icon: Icons.check,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
        _ => const SkeletonBlock(height: 120),
      },
    );
  }

  void _save() {
    final key = _key.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Anahtarı yapıştır.');
      return;
    }
    _run(() => saveApiKey(ref, key), 'Anahtar doğrulandı ve kaydedildi.');
  }

  static String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';
}

/// Her görev için seçili model; dokununca liste açılır.
class _RolesCard extends ConsumerWidget {
  const _RolesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final roles = ref.watch(aiRolesProvider);
    final models = ref.watch(aiModelsProvider);
    if (roles case AsyncError(:final error)) {
      return Panel(
        child: Text(
          error is ApiException ? error.message : 'Modeller okunamadı.',
          style: context.text.body,
        ),
      );
    }
    final selected = roles.value;
    if (selected == null) return const SkeletonBlock(height: 140);
    final list = models.value ?? const <AiModel>[];
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, role) in AiRole.values.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            _RoleTile(
              role: role,
              modelId: selected[role.key],
              model: _find(list, selected[role.key]),
              loading: models.isLoading,
              onTap: list.isEmpty
                  ? null
                  : () => _pick(context, ref, role, list, selected[role.key]),
            ),
          ],
          if (models case AsyncError(:final error)) ...[
            Divider(height: 1, color: c.line),
            Padding(
              padding: const EdgeInsets.all(NayaSpace.lg),
              child: Text(
                error is ApiException
                    ? error.message
                    : 'Model listesi alınamadı.',
                style: context.text.small,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static AiModel? _find(List<AiModel> models, String? id) {
    for (final m in models) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref,
    AiRole role,
    List<AiModel> models,
    String? current,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: NayaRadius.lg),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.94,
        builder: (context, controller) => _ModelPicker(
          role: role,
          models: [
            for (final m in models)
              if (role.fits(m)) m,
          ],
          current: current,
          controller: controller,
        ),
      ),
    );
    if (choice == null || choice == current) return;
    try {
      await setRoleModel(ref, role, choice);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.role,
    required this.modelId,
    required this.model,
    required this.loading,
    required this.onTap,
  });

  final AiRole role;
  final String? modelId;
  final AiModel? model;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(NayaSpace.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TechLabel(role.label),
                  const SizedBox(height: NayaSpace.xs),
                  Text(
                    model?.name ?? modelId ?? 'Seçilmedi',
                    style: context.text.body.copyWith(
                      color: c.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(role.help, style: context.text.small),
                ],
              ),
            ),
            if (loading)
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.textMuted,
                ),
              )
            else if (onTap != null)
              Icon(Icons.chevron_right, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Aranabilir model listesi; seçilen modelin kimliğiyle kapanır.
class _ModelPicker extends StatefulWidget {
  const _ModelPicker({
    required this.role,
    required this.models,
    required this.current,
    required this.controller,
  });

  final AiRole role;
  final List<AiModel> models;
  final String? current;
  final ScrollController controller;

  @override
  State<_ModelPicker> createState() => _ModelPickerState();
}

class _ModelPickerState extends State<_ModelPicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    List<AiModel> shown() {
      final q = _query.text.trim().toLowerCase();
      return [
        for (final m in widget.models)
          if (q.isEmpty ||
              m.name.toLowerCase().contains(q) ||
              m.id.toLowerCase().contains(q))
            m,
      ];
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NayaSpace.gutter,
            NayaSpace.lg,
            NayaSpace.gutter,
            NayaSpace.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TechLabel('${widget.models.length} model'),
              const SizedBox(height: NayaSpace.xs),
              Text(widget.role.label, style: context.text.title),
              const SizedBox(height: NayaSpace.xs),
              Text(
                'Fiyatlar milyon token başına dolar: giriş / çıkış.',
                style: context.text.small,
              ),
              const SizedBox(height: NayaSpace.md),
              NayaTextField(
                controller: _query,
                label: 'Ara',
                hint: 'deepseek, jev…',
                textInputAction: TextInputAction.search,
                suffix: Icon(Icons.search, size: 20, color: c.textMuted),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _query,
            builder: (context, _) {
              final list = shown();
              return ListView.separated(
                controller: widget.controller,
                itemCount: list.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: c.line),
                itemBuilder: (context, i) {
                  final m = list[i];
                  final selected = m.id == widget.current;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: NayaSpace.gutter,
                    ),
                    onTap: () => Navigator.of(context).pop(m.id),
                    title: Text(
                      m.name,
                      style: context.text.body.copyWith(
                        color: c.text,
                        fontWeight: selected ? FontWeight.w600 : null,
                      ),
                    ),
                    subtitle: Text(
                      m.details,
                      style: context.text.mono.copyWith(
                        fontSize: 11,
                        color: c.textMuted,
                      ),
                    ),
                    trailing: selected
                        ? Icon(Icons.check, color: c.accent)
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
