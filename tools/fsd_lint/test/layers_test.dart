import 'package:fsd_lint/src/layers.dart';
import 'package:test/test.dart';

LayerPath at(String path) => LayerPath.fromFile('/repo/apps/naya/lib/$path')!;

void main() {
  test('dosya yolundan katman ve dilim çıkar', () {
    final path = at('features/diagnose/model.dart');
    expect(path.layer, 'features');
    expect(path.slice, 'diagnose');
    expect(at('shared/theme.dart').slice, isNull);
  });

  test('uygulama dışındaki dosyalar kurala girmez', () {
    expect(LayerPath.fromFile('/repo/packages/x/lib/shared/a.dart'), isNull);
    expect(LayerPath.fromFile('/repo/apps/naya/lib/main.dart'), isNull);
    expect(LayerPath.fromFile('/repo/apps/naya/test/app_test.dart'), isNull);
  });

  test('alttaki katman import edilebilir', () {
    expect(canImport(at('pages/a/a.dart'), at('widgets/b/b.dart')), isTrue);
    expect(canImport(at('app/app.dart'), at('shared/ui/x.dart')), isTrue);
  });

  test('üstteki katman import edilemez', () {
    expect(canImport(at('shared/x.dart'), at('app/app.dart')), isFalse);
    expect(
      canImport(at('entities/part/p.dart'), at('features/f/f.dart')),
      isFalse,
    );
  });

  test('aynı katmanda yalnız aynı dilim', () {
    expect(canImport(at('features/a/x.dart'), at('features/a/y.dart')), isTrue);
    expect(
      canImport(at('features/a/x.dart'), at('features/b/y.dart')),
      isFalse,
    );
    expect(canImport(at('shared/ui/x.dart'), at('shared/api/y.dart')), isTrue);
  });
}
