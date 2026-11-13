import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

/// Web: oturum httpOnly çerezde. Yerelde API başka portta çalıştığı için
/// çerezin gitmesi `withCredentials` ister; yayında aynı adres olduğundan
/// zararı yok.
http.Client createHttpClient() => BrowserClient()..withCredentials = true;
