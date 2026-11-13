import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../entities/product/product_library.dart';
import '../pages/data_module/data_module_page.dart';
import '../pages/library/library_page.dart';
import '../pages/not_found/not_found_page.dart';
import '../pages/workspace/workspace_page.dart';
import '../shared/ui/routes.dart';

/// Sayfalar birbirini bilmez; adresler ve geçişler yalnız burada.
abstract final class AppRoutes {
  static const library = '/';
  static String workspace(String productId) => '/urun/$productId';
  static String module(String productId, String dmc) =>
      '/urun/$productId/dm/${Uri.encodeComponent(dmc)}';
}

GoRouter buildRouter({String initialLocation = AppRoutes.library}) {
  // DM'ler push ile açılıyor. Web'de adres çubuğu da değişsin; sayfa
  // yenilenince ve tarayıcının geri tuşunda doğru yer açılsın.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
    initialLocation: initialLocation,
    errorBuilder: (context, state) =>
        NotFoundPage(onHome: () => context.go(AppRoutes.library)),
    routes: [
      GoRoute(
        path: AppRoutes.library,
        pageBuilder: (context, state) => _page(
          state,
          LibraryPage(
            onOpen: (product) => context.go(AppRoutes.workspace(product.id)),
          ),
        ),
        // İç içe tanımlı: adresten doğrudan açılsa da geri düğmesi
        // kütüphaneye döner.
        routes: [
          GoRoute(
            path: 'urun/:id',
            pageBuilder: (context, state) =>
                _page(state, _WorkspaceRoute(state.pathParameters['id']!)),
            routes: [
              // DM'ler push ile açılır: geri dönünce çalışma alanı ve 3D
              // model yeniden yüklenmez.
              GoRoute(
                path: 'dm/:dmc',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _page(
                    state,
                    DataModulePage(
                      productId: id,
                      dmc: state.pathParameters['dmc']!,
                      onOpenModule: (dmc) =>
                          context.push(AppRoutes.module(id, dmc)),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});

CustomTransitionPage<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: fadeThroughDuration,
    reverseTransitionDuration: fadeThroughReverseDuration,
    transitionsBuilder: fadeThroughTransition,
  );
}

/// Adresteki kimliği ürüne çevirir.
class _WorkspaceRoute extends ConsumerWidget {
  const _WorkspaceRoute(this.productId);

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productLibraryProvider).value?.byId(productId);
    if (product != null) {
      return WorkspacePage(
        product: product,
        onOpenModule: (dmc) => context.push(AppRoutes.module(productId, dmc)),
      );
    }
    final isLoading = ref.watch(productLibraryProvider).isLoading;
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return NotFoundPage(onHome: () => context.go(AppRoutes.library));
  }
}
