"""Şablonların S1000D içeriğini ve parça haritasını tablolardan yazar.

Her şablonun `scripts/make_content.py` dosyası bir `Content` kurar, DM'leri
(`dm`), parçaları (`part`), bölgeleri, belirtileri ve arızaları tanımlar,
sonra `write()` çağırır. `csdb/` altındaki DM, PM ve DML dosyaları ile
`map/` altındaki parts, faults ve zones dosyaları buradan yazılır; DMC'ler,
parça haritası ve arızalar böylece birbiriyle tutarlı kalır.

DM sözlüğünün alanları:
  code, tech (konu), info (bilgi adı; yoksa bilgi koduna göre)
  description: [(başlık, [paragraf...])]   → tanım DM'i; paragraf yerine
               (giriş, [madde...]) verilirse paragrafın içinde liste olur
  steps: [adım | (başlık, [alt adım...])]   → prosedür DM'i
  isolation: {...}                          → arıza bulma DM'i
  figure: çizim numarası
  tools, supplies, spares: [(ad, adet)]; adet None ise "Gerektiği kadar"
  warnings, cautions: [metin]
  conditions: [metin]
  next: sonraki işlemin DMC'si ya da DMC listesi
"""
import json
from pathlib import Path
from xml.sax.saxutils import escape, quoteattr

INFO_NAMES = {
    '022': 'İş kuralları', '040': 'Tanım', '210': 'İkmal',
    '241': 'Yağ değişimi', '250': 'Temizlik', '271': 'Ayar',
    '300': 'Kontrol', '310': 'Gözle muayene', '320': 'Çalışma testi',
    '361': 'Ölçüm', '421': 'Arıza bulma', '920': 'Değiştirme',
    '921': 'Yenisiyle değiştirme', '941': 'Resimli parça kataloğu',
}


class Dmc:
    def __init__(self, model, system, sub, info, disassy, item):
        self.model = model
        self.system, self.sub, self.info = system, sub, info
        self.disassy, self.item = disassy, item

    def __str__(self):
        return (f'DMC-{self.model}-AAA-{self.system}-{self.sub}0-00-'
                f'{self.disassy}AA-{self.info}A-{self.item}')

    def file(self):
        return f'{self}_001-00_TR-TR.XML'

    def xml(self):
        return (f'<dmCode modelIdentCode="{self.model}" systemDiffCode="AAA" '
                f'systemCode="{self.system}" subSystemCode="{self.sub}" '
                f'subSubSystemCode="0" assyCode="00" '
                f'disassyCode="{self.disassy}" disassyCodeVariant="AA" '
                f'infoCode="{self.info}" infoCodeVariant="A" '
                f'itemLocationCode="{self.item}"/>')

    def ref(self):
        return f'<dmRef><dmRefIdent>{self.xml()}</dmRefIdent></dmRef>'


def t(text):
    return escape(text)


