// Platforma göre HTTP istemcisi: web'de çerez gönderen BrowserClient,
// diğerlerinde dart:io istemcisi.
export 'http_client_io.dart'
    if (dart.library.js_interop) 'http_client_web.dart';
