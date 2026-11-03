import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

import 'src/layer_import_rule.dart';

// Analyzer eklentiyi bu isimle bulur.
final plugin = FsdLintPlugin();

class FsdLintPlugin extends Plugin {
  @override
  String get name => 'fsd_lint';

  @override
  void register(PluginRegistry registry) {
    // Uyarı kuralı olarak kaydediliyor ki ayrıca açmaya gerek kalmasın.
    registry.registerWarningRule(LayerImportRule());
  }
}
