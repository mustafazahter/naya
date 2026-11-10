import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../entities/product/product_library.dart';
import '../../shared/ui/theme.dart';
import '../../shared/ui/tokens.dart';

class _LibraryQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String query) => state = query;
}

final libraryQueryProvider = NotifierProvider<_LibraryQuery, String>(
  _LibraryQuery.new,
);

/// Aramaya göre süzülmüş kütüphane.
final filteredLibraryProvider = Provider<AsyncValue<ProductLibrary>>((ref) {
  final query = ref.watch(libraryQueryProvider);
  return ref
      .watch(productLibraryProvider)
      .whenData(
        (library) => ProductLibrary(
          templates: library.templates.where((p) => p.matches(query)).toList(),
          userFiles: library.userFiles.where((p) => p.matches(query)).toList(),
        ),
      );
});

class LibrarySearchField extends ConsumerStatefulWidget {
  const LibrarySearchField({super.key});

  @override
  ConsumerState<LibrarySearchField> createState() => _LibrarySearchFieldState();
}

class _LibrarySearchFieldState extends ConsumerState<LibrarySearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String query) {
    ref.read(libraryQueryProvider.notifier).set(query);
  }

  void _clear() {
    _controller.clear();
    _set('');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasQuery = ref.watch(libraryQueryProvider).isNotEmpty;
    return TextField(
      controller: _controller,
      onChanged: _set,
      textInputAction: TextInputAction.search,
      style: context.text.body.copyWith(color: c.text),
      decoration: InputDecoration(
        hintText: 'Ürün ara',
        hintStyle: context.text.body.copyWith(color: c.textMuted),
        prefixIcon: Icon(Icons.search, color: c.textMuted),
        suffixIcon: hasQuery
            ? IconButton(
                tooltip: 'Aramayı temizle',
                onPressed: _clear,
                icon: Icon(Icons.close, color: c.textMuted),
              )
            : null,
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(NayaRadius.md),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(NayaRadius.md),
          borderSide: BorderSide(color: c.accent),
        ),
      ),
    );
  }
}
