import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import 'errors.dart';
import 'format_version.dart';
import 'manifest.dart';
import 'map/faults.dart';
import 'map/hotspots.dart';
import 'map/parts.dart';
import 'map/zones.dart';
import 'references.dart';

const _mimetypeName = 'mimetype';
const _manifestName = 'naya.json';

/// ZIP kayıtlarına sabit bir tarih yazıyoruz; aynı içerik her seferinde
/// bayt bayt aynı dosyayı versin (1 Ocak 1980, ZIP'in en erken tarihi).
const _fixedTimestamp = 315532800;

/// Bellekteki bir `.naya` dosyası.
///
/// [entries] manifest ve `mimetype` dışındaki her şeyi tutar: `csdb/`,
/// `model/`, `map/`, `media/`, `ai/`. S1000D dosyalarına dokunulmaz,
/// okunduğu gibi geri yazılır.
class NayaFile {
  NayaFile({required this.manifest, Map<String, Uint8List>? entries})
    : entries = entries ?? {};

  /// Baytları okur, kabı ve bütünlüğü doğrular.
  ///
  /// Hata durumunda [NayaFormatException] alt tiplerinden birini fırlatır.
  factory NayaFile.decode(List<int> bytes) {
    _checkMimetypeHeader(bytes);

    final decoder = ZipDecoder();
    final Archive archive;
    try {
      archive = decoder.decodeBytes(bytes, verify: true);
    } on Object catch (e) {
      throw InvalidContainerException('ZIP okunamadı: $e');
    }
    _checkCentralDirectory(bytes, decoder.directory);

    Uint8List? manifestBytes;
    final entries = <String, Uint8List>{};
    for (final file in archive) {
      if (!file.isFile) continue;
      _checkEntryName(file.name);
      switch (file.name) {
        case _mimetypeName:
          break;
        case _manifestName:
          manifestBytes = file.content;
        default:
          entries[file.name] = file.content;
      }
    }
    if (manifestBytes == null) {
      throw const InvalidContainerException('naya.json bulunamadı');
    }

    final json = _decodeJson(_manifestName, manifestBytes);
    NayaManifest.checkVersion(json);
    final manifest = NayaManifest.fromJson(json);
    _checkIntegrity(manifest.integrity, entries);

    return NayaFile(manifest: manifest, entries: entries);
  }

  final NayaManifest manifest;
  final Map<String, Uint8List> entries;

  PartsFile? get parts => _readMap('map/parts.json', PartsFile.fromJson);
  FaultsFile? get faults => _readMap('map/faults.json', FaultsFile.fromJson);
  ZonesFile? get zones => _readMap('map/zones.json', ZonesFile.fromJson);
  HotspotsFile? get hotspots =>
      _readMap('map/hotspots.json', HotspotsFile.fromJson);

  /// Harita dosyalarını okur ve aralarındaki bağları kontrol eder: her
  /// arıza ve etiket noktası var olan bir parçayı, her parça var olan bir
  /// bölgeyi gösteriyor mu, parça görselleri dosyada var mı?
  ///
  /// [decode] bunu yapmaz; dosyayı açmak hızlı kalsın, bağları yarım bir
  /// dosya da açılıp düzeltilebilsin. İçe aktarma ve `naya_cli validate`
  /// bunu çağırır. Bütün sorunları tek [InvalidReferencesException]
  /// içinde listeler.
  void validate() {
    final problems = findReferenceProblems(
      parts: parts,
      faults: faults,
      zones: zones,
      hotspots: hotspots,
      entryNames: entries.keys.toSet(),
    );
    if (problems.isNotEmpty) throw InvalidReferencesException(problems);
  }

  /// Bir JSON nesnesini girinti ile `entries` içine yazar.
  void putJson(String path, Map<String, Object?> json) {
    entries[path] = _encodeJson(json);
  }

