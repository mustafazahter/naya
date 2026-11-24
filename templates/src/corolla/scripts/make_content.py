"""Corolla şablonunun S1000D içeriğini ve parça haritasını üretir.

    python3 make_content.py

`csdb/` altındaki DM, PM ve DML dosyaları ile `map/` altındaki parts,
faults ve zones dosyaları buradan yazılır. Elle düzenlemek yerine buradaki
tabloları değiştirip betiği yeniden çalıştırın; böylece DMC'ler, parça
haritası ve arızalar birbiriyle tutarlı kalır.

Var olan DMC'ler değiştirilmez: teşhis geçmişi ve testler onlara bağlı.
Yeni bir DM eklerken aynı sistem, alt sistem ve bilgi kodunda başka DM
varsa `disassy` ('01', '02'...) ile ayırın; betik aynı kodu iki kez
kullanmaya izin vermez.

Değerler 1ZZ-FE ve E100 Corolla için yayımlanmış servis verilerinden
alındı (kompresyon, buji aralığı, supap boşluğu, sensör dirençleri, yakıt
basıncı...). Tam değeri bilinmeyen sarf malzemelerinin miktarı yazılmaz
("Gerektiği kadar").
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE.parent.parent / 'scripts'))

from s1000d_content import Content  # noqa: E402

# --- SNS ------------------------------------------------------------------

# Sistem kodu → (başlık, {alt sistem: başlık}).
SNS = {
    'D00': ('Araç', {}),
    'DA0': ('Gövde', {'1': 'Kapılar', '2': 'Kaput ve bagaj kapağı',
                      '3': 'Tamponlar ve ızgara', '4': 'Camlar ve silecekler',
                      '5': 'Aynalar', '6': 'Koltuklar, emniyet kemerleri ve '
                      'hava yastığı', '7': 'İç döşeme'}),
    'DA1': ('Motor', {'1': 'Blok, silindir kapağı ve pistonlar',
                      '2': 'Triger zinciri', '3': 'Yağlama',
                      '4': 'Soğutma', '5': 'Ateşleme',
                      '6': 'Emme ve egzoz', '7': 'Yakıt sistemi',
                      '8': 'Motor yönetimi', '9': 'Emisyon kontrolü'}),
    'DA2': ('Güç aktarma', {'1': 'Şanzıman ve debriyaj',
                            '2': 'Aks milleri'}),
    'DA3': ('Fren sistemi', {'1': 'Ön frenler', '2': 'Arka frenler',
                             '3': 'Fren servosu ve hidrolik',
                             '4': 'El freni'}),
    'DA4': ('Süspansiyon ve direksiyon', {'1': 'Ön süspansiyon',
                                          '2': 'Arka süspansiyon',
                                          '3': 'Direksiyon'}),
    'DA5': ('Tekerlekler', {'1': 'Lastikler', '2': 'Tekerlek rulmanları'}),
    'DA6': ('Elektrik ve aydınlatma', {'1': 'Akü', '2': 'Farlar ve lambalar',
                                       '3': 'Şarj sistemi',
                                       '4': 'Marş sistemi',
                                       '5': 'Gösterge paneli',
                                       '6': 'Sigortalar ve kablo demeti',
                                       '7': 'Elektrikli camlar ve kilitler',
                                       '8': 'Korna'}),
    'DA7': ('Isıtma ve klima', {'1': 'Isıtma ve havalandırma',
                                '2': 'Klima'}),
}

# --- Çizimler ---------------------------------------------------------------

# Numara → başlık. Dosyalar `render_icn.py` ile modelden üretilir.
FIGURES = {
    1: 'Araç, soldan görünüş',
    2: 'Motor bölmesi',
    3: '1ZZ-FE motor',
    4: 'Ön fren ve süspansiyon',
    5: 'Ateşleme bobinleri ve bujiler',
    6: 'Tekerlek ve lastik',
    7: 'Kabin: gösterge paneli, koltuklar ve pedallar',
    8: 'Arka süspansiyon ve fren',
    9: 'Araç altı: egzoz hattı ve yakıt deposu',
    10: 'Soğutma sistemi: radyatör, fan ve hortumlar',
    11: 'Şarj ve marş: alternatör, marş motoru ve akü',
}

C = Content(
    HERE, model='NAYACAR',
    applic='Toyota Corolla E100, 1ZZ-FE motorlu',
    product='Toyota Corolla E100',
    manual='Toyota Corolla E100 bakım el kitabı',
    sns=SNS, figures=FIGURES)
code, part = C.code, C.part


def dm(**kwargs):
    """Aynı DMC iki kez tanımlanırsa durur; yoksa dosyalar üst üste yazılır."""
    if str(kwargs['code']) in {str(d['code']) for d in C.dms}:
        raise ValueError(f'{kwargs["code"]} iki kez tanımlandı')
    return C.dm(**kwargs)


SHOP = 'yetkili servise başvurun'

# --- DM içerikleri ---------------------------------------------------------
#
# Alanlar `templates/scripts/s1000d_content.py` başında anlatılıyor.

# ===========================================================================
# Genel
# ===========================================================================

VEHICLE = dm(
    code=code('D00'), tech='Toyota Corolla E100', figure=1,
    description=[
        ('Genel', [
            'Toyota Corolla E100, 1991-1997 yılları arasında üretilen '
            'önden çekişli, dört kapılı bir sedandır. Orijinalinde 4A-FE ya '
            'da 7A-FE motor bulunur; bu şablonda araç, sonraki nesil '
            'Corolla\'nın 1,8 litrelik 1ZZ-FE motoruyla gösterilir.',
            'Motor ön tarafta enine durur; gücü sol taraftaki şanzıman '
            'üzerinden ön tekerleklere iletilir.',
            'Modeldeki araç sağdan direksiyonlu Japonya modelidir; sürücü '
            'kapısı sağ ön kapıdır.',
        ]),
        ('Sistemler', [
            'Gövde: kapılar, kaput, bagaj kapağı, tamponlar, camlar, '
            'silecekler, aynalar ve kabin döşemesi.',
            'Motor: blok ve silindir kapağı, triger zinciri, yağlama, '
            'soğutma, ateşleme, yakıt, motor yönetimi, emme, egzoz ve '
            'emisyon kontrolü.',
            'Güç aktarma: beş ileri manuel şanzıman, hidrolik debriyaj ve '
            'iki ön aks mili.',
            'Fren sistemi: önde havalandırmalı disk; bu modelde arkada da '
            'disk var (E100 sedanların çoğunda arkada kampana fren '
            'bulunur). Vakumlu fren servosu, mekanik el freni. Bu '
            'donanımda ABS yok; ABS bazı pazarlarda opsiyondu.',
            'Süspansiyon: önde ve arkada MacPherson tipi amortisörler, '
            'hidrolik destekli kremayer direksiyon.',
            'Elektrik: 12 V akü, alternatör, marş motoru, farlar ve '
            'lambalar, elektrikli camlar ve merkezi kilit.',
            'Isıtma ve klima: motor suyuyla çalışan kalorifer, R-134a '
            'soğutucu akışkanlı klima.',
        ]),
        ('Teknik veriler', [
            'Motor: 1ZZ-FE, 4 silindir sıralı, 16 supap, çift eksantrik '
            '(DOHC), 1794 cm³, sıkıştırma oranı 10,0:1.',
            'Lastikler: 175/65 R14. Lastik basıncı ön ve arka 2,2 bar.',
            'Motor yağı: 5W-30 (API SL ya da üstü), filtreyle birlikte '
            'yaklaşık 3,7 litre.',
            'Soğutma suyu: uzun ömürlü etilen glikol antifriz, %50 karışım; '
            'sistem yaklaşık 6 litre.',
            'Şanzıman yağı: API GL-4, SAE 75W-90. Fren hidroliği: DOT 3 ya da '
            'DOT 4. Hidrolik direksiyon yağı: ATF Dexron II/III.',
            'Bijon somunu sıkma torku: 103 N·m.',
        ]),
    ])

dm(code=code('D00', info='300'), tech='Araç', info='Periyodik kontrol',
   conditions=['Araç düz zeminde, motor soğuk.'],
   steps=[
       ('Her 10 000 km\'de ya da yılda bir', [
           'Motor yağını ve yağ filtresini değiştirin.',
           'Soğutma suyu, fren hidroliği, direksiyon yağı ve cam suyu '
           'seviyelerini kontrol edin.',
           'Lastik basınçlarını, diş derinliğini ve balata kalınlığını '
           'kontrol edin; lastikleri çapraz değiştirin.',
           'Akü kutup başlarını, kayışı ve hortumları gözden geçirin.',
           'Bütün lambaları, korna ve silecekleri çalıştırarak deneyin.',
       ]),
       ('Her 40 000 km\'de', [
           'Hava filtresini değiştirin.',
           'Şanzıman yağını, aks mili körüklerini ve süspansiyon burçlarını '
           'kontrol edin.',
           'Fren hidroliğini değiştirin (en geç iki yılda bir).',
       ]),
       ('Her 100 000 km\'de', [
           'İridyum bujileri değiştirin.',
           'Supap boşluğunu kontrol edin.',
           'Soğutma suyunu değiştirin (ilk değişim 160 000 km, sonra her '
           '80 000 km).',
       ]),
   ])

# ===========================================================================
# Gövde
# ===========================================================================

BODY = dm(
    code=code('DA0'), tech='Gövde', figure=1,
    description=[
        ('Genel', [
            'Gövde tek parça (monokok) çelik kasadır; ayrı bir şasi yoktur. '
            'Ön çamurluklar, kaput, kapılar ve bagaj kapağı sökülebilir.',
            'Ön ve arka tamponlar plastiktir; içlerinde darbe emici '
            'köpük ve çelik bir travers bulunur.',
            'Ön tamponun köşelerinde sis lambaları, çamurlukların arkasında '
            'yan sinyal lambaları vardır.',
        ]),
        ('Paslanma', [
            'Paslanma en çok kapı altlarında, çamurluk kenarlarında ve '
            'bagaj tabanında başlar. Boyadaki taş izleri zamanında '
            'kapatılmalıdır.',
        ]),
    ])

BODY_CHECK = dm(
    code=code('DA0', info='300'), tech='Gövde', info='Paslanma kontrolü',
    figure=1, conditions=['Araç yıkanmış ve kuru.'],
    steps=[
        'Kapı altlarını (marşpiyel), tekerlek davlumbazlarının kenarlarını '
        've kapıların alt kenarlarını kontrol edin.',
        'Boyada kabarma görülen yeri hafifçe bastırın; altı yumuşaksa sac '
        'delinmeye başlamıştır.',
        'Bagaj tabanını ve stepne yuvasını su birikintisi ve pasa karşı '
        'kontrol edin.',
        'Gövde altında koruyucu kaplamanın kalktığı yerleri işaretleyin.',
        'Yüzeysel pası zımparalayıp astar ve boyayla kapatın; delinmiş '
        'sacın kaynakla onarımı için kaporta ustasına başvurun.',
    ])

DOORS = dm(
    code=code('DA0', '1', '300'), tech='Kapılar',
    supplies=[('Beyaz gres', None)],
    steps=[
        'Kapıları açıp kapatın; zorlanma ya da sarkma olmamalıdır.',
        'Menteşeleri ve kapı gergilerini temizleyip ince bir kat gresle '
        'yağlayın.',
        'Kapı fitillerini çatlak ve yırtığa karşı kontrol edin; yağmur suyu '
        'içeri giriyorsa fitili değiştirin.',
        'Kapı altındaki su tahliye deliklerini açık tutun.',
    ])

REGULATOR = dm(
    code=code('DA0', '1', '920'), tech='Cam krikosu', figure=1,
    tools=[('Döşeme sökme aparatı', 1), ('Lokma takımı', 1)],
    spares=[('Cam krikosu, motoruyla', 1)],
    cautions=['Kapı döşemesinin tırnakları kolay kırılır; sökme aparatını '
              'tırnakların yanına sokun.'],
    steps=[
        'Akünün eksi kutbunu sökün.',
        'Kapı kolu çerçevesini, cam düğmesini ve döşeme vidalarını sökün; '
        'döşemeyi tırnaklarından ayırıp kaldırın.',
        'Nem örtüsünü dikkatle soyun.',
        'Camı cıvatalarının görüneceği yüksekliğe getirin, cam tutucu '
        'cıvatalarını sökün ve camı bantla yukarıda sabitleyin.',
        'Kriko cıvatalarını sökün, soketi çıkarın ve krikoyu kapının '
        'boşluğundan çıkarın.',
        'Yenisini ters sırayla takın; cıvataları 8 N·m\'de sıkın. Döşemeyi '
        'takmadan önce camı birkaç kez inip kaldırarak deneyin.',
    ])

LOCK = dm(
    code=code('DA0', '1', '920', '01'), tech='Kapı kilidi ve kilit motoru',
    tools=[('Döşeme sökme aparatı', 1), ('Torx anahtar takımı', 1)],
    spares=[('Kapı kilit mekanizması, motoruyla', 1)],
    steps=[
        'Akünün eksi kutbunu sökün; kapı döşemesini ve nem örtüsünü sökün.',
        'Dış kol ve kilit göbeği çubuklarını klipslerinden ayırın.',
        'Kilidin kapı kenarındaki üç Torx vidasını sökün ve kilidi soketiyle '
        'birlikte çıkarın.',
        'Yeni kilidi takın, vidaları 5 N·m\'de sıkın ve çubukları bağlayın.',
        'Kapıyı açıkken anahtar, iç kol ve merkezi kilitle deneyin; sonra '
        'döşemeyi takın.',
    ])

SEALS = dm(
    code=code('DA0', '1', '920', '02'), tech='Kapı fitili',
    spares=[('Kapı fitili', 1)], supplies=[('Fitil yapıştırıcısı', None)],
    steps=[
        'Eski fitili kapı çerçevesinden yavaşça çekip sökün.',
        'Yuvayı yapıştırıcı kalıntısından ve kirden temizleyin.',
        'Yeni fitili üst köşeden başlayarak yuvaya bastırın; köşelerde '
        'gerdirmeyin.',
        'Kapıyı kapatıp hortumla su tutarak sızdırmazlığı deneyin.',
    ])

HOOD_LATCH = dm(
    code=code('DA0', '2', '271'), tech='Kaput kilidi', info='Ayar',
    supplies=[('Beyaz gres', None)],
    steps=[
        'Kaputu açın; kilidi ve emniyet mandalını tel fırçayla temizleyin.',
        'Kilit mekanizmasını ve kaput açma telinin ucunu gresleyin.',
        'Kaput kendi ağırlığıyla kapanmıyorsa kilidin iki cıvatasını '
        'gevşetip kilidi aşağı kaydırın; kaput gövdeyle aynı hizada '
        'kapanana kadar ayarlayın.',
        'Kaput lastik tamponlarını çevirerek kaputun önde titremesini '
        'önleyin.',
        'Cıvataları 8 N·m\'de sıkın ve kaputu birkaç kez açıp kapatarak '
        'deneyin.',
    ])

WINDSHIELD_CHECK = dm(
    code=code('DA0', '4', '300'), tech='Ön cam', figure=1,
    steps=[
        'Camı içeriden ve dışarıdan, sürücünün görüş alanından başlayarak '
        'kontrol edin.',
        'Bir madeni paradan küçük taş izleri reçine dolgusuyla '
        'onarılabilir; izi bantla kapatıp kir girmesini önleyin.',
        'Çatlak ya da sürücü görüş alanındaki taş izi varsa cam '
        'değiştirilmelidir.',
        'Cam kenarındaki contada su sızıntısı olup olmadığını yağmur '
        'sonrasında kontrol edin.',
    ])

WINDSHIELD = dm(
    code=code('DA0', '4', '920', '03'), tech='Ön cam',
    tools=[('Cam kesme teli', 1), ('Vantuz', 2), ('Yapıştırıcı tabancası', 1)],
    spares=[('Ön cam', 1)], supplies=[('Poliüretan cam yapıştırıcısı', None),
                                      ('Cam astarı', None)],
    warnings=['Cam iki kişiyle ve vantuzlarla taşınmalıdır.'],
    cautions=['Yapıştırıcı kuruyana kadar (en az 2 saat) aracı kullanmayın, '
              'kapıları sert kapatmayın.'],
    steps=[
        'Silecek kollarını, kaput üstü havalandırma ızgarasını, dikiz '
        'aynasını ve cam çıtalarını sökün.',
        'Eski yapıştırıcıyı kesme teliyle cam çevresinde keserek camı '
        'ayırın ve vantuzlarla kaldırın.',
        'Gövdedeki yapıştırıcıyı 1-2 mm kalınlıkta bırakacak şekilde '
        'düzeltin; boya açılan yerlere astar sürün.',
        'Yeni camın kenarına astar sürün ve yapıştırıcıyı kesintisiz bir '
        'şerit halinde çekin.',
        'Camı vantuzlarla yerine oturtun, bantla sabitleyin ve sökülen '
        'parçaları takın.',
    ])

WIPERS = dm(
    code=code('DA0', '4', '920'), tech='Silecek lastikleri',
    spares=[('Silecek süpürgesi, sürücü tarafı 550 mm', 1),
            ('Silecek süpürgesi, yolcu tarafı 400 mm', 1)],
    steps=[
        'Silecek kolunu camdan kaldırın.',
        'Süpürgenin ortasındaki tırnağa bastırıp süpürgeyi koldan kaydırarak '
        'çıkarın.',
        'Yeni süpürgeyi tık sesi gelene kadar kola geçirin.',
        'Kolu yavaşça cama indirin; sileceği çalıştırıp camı iz bırakmadan '
        'sildiğini kontrol edin.',
    ])

WIPER_ISO = dm(
    code=code('DA0', '4', '421'), tech='Silecek ve yıkama sistemi',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA0-001',
        'descr': 'Silecekler çalışmıyor, yerine dönmüyor ya da cam suyu '
                 'fışkırmıyor.',
        'steps': [
            ('stp-0001', 'Kontağı açın ve sileceği her kademede çalıştırın.',
             'Silecekler hiç hareket etmiyor mu?', 'stp-0002', 'stp-0003'),
            ('stp-0002', 'Sigorta kutusunda WIPER sigortasını kontrol edin.',
             'Sigorta atmış mı?', 'end-fuse', 'stp-0004'),
            ('stp-0003', 'Sileceği kapatın.', 'Kollar camın altındaki '
             'yerlerine dönmeden duruyor mu?', 'end-motor', 'stp-0005'),
            ('stp-0004', 'Silecek motorunun soketinde kontak açıkken ve '
             'düğme açıkken 12 V olup olmadığını ölçün.', 'Gerilim var mı?',
             'end-motor', 'end-switch'),
            ('stp-0005', 'Cam suyu düğmesine basın ve depoyu dinleyin.',
             'Pompanın vızıltısı geliyor ama su gelmiyor mu?', 'end-nozzle',
             'end-washer'),
        ],
        'ends': [
            ('end-fuse', 'Sigortayı değiştirin; yeniden atarsa kısa devreyi '
             'arayın.', code('DA6', '6', '300')),
            ('end-motor', 'Silecek motoru ya da içindeki park anahtarı '
             'arızalı; motoru değiştirin.', code('DA0', '4', '920', '01')),
            ('end-switch', 'Motora gerilim gelmiyor: silecek kolu anahtarı ya '
             'da kablo arızalı; ' + SHOP + '.', None),
            ('end-nozzle', 'Depo dolu ise memeler ya da hortum tıkalı; '
             'memeleri iğneyle açın, hortumu kontrol edin.',
             code('DA0', '4', '920', '02')),
            ('end-washer', 'Cam suyu pompası çalışmıyor; pompayı kontrol '
             'edip değiştirin.', code('DA0', '4', '920', '02')),
        ],
    })

WIPER_MOTOR = dm(
    code=code('DA0', '4', '920', '01'), tech='Silecek motoru',
    tools=[('Lokma takımı', 1), ('Silecek kolu çektirmesi', 1)],
    spares=[('Silecek motoru', 1)],
    steps=[
        'Sileceği park konumunda kapatın, kontağı kapatın ve akünün eksi '
        'kutbunu sökün.',
        'Silecek kollarının somun kapaklarını açın, somunları sökün ve '
        'kolları çektirmeyle çıkarın.',
        'Torpido üstü havalandırma ızgarasını sökün.',
        'Motorun soketini çıkarın, mekanizma cıvatalarını sökün ve motoru '
        'mekanizmayla birlikte çıkarın.',
        'Motoru mekanizmadan ayırın; yeni motoru park konumunda takın.',
        'Takarken kolları camın altındaki çizgiye hizalayın ve somunları '
        '20 N·m\'de sıkın.',
    ])

WASHER = dm(
    code=code('DA0', '4', '920', '02'), tech='Cam suyu pompası',
    spares=[('Cam suyu pompası', 1)],
    supplies=[('Cam suyu, antifrizli', None)],
    steps=[
        'Depoyu boşaltın ya da hortumu sıkıştırın.',
        'Pompanın soketini ve hortumunu çıkarın; pompayı lastik '
        'yuvasından çekerek sökün.',
        'Yeni pompayı lastik yuvasına bastırın, hortumu ve soketi takın.',
        'Depoyu doldurun ve memelerin camın ortasına fışkırttığını '
        'kontrol edin; gerekirse memeleri iğneyle yönlendirin.',
    ])

MIRROR = dm(
    code=code('DA0', '5', '920'), tech='Dış dikiz aynası camı',
    spares=[('Dış ayna camı', 1)],
    warnings=['Kırık ayna camı keskindir; eldiven giyin.'],
    steps=[
        'Ayna camının üst kenarını içe doğru bastırın.',
        'Camın alt kenarına plastik bir aparat sokup camı tutucusundan '
        'kurtarın.',
        'Yeni camı tutucunun tırnaklarına hizalayıp ortasından avuç içiyle '
        'bastırarak oturtun.',
        'Aynayı içeriden ayar koluyla bütün yönlere çevirerek deneyin.',
    ])

BELT_CHECK = dm(
    code=code('DA0', '6', '300'), tech='Emniyet kemerleri', figure=7,
    steps=[
        'Kemeri sonuna kadar çekin; kayışta yırtık, kesik ve renk solması '
        'olup olmadığına bakın.',
        'Kemeri bırakın; makara kayışı kendiliğinden ve sonuna kadar '
        'sarmalıdır.',
        'Kemeri sert bir hareketle çekin; makara hemen kilitlenmelidir.',
        'Toka dilini takıp çekin; toka tutmalı ve düğmeye basınca kolayca '
        'bırakmalıdır.',
        'Kilitlenmeyen ya da sarmayan kemer değiştirilmelidir.',
    ])

BELT = dm(
    code=code('DA0', '6', '920'), tech='Emniyet kemeri', figure=7,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Emniyet kemeri, makarasıyla', 1)],
    warnings=['Emniyet kemeri onarılmaz; arızalı kemer bütün olarak '
              'değiştirilir. Bağlantı cıvatalarını yeniden kullanmayın.'],
    steps=[
        'Orta direk döşemesini ve kapı eşiği çıtasını sökün.',
        'Omuz bağlantısının ve alt bağlantının cıvatalarını sökün.',
        'Makaranın cıvatasını sökün ve kemeri makarasıyla çıkarın.',
        'Yenisini takın; bütün bağlantı cıvatalarını 42 N·m\'de sıkın.',
        'Makaranın dik durduğunu ve kemerin hem sarıp hem kilitlendiğini '
        'deneyin.',
    ])

SEAT = dm(
    code=code('DA0', '6', '920', '01'), tech='Ön koltuk rayı', figure=7,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    supplies=[('Beyaz gres', None)],
    steps=[
        'Koltuğu en arkaya alıp ön cıvataları, en öne alıp arka cıvataları '
        'sökün.',
        'Koltuğun altındaki kemer tokası ve varsa sensör soketini çıkarın; '
        'koltuğu araçtan alın.',
        'Rayları temizleyin; kilit mandalının yayını ve dişlerini kontrol '
        'edin.',
        'Rayları gresleyin; eğilmiş ya da dişi aşınmış rayı değiştirin.',
        'Koltuğu takın, cıvataları 37 N·m\'de sıkın ve rayın her konumda '
        'kilitlendiğini deneyin.',
    ])

SRS_ISO = dm(
    code=code('DA0', '6', '421'), tech='Hava yastığı sistemi (SRS)',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA0-002',
        'descr': 'SRS uyarı lambası kontak açıldıktan 6 saniye sonra '
                 'sönmüyor ya da hiç yanmıyor.',
        'steps': [
            ('stp-0001', 'Kontağı açın ve SRS lambasını izleyin.',
             'Lamba hiç yanmıyor mu?', 'end-bulb', 'stp-0002'),
            ('stp-0002', 'Akü gerilimini ölçün.', 'Gerilim 11 V\'un altında '
             'mı?', 'end-battery', 'end-shop'),
        ],
        'ends': [
            ('end-bulb', 'Lamba ampulü ya da gösterge paneli arızalı; '
             'sistem kendini denetleyemediği için ' + SHOP + '.', None),
            ('end-battery', 'Aküyü şarj edin ve lambayı yeniden kontrol '
             'edin.', code('DA6', '1', '300')),
            ('end-shop', 'Sistemde kayıtlı arıza var. Hava yastığı ve '
             'bağlantıları yalnız eğitimli personelce ele alınmalıdır; '
             + SHOP + '.', None),
        ],
    })

# ===========================================================================
# Motor: mekanik
# ===========================================================================

ENGINE = dm(
    code=code('DA1'), tech='Motor', figure=3,
    description=[
        ('Genel', [
            '1ZZ-FE alüminyum bloklu, dört silindirli bir benzinli '
            'motordur. Silindir kapağında iki eksantrik mili ve silindir '
            'başına dört supap vardır. Supap boşluğu ayar pullarıyla '
            'ayarlanır; hidrolik itici yoktur.',
            'Krank mili pistonlardan gelen gidip gelme hareketini dönme '
            'hareketine çevirir. Eksantrik milleri krank miline triger '
            'zinciriyle bağlıdır.',
        ]),
        ('Çalışma', [
            'Emme manifoldundan gelen hava enjektörlerin püskürttüğü yakıtla '
            'karışır, silindirde sıkıştırılır ve bujinin kıvılcımıyla '
            'yanar. Yanmış gazlar egzoz manifoldundan çıkar.',
            'Her silindirin kendi ateşleme bobini vardır; bobin bujinin '
            'üstüne oturur. Ateşleme sırası 1-3-4-2.',
        ]),
        ('Bakım', [
            'Triger zinciri motor ömrü boyunca çalışacak şekilde '
            'tasarlanmıştır; düzenli değişimi yoktur. Zincirin ömrü yağın '
            'temizliğine bağlıdır.',
            'Aksesuarlar (alternatör, hidrolik direksiyon pompası, klima '
            'kompresörü) krank kasnağından kanallı kayışla döner.',
        ]),
    ])

ENGINE_ISOLATE = dm(
    code=code('DA1', info='421'), tech='Motor', info='Çalışmıyor: arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-001',
        'descr': 'Motor çalışmıyor, marş basmıyor ya da marş basıyor ama '
                 'motor ateş almıyor.',
        'steps': [
            ('stp-0001', 'Kontağı açın ve göstergeleri izleyin; sonra marşa '
             'basın.', 'Marş motoru dönüyor mu?', 'stp-0003', 'stp-0002'),
            ('stp-0002', 'Akü gerilimini voltmetreyle ölçün.',
             'Gerilim 12,2 V\'un altında mı?', 'end-battery', 'end-starter'),
            ('stp-0003', 'EFI sigortasını çıkarın. Bir bobini söküp '
             'bujisini takın; bujiyi yalıtımlı penseyle ya da kıvılcım test '
             'cihazıyla gövdeye dayayıp marşa basın.',
             'Bujide kıvılcım var mı?', 'stp-0004', 'end-ignition'),
            ('stp-0004', 'EFI sigortasını takın. Marşa basarken yakıt '
             'pompasının sesini dinleyin ya da yakıt hattında basınç olup '
             'olmadığını kontrol edin.', 'Yakıt geliyor mu?',
             'end-compression', 'end-fuel'),
        ],
        'ends': [
            ('end-battery', 'Aküyü şarj edin ya da değiştirin.',
             code('DA6', '1', '300')),
            ('end-starter', 'Akü dolu ama marş dönmüyor: marş sistemini '
             'kontrol edin.', code('DA6', '4', '421')),
            ('end-ignition', 'Hiçbir silindirde kıvılcım yok: önce krank '
             'konum sensörünü ölçün; sağlamsa IG sigortasını ve motor '
             'beynini kontrol edin.', code('DA1', '8', '361', '01')),
            ('end-fuel', 'Yakıt gelmiyor: yakıt basıncını kontrol edin.',
             code('DA1', '7', '421')),
            ('end-compression', 'Kıvılcım ve yakıt var: kompresyonu ölçün.',
             code('DA1', '1', '361')),
        ],
    })

COMPRESSION = dm(
    code=code('DA1', '1', '361'), tech='Silindirler',
    info='Kompresyon ölçümü',
    tools=[('Kompresyon ölçer', 1), ('Buji anahtarı, 16 mm', 1)],
    conditions=['Motor çalışma sıcaklığında.', 'Akü tam dolu.'],
    warnings=['Motor sıcakken egzoz manifolduna dokunmayın.'],
    steps=[
        'Yakıt pompası sigortasını çıkarın; motor ölçüm sırasında '
        'çalışmasın.',
        'Ateşleme bobinlerini ve bütün bujileri sökün.',
        ('Ölçün', [
            'Kompresyon ölçeri 1. silindirin buji yuvasına takın.',
            'Gaz pedalını sonuna kadar basılı tutun ve marşa 5 saniye '
            'basın.',
            'Göstergedeki en yüksek değeri yazın. Diğer silindirleri aynı '
            'şekilde ölçün.',
        ]),
        'Standart değer 1,5 MPa, en düşük değer 1,0 MPa\'dır. Silindirler '
        'arasındaki fark 0,1 MPa\'yı geçmemelidir.',
        'Değer düşükse buji yuvasından bir çay kaşığı motor yağı koyup '
        'yeniden ölçün. Değer yükselirse segmanlar, yükselmezse supaplar '
        'ya da silindir kapak contası sızdırıyordur.',
    ])

HEAD_GASKET = dm(
    code=code('DA1', '1', '920'), tech='Silindir kapak contası',
    figure=3,
    tools=[('Tork anahtarı', 1), ('Lokma takımı', 1),
           ('Düz cetvel ve sentil', 1)],
    spares=[('Silindir kapak contası', 1), ('Silindir kapak cıvatası', 10)],
    supplies=[('Soğutma suyu', 6), ('Motor yağı, 5W-30', 4)],
    warnings=['Silindir kapağını motor soğumadan sökmeyin; alüminyum kapak '
              'eğilebilir.'],
    steps=[
        'Soğutma suyunu ve motor yağını boşaltın.',
        'Emme ve egzoz manifoldlarını, ateşleme bobinlerini ve supap '
        'kapağını sökün.',
        '1. silindiri üst ölü noktaya (ÜÖN) getirip triger işaretlerini '
        'hizalayın. Zincir kapağını, gergiyi ve eksantrik millerini sökün; '
        'zinciri ve dişlileri işaretleyin.',
        ('Kapağı sökün', [
            'Silindir kapak cıvatalarını dıştan içe doğru, birkaç turda '
            'gevşetin.',
            'Kapağı kaldırın ve eski contayı çıkarın.',
        ]),
        'Blok ve kapak yüzeylerini temizleyin. Düz cetvel ve sentille '
        'çarpıklığı ölçün; 0,05 mm\'yi geçiyorsa kapak taşlanmalıdır.',
        ('Takın', [
            'Yeni contayı blok üzerindeki pimlere oturtun.',
            'Kapağı yerleştirin; yeni cıvataları içten dışa doğru üç '
            'aşamada sıkın: 49 N·m, sonra 90°, sonra yine 90°.',
        ]),
        'Triger zincirini işaretlere göre takın, sökülen parçaları ters '
        'sırayla yerine takın, yağ ve soğutma suyunu doldurun.',
    ])

ENGINE_NOISE = dm(
    code=code('DA1', '1', '421'), tech='Motor', info='Ses: arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-004',
        'descr': 'Motordan tıkırtı, şıkırtı ya da vuruntu sesi geliyor; '
                 'motor rölantide titriyor.',
        'steps': [
            ('stp-0001', 'Motor yağı seviyesini kontrol edin.',
             'Seviye alt işaretin altında mı?', 'end-oil', 'stp-0002'),
            ('stp-0002', 'Motoru soğukken çalıştırın.', 'Şıkırtı yalnız ilk '
             'saniyelerde mi, triger kapağı tarafından mı geliyor?',
             'end-chain', 'stp-0003'),
            ('stp-0003', 'Motor ısındıktan sonra stetoskopla supap kapağının '
             'üstünü dinleyin.', 'Devirle hızlanan düzenli bir tıkırtı '
             'var mı?', 'end-valves', 'stp-0004'),
            ('stp-0004', 'Motoru rölantide ve 2000 d/d\'de çalıştırıp motor '
             'takozlarını izleyin.', 'Motor gövdeye göre fazla sallanıyor '
             'ya da vites değiştirirken vuruyor mu?', 'end-mounts',
             'end-shop'),
        ],
        'ends': [
            ('end-oil', 'Yağı tamamlayın; kaçak varsa arayın.',
             code('DA1', '3', '300')),
            ('end-chain', 'Triger zincirini ve gergiyi kontrol edin.',
             code('DA1', '2', '300')),
            ('end-valves', 'Supap boşluğunu ölçün ve ayarlayın.',
             code('DA1', '1', '271')),
            ('end-mounts', 'Motor takozlarını kontrol edin.',
             code('DA1', info='300')),
            ('end-shop', 'Ses motorun alt tarafından geliyorsa ana yatak ya '
             'da biyel yatağı aşınmış olabilir; motoru çalıştırmayın ve '
             + SHOP + '.', None),
        ],
    })

VALVES = dm(
    code=code('DA1', '1', '271'), tech='Supap boşluğu', info='Ayar',
    figure=3,
    tools=[('Sentil takımı', 1), ('Mikrometre', 1), ('Lokma takımı', 1)],
    spares=[('Supap kapağı contası', 1)],
    conditions=['Motor soğuk.'],
    steps=[
        'Bobinleri ve supap kapağını sökün.',
        '1. silindiri sıkıştırma zamanında ÜÖN\'ye getirin (krank kasnağı '
        'işareti 0\'da, eksantrik dişlisi işaretleri yukarıda).',
        'Eksantrik kamının topuğu iticiye bakarken boşluğu sentille ölçün. '
        'Soğukta emme 0,15-0,25 mm, egzoz 0,25-0,35 mm olmalıdır.',
        'Krankı bir tur çevirip kalan supapları ölçün; bütün değerleri '
        'yazın.',
        'Sınır dışındaki supapların iticisini (ayar pulunu) mikrometreyle '
        'ölçün. Yeni itici kalınlığı = eski kalınlık + (ölçülen boşluk - '
        'hedef boşluk). Hedef emmede 0,20 mm, egzozda 0,30 mm.',
        'Eksantrik millerini söküp iticileri değiştirin, milleri '
        'işaretlerine göre takın ve kapak cıvatalarını 13 N·m\'de sıkın.',
        'Boşluğu yeniden ölçün, supap kapağını yeni contayla takın.',
    ])

HEAD_COVER_GASKET = dm(
    code=code('DA1', '1', '920', '01'), tech='Supap kapağı contası',
    figure=3,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Supap kapağı contası', 1)],
    supplies=[('Silikon conta macunu', None)],
    steps=[
        'Bobinlerin soketlerini çıkarın, bobinleri sökün.',
        'PCV hortumunu ve havalandırma hortumunu supap kapağından ayırın.',
        'Kapak cıvatalarını ve somunlarını dıştan içe gevşetip kapağı '
        'kaldırın.',
        'Eski contayı ve buji kuyusu contalarını çıkarın; yüzeyleri '
        'temizleyin.',
        'Zincir kapağıyla silindir kapağının birleştiği iki köşeye nohut '
        'büyüklüğünde silikon sürün.',
        'Yeni contayla kapağı yerleştirin; cıvataları ortadan dışa doğru '
        '9 N·m\'de sıkın.',
        'Motoru çalıştırıp kaçak olup olmadığını kontrol edin.',
    ])

TIMING_CHECK = dm(
    code=code('DA1', '2', '300'), tech='Triger zinciri', figure=3,
    conditions=['Motor soğuk.'],
    steps=[
        'Motoru soğukken çalıştırın ve ilk saniyelerdeki sesi dinleyin.',
        'Triger kapağı tarafından gelen metalik şıkırtı birkaç saniyede '
        'kesilmiyorsa zincir gergisi yağ basıncını tutamıyor olabilir.',
        'Motor yağı seviyesini ve yağın rengini kontrol edin. Koyu ve '
        'tortulu yağ zincirin ve gerginin erken aşınmasına yol açar.',
        'Supap kapağını sökün; zincirin eksantrik dişlilerindeki '
        'boşluğunu ve kızak üzerindeki aşınma izlerini kontrol edin.',
        'Zincir uzamışsa ya da kızakta derin izler varsa zinciri, gergiyi '
        've kızakları birlikte değiştirin (yetkili servis işi).',
    ])

TIMING_COVER_SEAL = dm(
    code=code('DA1', '2', '920'), tech='Ön krank keçesi', figure=3,
    tools=[('Krank kasnağı tutucusu', 1), ('Kasnak çektirmesi', 1),
           ('Keçe çakma aparatı', 1), ('Tork anahtarı', 1)],
    spares=[('Ön krank keçesi', 1)], supplies=[('Motor yağı, 5W-30', None)],
    steps=[
        'Aksesuar kayışını sökün.',
        'Kasnağı tutucuyla sabitleyip kasnak cıvatasını sökün; kasnağı '
        'çektirmeyle çıkarın.',
        'Eski keçeyi zincir kapağını çizmeden bir tornavidayla çıkarın.',
        'Yeni keçenin dudağına yağ sürün ve aparatla kapakla aynı hizaya '
        'gelene kadar çakın.',
        'Kasnağı takın, cıvatayı 138 N·m\'de sıkın; kayışı takın.',
        'Motoru çalıştırıp kaçak olup olmadığını kontrol edin.',
    ])

MOUNTS = dm(
    code=code('DA1', info='300'), tech='Motor takozları', figure=2,
    tools=[('Levye', 1), ('Kriko', 1)],
    steps=[
        'Kaputu açın; bir yardımcı freni basılı tutarken motoru rölantide '
        'çalıştırın.',
        'Yardımcı birinci vitese, sonra geri vitese takıp debriyajı yavaşça '
        'bıraksın. Motorun 1-2 cm\'den fazla oynaması takozun yırtıldığını '
        'gösterir.',
        'Motoru durdurun. Takozların lastiğinde çatlak, yırtık ve yağ '
        'şişmesi olup olmadığına bakın.',
        'Motoru karter altından tahta takozlu krikoyla hafifçe kaldırın; '
        'takoz metalinin lastikten ayrılıp ayrılmadığını görün.',
        'Arızalı takozu değiştirin; cıvataları motor ağırlığı üzerindeyken '
        'sıkın.',
    ])

MOUNT = dm(
    code=code('DA1', '0', '920'), tech='Motor takozu', figure=2,
    tools=[('Kriko', 1), ('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Motor takozu', 1)],
    steps=[
        'Motoru karter altından tahta takozlu krikoyla destekleyin.',
        'Takozun gövde ve motor tarafındaki cıvatalarını sökün.',
        'Motoru takoz çıkacak kadar kaldırıp takozu alın.',
        'Yeni takozu yerleştirin, cıvataları elle takın.',
        'Krikoyu indirip motor ağırlığı takoza binince cıvataları 52 N·m\'de '
        'sıkın.',
    ])

DRIVE_BELT = dm(
    code=code('DA1', '0', '920', '01'), tech='Aksesuar kayışı', figure=11,
    tools=[('Lokma takımı', 1), ('Kayış gerginlik ölçer', 1)],
    spares=[('Kanallı aksesuar kayışı', 1)],
    conditions=['Motor kapalı, kontak anahtarı çıkarılmış.'],
    steps=[
        'Kayışın kanallarında çatlak, parça kopması ve parlama olup '
        'olmadığına bakın; varsa değiştirin.',
        'Alternatörün kilit cıvatasını gevşetin ve ayar cıvatasıyla kayışı '
        'boşaltıp çıkarın.',
        'Yeni kayışı kasnakların kanallarına tam oturacak şekilde takın.',
        'Ayar cıvatasıyla kayışı gerin: yeni kayışta 7-9 mm, kullanılmışta '
        '10-12 mm sehim (98 N kuvvetle, en uzun açıklıkta).',
        'Kilit cıvatasını sıkın, motoru 5 dakika çalıştırıp gerginliği '
        'yeniden kontrol edin.',
    ])

# Yağlama
OIL_CHANGE = dm(
    code=code('DA1', '3', '241'), tech='Motor yağı ve yağ filtresi',
    info='Değişim', figure=2,
    tools=[('Yağ filtresi anahtarı', 1), ('Lokma, 14 mm', 1),
           ('Yağ toplama kabı', 1)],
    supplies=[('Motor yağı, 5W-30', 4)],
    spares=[('Yağ filtresi', 1), ('Karter tapası contası', 1)],
    warnings=['Sıcak yağ yakar. Motoru birkaç dakika çalıştırıp durdurun, '
              'yağ ılıkken boşaltın.'],
    steps=[
        'Aracı düz zeminde güvenli şekilde kaldırın.',
        'Karter tapasını sökün ve yağın tamamen akmasını bekleyin.',
        'Tapayı yeni contayla 37 N·m\'de sıkın.',
        ('Filtreyi değiştirin', [
            'Eski filtreyi filtre anahtarıyla sökün.',
            'Yeni filtrenin lastik contasına ince bir kat yağ sürün.',
            'Filtreyi conta oturunca elle 3/4 tur daha sıkın.',
        ]),
        'Yağ doldurma kapağından 3,7 litre yağ koyun.',
        'Motoru çalıştırıp filtrede ve tapada kaçak olmadığını kontrol '
        'edin. Motoru durdurup 5 dakika sonra seviyeyi çubukla kontrol '
        'edin.',
    ])

OIL_CHECK = dm(
    code=code('DA1', '3', '300'), tech='Motor yağı', info='Seviye kontrolü',
    figure=2, conditions=['Araç düz zeminde; motor durdurulalı 5 dakika '
                          'olmuş.'],
    steps=[
        'Yağ çubuğunu çekin, temizleyin ve sonuna kadar yerine itin.',
        'Çubuğu yeniden çekin; yağ izi iki işaret arasında olmalıdır.',
        'Seviye alt işaretteyse yağ doldurma kapağından az az yağ ekleyin. '
        'İki işaret arası yaklaşık 1 litredir.',
        'Motorun altında, karterde ve yağ filtresi çevresinde kaçak izi '
        'olup olmadığına bakın.',
    ])

OIL_ISO = dm(
    code=code('DA1', '3', '421'), tech='Yağlama sistemi',
    info='Yağ lambası ve yağ kaçağı: arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-005',
        'descr': 'Yağ basıncı lambası yanıyor ya da yanıp sönüyor; motorun '
                 'altında yağ lekesi var ya da yanık yağ kokusu geliyor.',
        'steps': [
            ('stp-0001', 'Motoru hemen durdurun ve yağ seviyesini kontrol '
             'edin.', 'Seviye alt işaretin altında mı?', 'stp-0002',
             'stp-0003'),
            ('stp-0002', 'Motoru temizleyip kısa süre çalıştırın; kaçağın '
             'nereden başladığını yukarıdan aşağıya izleyin.', 'Kaçak supap '
             'kapağının kenarından mı geliyor?', 'end-cover', 'stp-0004'),
            ('stp-0003', 'Yağ basınç müşirinin yerine manometre takıp '
             'basıncı ölçün.', 'Rölantide basınç 29 kPa\'nın üstünde mi?',
             'end-switch', 'end-pump'),
            ('stp-0004', 'Kasnak arkasına ve karter kenarına bakın.',
             'Kaçak ön krank keçesinden mi geliyor?', 'end-seal',
             'end-pan'),
        ],
        'ends': [
            ('end-cover', 'Supap kapağı contasını değiştirin; PCV valfini de '
             'kontrol edin.', code('DA1', '1', '920', '01')),
            ('end-switch', 'Basınç yeterli: yağ basınç müşiri ya da kablosu '
             'arızalı; müşiri değiştirin.', code('DA1', '3', '920')),
            ('end-pump', 'Basınç düşük: yağ pompası, emiş süzgeci ya da '
             'yataklar. Motoru çalıştırmayın; basıncı ölçün ve ' + SHOP
             + '.', code('DA1', '3', '361')),
            ('end-seal', 'Ön krank keçesini değiştirin.',
             code('DA1', '2', '920')),
            ('end-pan', 'Karter tapası contasını ya da karter contasını '
             'yenileyin; yağı tamamlayın.', code('DA1', '3', '241')),
        ],
    })

OIL_PRESSURE = dm(
    code=code('DA1', '3', '361'), tech='Yağ basıncı', info='Ölçüm',
    figure=3,
    tools=[('Yağ basınç manometresi', 1), ('Lokma, 24 mm', 1)],
    supplies=[('Sızdırmazlık macunu', None)],
    conditions=['Motor çalışma sıcaklığında, yağ seviyesi doğru.'],
    steps=[
        'Yağ basınç müşirinin soketini çıkarın ve müşiri sökün.',
        'Manometreyi müşirin deliğine takın.',
        'Motoru çalıştırın. Rölantide en az 29 kPa, 3000 d/d\'de '
        '150-550 kPa olmalıdır.',
        'Basınç düşükse yağ pompası, emiş süzgeci ya da yataklar '
        'aşınmıştır.',
        'Manometreyi sökün; müşirin dişlerine macun sürüp 15 N·m\'de '
        'sıkın.',
    ])

OIL_SWITCH = dm(
    code=code('DA1', '3', '920'), tech='Yağ basınç müşiri', figure=3,
    tools=[('Lokma, 24 mm', 1), ('Tork anahtarı', 1)],
    spares=[('Yağ basınç müşiri', 1)],
    supplies=[('Sızdırmazlık macunu', None)],
    steps=[
        'Müşirin soketini çıkarın ve müşiri sökün.',
        'Yeni müşirin dişlerine sızdırmazlık macunu sürün.',
        'Müşiri 15 N·m\'de sıkın ve soketi takın.',
        'Motoru çalıştırın; yağ lambası birkaç saniyede sönmeli ve müşirde '
        'kaçak olmamalıdır.',
    ])

# Soğutma
COOLING = dm(
    code=code('DA1', '4', '040'), tech='Soğutma sistemi', figure=10,
    description=[
        ('Genel', [
            'Su pompası soğutma suyunu motorun su ceketlerinde dolaştırır. '
            'Termostat 80-84 °C\'de açılmaya başlar, 95 °C\'de tam açıktır; '
            'su bundan sonra radyatörden geçerek soğur.',
            'Radyatör kapağı sistemi 74-103 kPa basınçta tutar; böylece su '
            '100 °C\'nin üstünde kaynamaz. Isınan suyun fazlası genleşme '
            'kabına gider, soğuyunca geri çekilir.',
            'Elektrikli fan, su sıcaklığı yükselince ya da klima '
            'çalışınca devreye girer.',
        ]),
        ('Bakım', [
            'Uzun ömürlü antifriz ilk 160 000 km\'de, sonra her 80 000 km\'de '
            'değiştirilir. Karışım %50 antifriz, %50 saf sudur.',
        ]),
    ])

COOLING_CHECK = dm(
    code=code('DA1', '4', '300'), tech='Soğutma sistemi', figure=10,
    warnings=['Motor sıcakken radyatör kapağını açmayın; basınçlı sıcak su '
              'fışkırabilir.'],
    steps=[
        'Motor soğukken genleşme kabındaki seviyenin FULL ve LOW çizgileri '
        'arasında olduğunu kontrol edin.',
        'Radyatörü, hortumları ve su pompası çevresini kaçak ve beyaz '
        'tortu izine karşı kontrol edin.',
        'Hortumları elle sıkın; sertleşmiş, çatlamış ya da şişmiş hortumu '
        'değiştirin.',
        'Radyatör peteklerinin önünü kapatan yaprak ve böcekleri temizleyin.',
        'Antifriz oranını antifriz ölçerle kontrol edin; -35 °C\'ye kadar '
        'koruma sağlamalıdır.',
    ])

OVERHEAT = dm(
    code=code('DA1', '4', '421'), tech='Soğutma sistemi',
    info='Hararet: arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-002',
        'descr': 'Hararet göstergesi yükseliyor, motor ısınıyor ya da '
                 'kaputun altından buhar çıkıyor.',
        'steps': [
            ('stp-0001', 'Motor soğuduktan sonra genleşme kabındaki seviyeye '
             'bakın.', 'Soğutma suyu LOW çizgisinin altında mı?',
             'stp-0002', 'stp-0003'),
            ('stp-0002', 'Radyatörü, hortumları ve su pompasını kaçağa '
             'karşı kontrol edin.', 'Bir kaçak izi var mı?', 'stp-0005',
             'stp-0004'),
            ('stp-0003', 'Motoru rölantide ısıtın ve fanın devreye girip '
             'girmediğini izleyin.', 'Fan çalışıyor mu?', 'stp-0006',
             'end-fan'),
            ('stp-0004', 'Motor çalışırken genleşme kabında sürekli kabarcık '
             'çıkıp çıkmadığına bakın.', 'Sürekli kabarcık var mı?',
             'end-gasket', 'end-cap'),
            ('stp-0005', 'Kaçağın yerini bulun.', 'Kaçak su pompasının '
             'tahliye deliğinden mi geliyor?', 'end-pump', 'end-hose'),
            ('stp-0006', 'Motor ısındıktan sonra radyatörün üst hortumunu '
             'elle yoklayın (dikkatli olun).', 'Üst hortum soğuk mu?',
             'end-thermostat', 'end-radiator'),
        ],
        'ends': [
            ('end-pump', 'Su pompası keçesi sızdırıyor; pompayı değiştirin.',
             code('DA1', '4', '920')),
            ('end-hose', 'Çatlak hortumu ya da gevşek kelepçeyi yenileyin.',
             code('DA1', '4', '920', '02')),
            ('end-fan', 'Fan sigortasını, rölesini ve fan motorunu kontrol '
             'edin.', code('DA1', '4', '320')),
            ('end-gasket', 'Yanma gazı soğutma suyuna karışıyor: silindir '
             'kapak contası yanmış olabilir. Önce kompresyonu ölçün.',
             code('DA1', '1', '361')),
            ('end-cap', 'Görünür kaçak yok: radyatör kapağını ve sistemin '
             'basınç tutmasını kontrol edin.', code('DA1', '4', '361')),
            ('end-thermostat', 'Termostat kapalı kalmış; termostatı '
             'değiştirin.', code('DA1', '4', '920', '01')),
            ('end-radiator', 'Su dolaşıyor ama soğumuyor: radyatör petekleri '
             'tıkanmış olabilir. Radyatörü kontrol edin, gerekirse '
             'değiştirin.', code('DA1', '4', '920', '03')),
        ],
    })

COLD_ENGINE = dm(
    code=code('DA1', '4', '421', '01'), tech='Soğutma sistemi',
    info='Motor ısınmıyor: arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-006',
        'descr': 'Motor çalışma sıcaklığına geç geliyor ya da hiç gelmiyor; '
                 'kalorifer ılık üflüyor.',
        'steps': [
            ('stp-0001', 'Soğutma suyu seviyesini kontrol edin.',
             'Seviye düşük mü?', 'end-fill', 'stp-0002'),
            ('stp-0002', 'Motoru soğukken çalıştırıp radyatörün üst '
             'hortumunu yoklayın.', 'Hortum motorla birlikte hemen ısınıyor '
             'mu?', 'end-thermostat', 'stp-0003'),
            ('stp-0003', 'Göstergenin kablosunu ve su sıcaklık sensörünü '
             'ölçün.', 'Sensör direnci değer tablosunun dışında mı?',
             'end-sensor', 'end-heater'),
        ],
        'ends': [
            ('end-fill', 'Suyu tamamlayın ve sistemin havasını alın.',
             code('DA1', '4', '210')),
            ('end-thermostat', 'Termostat açık kalmış; değiştirin.',
             code('DA1', '4', '920', '01')),
            ('end-sensor', 'Su sıcaklık sensörünü değiştirin.',
             code('DA1', '8', '920', '02')),
            ('end-heater', 'Motor ısınıyor ama kalorifer üflemiyor: '
             'kalorifer sistemini kontrol edin.', code('DA7', '1', '421')),
        ],
    })

COOLANT_CHANGE = dm(
    code=code('DA1', '4', '210'), tech='Soğutma suyu',
    info='Değişim ve hava alma', figure=10,
    tools=[('Toplama kabı', 1), ('Antifriz ölçer', 1)],
    supplies=[('Soğutma suyu', 6)],
    warnings=['Motor sıcakken radyatör kapağını açmayın.',
              'Antifriz zehirlidir; dökülen sıvıyı hemen temizleyin.'],
    steps=[
        'Kaloriferi en sıcağa alın. Radyatör kapağını açın.',
        'Radyatörün alt musluğunu ve bloğun boşaltma tapasını açıp suyu '
        'boşaltın.',
        'Musluğu ve tapayı kapatın (tapa 13 N·m).',
        'Radyatörü boynuna kadar %50 karışımla doldurun; genleşme kabını '
        'FULL çizgisine kadar doldurun.',
        'Kapak açıkken motoru çalıştırıp fan iki kez devreye girene kadar '
        'ısıtın; seviye düştükçe tamamlayın, üst hortumu sıkarak havayı '
        'çıkarın.',
        'Kapağı kapatın; motor soğuyunca genleşme kabındaki seviyeyi '
        'yeniden kontrol edin.',
    ])

COOLANT_PRESSURE = dm(
    code=code('DA1', '4', '361'), tech='Soğutma sistemi',
    info='Basınç testi', figure=10,
    tools=[('Soğutma sistemi basınç test pompası', 1),
           ('Radyatör kapağı adaptörü', 1)],
    conditions=['Motor soğuk.'],
    steps=[
        'Radyatör kapağını açın ve pompayı radyatör boynuna takın.',
        'Sistemi 118 kPa\'ya kadar pompalayın ve 2 dakika bekleyin. Basınç '
        'düşüyorsa hortumları, radyatörü, su pompasını ve kalorifer '
        'peteğini kaçağa karşı izleyin.',
        'Kaçak görünmüyor ama basınç düşüyorsa yağı ve buji yuvalarını '
        'kontrol edin: silindir kapak contası sızdırıyor olabilir.',
        'Kapağı adaptörle pompaya takın. Kapak 74-103 kPa\'da açılmalı ve en '
        'az 59 kPa\'yı tutmalıdır; tutmuyorsa kapağı değiştirin.',
    ])

FAN_TEST = dm(
    code=code('DA1', '4', '320'), tech='Radyatör fanı', info='Çalışma testi',
    figure=10,
    tools=[('Voltmetre', 1), ('Köprü kablosu', 1)],
    warnings=['Fan kontak açıkken her an çalışabilir; ellerinizi fan '
              'kanatlarından uzak tutun.'],
    steps=[
        'Motor soğukken klimayı çalıştırın; fan dönmelidir (klimalı '
        'araçlarda).',
        'Fan sigortasını (RDI FAN, 30 A) ve fan rölesini kontrol edin.',
        'Fan motorunun soketini çıkarın, motora aküden doğrudan 12 V '
        'verin. Fan dönmüyorsa ya da zorlanıyorsa motor arızalıdır.',
        'Motor sağlamsa radyatör alt hortumundaki fan müşirinin soketini '
        'çıkarın: müşir 83 °C\'nin altında kapalı, üstünde açıktır (fan '
        'devresi bu sistemde müşir açılınca röle üzerinden çalışır).',
        'Arızalı motoru ya da müşiri değiştirin.',
    ])

WATER_PUMP = dm(
    code=code('DA1', '4', '920'), tech='Su pompası', figure=3,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Su pompası, contasıyla', 1)],
    supplies=[('Soğutma suyu', 6)],
    warnings=['Motor soğumadan soğutma sistemini açmayın.'],
    steps=[
        'Soğutma suyunu radyatörün altındaki musluktan boşaltın.',
        'Alternatör kayışını gevşetip çıkarın.',
        'Su pompası kasnağını ve pompanın cıvatalarını sökün; pompayı '
        'çıkarın.',
        'Triger kapağındaki yüzeyi eski contadan temizleyin.',
        'Yeni pompayı yeni contasıyla yerleştirin ve cıvataları çapraz '
        'sırayla 11 N·m\'de sıkın.',
        'Kasnağı ve kayışı takın, soğutma suyunu doldurun. Motoru '
        'çalıştırıp fan devreye girene kadar ısıtın ve sistemin havasını '
        'alın.',
    ],
    next=code('DA1', '4', '210'))

THERMOSTAT = dm(
    code=code('DA1', '4', '920', '01'), tech='Termostat', figure=10,
    tools=[('Lokma takımı', 1), ('Termometre', 1)],
    spares=[('Termostat, contasıyla', 1)], supplies=[('Soğutma suyu', None)],
    steps=[
        'Soğutma suyunu radyatör musluğundan yarısına kadar boşaltın.',
        'Su giriş borusunun iki somununu sökün ve termostatı contasıyla '
        'çıkarın.',
        'Termostatı su dolu bir kapta ısıtarak deneyin: 80-84 °C\'de açılmaya '
        'başlamalı, 95 °C\'de en az 8 mm açılmalıdır.',
        'Yeni termostatı hava deliği (jiggle valf) üstte olacak şekilde '
        'yeni contasıyla takın; somunları 9 N·m\'de sıkın.',
        'Suyu tamamlayıp sistemin havasını alın.',
    ],
    next=code('DA1', '4', '210'))

HOSES = dm(
    code=code('DA1', '4', '920', '02'), tech='Radyatör hortumları',
    figure=10,
    tools=[('Kelepçe pensesi', 1), ('Toplama kabı', 1)],
    spares=[('Radyatör hortumu, üst', 1), ('Radyatör hortumu, alt', 1)],
    supplies=[('Soğutma suyu', None)],
    steps=[
        'Soğutma suyunu boşaltın.',
        'Kelepçeleri penseyle sıkıp hortum boyunca kaydırın.',
        'Hortumu çevirerek yuvasından ayırın; yapışmışsa kesin, metal '
        'boruyu çizmeyin.',
        'Yeni hortumu yuvanın sonuna kadar geçirin ve kelepçeyi '
        'boncuğun arkasına yerleştirin.',
        'Suyu doldurun, sistemin havasını alın ve kaçak kontrolü yapın.',
    ],
    next=code('DA1', '4', '210'))

RADIATOR = dm(
    code=code('DA1', '4', '920', '03'), tech='Radyatör', figure=10,
    tools=[('Lokma takımı', 1), ('Kelepçe pensesi', 1)],
    spares=[('Radyatör', 1)], supplies=[('Soğutma suyu', 6)],
    steps=[
        'Soğutma suyunu boşaltın; fan soketini çıkarın.',
        'Üst ve alt hortumları ve otomatik şanzımanlıysa yağ soğutucu '
        'borularını ayırın.',
        'Radyatörün üst tutucularını sökün ve radyatörü fanla birlikte '
        'yukarı kaldırın.',
        'Fanı yeni radyatöre aktarın. Kondenserin peteklerine zarar '
        'vermeyin.',
        'Radyatörü alt lastik yuvalarına oturtun, tutucuları takın; '
        'hortumları bağlayın.',
        'Suyu doldurup havasını alın.',
    ],
    next=code('DA1', '4', '210'))

# Ateşleme
PLUGS = dm(
    code=code('DA1', '5', '920'), tech='Bujiler', figure=5,
    tools=[('Buji anahtarı, 16 mm', 1), ('Tork anahtarı', 1),
           ('Tel sentil', 1)],
    spares=[('Buji, iridyum', 4)],
    conditions=['Motor soğuk.'],
    steps=[
        'Supap kapağının üstündeki dört ateşleme bobininin '
        'soketlerini çıkarın.',
        'Bobinlerin cıvatalarını sökün ve bobinleri yukarı çekin.',
        'Bujileri buji anahtarıyla sökün. Elektrot rengine bakın: açık '
        'kahverengi normaldir; siyah is zengin karışımı, yağlı is yağ '
        'yakmayı gösterir.',
        'Yeni bujilerin tırnak aralığını kontrol edin: 1,0-1,1 mm. İridyum '
        'bujinin tırnağını eğmeyin.',
        'Bujileri önce elle, sonra 18 N·m\'de sıkın.',
        'Bobinleri yerine takın (cıvatalar 9 N·m), soketleri bağlayın.',
    ])

IGNITION = dm(
    code=code('DA1', '5', '421'), tech='Ateşleme sistemi',
    info='Tekleme: arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-003',
        'descr': 'Motor tekliyor, rölantide titriyor ya da hızlanırken '
                 'çekmiyor; motor arıza lambası yanıp sönüyor.',
        'steps': [
            ('stp-0001', 'Motor rölantideyken bobin soketlerini birer birer '
             'çıkarın.', 'Soketi çıkarınca devri değişmeyen bir silindir '
             'var mı?',
             'stp-0002', 'stp-0003'),
            ('stp-0002', 'Devri değiştirmeyen silindirin bobinini başka bir '
             'silindirinkiyle yer değiştirin.', 'Tekleme bobinle birlikte '
             'yer değiştirdi mi?', 'end-coil', 'stp-0004'),
            ('stp-0003', 'Hava filtresini çıkarın ve kontrol edin.',
             'Filtre çok kirli mi?', 'end-filter', 'end-mil'),
            ('stp-0004', 'O silindirin bujisini söküp bakın.', 'Buji aşınmış, '
             'islenmiş ya da yağlanmış mı?', 'end-plug', 'end-injector'),
        ],
        'ends': [
            ('end-coil', 'Ateşleme bobini arızalı; bobini değiştirin.',
             code('DA1', '5', '920', '01')),
            ('end-plug', 'Bujiyi değiştirin.', code('DA1', '5', '920')),
            ('end-injector', 'Kıvılcım sağlam: o silindirin enjektörünü ve '
             'kompresyonunu kontrol edin.', code('DA1', '7', '920', '02')),
            ('end-filter', 'Hava filtresini değiştirin.',
             code('DA1', '6', '920')),
            ('end-mil', 'Tekleme belirli bir silindirde değil: arıza '
             'kodlarını okuyun.', code('DA1', '8', '421')),
        ],
    })

COIL = dm(
    code=code('DA1', '5', '920', '01'), tech='Ateşleme bobini', figure=5,
    tools=[('Lokma, 10 mm', 1), ('Tork anahtarı', 1)],
    spares=[('Ateşleme bobini', 1)],
    steps=[
        'Kontağı kapatın; bobinin soketini kilidine basarak çıkarın.',
        'Bobinin cıvatasını sökün ve bobini çevirerek yukarı çekin.',
        'Buji kuyusunda yağ olup olmadığına bakın; yağ varsa supap kapağı '
        'contasını ve kuyu contasını da yenileyin.',
        'Yeni bobini bujinin üstüne oturana kadar bastırın, cıvatayı '
        '9 N·m\'de sıkın ve soketi takın.',
        'Motoru çalıştırıp teklemenin geçtiğini, arıza lambasının '
        'söndüğünü kontrol edin; arıza kodunu silin.',
    ])

# Emme, egzoz ve emisyon
AIR_FILTER = dm(
    code=code('DA1', '6', '920'), tech='Hava filtresi', figure=2,
    spares=[('Hava filtresi elemanı', 1)],
    steps=[
        'Hava filtresi kutusunun kapağındaki mandalları açın.',
        'Kapağı kaldırın ve filtre elemanını çıkarın.',
        'Kutunun içini nemli bir bezle temizleyin; emme borusuna toz '
        'kaçırmayın.',
        'Yeni elemanı kenarları oturacak şekilde yerleştirin.',
        'Kapağı kapatın ve mandalları takın.',
    ])

EXHAUST = dm(
    code=code('DA1', '6', '300'), tech='Egzoz sistemi', figure=9,
    warnings=['Egzoz sistemi motor durduktan sonra da uzun süre sıcak '
              'kalır.'],
    steps=[
        'Motoru çalıştırın ve manifold, boru bağlantıları ve susturucu '
        'çevresinden üfleme sesi gelip gelmediğini dinleyin.',
        'Motoru durdurun, araç soğuyunca altına bakın: boruda delik, '
        'paslanma ve kopmuş askı lastiği olup olmadığını kontrol edin.',
        'Susturucuyu elle sallayın; askılarda boşluk varsa lastikleri '
        'değiştirin.',
        'Egzoz manifoldu somunlarında gevşeklik olup olmadığını kontrol '
        'edin.',
    ])

EXHAUST_ISO = dm(
    code=code('DA1', '6', '421'), tech='Egzoz sistemi', info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-007',
        'descr': 'Egzozdan yüksek ses, üfleme ya da tıkırtı geliyor; yüksek '
                 'devirde motor çekmiyor ya da çürük yumurta kokusu var.',
        'steps': [
            ('stp-0001', 'Motoru soğukken çalıştırıp manifold tarafını '
             'dinleyin.', 'Isındıkça azalan tik tik sesi var mı?',
             'end-manifold', 'stp-0002'),
            ('stp-0002', 'Aracı kaldırıp motor çalışırken boru bağlantılarını '
             'eldivenli elle yoklayın (sıcak!).', 'Ön boru flanşında '
             'üfleme var mı?', 'end-front', 'stp-0003'),
            ('stp-0003', 'Katalitik konvertörü lastik tokmakla hafifçe '
             'vurun.', 'İçinden tıngırtı geliyor mu, ya da yüksek devirde '
             'motor boğuluyor mu?', 'end-cat', 'stp-0004'),
            ('stp-0004', 'Susturucuyu ve askılarını kontrol edin.',
             'Susturucu delinmiş ya da askı kopmuş mu?', 'end-muffler',
             'end-check'),
        ],
        'ends': [
            ('end-manifold', 'Egzoz manifoldu contası üflüyor ya da manifold '
             'çatlak; contayı değiştirin.', code('DA1', '6', '920', '02')),
            ('end-front', 'Ön boru contasını ve somunlarını yenileyin.',
             code('DA1', '6', '920', '05')),
            ('end-cat', 'Katalitik konvertör dağılmış ya da tıkanmış; '
             'değiştirin ve tıkanma nedenini (tekleme, yağ yakma) giderin.',
             code('DA1', '6', '920', '04')),
            ('end-muffler', 'Susturucuyu ya da askı lastiğini değiştirin.',
             code('DA1', '6', '920', '03')),
            ('end-check', 'Egzoz hattını baştan sona gözle kontrol edin.',
             code('DA1', '6', '300')),
        ],
    })

INTAKE_GASKET = dm(
    code=code('DA1', '6', '920', '01'), tech='Emme manifoldu contası',
    figure=3,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Emme manifoldu contası', 1)],
    steps=[
        'Akünün eksi kutbunu sökün; hava kanalını gaz kelebeği gövdesinden '
        'ayırın.',
        'Gaz telini, vakum hortumlarını, enjektör soketlerini ve yakıt '
        'rampasının bağlantısını ayırın (yakıt basıncını önce boşaltın).',
        'Manifoldun somun ve cıvatalarını sökün ve manifoldu kaldırın.',
        'Eski contayı çıkarın, yüzeyleri temizleyin; giriş kanallarına bez '
        'tıkayarak kir kaçmasını önleyin.',
        'Yeni contayla manifoldu takın; somunları ortadan dışa 30 N·m\'de '
        'sıkın. Sökülenleri takın ve yakıt kaçağı kontrolü yapın.',
    ])

MANIFOLD_GASKET = dm(
    code=code('DA1', '6', '920', '02'), tech='Egzoz manifoldu contası',
    figure=3,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1),
           ('Pas sökücü sprey', 1)],
    spares=[('Egzoz manifoldu contası', 1), ('Egzoz manifoldu somunu', 8)],
    warnings=['Egzoz manifoldunu motor tamamen soğuduktan sonra sökün.'],
    steps=[
        'Ön oksijen sensörünün soketini ayırın; ısı kalkanını sökün.',
        'Ön borunun manifolda bağlandığı somunları sökün.',
        'Manifold somunlarına pas sökücü sıkın, bekleyip sökün; manifoldu '
        'çıkarın.',
        'Manifoldun yüzeyini cetvelle kontrol edin; çatlak ya da 0,7 mm\'den '
        'fazla eğilme varsa manifoldu değiştirin.',
        'Yeni conta ve somunlarla takın; somunları 37 N·m\'de sıkın.',
    ])

MUFFLER = dm(
    code=code('DA1', '6', '920', '03'), tech='Susturucu', figure=9,
    tools=[('Lokma takımı', 1), ('Askı sökme pensesi', 1)],
    spares=[('Arka susturucu', 1), ('Egzoz askı lastiği', 2)],
    warnings=['Egzoz sistemi soğumadan çalışmayın.'],
    steps=[
        'Aracı kaldırıp sehpaya alın.',
        'Orta boruyla susturucu arasındaki flanş somunlarını sökün.',
        'Askı lastiklerini penseyle askı pimlerinden çıkarın ve '
        'susturucuyu indirin.',
        'Yeni susturucuyu yeni askı lastikleriyle takın; flanşa yeni conta '
        'koyup somunları 43 N·m\'de sıkın.',
        'Susturucunun gövdeye ve tampona değmediğini kontrol edin.',
    ])

CAT = dm(
    code=code('DA1', '6', '920', '04'), tech='Katalitik konvertör',
    figure=9,
    tools=[('Lokma takımı', 1), ('Oksijen sensörü lokması', 1)],
    spares=[('Katalitik konvertör', 1), ('Egzoz flanş contası', 2)],
    warnings=['Konvertör çalışırken 600 °C\'nin üstüne çıkar; soğumadan '
              'dokunmayın.'],
    steps=[
        'Arka oksijen sensörünün soketini ayırıp sensörü sökün.',
        'Konvertörün ön ve arka flanş somunlarını sökün; konvertörü indirin.',
        'Yeni konvertörü yeni contalarla takın; somunları 43 N·m\'de sıkın.',
        'Oksijen sensörünü 44 N·m\'de takın, soketini bağlayın.',
        'Konvertörü bozan nedeni giderin: tekleyen motor ve yağ yakma '
        'konvertörü kısa sürede yeniden tıkar.',
    ])

FRONT_PIPE = dm(
    code=code('DA1', '6', '920', '05'), tech='Egzoz ön borusu', figure=9,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Egzoz ön boru contası', 1), ('Ön boru somunu', 3)],
    steps=[
        'Ön borunun manifold flanşındaki somunları sökün.',
        'Borunun konvertöre bağlandığı flanşı ayırın ve boruyu indirin.',
        'Eski contayı çıkarın; flanş yüzeylerini tel fırçayla temizleyin.',
        'Yeni conta ve somunlarla takın; manifold tarafında 62 N·m, '
        'konvertör tarafında 43 N·m.',
        'Motoru çalıştırıp üfleme sesi kalmadığını kontrol edin.',
    ])

THROTTLE = dm(
    code=code('DA1', '6', '250'), tech='Gaz kelebeği gövdesi',
    info='Temizlik', figure=3,
    supplies=[('Gaz kelebeği temizleyici sprey', None)],
    cautions=['Elektronik parçalara ve gaz kelebeği konum sensörüne sprey '
              'sıkmayın.'],
    steps=[
        'Kontağı kapatın; hava kanalını gaz kelebeği gövdesinden ayırın.',
        'Gaz pedalına bir yardımcı bastırarak kelebeği açtırın.',
        'Temizleyiciyi bir beze sıkıp kelebeğin kenarındaki ve gövde '
        'içindeki karbon birikintisini silin.',
        'Hava kanalını takın. Motoru çalıştırıp 10 dakika rölantide '
        'bırakın; motor beyni rölanti ayarını yeniden öğrenir.',
    ])

EMISSION = dm(
    code=code('DA1', '9', '040'), tech='Emisyon kontrolü', figure=2,
    description=[
        ('Genel', [
            'Karter havalandırması (PCV): karterde biriken gazlar PCV valfi '
            'üzerinden emme manifolduna çekilip yakılır.',
            'Yakıt buharı kontrolü (EVAP): depodaki benzin buharı aktif '
            'karbon kanisterinde tutulur; motor çalışırken boşaltma valfi '
            '(VSV) açılır ve buhar emmeye çekilir.',
            'Üç yollu katalitik konvertör CO, HC ve NOx\'i zararsız gazlara '
            'çevirir. Konvertörün önündeki ve arkasındaki oksijen '
            'sensörleriyle motor beyni karışımı ve konvertörün verimini '
            'izler.',
            '1ZZ-FE\'de egzoz gazı geri dönüş (EGR) valfi yoktur; NOx, '
            'supap zamanlaması ve konvertörle düşürülür.',
        ]),
    ])

PCV = dm(
    code=code('DA1', '9', '920'), tech='PCV valfi', figure=3,
    spares=[('PCV valfi', 1)], tools=[('Lokma takımı', 1)],
    steps=[
        'PCV hortumunu supap kapağındaki valften ayırın.',
        'Valfi sökün. Silindir kapağı tarafından üfleyin: hava kolayca '
        'geçmeli; manifold tarafından üfleyince zor geçmelidir.',
        'Bu davranışı göstermeyen ya da sallayınca tıkırdamayan valfi '
        'değiştirin.',
        'Yeni valfi 27 N·m\'de sıkın; hortumun sertleşip çatlamadığını '
        'kontrol edin.',
    ])

EMISSION_ISO = dm(
    code=code('DA1', '9', '421'), tech='Yakıt buharı kontrolü (EVAP)',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-008',
        'descr': 'Motor arıza lambası yanıyor ve benzin kokusu geliyor; '
                 'yakıt aldıktan sonra motor zor çalışıyor.',
        'steps': [
            ('stp-0001', 'Depo kapağını açıp contasına bakın, sonra tık '
             'sesine kadar kapatın.', 'Conta çatlak ya da kapak tam '
             'kapanmıyor mu?', 'end-cap', 'stp-0002'),
            ('stp-0002', 'Kanister ve boşaltma valfi hortumlarını kontrol '
             'edin.', 'Hortum çatlak ya da çıkmış mı?', 'end-hose',
             'stp-0003'),
            ('stp-0003', 'Motor çalışırken boşaltma valfinin (VSV) soketini '
             'çıkarıp valfe üfleyin.', 'Valf soket çıkmışken de hava '
             'geçiriyor mu?', 'end-vsv', 'end-shop'),
        ],
        'ends': [
            ('end-cap', 'Depo kapağını değiştirin.', code('DA1', '7', '920',
                                                          '03')),
            ('end-hose', 'Hortumu yenileyin ve sistemi kontrol edin.',
             code('DA1', '9', '300')),
            ('end-vsv', 'Boşaltma valfi açık kalmış; valfi değiştirin.',
             code('DA1', '9', '300')),
            ('end-shop', 'Kanister ya da depo tarafında kaçak olabilir; '
             'duman testi için ' + SHOP + '.', None),
        ],
    })

EVAP_CHECK = dm(
    code=code('DA1', '9', '300'), tech='Yakıt buharı kontrolü (EVAP)',
    figure=9, tools=[('El vakum pompası', 1)],
    spares=[('EVAP boşaltma valfi (VSV)', 1)],
    steps=[
        'Kanisterden emme manifolduna giden hortumları çatlak ve gevşek '
        'bağlantıya karşı kontrol edin.',
        'Boşaltma valfinin soketini çıkarın. Valfe üfleyin: hava '
        'geçmemelidir.',
        'Valfe 12 V verin: hava geçmelidir. Valfin direnci 20 °C\'de '
        '27-33 Ω olmalıdır.',
        'Arızalı valfi değiştirin; hortumları ve soketi takıp arıza kodunu '
        'silin.',
    ])

# Yakıt
FUEL = dm(
    code=code('DA1', '7', '040'), tech='Yakıt sistemi', figure=9,
    description=[
        ('Genel', [
            'Depodaki elektrikli pompa benzini filtre ve basınç regülatörü '
            'üzerinden yakıt rampasına basar. 1ZZ-FE\'de geri dönüş hattı '
            'yoktur; regülatör, filtre ve pompa depodaki modülün içindedir.',
            'Çalışma basıncı 304-343 kPa\'dır. Motor beyni dört enjektörü '
            'sırayla açarak yakıtı emme kanallarına püskürtür.',
            'Depo arka koltuğun altındadır; doldurma borusu sol arka '
            'çamurluktadır. Yakıt: kurşunsuz benzin, en az 91 oktan.',
        ]),
    ])

FUEL_ISO = dm(
    code=code('DA1', '7', '421'), tech='Yakıt sistemi',
    info='Yakıt basıncı: arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-009',
        'descr': 'Motor marş basıyor ama çalışmıyor, yükte boğuluyor ya da '
                 'sıcakken zor çalışıyor; benzin kokusu geliyor.',
        'steps': [
            ('stp-0001', 'Kontağı açarken arka koltuğun altını dinleyin.',
             'Pompa 2 saniye kadar vızıldıyor mu?', 'stp-0003', 'stp-0002'),
            ('stp-0002', 'EFI sigortasını ve devre açma rölesini kontrol '
             'edin.', 'Sigorta ya da röle arızalı mı?', 'end-fuse',
             'end-pump'),
            ('stp-0003', 'Yakıt basıncını ölçün.', 'Basınç 304 kPa\'nın '
             'altında mı?', 'stp-0004', 'stp-0005'),
            ('stp-0004', 'Pompayı köprüleyip basıncın yükseldiğini izleyin; '
             'sonra dönüş akışını kısın.', 'Basınç yine düşük mü?',
             'end-filter', 'end-regulator'),
            ('stp-0005', 'Motoru durdurun ve 5 dakika sonra basınca bakın.',
             'Basınç 147 kPa\'nın altına düştü mü?', 'end-leak',
             'end-injectors'),
        ],
        'ends': [
            ('end-fuse', 'Sigortayı ya da röleyi değiştirin.',
             code('DA6', '6', '300')),
            ('end-pump', 'Pompaya gerilim geliyor ama dönmüyor: yakıt '
             'pompasını değiştirin.', code('DA1', '7', '920')),
            ('end-filter', 'Pompa basıncı çıkaramıyor ya da filtre tıkalı; '
             'filtreyi, sonra pompayı değiştirin.',
             code('DA1', '7', '920', '01')),
            ('end-regulator', 'Basınç regülatörü açık kalıyor; regülatörü '
             'değiştirin.', code('DA1', '7', '361')),
            ('end-leak', 'Basınç tutmuyor: enjektörler damlatıyor ya da '
             'pompa çek valfi kaçırıyor.', code('DA1', '7', '920', '02')),
            ('end-injectors', 'Basınç normal: enjektörleri ve ateşlemeyi '
             'kontrol edin.', code('DA1', '5', '421')),
        ],
    })

FUEL_PRESSURE = dm(
    code=code('DA1', '7', '361'), tech='Yakıt basıncı', info='Ölçüm',
    figure=9,
    tools=[('Yakıt basınç manometresi', 1), ('Bez', 1)],
    warnings=['Benzin çok yanıcıdır. Yakınında kıvılcım çıkarmayın, sigara '
              'içmeyin; yangın söndürücü hazır bulundurun.',
              'Hattı açmadan önce basıncı boşaltın: pompa sigortasını '
              'çıkarıp motoru kendi kendine durana kadar çalıştırın.'],
    steps=[
        'Akünün eksi kutbunu sökün; yakıt hattını rampa girişinden ayırıp '
        'manometreyi araya bağlayın.',
        'Aküyü bağlayın, pompayı köprüleyip çalıştırın. Basınç '
        '304-343 kPa olmalıdır.',
        'Motoru çalıştırın; rölantide basınç aynı aralıkta kalmalıdır.',
        'Motoru durdurun; 5 dakika sonra basınç en az 147 kPa olmalıdır.',
        'Basınç yüksekse ya da düşükse depo içindeki regülatörü ve filtreyi '
        'pompa modülüyle birlikte kontrol edin.',
    ])

FUEL_PUMP = dm(
    code=code('DA1', '7', '920'), tech='Yakıt pompası', figure=9,
    tools=[('Lokma takımı', 1), ('Döşeme sökme aparatı', 1)],
    spares=[('Yakıt pompası', 1), ('Pompa modülü contası', 1)],
    warnings=['Benzin çok yanıcıdır; işi açık havada, kıvılcımdan uzakta '
              'yapın. Önce yakıt basıncını boşaltın.'],
    steps=[
        'Yakıt basıncını boşaltın, akünün eksi kutbunu sökün.',
        'Arka koltuk minderini kaldırın ve servis kapağını açın.',
        'Pompa soketini ve yakıt hattını ayırın; modül kapağının '
        'cıvatalarını sökün ve modülü şamandırayı eğmeden çıkarın.',
        'Pompayı modülden ayırıp yenisini takın; süzgeci de yenileyin.',
        'Modülü yeni contayla takın, cıvataları 4 N·m\'de sıkın.',
        'Kontağı birkaç kez açıp kapatarak hattı doldurun ve kaçak kontrolü '
        'yapın.',
    ])

FUEL_FILTER = dm(
    code=code('DA1', '7', '920', '01'), tech='Yakıt filtresi', figure=9,
    tools=[('Lokma takımı', 1)],
    spares=[('Yakıt filtresi', 1), ('Pompa modülü contası', 1)],
    warnings=['Benzin çok yanıcıdır; önce yakıt basıncını boşaltın.'],
    steps=[
        'Pompa modülünü yakıt pompası değişimindeki gibi depodan çıkarın.',
        'Filtre modülün içindedir: basınç regülatörünü ve pompayı '
        'filtreden ayırın.',
        'Yeni filtreye yeni O-halkalar takıp parçaları birleştirin.',
        'Modülü yeni contayla depoya takın ve kaçak kontrolü yapın.',
    ])

INJECTORS = dm(
    code=code('DA1', '7', '920', '02'), tech='Enjektörler', figure=3,
    tools=[('Ohmmetre', 1), ('Lokma takımı', 1)],
    spares=[('Enjektör', 4), ('Enjektör O-halkası', 8)],
    supplies=[('Motor yağı, 5W-30', None)],
    warnings=['Benzin çok yanıcıdır; önce yakıt basıncını boşaltın.'],
    steps=[
        'Motor çalışırken stetoskopla her enjektörü dinleyin; düzenli '
        'tıklama sesi gelmelidir.',
        'Soketi çıkarıp enjektör direncini ölçün: 20 °C\'de 13,4-14,2 Ω.',
        'Yakıt basıncını boşaltın; enjektör soketlerini ve rampanın iki '
        'cıvatasını sökün, rampayı enjektörlerle birlikte kaldırın.',
        'Enjektörleri rampadan çıkarın; yenilerine yağlanmış yeni '
        'O-halkalar takın.',
        'Rampayı takın, cıvataları 19 N·m\'de sıkın; kontağı açıp kaçak '
        'kontrolü yapın.',
    ])

FUEL_CAP = dm(
    code=code('DA1', '7', '920', '03'), tech='Depo kapağı',
    spares=[('Yakıt deposu kapağı', 1)],
    steps=[
        'Depo kapağını açın ve contasında çatlak, ezilme ya da kir olup '
        'olmadığına bakın.',
        'Doldurma ağzının kenarını temizleyin.',
        'Yeni kapağı tık sesi gelene kadar çevirerek takın.',
        'Motor arıza lambası birkaç sürüş döngüsü sonra kendiliğinden söner; '
        'arıza kodunu silebilirsiniz.',
    ])

# Motor yönetimi
ECU_DESC = dm(
    code=code('DA1', '8', '040'), tech='Motor yönetimi', figure=7,
    description=[
        ('Genel', [
            'Motor beyni (ECM) torpidonun arkasındadır. Hava akış ölçerden '
            '(MAF), emme havası sıcaklık sensöründen, gaz kelebeği konum '
            'sensöründen (TPS), su sıcaklık sensöründen (ECT), krank ve '
            'eksantrik konum sensörlerinden, vuruntu sensöründen ve '
            'oksijen sensörlerinden gelen bilgilerle enjeksiyon süresini ve '
            'ateşleme avansını hesaplar.',
            'Rölanti devri, gaz kelebeği gövdesindeki rölanti ayar valfiyle '
            '(ISCV) tutulur; rölanti yaklaşık 700 d/d\'dir.',
            'Arızalar motor arıza lambasıyla bildirilir ve kod olarak '
            'saklanır; kodlar OBD-II soketinden (gösterge panelinin altında) '
            'okunur.',
        ]),
    ])

MIL_ISO = dm(
    code=code('DA1', '8', '421'), tech='Motor yönetimi',
    info='Motor arıza lambası: arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-010',
        'descr': 'Motor arıza lambası yanıyor; motor tekliyor, zor '
                 'çalışıyor, rölantisi düzensiz ya da yakıt tüketimi '
                 'arttı.',
        'steps': [
            ('stp-0001', 'OBD-II soketine arıza tespit cihazı bağlayın ve '
             'kodları okuyun.', 'P0100-P0103 (hava akış ölçer) kodu var '
             'mı?', 'end-maf', 'stp-0002'),
            ('stp-0002', 'Kodlara bakmaya devam edin.', 'P0115-P0118 (su '
             'sıcaklık sensörü) kodu var mı?', 'end-ect', 'stp-0003'),
            ('stp-0003', 'Kodlara bakmaya devam edin.', 'P0130-P0141 '
             '(oksijen sensörü) ya da P0171/P0172 (karışım) kodu var mı?',
             'end-o2', 'stp-0004'),
            ('stp-0004', 'Kodlara bakmaya devam edin.', 'P0335 (krank) ya '
             'da P0340 (eksantrik konum) kodu var mı?', 'end-position',
             'stp-0005'),
            ('stp-0005', 'Kodlara bakmaya devam edin.', 'P0120-P0123 (gaz '
             'kelebeği konum sensörü) kodu var mı?', 'end-tps', 'stp-0006'),
            ('stp-0006', 'Kodlara bakmaya devam edin.', 'P0325 (vuruntu '
             'sensörü) kodu var mı?', 'end-knock', 'stp-0007'),
            ('stp-0007', 'Kodlara bakmaya devam edin.', 'P0300-P0304 '
             '(tekleme) kodu var mı?', 'end-misfire', 'end-ecu'),
        ],
        'ends': [
            ('end-maf', 'Hava akış ölçeri temizleyin ve kontrol edin.',
             code('DA1', '8', '250')),
            ('end-ect', 'Su sıcaklık sensörünü ölçün.',
             code('DA1', '8', '361')),
            ('end-o2', 'Oksijen sensörünü ve emme tarafında hava kaçağını '
             'kontrol edin.', code('DA1', '8', '920', '01')),
            ('end-position', 'Krank ya da eksantrik konum sensörünü ölçün.',
             code('DA1', '8', '361', '01')),
            ('end-tps', 'Gaz kelebeği konum sensörünü kontrol edin.',
             code('DA1', '8', '920', '05')),
            ('end-knock', 'Vuruntu sensörünü kontrol edin.',
             code('DA1', '8', '920', '07')),
            ('end-misfire', 'Tekleyen silindiri bulun.',
             code('DA1', '5', '421')),
            ('end-ecu', 'Kod yok ya da birden çok ilgisiz kod var: motor '
             'beyninin besleme ve topraklarını kontrol edin.',
             code('DA1', '8', '300')),
        ],
    })

IDLE_ISO = dm(
    code=code('DA1', '8', '421', '01'), tech='Rölanti',
    info='Düzensiz rölanti: arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA1-011',
        'descr': 'Rölanti devri çok yüksek, çok düşük ya da dalgalı; motor '
                 'klima açılınca ya da durunca stop ediyor.',
        'steps': [
            ('stp-0001', 'Motor ısındıktan sonra rölanti devrini okuyun.',
             'Devir 900 d/d\'nin üstünde mi?', 'stp-0002', 'stp-0003'),
            ('stp-0002', 'Motor çalışırken emme manifoldu contası ve vakum '
             'hortumları çevresine temizleyici sprey sıkın.', 'Devir '
             'değişiyor mu?', 'end-leak', 'end-iscv'),
            ('stp-0003', 'Gaz kelebeği gövdesinin içine bakın.', 'Kelebek '
             'kenarında kalın karbon birikintisi var mı?', 'end-throttle',
             'stp-0004'),
            ('stp-0004', 'Hava akış ölçerin teline bakın.', 'Tel kirli ya da '
             'yağlı mı?', 'end-maf', 'end-iscv'),
        ],
        'ends': [
            ('end-leak', 'Emme tarafında hava kaçağı var; contayı ya da '
             'hortumu yenileyin.', code('DA1', '6', '920', '01')),
            ('end-iscv', 'Rölanti ayar valfi sıkışmış; valfi kontrol edin.',
             code('DA1', '8', '920', '06')),
            ('end-throttle', 'Gaz kelebeği gövdesini temizleyin.',
             code('DA1', '6', '250')),
            ('end-maf', 'Hava akış ölçeri temizleyin.',
             code('DA1', '8', '250')),
        ],
    })

ECU_CHECK = dm(
    code=code('DA1', '8', '300'), tech='Motor beyni (ECM)',
    info='Besleme ve toprak kontrolü', figure=7,
    tools=[('Voltmetre', 1)],
    cautions=['Motor beyninin soketlerini kontak açıkken takıp çıkarmayın.'],
    steps=[
        'EFI ve IG sigortalarını kontrol edin.',
        'Torpido gözünü indirip motor beynine ulaşın; soketleri takılıyken '
        'arkasından ölçün.',
        'Kontak açıkken +B ve IGSW uçlarında 9-14 V olmalıdır.',
        'E1 toprak ucuyla gövde arasında direnç 1 Ω\'un altında olmalıdır.',
        'Besleme ve toprak sağlam, sensörler doğru değerde ise motor beyni '
        'arızalı olabilir; ' + SHOP + '.',
    ])

MAF_CLEAN = dm(
    code=code('DA1', '8', '250'), tech='Hava akış ölçer (MAF)',
    info='Temizlik ve kontrol', figure=2,
    tools=[('Voltmetre', 1), ('Tornavida', 1)],
    supplies=[('Hava akış ölçer temizleyici sprey', None)],
    cautions=['Sıcak tele dokunmayın ve fırçalamayın; yalnız sprey '
              'kullanın.'],
    steps=[
        'Soketi çıkarın; sensörü hava kanalından iki vidasını sökerek '
        'çıkarın.',
        'Teli ve sıcaklık elemanını temizleyici spreyle yıkayın, 10 dakika '
        'kurumasını bekleyin.',
        'Sensörü takın. Kontak açıkken VG ucunda 0,2-4,9 V arasında, '
        'rölantide yaklaşık 1 V sinyal olmalıdır.',
        'Gaz verildikçe sinyal düzgün yükselmiyorsa sensörü değiştirin.',
    ])

ECT_TEST = dm(
    code=code('DA1', '8', '361'), tech='Su sıcaklık sensörü (ECT)',
    info='Ölçüm', figure=3,
    tools=[('Ohmmetre', 1), ('Termometre', 1)],
    steps=[
        'Sensörün soketini çıkarın.',
        'Sensörün iki ucu arasındaki direnci ölçün ve su sıcaklığıyla '
        'karşılaştırın.',
        '20 °C\'de 2,32-2,59 kΩ, 80 °C\'de 0,31-0,33 kΩ olmalıdır.',
        'Değer dışındaysa ya da sıcaklık değiştikçe direnç düzgün '
        'değişmiyorsa sensörü değiştirin.',
    ])

POSITION_TEST = dm(
    code=code('DA1', '8', '361', '01'), tech='Krank ve eksantrik konum '
    'sensörleri', info='Ölçüm', figure=3,
    tools=[('Ohmmetre', 1)],
    steps=[
        'Krank konum sensörünün soketini çıkarın (motorun önünde, krank '
        'kasnağının arkasında).',
        'İki uç arasındaki direnci ölçün: soğukta (-10 ile 50 °C) '
        '1630-2740 Ω, sıcakta (50-100 °C) 2065-3225 Ω.',
        'Eksantrik konum sensörünü (silindir kapağının arkasında, egzoz '
        'eksantriğinin ucunda) aynı şekilde ölçün: soğukta 835-1400 Ω, '
        'sıcakta 1060-1645 Ω.',
        'Sensörün ucunda metal talaşı olup olmadığına bakın; temizleyin.',
        'Değer dışındaki sensörü değiştirin.',
    ])

O2 = dm(
    code=code('DA1', '8', '920', '01'), tech='Oksijen sensörü', figure=9,
    tools=[('Oksijen sensörü lokması', 1), ('Ohmmetre', 1),
           ('Tork anahtarı', 1)],
    spares=[('Oksijen sensörü, ön', 1)],
    supplies=[('Yüksek ısı gresi', None)],
    steps=[
        'Sensörün soketini çıkarın. Isıtıcı direncini ölçün: 20 °C\'de '
        '11-16 Ω olmalıdır.',
        'Motor ılıkken sensörü özel lokmayla sökün.',
        'Yeni sensörün dişlerine (yalnız dişlere) yüksek ısı gresi sürün.',
        'Sensörü 44 N·m\'de sıkın ve kablosunu egzoza değmeyecek şekilde '
        'tutucusuna yerleştirin.',
        'Arıza kodunu silin; motoru ısıtıp kodun geri gelmediğini kontrol '
        'edin.',
    ])

ECT = dm(
    code=code('DA1', '8', '920', '02'), tech='Su sıcaklık sensörü (ECT)',
    figure=3, tools=[('Derin lokma, 19 mm', 1)],
    spares=[('Su sıcaklık sensörü', 1)], supplies=[('Soğutma suyu', None)],
    warnings=['Motor soğumadan sensörü sökmeyin.'],
    steps=[
        'Soğutma suyunu biraz boşaltın.',
        'Sensörün soketini çıkarın ve sensörü sökün.',
        'Yeni sensörü yeni contasıyla 20 N·m\'de sıkın.',
        'Suyu tamamlayıp havasını alın; arıza kodunu silin.',
    ])

CKP = dm(
    code=code('DA1', '8', '920', '03'), tech='Krank konum sensörü',
    figure=3, tools=[('Lokma, 10 mm', 1)],
    spares=[('Krank konum sensörü', 1)],
    supplies=[('Motor yağı, 5W-30', None)],
    steps=[
        'Akünün eksi kutbunu sökün; sensörün soketini çıkarın.',
        'Sensörün cıvatasını sökün ve sensörü çevirerek çıkarın.',
        'Yeni sensörün O-halkasına yağ sürüp takın; cıvatayı 9 N·m\'de '
        'sıkın.',
        'Aküyü bağlayın, motoru çalıştırıp devir göstergesinin marşta '
        'oynadığını kontrol edin.',
    ])

CMP = dm(
    code=code('DA1', '8', '920', '04'), tech='Eksantrik konum sensörü',
    figure=3, tools=[('Lokma, 10 mm', 1)],
    spares=[('Eksantrik konum sensörü', 1)],
    steps=[
        'Sensörün soketini çıkarın; silindir kapağının arka tarafındaki '
        'cıvatayı sökün.',
        'Sensörü çıkarın; yuvada yağ kaçağı varsa O-halkayı yenileyin.',
        'Yeni sensörü takın, cıvatayı 9 N·m\'de sıkın; arıza kodunu silin.',
    ])

TPS = dm(
    code=code('DA1', '8', '920', '05'), tech='Gaz kelebeği konum sensörü '
    '(TPS)', figure=3, tools=[('Voltmetre', 1), ('Tornavida', 1)],
    spares=[('Gaz kelebeği konum sensörü', 1)],
    steps=[
        'Kontak açıkken sensörün VTA ucunda gerilimi ölçün: kelebek '
        'kapalıyken 0,3-1,0 V, tam açıkken 3,2-4,9 V.',
        'Kelebeği yavaşça açarken gerilim kesintisiz yükselmelidir; atlama '
        'varsa sensör aşınmıştır.',
        'Soketi çıkarıp iki vidayı sökün ve sensörü çıkarın.',
        'Yeni sensörü kelebek mili kanalına hizalayıp takın, vidaları '
        'sıkın; arıza kodunu silin.',
    ])

ISCV = dm(
    code=code('DA1', '8', '920', '06'), tech='Rölanti ayar valfi (ISCV)',
    figure=3, tools=[('Ohmmetre', 1), ('Lokma takımı', 1)],
    spares=[('Rölanti ayar valfi', 1), ('ISCV contası', 1)],
    supplies=[('Gaz kelebeği temizleyici sprey', None)],
    steps=[
        'Soketi çıkarıp valf bobinlerinin direncini ölçün: 20 °C\'de '
        '17-24,5 Ω.',
        'Valfi gaz kelebeği gövdesinden sökün; hava kanalındaki karbonu '
        'temizleyin.',
        'Direnç doğru ve valf temizse yeniden takın; değilse yenisiyle '
        'değiştirin.',
        'Yeni contayla takın; motoru çalıştırıp 10 dakika rölantide '
        'bırakın.',
    ])

KNOCK = dm(
    code=code('DA1', '8', '920', '07'), tech='Vuruntu sensörü', figure=3,
    tools=[('Ohmmetre', 1), ('Tork anahtarı', 1)],
    spares=[('Vuruntu sensörü', 1)],
    steps=[
        'Sensör bloğun emme tarafında, manifoldun altındadır. Soketini '
        'çıkarın.',
        'Sensörün ucu ile gövdesi arasında direnç ölçün: 20 °C\'de '
        '120-280 kΩ.',
        'Değer dışındaysa sensörü sökün; yenisini 20 N·m\'de sıkın '
        '(fazla sıkmak sensörü körleştirir).',
        'Soketi takıp arıza kodunu silin.',
    ])

# ===========================================================================
# Güç aktarma
# ===========================================================================

GEARBOX = dm(
    code=code('DA2', '1', '300'), tech='Şanzıman',
    info='Yağ seviyesi kontrolü', figure=2,
    tools=[('Lokma, 24 mm', 1)],
    supplies=[('Şanzıman yağı, 75W-90', None)],
    steps=[
        'Aracı düz olarak kaldırın.',
        'Şanzımanın yanındaki doldurma tapasını sökün.',
        'Yağ seviyesi tapa deliğinin alt kenarına kadar olmalıdır.',
        'Seviye düşükse delikten yağ taşana kadar ekleyin (toplam '
        'kapasite yaklaşık 2,6 litre).',
        'Tapayı 39 N·m\'de sıkın; şanzıman ve aks mili keçelerinde kaçak '
        'olup olmadığına bakın.',
    ])

CLUTCH = dm(
    code=code('DA2', '1', '421'), tech='Debriyaj ve vites',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA2-001',
        'descr': 'Vites zor geçiyor, debriyaj kaçırıyor ya da kalkışta '
                 'araç sarsılıyor.',
        'steps': [
            ('stp-0001', 'Düz yolda üçüncü viteste gaza basın.',
             'Devir yükseliyor ama araç hızlanmıyor mu?', 'end-clutch',
             'stp-0002'),
            ('stp-0002', 'Motor çalışırken debriyaja tam basıp birinci '
             'vitese takın.', 'Vites dişli sesiyle mi giriyor?',
             'stp-0003', 'stp-0004'),
            ('stp-0003', 'Debriyaj hidroliği deposunun seviyesini kontrol '
             'edin.', 'Seviye düşük mü?', 'end-hydraulic', 'stp-0005'),
            ('stp-0004', 'Şanzıman yağı seviyesini kontrol edin.',
             'Seviye düşük mü?', 'end-oil', 'stp-0006'),
            ('stp-0005', 'Debriyaj pedalının serbest boşluğunu ölçün.',
             'Pedal 5-15 mm boşluktan sonra direnç göstermiyor ya da '
             'yavaşça yere iniyor mu?', 'end-hydraulic', 'end-clutch'),
            ('stp-0006', 'Vites kolunu boşta sağa sola oynatın.', 'Kolda '
             'fazla boşluk var ya da vitesler belirsiz mi?', 'end-linkage',
             'end-shop'),
        ],
        'ends': [
            ('end-clutch', 'Debriyaj balatası aşınmış ya da baskı zayıf; '
             'debriyaj setini değiştirin.', code('DA2', '1', '920')),
            ('end-hydraulic', 'Hidrolik kaçağını bulun, hidroliği tamamlayın '
             've havasını alın.', code('DA2', '1', '271')),
            ('end-oil', 'Şanzıman yağını tamamlayın.', code('DA2', '1', '300')),
            ('end-linkage', 'Vites kolu burçlarını ve kumanda tellerini '
             'kontrol edin.', code('DA2', '1', '271', '01')),
            ('end-shop', 'Senkromeç aşınmış olabilir; ' + SHOP + '.', None),
        ],
    })

CLUTCH_SET = dm(
    code=code('DA2', '1', '920'), tech='Debriyaj seti', figure=2,
    tools=[('Şanzıman krikosu', 1), ('Debriyaj merkezleme aparatı', 1),
           ('Tork anahtarı', 1)],
    spares=[('Debriyaj seti (baskı, disk, rulman)', 1)],
    supplies=[('Yüksek ısı gresi', None),
              ('Şanzıman yağı, 75W-90', None)],
    warnings=['Şanzıman yaklaşık 40 kg\'dır; şanzıman krikosu kullanın.',
              'Debriyaj tozunu üflemeyin; nemli bezle silin.'],
    steps=[
        'Aküyü, hava filtresi kutusunu ve şanzıman üstündeki kabloları ve '
        'vites tellerini sökün.',
        'Aks millerini, marş motorunu ve debriyaj silindirini (hortumu '
        'açmadan) sökün.',
        'Motoru alttan destekleyin, şanzıman takozunu ve çan cıvatalarını '
        'sökün; şanzımanı krikoyla indirin.',
        'Baskıyı çapraz gevşeterek sökün ve diski çıkarın. Volanın '
        'yüzeyinde çatlak ve mavilik olup olmadığına bakın.',
        'Yeni diski merkezleme aparatıyla takın; baskı cıvatalarını çapraz '
        'sırayla 19 N·m\'de sıkın.',
        'Rulmanın ve çatalın temas yerlerini gresleyin; şanzımanı takıp '
        'çan cıvatalarını 64 N·m\'de sıkın.',
    ])

CLUTCH_BLEED = dm(
    code=code('DA2', '1', '271'), tech='Debriyaj hidroliği',
    info='Hava alma ve pedal ayarı', figure=7,
    tools=[('Hava alma anahtarı, 10 mm', 1), ('Şeffaf hortum', 1),
           ('Toplama kabı', 1)],
    supplies=[('Fren hidroliği, DOT 3', None)],
    warnings=['Fren hidroliği boyaya zarar verir; dökülen hidroliği hemen '
              'suyla yıkayın.'],
    steps=[
        'Depoyu MAX çizgisine kadar doldurun (debriyaj ve fren aynı depoyu '
        'kullanır).',
        'Şanzımandaki debriyaj silindirinin hava alma nipeline hortumu '
        'takın, ucunu hidrolik dolu kaba daldırın.',
        'Yardımcı pedala birkaç kez basıp basılı tutsun; nipeli açıp kapatın. '
        'Hortumda kabarcık kalmayana kadar tekrarlayın.',
        'Nipeli 8 N·m\'de sıkın, depoyu tamamlayın.',
        'Pedal yüksekliğini ve serbest boşluğu (5-15 mm) kontrol edin; '
        'gerekirse ana merkez itici çubuğunu ayarlayın.',
    ])

LINKAGE = dm(
    code=code('DA2', '1', '271', '01'), tech='Vites kumandası',
    info='Kontrol ve ayar', figure=7,
    supplies=[('Beyaz gres', None)],
    steps=[
        'Orta konsolu ve vites körüğünü sökün.',
        'Vites kolunun alt burcunu ve kumanda tellerinin uçlarını boşluğa '
        'karşı kontrol edin.',
        'Şanzıman tarafında tellerin klipslerini ve burçlarını kontrol '
        'edin; aşınmış burçları yenileyin.',
        'Mafsalları gresleyin; bütün vitesleri motor kapalıyken deneyin.',
    ])

DRIVESHAFT = dm(
    code=code('DA2', '2', '300'), tech='Aks milleri', figure=4,
    steps=[
        'Direksiyonu tam sola çevirin; sağ aks milinin tekerlek tarafındaki '
        'körüğü görünür olur.',
        'Körükte yırtık, çatlak ya da gres sızıntısı olup olmadığına bakın. '
        'Sonra direksiyonu tam sağa çevirip diğer tarafı kontrol edin.',
        'Direksiyon tam kırıkken aracı yavaşça sürün. Tıkırtı sesi dış '
        'aks kafasının (homokinetik mafsal) aşındığını gösterir.',
        'Yırtık körük hemen değiştirilmelidir; içine giren toz ve su mafsalı '
        'kısa sürede bozar.',
    ])

CV_BOOT = dm(
    code=code('DA2', '2', '920'), tech='Aks mili körüğü', figure=4,
    tools=[('Aks somunu lokması, 30 mm', 1), ('Rotil ayırıcı', 1),
           ('Körük kelepçe pensesi', 1), ('Tork anahtarı', 1)],
    spares=[('Dış aks körüğü seti', 1)],
    supplies=[('Homokinetik mafsal gresi', None)],
    steps=[
        'Aks somununun emniyetini açın; araç yerdeyken somunu gevşetin.',
        'Aracı kaldırın, tekerleği sökün; alt rotili salıncaktan ayırın.',
        'Aks milini göbekten çıkarın; şanzıman tarafından çekip alın '
        '(yağ akabilir, kap koyun).',
        'Kelepçeleri kesin, eski körüğü çıkarın; mafsalı temizleyip '
        'kontrol edin.',
        'Yeni körüğü takın, mafsalı setteki gresle doldurun ve kelepçeleri '
        'sıkın.',
        'Aksı takın; rotil somununu 127 N·m, aks somununu 216 N·m\'de '
        'sıkıp emniyetleyin.',
    ])

# ===========================================================================
# Fren
# ===========================================================================

BRAKES = dm(
    code=code('DA3'), tech='Fren sistemi', figure=4,
    description=[
        ('Genel', [
            'Fren pedalına basılınca fren servosu kuvveti artırır, ana '
            'merkez hidroliği çapraz bağlı iki devreyle dört tekerleğin '
            'frenlerine iletir.',
            'Kaliperdeki piston balataları diske bastırır; sürtünme aracı '
            'yavaşlatır.',
            'El freni arka kaliperleri telle çalıştırır.',
        ]),
        ('Aşınma', [
            'Balatalar ve diskler kullanıldıkça incelir. Frenleme sırasında '
            'ağırlık öne aktarıldığı için ön frenler daha hızlı aşınır. '
            'Balatanın en az kalınlığı 1 mm\'dir.',
            'Fren hidroliği zamanla nem çeker; iki yılda bir '
            'değiştirilmelidir.',
        ]),
    ])

BRAKE_ISOLATE = dm(
    code=code('DA3', info='421'), tech='Fren sistemi', info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA3-001',
        'descr': 'Fren zayıf tutuyor, pedal yumuşak ya da sert, frenlerken '
                 'ses geliyor ya da araç bir yana çekiyor.',
        'steps': [
            ('stp-0001', 'Motor kapalıyken pedala birkaç kez basın, sonra '
             'pedalı basılı tutarak motoru çalıştırın.', 'Pedal hafifçe '
             'aşağı iniyor mu?', 'stp-0002', 'end-booster'),
            ('stp-0002', 'Fren hidroliği deposunun seviyesine bakın.',
             'Seviye MIN çizgisinin altında mı?', 'stp-0003', 'stp-0004'),
            ('stp-0003', 'Kaliperleri, hortumları ve boruları kaçağa karşı '
             'kontrol edin.', 'Kaçak var mı?', 'end-leak', 'stp-0004'),
            ('stp-0004', 'Ön balataların kalınlığını kaliperin içinden '
             'bakarak kontrol edin.', 'Balata 1 mm\'den ince mi?',
             'end-pads', 'stp-0005'),
            ('stp-0005', 'Diskin kalınlığını ve yüzeyini kontrol edin.',
             'Disk MIN değerinin altında ya da yüzeyi çizik mi?',
             'end-disc', 'stp-0006'),
            ('stp-0006', 'Kısa bir sürüşten sonra jantları elle yoklayın.',
             'Bir tekerlek ötekilerden belirgin sıcak mı?', 'end-caliper',
             'stp-0007'),
            ('stp-0007', 'Motor çalışırken pedalı orta kuvvetle 15 saniye '
             'basılı tutun.', 'Pedal yavaşça yere iniyor mu?', 'end-master',
             'stp-0008'),
            ('stp-0008', 'Arka balataları kontrol edin.', 'Arka balata 1 '
             'mm\'den ince mi?', 'end-rear', 'end-fluid'),
        ],
        'ends': [
            ('end-booster', 'Fren servosu vakum almıyor: vakum hortumunu ve '
             'servoyu kontrol edin.', code('DA3', '3', '300')),
            ('end-leak', 'Kaçağı giderin, hidroliği tamamlayın ve sistemin '
             'havasını alın. Kaçak giderilmeden aracı kullanmayın.',
             code('DA3', '3', '210')),
            ('end-pads', 'Ön balataları değiştirin.', code('DA3', '1', '921')),
            ('end-disc', 'Diskleri ölçün ve gerekirse değiştirin.',
             code('DA3', '1', '361')),
            ('end-caliper', 'O tekerleğin kaliper pistonu ya da kılavuz '
             'pimleri sıkışmış; kaliperi yenileyin.',
             code('DA3', '1', '920', '01')),
            ('end-master', 'Ana merkez içeriden kaçırıyor; ana merkezi '
             'değiştirin.', code('DA3', '3', '920')),
            ('end-rear', 'Arka balataları değiştirin.',
             code('DA3', '2', '921')),
            ('end-fluid', 'Pedal yumuşak ama kaçak yok: sistemde hava var ya '
             'da hidrolik nem çekmiş. Hidroliği değiştirip havasını alın.',
             code('DA3', '3', '210')),
        ],
    })

PADS = dm(
    code=code('DA3', '1', '921'), tech='Ön fren balataları', figure=4,
    tools=[('Kriko ve sehpa', 1), ('Bijon anahtarı', 1),
           ('Piston itme aparatı', 1), ('Tork anahtarı', 1)],
    spares=[('Ön balata takımı', 1)],
    warnings=['Balataları her zaman iki tarafta birlikte değiştirin.',
              'Aracı yalnız krikoyla kaldırılmış haldeyken altına '
              'girmeyin; sehpa kullanın.'],
    steps=[
        'Bijonları gevşetin, aracın önünü kaldırıp sehpaya alın ve '
        'tekerleği sökün.',
        'Kaliperin alt kılavuz cıvatasını sökün ve kaliperi yukarı '
        'kaldırın.',
        'Eski balataları ve ses önleyici sacları (şim) çıkarın.',
        'Fren hidroliği deposunun kapağını açın; pistonu aparatla yavaşça '
        'geri itin. Depodan taşan hidroliği silin.',
        'Yeni balataları ve şimleri yerleştirin, kaliperi indirip '
        'kılavuz cıvatasını 27 N·m\'de sıkın.',
        'Tekerleği takın, aracı indirin ve bijonları çapraz sırayla '
        '103 N·m\'de sıkın. Diğer tarafta aynısını yapın.',
        'Motoru çalıştırmadan önce pedala birkaç kez basarak pistonları '
        'balatalara oturtun.',
    ])

DISCS = dm(
    code=code('DA3', '1', '361'), tech='Ön fren diskleri', info='Ölçüm',
    figure=4,
    tools=[('Mikrometre', 1), ('Komparatör saat', 1)],
    steps=[
        'Tekerleği sökün ve diski iki bijonla göbeğe sabitleyin.',
        'Disk kalınlığını mikrometreyle sekiz noktadan ölçün. Diskin '
        'üzerinde yazan MIN değerinin altındaysa diski değiştirin.',
        'Komparatörü diskin dış kenarından 10 mm içeride yüzeye dayayın ve '
        'diski bir tur çevirin. Salgı 0,05 mm\'yi geçmemelidir.',
        'Yüzeyde derin çizik, çatlak ya da mavimsi renk değişimi varsa '
        'diski değiştirin.',
    ])

DISC_REPLACE = dm(
    code=code('DA3', '1', '920'), tech='Ön fren diski', figure=4,
    tools=[('Kriko ve sehpa', 1), ('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Ön fren diski', 2), ('Ön balata takımı', 1)],
    supplies=[('Fren temizleyici sprey', None)],
    warnings=['Diskleri her zaman iki tarafta birlikte, yeni balatalarla '
              'değiştirin.'],
    steps=[
        'Tekerleği ve balataları sökün.',
        'Kaliper taşıyıcısının iki cıvatasını sökün; kaliperi hortumu '
        'gerdirmeden bir telle asın.',
        'Diski göbekten çıkarın; göbek yüzeyini pastan temizleyin.',
        'Yeni diskin koruyucu yağını fren temizleyiciyle silin ve diski '
        'takın.',
        'Taşıyıcı cıvatalarını 107 N·m\'de sıkın, balataları ve kaliperi '
        'takın.',
        'İlk 200 km sert frenden kaçınarak balataları alıştırın.',
    ])

CALIPER = dm(
    code=code('DA3', '1', '920', '01'), tech='Ön fren kaliperi', figure=4,
    tools=[('Lokma takımı', 1), ('Hortum kıskacı', 1), ('Tork anahtarı', 1)],
    spares=[('Ön fren kaliperi', 1), ('Banjo cıvatası rondelası', 2)],
    supplies=[('Fren hidroliği, DOT 3', None), ('Kaliper pimi gresi', None)],
    steps=[
        'Tekerleği sökün; fren hortumunu kıskaçla sıkıştırın.',
        'Banjo cıvatasını sökün; kaliperin kılavuz cıvatalarını sökerek '
        'kaliperi çıkarın.',
        'Kılavuz pimlerini çıkarıp temizleyin ve özel gresle yağlayın; '
        'körükleri kontrol edin.',
        'Yeni kaliperi takın; banjo cıvatasını yeni rondelalarla 29 N·m, '
        'kılavuz cıvatalarını 27 N·m\'de sıkın.',
        'Kıskacı çıkarın ve o devrenin havasını alın.',
    ],
    next=code('DA3', '3', '210'))

REAR_BRAKES = dm(
    code=code('DA3', '2', '300'), tech='Arka frenler', figure=8,
    steps=[
        'Aracın arkasını kaldırın ve tekerlekleri sökün.',
        'Balata kalınlığını kontrol edin; 1 mm\'nin altındaysa değiştirin.',
        'Kaliper ve hortumlarda kaçak olup olmadığına bakın.',
        'El freni kolunu çekin; 5-8 diş arasında tam tutmalıdır. Daha '
        'fazlaysa el freni telini ayarlatın.',
    ])

REAR_PADS = dm(
    code=code('DA3', '2', '921'), tech='Arka fren balataları', figure=8,
    tools=[('Kriko ve sehpa', 1), ('Piston çevirme aparatı', 1),
           ('Tork anahtarı', 1)],
    spares=[('Arka balata takımı', 1)],
    warnings=['Balataları her zaman iki tarafta birlikte değiştirin.'],
    steps=[
        'El frenini indirin; aracın arkasını kaldırıp tekerlekleri sökün.',
        'Kaliperin alt kılavuz cıvatasını sökün ve kaliperi kaldırın.',
        'Eski balataları çıkarın. Arka kaliper pistonu el freni '
        'mekanizması yüzünden itilmez; aparatla saat yönünde çevirerek '
        'içeri alın.',
        'Pistonun kanalını balatanın pimine hizalayın, yeni balataları '
        'takın; kılavuz cıvatasını 27 N·m\'de sıkın.',
        'Pedala birkaç kez basın; el freni ayarını kontrol edin.',
    ],
    next=code('DA3', '4', '271'))

BOOSTER = dm(
    code=code('DA3', '3', '300'), tech='Fren servosu ve hidroliği',
    figure=2,
    warnings=['Fren hidroliği boyaya zarar verir; dökülen hidroliği hemen '
              'suyla yıkayın.'],
    steps=[
        'Motor kapalıyken fren pedalına birkaç kez basarak servodaki '
        'vakumu boşaltın.',
        'Pedalı basılı tutarken motoru çalıştırın; pedal hafifçe aşağı '
        'inmelidir. İnmiyorsa servo ya da vakum hortumu arızalıdır.',
        'Motoru 1-2 dakika çalıştırıp durdurun ve pedala birkaç kez basın. '
        'Her basışta pedal biraz yükselmelidir; servo vakumu tutuyordur.',
        'Vakum hortumunu ve çek valfini kontrol edin: valf yalnız servodan '
        'manifolda doğru hava geçirmelidir.',
        'Fren hidroliği deposunda seviyenin MIN ve MAX arasında olduğunu '
        've hidroliğin koyulaşmadığını kontrol edin.',
    ])

BRAKE_BLEED = dm(
    code=code('DA3', '3', '210'), tech='Fren hidroliği',
    info='Değişim ve hava alma', figure=4,
    tools=[('Hava alma anahtarı, 10 mm', 1), ('Şeffaf hortum', 1),
           ('Toplama kabı', 1)],
    supplies=[('Fren hidroliği, DOT 3', 1)],
    warnings=['Fren hidroliği boyaya ve göze zarar verir; gözlük takın.',
              'İşlem boyunca depo MIN çizgisinin altına inmesin; inerse '
              'ana merkeze hava girer.'],
    steps=[
        'Depodaki eski hidroliği şırıngayla çekin ve yeni hidrolikle '
        'doldurun.',
        'Sıra: sağ arka, sol ön, sol arka, sağ ön (merkezden en uzak '
        'kaliperden başlayarak, çapraz devreler).',
        'Hortumu nipele takın; yardımcı pedala basıp tutarken nipeli açıp '
        'kapatın. Hortumdan temiz ve kabarcıksız hidrolik gelene kadar '
        'tekrarlayın.',
        'Nipelleri 8 N·m\'de sıkın; depoyu MAX çizgisine tamamlayın.',
        'Motor çalışırken pedalın sert ve yüksek kaldığını kontrol edin; '
        'aracı yavaş hızda deneyin.',
    ])

MASTER = dm(
    code=code('DA3', '3', '920'), tech='Fren ana merkezi', figure=2,
    tools=[('Rakor anahtarı, 10 mm', 1), ('Tork anahtarı', 1)],
    spares=[('Fren ana merkezi', 1)],
    supplies=[('Fren hidroliği, DOT 3', None)],
    warnings=['Fren hidroliği boyaya zarar verir; çevreyi bezle örtün.'],
    steps=[
        'Depodaki hidroliği çekin; seviye müşirinin soketini çıkarın.',
        'Fren borularının rakorlarını rakor anahtarıyla gevşetip ayırın; '
        'uçlarını tıkayın.',
        'Ana merkezin servoya bağlandığı iki somunu sökün ve merkezi '
        'çıkarın.',
        'Yeni merkezin havasını tezgahta alın, servoya takıp somunları '
        '13 N·m, rakorları 15 N·m\'de sıkın.',
        'Bütün sistemin havasını alın.',
    ],
    next=code('DA3', '3', '210'))

PARKING = dm(
    code=code('DA3', '4', '271'), tech='El freni', info='Ayar', figure=8,
    tools=[('Lokma takımı', 1)],
    steps=[
        'Motoru çalıştırıp pedala birkaç kez basın; arka pistonlar '
        'balatalara otursun.',
        'Orta konsolun arka kapağını açın; el freni kolunun altındaki ayar '
        'somununa ulaşın.',
        'Kontra somunu gevşetin, ayar somununu çevirerek kol 196 N kuvvetle '
        'çekilince 5-8 diş tutacak şekilde ayarlayın.',
        'Kontra somunu sıkın. Kol indirildiğinde arka tekerleklerin '
        'serbestçe döndüğünü ve el freni lambasının söndüğünü kontrol '
        'edin.',
    ])

# ===========================================================================
# Süspansiyon ve direksiyon
# ===========================================================================

SUSPENSION_CHECK = dm(
    code=code('DA4', '1', '300'), tech='Ön süspansiyon', figure=4,
    steps=[
        'Aracın ön köşesine bastırıp bırakın. Gövde bir kez inip kalkarak '
        'durmalıdır; birden çok salınım amortisörün zayıfladığını '
        'gösterir.',
        'Amortisörün gövdesinde yağ sızıntısı olup olmadığına bakın.',
        'Aracı kaldırın, tekerleği üstten ve alttan tutup sallayın. Boşluk '
        'rotil ya da tekerlek rulmanı aşınmasını gösterir.',
        'Salıncak burçlarında ve viraj demiri lastiklerinde çatlak ve '
        'yırtık olup olmadığını kontrol edin.',
    ])

STRUT = dm(
    code=code('DA4', '1', '920'), tech='Ön amortisör', figure=4,
    tools=[('Yay sıkıştırma aparatı', 1), ('Tork anahtarı', 1)],
    spares=[('Ön amortisör', 2), ('Amortisör takozu', 2)],
    warnings=['Sıkıştırılmış yay büyük kuvvet taşır. Yalnız uygun yay '
              'sıkıştırma aparatı kullanın.',
              'Amortisörleri her zaman iki tarafta birlikte değiştirin.'],
    steps=[
        'Aracı kaldırıp sehpaya alın ve tekerleği sökün.',
        'Fren hortumunun amortisördeki tutucusunu çıkarın; viraj demiri '
        'bağlantısını ayırın.',
        'Amortisörü aks taşıyıcısına bağlayan iki cıvatayı sökün.',
        'Kaputun altındaki üç üst bağlantı somununu sökün ve amortisörü '
        'yayıyla birlikte çıkarın.',
        ('Yayı aktarın', [
            'Yayı aparatla, üst tabla serbest kalana kadar sıkıştırın.',
            'Mil somununu sökün; yayı ve takozu yeni amortisöre aktarın.',
            'Mil somununu 49 N·m\'de sıkın ve aparatı yavaşça gevşetin.',
        ]),
        'Amortisörü yerine takın: alt cıvatalar 153 N·m, üst somunlar '
        '39 N·m.',
        'Değişimden sonra ön düzen ayarı yaptırın.',
    ],
    next=code('DA4', '3', '271'))

BALL_JOINT = dm(
    code=code('DA4', '1', '920', '01'), tech='Ön rotil', figure=4,
    tools=[('Rotil ayırıcı', 1), ('Tork anahtarı', 1)],
    spares=[('Ön alt rotil', 1)],
    steps=[
        'Aracı kaldırıp tekerleği sökün.',
        'Rotilin aks taşıyıcısındaki somununun kopilyasını çıkarın, somunu '
        'gevşetin ve rotili ayırıcıyla ayırın.',
        'Rotilin salıncağa bağlandığı iki cıvatayı sökün.',
        'Yeni rotili takın: salıncak cıvataları 127 N·m, rotil somunu '
        '123 N·m; yeni kopilya takın.',
        'Ön düzeni kontrol ettirin.',
    ],
    next=code('DA4', '3', '271'))

STAB_LINK = dm(
    code=code('DA4', '1', '920', '02'), tech='Ön viraj demiri bağlantısı',
    figure=4, tools=[('Lokma takımı', 1), ('Alyan anahtarı', 1),
                     ('Tork anahtarı', 1)],
    spares=[('Viraj demiri bağlantı çubuğu', 2),
            ('Viraj demiri burcu', 2)],
    steps=[
        'Aracı tekerlekleri yerde olacak şekilde rampaya alın ya da her iki '
        'salıncağı destekleyin; viraj demiri yüksüz olsun.',
        'Bağlantı çubuğunun somunlarını, mili alyanla tutarak sökün.',
        'Yeni çubuğu takın, somunları 39 N·m\'de sıkın.',
        'Viraj demiri burçları çatlaksa kelepçelerini sökerek yenileyin.',
    ])

REAR_SUSPENSION = dm(
    code=code('DA4', '2', '300'), tech='Arka süspansiyon', figure=8,
    steps=[
        'Aracın arka köşesine bastırıp bırakın; birden çok salınım '
        'amortisörün zayıfladığını gösterir.',
        'Arka amortisörlerde yağ sızıntısı olup olmadığına bakın.',
        'Salıncakların, çeki kolunun ve viraj demirinin burçlarını çatlak '
        've yırtığa karşı kontrol edin.',
        'Aracı kaldırın, arka tekerleği sallayarak rulman boşluğunu '
        'kontrol edin.',
    ])

REAR_STRUT = dm(
    code=code('DA4', '2', '920'), tech='Arka amortisör', figure=8,
    tools=[('Yay sıkıştırma aparatı', 1), ('Tork anahtarı', 1),
           ('Döşeme sökme aparatı', 1)],
    spares=[('Arka amortisör', 2)],
    warnings=['Sıkıştırılmış yay büyük kuvvet taşır. Yalnız uygun yay '
              'sıkıştırma aparatı kullanın.'],
    steps=[
        'Arka koltuk sırtını ve bagajdaki üst kapakları sökün.',
        'Aracı kaldırın, tekerleği sökün; fren hortumu tutucusunu ve viraj '
        'demiri bağlantısını ayırın.',
        'Amortisörün alt cıvatasını ve bagajdaki üst somunları sökün; '
        'amortisörü çıkarın.',
        'Yayı aparatla sıkıştırıp yeni amortisöre aktarın; mil somununu '
        '49 N·m\'de sıkın.',
        'Takın: üst somunlar 39 N·m, alt cıvata 186 N·m. Arka düzeni '
        'kontrol ettirin.',
    ])

STEERING = dm(
    code=code('DA4', '3', '040'), tech='Direksiyon', figure=4,
    description=[
        ('Genel', [
            'Kremayer dişli direksiyon kutusu ön traversin üstündedir; rot '
            'milleri ve rot başları tekerleklerin aks taşıyıcılarına '
            'bağlanır.',
            'Hidrolik destek, motordan kayışla dönen pompanın bastığı yağla '
            'sağlanır. Yağ: ATF Dexron II/III.',
            'Direksiyon simidinde sürücü hava yastığı bulunan donanımlarda '
            'simide yapılacak her işten önce akü sökülüp 90 saniye '
            'beklenmelidir.',
        ]),
    ])

SUSPENSION_ISOLATE = dm(
    code=code('DA4', info='421'), tech='Süspansiyon ve direksiyon',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA4-001',
        'descr': 'Araç bir yana çekiyor, direksiyon titriyor, tümseklerde '
                 'vuruntu sesi geliyor, tekerlekten uğultu geliyor ya da '
                 'lastikler düzensiz aşınıyor.',
        'steps': [
            ('stp-0001', 'Lastik basınçlarını ölçün.', 'Sağ ve sol '
             'arasında fark var mı?', 'end-pressure', 'stp-0002'),
            ('stp-0002', 'Ön lastiklerin iç ve dış kenarlarına bakın.',
             'Lastik bir kenarından aşınmış mı?', 'end-alignment',
             'stp-0003'),
            ('stp-0003', 'Aracı yavaşça tümsekten geçirin ve sesi dinleyin.',
             'Önden vuruntu ya da tıkırtı sesi geliyor mu?', 'stp-0006',
             'stp-0004'),
            ('stp-0004', 'Belirli bir hızda direksiyonda titreme olup '
             'olmadığını izleyin.', 'Titreme var mı?', 'end-balance',
             'stp-0005'),
            ('stp-0005', '60-90 km/s\'de sürerken sesi dinleyin, sonra '
             'hafif viraj alın.', 'Hızla artan, virajda değişen bir uğultu '
             'var mı?', 'end-bearing', 'stp-0007'),
            ('stp-0006', 'Aracı kaldırıp tekerleği altından ve üstünden '
             'tutup sallayın.', 'Rotil ya da rot başında boşluk var mı?',
             'end-joint', 'stp-0008'),
            ('stp-0007', 'Motor çalışırken direksiyonu sağa sola çevirin.',
             'Direksiyon ağır ya da pompadan inilti geliyor mu?',
             'end-steering', 'end-shop'),
            ('stp-0008', 'Viraj demiri bağlantı çubuklarını elle oynatın.',
             'Çubuk mafsallarında boşluk var mı?', 'end-link', 'end-strut'),
        ],
        'ends': [
            ('end-pressure', 'Lastik basınçlarını 2,2 bara ayarlayın.',
             code('DA5', '1', '300')),
            ('end-alignment', 'Ön düzen ayarı yaptırın.',
             code('DA4', '3', '271')),
            ('end-balance', 'Tekerlek balansı bozulmuş olabilir; balans '
             'yaptırın.', code('DA5', '1', '271')),
            ('end-bearing', 'Tekerlek rulmanı aşınmış; uğultunun geldiği '
             'tarafın rulmanını değiştirin.', code('DA5', '2', '920')),
            ('end-joint', 'Boşluk rotilde ise rotili, rot başında ise rot '
             'başını değiştirin.', code('DA4', '1', '920', '01')),
            ('end-link', 'Viraj demiri bağlantı çubuklarını değiştirin.',
             code('DA4', '1', '920', '02')),
            ('end-strut', 'Amortisörü, takozunu ve salıncak burcunu kontrol '
             'edin.', code('DA4', '1', '300')),
            ('end-steering', 'Hidrolik direksiyonu kontrol edin.',
             code('DA4', '3', '421')),
            ('end-shop', 'Direksiyon kutusu aşınmış olabilir; ' + SHOP
             + '.', None),
        ],
    })

ALIGNMENT = dm(
    code=code('DA4', '3', '271'), tech='Ön düzen', figure=4,
    tools=[('Ön düzen ölçüm cihazı', 1), ('Rot ayar anahtarı', 1)],
    conditions=['Lastik basınçları doğru, araç boş ve düz zeminde.'],
    steps=[
        'Direksiyonu düz konuma getirin ve ölçüm cihazını tekerleklere '
        'bağlayın.',
        'Toplama değerini (toe) ölçün; toplam 0 ± 2 mm olmalıdır.',
        'Rot başı kontra somunlarını gevşetin; rot millerini çevirerek '
        'iki tarafı eşit ayarlayın.',
        'Kontra somunlarını 74 N·m\'de sıkın ve rot körüklerinin '
        'kıvrılmadığını kontrol edin.',
        'Aracı kısa bir yol sürüşüyle deneyin; direksiyon düz durmalı ve '
        'araç çekmemelidir.',
    ])

TIE_ROD = dm(
    code=code('DA4', '3', '920'), tech='Rot başı', figure=4,
    tools=[('Rotil ayırıcı', 1), ('Tork anahtarı', 1)],
    spares=[('Rot başı', 1)],
    steps=[
        'Aracı kaldırıp tekerleği sökün.',
        'Kontra somunu gevşetin ve rot başının mil üzerindeki yerini '
        'işaretleyin.',
        'Rot başı somununun kopilyasını çıkarıp somunu sökün; rot başını '
        'ayırıcıyla aks taşıyıcısından ayırın.',
        'Rot başını milden sökün, yenisini işarete kadar takın.',
        'Rot başı somununu 49 N·m\'de sıkıp kopilyalayın; kontra somunu '
        '74 N·m\'de sıkın ve ön düzeni ayarlatın.',
    ],
    next=code('DA4', '3', '271'))

STEERING_ISO = dm(
    code=code('DA4', '3', '421'), tech='Hidrolik direksiyon',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA4-002',
        'descr': 'Direksiyon ağır dönüyor, direksiyon çevrilirken inilti '
                 'geliyor ya da direksiyon yağı eksiliyor.',
        'steps': [
            ('stp-0001', 'Motor ısınmışken direksiyon yağı deposundaki '
             'seviyeye bakın.', 'Seviye HOT işaretinin altında mı?',
             'stp-0002', 'stp-0003'),
            ('stp-0002', 'Pompa, hortumlar ve direksiyon kutusu körüklerinde '
             'kaçak arayın.', 'Kutu körüklerinde yağ var mı?', 'end-rack',
             'end-leak'),
            ('stp-0003', 'Aksesuar kayışının gerginliğini kontrol edin.',
             'Kayış gevşek ya da kayıyor mu?', 'end-belt', 'stp-0004'),
            ('stp-0004', 'Depodaki yağa bakın.', 'Yağ köpüklü ya da kararmış '
             'mı?', 'end-fluid', 'end-pump'),
        ],
        'ends': [
            ('end-rack', 'Direksiyon kutusunun keçeleri sızdırıyor; kutunun '
             'yenilenmesi için ' + SHOP + '.', None),
            ('end-leak', 'Kaçak yapan hortumu ya da kelepçeyi yenileyin, '
             'yağı tamamlayın.', code('DA4', '3', '300')),
            ('end-belt', 'Kayışı gerin ya da değiştirin.',
             code('DA1', '0', '920', '01')),
            ('end-fluid', 'Sistemin havasını alın ve yağı değiştirin.',
             code('DA4', '3', '300')),
            ('end-pump', 'Pompa basınç vermiyor; pompayı değiştirin.',
             code('DA4', '3', '920', '01')),
        ],
    })

PS_CHECK = dm(
    code=code('DA4', '3', '300'), tech='Hidrolik direksiyon yağı',
    info='Kontrol ve hava alma', figure=2,
    supplies=[('Direksiyon yağı, ATF Dexron II', None)],
    steps=[
        'Motoru çalıştırıp direksiyonu birkaç kez sağa sola sonuna kadar '
        'çevirin; yağ 40-80 °C\'ye ısınsın.',
        'Motoru durdurun; depodaki seviye HOT işaretleri arasında olmalıdır.',
        'Seviye düşükse yağ ekleyin; kaçak arayın.',
        'Havayı almak için ön tekerlekleri kaldırın, motor kapalıyken '
        'direksiyonu sonuna kadar 10 kez sağa sola çevirin; motoru '
        'çalıştırıp tekrarlayın.',
        'Depodaki yağda köpük kalmadığını ve seviyenin değişmediğini '
        'kontrol edin.',
    ])

PS_PUMP = dm(
    code=code('DA4', '3', '920', '01'), tech='Hidrolik direksiyon pompası',
    figure=2, tools=[('Lokma takımı', 1), ('Rakor anahtarı', 1),
                     ('Tork anahtarı', 1)],
    spares=[('Hidrolik direksiyon pompası', 1)],
    supplies=[('Direksiyon yağı, ATF Dexron II', None)],
    steps=[
        'Depodaki yağı şırıngayla çekin; aksesuar kayışını sökün.',
        'Basınç hortumunun rakorunu ve emiş hortumunu pompadan ayırın; '
        'uçlarını tıkayın.',
        'Pompanın bağlantı cıvatalarını sökün ve pompayı kasnağıyla '
        'çıkarın.',
        'Yeni pompayı takın; basınç rakorunu yeni rondelayla 44 N·m\'de '
        'sıkın.',
        'Kayışı takıp gerin, yağı doldurun ve sistemin havasını alın.',
    ],
    next=code('DA4', '3', '300'))

# ===========================================================================
# Tekerlekler
# ===========================================================================

TIRES = dm(
    code=code('DA5', '1', '300'), tech='Lastikler', figure=6,
    tools=[('Lastik basınç ölçer', 1), ('Diş derinliği ölçer', 1)],
    conditions=['Lastikler soğuk (araç en az 3 saat durmuş).'],
    steps=[
        'Dört lastiğin ve stepnenin basıncını ölçün; ön ve arka 2,2 bar '
        'olmalıdır.',
        'Diş derinliğini üç noktadan ölçün. Yasal sınır 1,6 mm\'dir; kışın '
        'en az 4 mm önerilir.',
        'Yanaklarda kesik, şişlik ve çatlak olup olmadığına bakın. '
        'Şişlikli lastik hemen değiştirilmelidir.',
        'Lastiğin üretim tarihini (DOT kodunun son dört hanesi: hafta ve '
        'yıl) okuyun; altı yaşını geçmiş lastik kauçuğu sertleştiği için '
        'değiştirilmelidir.',
        'Aşınma düzensizse (iç ya da dış kenar) ön düzen ayarı yaptırın.',
    ])

BALANCE = dm(
    code=code('DA5', '1', '271'), tech='Tekerlek balansı', info='Ayar',
    figure=6, tools=[('Balans makinesi', 1)],
    spares=[('Balans ağırlığı', None)],
    steps=[
        'Tekerleği sökün; jantın iç yüzündeki çamur ve taşları temizleyin, '
        'eski ağırlıkları çıkarın.',
        'Tekerleği balans makinesine bağlayın; jant ölçülerini (14 inç, '
        '5 inç genişlik) girin.',
        'Makinenin gösterdiği yerlere ve ağırlıklarda çelik jant için '
        'çakma ağırlık takın.',
        'Yeniden döndürüp her iki düzlemde 5 g\'ın altında kaldığını '
        'kontrol edin.',
        'Tekerleği takıp bijonları 103 N·m\'de sıkın.',
    ])

WHEEL = dm(
    code=code('DA5', info='920'), tech='Tekerlek', figure=6,
    tools=[('Kriko', 1), ('Bijon anahtarı', 1), ('Tork anahtarı', 1)],
    warnings=['Aracı yokuşta krikoya almayın. El frenini çekin, karşı '
              'çapraz tekerleğin önüne takoz koyun.'],
    steps=[
        'Göbek kapağını çıkarın ve bijonları araç yerdeyken yarım tur '
        'gevşetin.',
        'Krikoyu kapı altındaki kriko noktasına yerleştirip tekerlek yerden '
        'kesilene kadar kaldırın.',
        'Bijonları sökün ve tekerleği çıkarın.',
        'Yeni tekerleği takın; bijonları çapraz sırayla elle sıkın.',
        'Aracı indirin ve bijonları çapraz sırayla 103 N·m\'de sıkın. '
        '100 km sonra yeniden kontrol edin.',
    ])

BEARING = dm(
    code=code('DA5', '2', '920'), tech='Ön tekerlek rulmanı', figure=4,
    tools=[('Pres', 1), ('Rulman çakma aparatı seti', 1),
           ('Segman pensesi', 1), ('Tork anahtarı', 1)],
    spares=[('Ön tekerlek rulmanı', 1), ('Aks somunu', 1)],
    steps=[
        'Aks somununu gevşetin; aracı kaldırıp tekerleği, kaliperi ve '
        'diski sökün.',
        'Rot başını ve alt rotili ayırın; amortisör cıvatalarını sökerek aks '
        'taşıyıcısını göbekle birlikte çıkarın.',
        'Göbeği preste taşıyıcıdan çıkarın; segmanı sökün ve rulmanı '
        'presle dışarı itin.',
        'Yeni rulmanı dış bileziğinden presleyin, segmanı takın; göbeği '
        'rulmanın iç bileziğine destek vererek presleyin.',
        'Taşıyıcıyı takın; aks somununu 216 N·m\'de sıkıp emniyetleyin, ön '
        'düzeni kontrol ettirin.',
    ])

BEARING_REAR = dm(
    code=code('DA5', '2', '920', '01'), tech='Arka tekerlek rulmanı',
    figure=8, tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Arka göbek ve rulman', 1)],
    steps=[
        'Aracı kaldırın; tekerleği, kaliperi ve diski sökün.',
        'Arka göbeğin aks taşıyıcısına bağlandığı dört cıvatayı arkadan '
        'sökün.',
        'Göbeği rulmanıyla birlikte çıkarın; taşıyıcının yüzeyini '
        'temizleyin.',
        'Yeni göbeği takın, cıvataları 80 N·m\'de sıkın; diski, kaliperi ve '
        'tekerleği takın.',
        'Tekerleği elle çevirip ses ve boşluk olmadığını kontrol edin.',
    ])

# ===========================================================================
# Elektrik ve aydınlatma
# ===========================================================================

ELECTRICAL = dm(
    code=code('DA6'), tech='Elektrik sistemi', figure=11,
    description=[
        ('Genel', [
            'Eksi kutbu gövdeye bağlı 12 V\'luk tek telli sistemdir. Motor '
            'dururken akü, motor çalışırken alternatör besler.',
            'Alternatör içindeki IC regülatörle şarj gerilimini 13,9-15,1 V '
            'arasında tutar.',
            'Ana sigorta ve röle kutusu motor bölmesinde akünün yanında, '
            'iç sigorta kutusu sürücü tarafında gösterge panelinin altındadır.',
        ]),
    ])

BATTERY_CHECK = dm(
    code=code('DA6', '1', '300'), tech='Akü', figure=11,
    tools=[('Voltmetre', 1)],
    warnings=['Akü patlayıcı hidrojen gazı çıkarır; yakınında kıvılcım '
              'çıkarmayın, sigara içmeyin.'],
    steps=[
        'Motor kapalıyken akü kutup başları arasındaki gerilimi ölçün. '
        '12,6 V ve üstü tam dolu, 12,4 V yaklaşık %75 dolu aküyü gösterir; '
        '12,2 V\'un altındaysa akü şarj edilmelidir.',
        'Motoru çalıştırın ve gerilimi yeniden ölçün. 13,9-15,1 V arası '
        'şarj sisteminin çalıştığını gösterir.',
        'Gerilim 13,5 V\'un altındaysa şarj sistemini kontrol edin.',
        'Kutup başlarındaki beyaz oksidi sıcak su ve tel fırçayla '
        'temizleyin; kelepçeleri sıkın.',
    ])

BATTERY = dm(
    code=code('DA6', '1', '920'), tech='Akü', figure=11,
    tools=[('Lokma, 10 mm', 1)],
    spares=[('Akü, 12 V 45 Ah', 1)],
    warnings=['Önce eksi (-), sonra artı (+) kutbu sökün; takarken önce '
              'artı, sonra eksi.'],
    steps=[
        'Kontağı kapatın ve anahtarı çıkarın.',
        'Eksi kutup kelepçesini, sonra artı kutup kelepçesini sökün.',
        'Akü tutucusunu sökün ve aküyü dik tutarak çıkarın.',
        'Akü tablasını temizleyin; yeni aküyü aynı yönde yerleştirin.',
        'Tutucuyu takın; önce artı, sonra eksi kelepçeyi bağlayıp sıkın.',
        'Radyo ve saat ayarlarını yeniden yapın.',
    ])

CHARGING_ISO = dm(
    code=code('DA6', '3', '421'), tech='Şarj sistemi', info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA6-002',
        'descr': 'Şarj lambası yanıyor, farlar sönük ya da dalgalı, akü '
                 'sık sık boşalıyor ya da ampuller sık yanıyor.',
        'steps': [
            ('stp-0001', 'Aksesuar kayışını kontrol edin.', 'Kayış gevşek, '
             'çatlak ya da ötüyor mu?', 'end-belt', 'stp-0002'),
            ('stp-0002', 'Motor 2000 d/d\'de çalışırken akü gerilimini '
             'ölçün.', 'Gerilim 13,9 V\'un altında mı?', 'stp-0003',
             'stp-0004'),
            ('stp-0003', 'Alternatörün B ucuyla akü artı kutbu arasındaki '
             'gerilim düşümünü ölçün.', 'Fark 0,5 V\'tan büyük mü?',
             'end-cable', 'end-alternator'),
            ('stp-0004', 'Ölçmeye devam edin.', 'Gerilim 15,1 V\'un üstünde '
             'mi?', 'end-regulator', 'end-battery'),
        ],
        'ends': [
            ('end-belt', 'Kayışı gerin ya da değiştirin.',
             code('DA1', '0', '920', '01')),
            ('end-cable', 'Şarj kablosu ya da sigortası (ALT 100 A) '
             'arızalı; bağlantıları temizleyin.', code('DA6', '6', '250')),
            ('end-alternator', 'Alternatör şarj etmiyor; alternatörü test '
             'edip değiştirin.', code('DA6', '3', '320')),
            ('end-regulator', 'Regülatör aşırı şarj ediyor; alternatörü '
             'değiştirin.', code('DA6', '3', '920')),
            ('end-battery', 'Şarj normal: aküyü test edin; araç dururken '
             'akım çeken bir devre olabilir (en çok 20 mA).',
             code('DA6', '1', '300')),
        ],
    })

CHARGING_TEST = dm(
    code=code('DA6', '3', '320'), tech='Şarj sistemi', info='Çalışma testi',
    figure=11, tools=[('Voltmetre', 1), ('Pens ampermetre', 1)],
    steps=[
        'Akü tam dolu olsun. Pens ampermetreyi alternatörün B kablosuna '
        'takın.',
        'Motoru 2000 d/d\'de, bütün tüketiciler kapalıyken çalıştırın: '
        'gerilim 13,9-15,1 V, akım 10 A\'in altında olmalıdır.',
        'Farları uzunda, ısıtmayı ve arka cam ısıtıcısını açın: akım en '
        'az 30 A olmalıdır.',
        'Değerler tutmuyorsa alternatörü değiştirin.',
    ])

ALTERNATOR = dm(
    code=code('DA6', '3', '920'), tech='Alternatör', figure=11,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Alternatör', 1)],
    warnings=['İşe başlamadan akünün eksi kutbunu sökün; B ucu sürekli '
              'akü gerilimindedir.'],
    steps=[
        'Akünün eksi kutbunu sökün.',
        'Alternatörün soketini ve B ucu somununu sökün.',
        'Kayışı gevşetip çıkarın; ayar ve pivot cıvatalarını sökerek '
        'alternatörü çıkarın.',
        'Yeni alternatörü takın; B ucu somununu 10 N·m\'de sıkın.',
        'Kayışı takıp gerin; aküyü bağlayıp şarj gerilimini ölçün.',
    ],
    next=code('DA1', '0', '920', '01'))

STARTING_ISO = dm(
    code=code('DA6', '4', '421'), tech='Marş sistemi', info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA6-003',
        'descr': 'Marşa basınca hiçbir şey olmuyor, yalnız tık sesi geliyor '
                 'ya da marş ağır dönüyor.',
        'steps': [
            ('stp-0001', 'Akü gerilimini ölçün.', 'Gerilim 12,2 V\'un '
             'altında mı?', 'end-battery', 'stp-0002'),
            ('stp-0002', 'Marşa basarken akü gerilimini izleyin.', 'Gerilim '
             '9,6 V\'un altına düşüyor mu?', 'stp-0003', 'stp-0004'),
            ('stp-0003', 'Akü kutup başlarını ve marş kablosu bağlantılarını '
             'kontrol edin.', 'Bağlantılar oksitli ya da gevşek mi?',
             'end-cable', 'end-starter'),
            ('stp-0004', 'Marşa basarken marş motorunun 50 ucundaki gerilimi '
             'ölçün (vites boşta).', 'Gerilim 8 V\'un üstünde mi?',
             'end-starter', 'end-switch'),
        ],
        'ends': [
            ('end-battery', 'Aküyü şarj edin ya da değiştirin.',
             code('DA6', '1', '920')),
            ('end-cable', 'Kutup başlarını ve kabloları temizleyip sıkın.',
             code('DA6', '6', '250')),
            ('end-starter', 'Marş motoru ya da otomatiği arızalı; marş '
             'motorunu değiştirin.', code('DA6', '4', '920')),
            ('end-switch', 'Marş motoruna sinyal gelmiyor: kontak anahtarı, '
             'debriyaj pedalı anahtarı ya da marş rölesi arızalı.',
             code('DA6', '4', '920', '01')),
        ],
    })

STARTER = dm(
    code=code('DA6', '4', '920'), tech='Marş motoru', figure=11,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Marş motoru', 1)],
    warnings=['İşe başlamadan akünün eksi kutbunu sökün.'],
    steps=[
        'Akünün eksi kutbunu sökün; gerekirse hava filtresi kutusunu sökün.',
        'Marş otomatiğinin 30 ucu somununu ve 50 ucu soketini sökün.',
        'Marş motorunun şanzımana bağlandığı iki cıvatayı sökün ve marşı '
        'çıkarın.',
        'Yeni marşı takın; cıvataları 37 N·m, 30 ucu somununu 10 N·m\'de '
        'sıkın.',
        'Aküyü bağlayıp marşı deneyin.',
    ])

IGN_SWITCH = dm(
    code=code('DA6', '4', '920', '01'), tech='Kontak anahtarı ve marş '
    'rölesi', figure=7, tools=[('Ohmmetre', 1), ('Tornavida', 1)],
    spares=[('Kontak anahtarı elektrik bloğu', 1)],
    warnings=['Hava yastıklı donanımda akünün eksi kutbunu söküp 90 saniye '
              'bekleyin; direksiyon simidine dokunmadan önce.'],
    steps=[
        'İç sigorta kutusundaki marş rölesini bilinen sağlam bir röleyle '
        'değiştirip deneyin.',
        'Debriyaj pedalı anahtarını ölçün: pedala basınca kontak '
        'kapanmalıdır.',
        'Direksiyon kolonu kapaklarını sökün; kontak bloğunun soketini '
        'çıkarın ve START konumunda AM1-ST1 uçları arasında süreklilik '
        'arayın.',
        'Süreklilik yoksa elektrik bloğunun iki vidasını sökerek bloğu '
        'değiştirin.',
    ])

FUSE_ISO = dm(
    code=code('DA6', '6', '421'), tech='Elektrik devreleri',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA6-004',
        'descr': 'Bir elektrikli donanım (korna, gösterge, lamba, cam) hiç '
                 'çalışmıyor ya da ara sıra kesiliyor.',
        'steps': [
            ('stp-0001', 'Kullanıcı el kitabındaki sigorta tablosundan '
             'devrenin sigortasını bulun ve kontrol edin.', 'Sigorta '
             'atmış mı?', 'stp-0002', 'stp-0003'),
            ('stp-0002', 'Aynı değerde yeni sigorta takın ve donanımı '
             'çalıştırın.', 'Sigorta hemen yeniden atıyor mu?', 'end-short',
             'end-ok'),
            ('stp-0003', 'Donanımın soketinde kontak açıkken gerilim '
             'ölçün.', 'Gerilim var mı?', 'stp-0004', 'end-wiring'),
            ('stp-0004', 'Donanımın toprak ucuyla gövde arasındaki direnci '
             'ölçün.', 'Direnç 1 Ω\'un üstünde mi?', 'end-ground',
             'end-device'),
        ],
        'ends': [
            ('end-short', 'Devrede kısa devre var; kabloyu sürtünme ve ezilme '
             'yerlerinde arayın.', code('DA6', '6', '300')),
            ('end-ok', 'Sigorta yenilendi; devre çalışıyor.', None),
            ('end-wiring', 'Sigortayla donanım arasında kopukluk ya da röle '
             'arızası var; demeti kontrol edin.', code('DA6', '6', '300')),
            ('end-ground', 'Toprak bağlantısı oksitli ya da gevşek; '
             'temizleyip sıkın.', code('DA6', '6', '250')),
            ('end-device', 'Besleme ve toprak sağlam: donanımın kendisi '
             'arızalı (korna, gösterge, motor). İlgili değiştirme '
             'işlemine bakın.', None),
        ],
    })

FUSE_CHECK = dm(
    code=code('DA6', '6', '300'), tech='Sigortalar ve kablo demeti',
    figure=2, tools=[('Sigorta çekme maşası', 1), ('Avometre', 1)],
    spares=[('Sigorta takımı (7,5-30 A)', 1)],
    cautions=['Atan sigortanın yerine daha yüksek değerli sigorta '
              'takmayın; kablo yanabilir.'],
    steps=[
        'Kontağı ve donanımı kapatın.',
        'Sigortayı maşayla çekin; ince telin kopuk olup olmadığına bakın ya '
        'da iki ucu arasında süreklilik ölçün.',
        'Aynı değerde (renkte) sigorta takın.',
        'Kısa devre arıyorsanız sigortanın yerine bir test lambası bağlayın; '
        'demeti parça parça oynatıp lambanın söndüğü yeri bulun.',
        'Demette sürtünen, eriyen ya da ezilen yeri yalıtın ya da onarın; '
        'demeti tutucularına yeniden bağlayın.',
    ])

GROUND = dm(
    code=code('DA6', '6', '250'), tech='Toprak bağlantıları',
    info='Temizlik', figure=11,
    tools=[('Tel fırça', 1), ('Lokma takımı', 1)],
    supplies=[('Kontak spreyi', None), ('Akü kutup gresi', None)],
    steps=[
        'Akünün eksi kutbunu sökün.',
        'Motor-gövde toprak örgüsünü, akü eksi kablosunun gövde bağlantısını '
        've far arkasındaki toprak noktalarını sökün.',
        'Temas yüzeylerini çıplak metal görünene kadar tel fırçayla '
        'temizleyin.',
        'Kontak spreyi sıkıp bağlantıları sıkın; üzerine ince bir kat gres '
        'sürün.',
        'Aküyü bağlayıp marş ve lambaları deneyin.',
    ])

CLUSTER = dm(
    code=code('DA6', '5', '920'), tech='Gösterge paneli', figure=7,
    tools=[('Döşeme sökme aparatı', 1), ('Tornavida', 1)],
    spares=[('Gösterge paneli lambası', 1)],
    cautions=['Göstergeyi yüzü aşağı bakacak şekilde koymayın; ibreler '
              'zarar görür.'],
    steps=[
        'Akünün eksi kutbunu sökün.',
        'Gösterge çerçevesinin vidalarını sökün ve çerçeveyi tırnaklarından '
        'çekip alın.',
        'Göstergenin dört vidasını sökün, öne çekip arkasındaki soketleri ve '
        'kilometre teli bağlantısını ayırın.',
        'Yanmış lambaları çeyrek tur çevirerek çıkarın ve yenileriyle '
        'değiştirin; baskılı devre kartında yanık ya da çatlak lehim '
        'arayın.',
        'Göstergeyi takıp bütün ibreleri ve uyarı lambalarını deneyin.',
    ])

HORN = dm(
    code=code('DA6', '8', '920'), tech='Korna', figure=2,
    tools=[('Lokma takımı', 1)], spares=[('Korna', 1)],
    steps=[
        'Korna ön tamponun arkasında, radyatör traversindedir. Soketini '
        'çıkarın.',
        'Kornaya aküden doğrudan 12 V verin; ses yoksa korna arızalıdır.',
        'Korna sağlamsa HORN sigortasını, korna rölesini ve direksiyondaki '
        'korna kontağını kontrol edin.',
        'Arızalı kornayı tutucu cıvatasını sökerek değiştirin; cıvatayı '
        '20 N·m\'de sıkın.',
    ])

WINDOW_ISO = dm(
    code=code('DA6', '7', '421'), tech='Elektrikli camlar ve merkezi kilit',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA6-005',
        'descr': 'Elektrikli cam inip kalkmıyor ya da yavaş gidiyor; bir '
                 'kapı merkezi kilitle kilitlenmiyor.',
        'steps': [
            ('stp-0001', 'Sorun bütün kapılarda mı, tek kapıda mı bakın.',
             'Hiçbir cam ya da kilit çalışmıyor mu?', 'end-fuse', 'stp-0002'),
            ('stp-0002', 'Sorunlu kapının camını hem sürücü kumandasından '
             'hem kendi düğmesinden deneyin.', 'Cam motorundan ses geliyor '
             'ama cam hareket etmiyor mu?', 'end-regulator', 'stp-0003'),
            ('stp-0003', 'Kapının açılma yerindeki (kapı ile direk arası) '
             'kablo körüğünü açıp kabloları oynatarak deneyin.', 'Kablo '
             'oynatınca çalışıyor mu?', 'end-wiring', 'stp-0004'),
            ('stp-0004', 'Kilit motorunun soketinde kilitleme sırasında '
             'gerilim ölçün.', 'Gerilim var ama kilit hareket etmiyor mu?',
             'end-lock', 'end-switch'),
        ],
        'ends': [
            ('end-fuse', 'POWER ya da DOOR LOCK sigortasını ve rölesini '
             'kontrol edin.', code('DA6', '6', '300')),
            ('end-regulator', 'Cam krikosunun teli kopmuş ya da makarası '
             'kırılmış; krikoyu değiştirin.', code('DA0', '1', '920')),
            ('end-wiring', 'Kapı kablo körüğündeki tel kopmuş; telleri '
             'lehimleyip yalıtın.', code('DA6', '6', '300')),
            ('end-lock', 'Kilit motoru arızalı; kilit mekanizmasını '
             'değiştirin.', code('DA0', '1', '920', '01')),
            ('end-switch', 'Kumanda düğmesi arızalı; düğmeyi değiştirmek için '
             + SHOP + '.', None),
        ],
    })

LIGHTS_ISO = dm(
    code=code('DA6', '2', '421'), tech='Aydınlatma ve sinyal',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA6-006',
        'descr': 'Bir lamba yanmıyor, stop lambaları sürekli yanıyor ya da '
                 'hiç yanmıyor, sinyaller hızlı çakıyor ya da çakmıyor.',
        'steps': [
            ('stp-0001', 'Stop lambalarını bir yardımcıyla kontrol edin.',
             'Stop lambaları pedala basmadan yanıyor ya da hiç yanmıyor mu?',
             'end-switch', 'stp-0002'),
            ('stp-0002', 'Sinyali iki yöne çalıştırın.', 'Bir yönde hızlı '
             'çakıyor mu?', 'end-bulb', 'stp-0003'),
            ('stp-0003', 'Sinyaller hiç çakmıyor ya da sürekli yanıyor mu '
             'bakın.', 'İki yönde de çakma yok mu?', 'end-flasher',
             'stp-0004'),
            ('stp-0004', 'Yanmayan lambanın ampulünü çıkarıp bakın.',
             'Ampulün teli kopuk ya da camı kararmış mı?', 'end-bulb',
             'end-socket'),
        ],
        'ends': [
            ('end-switch', 'Stop lambası müşiri ayarsız ya da arızalı; '
             'müşiri ayarlayın.', code('DA6', '2', '271')),
            ('end-bulb', 'Ampulü değiştirin (hızlı çakma o taraftaki bir '
             'ampulün yandığını gösterir).', code('DA6', '2', '920', '01')),
            ('end-flasher', 'Sinyal rölesi (flaşör) arızalı; röleyi '
             'değiştirin.', code('DA6', '2', '920', '02')),
            ('end-socket', 'Ampul sağlam: duy oksitli ya da besleme yok; '
             'sigortayı ve duyu kontrol edin.', code('DA6', '6', '421')),
        ],
    })

HEADLIGHT = dm(
    code=code('DA6', '2', '920'), tech='Far ampulü',
    spares=[('Ampul, H4 12 V 60/55 W', 1)],
    cautions=['Halojen ampulün camına çıplak elle dokunmayın; parmak izi '
              'ampulün ömrünü kısaltır.'],
    steps=[
        'Farları kapatın ve kaputu açın.',
        'Farın arkasındaki soketi ampulden çekip çıkarın.',
        'Lastik toz kapağını çıkarın, yaylı tutucuyu açın ve ampulü '
        'çıkarın.',
        'Yeni ampulü tırnakları yuvalara oturacak şekilde takın; tutucuyu '
        've toz kapağını kapatın.',
        'Soketi takın ve kısa ile uzun farı yakarak kontrol edin.',
    ])

TAIL_BULB = dm(
    code=code('DA6', '2', '920', '01'), tech='Arka lamba ampulleri',
    spares=[('Ampul, P21/5W 12 V', 1), ('Ampul, P21W 12 V', 1)],
    steps=[
        'Bagajı açın; lambanın arkasındaki kapağı ya da döşemeyi açın.',
        'Yanmayan ampulün duyunu çeyrek tur çevirip çıkarın.',
        'Ampulü bastırıp çevirerek çıkarın; aynı tip ampulü takın (stop ve '
        'park çift telli P21/5W, sinyal ve geri vites P21W).',
        'Duyu takın, lambaları bir yardımcıyla deneyin.',
    ])

FLASHER = dm(
    code=code('DA6', '2', '920', '02'), tech='Sinyal rölesi (flaşör)',
    figure=7, spares=[('Sinyal rölesi', 1)],
    steps=[
        'Röle sürücü tarafında, gösterge panelinin altındaki röle '
        'bloğundadır; dörtlü flaşör düğmesine basınca tıkırdayan röledir.',
        'Röleyi soketinden dikkatle çekip çıkarın.',
        'Aynı tipte yeni röleyi takın.',
        'Sinyalleri ve dörtlüleri deneyin; dakikada 60-120 çakmalıdır.',
    ])

FOG_BULB = dm(
    code=code('DA6', '2', '920', '03'), tech='Sis lambası',
    spares=[('Ampul, H3 12 V 55 W', 1), ('Sis lambası contası', 1)],
    cautions=['Halojen ampulün camına çıplak elle dokunmayın.'],
    steps=[
        'Ön tamponun alt kapağını ya da çamurluk içi davlumbazı açarak '
        'lambanın arkasına ulaşın.',
        'Lambanın içinde su varsa lambayı sökün, havalandırma deliğini açın '
        've lambayı kurutun; contayı yenileyin.',
        'Soketi çıkarın, tutucu yayı açın ve ampulü değiştirin.',
        'Lambayı takıp yakın; ışık hüzmesini duvarda kontrol edip ayar '
        'vidasıyla düzeltin.',
    ])

BRAKE_SWITCH = dm(
    code=code('DA6', '2', '271'), tech='Stop lambası müşiri', info='Ayar',
    figure=7, tools=[('Ohmmetre', 1)],
    spares=[('Stop lambası müşiri', 1)],
    steps=[
        'Müşir fren pedalının üstündedir. Soketini çıkarın.',
        'Pedal bırakıkken müşirin uçları arasında süreklilik olmamalı; '
        'pedala basınca olmalıdır.',
        'Kontra somunu gevşetin; müşiri, gövdesi pedal kolu tamponuyla '
        '0,5-2,4 mm boşluk kalacak şekilde çevirin.',
        'Kontra somunu sıkın; stop lambalarının pedala basınca yandığını, '
        'bırakınca söndüğünü kontrol edin.',
    ])

# ===========================================================================
# Isıtma ve klima
# ===========================================================================

HVAC = dm(
    code=code('DA7'), tech='Isıtma ve klima', figure=7,
    description=[
        ('Genel', [
            'Kalorifer, motor suyunun geçtiği kalorifer peteğini fanla '
            'üfler; sıcaklık karışım kapağıyla ayarlanır.',
            'Klimada kompresör R-134a soğutucu akışkanı sıkıştırır, '
            'kondenser radyatörün önünde ısısını atar, kurutucu nemi '
            'tutar, genleşme valfinden geçen akışkan evaporatörde '
            'buharlaşarak havayı soğutur.',
            'Kompresör elektromanyetik kavramayla devreye girer; basınç '
            'müşiri basınç düşük ya da yüksekken kompresörü durdurur.',
        ]),
    ])

HEATER_ISO = dm(
    code=code('DA7', '1', '421'), tech='Isıtma ve havalandırma',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA7-001',
        'descr': 'Kalorifer ısıtmıyor, fan çalışmıyor ya da yalnız en yüksek '
                 'kademede çalışıyor; camlar buğulanıyor, içeride tatlı bir '
                 'koku var.',
        'steps': [
            ('stp-0001', 'Fanı her kademede çalıştırın.', 'Fan hiç '
             'çalışmıyor mu?', 'stp-0002', 'stp-0003'),
            ('stp-0002', 'HEATER sigortasını kontrol edin; fan soketinde '
             'gerilim ölçün.', 'Gerilim var mı?', 'end-blower', 'end-fuse'),
            ('stp-0003', 'Fanın hangi kademelerde çalıştığına bakın.',
             'Yalnız en yüksek kademede mi çalışıyor?', 'end-resistor',
             'stp-0004'),
            ('stp-0004', 'Ön yolcu tarafında halıyı yoklayın ve camlara '
             'bakın.', 'Halı ıslak ya da camlarda yağlı buğu var mı?',
             'end-core', 'end-cooling'),
        ],
        'ends': [
            ('end-blower', 'Fan motoru arızalı; motoru değiştirin.',
             code('DA7', '1', '920')),
            ('end-fuse', 'Sigortayı ve fan rölesini kontrol edin.',
             code('DA6', '6', '300')),
            ('end-resistor', 'Fan direnci arızalı; dirençle birlikte fanı '
             'kontrol edin.', code('DA7', '1', '920')),
            ('end-core', 'Kalorifer peteği sızdırıyor; peteği değiştirin.',
             code('DA7', '1', '920', '01')),
            ('end-cooling', 'Fan çalışıyor ama ısıtmıyor: motorun ısınmasını '
             've soğutma suyunu kontrol edin.', code('DA1', '4', '421', '01')),
        ],
    })

BLOWER = dm(
    code=code('DA7', '1', '920'), tech='Kalorifer fanı ve direnci',
    figure=7, tools=[('Tornavida', 1), ('Ohmmetre', 1)],
    spares=[('Kalorifer fan motoru', 1), ('Fan direnci', 1)],
    steps=[
        'Torpido gözünü ve altındaki kapağı sökün; fan motoru yolcu '
        'tarafında torpidonun altındadır.',
        'Fan direncinin soketini çıkarıp kademeler arasındaki direnci '
        'ölçün; kopuk kademe varsa direnci değiştirin.',
        'Fan motorunun soketini çıkarın, üç vidasını sökün ve motoru '
        'aşağı indirin.',
        'Yeni motoru takın; kanatların gövdeye sürtmediğini kontrol edin.',
        'Fanı bütün kademelerde deneyin.',
    ])

HEATER_CORE = dm(
    code=code('DA7', '1', '920', '01'), tech='Kalorifer peteği', figure=7,
    tools=[('Döşeme sökme aparatı', 1), ('Lokma takımı', 1),
           ('Kelepçe pensesi', 1)],
    spares=[('Kalorifer peteği', 1)], supplies=[('Soğutma suyu', None)],
    warnings=['Hava yastıklı donanımda akünün eksi kutbunu söküp 90 saniye '
              'bekleyin.'],
    steps=[
        'Soğutma suyunu boşaltın; motor bölmesinde torpido duvarındaki '
        'kalorifer hortumlarını ayırın.',
        'Orta konsolu ve gösterge panelinin alt kapaklarını sökün.',
        'Kalorifer kutusunun alt kapağını açın; petek borularının kelepçe '
        'tutucularını sökün ve peteği aşağı çekip çıkarın.',
        'Yeni peteği yerleştirin, borularını bağlayın ve kapakları takın.',
        'Hortumları bağlayın, suyu doldurup havasını alın; halıyı '
        'kurutun.',
    ],
    next=code('DA1', '4', '210'))

AC_ISO = dm(
    code=code('DA7', '2', '421'), tech='Klima', info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA7-002',
        'descr': 'Klima soğutmuyor ya da az soğutuyor; klima açılınca ses '
                 'geliyor.',
        'steps': [
            ('stp-0001', 'Motor çalışırken klimayı açın ve kompresörün ön '
             'kavramasına bakın.', 'Kavrama devreye giriyor (merkez dönüyor) '
             'mu?', 'stp-0003', 'stp-0002'),
            ('stp-0002', 'Kavramanın soketinde gerilim ölçün.', 'Gerilim '
             'var mı?', 'end-clutch', 'stp-0004'),
            ('stp-0003', 'Kondenserin önünü ve fanın çalışmasını kontrol '
             'edin.', 'Kondenser kirli ya da fan çalışmıyor mu?',
             'end-condenser', 'end-gas'),
            ('stp-0004', 'Klima manometreleriyle sistem basıncını ölçün.',
             'Statik basınç 400 kPa\'nın altında mı?', 'end-gas',
             'end-switch'),
        ],
        'ends': [
            ('end-clutch', 'Kompresör kavraması arızalı ya da boşluğu '
             'büyümüş; kompresörü kontrol edin.', code('DA7', '2', '920')),
            ('end-condenser', 'Kondenseri temizleyin; fanı kontrol edin.',
             code('DA1', '4', '320')),
            ('end-gas', 'Soğutucu akışkan eksik: sızıntıyı bulup giderin ve '
             'sistemi şarj ettirin.', code('DA7', '2', '300')),
            ('end-switch', 'Basınç müşiri, klima rölesi ya da kumanda '
             'arızalı; ' + SHOP + '.', None),
        ],
    })

AC_CHECK = dm(
    code=code('DA7', '2', '300'), tech='Klima', info='Kaçak ve basınç '
    'kontrolü', figure=10,
    tools=[('Klima manometre takımı', 1), ('Elektronik kaçak dedektörü', 1)],
    supplies=[('Soğutucu akışkan R-134a', None)],
    warnings=['Soğutucu akışkan cilde ve göze değerse soğuk yanığı yapar; '
              'gözlük ve eldiven kullanın. Akışkanı havaya boşaltmayın.'],
    steps=[
        'Manometreleri alçak ve yüksek basınç servis vanalarına bağlayın.',
        'Motor 1500 d/d\'de, klima en soğukta ve fan en yüksekteyken '
        'okuyun: alçak taraf 150-250 kPa, yüksek taraf 1370-1570 kPa '
        '(dış sıcaklık 30-35 °C).',
        'Alçak basınç düşükse sistemde akışkan eksiktir. Rakorları, '
        'kondenseri ve kompresör keçesini kaçak dedektörüyle tarayın.',
        'Kaçağı giderdikten sonra sistemi vakumlayıp etiketteki miktarda '
        'R-134a ile şarj ettirin (yetkili klima servisi işi).',
    ])

COMPRESSOR = dm(
    code=code('DA7', '2', '920'), tech='Klima kompresörü', figure=11,
    tools=[('Sentil takımı', 1), ('Lokma takımı', 1)],
    spares=[('Klima kompresörü', 1), ('Klima O-halkası takımı', 1)],
    supplies=[('Kompresör yağı, ND-OIL 8', None),
              ('Soğutucu akışkan R-134a', None)],
    warnings=['Sistemdeki akışkanı yalnız geri kazanım cihazıyla '
              'boşaltın.'],
    steps=[
        'Kavrama boşluğunu sentille ölçün: 0,35-0,65 mm. Boşluk büyükse ya da '
        'bobin direnci 3,4-3,8 Ω dışındaysa kavrama arızalıdır.',
        'Akışkanı geri kazanım cihazıyla boşaltın; kayışı ve kompresör '
        'soketini sökün.',
        'Hortum bağlantılarını ayırıp tıkayın; kompresörün dört cıvatasını '
        'sökerek çıkarın.',
        'Yeni kompresördeki yağ miktarını eskisine göre ayarlayın; yeni '
        'O-halkalarla takın, cıvataları 25 N·m\'de sıkın.',
        'Kayışı takın; sistemi vakumlayıp şarj edin ve basınçları '
        'kontrol edin.',
    ],
    next=code('DA7', '2', '300'))

# --- Parça haritası --------------------------------------------------------

# Düğümü olmayan parçalar içinde bulundukları düğüme bağlı. Bir düğüme
# dokunulunca uygulama o düğüme bağlı tek düğümlü parçalardan en üstte
# olanı açar (eşitlikte dosyadaki sırayla). Bu yüzden her düğümün kendi
# parçası, aynı düğüme bağlanan başka sistemlerin parçalarından önce
# tanımlanır; `node_owner_check()` bunu denetler.

ENGINE_NODES = [
    'engine_block', 'engine_head', 'engine_head_gasket', 'engine_head_cover',
    'engine_camshafts', 'engine_timing_chain', 'engine_timing_cover',
    'engine_crankshaft', 'engine_pistons', 'engine_rods', 'engine_oil_pan',
    'engine_oil_pump', 'engine_oil_filter', 'engine_crank_pulley',
    'engine_intake', 'engine_exhaust_manifold',
]
DOOR_NODES = ['door_fl', 'door_fr', 'door_rl', 'door_rr']
SEAT_NODES = ['seat_front_l', 'seat_front_r', 'seat_rear']
WHEEL_NODES = ['wheel_fl', 'wheel_fr', 'wheel_rl', 'wheel_rr']

# Gövde
part('body', 'Gövde', None, 'DA0-00',
     ['body', 'hood', 'trunk', *DOOR_NODES, 'fender_l', 'fender_r',
      'bumper_front', 'bumper_rear', 'grille', 'windshield', 'rear_window',
      'wipers', 'washer_tank', 'mirror_l', 'mirror_r'], 'z.cabin',
     'Bütün parçaları taşıyan çelik monokok kasa ve sökülebilir paneller.')
part('body.shell', 'Gövde kabuğu', 'body', 'DA0-00', ['body'], 'z.cabin',
     'Tavan, direkler, taban, marşpiyeller ve iç çamurluklar; tekerlek '
     'davlumbazlarında plastik iç kaplama.', {'inspect': BODY_CHECK})
part('body.hood', 'Kaput', 'body', 'DA0-20', ['hood'], 'z.front',
     'Motor bölmesini örter; kilidi ön traverstedir.',
     {'adjust': HOOD_LATCH})
part('body.trunk', 'Bagaj kapağı', 'body', 'DA0-20', ['trunk'], 'z.rear',
     'Bagaj bölmesini kapatır; arka lambalar arasındaki panel üstündedir.')
part('body.door_fl', 'Sol ön kapı', 'body', 'DA0-10', ['door_fl'], 'z.cabin',
     'Ön yolcu kapısı; camı, kilidi ve iç döşemesiyle.', {'inspect': DOORS})
part('body.door_fr', 'Sağ ön kapı', 'body', 'DA0-10', ['door_fr'], 'z.cabin',
     'Sürücü kapısı. Modeldeki araç sağdan direksiyonlu (Japonya modeli).',
     {'inspect': DOORS})
part('body.door_rl', 'Sol arka kapı', 'body', 'DA0-10', ['door_rl'],
     'z.cabin', 'Arka yolcu kapısı.', {'inspect': DOORS})
part('body.door_rr', 'Sağ arka kapı', 'body', 'DA0-10', ['door_rr'],
     'z.cabin', 'Arka yolcu kapısı.', {'inspect': DOORS})
part('body.window_regulators', 'Cam krikoları', 'body', 'DA0-10',
     DOOR_NODES, 'z.cabin', 'Kapı camlarını inip kaldıran elektrik motorlu '
     'telli mekanizma; kapının içinde.', {'replace': REGULATOR}, quantity=4)
part('body.door_locks', 'Kapı kilitleri', 'body', 'DA0-10', DOOR_NODES,
     'z.cabin', 'Merkezi kilit motoruyla birlikte kapı kilit mekanizması.',
     {'replace': LOCK}, quantity=4)
part('body.door_seals', 'Kapı fitilleri', 'body', 'DA0-10', DOOR_NODES,
     'z.cabin', 'Kapı ile gövde arasını su ve rüzgâra karşı kapatır.',
     {'inspect': DOORS, 'replace': SEALS}, quantity=4)
part('body.fender_l', 'Sol ön çamurluk', 'body', 'DA0-00', ['fender_l'],
     'z.front', 'Ön tekerleğin üstünü örten sökülebilir panel; yan sinyal '
     'lambası üstündedir.')
part('body.fender_r', 'Sağ ön çamurluk', 'body', 'DA0-00', ['fender_r'],
     'z.front', 'Ön tekerleğin üstünü örten sökülebilir panel; yan sinyal '
     'lambası üstündedir.')
part('body.bumper_front', 'Ön tampon', 'body', 'DA0-30', ['bumper_front'],
     'z.front', 'Küçük çarpmalarda darbeyi emer; köşelerinde sis lambaları '
     'vardır.')
part('body.bumper_rear', 'Arka tampon', 'body', 'DA0-30', ['bumper_rear'],
     'z.rear', 'Küçük çarpmalarda darbeyi emer.')
part('body.grille', 'Ön ızgara', 'body', 'DA0-30', ['grille'], 'z.front',
     'Farlar arasında, radyatöre hava alır; Toyota amblemi üstündedir.')
part('body.windshield', 'Ön cam', 'body', 'DA0-40', ['windshield'],
     'z.cabin', 'Lamine güvenlik camı; gövdeye yapıştırılmıştır.',
     {'inspect': WINDSHIELD_CHECK, 'replace': WINDSHIELD})
part('body.rear_window', 'Arka cam', 'body', 'DA0-40', ['rear_window'],
     'z.rear', 'Temperli cam; içinde buğu çözücü rezistans telleri vardır.')
part('body.wipers', 'Silecekler', 'body', 'DA0-40', ['wipers'], 'z.cabin',
     'Ön camı yağmurda temiz tutar.',
     {'replace': WIPERS, 'isolate': WIPER_ISO}, quantity=2)
part('body.wiper_motor', 'Silecek motoru', 'body.wipers', 'DA0-40',
     ['wipers'], 'z.cabin', 'Torpido üstü ızgaranın altında; kolları '
     'mekanizmayla sürer, park anahtarı kolları yerine getirir.',
     {'replace': WIPER_MOTOR, 'isolate': WIPER_ISO})
part('body.washer', 'Cam suyu deposu ve pompası', 'body', 'DA0-40',
     ['washer_tank'], 'z.engine', 'Motor bölmesinin sağ ön köşesinde; '
     'pompa deponun altındadır.', {'replace': WASHER})
part('body.mirrors', 'Dış dikiz aynaları', 'body', 'DA0-50',
     ['mirror_l', 'mirror_r'], 'z.cabin',
     'İçeriden kolla ayarlanan dış aynalar.', {'replace': MIRROR},
     quantity=2)

# Kabin
part('interior', 'Kabin', None, 'DA0-70',
     [*SEAT_NODES, 'dashboard', 'carpet', 'headliner', 'interior_trim',
      'pedals'], 'z.cabin',
     'Koltuklar, emniyet kemerleri, gösterge paneli ve iç döşeme.')
part('interior.seat_front_l', 'Sol ön koltuk', 'interior', 'DA0-60',
     ['seat_front_l'], 'z.cabin', 'Yolcu koltuğu; kumaş kaplı, raylı.')
part('interior.seat_front_r', 'Sağ ön koltuk', 'interior', 'DA0-60',
     ['seat_front_r'], 'z.cabin', 'Sürücü koltuğu; kumaş kaplı, raylı ve '
     'sırt açısı ayarlı.', {'repair': SEAT})
part('interior.seat_rear', 'Arka koltuk', 'interior', 'DA0-60',
     ['seat_rear'], 'z.cabin', 'Üç kişilik arka koltuk; minderin altında '
     'yakıt pompası servis kapağı vardır.')
part('interior.seat_belts', 'Emniyet kemerleri', 'interior', 'DA0-60',
     SEAT_NODES, 'z.cabin', 'Önde makaralı üç noktalı kemerler; makara '
     'ani çekişte ve sert frende kilitlenir.',
     {'inspect': BELT_CHECK, 'replace': BELT}, quantity=5)
part('interior.srs', 'Hava yastığı sistemi (SRS)', 'interior', 'DA0-60',
     ['steering_wheel', 'dashboard'], 'z.cabin',
     'SRS donanımlı araçlarda direksiyon simidindeki sürücü hava yastığı '
     've ortadaki çarpma sensörü. SRS lambası gösterge panelindedir.',
     {'isolate': SRS_ISO})
part('interior.dashboard', 'Gösterge paneli gövdesi', 'interior',
     'DA0-70', ['dashboard'], 'z.cabin', 'Ön konsol, havalandırma ızgaraları, '
     'radyo yuvası ve torpido gözü; arkasında motor beyni ve kalorifer '
     'kutusu durur.')
part('interior.carpet', 'Halı ve paspaslar', 'interior', 'DA0-70',
     ['carpet'], 'z.cabin', 'Tabanı örten halı ve üstündeki paspaslar.')
part('interior.headliner', 'Tavan döşemesi', 'interior', 'DA0-70',
     ['headliner'], 'z.cabin', 'Tavanı ve direklerin üst kısmını örten açık '
     'renkli döşeme; tavan lambası üstündedir.')
part('interior.trim', 'İç döşeme panelleri', 'interior', 'DA0-70',
     ['interior_trim'], 'z.cabin', 'Direk kaplamaları, orta konsol, arka raf '
     've iç dikiz aynası.')
part('interior.pedals', 'Pedal grubu', 'interior', 'DA0-70', ['pedals'],
     'z.cabin', 'Debriyaj, fren ve gaz pedalları; sağdan direksiyonlu '
     'olduğu için sağ taraftadır.')

# Motor
part('engine', 'Motor', None, 'DA1-00',
     [*ENGINE_NODES, 'engine_water_pump'], 'z.engine',
     '1,8 litre, dört silindirli 1ZZ-FE benzinli motor.',
     {'isolate': ENGINE_ISOLATE})
part('engine.block', 'Silindir bloğu', 'engine', 'DA1-10',
     ['engine_block'], 'z.engine',
     'Silindirleri ve krank milini taşıyan alüminyum gövde.',
     {'measure': COMPRESSION})
part('engine.head', 'Silindir kapağı', 'engine', 'DA1-10', ['engine_head'],
     'z.engine', 'Supapları, eksantrikleri ve yanma odalarını taşır.',
     {'measure': COMPRESSION, 'isolate': ENGINE_NOISE})
part('engine.valves', 'Supaplar ve iticiler', 'engine.head', 'DA1-10',
     ['engine_head'], 'z.engine', 'Silindir başına iki emme, iki egzoz '
     'supabı; boşluk itici kalınlığıyla ayarlanır.', {'adjust': VALVES},
     quantity=16)
part('engine.head_gasket', 'Silindir kapak contası', 'engine.head',
     'DA1-10', ['engine_head_gasket'], 'z.engine',
     'Blok ile kapak arasını sızdırmaz yapar; yağ, su ve yanma gazını '
     'birbirinden ayırır.', {'replace': HEAD_GASKET})
part('engine.head_cover', 'Supap kapağı', 'engine', 'DA1-10',
     ['engine_head_cover'], 'z.engine',
     'Eksantrikleri örter; yağ doldurma kapağı ve PCV valfi üstündedir.',
     {'replace': HEAD_COVER_GASKET})
part('engine.camshafts', 'Eksantrik milleri', 'engine', 'DA1-10',
     ['engine_camshafts'], 'z.engine',
     'Emme ve egzoz supaplarını zamanında açıp kapatır.', quantity=2)
part('engine.pistons', 'Pistonlar', 'engine', 'DA1-10', ['engine_pistons'],
     'z.engine', 'Yanma basıncını biyellere aktarır.',
     {'measure': COMPRESSION}, quantity=4)
part('engine.rods', 'Biyeller', 'engine', 'DA1-10', ['engine_rods'],
     'z.engine', 'Pistonları krank miline bağlar.', quantity=4)
part('engine.crankshaft', 'Krank mili', 'engine', 'DA1-10',
     ['engine_crankshaft'], 'z.engine',
     'Pistonların doğrusal hareketini dönme hareketine çevirir.')
part('engine.timing_chain', 'Triger zinciri', 'engine', 'DA1-20',
     ['engine_timing_chain', 'engine_timing_cover'], 'z.engine',
     'Eksantrik millerini krank miline senkron döndürür.',
     {'inspect': TIMING_CHECK})
part('engine.timing_cover', 'Zincir kapağı ve ön krank keçesi', 'engine',
     'DA1-20', ['engine_timing_cover'], 'z.engine', 'Zinciri örter; '
     'krank mili ucundaki keçe yağı içeride tutar.',
     {'replace': TIMING_COVER_SEAL})
part('engine.drive_belt', 'Aksesuar kayışı', 'engine', 'DA1-20',
     ['engine_crank_pulley', 'alternator', 'ac_compressor'], 'z.engine',
     'Alternatörü, direksiyon pompasını ve klima kompresörünü çeviren '
     'kanallı kayış.', {'replace': DRIVE_BELT})
part('engine.mounts', 'Motor ve şanzıman takozları', 'engine', 'DA1-00',
     ['engine_block', 'transaxle'], 'z.engine',
     'Motoru gövdeye bağlayan, titreşimi sönümleyen lastik takozlar.',
     {'inspect': MOUNTS, 'replace': MOUNT}, quantity=4)
part('engine.oil_pan', 'Karter', 'engine', 'DA1-30', ['engine_oil_pan'],
     'z.engine', 'Motor yağını toplar; boşaltma tapası altındadır.',
     {'lubricate': OIL_CHANGE, 'inspect': OIL_CHECK, 'isolate': OIL_ISO})
part('engine.oil_pump', 'Yağ pompası', 'engine', 'DA1-30',
     ['engine_oil_pump'], 'z.engine',
     'Yağı karterden emip yataklara basınçla gönderir.',
     {'measure': OIL_PRESSURE})
part('engine.oil_filter', 'Yağ filtresi', 'engine', 'DA1-30',
     ['engine_oil_filter'], 'z.engine', 'Yağdaki metal ve is parçalarını '
     'tutar.', {'replace': OIL_CHANGE})
part('engine.oil_pressure_switch', 'Yağ basınç müşiri', 'engine.block',
     'DA1-30', ['engine_block'], 'z.engine', 'Yağ basıncı düşünce '
     'göstergedeki yağ lambasını yakar.', {'replace': OIL_SWITCH})
part('engine.intake', 'Emme manifoldu', 'engine', 'DA1-60',
     ['engine_intake'], 'z.engine', 'Havayı silindirlere dağıtır; gaz '
     'kelebeği gövdesi ve yakıt rampası üstündedir.',
     {'replace': INTAKE_GASKET})
part('engine.exhaust_manifold', 'Egzoz manifoldu', 'engine', 'DA1-60',
     ['engine_exhaust_manifold'], 'z.engine',
     'Silindirlerden çıkan gazları egzoz borusuna toplar.',
     {'inspect': EXHAUST, 'replace': MANIFOLD_GASKET})

# Soğutma
part('cooling', 'Soğutma sistemi', None, 'DA1-40',
     ['radiator', 'radiator_fan', 'radiator_hoses', 'coolant_tank',
      'engine_water_pump'], 'z.front',
     'Motorun ısısını radyatörden havaya atar.',
     {'isolate': OVERHEAT, 'inspect': COOLING_CHECK})
part('cooling.radiator', 'Radyatör', 'cooling', 'DA1-40', ['radiator'],
     'z.front', 'Soğutma suyunu geçen havayla soğutur; fan arkasındadır.',
     {'inspect': COOLING_CHECK, 'replace': RADIATOR})
part('cooling.fan', 'Radyatör fanı', 'cooling', 'DA1-40', ['radiator_fan'],
     'z.front', 'Su ısınınca ya da klima açılınca devreye giren elektrikli '
     'fan.', {'test': FAN_TEST})
part('cooling.hoses', 'Radyatör ve kalorifer hortumları', 'cooling',
     'DA1-40', ['radiator_hoses'], 'z.engine', 'Motoru radyatöre ve '
     'kalorifer peteğine bağlayan lastik hortumlar.',
     {'replace': HOSES})
part('cooling.tank', 'Genleşme kabı', 'cooling', 'DA1-40', ['coolant_tank'],
     'z.engine', 'Isınan soğutma suyunun fazlasını toplar; seviye buradan '
     'okunur.', {'inspect': COOLING_CHECK, 'service': COOLANT_CHANGE})
part('engine.water_pump', 'Su pompası', 'cooling', 'DA1-40',
     ['engine_water_pump'], 'z.engine',
     'Soğutma suyunu motor ile radyatör arasında dolaştırır.',
     {'inspect': COOLING_CHECK, 'replace': WATER_PUMP})
part('cooling.thermostat', 'Termostat', 'engine.water_pump', 'DA1-40',
     ['engine_water_pump'], 'z.engine', 'Su giriş borusunda; 80-84 °C\'de '
     'açılarak suyu radyatöre gönderir.',
     {'replace': THERMOSTAT, 'isolate': COLD_ENGINE})

# Yakıt
part('fuel', 'Yakıt sistemi', None, 'DA1-70', ['fuel_tank', 'engine_intake'],
     'z.under', 'Benzini depodan enjektörlere basınçla ulaştırır.',
     {'isolate': FUEL_ISO})
part('fuel.tank', 'Yakıt deposu', 'fuel', 'DA1-70', ['fuel_tank'],
     'z.under', 'Arka koltuğun altında, yaklaşık 50 litrelik çelik depo.')
part('fuel.pump', 'Yakıt pompası', 'fuel.tank', 'DA1-70', ['fuel_tank'],
     'z.under', 'Depodaki modülün içinde elektrikli pompa.',
     {'replace': FUEL_PUMP, 'measure': FUEL_PRESSURE})
part('fuel.filter', 'Yakıt filtresi', 'fuel.tank', 'DA1-70', ['fuel_tank'],
     'z.under', 'Pompa modülünün içinde; benzindeki kiri tutar.',
     {'replace': FUEL_FILTER})
part('fuel.cap', 'Depo kapağı', 'fuel.tank', 'DA1-70', ['fuel_tank'],
     'z.rear', 'Doldurma ağzını kapatır; contası buhar sızdırmazlığını '
     'sağlar.', {'replace': FUEL_CAP})
part('fuel.injectors', 'Enjektörler ve yakıt rampası', 'fuel', 'DA1-70',
     ['engine_intake'], 'z.engine', 'Emme manifoldunun üstündeki rampaya '
     'bağlı dört elektromanyetik enjektör.', {'replace': INJECTORS},
     quantity=4)

# Emme, egzoz ve emisyon
part('exhaust', 'Emme, egzoz ve emisyon', None, 'DA1-60',
     ['air_filter', 'exhaust_pipe', 'catalytic_converter', 'muffler'],
     'z.under', 'Motorun havasını süzer, egzoz gazını temizleyip aracın '
     'arkasına taşır; yakıt buharını ve karter gazlarını toplar.',
     {'inspect': EXHAUST, 'isolate': EXHAUST_ISO})
part('engine.air_filter', 'Hava filtresi ve emme kanalı', 'exhaust',
     'DA1-60', ['air_filter'], 'z.engine',
     'Motora giren havadaki tozu tutar; kanal havayı gaz kelebeğine '
     'taşır.', {'replace': AIR_FILTER})
part('exhaust.throttle_body', 'Gaz kelebeği gövdesi', 'exhaust', 'DA1-60',
     ['engine_intake'], 'z.engine', 'Gaz pedalıyla açılan kelebek; motora '
     'giren hava miktarını ayarlar.', {'clean': THROTTLE})
part('exhaust.pipe', 'Egzoz ön ve orta borusu', 'exhaust', 'DA1-60',
     ['exhaust_pipe'], 'z.under', 'Manifolddan konvertöre ve susturucuya '
     'giden borular.', {'replace': FRONT_PIPE})
part('exhaust.catalyst', 'Katalitik konvertör', 'exhaust', 'DA1-90',
     ['catalytic_converter'], 'z.under', 'Üç yollu konvertör; ısı kalkanı '
     'altında.', {'replace': CAT})
part('exhaust.muffler', 'Susturucu ve egzoz ucu', 'exhaust', 'DA1-60',
     ['muffler'], 'z.rear', 'Egzoz sesini azaltır; lastik askılarla '
     'gövdeye asılıdır.', {'replace': MUFFLER})
part('exhaust.pcv', 'Karter havalandırma (PCV) valfi', 'exhaust', 'DA1-90',
     ['engine_head_cover'], 'z.engine', 'Supap kapağında; karter gazlarını '
     'emmeye gönderir.', {'replace': PCV})
part('exhaust.evap', 'Yakıt buharı kanisteri ve boşaltma valfi', 'exhaust',
     'DA1-90', ['fuel_tank', 'engine_intake'], 'z.under',
     'Depo buharını aktif karbonda tutup motora çeker.',
     {'inspect': EVAP_CHECK, 'isolate': EMISSION_ISO})

# Ateşleme
part('ignition', 'Ateşleme sistemi', None, 'DA1-50',
     ['engine_coils', 'engine_spark_plugs'], 'z.engine',
     'Her silindirin kendi bobini vardır; ateşleme zamanını motor beyni '
     'belirler.', {'isolate': IGNITION})
part('engine.coils', 'Ateşleme bobinleri', 'ignition', 'DA1-50',
     ['engine_coils'], 'z.engine',
     'Bujiye kıvılcım için gereken yüksek gerilimi üretir.',
     {'isolate': IGNITION, 'replace': COIL}, quantity=4)
part('engine.spark_plugs', 'Bujiler', 'ignition', 'DA1-50',
     ['engine_spark_plugs'], 'z.engine',
     'Silindirdeki yakıt-hava karışımını ateşler.',
     {'replace': PLUGS}, quantity=4)

# Motor yönetimi
part('engine_control', 'Motor yönetimi', None, 'DA1-80',
     ['engine_crank_sensor', 'dashboard', 'air_filter', 'engine_intake',
      'engine_head', 'engine_block', 'engine_exhaust_manifold',
      'exhaust_pipe'], 'z.engine',
     'Motor beyni ve sensörleri: enjeksiyonu, ateşlemeyi ve rölantiyi '
     'yönetir.', {'isolate': MIL_ISO})
part('engine_control.ckp', 'Krank konum sensörü', 'engine_control',
     'DA1-80', ['engine_crank_sensor'], 'z.engine', 'Krank kasnağının '
     'arkasındaki dişli tekerleği okur; motor devrini ve konumunu bildirir.',
     {'measure': POSITION_TEST, 'replace': CKP})
part('engine_control.ecu', 'Motor beyni (ECM)', 'engine_control', 'DA1-80',
     ['dashboard'], 'z.cabin', 'Torpidonun arkasında; arıza kodlarını '
     'saklar.', {'inspect': ECU_CHECK, 'isolate': MIL_ISO})
part('engine_control.maf', 'Hava akış ölçer (MAF)', 'engine_control',
     'DA1-80', ['air_filter'], 'z.engine', 'Hava filtresi kutusunun '
     'çıkışında sıcak telli sensör; emme havası sıcaklığını da ölçer.',
     {'clean': MAF_CLEAN})
part('engine_control.tps', 'Gaz kelebeği konum sensörü (TPS)',
     'engine_control', 'DA1-80', ['engine_intake'], 'z.engine',
     'Kelebek açısını bildirir.', {'replace': TPS})
part('engine_control.iscv', 'Rölanti ayar valfi (ISCV)', 'engine_control',
     'DA1-80', ['engine_intake'], 'z.engine', 'Kelebeği atlayan havayı '
     'ayarlayarak rölanti devrini tutar.',
     {'replace': ISCV, 'isolate': IDLE_ISO})
part('engine_control.ect', 'Su sıcaklık sensörü (ECT)', 'engine_control',
     'DA1-80', ['engine_head'], 'z.engine', 'Silindir kapağının su '
     'çıkışında; soğuk çalıştırma zenginleştirmesini belirler.',
     {'measure': ECT_TEST, 'replace': ECT})
part('engine_control.cmp', 'Eksantrik konum sensörü', 'engine_control',
     'DA1-80', ['engine_head'], 'z.engine', 'Egzoz eksantriğinin ucunda; '
     'hangi silindirin sıkıştırmada olduğunu bildirir.',
     {'measure': POSITION_TEST, 'replace': CMP})
part('engine_control.knock', 'Vuruntu sensörü', 'engine_control', 'DA1-80',
     ['engine_block'], 'z.engine', 'Blokta; vuruntu duyulunca ateşleme '
     'avansı geri alınır.', {'replace': KNOCK})
part('engine_control.o2_front', 'Ön oksijen sensörü', 'engine_control',
     'DA1-80', ['engine_exhaust_manifold'], 'z.engine',
     'Manifoldda, konvertörün önünde; karışımı ölçer.', {'replace': O2})

# Elektrik
part('electrical', 'Elektrik sistemi', None, 'DA6-00',
     ['battery', 'alternator', 'starter', 'instrument_cluster'], 'z.engine',
     '12 V akü, şarj ve marş sistemi, sigortalar, kablo demeti ve gösterge '
     'paneli.', {'isolate': FUSE_ISO})
part('battery', 'Akü', 'electrical', 'DA6-10', ['battery'], 'z.engine',
     'Marş için gereken akımı ve motor dururken elektriği sağlar.',
     {'inspect': BATTERY_CHECK, 'replace': BATTERY})
part('electrical.fuses', 'Sigorta ve röle kutuları', 'electrical', 'DA6-60',
     ['battery'], 'z.engine', 'Motor bölmesindeki ana kutu akünün '
     'yanındadır; iç kutu gösterge panelinin altındadır.',
     {'inspect': FUSE_CHECK})
part('electrical.alternator', 'Alternatör', 'electrical', 'DA6-30',
     ['alternator'], 'z.engine', 'Motor çalışırken aküyü şarj eder; 80 A.',
     {'isolate': CHARGING_ISO, 'test': CHARGING_TEST,
      'replace': ALTERNATOR})
part('electrical.starter', 'Marş motoru', 'electrical', 'DA6-40',
     ['starter'], 'z.engine', 'Şanzıman çanına bağlı; otomatiği dişliyi '
     'volana iter.', {'isolate': STARTING_ISO, 'replace': STARTER})
part('electrical.ignition_switch', 'Kontak anahtarı ve marş rölesi',
     'electrical', 'DA6-40', ['steering_wheel', 'dashboard'], 'z.cabin',
     'Direksiyon kolonunda; marş rölesi iç sigorta kutusundadır.',
     {'replace': IGN_SWITCH})
part('electrical.cluster', 'Gösterge paneli (kadran)', 'electrical',
     'DA6-50', ['instrument_cluster'], 'z.cabin', 'Hız ve devir '
     'göstergesi, yakıt ve hararet göstergeleri, uyarı lambaları.',
     {'replace': CLUSTER})
part('electrical.wiring', 'Kablo demeti ve toprak bağlantıları',
     'electrical', 'DA6-60', ['body', 'dashboard'], 'z.cabin',
     'Bütün devreleri birbirine bağlayan demet ve gövde toprak noktaları.',
     {'clean': GROUND, 'inspect': FUSE_CHECK})
part('electrical.horn', 'Korna', 'electrical', 'DA6-80', ['bumper_front'],
     'z.front', 'Ön tamponun arkasında, radyatör traversinde.',
     {'replace': HORN})

# Aydınlatma
part('lighting', 'Aydınlatma ve sinyal', None, 'DA6-20',
     ['headlight_l', 'headlight_r', 'foglight_l', 'foglight_r',
      'taillight_l', 'taillight_r'], 'z.front',
     'Farlar, sis lambaları, arka lambalar, sinyaller ve stop lambaları.',
     {'isolate': LIGHTS_ISO})
part('body.headlights', 'Farlar', 'lighting', 'DA6-20',
     ['headlight_l', 'headlight_r'], 'z.front',
     'Kısa ve uzun far (H4), köşede ön sinyal.', {'replace': HEADLIGHT},
     quantity=2)
part('lighting.foglights', 'Sis lambaları', 'lighting', 'DA6-20',
     ['foglight_l', 'foglight_r'], 'z.front', 'Ön tamponun köşelerinde, '
     'sarı camlı H3 lambalar.', {'replace': FOG_BULB}, quantity=2)
part('body.taillights', 'Arka lambalar', 'lighting', 'DA6-20',
     ['taillight_l', 'taillight_r'], 'z.rear',
     'Stop, park, sinyal ve geri vites lambası.', {'replace': TAIL_BULB},
     quantity=2)
part('lighting.brake_switch', 'Stop lambası müşiri', 'lighting', 'DA6-20',
     ['pedals'], 'z.cabin', 'Fren pedalının üstünde; pedala basınca stop '
     'lambalarını yakar.', {'adjust': BRAKE_SWITCH})
part('lighting.flasher', 'Sinyal rölesi (flaşör)', 'lighting', 'DA6-20',
     ['dashboard'], 'z.cabin', 'Gösterge panelinin altındaki röle '
     'bloğunda; sinyalleri ve dörtlüleri çaktırır.',
     {'replace': FLASHER})

# Isıtma ve klima
part('hvac', 'Isıtma ve klima', None, 'DA7-00',
     ['ac_compressor', 'ac_condenser', 'dashboard'], 'z.cabin',
     'Kalorifer, havalandırma ve klima.', {'isolate': HEATER_ISO})
part('hvac.compressor', 'Klima kompresörü', 'hvac', 'DA7-20',
     ['ac_compressor'], 'z.engine', 'Kayışla dönen, elektromanyetik '
     'kavramalı pistonlu kompresör.',
     {'replace': COMPRESSOR, 'isolate': AC_ISO})
part('hvac.condenser', 'Klima kondenseri', 'hvac', 'DA7-20',
     ['ac_condenser'], 'z.front', 'Radyatörün önünde; akışkanın ısısını '
     'havaya atar.', {'inspect': AC_CHECK, 'isolate': AC_ISO})
part('hvac.blower', 'Kalorifer fanı', 'hvac', 'DA7-10', ['dashboard'],
     'z.cabin', 'Yolcu tarafında torpidonun altında; dört kademeli, '
     'dirençle ayarlanır.', {'replace': BLOWER, 'isolate': HEATER_ISO})
part('hvac.heater_core', 'Kalorifer peteği', 'hvac', 'DA7-10',
     ['dashboard'], 'z.cabin', 'Kalorifer kutusunun içinde; motor suyu '
     'geçer.', {'replace': HEATER_CORE})

# Güç aktarma
part('drivetrain', 'Güç aktarma', None, 'DA2-00',
     ['transaxle', 'driveshaft_front'], 'z.engine',
     'Motorun gücünü ön tekerleklere iletir.')
part('drivetrain.transaxle', 'Şanzıman', 'drivetrain', 'DA2-10',
     ['transaxle'], 'z.engine',
     'Beş ileri manuel şanzıman ve diferansiyel tek gövdede.',
     {'inspect': GEARBOX, 'isolate': CLUTCH})
part('drivetrain.clutch', 'Debriyaj', 'drivetrain.transaxle', 'DA2-10',
     ['transaxle'], 'z.engine',
     'Vites değiştirirken motoru şanzımandan ayırır.',
     {'isolate': CLUTCH, 'replace': CLUTCH_SET})
part('drivetrain.clutch_hydraulics', 'Debriyaj ana ve tali merkezi',
     'drivetrain', 'DA2-10', ['pedals', 'transaxle'], 'z.engine',
     'Pedal kuvvetini hidrolikle şanzımandaki debriyaj çatalına iletir; '
     'fren hidroliğiyle çalışır.', {'adjust': CLUTCH_BLEED})
part('drivetrain.shift_linkage', 'Vites kolu ve kumanda telleri',
     'drivetrain', 'DA2-10', ['interior_trim', 'transaxle'], 'z.cabin',
     'Vites kolunun hareketini iki telle şanzımana iletir.',
     {'adjust': LINKAGE})
part('drivetrain.driveshafts', 'Aks milleri', 'drivetrain', 'DA2-20',
     ['driveshaft_front'], 'z.front',
     'Diferansiyelden ön tekerleklere gücü aks kafalarıyla (homokinetik '
     'mafsal) iletir.',
     {'inspect': DRIVESHAFT, 'replace': CV_BOOT}, quantity=2)

# Fren
part('brakes', 'Fren sistemi', None, 'DA3-00',
     ['brake_caliper_front', 'brake_disc_front', 'brake_caliper_rear',
      'brake_disc_rear', 'brake_booster'], 'z.front',
     'Aracı yavaşlatır ve durdurur.', {'isolate': BRAKE_ISOLATE})
part('brakes.front', 'Ön frenler', 'brakes', 'DA3-10',
     ['brake_caliper_front', 'brake_disc_front'], 'z.front',
     'Disk, kaliper ve balatalar.',
     {'isolate': BRAKE_ISOLATE, 'measure': DISCS}, quantity=2)
part('brakes.front.calipers', 'Ön kaliperler', 'brakes.front', 'DA3-10',
     ['brake_caliper_front'], 'z.front', 'Tek pistonlu yüzer kaliper.',
     {'replace': CALIPER}, quantity=2)
part('brakes.front.pads', 'Ön balatalar', 'brakes.front.calipers', 'DA3-10',
     ['brake_caliper_front'], 'z.front', 'Diske sürtünerek frenleme yapar.',
     {'replace': PADS}, quantity=2)
part('brakes.front.discs', 'Ön fren diskleri', 'brakes.front', 'DA3-10',
     ['brake_disc_front'], 'z.front', 'Tekerlekle dönen, havalandırmalı disk.',
     {'measure': DISCS, 'replace': DISC_REPLACE})
part('brakes.rear', 'Arka frenler', 'brakes', 'DA3-20',
     ['brake_caliper_rear', 'brake_disc_rear'], 'z.rear',
     'Arka disk frenler; el freni kaliperlere tel ile kumanda eder.',
     {'inspect': REAR_BRAKES}, quantity=2)
part('brakes.rear.pads', 'Arka kaliperler ve balatalar', 'brakes.rear',
     'DA3-20', ['brake_caliper_rear'], 'z.rear', 'El freni mekanizmalı tek '
     'pistonlu kaliper ve balataları.', {'replace': REAR_PADS,
                                         'inspect': REAR_BRAKES},
     quantity=2)
part('brakes.booster', 'Fren servosu', 'brakes', 'DA3-30',
     ['brake_booster'], 'z.engine',
     'Motor vakumuyla pedal kuvvetini artırır; ana merkez önündedir.',
     {'inspect': BOOSTER})
part('brakes.master_cylinder', 'Fren ana merkezi ve deposu',
     'brakes.booster', 'DA3-30', ['brake_booster'], 'z.engine',
     'Çift devreli ana merkez; depo debriyajla ortaktır.',
     {'replace': MASTER, 'service': BRAKE_BLEED})
part('brakes.lines', 'Fren boruları ve hortumları', 'brakes', 'DA3-30',
     ['brake_caliper_front', 'brake_caliper_rear'], 'z.under',
     'Hidroliği ana merkezden kaliperlere taşır; tekerleklerde esnek '
     'hortumlar.', {'service': BRAKE_BLEED})
part('brakes.parking', 'El freni', 'brakes', 'DA3-40',
     ['brake_caliper_rear', 'interior_trim'], 'z.cabin',
     'Orta konsoldaki kol ve arka kaliperlere giden teller.',
     {'adjust': PARKING})

# Süspansiyon ve direksiyon
part('chassis', 'Süspansiyon ve direksiyon', None, 'DA4-00',
     ['subframe_front', 'strut_front', 'control_arm_front', 'hub_front',
      'strut_rear', 'arms_rear', 'stabilizer_rear', 'subframe_rear',
      'hub_rear', 'steering_rack', 'steering_wheel', 'ps_reservoir'],
     'z.front',
     'Tekerlekleri gövdeye bağlar, yoldan gelen darbeleri sönümler ve '
     'aracı yönlendirir.', {'isolate': SUSPENSION_ISOLATE})
part('chassis.strut_front', 'Ön amortisörler', 'chassis', 'DA4-10',
     ['strut_front'], 'z.front',
     'MacPherson amortisör ve helezon yay; tekerleği taşır ve sönümler.',
     {'inspect': SUSPENSION_CHECK, 'replace': STRUT}, quantity=2)
part('chassis.control_arm', 'Ön salıncaklar ve rotiller', 'chassis',
     'DA4-10', ['control_arm_front'], 'z.front',
     'Aks taşıyıcısını traverse bağlar; ucundaki rotil aks taşıyıcısının '
     'dönmesine izin verir.',
     {'inspect': SUSPENSION_CHECK, 'replace': BALL_JOINT}, quantity=2)
part('chassis.stabilizer_front', 'Ön travers ve viraj demiri', 'chassis',
     'DA4-10', ['subframe_front'], 'z.under', 'Motorun altındaki travers '
     'salıncakları ve direksiyon kutusunu taşır; viraj demiri virajda '
     'gövdenin yatmasını azaltır.', {'replace': STAB_LINK})
part('chassis.wheel_bearing_front', 'Ön göbekler ve tekerlek rulmanları',
     'chassis', 'DA5-20', ['hub_front'], 'z.front', 'Aks taşıyıcısı, göbek '
     've taşıyıcıya preslenmiş çift sıra bilyalı rulman.',
     {'replace': BEARING}, quantity=2)
part('chassis.suspension_rear', 'Arka süspansiyon', 'chassis', 'DA4-20',
     ['strut_rear', 'arms_rear', 'stabilizer_rear', 'subframe_rear',
      'hub_rear'], 'z.rear',
     'Arka amortisörler, salıncaklar, çeki kolları ve viraj demiri.',
     {'inspect': REAR_SUSPENSION})
part('chassis.strut_rear', 'Arka amortisörler', 'chassis.suspension_rear',
     'DA4-20', ['strut_rear'], 'z.rear', 'MacPherson tipi arka amortisör '
     've yay.', {'inspect': REAR_SUSPENSION, 'replace': REAR_STRUT},
     quantity=2)
part('chassis.arms_rear', 'Arka salıncaklar ve çeki kolları',
     'chassis.suspension_rear', 'DA4-20', ['arms_rear'], 'z.rear',
     'Çift alt salıncak ve çeki kolu; arka toplamayı belirler.',
     {'inspect': REAR_SUSPENSION})
part('chassis.wheel_bearing_rear', 'Arka göbekler ve tekerlek rulmanları',
     'chassis.suspension_rear', 'DA5-20', ['hub_rear'], 'z.rear',
     'Arka aks taşıyıcısı ve onunla bütün halde değişen göbek-rulman.',
     {'replace': BEARING_REAR}, quantity=2)
part('chassis.steering_rack', 'Direksiyon kutusu', 'chassis', 'DA4-30',
     ['steering_rack'], 'z.front',
     'Kremayer dişliyle direksiyon dönüşünü tekerleklere iletir.',
     {'adjust': ALIGNMENT})
part('chassis.tie_rods', 'Rot milleri ve rot başları',
     'chassis.steering_rack', 'DA4-30', ['steering_rack'], 'z.front',
     'Direksiyon kutusunu aks taşıyıcılarına bağlar; toplama buradan '
     'ayarlanır.', {'replace': TIE_ROD}, quantity=2)
part('chassis.steering_wheel', 'Direksiyon simidi ve kolonu', 'chassis',
     'DA4-30', ['steering_wheel'], 'z.cabin',
     'Sürücünün aracı yönlendirdiği simit; kolon kontak anahtarını taşır.')
part('chassis.power_steering', 'Hidrolik direksiyon pompası ve deposu',
     'chassis', 'DA4-30', ['ps_reservoir'], 'z.engine',
     'Kayışla dönen pompa ve motor bölmesinin sağ arkasındaki yağ deposu. '
     'Seçilince depo vurgulanır.',
     {'inspect': PS_CHECK, 'replace': PS_PUMP, 'isolate': STEERING_ISO})

# Tekerlekler
part('wheels', 'Tekerlekler', None, 'DA5-00', WHEEL_NODES, 'z.under',
     'Dört tekerlek: 175/65 R14 lastik, çelik jant ve göbek kapağı.',
     {'inspect': TIRES, 'replace': WHEEL}, quantity=4)
part('wheels.tires', 'Lastikler', 'wheels', 'DA5-10', WHEEL_NODES,
     'z.under', '175/65 R14 lastikler; basınç ön ve arka 2,2 bar.',
     {'inspect': TIRES, 'adjust': BALANCE}, quantity=4)

ZONES = [
    ('z.front', 'Ön', None), ('z.engine', 'Motor bölmesi', 'z.front'),
    ('z.cabin', 'Kabin', None), ('z.rear', 'Arka', None),
    ('z.under', 'Araç altı', None),
]

# --- Arızalar ---------------------------------------------------------------

SYMPTOMS = [
    # Motor
    ('sym.no_start', 'Motor çalışmıyor ya da marş basmıyor'),
    ('sym.slow_crank', 'Marş ağır dönüyor'),
    ('sym.click_no_crank', 'Marşa basınca yalnız tık sesi geliyor'),
    ('sym.cranks_no_start', 'Marş dönüyor ama motor ateş almıyor'),
    ('sym.hard_start_hot', 'Motor sıcakken zor çalışıyor'),
    ('sym.hard_start_cold', 'Motor soğukken zor çalışıyor'),
    ('sym.stall', 'Motor seyir halinde ya da durunca stop ediyor'),
    ('sym.misfire', 'Motor tekliyor ya da rölantide titriyor'),
    ('sym.rough_idle', 'Rölanti devri dalgalı, çok yüksek ya da çok düşük'),
    ('sym.power_loss', 'Motor çekmiyor, hızlanmıyor'),
    ('sym.hesitation', 'Gaza basınca motor bir an duraksıyor'),
    ('sym.fuel_consumption', 'Yakıt tüketimi arttı'),
    ('sym.mil', 'Motor arıza lambası yanıyor'),
    ('sym.fuel_smell', 'Benzin kokusu geliyor'),
    ('sym.black_smoke', 'Egzozdan siyah duman çıkıyor'),
    ('sym.white_smoke', 'Egzozdan beyaz duman çıkıyor'),
    ('sym.blue_smoke', 'Egzozdan mavi duman çıkıyor, motor yağ eksiltiyor'),
    ('sym.engine_rattle', 'Soğuk çalıştırmada motordan şıkırtı geliyor'),
    ('sym.valve_tick', 'Motorun üstünden devirle hızlanan tıkırtı geliyor'),
    ('sym.engine_vibration', 'Motor rölantide gövdeyi titretiyor; vites '
     'değiştirirken vuruyor'),
    ('sym.belt_squeal', 'Motorun önünden kayış ötmesi geliyor'),
    ('sym.oil_light', 'Yağ lambası yanıyor'),
    ('sym.oil_leak', 'Aracın altına yağ damlıyor'),
    ('sym.burning_oil_smell', 'Kaputun altından yanık yağ kokusu geliyor'),
    # Soğutma
    ('sym.overheat', 'Hararet göstergesi yükseliyor'),
    ('sym.overheat_idle', 'Trafikte ve rölantide hararet yapıyor, yolda '
     'düzeliyor'),
    ('sym.coolant_loss', 'Soğutma suyu eksiliyor'),
    ('sym.slow_warmup', 'Motor geç ısınıyor, hararet göstergesi düşük '
     'kalıyor'),
    ('sym.heater_cold', 'Kalorifer ısıtmıyor'),
    # Egzoz
    ('sym.exhaust_noise', 'Egzozdan yüksek ya da üfleme sesi geliyor'),
    ('sym.manifold_tick', 'Soğukken motordan ısınınca azalan tik tik sesi '
     'geliyor'),
    ('sym.rotten_egg', 'Egzozdan çürük yumurta kokusu geliyor'),
    ('sym.underbody_rattle', 'Aracın altından tıngırtı geliyor'),
    # Güç aktarma
    ('sym.clutch_slip', 'Gaza basınca devir yükseliyor ama araç hızlanmıyor'),
    ('sym.clutch_pedal', 'Debriyaj pedalı yere iniyor ya da süngerimsi'),
    ('sym.hard_shift', 'Vites zor geçiyor ya da cızırdıyor'),
    ('sym.vague_shift', 'Vites kolu boşluklu, vitesler belirsiz'),
    ('sym.turn_click', 'Direksiyon kırıkken önden tıkırtı geliyor'),
    # Fren
    ('sym.brake_weak', 'Fren yeterince tutmuyor'),
    ('sym.brake_noise', 'Frenlerken ciyaklama ya da sürtme sesi geliyor'),
    ('sym.brake_pulse', 'Frenlerken pedal ve direksiyon titriyor'),
    ('sym.pedal_hard', 'Fren pedalı çok sert'),
    ('sym.pedal_soft', 'Fren pedalı yumuşak ya da yavaşça yere iniyor'),
    ('sym.brake_pull', 'Frenlerken araç bir yana çekiyor'),
    ('sym.hot_wheel', 'Bir tekerlek aşırı ısınıyor, yanık kokusu geliyor'),
    ('sym.handbrake', 'El freni tutmuyor ya da kol çok yukarı çıkıyor'),
    ('sym.brake_fluid_low', 'Fren hidroliği eksiliyor'),
    # Süspansiyon, direksiyon, tekerlek
    ('sym.bounce', 'Araç tümseklerde fazla zıplıyor'),
    ('sym.knock', 'Tümseklerde önden vuruntu sesi geliyor'),
    ('sym.rear_knock', 'Tümseklerde arkadan vuruntu sesi geliyor'),
    ('sym.rattle_bumps', 'Bozuk yolda önden takırtı geliyor'),
    ('sym.pull', 'Araç bir yana çekiyor'),
    ('sym.wander', 'Direksiyon boşluklu, araç yolda yalpalıyor'),
    ('sym.tire_wear', 'Lastikler bir kenarından aşınıyor'),
    ('sym.flat', 'Lastik iniyor'),
    ('sym.vibration', 'Belli bir hızda direksiyon titriyor'),
    ('sym.wheel_hum', 'Tekerlekten hızla artan uğultu geliyor'),
    ('sym.heavy_steering', 'Direksiyon ağır dönüyor'),
    ('sym.steering_whine', 'Direksiyon çevrilirken inilti geliyor'),
    # Elektrik ve aydınlatma
    ('sym.dim_lights', 'Farlar sönük yanıyor'),
    ('sym.battery_light', 'Şarj lambası yanıyor'),
    ('sym.battery_drain', 'Akü sık sık boşalıyor'),
    ('sym.bulbs_blow', 'Ampuller sık sık yanıyor'),
    ('sym.headlight_out', 'Farlardan biri yanmıyor'),
    ('sym.brake_light', 'Stop lambaları yanmıyor ya da sürekli yanıyor'),
    ('sym.turn_fast', 'Sinyal hızlı çakıyor ya da hiç çakmıyor'),
    ('sym.fog_out', 'Sis lambası yanmıyor ya da içine su girmiş'),
    ('sym.circuit_dead', 'Bir elektrikli donanım hiç çalışmıyor'),
    ('sym.intermittent', 'Elektrikli donanımlar ara sıra kesiliyor'),
    ('sym.horn', 'Korna çalmıyor'),
    ('sym.gauges', 'Göstergeler çalışmıyor ya da yanlış gösteriyor'),
    ('sym.window', 'Elektrikli cam inip kalkmıyor ya da yavaş gidiyor'),
    ('sym.door_lock', 'Kapı merkezi kilitle kilitlenmiyor'),
    # Gövde ve kabin
    ('sym.wiper_streak', 'Silecekler camda iz bırakıyor'),
    ('sym.wiper_dead', 'Silecekler çalışmıyor ya da yerine dönmüyor'),
    ('sym.washer', 'Cam suyu fışkırmıyor'),
    ('sym.water_leak', 'Kapı kenarından içeri su giriyor'),
    ('sym.windshield_crack', 'Ön camda çatlak ya da taş izi var'),
    ('sym.hood', 'Kaput açılmıyor ya da tam kapanmıyor'),
    ('sym.mirror', 'Dış ayna camı kırık ya da gevşek'),
    ('sym.rust', 'Kapı altlarında ve davlumbazlarda pas var'),
    ('sym.belt', 'Emniyet kemeri sarmıyor ya da kilitlenmiyor'),
    ('sym.seat', 'Sürücü koltuğu kaymıyor ya da kilitlenmiyor'),
    ('sym.srs', 'SRS lambası yanık kalıyor'),
    # Isıtma ve klima
    ('sym.ac_warm', 'Klima soğutmuyor'),
    ('sym.ac_noise', 'Klima açılınca motordan ses geliyor'),
    ('sym.blower', 'Kalorifer fanı çalışmıyor ya da yalnız en yüksek '
     'kademede çalışıyor'),
    ('sym.fogging', 'Camlar buğulanıyor, içeride tatlı bir koku var'),
]

# (id, parça, belirtiler, neden, önem 1-3, arıza bulma, onarım)
FAULTS = [
    # Motor
    ('f.head_gasket.blown', 'engine.head_gasket',
     ['sym.overheat', 'sym.white_smoke', 'sym.coolant_loss'],
     'Silindir kapak contası yanmış; soğutma suyu yanma odasına giriyor.',
     3, COMPRESSION, HEAD_GASKET),
    ('f.pistons.rings_worn', 'engine.pistons', ['sym.power_loss',
                                                'sym.blue_smoke'],
     'Segmanlar aşınmış; kompresyon düşük, motor yağ yakıyor.', 2,
     COMPRESSION, None),
    ('f.timing_chain.stretched', 'engine.timing_chain',
     ['sym.engine_rattle', 'sym.power_loss'],
     'Triger zinciri uzamış ya da gergisi yağ basıncını tutamıyor. '
     'Zincir atlarsa supaplar pistonlara çarpar.', 3,
     TIMING_CHECK, None),
    ('f.valves.clearance', 'engine.valves',
     ['sym.valve_tick', 'sym.rough_idle'],
     'Supap boşluğu açılmış ya da kapanmış; supap ya tıkırdıyor ya da tam '
     'kapanmıyor.', 2, ENGINE_NOISE, VALVES),
    ('f.head_cover.gasket', 'engine.head_cover',
     ['sym.oil_leak', 'sym.burning_oil_smell'],
     'Supap kapağı contası sertleşmiş; yağ egzoz manifolduna damlıyor.', 1,
     OIL_ISO, HEAD_COVER_GASKET),
    ('f.crank_seal.leak', 'engine.timing_cover', ['sym.oil_leak'],
     'Ön krank keçesi sızdırıyor; yağ kasnağın arkasından damlıyor.', 2,
     OIL_ISO, TIMING_COVER_SEAL),
    ('f.mounts.worn', 'engine.mounts', ['sym.engine_vibration'],
     'Motor takozunun lastiği yırtılmış.', 1, ENGINE_NOISE, MOUNT),
    ('f.drive_belt.worn', 'engine.drive_belt',
     ['sym.belt_squeal', 'sym.battery_light'],
     'Aksesuar kayışı gevşemiş ya da kanalları çatlamış.', 2, CHARGING_ISO,
     DRIVE_BELT),
    ('f.oil.low', 'engine.oil_pan', ['sym.oil_light', 'sym.oil_leak',
                                     'sym.engine_rattle'],
     'Motor yağı eksik ya da yağ değişimi gecikmiş; karter tapasından ya '
     'da contasından sızıntı olabilir.', 3, OIL_CHECK, OIL_CHANGE),
    ('f.oil_pump.worn', 'engine.oil_pump', ['sym.oil_light',
                                            'sym.engine_rattle'],
     'Yağ pompası aşınmış ya da emiş süzgeci tıkanmış; yağ basıncı düşük.',
     3, OIL_ISO, OIL_PRESSURE),
    ('f.oil_switch.faulty', 'engine.oil_pressure_switch', ['sym.oil_light'],
     'Yağ basınç müşiri arızalı; basınç yeterliyken lamba yanıyor.', 1,
     OIL_ISO, OIL_SWITCH),
    ('f.intake.gasket', 'engine.intake', ['sym.rough_idle', 'sym.mil'],
     'Emme manifoldu contası hava kaçırıyor; karışım fakirleşiyor.', 2,
     IDLE_ISO, INTAKE_GASKET),
    ('f.exhaust_manifold.leak', 'engine.exhaust_manifold',
     ['sym.manifold_tick', 'sym.exhaust_noise'],
     'Egzoz manifoldu contası üflüyor ya da manifold çatlamış.', 1,
     EXHAUST_ISO, MANIFOLD_GASKET),
    # Soğutma
    ('f.water_pump.leak', 'engine.water_pump', ['sym.coolant_loss',
                                                'sym.overheat'],
     'Su pompası keçesi sızdırıyor.', 2, OVERHEAT, WATER_PUMP),
    ('f.radiator.clogged', 'cooling.radiator', ['sym.overheat'],
     'Radyatör petekleri içeriden tortuyla ya da dışarıdan kirle tıkanmış.',
     2, OVERHEAT, RADIATOR),
    ('f.radiator_cap.faulty', 'cooling.radiator',
     ['sym.coolant_loss', 'sym.overheat'],
     'Radyatör kapağı basınç tutmuyor; su kaynayıp genleşme kabından '
     'taşıyor.', 2, OVERHEAT, COOLANT_PRESSURE),
    ('f.fan.inoperative', 'cooling.fan', ['sym.overheat_idle'],
     'Radyatör fanı, rölesi ya da fan müşiri arızalı; fan devreye '
     'girmiyor.', 2, OVERHEAT, FAN_TEST),
    ('f.hoses.cracked', 'cooling.hoses', ['sym.coolant_loss',
                                          'sym.overheat'],
     'Radyatör hortumu çatlamış ya da kelepçesi gevşemiş.', 2, OVERHEAT,
     HOSES),
    ('f.thermostat.stuck_open', 'cooling.thermostat',
     ['sym.slow_warmup', 'sym.heater_cold', 'sym.fuel_consumption'],
     'Termostat açık kalmış; motor çalışma sıcaklığına gelmiyor.', 1,
     COLD_ENGINE, THERMOSTAT),
    ('f.thermostat.stuck_closed', 'cooling.thermostat', ['sym.overheat'],
     'Termostat kapalı kalmış; su radyatöre gitmiyor.', 3, OVERHEAT,
     THERMOSTAT),
    # Yakıt
    ('f.fuel_pump.failed', 'fuel.pump',
     ['sym.cranks_no_start', 'sym.stall'],
     'Yakıt pompası çalışmıyor ya da basınç veremiyor.', 3, FUEL_ISO,
     FUEL_PUMP),
    ('f.fuel_filter.clogged', 'fuel.filter',
     ['sym.power_loss', 'sym.hesitation'],
     'Yakıt filtresi tıkanmış; yükte yeterli yakıt gelmiyor.', 2, FUEL_ISO,
     FUEL_FILTER),
    ('f.fuel_regulator.faulty', 'fuel.pump',
     ['sym.hard_start_hot', 'sym.black_smoke'],
     'Pompa modülündeki basınç regülatörü basıncı tutamıyor.', 2, FUEL_ISO, FUEL_PRESSURE),
    ('f.injectors.clogged', 'fuel.injectors',
     ['sym.misfire', 'sym.rough_idle', 'sym.hard_start_hot'],
     'Bir enjektör tıkanmış ya da damlatıyor.', 2, IGNITION, INJECTORS),
    ('f.fuel_cap.seal', 'fuel.cap', ['sym.mil', 'sym.fuel_smell'],
     'Depo kapağının contası sızdırıyor; EVAP sistemi kaçak algılıyor.', 1,
     EMISSION_ISO, FUEL_CAP),
    # Emme, egzoz ve emisyon
    ('f.air_filter.clogged', 'engine.air_filter', ['sym.power_loss',
                                                   'sym.fuel_consumption'],
     'Hava filtresi tıkanmış; motor yeterince hava alamıyor.', 1,
     IGNITION, AIR_FILTER),
    ('f.throttle.dirty', 'exhaust.throttle_body', ['sym.rough_idle',
                                                   'sym.stall'],
     'Gaz kelebeğinin kenarında karbon birikmiş; rölantide hava yetmiyor.',
     1, IDLE_ISO, THROTTLE),
    ('f.exhaust.leak', 'exhaust.muffler', ['sym.exhaust_noise'],
     'Susturucu delinmiş ya da askısı kopmuş.', 1, EXHAUST_ISO, MUFFLER),
    ('f.front_pipe.gasket', 'exhaust.pipe', ['sym.exhaust_noise'],
     'Ön boru flanş contası üflüyor.', 1, EXHAUST_ISO, FRONT_PIPE),
    ('f.catalyst.clogged', 'exhaust.catalyst',
     ['sym.power_loss', 'sym.rotten_egg', 'sym.underbody_rattle'],
     'Katalitik konvertörün içi dağılmış ya da erimiş; egzoz tıkanıyor.', 2,
     EXHAUST_ISO, CAT),
    ('f.pcv.clogged', 'exhaust.pcv', ['sym.oil_leak', 'sym.rough_idle'],
     'PCV valfi tıkanmış; karter basıncı yükseliyor ve keçeler '
     'sızdırıyor.', 1, OIL_ISO, PCV),
    ('f.evap.purge', 'exhaust.evap', ['sym.mil', 'sym.fuel_smell'],
     'EVAP boşaltma valfi açık kalmış ya da kanister hortumu çatlak.', 1,
     EMISSION_ISO, EVAP_CHECK),
    # Ateşleme
    ('f.plugs.worn', 'engine.spark_plugs', ['sym.misfire', 'sym.power_loss',
                                            'sym.hard_start_cold'],
     'Bujilerin elektrotları aşınmış ya da islenmiş; kıvılcım zayıf.', 1,
     IGNITION, PLUGS),
    ('f.coils.failed', 'engine.coils', ['sym.misfire', 'sym.mil'],
     'Bir ateşleme bobini arızalı; o silindir çalışmıyor.', 2, IGNITION,
     COIL),
    # Motor yönetimi
    ('f.maf.dirty', 'engine_control.maf',
     ['sym.hesitation', 'sym.stall', 'sym.mil'],
     'Hava akış ölçerin teli kirlenmiş; motor beyni havayı eksik ölçüyor.',
     2, MIL_ISO, MAF_CLEAN),
    ('f.o2.failed', 'engine_control.o2_front',
     ['sym.fuel_consumption', 'sym.mil', 'sym.black_smoke'],
     'Ön oksijen sensörü yaşlanmış; karışım düzeltmesi yapılamıyor.', 1,
     MIL_ISO, O2),
    ('f.ect.failed', 'engine_control.ect',
     ['sym.hard_start_cold', 'sym.black_smoke', 'sym.gauges'],
     'Su sıcaklık sensörü yanlış değer veriyor; motor beyni karışımı yanlış '
     'hesaplıyor.', 2, MIL_ISO, ECT),
    ('f.ckp.failed', 'engine_control.ckp',
     ['sym.cranks_no_start', 'sym.stall'],
     'Krank konum sensörü arızalı; motor ısınınca stop ediyor ya da hiç '
     'kıvılcım yok.', 3, ENGINE_ISOLATE, CKP),
    ('f.cmp.failed', 'engine_control.cmp', ['sym.mil', 'sym.hard_start_hot'],
     'Eksantrik konum sensörü arızalı; marş uzun basıyor.', 2, MIL_ISO,
     CMP),
    ('f.tps.failed', 'engine_control.tps', ['sym.hesitation',
                                            'sym.rough_idle'],
     'Gaz kelebeği konum sensörünün izi aşınmış; sinyal atlıyor.', 2,
     MIL_ISO, TPS),
    ('f.iscv.sticking', 'engine_control.iscv', ['sym.rough_idle',
                                                'sym.stall'],
     'Rölanti ayar valfi karbonla sıkışmış.', 2, IDLE_ISO, ISCV),
    ('f.knock.failed', 'engine_control.knock', ['sym.mil',
                                                'sym.power_loss'],
     'Vuruntu sensörü arızalı; motor beyni avansı güvenlik için geri '
     'alıyor.', 1, MIL_ISO, KNOCK),
    ('f.ecu.power', 'engine_control.ecu', ['sym.no_start', 'sym.mil'],
     'Motor beyninin beslemesi ya da toprağı kesik.', 3, MIL_ISO, ECU_CHECK),
    # Elektrik
    ('f.battery.flat', 'battery', ['sym.no_start', 'sym.slow_crank',
                                   'sym.dim_lights'],
     'Akü boşalmış ya da ömrünü doldurmuş.', 2, BATTERY_CHECK, BATTERY),
    ('f.alternator.failed', 'electrical.alternator',
     ['sym.battery_light', 'sym.dim_lights', 'sym.battery_drain',
      'sym.bulbs_blow'],
     'Alternatör şarj etmiyor (kömür ya da diyot arızası) ya da içindeki '
     'regülatör aşırı şarj ediyor.', 3,
     CHARGING_ISO, ALTERNATOR),
    ('f.starter.failed', 'electrical.starter',
     ['sym.click_no_crank', 'sym.no_start'],
     'Marş motorunun otomatiği ya da kömürleri aşınmış.', 2, STARTING_ISO,
     STARTER),
    ('f.ignition_switch.faulty', 'electrical.ignition_switch',
     ['sym.no_start', 'sym.intermittent'],
     'Kontak anahtarının elektrik bloğu ya da marş rölesi arızalı.', 2,
     STARTING_ISO, IGN_SWITCH),
    ('f.fuse.blown', 'electrical.fuses', ['sym.circuit_dead'],
     'Devrenin sigortası atmış ya da rölesi arızalı.', 1, FUSE_ISO,
     FUSE_CHECK),
    ('f.ground.corroded', 'electrical.wiring',
     ['sym.intermittent', 'sym.dim_lights', 'sym.slow_crank'],
     'Toprak bağlantısı oksitlenmiş ya da gevşemiş.', 2, FUSE_ISO, GROUND),
    ('f.horn.failed', 'electrical.horn', ['sym.horn'],
     'Korna, korna rölesi ya da direksiyondaki kontak arızalı.', 1,
     FUSE_ISO, HORN),
    ('f.cluster.failed', 'electrical.cluster', ['sym.gauges'],
     'Gösterge panelinin baskılı devresinde lehim çatlamış ya da lambaları '
     'yanmış.', 1, FUSE_ISO, CLUSTER),
    ('f.window.regulator', 'body.window_regulators', ['sym.window'],
     'Cam krikosunun teli kopmuş ya da motoru zayıflamış.', 1, WINDOW_ISO,
     REGULATOR),
    ('f.door_lock.motor', 'body.door_locks', ['sym.door_lock'],
     'Kapı kilit motoru ya da mekanizması arızalı.', 1, WINDOW_ISO, LOCK),
    # Aydınlatma
    ('f.headlight.bulb', 'body.headlights', ['sym.headlight_out'],
     'Far ampulü yanmış.', 1, LIGHTS_ISO, HEADLIGHT),
    ('f.taillight.bulb', 'body.taillights', ['sym.brake_light',
                                             'sym.turn_fast'],
     'Arka lamba ampulü yanmış ya da duyu oksitlenmiş.', 2, LIGHTS_ISO,
     TAIL_BULB),
    ('f.brake_switch.faulty', 'lighting.brake_switch', ['sym.brake_light'],
     'Stop lambası müşiri ayarsız ya da arızalı.', 2, LIGHTS_ISO,
     BRAKE_SWITCH),
    ('f.flasher.failed', 'lighting.flasher', ['sym.turn_fast'],
     'Sinyal rölesi arızalı.', 1, LIGHTS_ISO, FLASHER),
    ('f.foglight.water', 'lighting.foglights', ['sym.fog_out'],
     'Sis lambasının contası bozulmuş; içine su girip ampulü yakmış.', 1,
     LIGHTS_ISO, FOG_BULB),
    # Gövde ve kabin
    ('f.wipers.worn', 'body.wipers', ['sym.wiper_streak'],
     'Silecek lastikleri sertleşmiş.', 1, None, WIPERS),
    ('f.wiper_motor.failed', 'body.wiper_motor', ['sym.wiper_dead'],
     'Silecek motoru ya da park anahtarı arızalı.', 2, WIPER_ISO,
     WIPER_MOTOR),
    ('f.washer.pump', 'body.washer', ['sym.washer'],
     'Cam suyu pompası arızalı ya da memeler tıkalı.', 1, WIPER_ISO, WASHER),
    ('f.door.seal', 'body.door_seals', ['sym.water_leak'],
     'Kapı fitili sertleşmiş ya da yırtılmış.', 1, DOORS, SEALS),
    ('f.windshield.crack', 'body.windshield', ['sym.windshield_crack'],
     'Taş çarpmasıyla camda çatlak ya da çukur oluşmuş.', 2,
     WINDSHIELD_CHECK, WINDSHIELD),
    ('f.hood.latch', 'body.hood', ['sym.hood'],
     'Kaput kilidi kirlenmiş ya da ayarsız; açma teli gerilmiş.', 1, None,
     HOOD_LATCH),
    ('f.mirror.glass', 'body.mirrors', ['sym.mirror'],
     'Ayna camı kırılmış ya da tutucusundan çıkmış.', 1, None, MIRROR),
    ('f.body.rust', 'body.shell', ['sym.rust'],
     'Boya altına su girmiş; sac paslanıyor.', 1, BODY_CHECK, None),
    ('f.seat_belt.retractor', 'interior.seat_belts', ['sym.belt'],
     'Emniyet kemeri makarası arızalı ya da kayış kirlenmiş.', 3,
     BELT_CHECK, BELT),
    ('f.seat.runner', 'interior.seat_front_r', ['sym.seat'],
     'Koltuk rayı kirlenmiş ya da kilit mandalı aşınmış.', 2, None, SEAT),
    ('f.srs.fault', 'interior.srs', ['sym.srs'],
     'Hava yastığı sisteminde kayıtlı arıza var (bağlantı, çarpma sensörü '
     'ya da spiral kablo).', 3, SRS_ISO, None),
    # Isıtma ve klima
    ('f.ac.leak', 'hvac.condenser', ['sym.ac_warm'],
     'Kondenser ya da rakorlar sızdırıyor; soğutucu akışkan eksik.', 1,
     AC_ISO, AC_CHECK),
    ('f.ac.compressor', 'hvac.compressor', ['sym.ac_warm', 'sym.ac_noise'],
     'Kompresör kavraması devreye girmiyor ya da kompresör aşınmış.', 2,
     AC_ISO, COMPRESSOR),
    ('f.blower.failed', 'hvac.blower', ['sym.blower'],
     'Kalorifer fan motoru ya da fan direnci arızalı.', 1, HEATER_ISO,
     BLOWER),
    ('f.heater_core.leak', 'hvac.heater_core',
     ['sym.fogging', 'sym.coolant_loss', 'sym.heater_cold'],
     'Kalorifer peteği sızdırıyor; soğutma suyu kabine buharlaşıyor.', 2,
     HEATER_ISO, HEATER_CORE),
    # Güç aktarma
    ('f.clutch.worn', 'drivetrain.clutch', ['sym.clutch_slip'],
     'Debriyaj balatası aşınmış.', 2, CLUTCH, CLUTCH_SET),
    ('f.clutch.hydraulic', 'drivetrain.clutch_hydraulics',
     ['sym.clutch_pedal', 'sym.hard_shift'],
     'Debriyaj ana ya da tali merkezi kaçırıyor; sistemde hava var.', 2,
     CLUTCH, CLUTCH_BLEED),
    ('f.transaxle.oil_low', 'drivetrain.transaxle', ['sym.hard_shift'],
     'Şanzıman yağı eksik.', 2, CLUTCH, GEARBOX),
    ('f.shift_linkage.worn', 'drivetrain.shift_linkage', ['sym.vague_shift'],
     'Vites kolu burçları ya da kumanda tellerinin uçları aşınmış.', 1,
     CLUTCH, LINKAGE),
    ('f.driveshaft.boot', 'drivetrain.driveshafts', ['sym.turn_click'],
     'Aks mili körüğü yırtılmış; aks kafası aşınmış.', 2, DRIVESHAFT,
     CV_BOOT),
    # Fren
    ('f.pads.worn', 'brakes.front.pads', ['sym.brake_weak',
                                          'sym.brake_noise'],
     'Ön balatalar aşınma sınırına gelmiş.', 3, BRAKE_ISOLATE, PADS),
    ('f.discs.warped', 'brakes.front.discs', ['sym.brake_pulse',
                                              'sym.brake_noise'],
     'Ön diskler eğrilmiş ya da MIN kalınlığın altına inmiş.', 2, DISCS,
     DISC_REPLACE),
    ('f.caliper.sticking', 'brakes.front.calipers',
     ['sym.brake_pull', 'sym.hot_wheel'],
     'Ön kaliper pistonu ya da kılavuz pimleri sıkışmış.', 3, BRAKE_ISOLATE,
     CALIPER),
    ('f.rear_pads.worn', 'brakes.rear.pads', ['sym.brake_noise',
                                              'sym.handbrake'],
     'Arka balatalar aşınma sınırına gelmiş.', 2, BRAKE_ISOLATE, REAR_PADS),
    ('f.booster.vacuum', 'brakes.booster', ['sym.pedal_hard',
                                            'sym.brake_weak'],
     'Fren servosu vakum almıyor; hortum çatlak ya da diyafram yırtık.', 3,
     BRAKE_ISOLATE, BOOSTER),
    ('f.master.internal', 'brakes.master_cylinder', ['sym.pedal_soft'],
     'Ana merkezin keçeleri içeriden kaçırıyor.', 3, BRAKE_ISOLATE, MASTER),
    ('f.brake_lines.leak', 'brakes.lines',
     ['sym.pedal_soft', 'sym.brake_fluid_low'],
     'Fren hortumu çatlamış ya da borusu paslanıp delinmiş.', 3,
     BRAKE_ISOLATE, BRAKE_BLEED),
    ('f.parking.adjust', 'brakes.parking', ['sym.handbrake'],
     'El freni teli gerilmiş ya da ayarı bozulmuş.', 2, REAR_BRAKES,
     PARKING),
    # Süspansiyon ve direksiyon
    ('f.strut.worn', 'chassis.strut_front', ['sym.bounce', 'sym.knock'],
     'Ön amortisör yağını kaçırmış ya da takozu yırtılmış.', 2,
     SUSPENSION_CHECK, STRUT),
    ('f.control_arm.bushing', 'chassis.control_arm', ['sym.knock',
                                                      'sym.pull'],
     'Salıncak burcu aşınmış.', 2, SUSPENSION_ISOLATE, None),
    ('f.ball_joint.worn', 'chassis.control_arm', ['sym.knock', 'sym.wander'],
     'Ön alt rotilde boşluk var.', 3, SUSPENSION_ISOLATE, BALL_JOINT),
    ('f.stabilizer.links', 'chassis.stabilizer_front', ['sym.rattle_bumps'],
     'Viraj demiri bağlantı çubuklarının mafsalları aşınmış.', 1,
     SUSPENSION_ISOLATE, STAB_LINK),
    ('f.wheel_bearing.front', 'chassis.wheel_bearing_front',
     ['sym.wheel_hum'], 'Ön tekerlek rulmanı aşınmış.', 2,
     SUSPENSION_ISOLATE, BEARING),
    ('f.wheel_bearing.rear', 'chassis.wheel_bearing_rear', ['sym.wheel_hum'],
     'Arka tekerlek rulmanı aşınmış.', 2, SUSPENSION_ISOLATE, BEARING_REAR),
    ('f.rear_strut.worn', 'chassis.strut_rear', ['sym.bounce',
                                                 'sym.rear_knock'],
     'Arka amortisör yağını kaçırmış.', 2, REAR_SUSPENSION, REAR_STRUT),
    ('f.rear_arms.bushing', 'chassis.arms_rear', ['sym.rear_knock',
                                                  'sym.tire_wear'],
     'Arka salıncak ya da çeki kolu burcu aşınmış; arka toplama bozuluyor.',
     2, REAR_SUSPENSION, None),
    ('f.alignment', 'chassis.steering_rack', ['sym.pull', 'sym.tire_wear'],
     'Ön düzen bozulmuş.', 1, SUSPENSION_ISOLATE, ALIGNMENT),
    ('f.tie_rod.worn', 'chassis.tie_rods', ['sym.wander', 'sym.tire_wear'],
     'Rot başında boşluk var.', 3, SUSPENSION_ISOLATE, TIE_ROD),
    ('f.power_steering.leak', 'chassis.power_steering',
     ['sym.heavy_steering', 'sym.steering_whine'],
     'Direksiyon yağı eksik; hortum ya da pompa keçesi sızdırıyor.', 2,
     STEERING_ISO, PS_CHECK),
    ('f.power_steering.pump', 'chassis.power_steering',
     ['sym.heavy_steering', 'sym.steering_whine'],
     'Hidrolik direksiyon pompası aşınmış; basınç vermiyor.', 2,
     STEERING_ISO, PS_PUMP),
    # Tekerlekler
    ('f.tire.puncture', 'wheels.tires', ['sym.flat', 'sym.pull'],
     'Lastik delinmiş ya da sibop kaçırıyor.', 2, TIRES, WHEEL),
    ('f.tire.balance', 'wheels.tires', ['sym.vibration'],
     'Tekerlek balansı bozulmuş.', 1, SUSPENSION_ISOLATE, BALANCE),
]


SPARE_PARTS = {
    'Silindir kapak contası': 'engine.head_gasket',
    'Supap kapağı contası': 'engine.head_cover',
    'Ön krank keçesi': 'engine.timing_cover',
    'Motor takozu': 'engine.mounts',
    'Kanallı aksesuar kayışı': 'engine.drive_belt',
    'Yağ filtresi': 'engine.oil_filter',
    'Yağ basınç müşiri': 'engine.oil_pressure_switch',
    'Emme manifoldu contası': 'engine.intake',
    'Egzoz manifoldu contası': 'engine.exhaust_manifold',
    'Su pompası, contasıyla': 'engine.water_pump',
    'Termostat, contasıyla': 'cooling.thermostat',
    'Radyatör': 'cooling.radiator',
    'Radyatör hortumu, üst': 'cooling.hoses',
    'Radyatör hortumu, alt': 'cooling.hoses',
    'Yakıt pompası': 'fuel.pump',
    'Yakıt filtresi': 'fuel.filter',
    'Enjektör': 'fuel.injectors',
    'Yakıt deposu kapağı': 'fuel.cap',
    'Hava filtresi elemanı': 'engine.air_filter',
    'Arka susturucu': 'exhaust.muffler',
    'Katalitik konvertör': 'exhaust.catalyst',
    'PCV valfi': 'exhaust.pcv',
    'EVAP boşaltma valfi (VSV)': 'exhaust.evap',
    'Buji, iridyum': 'engine.spark_plugs',
    'Ateşleme bobini': 'engine.coils',
    'Oksijen sensörü, ön': 'engine_control.o2_front',
    'Su sıcaklık sensörü': 'engine_control.ect',
    'Krank konum sensörü': 'engine_control.ckp',
    'Eksantrik konum sensörü': 'engine_control.cmp',
    'Gaz kelebeği konum sensörü': 'engine_control.tps',
    'Rölanti ayar valfi': 'engine_control.iscv',
    'Vuruntu sensörü': 'engine_control.knock',
    'Akü, 12 V 45 Ah': 'battery',
    'Alternatör': 'electrical.alternator',
    'Marş motoru': 'electrical.starter',
    'Kontak anahtarı elektrik bloğu': 'electrical.ignition_switch',
    'Korna': 'electrical.horn',
    'Ampul, H4 12 V 60/55 W': 'body.headlights',
    'Sinyal rölesi': 'lighting.flasher',
    'Stop lambası müşiri': 'lighting.brake_switch',
    'Cam krikosu, motoruyla': 'body.window_regulators',
    'Kapı kilit mekanizması, motoruyla': 'body.door_locks',
    'Kapı fitili': 'body.door_seals',
    'Ön cam': 'body.windshield',
    'Silecek süpürgesi, sürücü tarafı 550 mm': 'body.wipers',
    'Silecek süpürgesi, yolcu tarafı 400 mm': 'body.wipers',
    'Silecek motoru': 'body.wiper_motor',
    'Cam suyu pompası': 'body.washer',
    'Dış ayna camı': 'body.mirrors',
    'Emniyet kemeri, makarasıyla': 'interior.seat_belts',
    'Klima kompresörü': 'hvac.compressor',
    'Kalorifer fan motoru': 'hvac.blower',
    'Kalorifer peteği': 'hvac.heater_core',
    'Debriyaj seti (baskı, disk, rulman)': 'drivetrain.clutch',
    'Dış aks körüğü seti': 'drivetrain.driveshafts',
    'Ön balata takımı': 'brakes.front.pads',
    'Ön fren diski': 'brakes.front.discs',
    'Ön fren kaliperi': 'brakes.front.calipers',
    'Arka balata takımı': 'brakes.rear.pads',
    'Fren ana merkezi': 'brakes.master_cylinder',
    'Ön amortisör': 'chassis.strut_front',
    'Ön alt rotil': 'chassis.control_arm',
    'Viraj demiri bağlantı çubuğu': 'chassis.stabilizer_front',
    'Arka amortisör': 'chassis.strut_rear',
    'Rot başı': 'chassis.tie_rods',
    'Hidrolik direksiyon pompası': 'chassis.power_steering',
    'Ön tekerlek rulmanı': 'chassis.wheel_bearing_front',
    'Arka göbek ve rulman': 'chassis.wheel_bearing_rear',
}


def node_owner_check():
    """Her düğüme dokununca kendi parçası açılmalı.

    Uygulamanın seçimi (`ProductContent.partForNode`): en az düğümlü
    parçalar, sonra aynı düğümdeki diğer adayları en çok kapsayan, sonra
    ağaçta en üstte olan, sonra dosyadaki sıra. Beklenen: düğüme bağlı tek
    düğümlü parçalardan dosyada ilk gelen.
    """
    parents = {p['id']: p['parent'] for p in C.parts}

    def ancestors(pid):
        seen, p = [], parents[pid]
        while p:
            seen.append(p)
            p = parents[p]
        return seen

    nodes = {n for p in C.parts for n in p['nodes']}
    for node in sorted(nodes):
        cands = [p for p in C.parts if node in p['nodes']]
        fewest = min(len(p['nodes']) for p in cands)
        narrow = [p for p in cands if len(p['nodes']) == fewest]
        ids = [p['id'] for p in narrow]

        def key(p):
            covered = sum(1 for o in ids if p['id'] in ancestors(o))
            return (-covered, len(ancestors(p['id'])), ids.index(p['id']))

        chosen = min(narrow, key=key)['id']
        if fewest == 1:
            expected = next(p['id'] for p in C.parts if p['nodes'] == [node])
            assert chosen == expected, \
                f'{node}: {chosen} açılıyor, {expected} bekleniyordu'


C.zones, C.symptoms, C.faults = ZONES, SYMPTOMS, FAULTS
C.spare_parts = SPARE_PARTS
for name in SPARE_PARTS.values():
    C.part_number(name)
node_owner_check()
C.write()