class Content:
    """Bir şablonun bütün içeriği.

    [here] şablon klasörü; [product] IPD ve BREX DM'lerinin konusu;
    [manual] PM'in başlığı; [sns] sistem kodu → (başlık, {alt sistem:
    başlık}); [figures] çizim numarası → başlık; [liquids] litreyle
    ölçülen sarf malzemelerinin adlarında geçen sözcükler; [general]
    bütün ürünü kapsayan sistemin kodu (IPD ve BREX bunun altında).
    """

    def __init__(self, here, model, applic, product, manual, sns, figures,
                 company='NAYA0', date=('2026', '11', '23'),
                 liquids=('yağı', 'suyu', 'hidroliği'), general='D00',
                 numbers=None):
        self.csdb = Path(here) / 'csdb'
        self.map = Path(here) / 'map'
        self.model, self.company, self.date = model, company, date
        self.applic, self.product, self.manual = applic, product, manual
        self.sns, self.figures, self.liquids = sns, figures, liquids
        self.dms, self.parts = [], []
        self.zones, self.symptoms, self.faults = [], [], []
        # Yedek parça adı → IPD'deki parçanın kimliği; böylece prosedürdeki
        # parça katalogda aynı numarayla bulunur.
        self.spare_parts = {}
        # Alet ve sarf malzemesi adı → sabit parça numarası; verilmeyenler
        # NC-TL-001 gibi sırayla numaralanır.
        self.numbers = dict(numbers or {})
        self._numbers = {}
        self.brex = self.code(general, info='022', item='D')
        self.ipd = self.code(general, info='941', disassy='01')

    # --- Tanımlar -----------------------------------------------------------

    def code(self, system, sub='0', info='040', disassy='00', item='A'):
        return Dmc(self.model, system, sub, info, disassy, item)

    def dm(self, **kwargs):
        self.dms.append(kwargs)
        return kwargs['code']

    def part(self, id, name, parent, sns, nodes, zone, function,
             procedures=None, quantity=1, part_number=None, ipd_name=None):
        """(id, ad, üst parça, sns, düğümler, bölge, işlev, prosedürler,
        IPD adedi). Düğümü olmayan parça içinde bulunduğu düğüme bağlanır.
        [ipd_name] katalogdaki tanım (ölçü, tip); yoksa parçanın adı."""
        self.parts.append(dict(id=id, name=name, parent=parent, sns=sns,
                               nodes=nodes, zone=zone, function=function,
                               procedures=procedures or {},
                               quantity=quantity, part_number=part_number,
                               ipd_name=ipd_name,
                               item=f'{len(self.parts) + 1:03d}'))

    def icn(self, number):
        return (f'ICN-{self.model}-AAA-D000000-0-{self.company}-'
                f'{number:05d}-A-001-01')

    # --- Numaralar ----------------------------------------------------------

    def part_number(self, part_id):
        """Parçanın IPD'deki numarası."""
        for i, p in enumerate(self.parts, 1):
            if p['id'] == part_id:
                return p['part_number'] or f'NC-{p["sns"]}-{i:03d}'
        raise KeyError(part_id)

    def item_number(self, prefix, name):
        """Alet, sarf ve yedek parçaların numarası; aynı ad her DM'de aynı
        numarayı alır."""
        if prefix == 'PT' and name in self.spare_parts:
            return self.part_number(self.spare_parts[name])
        if name in self.numbers:
            return self.numbers[name]
        key = (prefix, name)
        if key not in self._numbers:
            count = sum(1 for k in self._numbers if k[0] == prefix) + 1
            self._numbers[key] = f'NC-{prefix}-{count:03d}'
        return self._numbers[key]

    # --- XML ----------------------------------------------------------------

    def dm_status(self):
        return f'''    <dmStatus issueType="new">
      <security securityClassification="01"/>
      <responsiblePartnerCompany enterpriseCode="{self.company}"><enterpriseName>NAYA</enterpriseName></responsiblePartnerCompany>
      <originator enterpriseCode="{self.company}"><enterpriseName>NAYA</enterpriseName></originator>
      <applic><displayText><simplePara>{t(self.applic)}</simplePara></displayText></applic>
      <brexDmRef>{self.brex.ref()}</brexDmRef>
      <qualityAssurance><unverified/></qualityAssurance>
    </dmStatus>'''

    def dm_xml(self, dmc, tech, info, schema, body, figures=()):
        entities = ''.join(
            f'<!ENTITY {self.icn(n)} SYSTEM "{self.icn(n)}.JPG" NDATA JPEG>\n'
            for n in sorted(set(figures)))
        doctype = ('<!DOCTYPE dmodule [\n<!NOTATION JPEG SYSTEM "JPEG">\n'
                   f'{entities}]>\n') if figures else ''
        year, month, day = self.date
        return f'''<?xml version="1.0" encoding="UTF-8"?>
{doctype}<dmodule xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.s1000d.org/S1000D_5-0/xml_schema_flat/{schema}.xsd">
  <identAndStatusSection>
    <dmAddress>
      <dmIdent>
        {dmc.xml()}
        <language languageIsoCode="tr" countryIsoCode="TR"/>
        <issueInfo issueNumber="001" inWork="00"/>
      </dmIdent>
      <dmAddressItems>
        <issueDate year="{year}" month="{month}" day="{day}"/>
        <dmTitle><techName>{t(tech)}</techName><infoName>{t(info)}</infoName></dmTitle>
      </dmAddressItems>
    </dmAddress>
{self.dm_status()}
  </identAndStatusSection>
  <content>
{body}
  </content>
</dmodule>
'''

    def figure_xml(self, number, indent):
        return (f'{indent}<figure id="fig-{number:04d}"><title>'
                f'{t(self.figures[number])}</title><graphic '
                f'infoEntityIdent="{self.icn(number)}"/></figure>')

    @staticmethod
    def para_xml(p, indent='        '):
        """Paragraf; (giriş, [madde...]) ise maddeler paragrafın içinde
        sırasız liste olur."""
        if isinstance(p, str):
            return f'{indent}<para>{t(p)}</para>'
        intro, items = p
        rows = ''.join(f'<listItem><para>{t(i)}</para></listItem>'
                       for i in items)
        return f'{indent}<para>{t(intro)}<randomList>{rows}</randomList></para>'

    def description_body(self, d):
        lines = ['    <description>']
        for i, (title, paras) in enumerate(d['description']):
            lines.append('      <levelledPara>')
            lines.append(f'        <title>{t(title)}</title>')
            lines += [self.para_xml(p) for p in paras]
            lines.append('      </levelledPara>')
            if i == 0 and d.get('figure'):
                lines.append(self.figure_xml(d['figure'], '      '))
        lines.append('    </description>')
        return '\n'.join(lines)

    def items(self, kind, entries, prefix, unit):
        """Aletler, sarf malzemeleri ve yedek parçalar."""
        if not entries:
            return f'<no{kind[0].upper()}{kind[1:]}/>'
        group, descr, req = {
            'supportEquips': ('supportEquipDescrGroup', 'supportEquipDescr',
                              'reqQuantity'),
            'supplies': ('supplyDescrGroup', 'supplyDescr', 'reqQuantity'),
            'spares': ('spareDescrGroup', 'spareDescr', 'reqQuantity'),
        }[kind]
        rows = []
        for i, (name, quantity) in enumerate(entries, 1):
            ident = (f'<identNumber><manufacturerCode>{self.company}'
                     '</manufacturerCode><partAndSerialNumber><partNumber>'
                     f'{self.item_number(prefix, name)}'
                     '</partNumber></partAndSerialNumber></identNumber>')
            if quantity is None:
                # Miktar el kitabına bağlı (yakıt, yağ); sayı uydurulmaz.
                amount = f'<{req}>Gerektiği kadar</{req}>'
            else:
                # Sıvılar litreyle, gerisi adetle.
                liquid = any(w in name for w in self.liquids)
                unit_of = 'L' if unit == 'L' and liquid else 'EA'
                amount = f'<{req} unitOfMeasure="{unit_of}">{quantity}</{req}>'
            rows.append(f'<{descr} id="{prefix.lower()}-{i:04d}"><name>'
                        f'{t(name)}</name>{ident}{amount}</{descr}>')
        return f'<{group}>{"".join(rows)}</{group}>'

    @staticmethod
    def safety(d):
        warnings = ''.join(
            f'<warning><warningAndCautionPara>{t(w)}</warningAndCautionPara>'
            '</warning>' for w in d.get('warnings', []))
        cautions = ''.join(
            f'<caution><warningAndCautionPara>{t(c)}</warningAndCautionPara>'
            '</caution>' for c in d.get('cautions', []))
        if not warnings and not cautions:
            return '<noSafety/>'
        return f'<safetyRqmts>{warnings}{cautions}</safetyRqmts>'

    @staticmethod
    def conditions(d):
        conds = d.get('conditions', [])
        if not conds:
            return '<noConds/>'
        return ''.join(f'<reqCondNoRef><reqCond>{t(c)}</reqCond>'
                       '</reqCondNoRef>' for c in conds)

    def prelim(self, d):
        return ('      <preliminaryRqmts>\n'
                f'        <reqCondGroup>{self.conditions(d)}</reqCondGroup>\n'
                '        <reqSupportEquips>'
                f'{self.items("supportEquips", d.get("tools"), "TL", "EA")}'
                '</reqSupportEquips>\n'
                '        <reqSupplies>'
                f'{self.items("supplies", d.get("supplies"), "SP", "L")}'
                '</reqSupplies>\n'
                '        <reqSpares>'
                f'{self.items("spares", d.get("spares"), "PT", "EA")}'
                '</reqSpares>\n'
                f'        <reqSafety>{self.safety(d)}</reqSafety>\n'
                '      </preliminaryRqmts>')

    def procedure_body(self, d):
        steps = []
        for i, step in enumerate(d['steps']):
            figure = self.figure_xml(d['figure'], '') if i == 0 and d.get(
                'figure') else ''
            if isinstance(step, tuple):
                title, subs = step
                inner = ''.join(f'<proceduralStep><para>{t(s)}</para>'
                                '</proceduralStep>' for s in subs)
                steps.append(f'        <proceduralStep><title>{t(title)}'
                             f'</title>{figure}{inner}</proceduralStep>')
            else:
                steps.append(f'        <proceduralStep><para>{t(step)}</para>'
                             f'{figure}</proceduralStep>')
        nxt = d.get('next')
        nxt = nxt if isinstance(nxt, list) else [nxt] if nxt else []
        close = ('<reqCondGroup>' + ''.join(
            '<reqCondDm><reqCond>Sonraki işlem:</reqCond>'
            f'{n.ref()}</reqCondDm>' for n in nxt) + '</reqCondGroup>'
        ) if nxt else '<reqCondGroup><noConds/></reqCondGroup>'
        return ('    <procedure>\n' + self.prelim(d)
                + '\n      <mainProcedure>\n' + '\n'.join(steps)
                + '\n      </mainProcedure>\n'
                f'      <closeRqmts>{close}</closeRqmts>\n    </procedure>')

    @staticmethod
    def isolation_body(d):
        iso = d['isolation']
        rows = []
        for sid, action, question, yes, no in iso['steps']:
            rows.append(
                f'            <isolationStep id="{sid}">\n'
                f'              <action>{t(action)}</action>\n'
                f'              <isolationStepQuestion>{t(question)}'
                '</isolationStepQuestion>\n'
                '              <isolationStepAnswer><yesNoAnswer>'
                f'<yesAnswer nextActionRefId="{yes}"/>'
                f'<noAnswer nextActionRefId="{no}"/></yesNoAnswer>'
                '</isolationStepAnswer>\n'
                '            </isolationStep>')
        for eid, action, target in iso['ends']:
            ref = f' {target.ref()}' if target else ''
            rows.append(f'            <isolationProcedureEnd id="{eid}">'
                        f'<action>{t(action)}{ref}</action>'
                        '</isolationProcedureEnd>')
        empty = ('<preliminaryRqmts><reqCondGroup><noConds/></reqCondGroup>'
                 '<reqSupportEquips><noSupportEquips/></reqSupportEquips>'
                 '<reqSupplies><noSupplies/></reqSupplies><reqSpares>'
                 '<noSpares/></reqSpares><reqSafety><noSafety/></reqSafety>'
                 '</preliminaryRqmts>')
        return f'''    <faultIsolation>
      <faultIsolationProcedure>
        <fault faultCode="{iso['fault']}"/>
        <faultDescr><descr>{t(iso['descr'])}</descr></faultDescr>
        <isolationProcedure>
          {empty}
          <isolationMainProcedure>
{chr(10).join(rows)}
          </isolationMainProcedure>
          <closeRqmts><reqCondGroup><noConds/></reqCondGroup></closeRqmts>
        </isolationProcedure>
      </faultIsolationProcedure>
    </faultIsolation>'''

    def ipd_body(self):
        rows = [self.figure_xml(1, '      ')]
        depth = {}
        for i, p in enumerate(self.parts, 1):
            depth[p['id']] = (1 if p['parent'] is None
                              else depth[p['parent']] + 1)
            number = self.part_number(p['id'])
            rows.append(
                f'      <catalogSeqNumber figureNumber="01" item="{i:03d}" '
                f'indenture="{min(depth[p["id"]], 9)}">\n'
                '        <itemSeqNumber itemSeqNumberValue="00A">\n'
                '          <quantityPerNextHigherAssy>'
                f'{p["quantity"]}</quantityPerNextHigherAssy>\n'
                f'          <partRef manufacturerCodeValue="{self.company}" '
                f'partNumberValue={quoteattr(number)}/>\n'
                '          <partSegment><itemIdentData><descrForPart>'
                f'{t(p["ipd_name"] or p["name"])}</descrForPart>'
                '</itemIdentData></partSegment>\n'
                '        </itemSeqNumber>\n'
                '      </catalogSeqNumber>')
        return ('    <illustratedPartsCatalog>\n' + '\n'.join(rows)
                + '\n    </illustratedPartsCatalog>')

    def brex_body(self):
        systems = []
        for system, (title, subs) in self.sns.items():
            inner = ''.join(
                f'<snsSubSystem><snsCode>{sub}</snsCode><snsTitle>{t(name)}'
                f'</snsTitle><snsSubSubSystem><snsCode>0</snsCode><snsTitle>'
                f'{t(name)}</snsTitle><snsAssy><snsCode>00</snsCode>'
                f'<snsTitle>{t(name)}</snsTitle></snsAssy></snsSubSubSystem>'
                '</snsSubSystem>'
                for sub, name in subs.items())
            systems.append(f'          <snsSystem><snsCode>{system}</snsCode>'
                           f'<snsTitle>{t(title)}</snsTitle>{inner}'
                           '</snsSystem>')
        return ('    <brex>\n      <snsRules>\n        <snsDescr>\n'
                + '\n'.join(systems)
                + '\n        </snsDescr>\n      </snsRules>\n'
                  '      <contextRules/>\n    </brex>')

    @staticmethod
    def info_name(d):
        return d.get('info') or INFO_NAMES[d['code'].info]

    # --- Dosyalar -----------------------------------------------------------

    def write_dms(self):
        self.csdb.mkdir(exist_ok=True)
        for old in self.csdb.glob('*.XML'):
            old.unlink()
        written = []
        for d in self.dms:
            if 'description' in d:
                body, schema = self.description_body(d), 'descript'
            elif 'isolation' in d:
                body, schema = self.isolation_body(d), 'fault'
            else:
                body, schema = self.procedure_body(d), 'proced'
            figures = [d['figure']] if d.get('figure') else []
            (self.csdb / d['code'].file()).write_text(
                self.dm_xml(d['code'], d['tech'], self.info_name(d), schema,
                            body, figures), encoding='utf-8')
            written.append((d['code'], d['tech'], self.info_name(d)))
        for dmc, schema, body, figures in (
                (self.ipd, 'ipd', self.ipd_body(), [1]),
                (self.brex, 'brex', self.brex_body(), [])):
            info = INFO_NAMES[dmc.info]
            (self.csdb / dmc.file()).write_text(
                self.dm_xml(dmc, self.product, info, schema, body, figures),
                encoding='utf-8')
            written.append((dmc, self.product, info))
        return written

    def pm_file(self):
        return f'PMC-{self.model}-{self.company}-00001-00_001-00_TR-TR.XML'

    def write_pm(self, written):
        year, month, day = self.date
        by_system = {}
        for dmc, tech, info in written:
            if dmc.info == '022':
                continue
            by_system.setdefault(dmc.system, []).append((dmc, tech, info))
        entries = []
        for system, (title, _) in self.sns.items():
            refs = ''.join(
                f'<dmRef><dmRefIdent>{dmc.xml()}</dmRefIdent>'
                '<dmRefAddressItems><dmTitle><techName>'
                f'{t(tech)}</techName><infoName>{t(info)}</infoName>'
                '</dmTitle></dmRefAddressItems></dmRef>'
                for dmc, tech, info in sorted(
                    by_system.get(system, []),
                    key=lambda r: (r[0].sub, r[0].info)))
            if refs:
                entries.append(f'    <pmEntry>\n      <pmEntryTitle>{t(title)}'
                               f'</pmEntryTitle>\n      {refs}\n    </pmEntry>')
        xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<pm xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.s1000d.org/S1000D_5-0/xml_schema_flat/pm.xsd">
  <identAndStatusSection>
    <pmAddress>
      <pmIdent>
        <pmCode modelIdentCode="{self.model}" pmIssuer="{self.company}" pmNumber="00001" pmVolume="00"/>
        <language languageIsoCode="tr" countryIsoCode="TR"/>
        <issueInfo issueNumber="001" inWork="00"/>
      </pmIdent>
      <pmAddressItems>
        <issueDate year="{year}" month="{month}" day="{day}"/>
        <pmTitle>{t(self.manual)}</pmTitle>
      </pmAddressItems>
    </pmAddress>
    <pmStatus issueType="new">
      <security securityClassification="01"/>
      <responsiblePartnerCompany enterpriseCode="{self.company}"><enterpriseName>NAYA</enterpriseName></responsiblePartnerCompany>
      <applic><displayText><simplePara>{t(self.applic)}</simplePara></displayText></applic>
      <brexDmRef>{self.brex.ref()}</brexDmRef>
      <qualityAssurance><unverified/></qualityAssurance>
    </pmStatus>
  </identAndStatusSection>
  <content>
{chr(10).join(entries)}
  </content>