  /// ZIP olarak yazar. Bütünlük özetleri her seferinde yeniden hesaplanır,
  /// manifestteki eski değerler kullanılmaz.
  Uint8List encode() {
    final names = entries.keys.toList()..sort();
    names.forEach(_checkEntryName);
    // Bu iki ad kabın kendisine ait; entries'te olurlarsa ZIP'te aynı adlı
    // kaydı ezip okunamayan bir dosya çıkarırlar.
    for (final reserved in [_mimetypeName, _manifestName]) {
      if (entries.containsKey(reserved)) {
        throw InvalidContainerException(
          '"$reserved" kabın kendi dosyası; entries içine konamaz',
        );
      }
    }
    _checkUniqueNames([_mimetypeName, _manifestName, ...names]);

    final integrity = Integrity({
      for (final name in names) name: sha256.convert(entries[name]!).toString(),
    });
    final manifestBytes = _encodeJson(
      manifest.withIntegrity(integrity).toJson(),
    );

    final archive = Archive()
      // mimetype ilk kayıt ve sıkıştırmasız: dosyanın ilk baytlarına bakan
      // biri ZIP'i açmadan türünü anlayabilsin (EPUB ve ODF'deki gibi).
      ..add(_entry(_mimetypeName, utf8.encode(nayaMimeType), compress: false))
      ..add(_entry(_manifestName, manifestBytes));
    for (final name in names) {
      archive.add(_entry(name, entries[name]!));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  T? _readMap<T>(String path, T Function(Object?) parse) {
    final bytes = entries[path];
    return bytes == null ? null : parse(_decodeJson(path, bytes));
  }

  static ArchiveFile _entry(
    String name,
    List<int> data, {
    bool compress = true,
  }) {
    final file = compress
        ? ArchiveFile.bytes(name, data)
        : ArchiveFile.noCompress(name, data.length, data);
    return file..lastModTime = _fixedTimestamp;
  }

  /// ZIP'in ilk yerel başlığına bakar: adı `mimetype`, sıkıştırması yok
  /// ve içeriği [nayaMimeType] olmalı.
  static void _checkMimetypeHeader(List<int> bytes) {
    const headerSize = 30;
    final expected = utf8.encode(nayaMimeType);
    final view = ByteData.sublistView(
      Uint8List.fromList(bytes.take(256).toList()),
    );

    bool ok() {
      if (view.lengthInBytes < headerSize) return false;
      if (view.getUint32(0, Endian.little) != 0x04034b50) return false;
      if (view.getUint16(8, Endian.little) != 0) return false;
      final nameLength = view.getUint16(26, Endian.little);
      final extraLength = view.getUint16(28, Endian.little);
      final nameEnd = headerSize + nameLength;
      final dataEnd = nameEnd + extraLength + expected.length;
      if (view.lengthInBytes < dataEnd) return false;
      // Ad baytça karşılaştırılır; bozuk UTF-8 içeren bir ad da yalnızca
      // "mimetype değil" demektir.
      final name = bytes.sublist(headerSize, nameEnd);
      final data = bytes.sublist(nameEnd + extraLength, dataEnd);
      return _sameBytes(name, utf8.encode(_mimetypeName)) &&
          _sameBytes(data, expected);
    }

    if (!ok()) {
      throw const InvalidContainerException(
        'Bu bir .naya dosyası değil: ilk kayıt sıkıştırmasız "mimetype" olmalı',
      );
    }
  }

  /// ZIP'in merkez dizinindeki her kaydı tek tek kontrol eder.
  ///
  /// `archive` paketi aynı adlı kayıtları okurken tekilleştiriyor, sonuncusu
  /// kalıyor. Başka bir okuyucu ilkini alabilir; böylece aynı dosya iki
  /// programda farklı içerik gösterir. Bu yüzden çift kaydı ve merkez
  /// dizinle yerel başlıkta adı farklı olan kaydı reddediyoruz (uv ve
  /// PyPI da 2025'te aynı nedenle bunu yaptı). Adlar UTF-8 yazılır;
  /// `encode` de öyle yazıyor.
  static void _checkCentralDirectory(List<int> bytes, ZipDirectory directory) {
    final names = <String>[];
    for (final header in directory.fileHeaders) {
      // archive paketi yerel başlıktaki adı okumadan atlıyor; onu biz
      // okuyoruz. Akış hâlinde okuyan programlar yalnız bu adı görür.
      final local = _localName(bytes, header.localHeaderOffset);
      if (local != null && !_sameBytes(local, utf8.encode(header.filename))) {
        throw InvalidContainerException(
          '"${header.filename}" kaydının adı yerel başlıkta farklı',
        );
      }
      names.add(header.filename);
    }
    _checkUniqueNames(names);
  }

  /// [offset]'teki yerel başlığın ad baytları; başlık okunamıyorsa null
  /// (o durumda ZIP zaten açılamamış olur).
  static List<int>? _localName(List<int> bytes, int offset) {
    const headerSize = 30;
    if (offset < 0 || offset + headerSize > bytes.length) return null;
    final length = bytes[offset + 26] | bytes[offset + 27] << 8;
    final end = offset + headerSize + length;
    return end > bytes.length ? null : bytes.sublist(offset + headerSize, end);
  }

  /// Aynı ad iki kez geçemez. Büyük/küçük harf farkı da sayılmaz: macOS ve
  /// Windows'ta `Zincir.webp` ile `zincir.webp` aynı dosyadır (EPUB'daki
  /// OCF kuralı da böyle).
  static void _checkUniqueNames(Iterable<String> names) {
    final seen = <String, String>{};
    for (final name in names) {
      final previous = seen[name.toLowerCase()];
      if (previous != null) {
        throw InvalidContainerException(
          previous == name
              ? '"$name" iki kez geçiyor'
              : '"$previous" ve "$name" yalnız büyük/küçük harfle ayrışıyor',
        );
      }
      seen[name.toLowerCase()] = name;
    }
  }

  /// Arşiv dışına yazmaya çalışan yolları (`../`, `/etc/...`, `C:/...`)
  /// reddeder.
  static void _checkEntryName(String name) {
    final segments = name.split('/');
    if (name.startsWith('/') ||
        name.contains(r'\') ||
        // Windows'ta "C:/..." mutlak yoldur; ':' zaten dosya adında geçemez.
        name.contains(':') ||
        segments.any((s) => s.isEmpty || s == '.' || s == '..')) {
      throw InvalidContainerException('Geçersiz dosya yolu: $name');
    }
  }

  static void _checkIntegrity(
    Integrity? integrity,
    Map<String, Uint8List> entries,
  ) {
    if (integrity == null) {
      throw IntegrityException(['manifestte "integrity" alanı yok']);
    }
    final problems = <String>[];
    for (final MapEntry(key: name, value: bytes) in entries.entries) {
      final expected = integrity.files[name];
      if (expected == null) {
        problems.add('$name manifestte kayıtlı değil');
      } else if (sha256.convert(bytes).toString() != expected.toLowerCase()) {
        problems.add('$name değiştirilmiş');
      }
    }
    for (final name in integrity.files.keys) {
      if (!entries.containsKey(name)) problems.add('$name eksik');
    }
    if (problems.isNotEmpty) throw IntegrityException(problems);
  }

  static Object? _decodeJson(String path, List<int> bytes) {
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException catch (e) {
      throw InvalidJsonException(path, 'JSON okunamadı (${e.message})');
    }
  }

  static Uint8List _encodeJson(Map<String, Object?> json) =>
      utf8.encode('${const JsonEncoder.withIndent('  ').convert(json)}\n');

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
