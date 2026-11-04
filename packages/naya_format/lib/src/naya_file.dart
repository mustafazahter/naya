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

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: true);
    } on Object catch (e) {
      throw InvalidContainerException('ZIP okunamadı: $e');
    }

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
          if (entries.containsKey(file.name)) {
            throw InvalidContainerException('"${file.name}" iki kez geçiyor');
          }
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