</pm>
'''
        (self.csdb / self.pm_file()).write_text(xml, encoding='utf-8')

    def write_dml(self, written):
        year, month, day = self.date
        rows = ''.join(
            f'\n    <dmlEntry issueType="new">{dmc.ref()}'
            f'<responsiblePartnerCompany enterpriseCode="{self.company}">'
            '<enterpriseName>NAYA</enterpriseName>'
            '</responsiblePartnerCompany></dmlEntry>'
            for dmc, _, _ in sorted(written, key=lambda r: str(r[0])))
        xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<dml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.s1000d.org/S1000D_5-0/xml_schema_flat/dml.xsd">
  <identAndStatusSection>
    <dmlAddress>
      <dmlIdent>
        <dmlCode modelIdentCode="{self.model}" senderIdent="{self.company}" dmlType="s" yearOfDataIssue="{year}" seqNumber="00001"/>
        <issueInfo issueNumber="001" inWork="00"/>
      </dmlIdent>
      <dmlAddressItems><issueDate year="{year}" month="{month}" day="{day}"/></dmlAddressItems>
    </dmlAddress>
    <dmlStatus issueType="new"><security securityClassification="01"/><brexDmRef>{self.brex.ref()}</brexDmRef></dmlStatus>
  </identAndStatusSection>
  <dmlContent>{rows}
  </dmlContent>
</dml>
'''
        (self.csdb / f'DML-{self.model}-{self.company}-S-{year}-00001'
                     '_001-00.XML').write_text(xml, encoding='utf-8')

    def write_maps(self):
        self.map.mkdir(exist_ok=True)
        parts = []
        for p in self.parts:
            entry = {'id': p['id'], 'name': p['name']}
            if p['parent']:
                entry['parent'] = p['parent']
            entry.update({
                'sns': p['sns'], 'meshNodes': p['nodes'], 'zone': p['zone'],
                'function': p['function'],
                'ipd': {'dmc': str(self.ipd), 'figure': '01',
                        'item': p['item']},
            })
            if p['procedures']:
                entry['procedures'] = {k: str(v)
                                       for k, v in p['procedures'].items()}
            parts.append(entry)
        dump(self.map / 'parts.json', {'parts': parts})

        faults = []
        for fid, pid, symptoms, cause, severity, isolation, repair in (
                self.faults):
            f = {'id': fid, 'part': pid, 'symptoms': symptoms, 'cause': cause,
                 'severity': severity}
            if isolation:
                f['isolation'] = str(isolation)
            if repair:
                f['repair'] = str(repair)
            faults.append(f)
        dump(self.map / 'faults.json', {
            'symptoms': [{'id': i, 'text': text} for i, text in self.symptoms],
            'faults': faults,
        })
        dump(self.map / 'zones.json', {'zones': [
            {'id': i, 'name': n, **({'parent': p} if p else {})}
            for i, n, p in self.zones]})

    def check(self):
        """Tablolar arasındaki tutarlılık: kimlikler tek, başvurular var."""
        ids = [p['id'] for p in self.parts]
        assert len(ids) == len(set(ids)), 'aynı kimlikli iki parça var'
        zones = {z[0] for z in self.zones}
        symptoms = {s[0] for s in self.symptoms}
        for p in self.parts:
            assert p['zone'] in zones, f'{p["id"]}: bölge yok'
            assert p['parent'] is None or p['parent'] in ids, \
                f'{p["id"]}: üst parça yok'
        used = set()
        for fid, pid, syms, *_ in self.faults:
            assert pid in ids, f'{fid}: parça yok'
            assert set(syms) <= symptoms, f'{fid}: belirti yok'
            used |= set(syms)
        assert used == symptoms, f'kullanılmayan belirti: {symptoms - used}'
        # Her DMC başvurusu tanımlı bir DM'e, her arıza bulma adımı tanımlı
        # bir adıma gitmeli.
        defined = {str(d['code']) for d in self.dms} | {str(self.ipd)}
        refs = [(p['id'], v) for p in self.parts
                for v in p['procedures'].values()]
        refs += [(f[0], dmc) for f in self.faults for dmc in f[5:7] if dmc]
        for d in self.dms:
            nxt = d.get('next')
            for n in (nxt if isinstance(nxt, list) else [nxt] if nxt else []):
                refs.append((str(d['code']), n))
            iso = d.get('isolation')
            if not iso:
                continue
            ids = {st[0] for st in iso['steps']} | {e[0] for e in iso['ends']}
            for sid, _, _, yes, no in iso['steps']:
                assert {yes, no} <= ids, f'{d["code"]} {sid}: adım yok'
            refs += [(str(d['code']), e[2]) for e in iso['ends'] if e[2]]
        for where, dmc in refs:
            assert str(dmc) in defined, f'{where}: {dmc} tanımlı değil'

    def write(self):
        self.check()
        written = self.write_dms()
        self.write_pm(written)
        self.write_dml(written)
        self.write_maps()
        print(f'{len(written)} DM, {len(self.parts)} parça, '
              f'{len(self.faults)} arıza, {len(self.symptoms)} belirti')


def dump(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n',
                    encoding='utf-8')
