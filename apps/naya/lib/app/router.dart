import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../entities/product/product_library.dart';
import '../pages/data_module/data_module_page.dart';
import '../pages/history/history_page.dart';
import '../pages/library/library_page.dart';
import '../pages/not_found/not_found_page.dart';
import '../pages/part/part_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/sign_in/sign_in_page.dart';
import '../pages/workspace/workspace_page.dart';
import '../shared/ui/routes.dart';

/// Sayfalar birbirini bilmez; adresler ve geçişler yalnız burada.
abstract final class AppRoutes {
  static const library = '/';
  static const signIn = '/giris';
  static const settings = '/ayarlar';

  /// Sorgu parametreleri çalışma alanında ne açılacağını söyler:
  /// `teshis` (geçmiş teşhis), `sohbet` (kayıtlı sohbet), `sor` (parça).
  static String workspace(
    String productId, {
    int? diagnosis,
    int? conversation,
    String? askPart,
  }) => Uri(
    path: '/urun/$productId',
    queryParameters: {
      if (diagnosis != null) 'teshis': '$diagnosis',
      if (conversation != null) 'sohbet': '$conversation',
      'sor': ?askPart,
    },
  ).toString().replaceFirst(RegExp(r'\?$'), '');
  static String history(String productId) => '/urun/$productId/gecmis';
  static String module(String productId, String dmc) =>
      '/urun/$productId/dm/${Uri.encodeComponent(dmc)}';
  static String part(String productId, String partId) =>
      '/urun/$productId/parca/${Uri.encodeComponent(partId)}';
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
            onOpenSettings: () => context.push(AppRoutes.settings),
            onSignIn: () => context.push(AppRoutes.signIn),
          ),
        ),
        // İç içe tanımlı: adresten doğrudan açılsa da geri düğmesi
        // kütüphaneye döner.
        routes: [
          GoRoute(
            path: 'giris',
            pageBuilder: (context, state) =>
                _page(state, SignInPage(onDone: () => _back(context))),
          ),
          GoRoute(
            path: 'ayarlar',
            pageBuilder: (context, state) => _page(
              state,
              SettingsPage(onSignIn: () => context.push(AppRoutes.signIn)),
            ),
          ),
          GoRoute(
            path: 'urun/:id',
            pageBuilder: (context, state) => _page(
              state,
              _WorkspaceRoute(
                state.pathParameters['id']!,
                request: _requestOf(state.uri.queryParameters),
              ),
            ),
            routes: [
              GoRoute(
                path: 'gecmis',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _page(
                    state,
                    HistoryPage(
                      productId: id,
                      // `go` geçmişi kapatır; çalışma alanı ve model
                      // yeniden yüklenmeden isteği alır.
                      onOpenDiagnosis: (d) =>
                          context.go(AppRoutes.workspace(id, diagnosis: d)),
                      onOpenConversation: (c) =>
                          context.go(AppRoutes.workspace(id, conversation: c)),
                      onSignIn: () => context.push(AppRoutes.signIn),
                    ),
                  );
                },
              ),
              // DM'ler push ile açılır: geri dönünce çalışma alanı ve 3D
              // model yeniden yüklenmez.
              GoRoute(
                path: 'parca/:part',
                pageBuilder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return _page(
                    state,
                    PartPage(
                      productId: id,
                      partId: state.pathParameters['part']!,
                      onOpenModule: (dmc) =>
                          context.push(AppRoutes.module(id, dmc)),
                      // Alt parçaya geçiş yığını büyütmesin.
                      onOpenPart: (part) =>
                          context.pushReplacement(AppRoutes.part(id, part)),
                      // Çalışma alanına dönülür; sohbet bu parçaya geçer.
                      onAsk: (part) =>
                          context.go(AppRoutes.workspace(id, askPart: part)),
                    ),
                  );
                },
              ),
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

/// Giriş sayfası açıldığı yere döner; adresten doğrudan açıldıysa
/// kütüphaneye.
void _back(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(AppRoutes.library);
  }
}

WorkspaceRequest? _requestOf(Map<String, String> query) {
  final diagnosis = int.tryParse(query['teshis'] ?? '');
  if (diagnosis != null) return OpenDiagnosis(diagnosis);
  final conversation = int.tryParse(query['sohbet'] ?? '');
  if (conversation != null) return OpenConversation(conversation);
  final part = query['sor'];
  if (part != null && part.isNotEmpty) return AskAboutPart(part);
  return null;
}

/// Adresteki kimliği ürüne çevirir.
class _WorkspaceRoute extends ConsumerWidget {
  const _WorkspaceRoute(this.productId, {this.request});

  final String productId;
  final WorkspaceRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Girişten sonra kütüphane yenilenirken eski liste kalır; çalışma alanı
    // (ve sohbet) kapanmaz.
    final product = ref.watch(productLibraryProvider).value?.byId(productId);
    if (product != null) {
      return WorkspacePage(
        product: product,
        request: request,
        onOpenModule: (dmc) => context.push(AppRoutes.module(productId, dmc)),
        onOpenPart: (part) => context.push(AppRoutes.part(productId, part)),
        onOpenHistory: () => context.push(AppRoutes.history(productId)),
        onSignIn: () => context.push(AppRoutes.signIn),
        onOpenSettings: () => context.push(AppRoutes.settings),
      );
    }
    final isLoading = ref.watch(productLibraryProvider).isLoading;
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return NotFoundPage(onHome: () => context.go(AppRoutes.library));
  }
}
