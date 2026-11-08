/// Uç durum testleri için küçük DM, PM ve DML metinleri üretir. Her testte
/// yalnız o testin bozduğu yer görünsün diye geri kalanı burada duruyor.
library;

const dmCodeAttributes =
    'modelIdentCode="X" systemDiffCode="A" systemCode="D00" '
    'subSystemCode="0" subSubSystemCode="0" assyCode="00" disassyCode="00" '
    'disassyCodeVariant="AA" infoCode="040" infoCodeVariant="A" '
    'itemLocationCode="A"';

const dmCodeElement = '<dmCode $dmCodeAttributes/>';

const simpleDescription =
    '<description><levelledPara><para>Metin.</para></levelledPara>'
    '</description>';

String schemaAttribute(String issue) =>
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
    'xsi:noNamespaceSchemaLocation='
    '"http://www.s1000d.org/$issue/xml_schema_flat/descript.xsd"';

String dmXml({
  String rootAttributes = '',
  String code = dmCodeElement,
  String title = '<dmTitle><techName>Zincir</techName></dmTitle>',
  String issueInfo = '<issueInfo issueNumber="001" inWork="00"/>',
  String language = '<language languageIsoCode="tr" countryIsoCode="TR"/>',
  String issueDate = '<issueDate year="2026" month="11" day="8"/>',
  String status = '',
  String content = simpleDescription,
}) =>
    '''
<dmodule $rootAttributes>
  <identAndStatusSection>
    <dmAddress>
      <dmIdent>$code$issueInfo$language</dmIdent>
      <dmAddressItems>$issueDate$title</dmAddressItems>
    </dmAddress>
    <dmStatus>$status</dmStatus>
  </identAndStatusSection>
  <content>$content</content>
</dmodule>
''';

/// [attributes] verilen hedefe başvuran bir `dmRef`.
String dmRefXml(String attributes, {String title = ''}) =>
    '<dmRef><dmRefIdent><dmCode $attributes/></dmRefIdent>$title</dmRef>';

const pmCodeElement =
    '<pmCode modelIdentCode="X" pmIssuer="C3002" pmNumber="00001" '
    'pmVolume="00"/>';

String pmXml(String entries) =>
    '''
<pm>
  <identAndStatusSection>
    <pmAddress>
      <pmIdent>$pmCodeElement</pmIdent>
      <pmAddressItems><pmTitle>Kitap</pmTitle></pmAddressItems>
    </pmAddress>
  </identAndStatusSection>
  <content>$entries</content>
</pm>
''';

const dmlCodeElement =
    '<dmlCode modelIdentCode="X" senderIdent="C3002" dmlType="s" '
    'yearOfDataIssue="2026" seqNumber="00001"/>';

String dmlXml(String entries) =>
    '''
<dml>
  <identAndStatusSection>
    <dmlAddress><dmlIdent>$dmlCodeElement</dmlIdent></dmlAddress>
  </identAndStatusSection>
  <dmlContent>$entries</dmlContent>
</dml>
''';
