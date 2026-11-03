import 'errors.dart';

/// JSON nesnesinden alanları tipine göre okur.
///
/// Eksik ya da yanlış tipte bir alanda hangi dosyanın hangi alanı olduğunu
/// söyleyen bir [InvalidJsonException] fırlatır. Böylece her modelde aynı
/// kontrolleri tekrar yazmaya gerek kalmaz.
class JsonReader {
  JsonReader(Object? json, this.file, [this.path = ''])
    : _json = json is Map<String, Object?>
          ? json
          : throw InvalidJsonException(
              file,
              '${_where(path)}nesne bekleniyordu',
            );

  final Map<String, Object?> _json;
  final String file;
  final String path;

  static String _where(String path) => path.isEmpty ? '' : '$path: ';

  Never fail(String problem) =>
      throw InvalidJsonException(file, '${_where(path)}$problem');

  T _get<T>(String key, String typeName) {
    final value = _json[key];
    if (value is T) return value;
    if (value == null) fail('"$key" alanı eksik');
    fail('"$key" alanı $typeName olmalı');
  }

  T? _optional<T>(String key, String typeName) {
    final value = _json[key];
    if (value == null || value is T) return value as T?;
    fail('"$key" alanı $typeName olmalı');
  }

  String string(String key) => _get<String>(key, 'metin');
  String? optionalString(String key) => _optional<String>(key, 'metin');

  int integer(String key) => _get<int>(key, 'tam sayı');
  int? optionalInteger(String key) => _optional<int>(key, 'tam sayı');

  double number(String key) => _get<num>(key, 'sayı').toDouble();

  List<String> strings(String key, {bool optional = false}) {
    final list = optional
        ? _optional<List<Object?>>(key, 'liste') ?? const []
        : _get<List<Object?>>(key, 'liste');
    if (list.any((item) => item is! String)) {
      fail('"$key" listesi yalnız metin içermeli');
    }
    return list.cast<String>();
  }

  List<double> numbers(String key, {int? length}) {
    final list = _get<List<Object?>>(key, 'liste');
    if (list.any((item) => item is! num)) {
      fail('"$key" listesi yalnız sayı içermeli');
    }
    if (length != null && list.length != length) {
      fail('"$key" listesi $length elemanlı olmalı');
    }
    return [for (final item in list) (item! as num).toDouble()];
  }

  JsonReader object(String key) =>
      JsonReader(_get<Map<String, Object?>>(key, 'nesne'), file, _child(key));

  JsonReader? optionalObject(String key) {
    final value = _optional<Map<String, Object?>>(key, 'nesne');
    return value == null ? null : JsonReader(value, file, _child(key));
  }

  List<JsonReader> objects(String key, {bool optional = false}) {
    final list = optional
        ? _optional<List<Object?>>(key, 'liste') ?? const []
        : _get<List<Object?>>(key, 'liste');
    return [
      for (var i = 0; i < list.length; i++)
        JsonReader(list[i], file, '${_child(key)}[$i]'),
    ];
  }

  Map<String, String> stringMap(String key, {bool optional = false}) {
    final map = optional
        ? _optional<Map<String, Object?>>(key, 'nesne') ?? const {}
        : _get<Map<String, Object?>>(key, 'nesne');
    if (map.values.any((value) => value is! String)) {
      fail('"$key" içindeki değerler metin olmalı');
    }
    return map.cast<String, String>();
  }

  String _child(String key) => path.isEmpty ? key : '$path.$key';
}
