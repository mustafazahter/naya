import 'map/faults.dart';
import 'map/hotspots.dart';
import 'map/parts.dart';
import 'map/zones.dart';

/// Harita dosyaları arasındaki bağları kontrol eder ve bulduğu her sorunu
/// döndürür. Dosyalar tek tek okunurken bunlar görülemez; çünkü örneğin
/// `faults.json` okunurken hangi parçaların var olduğu bilinmez.
///
/// Olmayan dosya boş kabul edilir: `zones.json` yoksa hiçbir parça bölge
/// gösteremez.
List<String> findReferenceProblems({
  required PartsFile? parts,
  required FaultsFile? faults,
  required ZonesFile? zones,
  required HotspotsFile? hotspots,
  required Set<String> entryNames,
}) {
  final problems = <String>[];
  final partIds = {for (final p in parts?.parts ?? <Part>[]) p.id};
  final zoneList = zones?.zones ?? <Zone>[];
  final zoneIds = <String>{};

  void unique(String file, String kind, Iterable<String> ids) {
    final seen = <String>{};
    for (final id in ids) {
      if (!seen.add(id)) problems.add('$file: "$id" $kind birden fazla kez');
    }
  }

  for (final z in zoneList) {
    if (!zoneIds.add(z.id)) {
      problems.add('map/zones.json: "${z.id}" bölgesi birden fazla kez');
    }
  }
  final zoneParent = {for (final z in zoneList) z.id: z.parent};
  for (final z in zoneList) {
    if (z.parent != null && !zoneIds.contains(z.parent)) {
      problems.add(
        'map/zones.json: "${z.id}" bölgesinin üstü "${z.parent}" yok',
      );
      continue;
    }
    // Yukarı doğru yürürken aynı bölgeye dönülürse döngü vardır.
    final seen = <String>{z.id};
    for (var p = z.parent; p != null; p = zoneParent[p]) {
      if (!seen.add(p)) {
        problems.add('map/zones.json: "${z.id}" bölge ağacında döngü var');
        break;
      }
    }
  }

  for (final p in parts?.parts ?? <Part>[]) {
    if (p.zone != null && !zoneIds.contains(p.zone)) {
      problems.add(
        'map/parts.json: "${p.id}" parçasının bölgesi '
        '"${p.zone}" yok',
      );
    }
    for (final m in p.media) {
      if (!entryNames.contains(m)) {
        problems.add(
          'map/parts.json: "${p.id}" parçasının görseli "$m" '
          'dosyada yok',
        );
      }
    }
  }

  if (faults != null) {
    unique('map/faults.json', 'belirtisi', faults.symptoms.map((s) => s.id));
    unique('map/faults.json', 'arızası', faults.faults.map((f) => f.id));
    for (final f in faults.faults) {
      if (!partIds.contains(f.part)) {
        problems.add(
          'map/faults.json: "${f.id}" arızasının parçası '
          '"${f.part}" yok',
        );
      }
    }
  }

  if (hotspots != null) {
    unique('map/hotspots.json', 'noktası', hotspots.hotspots.map((h) => h.id));
    for (final h in hotspots.hotspots) {
      if (!partIds.contains(h.part)) {
        problems.add(
          'map/hotspots.json: "${h.id}" noktasının parçası '
          '"${h.part}" yok',
        );
      }
    }
  }

  return problems;
}
