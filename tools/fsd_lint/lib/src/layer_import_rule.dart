import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:path/path.dart' as p;

import 'layers.dart';

class LayerImportRule extends AnalysisRule {
  static const code = LintCode(
    'fsd_layer_import',
    "'{0}' katmanı '{1}' katmanını import edemez.",
    correctionMessage:
        'Bir katman yalnız kendinden alttakileri import eder: '
        'app → pages → widgets → features → entities → shared.',
    severity: DiagnosticSeverity.ERROR,
  );

  LayerImportRule()
    : super(
        name: 'fsd_layer_import',
        description: 'FSD katman sırasına aykırı importları yakalar.',
      );

  @override
  DiagnosticCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    final visitor = _Visitor(this, context);
    registry.addImportDirective(this, visitor);
    registry.addExportDirective(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final LayerImportRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) => _check(node);

  @override
  void visitExportDirective(ExportDirective node) => _check(node);

  void _check(NamespaceDirective node) {
    final file = context.currentUnit?.file.path;
    final uri = node.uri.stringValue;
    if (file == null || uri == null) return;

    final from = LayerPath.fromFile(file);
    if (from == null) return;

    final target = _targetPath(file, uri);
    if (target == null) return;
    final to = LayerPath.fromFile(target);
    if (to == null) return;

    if (!canImport(from, to)) {
      rule.reportAtNode(node.uri, arguments: [from.layer, to.layer]);
    }
  }

  /// Import edilen dosyanın yolunu bulur. Yalnız bu paketin kendi dosyaları
  /// (göreli yol ya da `package:<bu paket>/`) ilgilendirir.
  String? _targetPath(String file, String uri) {
    final parsed = Uri.parse(uri);
    if (!parsed.hasScheme) {
      return p.normalize(p.join(p.dirname(file), parsed.path));
    }
    if (parsed.scheme != 'package') return null;

    final parts = p.split(p.normalize(file));
    final lib = parts.lastIndexOf('lib');
    if (lib < 1) return null;
    // Klasör adı paket adıyla aynı tutuluyor (apps/naya → naya).
    final packageName = parts[lib - 1];
    final segments = parsed.pathSegments;
    if (segments.isEmpty || segments.first != packageName) return null;
    return p.joinAll([...parts.take(lib + 1), ...segments.skip(1)]);
  }
}
