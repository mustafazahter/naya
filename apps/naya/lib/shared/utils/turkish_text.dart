/// Dart'ın `toUpperCase` ve `toLowerCase` işlevleri dil bilmiyor: "i" harfini
/// "I" yapıyor, "SENİN" yerine "SENIN" çıkıyor.
String turkishUpperCase(String text) =>
    text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

String turkishLowerCase(String text) =>
    text.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
