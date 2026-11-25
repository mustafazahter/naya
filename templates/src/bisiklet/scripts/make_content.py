"""Bisiklet şablonunun S1000D içeriğini ve parça haritasını üretir.

    python3 make_content.py

`csdb/` altındaki DM, PM ve DML dosyaları ile `map/` altındaki parts,
faults ve zones dosyaları buradan yazılır (`map/hotspots.json` elle
tutulur). Elle düzenlemek yerine buradaki tabloları değiştirip betiği
yeniden çalıştırın; böylece DMC'ler, parça haritası ve arızalar birbiriyle
tutarlı kalır.

İlk 26 DM elle yazılmıştı; kodları, parça kimlikleri ve uygulamanın
testlerinde geçen metinler korunarak buraya taşındı.

Değerler bu sınıftaki bisikletler için yaygın üretici değerleridir (Shimano
bayi el kitapları, Park Tool tork tablosu). Parçanın üzerinde ya da kendi
el kitabında başka bir değer yazıyorsa o geçerlidir.
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE.parent.parent / 'scripts'))

from s1000d_content import Content  # noqa: E402

# --- SNS ------------------------------------------------------------------

SNS = {
    'D00': ('Bisiklet', {}),
    'DA0': ('Kadro, çatal ve kumanda', {
        '1': 'Kadro', '2': 'Çatal ve furç', '3': 'Gidon ve kumanda',
        '4': 'Sele'}),
    'DA1': ('Aktarma organları', {
        '1': 'Zincir', '2': 'Aynakol, orta göbek ve ön vites',
        '3': 'Kaset', '4': 'Arka vites değiştirici', '5': 'Pedallar',
        '6': 'Vites kolları ve telleri'}),
    'DA2': ('Fren sistemi', {
        '1': 'Balatalar ve kaliperler', '2': 'Fren diskleri',
        '3': 'Fren kolları ve telleri'}),
    'DA3': ('Tekerlekler', {
        '1': 'Lastik ve iç lastik', '2': 'Jant ve teller', '3': 'Göbekler'}),
}

# --- Çizimler ---------------------------------------------------------------

# Numara → başlık. Dosyalar `render_icn.py` ile modelden üretilir.
FIGURES = {
    1: 'Bisiklet, sağdan görünüş',
    2: 'Aktarma organları',
    3: 'Ön disk fren',
    4: 'Arka vites değiştirici',
    5: 'Arka tekerlek',
    6: 'Yaylı çatal ve furç',
    7: 'Gidon ve kumanda',
    8: 'Aynakol ve orta göbek',
    9: 'Kaset ve arka göbek',
    10: 'Sele ve sele borusu',
    11: 'Ön göbek ve çabuk sökme mandalı',
    12: 'Arka disk fren',
    13: 'Vites ve fren kabloları',
    14: 'Ön vites değiştirici',
}

# Alet ve sarf malzemelerinin sabit numaraları. İlk DM'lerdeki numaralar
# korunuyor.
NUMBERS = {
    'Zincir sökme aparatı': 'NB-TL-CHAIN-TOOL',
    'Alyan anahtar takımı (2-8 mm)': 'NB-TL-HEX',
    'Bakım sehpası': 'NB-TL-STAND',
    'Zincir aşınma ölçeri': 'NB-TL-CHAIN-GAUGE',
    'Kaset sökme aparatı ve zincir kırbacı': 'NB-TL-CASSETTE-TOOL',
    '15 mm pedal anahtarı': 'NB-TL-PEDAL-WRENCH',
    'T25 Torx anahtar': 'NB-TL-TORX',
    'Manometreli pompa': 'NB-TL-PUMP',
    'Lastik sökme levyesi (2 adet)': 'NB-TL-TIRE-LEVERS',
    'Tork anahtarı (2-60 Nm)': 'NB-TL-TORQUE',
    'Orta göbek anahtarı (kartuş tipi)': 'NB-TL-BB',
    'Pedal kolu çektirmesi (kare göbek)': 'NB-TL-CRANK-PULLER',
    'Kablo kesme pensesi': 'NB-TL-CABLE-CUTTER',
    'Nipel anahtarı': 'NB-TL-SPOKE',
    'Jant düzeltme sehpası': 'NB-TL-TRUING',
    'Tel gerginlik ölçeri': 'NB-TL-TENSION',
    'Disk düzeltme anahtarı': 'NB-TL-ROTOR',
    'Göbek konik anahtarı (13-17 mm)': 'NB-TL-CONE',
    'Vites askısı hizalama aparatı': 'NB-TL-HANGER',
    'Kumpas': 'NB-TL-CALIPER',
    'Sibop içi anahtarı': 'NB-TL-VALVE',
    'Furç kabı sökücü ve presi': 'NB-TL-HEADSET',
    'Yama takımı': 'NB-TL-PATCH',
    'Kaşık uçlu tornavida': 'NB-TL-SCREWDRIVER',
    'Zincir yağı': 'NB-SP-CHAIN-LUBE',
    'Bisiklet gresi': 'NB-SP-GREASE',
    'İzopropil alkol': 'NB-SP-IPA',
    'Yağ çözücü': 'NB-SP-DEGREASER',
    'Çatal yağı (üreticinin önerdiği)': 'NB-SP-FORK-OIL',
    'Orta güçte vida sabitleyici': 'NB-SP-THREADLOCK',
    'İç lastik koruyucu sıvısı': 'NB-SP-SEALANT',
    'Temiz bez': 'NB-SP-RAG',
    'Bisiklet şampuanı': 'NB-SP-SHAMPOO',
    'Kablo ucu kapağı': 'NB-SP-CABLE-END',
}

C = Content(
    HERE, model='NAYABIKE',
    applic='Bütün bisikletler',
    product='Dağ bisikleti',
    manual='Dağ bisikleti bakım el kitabı',
    sns=SNS, figures=FIGURES, date=('2026', '11', '24'),
    numbers=NUMBERS)
code, dm, part = C.code, C.dm, C.part

HEX = ('Alyan anahtar takımı (2-8 mm)', 1)
STAND = ('Bakım sehpası', 1)
TORQUE = ('Tork anahtarı (2-60 Nm)', 1)
TORX = ('T25 Torx anahtar', 1)
PUMP = ('Manometreli pompa', 1)
LEVERS = ('Lastik sökme levyesi (2 adet)', 1)
CUTTER = ('Kablo kesme pensesi', 1)
GREASE = ('Bisiklet gresi', None)
IPA = ('İzopropil alkol', None)
RAG = ('Temiz bez', None)
DEGREASER = ('Yağ çözücü', None)
LUBE = ('Zincir yağı', None)

# --- DMC'ler ----------------------------------------------------------------
#
# Önce kodlar: DM'ler birbirine ve arızalara bu adlarla başvurur.

BIKE = code('D00')
PRERIDE = code('D00', info='300')
SCHEDULE = code('D00', info='300', disassy='01')
CLEANING = code('D00', info='250')
LUBRICATION = code('D00', info='241')
TORQUES = code('D00', info='030')
NOISES = code('D00', info='421')

FRAME_SYSTEM = code('DA0')
FRAME_CHECK = code('DA0', '1', '310')
FORK = code('DA0', '2')
HEADSET_ADJUST = code('DA0', '2', '271')
FORK_CHECK = code('DA0', '2', '300')
FORK_ISOLATE = code('DA0', '2', '421')
FORK_SETUP = code('DA0', '2', '271', '01')
FORK_SERVICE = code('DA0', '2', '241')
FORK_SEALS = code('DA0', '2', '921')
HEADSET_BEARINGS = code('DA0', '2', '920', '01')
COCKPIT_CHECK = code('DA0', '3', '300')
GRIPS = code('DA0', '3', '921')
LEVER_POSITION = code('DA0', '3', '271')
SEAT_HEIGHT = code('DA0', '4', '271')
SADDLE_ADJUST = code('DA0', '4', '271', '01')
SEATPOST_SERVICE = code('DA0', '4', '241')

DRIVE = code('DA1')
SHIFT_ISOLATE = code('DA1', info='421')
DRIVE_CLEAN = code('DA1', info='250')
CHAIN_LUBE = code('DA1', '1', '241')
CHAIN_MEASURE = code('DA1', '1', '361')
CHAIN_REMOVE = code('DA1', '1', '520')
CHAIN_INSTALL = code('DA1', '1', '720')
CHAIN_ISOLATE = code('DA1', '1', '421')
FD_ADJUST = code('DA1', '2', '271')
CRANK_CHECK = code('DA1', '2', '300')
CRANK_ISOLATE = code('DA1', '2', '421')
CRANK_ARMS = code('DA1', '2', '920')
BOTTOM_BRACKET = code('DA1', '2', '920', '01')
CHAINRING = code('DA1', '2', '921', '02')
CASSETTE = code('DA1', '3', '920')
CASSETTE_CHECK = code('DA1', '3', '300')
RD_ADJUST = code('DA1', '4', '271')
HANGER_CHECK = code('DA1', '4', '310')
RD_REPLACE = code('DA1', '4', '920')
HANGER_REPLACE = code('DA1', '4', '921', '01')
JOCKEY = code('DA1', '4', '921', '02')
PEDALS = code('DA1', '5', '920')
PEDAL_SERVICE = code('DA1', '5', '241')
SHIFT_CABLES = code('DA1', '6', '921')
SHIFTER_CHECK = code('DA1', '6', '300')
SHIFTER_REPLACE = code('DA1', '6', '920')
SHIFT_CABLE_LUBE = code('DA1', '6', '241')

BRAKES = code('DA2')
BRAKE_ADJUST = code('DA2', info='271')
BRAKE_ISOLATE = code('DA2', info='421')
BRAKE_CHECK = code('DA2', info='300')
PADS = code('DA2', '1', '921')
CALIPER = code('DA2', '1', '920', '01')
BRAKE_CLEAN = code('DA2', '1', '250')
PAD_MEASURE = code('DA2', '1', '361')
ROTOR_CHECK = code('DA2', '2', '300')
ROTOR_REPLACE = code('DA2', '2', '920')
ROTOR_TRUE = code('DA2', '2', '271')
BRAKE_CABLES = code('DA2', '3', '921')
BRAKE_LEVER = code('DA2', '3', '920')
BRAKE_LEVER_CHECK = code('DA2', '3', '300')
BRAKE_LEVER_ISOLATE = code('DA2', '3', '421')

WHEELS = code('DA3')
WHEEL_CHECK = code('DA3', info='300')
WHEEL_REMOVE = code('DA3', info='520')
WHEEL_INSTALL = code('DA3', info='720')
WHEEL_ISOLATE = code('DA3', info='421')
QR_ADJUST = code('DA3', info='271')
TUBE = code('DA3', '1', '920')
TIRE = code('DA3', '1', '921', '01')
VALVE = code('DA3', '1', '921', '02')
INFLATE = code('DA3', '1', '210')
SEALANT = code('DA3', '1', '210', '01')
TIRE_CHECK = code('DA3', '1', '300')
TRUING = code('DA3', '2', '271')
SPOKE_TENSION = code('DA3', '2', '361')
SPOKE_REPLACE = code('DA3', '2', '921')
RIM_CHECK = code('DA3', '2', '300')
HUB_ADJUST = code('DA3', '3', '271')
HUB_SERVICE = code('DA3', '3', '241')
HUB_CHECK = code('DA3', '3', '300')


# --- DM içerikleri ---------------------------------------------------------
#
# Alanlar `templates/scripts/s1000d_content.py` başında anlatılıyor.

# Genel ----------------------------------------------------------------------

dm(code=BIKE, tech='Bisiklet', figure=1, description=[
    ('Genel', [
        'Bu el kitabı, önden süspansiyonlu bir dağ bisikletinin bakımını ve '
        'arıza bulmasını anlatır. Bisiklet alüminyum kadro, yaylı çatal, '
        '3 × 8 = 24 vitesli aktarma organları ve iki tekerlekte telle '
        'çalışan disk frenlerden oluşur.',
        'Sağ, sol, ön ve arka, bisiklete sürücü selesinde otururken bakılan '
        'yöne göre verilir. Zincir tarafı sağ taraftır.',
    ]),
    ('Ana bölümler', [
        ('Bisiklet dört ana sistemden oluşur:', [
            'Kadro, çatal ve kumanda: kadro bütün parçaları taşır; yaylı '
            'çatal ön tekerleği tutar ve yoldan gelen darbeyi sönümler; '
            'gidonda elcikler, fren kolları ve tetik vites kolları vardır.',
            'Aktarma organları: pedallardan gelen güç üç aynalı aynakol, '
            'zincir ve sekiz dişli kaset üzerinden arka tekerleğe aktarılır. '
            'Ön ve arka vites değiştiriciler zinciri dişliler arasında '
            'kaydırır.',
            'Fren sistemi: her iki tekerlekte 160 mm disk ve mekanik kaliper '
            'vardır. Fren kolu çekilince tel kaliperdeki balataları diske '
            'bastırır.',
            'Tekerlekler: jant, teller, çabuk sökme mandallı göbek, iç '
            'lastik ve dış lastik.',
        ]),
    ]),
    ('Teknik veriler', [
        ('Ana ölçüler ve parçalar:', [
            'Tekerlek: 27,5" (ETRTO 584), lastik 27,5 × 2,25 (57-584).',
            'Lastik basıncı: lastiğin yanağında yazan aralıkta; bu ölçüde '
            'genellikle 2,0-3,5 bar (30-50 psi).',
            'Sibop: otomobil tipi (Schrader).',
            'Vites: önde 3 ayna (22-32-42 diş), arkada 8 dişli kaset '
            '(11-32 diş); zincir 8 vites, 116 bakla.',
            'Fren: mekanik disk, 160 mm 6 cıvatalı disk, organik balata.',
            'Çatal: yaylı, 100 mm yol, ön yük ayarlı.',
            'Orta göbek: kare milli kartuş, BSA 68 mm gövde.',
            'Sele borusu: 27,2 mm, çabuk sökme kelepçeli.',
        ]),
        'Sıkma torkları ayrı bir DM\'de toplanmıştır.',
    ]),
    ('Güvenlik', [
        'Her sürüşten önce fren kollarını sıkın ve lastik basıncına bakın. '
        'Frenler tutmuyorsa bisiklete binmeyin.',
        'Karbon ya da alüminyum parçalarda çatlak, ezik ya da derin çizik '
        'varsa parçayı kullanmayın; bu parçalar uyarı vermeden kırılabilir.',
    ]),
])

dm(code=TORQUES, tech='Bisiklet', info='Sıkma torkları', description=[
    ('Genel', [
        'Cıvataları tork anahtarıyla sıkın. Değerler bu sınıftaki parçalar '
        'için yaygın üretici değerleridir; parçanın üzerinde ya da kendi '
        'el kitabında farklı bir değer yazıyorsa o geçerlidir.',
        'Dişleri temiz ve hafif greslenmiş olarak sıkın. Disk cıvataları ve '
        'kaliper cıvataları gibi titreşim alan cıvatalara orta güçte vida '
        'sabitleyici sürülür.',
    ]),
    ('Kadro, çatal ve kumanda', [
        ('Torklar:', [
            'Gidon boğazı (stem) çatal boğazı cıvataları: 5-6 Nm, sırayla.',
            'Gidon boğazı ön kapak cıvataları: 5-6 Nm, çapraz sırayla.',
            'Furç üst kapak cıvatası: yalnız boşluk alınacak kadar; tork '
            'uygulanmaz.',
            'Fren kolu kelepçesi: 6-8 Nm.',
            'Tetik vites kolu kelepçesi: 2,5-3 Nm.',
            'Elcik kilit halkası (varsa): 2-3 Nm.',
            'Sele kelepçesi (tek cıvata): 20-24 Nm.',
            'Sele borusu kelepçesi (cıvatalı): 5-6 Nm; çabuk sökme '
            'kelepçede elle kapatma.',
        ]),
    ]),
    ('Aktarma organları', [
        ('Torklar:', [
            'Pedal kolu cıvatası (kare göbek): 35-50 Nm.',
            'Orta göbek kartuşu (BSA): 50-70 Nm.',
            'Aynakol cıvataları: 8-11 Nm.',
            'Pedal: 35-55 Nm.',
            'Kaset kilit somunu: 30-50 Nm.',
            'Arka vites değiştirici bağlantı cıvatası: 8-10 Nm.',
            'Vites teli sıkma cıvatası (ön ve arka): 5-7 Nm.',
            'Ön vites değiştirici kelepçesi: 5-7 Nm.',
            'Vites askısı cıvatası: 1,5-2,5 Nm (askı üreticisinin değeri '
            'geçerlidir).',
        ]),
    ]),
    ('Frenler ve tekerlekler', [
        ('Torklar:', [
            'Fren diski cıvatası (6 cıvatalı, T25): 2-4 Nm.',
            'Kaliper bağlantı cıvataları: 6-8 Nm.',
            'Fren teli sıkma cıvatası: 6-8 Nm.',
            'Çabuk sökme mandalı: tork yerine kapatma direnci; mandal '
            'kapanırken avuç içinde iz bırakmalıdır.',
            'Göbek kontra somunları: 15-17 Nm.',
        ]),
    ]),
])

dm(code=PRERIDE, tech='Bisiklet', info='Sürüş öncesi kontrol', figure=1,
   steps=[
       'Fren kollarını sıkın. Kollar gidona değmeden sertleşmeli ve '
       'bisiklet itildiğinde tekerlekler dönmemelidir.',
       'Lastik basıncını parmakla ya da manometreyle kontrol edin; '
       'yanaktaki aralıkta olmalıdır.',
       'Çabuk sökme mandallarının kapalı ve sıkı olduğunu, mandal ucunun '
       'çatal ya da kadro yönüne baktığını kontrol edin.',
       'Bisikleti 10 cm kaldırıp bırakın. Tıkırtı ya da gevşek parça sesi '
       'gelmemelidir.',
       'Ön freni sıkıp bisikleti ileri geri itin; furçta boşluk '
       'olmamalıdır.',
       'Gidonu ön tekerlekle hizalı tutup döndürmeye çalışın; gidon '
       'boğazı kaymamalıdır.',
       'Pedal kollarını yanlara itin; boşluk olmamalıdır.',
       'Zincirin kuru ya da paslı olmadığına bakın.',
   ])

dm(code=SCHEDULE, tech='Bisiklet', info='Periyodik bakım çizelgesi',
   steps=[
       ('Her sürüşten önce', [
           'Sürüş öncesi kontrolü yapın.',
       ]),
       ('Her sürüşten sonra', [
           'Çamurlu sürüşten sonra bisikleti yıkayın, zinciri kurulayıp '
           'yağlayın.',
           'Çatal iç borularını ve toz keçelerini temiz bir bezle silin.',
       ]),
       ('Her 25 saatte ya da ayda bir', [
           'Zinciri temizleyip yağlayın.',
           'Fren balatası kalınlığını ve kol boşluğunu kontrol edin.',
           'Tekerleklerde yalpa ve tel gevşekliği olup olmadığına bakın.',
           'Vites ayarını kontrol edin.',
       ]),
       ('Her 50 saatte ya da üç ayda bir', [
           'Zincir aşınmasını ölçün.',
           'Çatal alt bacak yağını değiştirin ve toz keçelerini temizleyin.',
           'Cıvataları sıkma torklarına göre kontrol edin.',
           'Fren ve vites tellerini ve kılıflarını kontrol edin.',
           'Fren disklerinin kalınlığını ölçün.',
       ]),
       ('Her 100 saatte ya da yılda bir', [
           'Fren ve vites tellerini ve kılıflarını değiştirin.',
           'Furç, göbek ve pedal rulmanlarının boşluğunu ve dönüşünü '
           'kontrol edin; gerekiyorsa bakımını yapın.',
           'Orta göbeği kontrol edin.',
           'Sele borusunu söküp temizleyin ve gresleyin.',
           'Çatalın yetkili serviste tam bakımını yaptırın.',
       ]),
   ])

dm(code=CLEANING, tech='Bisiklet', info='Temizlik',
   tools=[STAND],
   supplies=[('Bisiklet şampuanı', None), DEGREASER, RAG, LUBE],
   cautions=['Basınçlı yıkama makinesini rulmanlara, furça, orta göbeğe ve '
             'göbeklere tutmayın; su keçelerden içeri girer.',
             'Yağ çözücüyü fren disklerine ve balatalara bulaştırmayın.'],
   steps=[
       'Bisikleti bakım sehpasına alın. Kuru çamuru yumuşak fırçayla '
       'dökün.',
       'Kadroyu, çatalı ve tekerlekleri şampuanlı suyla yukarıdan aşağıya '
       'yıkayın ve bol suyla durulayın.',
       'Zinciri, kaseti, aynakolu ve vites değiştiricilerin makaralarını '
       'yağ çözücüyle fırçalayın; suyla durulayın.',
       'Bisikleti bezle kurulayın. Zinciri kuruladıktan sonra yağlayın.',
       'Diskleri izopropil alkollü temiz bir bezle silin.',
   ],
   next=CHAIN_LUBE)

dm(code=LUBRICATION, tech='Bisiklet', info='Yağlama',
   supplies=[LUBE, GREASE, RAG],
   cautions=['Fren disklerine, balatalara ve fren kolu bağlantılarının '
             'dışındaki fren yüzeylerine yağ bulaştırmayın.'],
   steps=[
       ('Zincir yağı ile', [
           'Zincir: her baklanın makarasına bir damla, sonra fazlasını '
           'silin.',
           'Ön ve arka vites değiştiricinin pivot noktaları: birer damla.',
           'Fren ve vites kollarının pivotları: birer damla.',
           'Tellerin kılıfa girdiği uçlar: birer damla.',
       ]),
       ('Gres ile (sökülüp takılırken)', [
           'Pedal ve pedal kolu dişleri, orta göbek dişleri.',
           'Sele borusunun kadroya giren kısmı (alüminyum kadro, alüminyum '
           'boru).',
           'Furç, göbek ve pedal rulmanları.',
           'Çabuk sökme mandalı kamı ve mili.',
       ]),
   ])

dm(code=NOISES, tech='Bisiklet', info='Arıza bulma: sesler', isolation={
    'fault': 'NAYABIKE-D00-001',
    'descr': 'Sürüşte gıcırtı, tıkırtı ya da vuruntu sesi geliyor.',
    'steps': [
        ('stp-0001', 'Bisikleti sehpaya alın ve pedalı çevirmeden yalnız '
         'arka tekerleği döndürün.',
         'Ses yalnız pedal çevirince mi geliyor?', 'stp-0002', 'stp-0003'),
        ('stp-0002', 'Pedalları koldayken elle çevirin ve pedal gövdesini '
         'mil yönünde oynatın.',
         'Pedal takılarak dönüyor ya da mil üzerinde boşluk yapıyor mu?',
         'end-pedal', 'stp-0005'),
        ('stp-0005', 'Ayakta pedal basarken ve otururken sesi dinleyin; '
         'sonra pedal kollarını yanlara itin.',
         'Ses ayakta ve her pedal turunda aynı noktada mı geliyor?',
         'end-crank', 'end-chain'),
        ('stp-0003', 'Ön freni sıkıp bisikleti ileri geri itin ve '
         'bisikleti tümseklerde zıplatın.',
         'Ses önden, furç ya da çataldan mı geliyor?', 'end-fork',
         'stp-0004'),
        ('stp-0004', 'Sele üzerinde otururken ağırlığınızı kaydırın.',
         'Ses seleden ya da sele borusundan mı geliyor?', 'end-seat',
         'end-wheel'),
    ],
    'ends': [
        ('end-pedal', 'Pedalı söküp rulmanını kontrol edin; rulman '
         'aşınmışsa pedalı değiştirin. Takarken 35 Nm ile sıkın.', PEDALS),
        ('end-crank', 'Aynakol ve orta göbek için arıza bulmaya geçin.',
         CRANK_ISOLATE),
        ('end-chain', 'Zinciri temizleyip yağlayın; ses sürerse vites '
         'ayarını kontrol edin.', CHAIN_LUBE),
        ('end-fork', 'Çatal için arıza bulmaya geçin.', FORK_ISOLATE),
        ('end-seat', 'Sele borusunu söküp temizleyin ve gresleyin; sele '
         'kelepçesini sıkın.', SEATPOST_SERVICE),
        ('end-wheel', 'Tekerlekler için arıza bulmaya geçin.',
         WHEEL_ISOLATE),
    ],
})

# Kadro, çatal ve kumanda ------------------------------------------------------

dm(code=FRAME_SYSTEM, tech='Kadro, çatal ve kumanda', figure=1, description=[
    ('Kadro', [
        'Kadro 6061 alüminyum borulardan kaynaklıdır. Baş borusunda furç, '
        'orta göbek gövdesinde (BSA, 68 mm) orta göbek, sele borusunda sele '
        'borusu ve ön vites değiştirici kelepçesi yer alır.',
        'Arka vites değiştirici, kadroya değiştirilebilir bir vites askısıyla '
        'bağlanır. Askı darbede kadrodan önce bükülerek kadroyu korur.',
        'Fren ve vites kabloları üst boru boyunca kılıflı olarak gider.',
    ]),
    ('Çatal ve furç', [
        'Yaylı çatalın 100 mm yolu vardır; ön yük düğmesiyle sertliği '
        'ayarlanır. Çatal boğazı baş borusu içinde furç rulmanlarıyla döner.',
    ]),
    ('Gidon ve kumanda', [
        'Düz gidon, gidon boğazıyla (stem) çatal boğazına bağlanır. Gidonda '
        'elcikler, iki fren kolu ve iki tetik vites kolu vardır: sol kollar '
        'ön fren ve ön vites değiştiriciyi, sağ kollar arka fren ve arka '
        'vites değiştiriciyi kumanda eder.',
    ]),
    ('Sele', [
        'Sele, tek cıvatalı kelepçeyle 27,2 mm sele borusuna bağlanır. Sele '
        'borusu kadroya çabuk sökme kelepçesiyle sıkılır.',
    ]),
])

dm(code=FRAME_CHECK, tech='Kadro', info='Gözle muayene', figure=1,
   tools=[STAND], supplies=[RAG],
   warnings=['Çatlak ya da ezik bulunan kadroyla sürüş yapmayın. Alüminyum '
             'kadrolar onarılmaz; kadroyu değiştirin.'],
   steps=[
       'Bisikleti yıkayıp kurulayın; boya altındaki çatlaklar ancak temiz '
       'yüzeyde görünür.',
       'Kaynak yerlerini ışık tutarak inceleyin: baş borusu, orta göbek '
       'gövdesi, sele borusu ile üst borunun birleşimi ve arka çatal '
       'uçları (dropout).',
       'Borularda ezik, derin çizik ya da boyada kılcal çatlak izi olup '
       'olmadığına bakın.',
       'Arka çatal uçlarının ve vites askısı yuvasının eğri olmadığını '
       'kontrol edin.',
       'Kablo kılavuzlarının ve matara pabuçlarının yerinde ve sıkı '
       'olduğunu kontrol edin.',
   ])

dm(code=FORK, tech='Yaylı çatal', figure=6, description=[
    ('Genel', [
        'Çatal, üst bağlantı (taç) ve iki iç boru (stanchion) ile bunların '
        'üzerinde kayan alt bacaklardan oluşur. Sol ayakta helezon yay ve '
        'ön yük düğmesi, sağ ayakta sönümleme ve kilit (varsa) bulunur.',
        'Alt bacaklar iç borulara burçlarla oturur. Burçlar ve toz keçeleri '
        'alt bacaktaki banyo yağıyla yağlanır.',
    ]),
    ('Ayarlar', [
        'Ön yük düğmesi saat yönünde çevrilince yay sıkışır, çatal sertleşir. '
        'Sürücü bisiklete bindiğinde çatal yolunun yaklaşık %15-25\'i kadar '
        'çökmelidir.',
        'Kilit kolu (varsa) çatalı düz yolda ve tırmanışta sertleştirir. '
        'Kilitli çatalla arazi inişi yapmayın.',
    ]),
    ('Bakım', [
        'İç borular her sürüşten sonra silinir. Alt bacak yağı yaklaşık 50 '
        'saatte bir değiştirilir. Yay ve sönümleme kartuşunun bakımı '
        'yetkili serviste yapılır.',
    ]),
])

dm(code=FORK_CHECK, tech='Çatal ve furç', info='Muayene', figure=6,
   tools=[STAND], supplies=[RAG],
   steps=[
       'Bisikleti yere koyun, ön freni sıkın ve gidonu ileri geri itin. '
       'Furçtan tıkırtı geliyorsa ya da boşluk hissediliyorsa furç ayarı '
       'yapın.',
       'Çatalı birkaç kez bastırarak çökertin. Hareket pürüzsüz olmalı, '
       'dönüşte vuruntu sesi gelmemelidir.',
       'Çatal ayaklarının iç borularında çizik, yağ sızıntısı ya da kir '
       'olup olmadığına bakın. İç boruları temiz bir bezle silin.',
       'Ön tekerleği yerden kaldırın ve gidonu sağa sola çevirin. Dönüş '
       'takılmadan ve boşluksuz olmalıdır.',
       'Alt bacakları tutup ileri geri oynatın. Belirgin boşluk varsa '
       'burçlar aşınmıştır.',
   ],
   next=HEADSET_ADJUST)

dm(code=HEADSET_ADJUST, tech='Furç', info='Ayar', figure=6,
   tools=[HEX, TORQUE],
   steps=[
       'Gidon boğazının yan taraftaki iki sıkma cıvatasını 5 mm alyanla '
       'gevşetin.',
       'Üstteki kapak cıvatasını çeyrek tur sıkın.',
       'Ön freni sıkıp gidonu ileri geri iterek boşluğu kontrol edin. '
       'Boşluk kalmayana kadar çeyrek turluk adımlarla devam edin.',
       'Gidonu çevirin; dönüş sıkışmamalıdır. Sıkışıyorsa kapak cıvatasını '
       'biraz gevşetin.',
       'Gidonu ön tekerlekle hizalayın ve boğaz cıvatalarını sırayla '
       '5-6 Nm ile sıkın.',
   ])

dm(code=FORK_ISOLATE, tech='Yaylı çatal', info='Arıza bulma', isolation={
    'fault': 'NAYABIKE-DA0-001',
    'descr': 'Çatal vuruntu yapıyor, yağ sızdırıyor, takılıyor ya da '
             'dibe vuruyor.',
    'steps': [
        ('stp-0001', 'Ön freni sıkıp gidonu ileri geri itin.',
         'Boşluk ya da tıkırtı hissediliyor mu?', 'end-headset',
         'stp-0006'),
        ('stp-0006', 'Ön tekerleği yerden kaldırıp gidonu yavaşça sağa '
         'sola çevirin.',
         'Gidon belli bir noktada takılıyor ya da tırtıklı dönüyor mu?',
         'end-bearings', 'stp-0002'),
        ('stp-0002', 'İç boruları silip birkaç kez çökertin; sonra '
         'toz keçelerinin çevresine bakın.',
         'İç boruda yağ halkası ya da keçe çevresinde kir birikmiş mi?',
         'stp-0003', 'stp-0004'),
        ('stp-0003', 'İç boruları ışık tutarak inceleyin.',
         'İç boruda tırnağın takıldığı bir çizik var mı?', 'end-stanchion',
         'end-seals'),
        ('stp-0004', 'Bisiklete binip sert bir frenleme ve küçük bir '
         'düşüş deneyin.',
         'Çatal dibe vuruyor ya da çok yumuşak mı?', 'end-preload',
         'stp-0005'),
        ('stp-0005', 'Alt bacakları tutup ileri geri oynatın.',
         'Alt bacaklarda boşluk var mı?', 'end-bushings', 'end-service'),
    ],
    'ends': [
        ('end-headset', 'Furç boşluğunu alın.', HEADSET_ADJUST),
        ('end-bearings', 'Furç rulmanları ya da kapları çukurlaşmış; '
         'rulmanları değiştirin.', HEADSET_BEARINGS),
        ('end-stanchion', 'Çizik iç boru keçeyi kısa sürede bozar; iç boru '
         'ünitesi yetkili serviste değiştirilmelidir.', None),
        ('end-seals', 'Toz keçelerini değiştirin.', FORK_SEALS),
        ('end-preload', 'Ön yükü sürücü ağırlığına göre ayarlayın.',
         FORK_SETUP),
        ('end-bushings', 'Burçlar aşınmış; alt bacak yağını değiştirin. '
         'Boşluk sürerse alt bacaklar yetkili serviste değiştirilmelidir.',
         FORK_SERVICE),
        ('end-service', 'Alt bacak bakımını yapın.', FORK_SERVICE),
    ],
})

dm(code=FORK_SETUP, tech='Yaylı çatal', info='Ön yük ve kilit ayarı',
   figure=6, tools=[('Kumpas', 1)],
   steps=[
       'İç borunun üzerine bir plastik kablo bağı takıp toz keçesine kadar '
       'itin.',
       'Sürüş kıyafetinizle bisiklete binin ve ağırlığınızı pedallara ve '
       'gidona normal sürüşteki gibi verin; sonra dikkatle inin.',
       'Kablo bağı ile toz keçesi arasındaki mesafeyi ölçün. 100 mm yollu '
       'çatalda bu çökme 15-25 mm olmalıdır.',
       'Çökme fazlaysa ön yük düğmesini saat yönünde, azsa tersine çevirin '
       've ölçümü tekrarlayın.',
       'Ön yük düğmesi sonuna kadar çevrildiği halde çatal dibe vuruyorsa '
       'daha sert bir yay gerekir; yetkili servise başvurun.',
       'Kilit kolunu (varsa) açık ve kapalı konumda deneyin; kapalıyken '
       'çatal belirgin şekilde sertleşmelidir.',
   ])

dm(code=FORK_SERVICE, tech='Yaylı çatal', info='Alt bacak bakımı',
   figure=6, tools=[HEX, TORQUE, ('Kaşık uçlu tornavida', 1)],
   supplies=[('Çatal yağı (üreticinin önerdiği)', None), GREASE, IPA, RAG],
   conditions=['Ön tekerlek ve ön fren kaliperi sökülmüş.'],
   cautions=['Çatal yağının cinsini ve miktarını çatalın kendi el '
             'kitabından alın; yanlış yağ keçeleri bozar.'],
   steps=[
       'Ön tekerleği ve kaliperi sökün; fren telini çataldaki tutucudan '
       'çıkarın.',
       'Alt bacakların altındaki iki cıvatayı birkaç tur gevşetin ve '
       'plastik tokmakla vurarak milleri içeri itin.',
       'Bir kabın üstünde cıvataları tamamen sökün ve alt bacakları aşağı '
       'çekip çıkarın; banyo yağını boşaltın.',
       'İç boruları ve alt bacakların içini izopropil alkolle temizleyin. '
       'Toz keçelerinin içindeki köpük halkaları yağa batırın.',
       'Keçe dudaklarına ince gres sürün ve alt bacakları iç borulara '
       'takın.',
       'Alt bacaklar yarıya kadar takılıyken her ayağa çatalın el kitabında '
       'yazan miktarda banyo yağı koyun.',
       'Alt bacakları sonuna kadar itin, cıvataları el kitabındaki torkla '
       'sıkın.',
       'Kaliperi ve tekerleği takın; çatalı birkaç kez çökertip fazla '
       'yağı silin.',
   ],
   next=WHEEL_INSTALL)

dm(code=FORK_SEALS, tech='Çatal toz keçeleri', info='Değiştirme',
   figure=6, tools=[('Kaşık uçlu tornavida', 1), HEX],
   supplies=[GREASE, IPA, RAG],
   spares=[('Toz keçesi takımı', 1)],
   conditions=['Alt bacaklar sökülmüş.'],
   steps=[
       'Eski keçeyi alt bacağın ağzından, keçe yuvasını çizmeden '
       'tornavidayla kaldırarak çıkarın.',
       'Keçe yuvasını izopropil alkolle temizleyin.',
       'Yeni köpük halkayı yağa batırıp yerleştirin.',
       'Yeni keçeyi uygun çaplı bir boru ya da keçe çakma aletiyle düz ve '
       'tam oturana kadar çakın.',
       'Keçe dudağına ince gres sürün ve alt bacakları takın.',
   ],
   next=FORK_SERVICE)

dm(code=HEADSET_BEARINGS, tech='Furç rulmanları', info='Değiştirme',
   figure=6, tools=[HEX, TORQUE, ('Furç kabı sökücü ve presi', 1)],
   supplies=[GREASE, RAG],
   spares=[('Furç rulmanı takımı', 1)],
   steps=[
       'Ön freni ve gidonu kablolar takılı kalacak şekilde sökün; gidonu '
       'kadroya bağlayarak asın.',
       'Furç üst kapağını ve gidon boğazını çıkarın; çatalı alttan tutarak '
       'aşağı çekin.',
       'Üst ve alt rulmanları çıkarın; furç kaplarını ve çatal boğazını '
       'temizleyin.',
       'Rulman yuvalarında çukurlaşma varsa kapları sökücüyle çıkarıp '
       'yenilerini presle takın.',
       'Yeni rulmanları greslenmiş yuvalara yerleştirin ve çatalı takın.',
       'Gidon boğazını ve üst kapağı takın, furç boşluğunu ayarlayın.',
   ],
   next=HEADSET_ADJUST)

dm(code=COCKPIT_CHECK, tech='Gidon ve gidon boğazı', info='Kontrol',
   figure=7, tools=[HEX, TORQUE],
   warnings=['Gidonda ya da gidon boğazında çatlak, ezik ya da kelepçe '
             'izinde derin çizik varsa parçayı değiştirin.'],
   steps=[
       'Ön tekerleği dizlerinizin arasına alıp gidonu çevirmeye çalışın; '
       'gidon boğazı çatal boğazı üzerinde kaymamalıdır.',
       'Gidonu aşağı bastırarak döndürmeye çalışın; gidon kelepçede '
       'dönmemelidir.',
       'Gidon boğazı cıvatalarını 5-6 Nm, ön kapak cıvatalarını çapraz '
       'sırayla 5-6 Nm ile kontrol edin. Ön kapakla gövde arasındaki '
       'boşluk alt ve üstte eşit olmalıdır.',
       'Gidonu kelepçe çevresinde ve kol kelepçelerinin kenarında çatlak '
       'ya da derin çizik için inceleyin.',
       'Fren ve vites kolu kelepçelerinin sıkılığını kontrol edin.',
   ])

dm(code=GRIPS, tech='Elcikler', info='Değiştirme', figure=7,
   tools=[HEX, ('Kaşık uçlu tornavida', 1)], supplies=[IPA],
   spares=[('Elcik çifti', 1)],
   steps=[
       'Kilit halkalı elcikte halka cıvatalarını gevşetip elciği çekin. '
       'Yapıştırma elcikte elciğin altına tornavidayla açıklık yapıp '
       'izopropil alkol damlatın ve elciği döndürerek çıkarın.',
       'Gidon ucunu temizleyin.',
       'Yeni elciği izopropil alkolle ıslatılmış gidona itin; alkol '
       'kuruyunca elcik tutar.',
       'Kilit halkalı elcikte cıvataları 2-3 Nm ile sıkın.',
       'Gidon uçlarında tapa olduğunu kontrol edin; açık uç düşmede yara '
       'açar.',
   ])

dm(code=LEVER_POSITION, tech='Fren ve vites kolları', info='Konum ayarı',
   figure=7, tools=[HEX, TORQUE],
   steps=[
       'Bisiklete binin, pedallarda ayakta durur gibi durun.',
       'Fren kolu kelepçesini gevşetin ve kolu, parmaklar kol üzerindeyken '
       'el bileği düz kalacak açıya getirin.',
       'Kolları gidon ucundan eşit mesafede konumlandırın; tek parmakla '
       'frenleyebilmek için kol ucuna işaret parmağı yetişmelidir.',
       'Fren kolu kelepçesini 6-8 Nm, vites kolu kelepçesini 2,5-3 Nm ile '
       'sıkın.',
       'Kol mesafe vidası (varsa) ile kolun gidona uzaklığını elinize göre '
       'ayarlayın; ardından fren kol boşluğunu kontrol edin.',
   ],
   next=BRAKE_ADJUST)

dm(code=SEAT_HEIGHT, tech='Sele', info='Yükseklik ayarı', figure=10,
   tools=[HEX],
   warnings=['Sele borusu üzerindeki en az yerleştirme çizgisi kadroya '
             'girmelidir. Çizgi görünüyorsa seleyi yükseltmeyin.'],
   steps=[
       'Sele borusu kelepçesini gevşetin.',
       'Pedal en alt noktadayken ve topuk pedalın üstündeyken bacak tam '
       'düz olacak şekilde seleyi ayarlayın.',
       'Seleyi kadroya hizalayın ve kelepçeyi kapatın. Cıvatalı kelepçede '
       '5-6 Nm ile sıkın; çabuk sökme kelepçe kapanırken avuç içinde iz '
       'bırakmalıdır.',
   ])

dm(code=SADDLE_ADJUST, tech='Sele', info='Açı ve ileri-geri ayarı',
   figure=10, tools=[HEX, TORQUE],
   steps=[
       'Sele borusu başlığındaki kelepçe cıvatasını iki-üç tur gevşetin.',
       'Seleyi raylar üzerinde kaydırın: pedal kolları yatayken öndeki '
       'dizin ön yüzünden sarkıtılan çekül pedal milinden geçmelidir.',
       'Sele yüzeyini yere paralel ayarlayın; sele ucu en fazla birkaç '
       'derece aşağı bakabilir.',
       'Kelepçe cıvatasını 20-24 Nm ile sıkın. Rayları sele üzerindeki '
       'işaretli bölgenin dışına taşımayın.',
   ])

dm(code=SEATPOST_SERVICE, tech='Sele borusu', info='Temizlik ve gresleme',
   figure=10, tools=[HEX], supplies=[GREASE, IPA, RAG],
   steps=[
       'Sele borusunun kadrodaki yüksekliğini bantla işaretleyin.',
       'Kelepçeyi açıp sele borusunu döndürerek çekin.',
       'Sele borusunu ve kadronun sele borusu ağzını izopropil alkolle '
       'temizleyin; kelepçeyi çıkarıp temizleyin.',
       'Sele borusunun kadroya giren kısmına ince bir kat gres sürün.',
       'Sele borusunu işarete kadar takın, seleyi hizalayın ve kelepçeyi '
       'kapatın.',
   ],
   next=SEAT_HEIGHT)

# Aktarma organları ------------------------------------------------------------

dm(code=DRIVE, tech='Aktarma organları', figure=2, description=[
    ('Genel', [
        'Aktarma organları aynakol ve orta göbek, zincir, kaset, ön ve arka '
        'vites değiştiriciler, vites kolları ve tellerinden oluşur.',
    ]),
    ('Vitesler', [
        'Sol vites kolu ön vites değiştiriciyi, sağ kol arka vites '
        'değiştiriciyi yönetir. Önde 3, arkada 8 dişli vardır.',
        'Zinciri aşırı çaprazlamayın: önde büyük aynada arkadaki en büyük '
        'dişli, önde küçük aynada arkadaki en küçük dişli kullanılmamalıdır. '
        'Bu durum zinciri ve dişlileri hızlı aşındırır, zincirin düşmesine '
        'yol açar.',
    ]),
    ('Ayar noktaları', [
        ('Vites değiştiricilerde üç ayar vardır:', [
            'Limit vidaları (H ve L): zincirin en küçük ve en büyük '
            'dişlinin dışına kaçmasını önler.',
            'Tel gerginliği: vites kolundaki ya da vites değiştiricideki '
            'ayar vidasıyla her tıkta bir dişli geçilmesini sağlar.',
            'B vidası (yalnız arkada): üst makaranın dişlilere uzaklığını '
            'ayarlar.',
        ]),
    ]),
    ('Aşınma', [
        'Zincir kullanıldıkça uzar. Uzamış zincir dişlileri de aşındırır; '
        'zamanında değiştirilen zincir kaseti ve aynakolu korur. 8 vitesli '
        'zincir %0,75 uzamada değiştirilir.',
    ]),
])

dm(code=SHIFT_ISOLATE, tech='Vites sistemi', info='Arıza bulma',
   isolation={
       'fault': 'NAYABIKE-DA1-002',
       'descr': 'Vites geç geçiyor, hiç geçmiyor, tıkırtı yapıyor ya da '
                'zincir düşüyor.',
       'steps': [
           ('stp-0001', 'Pedal çevirirken vitesleri önde ve arkada ayrı '
            'ayrı değiştirin.', 'Sorun ön aynalarda mı?', 'stp-0009',
            'stp-0002'),
           ('stp-0002', 'Bisikleti sehpaya alın ve arka vites '
            'değiştiriciye arkadan bakın.',
            'Makaralar dişlilerle aynı düzlemde değil mi (içe eğik mi)?',
            'stp-0003', 'stp-0004'),
           ('stp-0003', 'Vites askısını hizalama aparatıyla ölçün ve '
            'çatlak için inceleyin.',
            'Askı çatlak mı ya da düzeltme tutmuyor mu?',
            'end-hanger-replace', 'end-hanger-align'),
           ('stp-0004', 'Arka vites değiştiricinin kafesine bakın ve kafesi '
            'elle öne çekip bırakın.',
            'Kafes bükük mü ya da yay zinciri germiyor mu?', 'end-rd',
            'stp-0005'),
           ('stp-0005', 'Makaraları elle çevirip yanlara oynatın ve '
            'dişlerine bakın.',
            'Makara dişleri sivrilmiş mi ya da makarada boşluk var mı?',
            'end-jockey', 'stp-0006'),
           ('stp-0006', 'Pedal çevirirken vites kolunu en küçükten en '
            'büyüğe tek tek çekin.',
            'Zincir en küçük ya da en büyük dişlinin dışına kaçıyor mu?',
            'end-limits', 'stp-0007'),
           ('stp-0007', 'Vites kolunu çektiğinizde teldeki gerginliği ve '
            'kolun direncini hissedin.',
            'Kol sert mi ya da tel kılıfta takılıyor mu?', 'stp-0008',
            'stp-0010'),
           ('stp-0008', 'Teli kılıf dışındaki kısımlarında ve uçlarında '
            'inceleyin.', 'Tel paslı mı ya da lifleri kopuk mu?',
            'end-cable', 'end-cable-lube'),
           ('stp-0010', 'Kolu bıraktığınızda kolun ve zincirin geri '
            'dönüşünü izleyin.',
            'Kol yerine dönmüyor ya da tıklamıyor mu?', 'stp-0011',
            'end-adjust'),
           ('stp-0011', 'Teli sıkma cıvatasından çıkarıp kolu boşta '
            'çalıştırın.', 'Kol tel olmadan da takılıyor mu?',
            'end-shifter', 'end-cable'),
           ('stp-0009', 'Sol vites kolunu çekerken teldeki direnci '
            'hissedin.', 'Kol sert mi ya da tel kılıfta takılıyor mu?',
            'stp-0008', 'end-fd'),
       ],
       'ends': [
           ('end-hanger-replace', 'Vites askısını değiştirin.',
            HANGER_REPLACE),
           ('end-hanger-align', 'Askıyı hizalama aparatıyla düzeltin.',
            HANGER_CHECK),
           ('end-rd', 'Arka vites değiştiriciyi değiştirin.', RD_REPLACE),
           ('end-jockey', 'Makaraları değiştirin.', JOCKEY),
           ('end-limits', 'Limit vidalarını ayarlayın.', RD_ADJUST),
           ('end-cable', 'Vites telini ve kılıfını değiştirin.',
            SHIFT_CABLES),
           ('end-cable-lube', 'Teli temizleyip yağlayın.',
            SHIFT_CABLE_LUBE),
           ('end-shifter', 'Vites kolu arızalı; değiştirin.',
            SHIFTER_REPLACE),
           ('end-adjust', 'Tel gerginliğini ayarlayın.', RD_ADJUST),
           ('end-fd', 'Ön vites değiştiricinin konumunu, limit vidalarını '
            've tel gerginliğini ayarlayın.', FD_ADJUST),
       ],
   })

dm(code=DRIVE_CLEAN, tech='Aktarma organları', info='Temizlik', figure=2,
   tools=[STAND], supplies=[DEGREASER, RAG, LUBE],
   cautions=['Yağ çözücüyü fren disklerine ve balatalara bulaştırmayın; '
             'arka tekerleği sökerek temizlemek daha güvenlidir.'],
   steps=[
       'Bisikleti bakım sehpasına alın.',
       'Pedalı geriye çevirirken zinciri yağ çözücüye batırılmış fırçayla '
       'ya da zincir temizleme kutusuyla temizleyin.',
       'Kaset dişlilerinin arasını ve aynakol dişlerini fırçalayın.',
       'Arka vites değiştiricinin makaralarındaki kiri kazıyın.',
       'Zinciri, dişlileri ve makaraları suyla durulayıp bezle kurulayın.',
       'Zincir tamamen kuruduktan sonra yağlayın.',
   ],
   next=CHAIN_LUBE)

dm(code=CHAIN_LUBE, tech='Zincir', info='Temizlik ve yağlama', figure=2,
   tools=[STAND], supplies=[LUBE, RAG],
   cautions=['Yağın fren disklerine ve balatalara bulaşmamasına dikkat '
             'edin.'],
   steps=[
       'Bisikleti bakım sehpasına alın.',
       'Pedalı geriye çevirirken zinciri temiz bir bezle silin. Çok '
       'kirliyse zincir temizleyicisi kullanın ve kurumasını bekleyin.',
       'Pedalı geriye çevirirken her baklanın üst kısmına bir damla zincir '
       'yağı damlatın.',
       'Pedalı yirmi tur kadar çevirip vitesleri birkaç kez değiştirin.',
       'Fazla yağı bezle silin. Dışta kalan yağ toz toplar.',
   ])

dm(code=CHAIN_MEASURE, tech='Zincir', info='Aşınma ölçümü', figure=2,
   tools=[('Zincir aşınma ölçeri', 1)],
   steps=[
       'Zinciri en büyük aynaya ve en küçük arka dişliye alın.',
       'Zincir aşınma ölçerini baklalar arasına yerleştirin.',
       'Ölçer %0,5 işaretinde baklaya tam oturuyorsa zincir yakında '
       'değiştirilmelidir. %0,75 işaretinde oturuyorsa zinciri hemen '
       'değiştirin.',
       'Zincir %0,75 aşınmış ve yeni zincir arka dişlilerde atlıyorsa kaset '
       'de aşınmıştır; kaseti de değiştirin.',
       'Baklaları tek tek bükerek kontrol edin. Sıkışmış bakla varsa '
       'yağlayın, açılmıyorsa zinciri değiştirin.',
   ],
   next=CHAIN_REMOVE)

dm(code=CHAIN_REMOVE, tech='Zincir', info='Sökme', figure=2,
   tools=[('Zincir sökme aparatı', 1)],
   warnings=['Zincir kenarları keskin olabilir; eldiven takın.'],
   steps=[
       'Zinciri en küçük aynaya ve en küçük arka dişliye alın; zincir '
       'gerginliği azalır.',
       ('Pimi çıkarın', [
           'Zincir sökme aparatını zincirin alt kolundaki bir baklaya '
           'yerleştirin.',
           'Aparat kolunu pim baklanın dış plakasından çıkana kadar '
           'çevirin. Çıkan pim yeniden kullanılmaz.',
           'Baklayı bükerek zinciri ayırın.',
       ]),
       'Zinciri dişlilerden ve vites değiştiricilerden çekerek çıkarın.',
   ],
   next=CHAIN_INSTALL)

dm(code=CHAIN_INSTALL, tech='Zincir', info='Takma', figure=2,
   tools=[('Zincir sökme aparatı', 1)],
   spares=[('Zincir, 8 vites', 1),
           ('Zincir bağlantı pimi, 6-8 vites', 1)],
   cautions=['Shimano HG zincirde sökülen pimi geri itmeyin; pim yuvası '
             'genişler ve zincir kopabilir. Her zaman yeni bağlantı pimi '
             'ya da 8 vites bağlantı baklası kullanın.'],
   steps=[
       'Yeni zinciri eskisiyle yan yana koyup aynı bakla sayısında '
       'kısaltın. Eski zincir yoksa: zinciri en büyük aynadan ve en büyük '
       'arka dişliden vites değiştiriciye uğramadan geçirin, iki bakla '
       'ekleyerek kesin.',
       'Zinciri aynadan, arka dişliden ve arka vites değiştiricinin iki '
       'makarası arasından geçirin. Makaralar arasındaki metal dile '
       'değmemelidir.',
       'Zincirin uçlarını birleştirin. Yeni bağlantı pimini kılavuz '
       'ucundan baklaya sokup aparatla, pim iki yandan eşit çıkana kadar '
       'itin; çıkıntı yapan kılavuz ucunu pensle kırın. Bağlantı baklası '
       'kullanılıyorsa iki yarıyı takıp pedala yüklenerek kilitleyin.',
       'Birleşen baklayı yanlara bükerek gevşetin; sıkışık kalmamalıdır.',
       'Bütün vitesleri deneyin.',
   ],
   next=CHAIN_LUBE)

dm(code=CHAIN_ISOLATE, tech='Zincir', info='Arıza bulma: zincir atlıyor',
   isolation={
       'fault': 'NAYABIKE-DA1-001',
       'descr': 'Pedala yüklenince zincir boşa atlıyor ya da dişlilerden '
                'düşüyor.',
       'steps': [
           ('stp-0001', 'Zincir aşınmasını ölçerle ölçün.',
            'Zincir %0,75 ya da daha fazla uzamış mı?', 'end-chain',
            'stp-0002'),
           ('stp-0002', 'Pedalı geriye yavaşça çevirirken zincirin arka '
            'vites değiştiriciden geçişini izleyin.',
            'Bir bakla makaralardan geçerken sıçrıyor mu?', 'end-link',
            'stp-0003'),
           ('stp-0003', 'Atlamanın hangi dişlide olduğunu bulun ve o '
            'dişlinin dişlerine bakın.',
            'Dişler sivrilmiş ya da kancalanmış mı?', 'stp-0004',
            'end-adjust'),
           ('stp-0004', 'Atlama arka dişlide mi, öndeki aynada mı olduğuna '
            'bakın.', 'Atlama arka dişlide mi?', 'end-cassette',
            'end-chainring'),
       ],
       'ends': [
           ('end-chain', 'Zinciri değiştirin; yeni zincir atlarsa kaseti de '
            'değiştirin.', CHAIN_REMOVE),
           ('end-link', 'Sıkışmış baklayı yağlayıp yanlara bükerek açın; '
            'açılmıyorsa zinciri değiştirin.', CHAIN_LUBE),
           ('end-adjust', 'Dişliler sağlam: vites ayarını yapın.',
            SHIFT_ISOLATE),
           ('end-cassette', 'Kaseti değiştirin.', CASSETTE),
           ('end-chainring', 'Aşınmış aynayı değiştirin.', CHAINRING),
       ],
   })

dm(code=FD_ADJUST, tech='Ön vites değiştirici', info='Ayar', figure=14,
   tools=[HEX, STAND, TORQUE],
   steps=[
       'Kafesin dış plakası en büyük aynanın dişlerinin 1-3 mm üstünde ve '
       'aynaya paralel olmalıdır; değilse kelepçeyi gevşetip düzeltin ve '
       '5-7 Nm ile sıkın.',
       'Zinciri en küçük aynaya ve arkada en büyük dişliye alın.',
       'Alt limit vidasını (L) zincirle iç kafes plakası arasında 0,5 mm '
       'boşluk kalacak şekilde ayarlayın.',
       'Zinciri en büyük aynaya ve arkada en küçük dişliye alın.',
       'Üst limit vidasını (H) zincirle dış kafes plakası arasında 0,5 mm '
       'boşluk kalacak şekilde ayarlayın.',
       'Orta aynaya geçiş yavaşsa sol vites kolundaki ayar vidasını saat '
       'yönünün tersine yarım tur çevirerek teli gerin.',
       'Bütün vitesleri deneyin; zincir aynadan dışarı düşmemelidir.',
   ])

dm(code=CRANK_CHECK, tech='Aynakol ve orta göbek', info='Kontrol',
   figure=8, tools=[HEX, TORQUE],
   steps=[
       'Pedal kollarını kadroya dik tutun ve iki kolu birlikte yanlara '
       'itin. Boşluk varsa orta göbek gevşemiş ya da aşınmıştır.',
       'Zinciri aynadan indirip pedal kollarını çevirin. Dönüş pürüzlü ya '
       'da sesliyse orta göbek değiştirilmelidir.',
       'Aynakol dişlerinin köpekbalığı yüzgeci gibi sivrilip sivrilmediğine '
       'bakın. Sivrilmiş dişler zincirin atlamasına yol açar.',
       'Pedal kolu cıvatalarını 35-50 Nm, aynakol cıvatalarını 8-11 Nm ile '
       'kontrol edin.',
       'Aynaların eğri olup olmadığını, kol dönerken ön vites '
       'değiştiricinin kafesine bakarak kontrol edin.',
   ])

dm(code=CRANK_ISOLATE, tech='Aynakol ve orta göbek',
   info='Arıza bulma', isolation={
       'fault': 'NAYABIKE-DA1-003',
       'descr': 'Pedala basarken gıcırtı geliyor, pedal kolu boşluk '
                'yapıyor ya da zincir aynadan atlıyor.',
       'steps': [
           ('stp-0001', 'Pedal kollarını kadroya dik tutun ve iki kolu '
            'birlikte yanlara itin.', 'Boşluk var mı?', 'stp-0002',
            'stp-0003'),
           ('stp-0002', 'Pedal kolu cıvatalarını 35-50 Nm ile sıkın ve '
            'kolları yeniden yanlara itin.', 'Boşluk sürüyor mu?',
            'end-bb', 'end-crank'),
           ('stp-0003', 'Zinciri aynadan indirip pedal kollarını çevirin.',
            'Dönüş pürüzlü ya da sesli mi?', 'end-bb', 'stp-0004'),
           ('stp-0004', 'Aynaların dişlerine bakın.',
            'Dişler sivrilmiş ya da kancalanmış mı?', 'end-chainring',
            'end-check'),
       ],
       'ends': [
           ('end-bb', 'Orta göbeği değiştirin.', BOTTOM_BRACKET),
           ('end-crank', 'Kol gevşemişti. Kolu söküp kare yuvasının '
            'bozulmadığını kontrol edin ve yeniden takın.', CRANK_ARMS),
           ('end-chainring', 'Aşınmış aynayı değiştirin.', CHAINRING),
           ('end-check', 'Aynakolu ve orta göbeği ayrıntılı kontrol edin.',
            CRANK_CHECK),
       ],
   })

dm(code=CRANK_ARMS, tech='Pedal kolları', info='Sökme ve takma', figure=8,
   tools=[HEX, TORQUE, ('Pedal kolu çektirmesi (kare göbek)', 1)],
   supplies=[GREASE],
   cautions=['Kare göbekli milin konik yüzeyine gres sürmeyin; kol mile '
             'fazla girer ve alüminyum kol bozulur.'],
   steps=[
       'Zinciri aynadan indirin.',
       'Pedal kolu cıvatasını 8 mm alyanla sökün.',
       'Çektirmenin gövdesini kolun dişlerine sonuna kadar elle vidalayın.',
       'Çektirmenin milini anahtarla çevirerek kolu orta göbek milinden '
       'çekin.',
       'Takarken mil ve kol yuvasını temizleyin, cıvata dişine gres sürün.',
       'Kolu karşı kolun 180° tersine gelecek şekilde mile takın ve '
       'cıvatayı 35-50 Nm ile sıkın.',
       'İlk 50 km sonra cıvatayı yeniden sıkın.',
   ])

dm(code=BOTTOM_BRACKET, tech='Orta göbek', info='Değiştirme', figure=8,
   tools=[HEX, TORQUE, ('Orta göbek anahtarı (kartuş tipi)', 1),
          ('Pedal kolu çektirmesi (kare göbek)', 1)],
   supplies=[GREASE, RAG],
   spares=[('Orta göbek kartuşu, kare mil', 1)],
   cautions=['Sağ (zincir tarafı) kap BSA dişlidir ve ters yönde sökülür: '
             'saat yönünde çevrilince gevşer.'],
   steps=[
       'Pedal kollarını sökün.',
       'Sol kabı saat yönünün tersine, sağ kabı saat yönünde çevirerek '
       'sökün ve kartuşu çıkarın.',
       'Orta göbek gövdesinin dişlerini temizleyin ve çatlak için '
       'inceleyin.',
       'Yeni kartuşun ve kapların dişlerine gres sürün.',
       'Kartuşu sağ taraftan takıp sağ kabı 50-70 Nm ile sıkın, sonra sol '
       'kabı takıp aynı torkla sıkın.',
       'Pedal kollarını takın ve milin boşluksuz döndüğünü kontrol edin.',
   ],
   next=CRANK_ARMS)

dm(code=CHAINRING, tech='Ayna', info='Değiştirme', figure=8,
   tools=[HEX, TORQUE, ('Kaşık uçlu tornavida', 1)],
   supplies=[GREASE],
   spares=[('Ayna, 42 diş', 1)],
   steps=[
       'Zinciri aynadan indirin. Büyük ve orta aynalar için sağ pedal '
       'kolunu sökmek işi kolaylaştırır.',
       'Aynakol cıvatalarını arkadan somun anahtarıyla tutarak sökün.',
       'Eski aynayı çıkarın. Yeni aynayı, zincir pimi (çıkıntı) pedal '
       'kolunun arkasına gelecek şekilde konumlayın.',
       'Cıvata dişlerine gres sürüp cıvataları çapraz sırayla 8-11 Nm ile '
       'sıkın.',
       'Ön vites değiştirici ayarını kontrol edin.',
   ],
   next=FD_ADJUST)

dm(code=CASSETTE, tech='Kaset', info='Değiştirme', figure=9,
   tools=[('Kaset sökme aparatı ve zincir kırbacı', 1), TORQUE],
   spares=[('Kaset, 8 dişli', 1)],
   steps=[
       'Arka tekerleği sökün.',
       ('Eski kaseti sökün', [
           'Kaset sökme aparatını kilit somunu dişlerine yerleştirin.',
           'Zincir kırbacıyla kaseti tutarken aparatı anahtarla saat '
           'yönünün tersine çevirip kilit somununu çıkarın.',
           'Dişlileri ve ara pulları sırasını bozmadan çıkarın.',
       ]),
       ('Yeni kaseti takın', [
           'Dişlileri göbek gövdesindeki geniş kanala hizalayarak büyükten '
           'küçüğe doğru yerleştirin.',
           'Kilit somununu aparatla 30-50 Nm ile sıkın.',
       ]),
       'Tekerleği takın ve vites ayarını kontrol edin.',
   ],
   next=[WHEEL_INSTALL, RD_ADJUST])

dm(code=CASSETTE_CHECK, tech='Kaset', info='Kontrol', figure=9,
   tools=[('Kaset sökme aparatı ve zincir kırbacı', 1), TORQUE],
   steps=[
       'Kaseti elle yanlara oynatın. Kaset göbek üzerinde oynuyorsa kilit '
       'somunu gevşemiştir; 30-50 Nm ile sıkın.',
       'En çok kullanılan dişlilerin dişlerine bakın. Kancalanmış ya da '
       'sivrilmiş dişler aşınmayı gösterir.',
       'Dişlilerin arasındaki kiri ve çalı parçalarını temizleyin.',
       'Pedalı geriye çevirin; kaset zinciri sürüklemeden boşa dönmelidir. '
       'Sürüklüyorsa serbest çarkı kontrol edin.',
   ])

dm(code=RD_ADJUST, tech='Arka vites değiştirici', info='Ayar', figure=4,
   tools=[HEX, STAND],
   steps=[
       'Sağ vites kolunu en küçük dişliye alın.',
       'Üst limit vidasını (H) üst makara en küçük dişlinin tam altında '
       'olacak şekilde ayarlayın.',
       'Pedalı çevirirken vitesleri tek tek büyütün. Zincir bir üst '
       'dişliye geç çıkıyorsa vites kolundaki ayar vidasını saat yönünün '
       'tersine çeyrek tur çevirin; bir sonraki dişliye kaçıyorsa saat '
       'yönünde çevirin.',
       'En büyük dişliye geçin. Alt limit vidasını (L) zincir tellere '
       'değmeden en büyük dişliye çıkacak şekilde ayarlayın.',
       'B vidasını üst makara en büyük dişliye 5-6 mm yaklaşacak şekilde '
       'ayarlayın.',
       'Ayar tutmuyorsa vites askısının eğri olup olmadığını kontrol edin.',
   ],
   next=HANGER_CHECK)

dm(code=HANGER_CHECK, tech='Vites askısı', info='Gözle kontrol', figure=4,
   tools=[('Vites askısı hizalama aparatı', 1)],
   warnings=['Eğri askıyla büyük dişliye geçmek vites değiştiricinin '
             'tellere kaçmasına ve tekerleğin kilitlenmesine yol açabilir.'],
   steps=[
       'Zinciri en büyük arka dişliye alın.',
       'Bisikletin arkasından bakın: vites değiştiricinin iki makarası '
       'dişliyle aynı düzlemde olmalıdır.',
       'Makaralar içe doğru eğikse askı bükülmüştür. Hizalama aparatıyla '
       'jantın dört noktasında ölçerek düzeltin; fark 4 mm\'nin altında '
       'olmalıdır.',
       'Askıda çatlak varsa ya da düzeltme tutmuyorsa askıyı değiştirin.',
   ],
   next=RD_ADJUST)

dm(code=RD_REPLACE, tech='Arka vites değiştirici', info='Sökme ve takma',
   figure=4, tools=[HEX, TORQUE, ('Zincir sökme aparatı', 1), CUTTER],
   spares=[('Arka vites değiştirici, 8 vites', 1)],
   steps=[
       'Vites telini sıkma cıvatasından çıkarın.',
       'Zinciri sökün ya da alt makarayı çıkarıp zinciri kafesten alın.',
       'Bağlantı cıvatasını 5 mm alyanla sökün ve vites değiştiriciyi '
       'askıdan çıkarın.',
       'Yeni vites değiştiriciyi, B vidası askının durdurucusunun arkasına '
       'gelecek şekilde takıp bağlantı cıvatasını 8-10 Nm ile sıkın.',
       'Zinciri kafesten geçirin ve takın.',
       'Teli takıp 5-7 Nm ile sıkın ve ayarı yapın.',
   ],
   next=RD_ADJUST)

dm(code=HANGER_REPLACE, tech='Vites askısı', info='Değiştirme', figure=4,
   tools=[HEX, TORQUE],
   spares=[('Vites askısı', 1)],
   steps=[
       'Arka tekerleği sökün.',
       'Arka vites değiştiriciyi askıdan sökün; tele ve zincire dokunmadan '
       'yana asın.',
       'Askı cıvatalarını sökün ve askıyı çıkarın.',
       'Askı yuvasını temizleyin. Yeni askıyı yerine oturtup cıvatalarını '
       'askı üreticisinin değeriyle (genellikle 1,5-2,5 Nm) sıkın.',
       'Vites değiştiriciyi takın, tekerleği takın ve ayarı yapın.',
   ],
   next=RD_ADJUST)

dm(code=JOCKEY, tech='Makaralar', info='Değiştirme', figure=4,
   tools=[HEX, TORQUE], supplies=[GREASE],
   spares=[('Makara takımı, 11 diş', 1)],
   steps=[
       'Alt makaranın cıvatasını sökün ve makarayı çıkarın; zincir kafesten '
       'serbest kalır.',
       'Üst makaranın cıvatasını sökün ve makarayı çıkarın. Üst ve alt '
       'makara farklı olabilir; yönlerini not edin.',
       'Yeni makaraları ok işareti zincirin dönüş yönüne bakacak şekilde '
       'takın; cıvata dişlerine gres sürüp 3-4 Nm ile sıkın.',
       'Zincirin makaralardan doğru geçtiğini kontrol edin.',
   ],
   next=RD_ADJUST)

dm(code=PEDALS, tech='Pedallar', info='Sökme ve takma',
   tools=[('15 mm pedal anahtarı', 1), TORQUE],
   supplies=[GREASE],
   spares=[('Pedal takımı', 1)],
   warnings=['Sol pedal ters dişlidir. Sağ pedal saat yönünün tersine, sol '
             'pedal saat yönünde çevrilerek sökülür.'],
   steps=[
       'Pedal anahtarını pedal milinin düz yüzeylerine takın.',
       'Pedalları sökün.',
       'Pedal mili dişlerine ince bir kat gres sürün.',
       'R işaretli pedalı sağ kola, L işaretli pedalı sol kola elle '
       'başlatıp takın; dişler zorlanmadan girmelidir.',
       'Pedalları 35 Nm ile sıkın.',
   ])

dm(code=PEDAL_SERVICE, tech='Pedal rulmanları', info='Bakım',
   tools=[('15 mm pedal anahtarı', 1), ('Kaşık uçlu tornavida', 1)],
   supplies=[GREASE, DEGREASER, RAG],
   steps=[
       'Pedalı koldan sökün.',
       'Toz kapağını tornavidayla çıkarın; kontra somununu ve koniyi '
       'sökün, bilyaları bir kaba toplayın.',
       'Mil, koni ve bilya yuvalarını yağ çözücüyle temizleyin; '
       'çukurlaşma varsa pedalı değiştirin.',
       'Yuvalara gres doldurup bilyaları yerleştirin.',
       'Koniyi boşluk kalmayacak ama mil sıkışmadan dönecek şekilde '
       'ayarlayın ve kontra somununu sıkın.',
       'Toz kapağını takın ve pedalı kola takın.',
   ],
   next=PEDALS)

dm(code=SHIFT_CABLES, tech='Vites teli ve kılıfı', info='Değiştirme',
   figure=13, tools=[HEX, TORQUE, CUTTER],
   supplies=[LUBE, ('Kablo ucu kapağı', 2)],
   spares=[('Vites teli ve kılıfı takımı', 1)],
   steps=[
       'Vites kolunu en küçük dişliye (arka) ya da en küçük aynaya (ön) '
       'alın.',
       'Tel ucu kapağını kesin ve teli sıkma cıvatasından çıkarın.',
       'Teli vites kolundan çekerek çıkarın; eski kılıfları ölçü için '
       'saklayın.',
       'Yeni kılıfları eskileriyle aynı boyda kesin; uçları düz ve açık '
       'olmalı, kılıf uçlarına yüksük takın.',
       'Yeni teli koldan geçirip kılıflardan ve kadro kılavuzlarından '
       'geçirin; tele bir damla yağ sürün.',
       'Teli elle gerip sıkma cıvatasını 5-7 Nm ile sıkın; fazlasını 3 cm '
       'bırakıp kesin ve kapak takın.',
       'Teli birkaç kez sertçe çekip yerine oturtun ve vites ayarını '
       'yapın.',
   ],
   next=RD_ADJUST)

dm(code=SHIFTER_CHECK, tech='Vites kolları', info='Kontrol', figure=7,
   tools=[HEX, TORQUE],
   steps=[
       'Vites kollarını sehpada, pedal çevirirken tek tek çalıştırın. Her '
       'tıkta bir vites geçmeli ve kol yerine dönmelidir.',
       'Teli sıkma cıvatasından çıkarıp kolu boşta çalıştırın. Kol hâlâ '
       'takılıyorsa vites kolu arızalıdır.',
       'Kol takılmıyorsa tel ya da kılıf sürtünüyordur; teli ve kılıfı '
       'değiştirin.',
       'Vites kolu kelepçesini 2,5-3 Nm ile kontrol edin.',
   ],
   next=SHIFT_CABLES)

dm(code=SHIFTER_REPLACE, tech='Vites kolu', info='Değiştirme', figure=7,
   tools=[HEX, TORQUE, CUTTER],
   spares=[('Tetik vites kolu, sağ 8 vites', 1)],
   steps=[
       'Vites telini sıkma cıvatasından çıkarın ve koldan çekin.',
       'Elciği ve fren kolunu gerekiyorsa sökün; vites kolu kelepçesini '
       'gevşetip kolu gidondan çıkarın.',
       'Yeni kolu takın, konumunu ayarlayıp kelepçeyi 2,5-3 Nm ile sıkın.',
       'Yeni tel takın ve vites ayarını yapın.',
   ],
   next=SHIFT_CABLES)

dm(code=SHIFT_CABLE_LUBE, tech='Vites telleri', info='Temizlik ve yağlama',
   figure=13, supplies=[LUBE, RAG],
   steps=[
       'Arka vites kolunu en büyük dişliye alın, sonra pedal çevirmeden '
       'kolu en küçüğe bırakın; tel gevşer.',
       'Kılıfları kadro kılavuzlarındaki yuvalarından çıkarın.',
       'Açıkta kalan teli bezle silin ve kılıfa giren kısmına ince yağ '
       'sürün.',
       'Kılıfları yerine takın ve vitesleri deneyin.',
   ])

# Fren sistemi -----------------------------------------------------------------

dm(code=BRAKES, tech='Fren sistemi', figure=3, description=[
    ('Genel', [
        'Bisiklette iki adet telle çalışan (mekanik) disk fren vardır. Sol '
        'kol ön freni, sağ kol arka freni çalıştırır.',
    ]),
    ('Çalışma', [
        'Kol çekilince fren teli kaliperdeki kolu döndürür. Dış balata '
        'diske doğru itilir, disk iç balataya bastırılır ve tekerlek '
        'yavaşlar.',
        'Balatalar aşındıkça kol boşluğu artar; bu boşluk kaliperdeki iç '
        'balata ayar düğmesi ve fren kolundaki ayar vidasıyla alınır.',
    ]),
    ('Aşınma sınırları', [
        ('Ölçüler:', [
            'Balata sürtünme malzemesi: en az 0,5 mm (çelik taban hariç).',
            'Disk kalınlığı: en az 1,5 mm (yenisi 1,8 mm).',
            'Kol boşluğu: kol, gidona 2 cm\'den fazla yaklaşmamalı.',
        ]),
    ]),
    ('Uyarı', [
        'Disk ve balatalara yağ, sprey ya da el yağı bulaşırsa fren gücü '
        'büyük ölçüde düşer. Diske çıplak elle dokunmayın.',
    ]),
])

dm(code=BRAKE_CHECK, tech='Fren sistemi', info='Kontrol', figure=3,
   tools=[STAND, ('Kumpas', 1)],
   steps=[
       'Her iki fren kolunu sıkın. Kollar gidona 2 cm\'den fazla '
       'yaklaşmadan sertleşmelidir.',
       'Bisikleti iterek frenleri ayrı ayrı deneyin; ön fren tekerleği '
       'kilitlemeli, arka fren tekerleği kaydırmalıdır.',
       'Balata kalınlığını kaliperin üstünden bakarak kontrol edin.',
       'Disklerin kalınlığını kumpasla ölçün ve eğrilik için tekerleği '
       'çevirin.',
       'Fren tellerinde kopuk lif, paslanma ya da kılıfta ezik olup '
       'olmadığına bakın.',
       'Kaliper ve disk cıvatalarının sıkılığını kontrol edin.',
   ])

dm(code=BRAKE_ADJUST, tech='Disk fren', info='Ayar', figure=3,
   tools=[HEX, TORX, TORQUE],
   steps=[
       'Kaliperi kadroya bağlayan iki cıvatayı hafifçe gevşetin.',
       'Fren kolunu sıkılı tutun; kaliper kendini diske ortalar. Kol '
       'sıkılıyken cıvataları 6-8 Nm ile sıkın.',
       'Kaliperdeki iç balata ayar düğmesini balata diske neredeyse değene '
       'kadar çevirin, sonra çeyrek tur geri alın.',
       'Fren kolundaki ayar vidasını saat yönünün tersine çevirerek teli '
       'gerin; kol gidona 2 cm\'den fazla yaklaşmamalıdır.',
       'Tekerleği çevirin; disk balatalara sürtmemelidir.',
   ])

dm(code=BRAKE_ISOLATE, tech='Fren sistemi', info='Arıza bulma', isolation={
    'fault': 'NAYABIKE-DA2-001',
    'descr': 'Fren yeterince tutmuyor, kol gidona kadar geliyor ya da '
             'frenlerken ciyaklama sesi geliyor.',
    'steps': [
        ('stp-0001', 'Kaliperin içine bakarak balata kalınlığını ölçün.',
         "Balata sürtünme malzemesi 0,5 mm'den ince mi?", 'end-pads',
         'stp-0002'),
        ('stp-0002', 'Diskte yağ lekesi, cam gibi parlama ya da renk '
         'değişimi olup olmadığına bakın.',
         'Disk ya da balata yağlanmış mı?', 'end-clean', 'stp-0003'),
        ('stp-0003', 'Fren kolunu sıkın ve kol ile gidon arasındaki '
         'mesafeyi ölçün.',
         "Kol gidona 2 cm'den fazla yaklaşıyor mu?", 'end-adjust',
         'stp-0004'),
        ('stp-0004', 'Tekerleği çevirerek diskin kaliperden geçişini '
         'izleyin.',
         'Disk kaliper içinde yalpalıyor ya da balatalara sürtüyor mu?',
         'end-rotor', 'stp-0006'),
        ('stp-0006', 'Kaliperi elle tutup oynatın.',
         'Kaliper ya da adaptörü oynuyor mu?', 'end-caliper', 'stp-0005'),
        ('stp-0005', 'Diskin kalınlığını kumpasla ölçün.',
         "Disk 1,5 mm'den ince mi?", 'end-rotor-worn', 'end-shop'),
    ],
    'ends': [
        ('end-pads', 'Balataları değiştirin.', PADS),
        ('end-clean', 'Diski izopropil alkolle temizleyin. Yağlanmış '
         'balatalar temizlenemez; değiştirin.', PADS),
        ('end-adjust', 'Fren telini ve kaliperi ayarlayın.', BRAKE_ADJUST),
        ('end-rotor', 'Diski düzeltin; belirgin eğri disk '
         'değiştirilmelidir.', ROTOR_TRUE),
        ('end-caliper', 'Kaliperi ve adaptörünü söküp vida sabitleyiciyle '
         'yeniden takın.', CALIPER),
        ('end-rotor-worn', 'Diski değiştirin.', ROTOR_REPLACE),
        ('end-shop', 'Fren teli kılıfı ezilmiş ya da kaliper arızalı '
         'olabilir; fren kolu ve teli için arıza bulmaya geçin, sorun '
         'sürerse yetkili servise başvurun.', BRAKE_LEVER_ISOLATE),
    ],
})

dm(code=PADS, tech='Fren balatası', info='Değiştirme', figure=3,
   tools=[HEX],
   spares=[('Fren balatası çifti', 1)],
   warnings=['Balata tozu solunmamalı; kaliperi basınçlı havayla '
             'temizlemeyin.'],
   steps=[
       'Tekerleği sökün.',
       ('Eski balataları çıkarın', [
           'Kaliperdeki balata pimi emniyet klipsini çıkarın ve pimi '
           'çekin.',
           'Balataları ve yayı kaliperin üstünden çekerek çıkarın.',
       ]),
       'Balata kalınlığını ölçün; sürtünme malzemesi 0,5 mm\'den inceyse ya '
       'da yağlanmışsa yenilerini takın.',
       ('Yeni balataları takın', [
           'Balataları yayla birlikte kaliperin üstünden yerleştirin.',
           'Balata pimini takın ve emniyet klipsini geçirin.',
       ]),
       'Tekerleği takın ve kaliperi ayarlayın.',
       ('Balataları alıştırın', [
           'Bisikletle düz bir yolda orta hızla gidin ve durmadan freni '
           'yavaşça sıkın.',
           'Bunu on kez tekrarlayın; yeni balatalar ancak alıştırıldıktan '
           'sonra tam güçle tutar.',
       ]),
   ],
   next=BRAKE_ADJUST)

dm(code=PAD_MEASURE, tech='Fren balatası', info='Kalınlık ölçümü', figure=3,
   tools=[('Kumpas', 1), HEX],
   steps=[
       'Tekerleği sökün ve balataları kaliperden çıkarın.',
       'Sürtünme malzemesinin kalınlığını çelik tabandan ayrı olarak dört '
       'köşeden ölçün.',
       'En ince nokta 0,5 mm\'nin altındaysa ya da iki balata arasında '
       'belirgin fark varsa balataları değiştirin.',
       'Sürtünme yüzeyinde çatlak, kopma ya da yağ lekesi varsa balataları '
       'değiştirin.',
   ],
   next=PADS)

dm(code=BRAKE_CLEAN, tech='Disk ve balata', info='Temizlik', figure=3,
   tools=[HEX, TORX], supplies=[IPA, RAG],
   warnings=['Yağlanmış balatalarla sürüş yapmayın. Organik balatalar yağı '
             'emer ve temizlenemez.'],
   steps=[
       'Tekerleği sökün ve balataları çıkarın.',
       'Diski izopropil alkolle ıslatılmış temiz, tüy bırakmayan bir bezle '
       'iki yüzünden silin ve kurumasını bekleyin.',
       'Kaliperin içini izopropil alkolle silin.',
       'Balatalar yağlanmışsa değiştirin; yalnız tozlanmışsa yüzeylerini '
       'ince zımparayla düzleştirin.',
       'Balataları ve tekerleği takın, balataları yeniden alıştırın.',
   ],
   next=PADS)

dm(code=CALIPER, tech='Fren kaliperi', info='Sökme ve takma', figure=12,
   tools=[HEX, TORQUE, CUTTER],
   supplies=[('Orta güçte vida sabitleyici', None)],
   spares=[('Mekanik disk kaliper', 1)],
   steps=[
       'Fren telini kaliperdeki sıkma cıvatasından çıkarın.',
       'Kaliper bağlantı cıvatalarını sökün ve kaliperi adaptörüyle '
       'birlikte çıkarın.',
       'Takarken cıvata dişlerine vida sabitleyici sürün ve kaliperi '
       'gevşek takın.',
       'Fren telini takıp sıkma cıvatasını 6-8 Nm ile sıkın.',
       'Kaliperi ortalayıp cıvataları 6-8 Nm ile sıkın.',
   ],
   next=BRAKE_ADJUST)

dm(code=ROTOR_CHECK, tech='Fren diski', info='Kontrol', figure=3,
   tools=[TORX, TORQUE, ('Kumpas', 1)],
   steps=[
       'Diskin kalınlığını kumpasla ölçün. 1,5 mm\'den inceyse diski '
       'değiştirin.',
       'Tekerleği çevirirken diskin kaliper içindeki salınımına bakın. Disk '
       'bir noktada balatalara sürtüyorsa eğridir.',
       'Hafif eğrilikleri disk düzeltme anahtarıyla düzeltin. Belirgin eğri '
       'disk değiştirilmelidir.',
       'Disk cıvatalarının sıkılığını kontrol edin (2-4 Nm).',
   ])

dm(code=ROTOR_TRUE, tech='Fren diski', info='Düzeltme', figure=3,
   tools=[('Disk düzeltme anahtarı', 1)], supplies=[IPA, RAG],
   steps=[
       'Tekerleği takılı bırakın. Kaliperin arkasına beyaz bir kâğıt '
       'tutarak diskle balata arasındaki boşluğu görün.',
       'Tekerleği yavaşça çevirin ve diskin balataya yaklaştığı noktayı '
       'bulun.',
       'Düzeltme anahtarını o noktada diskin kenarına takın ve diski ters '
       'yöne çok az bükün.',
       'Disk her iki balataya da değmeden dönene kadar tekrarlayın.',
       'Diski izopropil alkolle silin; elinizin yağı bulaşmış olabilir.',
   ])

dm(code=ROTOR_REPLACE, tech='Fren diski', info='Değiştirme', figure=3,
   tools=[TORX, TORQUE],
   supplies=[('Orta güçte vida sabitleyici', None), IPA, RAG],
   spares=[('Fren diski, 160 mm', 1)],
   steps=[
       'Tekerleği sökün.',
       'Altı disk cıvatasını T25 anahtarla sökün ve diski çıkarın.',
       'Göbekteki disk yüzeyini temizleyin.',
       'Yeni diski, üzerindeki ok tekerleğin dönüş yönüne bakacak şekilde '
       'takın.',
       'Cıvatalara vida sabitleyici sürün ve çapraz sırayla 2-4 Nm ile '
       'sıkın.',
       'Diski izopropil alkolle silin, tekerleği takın ve balataları yeni '
       'diske alıştırın.',
   ],
   next=WHEEL_INSTALL)

dm(code=BRAKE_CABLES, tech='Fren teli ve kılıfı', info='Değiştirme',
   figure=13, tools=[HEX, TORQUE, CUTTER],
   supplies=[LUBE, ('Kablo ucu kapağı', 2)],
   spares=[('Fren teli ve kılıfı takımı', 1)],
   warnings=['Fren teli kılıfı yerine vites kılıfı kullanmayın; vites '
             'kılıfı frenleme kuvvetinde ezilebilir.'],
   steps=[
       'Tel ucu kapağını kesin, teli kaliperdeki sıkma cıvatasından çıkarın.',
       'Fren kolundaki ayar vidasının yarığını hizalayıp tel başını koldan '
       'çıkarın ve teli çekin.',
       'Yeni kılıfı eskisiyle aynı boyda kesin, uçlarına yüksük takın.',
       'Yeni teli koldan ve kılıftan geçirin; tele ince yağ sürün.',
       'Kaliperdeki kolu elle diske doğru itip teli gerin ve sıkma '
       'cıvatasını 6-8 Nm ile sıkın.',
       'Kolu birkaç kez sertçe sıkıp teli oturtun, fazlasını kesip kapak '
       'takın.',
   ],
   next=BRAKE_ADJUST)

dm(code=BRAKE_LEVER, tech='Fren kolu', info='Değiştirme', figure=7,
   tools=[HEX, TORQUE],
   spares=[('Fren kolu', 1)],
   steps=[
       'Fren telini kaliperden çıkarın ve koldan çekin.',
       'Elciği sökün, fren kolu kelepçesini gevşetip kolu gidondan '
       'çıkarın.',
       'Yeni kolu takıp konumunu ayarlayın ve kelepçeyi 6-8 Nm ile sıkın.',
       'Teli takın.',
   ],
   next=BRAKE_CABLES)

dm(code=BRAKE_LEVER_ISOLATE, tech='Fren kolları ve telleri',
   info='Arıza bulma', isolation={
       'fault': 'NAYABIKE-DA2-002',
       'descr': 'Fren kolu sert çalışıyor ya da bırakınca yerine dönmüyor.',
       'steps': [
           ('stp-0001', 'Fren telini kaliperdeki sıkma cıvatasından çıkarın '
            've kolu boşta çalıştırın.', 'Kol tel olmadan da takılıyor mu?',
            'end-lever', 'stp-0002'),
           ('stp-0002', 'Teli kılıf içinde ileri geri çekin ve kılıfı '
            'boydan boya inceleyin.',
            'Tel takılıyor mu, paslı mı ya da kılıf ezik mi?', 'end-cable',
            'end-caliper'),
       ],
       'ends': [
           ('end-lever', 'Kol pivotuna yağ damlatın; düzelmezse fren kolunu '
            'değiştirin.', BRAKE_LEVER),
           ('end-cable', 'Fren telini ve kılıfını değiştirin.',
            BRAKE_CABLES),
           ('end-caliper', 'Tel ve kol sağlam: kaliper kolu takılıyor '
            'olabilir; kaliperi söküp kontrol edin.', CALIPER),
       ],
   })

dm(code=BRAKE_LEVER_CHECK, tech='Fren kolları ve telleri', info='Kontrol',
   figure=13, tools=[HEX, TORQUE], supplies=[LUBE],
   steps=[
       'Fren kollarını sıkıp bırakın. Kol çabuk ve tam olarak geri '
       'dönmelidir.',
       'Kol dönüşü yavaşsa teli kaliperden çıkarıp kolu boşta çalıştırın. '
       'Kol hâlâ yavaşsa pivotuna yağ damlatın; düzelmezse kolu değiştirin.',
       'Kol rahat dönüyorsa tel ya da kılıf sürtünüyordur; teli ve kılıfı '
       'değiştirin.',
       'Tellerde kopuk lif, kılıflarda ezik ya da çatlak olup olmadığına '
       'bakın.',
       'Fren kolu kelepçesini 6-8 Nm ile kontrol edin.',
   ])

# Tekerlekler ------------------------------------------------------------------

dm(code=WHEELS, tech='Tekerlekler', figure=5, description=[
    ('Genel', [
        'Tekerlekler 27,5" (584 mm) çift cidarlı alüminyum jant, 32 adet '
        '2 mm paslanmaz tel, rulmanlı göbek, iç lastik ve dış lastikten '
        'oluşur. Göbekler çabuk sökme mandalıyla çatala ve kadroya '
        'bağlanır.',
        'Arka göbekte kasetin oturduğu serbest çark (freehub) gövdesi '
        'vardır. Disk, her iki göbeğe altı cıvatayla bağlanır.',
    ]),
    ('Lastik basıncı', [
        'Basınç lastik yanağında yazan aralıkta tutulur. Hafif sürücüler ve '
        'yumuşak zemin için alt sınıra, ağır sürücüler ve sert zemin için '
        'üst sınıra yakın değer seçilir. Basınç düşükse iç lastik jantla '
        'taş arasında sıkışıp iki yan yana delik açılır.',
    ]),
    ('Tel gerginliği', [
        'Teller jantı göbeğe gergin olarak bağlar. Tel gerginliği eşit '
        'değilse jant yanlara yalpalar. Gerginlik, aynı taraftaki teller '
        'arasında ortalamadan %20\'den fazla sapmamalıdır.',
    ]),
])

dm(code=WHEEL_CHECK, tech='Tekerlekler', info='Kontrol', figure=5,
   tools=[PUMP],
   steps=[
       'Lastik basıncını ölçün. Basınç lastiğin yanında yazan aralıkta '
       'olmalıdır (2,0-3,5 bar).',
       'Lastik yüzeyinde kesik, batan cisim ya da yanakta çatlak olup '
       'olmadığına bakın.',
       'Tekerleği çevirin ve jantın fren ya da kadroya göre yanlara '
       'salınımını izleyin. 1 mm\'den fazla yalpa varsa teller '
       'ayarlanmalıdır.',
       'Telleri ikişer ikişer sıkın; gevşek tel varsa tekerlek '
       'düzeltilmelidir.',
       'Tekerleği iki elle tutup yanlara sallayın. Göbekte boşluk '
       'olmamalıdır.',
       'Çabuk sökme mandallarının kapalı ve sıkı olduğunu kontrol edin.',
   ])

dm(code=WHEEL_REMOVE, tech='Tekerlek', info='Sökme', figure=5,
   tools=[STAND],
   cautions=['Tekerlek sökülüyken fren kolunu sıkmayın; balatalar birbirine '
             'yaklaşır ve disk yerine giremez.'],
   steps=[
       'Arka tekerlek için zinciri en küçük arka dişliye alın.',
       'Çabuk sökme mandalını açın. Ön tekerlekte mandalın karşısındaki '
       'somunu birkaç tur gevşetin.',
       'Arka tekerlekte vites değiştiriciyi geriye çekip tekerleği aşağı '
       'doğru çıkarın.',
   ],
   next=WHEEL_INSTALL)

dm(code=WHEEL_INSTALL, tech='Tekerlek', info='Takma', figure=5,
   warnings=['Mandal yarı kapalı bırakılırsa tekerlek sürüş sırasında '
             'çıkabilir.'],
   steps=[
       'Diski kaliperin balataları arasına hizalayarak tekerleği yuvalarına '
       'oturtun. Arka tekerlekte zinciri en küçük dişliye geçirin.',
       'Mandal karşısındaki somunu sıkın; mandal kapanırken avuç içinde iz '
       'bırakacak kadar direnç olmalıdır.',
       'Mandalı kapatın.',
       'Tekerleği çevirin ve fren kolunu birkaç kez sıkın.',
   ])

dm(code=WHEEL_ISOLATE, tech='Tekerlekler', info='Arıza bulma', isolation={
    'fault': 'NAYABIKE-DA3-001',
    'descr': 'Tekerlek yalpalıyor, yanlara oynuyor ya da lastik iniyor.',
    'steps': [
        ('stp-0001', 'Lastik basıncını ölçün ve bir gün sonra tekrar '
         'ölçün.', 'Basınç düşüyor mu?', 'stp-0002', 'stp-0004'),
        ('stp-0002', 'Sibobun çevresine sabunlu su sürün.',
         'Sibopta kabarcık var mı?', 'end-valve', 'stp-0003'),
        ('stp-0003', 'İç lastiği çıkarıp deliğin yerine bakın.',
         'Delik iç lastiğin jant tarafında mı?', 'end-rim-tape',
         'stp-0007'),
        ('stp-0007', 'Deliğin şekline bakın.',
         'Yan yana iki küçük delik (yılan ısırığı) mı?', 'end-pressure',
         'stp-0008'),
        ('stp-0008', 'Dış lastiğin içini ve yanaklarını deliğin hizasında '
         'inceleyin.', 'Dış lastikte kesik ya da yanakta yırtık var mı?',
         'end-tire', 'end-tube'),
        ('stp-0004', 'Tekerleği iki elle tutup yanlara sallayın.',
         'Tekerlek yanlara oynuyor mu?', 'stp-0005', 'stp-0006'),
        ('stp-0005', 'Çabuk sökme mandalının kapalı ve sıkı olduğunu '
         'kontrol edin.', 'Mandal gevşek mi?', 'end-qr', 'stp-0009'),
        ('stp-0009', 'Tekerleği sökün ve göbek milini parmaklarınızla '
         'çevirin.', 'Dönüş pürüzlü ya da hışırtılı mı?',
         'end-hub-service', 'end-hub'),
        ('stp-0006', 'Tekerleği çevirip janta bakın.',
         'Jant yanlara yalpalıyor mu?', 'stp-0010', 'end-ok'),
        ('stp-0010', 'Telleri ikişer ikişer sıkarak yoklayın.',
         'Kopuk ya da çok gevşek tel var mı?', 'end-spoke', 'end-true'),
    ],
    'ends': [
        ('end-valve', 'Sibop içini sıkın ya da değiştirin.', VALVE),
        ('end-rim-tape', 'Tel delikleri iç lastiği delmiş: jant bandını '
         'kontrol edin, iç lastiği değiştirin.', TUBE),
        ('end-tube', 'İç lastiği yamayın ya da değiştirin; dış lastiğin '
         'içindeki batan cismi bulun.', TUBE),
        ('end-pressure', 'Lastik basıncı düşük kalmış. İç lastiği yamayın '
         'ya da değiştirin ve lastiği basınç aralığında tutun.', INFLATE),
        ('end-tire', 'Dış lastiği değiştirin; kesik yerinden iç lastik '
         'yeniden delinir.', TIRE),
        ('end-qr', 'Çabuk sökme mandalını ayarlayın.', QR_ADJUST),
        ('end-hub', 'Göbek rulman boşluğunu ayarlayın.', HUB_ADJUST),
        ('end-hub-service', 'Göbek rulmanlarının bakımını yapın.',
         HUB_SERVICE),
        ('end-spoke', 'Kopuk teli değiştirin.', SPOKE_REPLACE),
        ('end-true', 'Tekerleği düzeltin.', TRUING),
        ('end-ok', 'Tekerlek sağlam görünüyor; tekerlekleri ayrıntılı '
         'kontrol edin.', WHEEL_CHECK),
    ],
})

dm(code=QR_ADJUST, tech='Çabuk sökme mandalı', info='Ayar', figure=11,
   supplies=[GREASE],
   warnings=['Mandalı kelebek somun gibi çevirerek sıkmayın; mandal ancak '
             'kapatılarak sıkar.'],
   steps=[
       'Mandalı açın.',
       'Mandal karşısındaki somunu elle çevirin: mandal yarı yolda dirençle '
       'karşılaşmaya başlamalıdır.',
       'Mandalı kapatın. Kapanırken avuç içinde iz bırakacak kadar direnç '
       'olmalı; kolay kapanıyorsa somunu sıkın, kapanmıyorsa gevşetin.',
       'Mandal ucunu çatal ayağına ya da kadroya doğru, takılmayacak bir '
       'konuma getirin.',
       'Mandalın kamı kuru ve sesli çalışıyorsa kamına ve miline ince gres '
       'sürün.',
   ])

dm(code=TUBE, tech='İç lastik', info='Yama ve değiştirme', figure=5,
   tools=[LEVERS, PUMP, ('Yama takımı', 1)],
   spares=[('İç lastik', 1)],
   steps=[
       'Tekerleği sökün ve iç lastikteki havayı tamamen boşaltın.',
       'Levyeleri sibobun karşısından lastik ile jant arasına sokun ve '
       'lastiğin bir yanını janttan çıkarın.',
       'İç lastiği çıkarın. Lastiğin içini parmakla yoklayarak batan cismi '
       'bulun ve çıkarın.',
       'İç lastiği hafifçe şişirip deliği bulun. Küçük deliği yama ile '
       'kapatın; büyük yırtıkta iç lastiği değiştirin.',
       'Jant bandının bütün tel deliklerini örttüğünü kontrol edin.',
       'İç lastiği hafif şişirip önce sibobu jant deliğine sokarak '
       'yerleştirin.',
       'Lastiği elle janta geçirin. İç lastiğin lastik ile jant arasına '
       'sıkışmadığını kontrol edin.',
       'Lastiği basınç aralığında şişirin ve tekerleği takın.',
   ],
   next=WHEEL_INSTALL)

dm(code=TIRE, tech='Dış lastik', info='Değiştirme', figure=5,
   tools=[LEVERS, PUMP],
   spares=[('Dış lastik, 27,5 × 2,25', 1)],
   steps=[
       'Tekerleği sökün, havayı boşaltın ve lastiğin iki yanını da janttan '
       'çıkarın; iç lastiği çıkarın.',
       'Yeni lastiğin yanağındaki dönüş yönü okunu tekerleğin dönüş '
       'yönüne getirin.',
       'Lastiğin bir yanını elle janta geçirin.',
       'İç lastiği yerleştirin ve diğer yanı sibobun karşısından başlayarak '
       'elle geçirin; son kısım için levyeyi iç lastiği sıkıştırmadan '
       'kullanın.',
       'Lastiği 1 bar\'a şişirip lastik yanağındaki çizginin jant kenarına '
       'her yerde eşit uzaklıkta olduğunu kontrol edin; sonra basınç '
       'aralığına şişirin.',
   ],
   next=WHEEL_INSTALL)

dm(code=VALVE, tech='Sibop', info='Sibop içi değiştirme', figure=5,
   tools=[('Sibop içi anahtarı', 1), PUMP],
   spares=[('Sibop içi (otomobil tipi)', 1)],
   steps=[
       'Sibop kapağını çıkarın ve sibop içine basarak havayı boşaltın.',
       'Sibop içi anahtarıyla sibop içini saat yönünün tersine çevirip '
       'çıkarın.',
       'Yeni sibop içini elle başlatıp anahtarla hafifçe sıkın.',
       'Lastiği şişirin, sibobun çevresine sabunlu su sürüp kaçak olmadığını '
       'kontrol edin ve kapağı takın.',
   ])

dm(code=INFLATE, tech='Lastikler', info='Şişirme', figure=5,
   tools=[PUMP],
   steps=[
       'Lastik yanağında yazan basınç aralığını okuyun.',
       'Sibop kapağını çıkarın ve pompanın başlığını otomobil sibobuna '
       'takın.',
       'Lastiği aralık içinde istenen basınca şişirin. Ön lastik arkaya '
       'göre 0,1-0,2 bar düşük olabilir.',
       'Pompayı çıkarın ve sibop kapağını takın.',
       'Basıncı en az haftada bir kontrol edin; iç lastik zamanla hava '
       'kaçırır.',
   ])

dm(code=SEALANT, tech='İç lastik', info='Koruyucu sıvı ekleme', figure=5,
   tools=[('Sibop içi anahtarı', 1), PUMP],
   supplies=[('İç lastik koruyucu sıvısı', None)],
   steps=[
       'Sibobu saat 12 konumuna getirin ve havayı boşaltın.',
       'Sibop içini anahtarla çıkarın.',
       'Koruyucu sıvının şişesindeki miktarı (27,5" iç lastik için '
       'genellikle 60-90 ml) sibobun içinden enjekte edin.',
       'Sibop içini takın ve lastiği şişirin.',
       'Tekerleği birkaç tur döndürerek sıvıyı iç lastiğin içine yayın.',
       'Sıvı yaklaşık altı ayda kurur; bu sürede yenileyin.',
   ])

dm(code=TIRE_CHECK, tech='Lastikler', info='Kontrol', figure=5,
   tools=[PUMP],
   steps=[
       'Tırtılların yüksekliğine bakın. Orta sıradaki tırtıllar yarıya '
       'indiyse ya da köşeleri yuvarlaklaştıysa lastik tutuşunu yitirmiştir.',
       'Lastiği döndürerek yüzeyde kesik, batan cisim ve kopmuş tırtıl '
       'arayın; batan cisimleri çıkarın.',
       'Yanaklarda çatlak, kabarma ya da bezi görünen kesik olup '
       'olmadığına bakın. Bu durumda lastiği değiştirin.',
       'Sibobun dik durduğunu kontrol edin. Eğik sibop, iç lastiğin janta '
       'göre kaydığını gösterir.',
   ])

dm(code=TRUING, tech='Tekerlek', info='Düzeltme', figure=5,
   tools=[('Nipel anahtarı', 1), ('Jant düzeltme sehpası', 1)],
   steps=[
       'Tekerleği düzeltme sehpasına takın ya da bisiklette kaliperin '
       'yanındaki bir referans noktası kullanın.',
       'Tekerleği çevirip jantın sehpanın ucuna en çok yaklaştığı yeri '
       'bulun.',
       'Bu noktadaki karşı taraf telini çeyrek tur gevşetin, aynı taraftaki '
       'iki komşu teli çeyrek tur sıkın. Nipel, telin göbek tarafından '
       'bakıldığında saat yönünde çevrilince sıkar.',
       'Yalpa 0,5 mm\'nin altına inene kadar küçük adımlarla tekrarlayın.',
       'Tel gerginliğini ölçün; gevşek tel kalmamalıdır.',
       'Telleri ikişer ikişer sıkarak gerilimi oturtun ve son kontrolü '
       'yapın.',
   ],
   next=SPOKE_TENSION)

dm(code=SPOKE_TENSION, tech='Teller', info='Gerginlik ölçümü', figure=5,
   tools=[('Tel gerginlik ölçeri', 1), ('Nipel anahtarı', 1)],
   steps=[
       'Ölçeri her telin ortasına takıp değerini not edin; iki tarafı ayrı '
       'ayrı ölçün.',
       'Aynı taraftaki tellerin ortalamasını hesaplayın.',
       'Ortalamadan %20\'den fazla sapan telleri komşularıyla birlikte '
       'ayarlayın.',
       'Ön tekerlekte iki taraf, arka tekerlekte sağ (zincir) taraf jant '
       'üreticisinin önerdiği gerilimde olmalıdır; bu jantlarda genellikle '
       '1000-1200 N.',
       'Ayardan sonra jant yalpasını kontrol edin.',
   ])

dm(code=SPOKE_REPLACE, tech='Tel', info='Değiştirme', figure=5,
   tools=[('Nipel anahtarı', 1), LEVERS, ('Jant düzeltme sehpası', 1)],
   spares=[('Jant teli, 2 mm, nipeliyle', 1)],
   steps=[
       'Tekerleği sökün, lastiği ve iç lastiği çıkarın. Arka tekerlekte sağ '
       'taraf teli için kaseti, gerekirse diski de sökün.',
       'Kırık teli nipelinden çıkarın.',
       'Yeni teli göbekteki delikten, komşu tellerle aynı yönde ve aynı '
       'çaprazlama düzeninde geçirin.',
       'Nipeli jant deliğinden takın ve teli komşularıyla aynı gerginliğe '
       'gelene kadar sıkın.',
       'Tekerleği düzeltin, lastiği ve tekerleği takın.',
   ],
   next=TRUING)

dm(code=RIM_CHECK, tech='Jant', info='Kontrol', figure=5,
   tools=[('Kumpas', 1), LEVERS],
   steps=[
       'Jantın iki yanında ezik, çatlak ya da kenar açılması olup '
       'olmadığına bakın.',
       'Tel deliklerinin çevresinde kılcal çatlak arayın; çatlaklı jantı '
       'değiştirin.',
       'Lastiği çıkardığınızda jant bandının bütün tel deliklerini '
       'örttüğünü ve kaymadığını kontrol edin.',
       'Jantın yuvarlaklığını (yukarı aşağı salgı) tekerleği çevirerek '
       'izleyin; 1 mm\'den fazla salgı tekerleğin düzeltilmesini gerektirir.',
   ],
   next=TRUING)

dm(code=HUB_ADJUST, tech='Göbek', info='Rulman boşluğu ayarı', figure=11,
   tools=[('Göbek konik anahtarı (13-17 mm)', 1), TORQUE],
   steps=[
       'Tekerleği sökün.',
       'Bir taraftaki koniyi konik anahtarıyla tutup kontra somununu '
       'gevşetin.',
       'Koniyi çeyrek turdan küçük adımlarla çevirin: mil boşluksuz ama '
       'sıkışmadan dönmelidir. Çabuk sökme mandalı sıkılınca rulman biraz '
       'daha sıkışır; bu yüzden çok az boşluk bırakın.',
       'Koniyi tutarken kontra somununu 15-17 Nm ile sıkın.',
       'Tekerleği takıp mandalı kapatın ve yanlara oynatarak boşluğu '
       'kontrol edin.',
   ],
   next=WHEEL_INSTALL)

dm(code=HUB_SERVICE, tech='Göbek rulmanları', info='Bakım', figure=11,
   tools=[('Göbek konik anahtarı (13-17 mm)', 1),
          ('Kaset sökme aparatı ve zincir kırbacı', 1)],
   supplies=[GREASE, DEGREASER, RAG],
   steps=[
       'Tekerleği sökün; arka tekerlekte kaseti sökün.',
       'Disk tarafındaki kontra somunu ve koniyi sökün, mili çekin; '
       'bilyaları bir kaba toplayın.',
       'Mil, koni, bilya ve kap yüzeylerini yağ çözücüyle temizleyin.',
       'Koni ya da kapta çukurlaşma varsa koniyi değiştirin; kapta '
       'çukurlaşma varsa göbek değiştirilmelidir.',
       'Kaplara gres doldurup bilyaları (genellikle önde 10, arkada 9 adet '
       '3/16") yerleştirin.',
       'Mili takın, koniyi ve kontra somunu takıp boşluğu ayarlayın.',
   ],
   next=HUB_ADJUST)

dm(code=HUB_CHECK, tech='Göbek ve serbest çark', info='Kontrol',
   figure=9, tools=[STAND],
   steps=[
       'Tekerleği yanlara oynatın; boşluk olmamalıdır.',
       'Tekerleği sökün ve mili parmaklarınızla çevirin; dönüş pürüzsüz '
       'olmalıdır.',
       'Arka tekerlekte kaseti elle saat yönünde çevirin: göbek tutmalı, '
       'tekerlek birlikte dönmelidir.',
       'Kaseti tersine çevirin: kaset tekerlekten bağımsız ve sürtünmesiz '
       'dönmeli, düzenli tıkırtı gelmelidir.',
       'Serbest çark pedala yüklenince boşa dönüyor ya da tersine dönerken '
       'zinciri sürüklüyorsa serbest çark gövdesi değiştirilmelidir.',
   ])


# --- Sele grubu arıza bulma -------------------------------------------------

SEAT_ISOLATE = code('DA0', '4', '421')

dm(code=SEAT_ISOLATE, tech='Sele grubu', info='Arıza bulma',
   isolation={
       'fault': 'NAYABIKE-DA0-101',
       'descr': 'Sele sürüşte kayıyor, yatıyor ya da gıcırdıyor.',
       'steps': [
           ('stp-0001', 'Sele borusunda kadronun üst kenarına bir bant '
            'yapıştırıp kısa bir sürüş yapın.', 'Sele borusu banttan '
            'aşağı kaydı mı?', 'end-height', 'stp-0002'),
           ('stp-0002', 'Seleyi ucundan ve arkasından bastırın.', 'Sele '
            'öne ya da arkaya yatıyor mu?', 'end-saddle', 'stp-0003'),
           ('stp-0003', 'Selede otururken ağırlığınızı kaydırıp sesin '
            'nereden geldiğini dinleyin.', 'Ses sele borusunun kadroya '
            'girdiği yerden mi geliyor?', 'end-post', 'end-rails'),
       ],
       'ends': [
           ('end-height', 'Sele borusu kelepçesini temizleyip doğru '
            'kuvvetle sıkın.', SEAT_HEIGHT),
           ('end-saddle', 'Sele kelepçesini ayarlayıp torkunda sıkın.',
            SADDLE_ADJUST),
           ('end-post', 'Sele borusunu söküp temizleyin ve gresleyin.',
            SEATPOST_SERVICE),
           ('end-rails', 'Ses sele raylarından ya da kelepçeden geliyor; '
            'kelepçeyi söküp temaslarını gresleyerek yeniden sıkın.',
            SADDLE_ADJUST),
       ],
   })

# --- Çalışma ilkesi ----------------------------------------------------------
#
# Her sistem kökü için sade bir çalışma anlatımı. Sistemde zaten bir tanım
# DM'i varsa bu anlatım yanına '01' sökme koduyla eklenir.

HOW = 'Çalışma ilkesi'

dm(code=code('DA0', '1', '040'), tech='Kadro', info=HOW, description=[
    ('Kadronun görevi', [
        'Kadro bütün parçaların bağlandığı iskelettir. Sürücünün ağırlığı '
        'sele borusu ve orta göbek üzerinden, darbeler tekerleklerden ve '
        'çataldan kadroya geçer.',
        'Ön üçgen (üst boru, alt boru, sele borusu) ile arka üçgen (zincir '
        've sele kalçaları) birlikte bükülmeye karşı sert bir yapı '
        'oluşturur.',
    ]),
    ('Çatlak belirtileri', [
        'Çatlak çoğu zaman kaynak yerlerinde, furç borusunun altında ve orta '
        'göbek çevresinde başlar. Boyada ince bir çizgi gibi görünür; '
        'yüklenince gıcırdar. Çatlak kadro onarılmaz, değiştirilir.',
    ]),
])

dm(code=code('DA0', '2', '040', '01'), tech='Yaylı çatal', info=HOW,
   description=[
       ('Yay ve sönüm', [
           'Çatalın iç boruları alt bacakların içinde kayar. İçerideki '
           'helezon yay darbeyi emer; sönüm düzeni çatalın geri gelişini '
           'yavaşlatır, böylece çatal yaylanıp sekmez.',
           'Ön yük düğmesi yayı önceden sıkıştırır. Sürücü ağırlığına göre '
           'ayarlanmazsa çatal ya dibe vurur ya da hiç çalışmaz.',
       ]),
       ('Keçeler ve yağ', [
           'Toz keçeleri iç boruları silerek kiri dışarıda tutar. Alt '
           'bacaklardaki az miktardaki yağ burçları yağlar. Yağ eskiyip '
           'azalınca çatal takılarak çalışır ve burçlar aşınır.',
           'İç borudaki bir çizik keçeyi keser; çatal yağ kaçırmaya '
           'başlar. İç boru onarılmaz, alt bacakla birlikte değiştirilir.',
       ]),
       ('Furç', [
           'Çatal boğazı kadronun furç borusundaki iki rulmanın içinde '
           'döner. Furç boşluğu gidon boğazı ile üst kapak cıvatasıyla '
           'alınır; boşluk kalırsa frenlerken gidon ileri geri oynar.',
       ]),
   ])

dm(code=code('DA0', '3', '040'), tech='Gidon ve kumanda', info=HOW,
   description=[
       ('Gidon', [
           'Gidon boğazı gidonu çatal boğazına bağlar; iki kelepçe cıvatası '
           'çatal boğazını, ön kapak cıvataları gidonu sıkar. Bu cıvatalar '
           'yanlış torkta sıkılırsa gidon kayar ya da karbon/alüminyum boru '
           'zarar görür.',
       ]),
       ('Kumandalar', [
           'Vites kolları her tıkta teli belirli bir miktar çeker ya da '
           'bırakır; vites değiştirici bu hareketle zinciri bir dişliden '
           'ötekine iter.',
           'Fren kolları fren telini çekerek mekanik kaliperi sıkar. Kol '
           'pivotu kurursa kol yavaş döner ya da yerine dönmez.',
       ]),
   ])

dm(code=code('DA0', '4', '040'), tech='Sele grubu', info=HOW, description=[
    ('Yükseklik ve konum', [
        'Sele borusu kadronun sele borusuna girer ve kelepçeyle sıkılır. '
        'Sele yüksekliği, pedal en aşağıdayken dizin hafifçe bükülü kalacağı '
        'kadar olmalıdır.',
        'Sele, sele borusunun başlığındaki kelepçeye raylarından bağlanır; '
        'ileri geri konum ve eğim bu kelepçeyle ayarlanır.',
    ]),
    ('Sesler', [
        'Kuru ya da kirli sele borusu kadro içinde gıcırdar. Sele borusunda '
        'üzerinde yazan en az takma derinliği işaretinin kadro içinde '
        'kalması gerekir; dışarıda kalırsa kadro çatlayabilir.',
    ]),
])

dm(code=code('DA1', info='040', disassy='01'), tech='Aktarma organları',
   info=HOW,
   description=[
       ('Pedaldan tekerleğe', [
           'Pedallar pedal kollarını, kollar orta göbekteki mili döndürür. '
           'Aynalar zinciri çeker; zincir arka kasetteki dişliyi, kaset de '
           'serbest çark gövdesi üzerinden arka tekerleği döndürür.',
           'Serbest çark gövdesindeki tırnaklar yalnız pedal ileri '
           'çevrilince kavrar; pedal durunca tekerlek serbest döner ve '
           'tıkırtı duyulur.',
       ]),
       ('Vitesler', [
           'Arka vites değiştirici zinciri kasetteki dişliler arasında, ön '
           'vites değiştirici aynalar arasında kaydırır. Küçük ön ayna ile '
           'büyük arka dişli en hafif, büyük ön ayna ile küçük arka dişli en '
           'ağır vitestir.',
           'Limit vidaları zincirin en dıştaki dişlilerden dışarı '
           'kaçmasını önler. Tel gerginliği her tıkın tam bir dişliye denk '
           'gelmesini sağlar. Vites askısı darbede eğilerek kadroyu korur; '
           'eğilince vitesler bozulur.',
       ]),
       ('Aşınma', [
           'Zincirin pimleri ve makaraları aşındıkça zincir uzar. Uzamış '
           'zincir dişlileri de aşındırır; zincir zamanında değişirse kaset '
           've aynalar çok daha uzun dayanır.',
       ]),
   ])

dm(code=code('DA2', info='040', disassy='01'), tech='Fren sistemi',
   info=HOW,
   description=[
       ('Mekanik disk fren', [
           'Fren kolu çekilince tel kaliperdeki kolu döndürür. Kol bir '
           'kam düzeneğiyle hareketli balatayı diske iter; disk sabit '
           'balataya doğru hafifçe esneyerek iki balata arasında sıkışır.',
           'Balata aşındıkça kol daha çok yol alır. Balata boşluğu kaliperin '
           'ayar düğmesiyle ve tel gerginliğiyle alınır.',
       ]),
       ('Temizlik', [
           'Diske ya da balataya bulaşan yağ freni ciddi biçimde '
           'zayıflatır ve ciyaklama yapar. Yağlanmış organik balata '
           'temizlenmez, değiştirilir; disk izopropil alkolle silinir.',
           'Yeni balatalar ilk birkaç frenlemede diske alıştırılır; tam '
           'gücüne ondan sonra ulaşır.',
       ]),
       ('Disk', [
           'Disk ısı ve sürtünmeyle incelir. En az kalınlığın altına inen '
           'disk değiştirilir. Eğilmiş disk her turda balataya sürter.',
       ]),
   ])

dm(code=code('DA3', info='040', disassy='01'), tech='Tekerlekler', info=HOW,
   description=[
       ('Tel ve jant', [
           'Teller göbeği janta bağlar ve gergin durur. Tekerlek yükü '
           'aşağıdaki tellerin gerginliğinin azalmasıyla taşır. Teller '
           'gevşerse jant yalpalar; bir tel koparsa jant o yana hemen eğilir.',
       ]),
       ('Lastik', [
           'İç lastikteki hava dış lastiği şişirir ve jantın kenarlarına '
           'oturtur. Basınç düşükse lastik darbede jant kenarına kadar '
           'ezilir ve iç lastik iki yerden delinir (yılan ısırığı).',
           'Jant bandı tel deliklerini örter; kayarsa delik kenarı iç '
           'lastiği içeriden keser.',
       ]),
       ('Göbek ve mandal', [
           'Göbek akslar üzerindeki bilyalı rulmanlarda döner. Koni ayarı '
           'gevşekse tekerlek yanlara oynar, sıkıysa takılarak döner.',
           'Çabuk sökme mandalı tekerleği kadroya ya da çatala sıkar; '
           'mandal kapatılırken avuç içinde belirgin bir direnç hissedilmeli '
           've iz bırakmalıdır.',
       ]),
   ])

# --- Bakım takvimi, sıvılar ve terimler --------------------------------------

SEE_MAKER = 'üretici değerine bakın'

dm(code=code('D00', info='000'), tech='Bisiklet',
   info='Bakım takvimi ve değiştirme ölçütleri',
   description=[
       ('Kullanım', [
           'Adım adım yapılacaklar periyodik bakım çizelgesinde. Bu DM, '
           'hangi parçanın ne zaman değiştirileceğini gösteren ölçütleri '
           'toplar. Islak, çamurlu ve tozlu sürüşte aralıklar kısalır.',
       ]),
       ('Değiştirme ölçütleri', [
           ('Parça şu durumda değiştirilir:', [
               'Zincir: zincir ölçer %0,75 işaretinde tam oturuyorsa (bu '
               'bisikletin zinciri için); %0,5\'te değişim yaklaşmıştır.',
               'Kaset ve aynalar: yeni zincir yükte atlıyorsa ya da dişler '
               'köpek balığı yüzgeci gibi sivrilmişse.',
               'Fren balatası: sürtünme malzemesi 0,5 mm\'ye inmişse ya da '
               'balata yağlanmışsa.',
               'Fren diski: 1,5 mm\'nin altına incelmişse, çatlamışsa ya da '
               'düzeltilemeyecek kadar eğilmişse.',
               'Dış lastik: tırtıllar aşınmışsa, yanağında kesik ya da '
               'kabarma varsa.',
               'Fren ve vites teli: lifleri kopmuş, paslanmış ya da kılıfı '
               'ezilmişse.',
               'Elcikler: gidonda dönüyorsa ya da yırtılmışsa.',
           ]),
       ]),
       ('Takvim', [
           ('Özet:', [
               'Her sürüşten önce: lastik basıncı, frenler, çabuk sökme '
               'mandalları.',
               'Her çamurlu sürüşten sonra: yıkama, zinciri kurulama ve '
               'yağlama, çatal iç borularını silme.',
               'Ayda bir: zincir temizliği, balata ve kol boşluğu, tekerlek '
               'yalpası, vites ayarı.',
               'Üç ayda bir: zincir ölçümü, çatal alt bacak bakımı, tork '
               'kontrolü, tel ve kılıflar, disk kalınlığı.',
               'Yılda bir: tellerin ve kılıfların değişimi, rulmanların '
               'bakımı, sele borusunun greslenmesi, çatalın tam bakımı.',
           ]),
       ]),
   ])

dm(code=code('D00', info='030', disassy='01'), tech='Bisiklet',
   info='Yağlar, sıvılar ve basınçlar',
   description=[
       ('Yağlar', [
           ('Kullanılanlar:', [
               'Zincir yağı: kuru hava için kuru tip, ıslak ve çamurlu '
               'hava için ıslak tip zincir yağı. Her baklaya bir damla; '
               'fazlası silinir.',
               'Bisiklet gresi: rulmanlar, pedal dişleri, sele borusu ve '
               'cıvata dişleri için.',
               f'Çatal yağı: alt bacaklar için üreticinin önerdiği tip ve '
               f'miktar; {SEE_MAKER}.',
               'İç lastik koruyucu sıvısı (kullanılıyorsa): üreticinin '
               'önerdiği miktar, iç lastiğin sibobundan.',
               'Orta güçte vida sabitleyici: disk ve kaliper cıvataları '
               'için.',
           ]),
       ]),
       ('Temizleyiciler', [
           'İzopropil alkol: fren diski ve balata çevresi için. Yağ çözücü '
           'yalnız aktarma organlarında kullanılır; frenlere bulaştırılmaz.',
           'Bisiklet şampuanı ve bol su; basınçlı yıkama rulmanlara '
           'tutulmaz.',
       ]),
       ('Lastik basıncı', [
           'Bu bisikletin lastikleri için genellikle 2,0-3,5 bar (30-50 psi); '
           'kesin aralık lastiğin yanağında yazar. Hafif sürücü ve gevşek '
           'zeminde alt, ağır sürücü ve sert zeminde üst değere yakın.',
           'Basınç her sürüşten önce manometreli pompayla kontrol edilir; iç '
           'lastikler birkaç günde doğal olarak basınç kaybeder.',
       ]),
       ('Çatal', [
           f'Ön yük ayarı sürücü ağırlığına göre yapılır; çatal yağı '
           f'miktarı ve tipi için {SEE_MAKER}. Çatalın içindeki sönüm '
           'yağının değişimi yetkili servis işidir.',
       ]),
   ])

dm(code=code('D00', info='006'), tech='Bisiklet', info='Terimler sözlüğü',
   description=[
       ('Kadro, çatal ve kumanda', [
           ('Terimler:', [
               'Furç: çatal boğazının kadro içinde döndüğü rulman takımı.',
               'Gidon boğazı (stem): gidonu çatal boğazına bağlayan parça.',
               'İç boru ve alt bacak: yaylı çatalın kayan ve sabit '
               'boruları.',
               'Ön yük: çatal yayının önceden sıkıştırılması.',
               'Çökme (sag): sürücü binince çatalın kendiliğinden çöktüğü '
               'miktar.',
               'Toz keçesi: iç boruyu silerek kiri dışarıda tutan keçe.',
               'Elcik: gidonun tutulan lastik kaplaması.',
           ]),
       ]),
       ('Aktarma organları', [
           ('Terimler:', [
               'Aynakol: pedal kolları ve ön dişlilerin (aynaların) takımı.',
               'Orta göbek: pedal kollarını taşıyan milli rulman kartuşu.',
               'Kaset: arka göbekteki dişliler takımı.',
               'Serbest çark gövdesi: kasetin takıldığı, yalnız ileri '
               'yönde kavrayan göbek parçası.',
               'Vites değiştirici (aktarıcı): zinciri dişliler arasında '
               'kaydıran düzen.',
               'Vites askısı: arka vites değiştiriciyi kadroya bağlayan, '
               'darbede eğilen parça.',
               'Makara: arka vites değiştiricideki iki küçük dişli tekerlek.',
               'Limit vidası: vites değiştiricinin gidebileceği en uç '
               'konumu sınırlayan vida.',
               'Zincir uzaması: pim ve makaraların aşınmasıyla zincirin '
               'boyunun artması.',
               'Kilit bakla (hızlı bakla): zinciri aletsiz birleştiren '
               'bakla.',
           ]),
       ]),
       ('Fren ve tekerlek', [
           ('Terimler:', [
               'Kaliper: balataları diske bastıran fren gövdesi.',
               'Adaptör: kaliperi kadroya ya da çatala bağlayan ara parça.',
               'Balata: diske sürtünerek bisikleti yavaşlatan parça.',
               'Alıştırma: yeni balatanın diske ilk frenlemelerle '
               'oturtulması.',
               'Jant bandı: jant içindeki tel deliklerini örten bant.',
               'Sibop: iç lastiğin hava valfi.',
               'Yılan ısırığı: düşük basınçta iç lastikte oluşan iki yan '
               'yana delik.',
               'Yalpa: tekerleğin dönerken yana sallanması.',
               'Tel gerginliği: tellerin ne kadar gergin olduğu; jantın '
               'düzgünlüğünü belirler.',
               'Koni: göbek rulmanının bilyalarını yerinde tutan somun.',
               'Çabuk sökme mandalı: tekerleği aletsiz sıkıp bırakan mandal.',
           ]),
       ]),
   ])

# --- Parçalar ----------------------------------------------------------------
#
# (kimlik, ad, üst parça, SNS, model düğümleri, bölge, işlev, prosedürler).
# Kendi düğümü olmayan parça içinde bulunduğu düğüme bağlanır; seçilince o
# düğüm vurgulanır. IPD tanımı (ipd_name) ve parça numarası katalogda görünür.

part('frame', 'Kadro', None, 'DA0-10', ['frame'], 'z.middle',
     'Bütün parçaları taşıyan alüminyum gövde.',
     {'inspect': FRAME_CHECK}, part_number='NB-FR-100',
     ipd_name='Kadro, alüminyum')

part('fork', 'Yaylı çatal', None, 'DA0-20', ['fork'], 'z.front',
     'Ön tekerleği tutar, yoldan gelen darbeleri sönümler.',
     {'isolate': FORK_ISOLATE, 'inspect': FORK_CHECK,
      'adjust': FORK_SETUP, 'lubricate': FORK_SERVICE},
     part_number='NB-FK-100', ipd_name='Yaylı çatal, 100 mm')
part('fork.headset', 'Furç', 'fork', 'DA0-20', ['fork'], 'z.front',
     'Çatalın kadro içinde rahat dönmesini sağlayan rulmanlar.',
     {'inspect': FORK_CHECK, 'adjust': HEADSET_ADJUST,
      'replace': HEADSET_BEARINGS},
     part_number='NB-FK-110', ipd_name='Furç takımı, 1 1/8"')
part('fork.stanchions', 'Çatal iç boruları', 'fork', 'DA0-20', ['fork'],
     'z.front', 'Alt bacakların üzerinde kaydığı krom kaplı borular.',
     {'inspect': FORK_CHECK}, quantity=2, part_number='NB-FK-120',
     ipd_name='İç boru ve taç ünitesi, 30 mm')
part('fork.lowers', 'Çatal alt bacakları', 'fork', 'DA0-20', ['fork'],
     'z.front', 'Ön tekerleği ve kaliperi taşıyan, burçlu alt gövde.',
     {'lubricate': FORK_SERVICE}, part_number='NB-FK-130',
     ipd_name='Alt bacak, burçlarıyla')
part('fork.seals', 'Çatal toz keçeleri', 'fork', 'DA0-20', ['fork'],
     'z.front', 'İç borudaki kiri sıyırır, banyo yağını içeride tutar.',
     {'replace': FORK_SEALS}, quantity=2, part_number='NB-FK-140',
     ipd_name='Toz keçesi ve köpük halka takımı')
part('fork.spring', 'Çatal yayı ve ön yük ayarı', 'fork', 'DA0-20',
     ['fork'], 'z.front',
     'Sol ayaktaki helezon yay; ön yük düğmesiyle sertliği ayarlanır.',
     {'adjust': FORK_SETUP}, part_number='NB-FK-150',
     ipd_name='Helezon yay, orta sertlik')

part('cockpit', 'Gidon ve kumanda', None, 'DA0-30', ['handlebar'],
     'z.cockpit', 'Yön verme, fren ve vites kumandası.',
     {'inspect': COCKPIT_CHECK, 'adjust': LEVER_POSITION},
     part_number='NB-CP-100', ipd_name='Gidon, elcikli')
part('cockpit.bar', 'Gidon borusu', 'cockpit', 'DA0-30', ['handlebar'],
     'z.cockpit', '680 mm düz alüminyum gidon, 31,8 mm kelepçe çapı.',
     {'inspect': COCKPIT_CHECK}, part_number='NB-CP-140',
     ipd_name='Gidon borusu, 680 mm, 31,8 mm')
part('cockpit.stem', 'Gidon boğazı', 'cockpit', 'DA0-30', ['handlebar'],
     'z.cockpit', 'Gidonu çatal boğazına bağlar; furç ayarı bunun '
     'üzerinden yapılır.',
     {'inspect': COCKPIT_CHECK, 'adjust': HEADSET_ADJUST},
     part_number='NB-CP-150', ipd_name='Gidon boğazı, 70 mm, 1 1/8"')
part('cockpit.grips', 'Elcikler', 'cockpit', 'DA0-30', ['handlebar'],
     'z.cockpit', 'Gidon uçlarındaki kauçuk tutma yerleri.',
     {'replace': GRIPS}, quantity=2, part_number='NB-CP-160',
     ipd_name='Elcik çifti')
part('cockpit.shifters', 'Vites kolları', 'cockpit', 'DA1-60',
     ['handlebar'], 'z.cockpit',
     'Sol kol ön, sağ kol arka vites değiştiriciyi tel ile çeker.',
     {'inspect': SHIFTER_CHECK, 'adjust': RD_ADJUST,
      'replace': SHIFTER_REPLACE},
     part_number='NB-CP-120', ipd_name='Tetik vites kolu, sağ 8 vites')
part('cockpit.brake_levers', 'Fren kolları', 'cockpit', 'DA2-30',
     ['handlebar'], 'z.cockpit',
     'Sol kol ön freni, sağ kol arka freni çalıştırır.',
     {'inspect': BRAKE_LEVER_CHECK, 'adjust': BRAKE_ADJUST,
      'replace': BRAKE_LEVER},
     quantity=2, part_number='NB-CP-130', ipd_name='Fren kolu')

part('seat', 'Sele grubu', None, 'DA0-40', ['saddle', 'seatpost'],
     'z.middle', 'Sürücünün oturduğu sele ve onu taşıyan boru.',
     {'adjust': SEAT_HEIGHT}, part_number='NB-ST-000',
     ipd_name='Sele grubu')
part('seat.saddle', 'Sele', 'seat', 'DA0-40', ['saddle'], 'z.middle',
     'Çelik raylı sele.', {'adjust': SADDLE_ADJUST},
     part_number='NB-ST-100', ipd_name='Sele, çelik raylı')
part('seat.post', 'Sele borusu', 'seat', 'DA0-40', ['seatpost'],
     'z.middle', 'Sele yüksekliğini ayarlamaya yarar.',
     {'adjust': SEAT_HEIGHT, 'lubricate': SEATPOST_SERVICE},
     part_number='NB-ST-110', ipd_name='Sele borusu, 27,2 mm')
part('seat.post_head', 'Sele borusu başlığı', 'seat.post', 'DA0-40',
     ['seatpost'], 'z.middle',
     'Seleyi raylarından tutan tek cıvatalı kelepçe.',
     {'adjust': SADDLE_ADJUST}, part_number='NB-ST-120',
     ipd_name='Sele kelepçesi, tek cıvatalı')
part('seat.clamp', 'Sele borusu kelepçesi', 'seat.post', 'DA0-40',
     ['seatpost'], 'z.middle',
     'Sele borusunu kadroya sıkan çabuk sökme kelepçe.',
     {'adjust': SEAT_HEIGHT}, part_number='NB-ST-130',
     ipd_name='Sele borusu kelepçesi, çabuk sökme, 31,8 mm')

DRIVE_NODES = ['drive_chain', 'drive_crankset', 'drive_bottom_bracket',
               'drive_pedals', 'drive_cassette', 'drive_derailleur',
               'drive_front_derailleur', 'cables_shift']
part('drive', 'Aktarma organları', None, 'DA1', DRIVE_NODES, 'z.middle',
     'Pedal gücünü arka tekerleğe aktarır; 3 × 8 = 24 vites.',
     {'isolate': SHIFT_ISOLATE, 'clean': DRIVE_CLEAN},
     part_number='NB-DR-000', ipd_name='Aktarma organları takımı')
part('drive.crankset', 'Aynakol ve pedal kolları', 'drive', 'DA1-20',
     ['drive_crankset'], 'z.middle',
     'Üç aynalı ön dişli grubu; pedal kuvvetini zincire verir.',
     {'inspect': CRANK_CHECK, 'remove': CRANK_ARMS},
     part_number='NB-DR-100', ipd_name='Aynakol, 3 aynalı, pedal kollarıyla')
part('drive.chainrings', 'Aynalar', 'drive.crankset', 'DA1-20',
     ['drive_crankset'], 'z.middle', '22, 32 ve 42 dişli çelik aynalar.',
     {'inspect': CRANK_CHECK, 'replace': CHAINRING}, quantity=3,
     part_number='NB-DR-130', ipd_name='Ayna, 42 diş')
part('drive.crank_arms', 'Pedal kolları', 'drive.crankset', 'DA1-20',
     ['drive_crankset'], 'z.middle',
     '170 mm alüminyum kollar; kare göbekli mile cıvatayla takılır.',
     {'inspect': CRANK_CHECK, 'remove': CRANK_ARMS}, quantity=2,
     part_number='NB-DR-140', ipd_name='Pedal kolu, 170 mm, kare göbek')
part('drive.bottom_bracket', 'Orta göbek', 'drive.crankset', 'DA1-20',
     ['drive_bottom_bracket'], 'z.middle',
     'Pedal kollarının döndüğü rulmanlı mil.',
     {'inspect': CRANK_CHECK, 'replace': BOTTOM_BRACKET},
     part_number='NB-DR-110', ipd_name='Orta göbek, kartuş, kare mil, '
     'BSA 68 × 122,5 mm')
part('drive.front_derailleur', 'Ön vites değiştirici', 'drive', 'DA1-20',
     ['drive_front_derailleur'], 'z.middle',
     'Zinciri üç ayna arasında kaydırır.', {'adjust': FD_ADJUST},
     part_number='NB-DR-120', ipd_name='Ön vites değiştirici, kelepçeli, '
     '31,8 mm')
part('drive.chain', 'Zincir', 'drive', 'DA1-10', ['drive_chain'],
     'z.middle', 'Aynakoldaki gücü arka dişliye taşır.',
     {'isolate': CHAIN_ISOLATE, 'measure': CHAIN_MEASURE,
      'lubricate': CHAIN_LUBE, 'remove': CHAIN_REMOVE,
      'install': CHAIN_INSTALL},
     part_number='NB-DR-200', ipd_name='Zincir, 8 vites, 116 bakla')
part('drive.cassette', 'Kaset', 'drive', 'DA1-30', ['drive_cassette'],
     'z.rear', 'Arka tekerlekteki 8 dişli; 11-32 diş.',
     {'inspect': CASSETTE_CHECK, 'replace': CASSETTE},
     part_number='NB-DR-300', ipd_name='Kaset, 8 dişli, 11-32')
part('drive.lockring', 'Kaset kilit somunu', 'drive.cassette', 'DA1-30',
     ['drive_cassette'], 'z.rear',
     'Kaseti serbest çark gövdesinde tutar.',
     {'inspect': CASSETTE_CHECK}, part_number='NB-DR-310',
     ipd_name='Kaset kilit somunu, 11 diş')
part('drive.rear_derailleur', 'Arka vites değiştirici', 'drive', 'DA1-40',
     ['drive_derailleur'], 'z.rear',
     'Zinciri kasetteki dişliler arasında kaydırır ve gergin tutar.',
     {'adjust': RD_ADJUST, 'inspect': HANGER_CHECK, 'replace': RD_REPLACE},
     part_number='NB-DR-400', ipd_name='Arka vites değiştirici, 8 vites, '
     'uzun kafes')
part('drive.hanger', 'Vites askısı', 'drive.rear_derailleur', 'DA1-40',
     ['drive_derailleur'], 'z.rear',
     'Arka vites değiştiriciyi kadroya bağlayan, darbede önce bükülen '
     'parça.', {'inspect': HANGER_CHECK, 'replace': HANGER_REPLACE},
     part_number='NB-DR-410', ipd_name='Vites askısı')
part('drive.jockey_wheels', 'Makaralar', 'drive.rear_derailleur',
     'DA1-40', ['drive_derailleur'], 'z.rear',
     'Zinciri kılavuzlayan ve geren iki makara.', {'replace': JOCKEY},
     quantity=2, part_number='NB-DR-420', ipd_name='Makara, 11 diş')
part('drive.pedals', 'Pedallar', 'drive', 'DA1-50', ['drive_pedals'],
     'z.middle', 'Platform pedallar; sol pedal ters dişlidir.',
     {'replace': PEDALS, 'lubricate': PEDAL_SERVICE},
     part_number='NB-DR-500', ipd_name='Pedal takımı, platform, 9/16"')
part('drive.pedal_bearings', 'Pedal rulmanları', 'drive.pedals', 'DA1-50',
     ['drive_pedals'], 'z.middle',
     'Pedal gövdesinin mil üzerinde döndüğü bilyalı yataklar.',
     {'lubricate': PEDAL_SERVICE}, quantity=2, part_number='NB-DR-510',
     ipd_name='Pedal rulman takımı (koni, bilya, toz kapağı)')
part('drive.shift_cables', 'Vites telleri', 'drive', 'DA1-60',
     ['cables_shift'], 'z.cockpit',
     'Vites kollarındaki hareketi vites değiştiricilere taşır.',
     {'adjust': RD_ADJUST, 'replace': SHIFT_CABLES,
      'lubricate': SHIFT_CABLE_LUBE},
     quantity=2, part_number='NB-DR-600', ipd_name='Vites teli ve kılıfı')
part('drive.shift_cable_rear', 'Arka vites teli', 'drive.shift_cables',
     'DA1-60', ['cables_shift'], 'z.rear',
     'Sağ vites kolundan arka vites değiştiriciye giden tel ve kılıf.',
     {'replace': SHIFT_CABLES}, part_number='NB-DR-610',
     ipd_name='Vites teli 2100 mm ve 4 mm kılıf, arka')
part('drive.shift_cable_front', 'Ön vites teli', 'drive.shift_cables',
     'DA1-60', ['cables_shift'], 'z.middle',
     'Sol vites kolundan ön vites değiştiriciye giden tel ve kılıf.',
     {'replace': SHIFT_CABLES}, part_number='NB-DR-620',
     ipd_name='Vites teli 2100 mm ve 4 mm kılıf, ön')

part('brakes', 'Fren sistemi', None, 'DA2',
     ['brakes_front', 'brakes_rear', 'brakes_front_rotor',
      'brakes_rear_rotor', 'cables_brake'], 'z.middle',
     'İki tekerlekte telle çalışan disk frenler.',
     {'isolate': BRAKE_ISOLATE, 'inspect': BRAKE_CHECK,
      'adjust': BRAKE_ADJUST},
     part_number='NB-BR-000', ipd_name='Fren sistemi takımı')
for side, name, zone, figure_node in (
        ('front', 'Ön', 'z.front', 'brakes_front'),
        ('rear', 'Arka', 'z.rear', 'brakes_rear')):
    part(f'brakes.{side}', f'{name} disk fren', 'brakes', 'DA2-10',
         [f'brakes_{side}'], zone,
         'Telle çalışan mekanik kaliper ve balataları.',
         {'isolate': BRAKE_ISOLATE, 'adjust': BRAKE_ADJUST,
          'replace': CALIPER},
         part_number='NB-BR-100', ipd_name='Mekanik disk kaliper')
    part(f'brakes.{side}.pads', f'{name} fren balatası', f'brakes.{side}',
         'DA2-10', [f'brakes_{side}'], zone,
         'Diske bastırılarak tekerleği yavaşlatan sürtünme parçaları.',
         {'measure': PAD_MEASURE, 'clean': BRAKE_CLEAN, 'replace': PADS},
         part_number='NB-BR-110', ipd_name='Fren balatası çifti, organik')
    part(f'brakes.{side}.adapter', f'{name} kaliper adaptörü',
         f'brakes.{side}', 'DA2-10', [f'brakes_{side}'], zone,
         'Kaliperi çatala ya da kadroya bağlayan ara parça.',
         {'replace': CALIPER}, part_number='NB-BR-120',
         ipd_name='Kaliper adaptörü, 160 mm')
    part(f'brakes.{side}.rotor', f'{name} fren diski', f'brakes.{side}',
         'DA2-20', [f'brakes_{side}_rotor'], zone,
         'Göbeğe altı cıvatayla bağlı 160 mm çelik disk.',
         {'inspect': ROTOR_CHECK, 'adjust': ROTOR_TRUE,
          'replace': ROTOR_REPLACE},
         part_number='NB-BR-200', ipd_name='Fren diski, 160 mm, 6 cıvatalı')
part('brakes.cables', 'Fren telleri', 'brakes', 'DA2-30', ['cables_brake'],
     'z.cockpit', 'Fren kolundaki kuvveti kalipere taşır.',
     {'inspect': BRAKE_LEVER_CHECK, 'adjust': BRAKE_ADJUST,
      'replace': BRAKE_CABLES},
     quantity=2, part_number='NB-BR-300', ipd_name='Fren teli ve kılıfı')
part('brakes.cable_front', 'Ön fren teli', 'brakes.cables', 'DA2-30',
     ['cables_brake'], 'z.front',
     'Sol fren kolundan çatal boyunca ön kalipere iner.',
     {'replace': BRAKE_CABLES}, part_number='NB-BR-310',
     ipd_name='Fren teli 1700 mm ve 5 mm kılıf, ön')
part('brakes.cable_rear', 'Arka fren teli', 'brakes.cables', 'DA2-30',
     ['cables_brake'], 'z.middle',
     'Sağ fren kolundan üst boru boyunca arka kalipere gider.',
     {'replace': BRAKE_CABLES}, part_number='NB-BR-320',
     ipd_name='Fren teli 1700 mm ve 5 mm kılıf, arka')

for side, name, zone in (('front', 'Ön', 'z.front'),
                         ('rear', 'Arka', 'z.rear')):
    n = f'wheel_{side}'
    part(f'wheel.{side}', f'{name} tekerlek', None, 'DA3',
         [f'{n}_tire', f'{n}_tube', f'{n}_rim', f'{n}_spokes', f'{n}_hub'],
         zone, 'Lastik, iç lastik, jant, teller ve göbek.',
         {'isolate': WHEEL_ISOLATE, 'inspect': WHEEL_CHECK,
          'remove': WHEEL_REMOVE, 'install': WHEEL_INSTALL},
         part_number='NB-WH-100' if side == 'front' else 'NB-WH-200',
         ipd_name=f'{name} tekerlek, takım')
    part(f'wheel.{side}.tire', f'{name} dış lastik', f'wheel.{side}',
         'DA3-10', [f'{n}_tire'], zone,
         'Tırtıllı arazi lastiği, 27,5 × 2,25.',
         {'inspect': TIRE_CHECK, 'refill': INFLATE, 'replace': TIRE},
         part_number='NB-WH-310', ipd_name='Dış lastik, 27,5 × 2,25')
    part(f'wheel.{side}.tube', f'{name} iç lastik', f'wheel.{side}',
         'DA3-10', [f'{n}_tube'], zone,
         'Havayı tutan lastik; otomobil sibobludur.',
         {'replace': TUBE, 'refill': SEALANT},
         part_number='NB-WH-320',
         ipd_name='İç lastik, 27,5 × 2,1-2,4, otomobil sibopu')
    part(f'wheel.{side}.valve', f'{name} sibop', f'wheel.{side}.tube',
         'DA3-10', [f'{n}_tube'], zone,
         'İç lastiğin otomobil tipi sibobu; içi sökülüp değiştirilebilir.',
         {'replace': VALVE, 'refill': INFLATE}, part_number='NB-WH-325',
         ipd_name='Sibop içi, otomobil tipi')
    part(f'wheel.{side}.rim', f'{name} jant', f'wheel.{side}', 'DA3-20',
         [f'{n}_rim'], zone, 'Çift cidarlı alüminyum jant, 32 delik.',
         {'inspect': RIM_CHECK, 'adjust': TRUING},
         part_number='NB-WH-330', ipd_name='Jant, 27,5", 32 delik')
    part(f'wheel.{side}.rim_tape', f'{name} jant bandı', f'wheel.{side}.rim',
         'DA3-20', [f'{n}_rim'], zone,
         'Tel deliklerini örterek iç lastiği korur.',
         {'inspect': RIM_CHECK, 'replace': TUBE}, part_number='NB-WH-335',
         ipd_name='Jant bandı, 584 × 19 mm')
    part(f'wheel.{side}.spokes', f'{name} teller', f'wheel.{side}',
         'DA3-20', [f'{n}_spokes'], zone,
         '32 tel; jantı göbeğe gergin bağlar.',
         {'measure': SPOKE_TENSION, 'adjust': TRUING,
          'replace': SPOKE_REPLACE},
         quantity=32, part_number='NB-WH-340', ipd_name='Jant teli, 2 mm')
    part(f'wheel.{side}.hub', f'{name} göbek', f'wheel.{side}', 'DA3-30',
         [f'{n}_hub'], zone, 'Rulmanlı göbek, çabuk sökme mandallı.',
         {'inspect': HUB_CHECK, 'adjust': HUB_ADJUST,
          'lubricate': HUB_SERVICE},
         part_number='NB-WH-350' if side == 'front' else 'NB-WH-360',
         ipd_name=f'{name} göbek, 6 cıvatalı disk yuvalı, 32 delik')
    part(f'wheel.{side}.bearings', f'{name} göbek rulmanları',
         f'wheel.{side}.hub', 'DA3-30', [f'{n}_hub'], zone,
         'Koni ve bilyalı (açılıp ayarlanabilen) göbek yatakları.',
         {'adjust': HUB_ADJUST, 'lubricate': HUB_SERVICE},
         part_number='NB-WH-352' if side == 'front' else 'NB-WH-362',
         ipd_name='Koni, kontra somun ve 3/16" bilya takımı')
    part(f'wheel.{side}.qr', f'{name} çabuk sökme mandalı',
         f'wheel.{side}.hub', 'DA3-30', [f'{n}_hub'], zone,
         'Tekerleği takımsız söküp takmaya yarayan kamlı mil.',
         {'adjust': QR_ADJUST, 'remove': WHEEL_REMOVE,
          'install': WHEEL_INSTALL},
         part_number='NB-WH-355' if side == 'front' else 'NB-WH-365',
         ipd_name=f'Çabuk sökme mandalı, {"100" if side == "front" else "135"}'
         ' mm')
part('wheel.rear.freehub', 'Serbest çark gövdesi', 'wheel.rear.hub',
     'DA3-30', ['wheel_rear_hub'], 'z.rear',
     'Kasetin oturduğu, pedal çevrilmeyince tekerleğin serbest dönmesini '
     'sağlayan gövde.', {'inspect': HUB_CHECK}, part_number='NB-WH-370',
     ipd_name='Serbest çark gövdesi, 8-10 vites')

ZONES = [
    ('z.front', 'Ön', None), ('z.cockpit', 'Gidon', 'z.front'),
    ('z.middle', 'Orta', None), ('z.rear', 'Arka', None),
]

# --- Arızalar ---------------------------------------------------------------

SYMPTOMS = [
    ('sym.chain_skip', 'Pedala yüklenince zincir boşa atlıyor'),
    ('sym.chain_noise', 'Pedal çevirirken zincirden cızırtı ya da gıcırtı '
     'geliyor'),
    ('sym.chain_drop', 'Zincir dişlilerden düşüyor'),
    ('sym.shift_slow', 'Vites geç geçiyor ya da hiç geçmiyor'),
    ('sym.shift_noise', 'Vites değişmese de arkadan sürekli tıkırtı '
     'geliyor'),
    ('sym.front_shift', 'Ön vites (aynakol) değişmiyor'),
    ('sym.shift_stiff', 'Vites kolu sert çalışıyor'),
    ('sym.shifter_no_return', 'Vites kolu yerine dönmüyor ya da tıklamıyor'),
    ('sym.fd_rub', 'Ön vites değiştiricinin kafesi zincire sürtüyor'),
    ('sym.brake_weak', 'Fren yeterince tutmuyor'),
    ('sym.lever_travel', 'Fren kolu gidona kadar geliyor'),
    ('sym.lever_no_return', 'Fren kolu bırakınca yerine dönmüyor'),
    ('sym.brake_squeal', 'Frenlerken ciyaklama sesi geliyor'),
    ('sym.brake_rub', 'Tekerlek dönerken diskten sürtünme sesi geliyor'),
    ('sym.brake_clunk', 'Frenlerken kaliperden tok bir ses geliyor ya da '
     'kaliper oynuyor'),
    ('sym.flat', 'Lastik iniyor'),
    ('sym.slow_leak', 'Lastik birkaç günde yavaş yavaş iniyor'),
    ('sym.pinch_flat', 'İç lastikte yan yana iki küçük delik var'),
    ('sym.tire_wear', 'Lastik tırtılları aşınmış, viraj ve frenlemede '
     'kayıyor'),
    ('sym.tire_damage', 'Lastik yanağında kesik ya da kabarma var'),
    ('sym.wobble', 'Tekerlek dönerken yalpalıyor'),
    ('sym.wheel_play', 'Tekerlek yanlara oynuyor'),
    ('sym.spoke_ping', 'Sürüşte tellerden çınlama sesi geliyor ya da tel '
     'kopmuş'),
    ('sym.hub_rough', 'Tekerlek elle çevrilince göbekten hışırtı geliyor'),
    ('sym.freehub_slip', 'Pedala basınca pedal boşa dönüyor, tekerlek '
     'itilmiyor'),
    ('sym.crank_creak', 'Pedala basarken orta göbekten gıcırtı geliyor'),
    ('sym.pedal_play', 'Pedal ya da pedal kolu boşluk yapıyor'),
    ('sym.pedal_rough', 'Pedal elle çevrilince takılarak dönüyor'),
    ('sym.fork_knock', 'Çatal çökerken vuruntu sesi geliyor'),
    ('sym.fork_leak', 'Çatal iç borusunda yağ halkası kalıyor'),
    ('sym.fork_sticky', 'Çatal küçük darbelerde çökmüyor, takılarak '
     'çalışıyor'),
    ('sym.fork_bottom', 'Çatal dibe vuruyor ya da çok yumuşak'),
    ('sym.headset_play', 'Ön fren sıkılıyken gidon ileri geri oynuyor'),
    ('sym.steering_notchy', 'Gidon döndürülürken belli bir noktada takılıyor'),
    ('sym.bar_slip', 'Gidon ya da gidon boğazı yerinden kayıyor'),
    ('sym.bar_creak', 'Gidona yüklenince gıcırtı geliyor'),
    ('sym.grip_slip', 'Elcikler gidon üzerinde dönüyor'),
    ('sym.saddle_slip', 'Sele sürüşte aşağı kayıyor'),
    ('sym.saddle_tilt', 'Sele öne ya da arkaya yatıyor'),
    ('sym.seat_creak', 'Selede otururken gıcırtı geliyor'),
    ('sym.frame_crack', 'Kadroda boya çatlağı ya da ezik görünüyor'),
    ('sym.cassette_wobble', 'Kaset göbek üzerinde oynuyor, arkadan tıkırtı '
     'geliyor'),
]

# (id, parça, belirtiler, neden, önem 1-4, arıza bulma, onarım)
FAULTS = [
    ('f.frame.crack', 'frame', ['sym.frame_crack', 'sym.bar_creak'],
     'Kadroda kaynak yerinde ya da boruda çatlak var.', 4, FRAME_CHECK,
     None),

    ('f.headset.loose', 'fork.headset',
     ['sym.headset_play', 'sym.fork_knock'], 'Furç gevşemiş.', 3,
     FORK_CHECK, HEADSET_ADJUST),
    ('f.headset.worn', 'fork.headset', ['sym.steering_notchy'],
     'Furç rulmanları ya da kapları çukurlaşmış.', 2, FORK_ISOLATE, HEADSET_BEARINGS),
    ('f.fork.worn', 'fork.lowers', ['sym.fork_knock', 'sym.fork_sticky'],
     'Çatal burçları aşınmış ya da alt bacak yağı azalmış.', 3,
     FORK_ISOLATE, FORK_SERVICE),
    ('f.fork.seals', 'fork.seals', ['sym.fork_leak', 'sym.fork_sticky'],
     'Toz keçeleri sertleşmiş ya da kir tutmuş; yağ sızdırıyor.', 2,
     FORK_ISOLATE, FORK_SEALS),
    ('f.fork.stanchion', 'fork.stanchions', ['sym.fork_leak'],
     'İç boruda çizik var; keçeyi kesiyor.', 3, FORK_ISOLATE, None),
    ('f.fork.preload', 'fork.spring', ['sym.fork_bottom'],
     'Ön yük sürücü ağırlığına göre az ayarlanmış.', 1, FORK_ISOLATE,
     FORK_SETUP),

    ('f.stem.loose', 'cockpit.stem', ['sym.bar_slip', 'sym.headset_play'],
     'Gidon boğazı cıvataları gevşemiş.', 4, COCKPIT_CHECK, COCKPIT_CHECK),
    ('f.bar.damaged', 'cockpit.bar', ['sym.bar_creak'],
     'Gidon kelepçe kenarında çizilmiş ya da çatlamış.', 4, COCKPIT_CHECK,
     None),
    ('f.grips.worn', 'cockpit.grips', ['sym.grip_slip'],
     'Elcikler aşınmış ya da yağlanmış.', 1, None, GRIPS),
    ('f.shifter.faulty', 'cockpit.shifters',
     ['sym.shifter_no_return', 'sym.shift_slow'],
     'Vites kolunun içindeki mandal mekanizması arızalı.', 2,
     SHIFT_ISOLATE, SHIFTER_REPLACE),
    ('f.brake_lever.sticky', 'cockpit.brake_levers',
     ['sym.lever_no_return'], 'Fren kolu pivotu kurumuş ya da bükülmüş.',
     3, BRAKE_LEVER_ISOLATE, BRAKE_LEVER),

    ('f.seatpost.slip', 'seat.post', ['sym.saddle_slip'],
     'Sele borusu kelepçesi yeterince sıkılmamış.', 1, SEAT_ISOLATE,
     SEAT_HEIGHT),
    ('f.seatpost.creak', 'seat.post', ['sym.seat_creak'],
     'Sele borusu kuru ya da kirli; kadro içinde gıcırdıyor.', 1, NOISES,
     SEATPOST_SERVICE),
    ('f.post_head.loose', 'seat.post_head', ['sym.saddle_tilt'],
     'Sele kelepçesinin cıvatası gevşemiş.', 2, SEAT_ISOLATE,
     SADDLE_ADJUST),

    ('f.chain.worn', 'drive.chain', ['sym.chain_skip', 'sym.chain_noise'],
     'Zincir aşınıp uzamış; dişlilere tam oturmuyor.', 2, CHAIN_MEASURE,
     CHAIN_REMOVE),
    ('f.chain.dry', 'drive.chain', ['sym.chain_noise'],
     'Zincir kurumuş ya da kirlenmiş.', 1, NOISES, CHAIN_LUBE),
    ('f.chain.stiff_link', 'drive.chain',
     ['sym.chain_skip', 'sym.shift_noise'],
     'Zincirde sıkışmış bir bakla var; makaralardan geçerken atlıyor.', 2,
     CHAIN_ISOLATE, CHAIN_LUBE),
    ('f.cassette.worn', 'drive.cassette', ['sym.chain_skip'],
     'Kaset dişlileri aşınmış; yeni zincir en çok kullanılan dişlide '
     'atlıyor.', 2, CHAIN_ISOLATE, CASSETTE),
    ('f.lockring.loose', 'drive.lockring',
     ['sym.cassette_wobble', 'sym.shift_noise'],
     'Kaset kilit somunu gevşemiş.', 2, None, CASSETTE_CHECK),
    ('f.crankset.worn_teeth', 'drive.chainrings',
     ['sym.chain_skip', 'sym.chain_drop'], 'Aynakol dişleri sivrilmiş.',
     2, CRANK_ISOLATE, CHAINRING),
    ('f.crank.loose', 'drive.crank_arms',
     ['sym.pedal_play', 'sym.crank_creak'],
     'Pedal kolu cıvatası gevşemiş; kol kare milde oynuyor.', 3,
     CRANK_ISOLATE, CRANK_ARMS),
    ('f.bottom_bracket.worn', 'drive.bottom_bracket',
     ['sym.crank_creak', 'sym.pedal_play'],
     'Orta göbek rulmanları aşınmış ya da gevşemiş.', 2, CRANK_ISOLATE, BOTTOM_BRACKET),
    ('f.front_derailleur.misadjusted', 'drive.front_derailleur',
     ['sym.front_shift', 'sym.chain_drop'],
     'Ön vites değiştiricinin limit vidaları ya da tel gerginliği ayarsız.',
     1, SHIFT_ISOLATE, FD_ADJUST),
    ('f.front_derailleur.position', 'drive.front_derailleur',
     ['sym.fd_rub'],
     'Ön vites değiştiricinin yüksekliği ya da açısı aynaya göre bozuk.',
     1, None, FD_ADJUST),
    ('f.rear_derailleur.misadjusted', 'drive.rear_derailleur',
     ['sym.shift_slow', 'sym.shift_noise'],
     'Vites teli gerginliği ya da limit vidaları ayarsız.', 1,
     SHIFT_ISOLATE, RD_ADJUST),
    ('f.rear_derailleur.limit', 'drive.rear_derailleur', ['sym.chain_drop'],
     'Limit vidaları ayarsız; zincir en küçük ya da en büyük dişliden '
     'dışarı kaçıyor.', 3, SHIFT_ISOLATE, RD_ADJUST),
    ('f.rear_derailleur.damaged', 'drive.rear_derailleur',
     ['sym.shift_slow', 'sym.chain_drop'],
     'Arka vites değiştiricinin kafesi bükülmüş ya da yayı zayıflamış.',
     3, SHIFT_ISOLATE, RD_REPLACE),
    ('f.hanger.bent', 'drive.hanger',
     ['sym.shift_noise', 'sym.chain_drop', 'sym.shift_slow'],
     'Vites askısı darbe sonucu bükülmüş.', 3, SHIFT_ISOLATE, HANGER_REPLACE),
    ('f.jockey.worn', 'drive.jockey_wheels',
     ['sym.shift_noise', 'sym.chain_noise'],
     'Makara dişleri aşınmış ya da yatağı kurumuş.', 1, SHIFT_ISOLATE, JOCKEY),
    ('f.pedal.bearing', 'drive.pedals', ['sym.pedal_play',
                                         'sym.crank_creak'],
     'Pedal rulmanı aşınmış ya da pedal kola tam sıkılmamış.', 2, NOISES,
     PEDALS),
    ('f.pedal_bearings.dry', 'drive.pedal_bearings', ['sym.pedal_rough'],
     'Pedal rulmanlarının gresi kurumuş ya da içine su girmiş.', 1, None,
     PEDAL_SERVICE),
    ('f.shift_cable.stretched', 'drive.shift_cables',
     ['sym.shift_slow', 'sym.front_shift'],
     'Vites teli esnemiş ya da kılıfı kirlenmiş.', 1, SHIFT_ISOLATE,
     RD_ADJUST),
    ('f.shift_cable_rear.frayed', 'drive.shift_cable_rear',
     ['sym.shift_stiff', 'sym.shift_slow'],
     'Arka vites teli paslanmış ya da lifleri kopmaya başlamış.', 2,
     SHIFT_ISOLATE, SHIFT_CABLES),
    ('f.shift_cable_front.dirty', 'drive.shift_cable_front',
     ['sym.shift_stiff', 'sym.front_shift'],
     'Ön vites teli kılıf içinde kirlenmiş, sürtünüyor.', 1, SHIFT_ISOLATE,
     SHIFT_CABLE_LUBE),

    ('f.brake_front.pads_worn', 'brakes.front.pads',
     ['sym.brake_weak', 'sym.brake_squeal', 'sym.lever_travel'],
     'Ön balatalar aşınmış.', 4, BRAKE_ISOLATE, PADS),
    ('f.brake_front.contaminated', 'brakes.front.pads',
     ['sym.brake_weak', 'sym.brake_squeal'],
     'Ön disk ya da balatalar yağlanmış.', 4, BRAKE_ISOLATE, PADS),
    ('f.brake_front.rotor_bent', 'brakes.front.rotor', ['sym.brake_rub'],
     'Ön disk eğrilmiş.', 2, BRAKE_ISOLATE, ROTOR_TRUE),
    ('f.brake_front.rotor_worn', 'brakes.front.rotor',
     ['sym.brake_weak', 'sym.lever_travel'],
     "Ön disk 1,5 mm'nin altına incelmiş.", 4, BRAKE_ISOLATE, ROTOR_REPLACE),
    ('f.brake_front.caliper_misaligned', 'brakes.front',
     ['sym.brake_rub', 'sym.lever_travel'],
     'Ön kaliper diske ortalı değil ya da balata boşluğu fazla.', 2,
     BRAKE_ISOLATE, BRAKE_ADJUST),
    ('f.brake_front.adapter_loose', 'brakes.front.adapter',
     ['sym.brake_clunk'],
     'Ön kaliper adaptörünün cıvataları gevşemiş.', 4, BRAKE_ISOLATE, CALIPER),
    ('f.tube_front.puncture', 'wheel.front.tube', ['sym.flat'],
     'Ön iç lastik delinmiş.', 3, WHEEL_ISOLATE, TUBE),
    ('f.brake_rear.pads_worn', 'brakes.rear.pads',
     ['sym.brake_weak', 'sym.brake_squeal', 'sym.lever_travel'],
     'Arka balatalar aşınmış.', 4, BRAKE_ISOLATE, PADS),
    ('f.brake_rear.contaminated', 'brakes.rear.pads',
     ['sym.brake_weak', 'sym.brake_squeal'],
     'Arka disk ya da balatalar yağlanmış.', 4, BRAKE_ISOLATE, PADS),
    ('f.brake_rear.rotor_bent', 'brakes.rear.rotor', ['sym.brake_rub'],
     'Arka disk eğrilmiş.', 2, BRAKE_ISOLATE, ROTOR_TRUE),
    ('f.brake_rear.rotor_worn', 'brakes.rear.rotor',
     ['sym.brake_weak', 'sym.lever_travel'],
     "Arka disk 1,5 mm'nin altına incelmiş.", 4, BRAKE_ISOLATE, ROTOR_REPLACE),
    ('f.brake_rear.caliper_misaligned', 'brakes.rear',
     ['sym.brake_rub', 'sym.lever_travel'],
     'Arka kaliper diske ortalı değil ya da balata boşluğu fazla.', 2,
     BRAKE_ISOLATE, BRAKE_ADJUST),
    ('f.tube_rear.puncture', 'wheel.rear.tube', ['sym.flat'],
     'Arka iç lastik delinmiş.', 3, WHEEL_ISOLATE, TUBE),
    ('f.brake_cable.stretched', 'brakes.cables',
     ['sym.lever_travel', 'sym.brake_weak'],
     'Fren teli esnemiş; kol boşluğu artmış.', 4, BRAKE_ISOLATE,
     BRAKE_ADJUST),
    ('f.brake_cable_front.frayed', 'brakes.cable_front',
     ['sym.lever_no_return', 'sym.brake_weak'],
     'Ön fren teli paslanmış ya da kılıfı ezilmiş; tel sürtünüyor.', 4,
     BRAKE_LEVER_ISOLATE, BRAKE_CABLES),
    ('f.brake_cable_rear.frayed', 'brakes.cable_rear',
     ['sym.lever_no_return', 'sym.brake_weak'],
     'Arka fren teli paslanmış ya da kılıfı ezilmiş; tel sürtünüyor.', 4,
     BRAKE_LEVER_ISOLATE, BRAKE_CABLES),

    ('f.rim.out_of_true', 'wheel.rear.rim', ['sym.wobble', 'sym.brake_rub'],
     'Arka jant eğrilmiş.', 2, WHEEL_ISOLATE, TRUING),
    ('f.spokes.loose', 'wheel.rear.spokes', ['sym.wobble', 'sym.spoke_ping'],
     'Arka tekerlekte teller gevşemiş.', 2, WHEEL_ISOLATE, TRUING),
    ('f.spokes_front.broken', 'wheel.front.spokes',
     ['sym.spoke_ping', 'sym.wobble'], 'Ön tekerlekte tel kopmuş.', 3,
     WHEEL_ISOLATE, SPOKE_REPLACE),
    ('f.rim_tape.shifted', 'wheel.rear.rim_tape',
     ['sym.flat', 'sym.slow_leak'],
     'Jant bandı kaymış; tel delikleri iç lastiği deliyor.', 2,
     WHEEL_ISOLATE, TUBE),
    ('f.valve_front.leak', 'wheel.front.valve', ['sym.slow_leak'],
     'Sibop içi gevşemiş ya da contası bozulmuş.', 2, WHEEL_ISOLATE,
     VALVE),
    ('f.tire_front.pressure_low', 'wheel.front.tire',
     ['sym.pinch_flat', 'sym.flat'],
     'Lastik basıncı düşük kalmış; iç lastik darbede jantla taş arasında '
     'sıkışıyor.', 2, WHEEL_ISOLATE, INFLATE),
    ('f.tire_front.worn', 'wheel.front.tire', ['sym.tire_wear'],
     'Ön lastiğin tırtılları aşınmış.', 2, None, TIRE),
    ('f.tire_rear.damaged', 'wheel.rear.tire',
     ['sym.tire_damage', 'sym.flat'],
     'Arka lastiğin yanağı kesilmiş ya da kabarmış.', 3, WHEEL_ISOLATE, TIRE),
    ('f.hub_front.play', 'wheel.front.bearings', ['sym.wheel_play'],
     'Ön göbek rulmanında boşluk var.', 3, WHEEL_ISOLATE, HUB_ADJUST),
    ('f.qr_front.loose', 'wheel.front.qr', ['sym.wheel_play'],
     'Ön çabuk sökme mandalı gevşek kapatılmış.', 4, WHEEL_ISOLATE,
     QR_ADJUST),
    ('f.hub_rear.worn', 'wheel.rear.bearings',
     ['sym.hub_rough', 'sym.wheel_play'],
     'Arka göbek rulmanlarının gresi kurumuş, koni ve bilyalar aşınmış.',
     2, WHEEL_ISOLATE, HUB_SERVICE),
    ('f.freehub.slipping', 'wheel.rear.freehub', ['sym.freehub_slip'],
     'Serbest çark gövdesinin tırnakları tutmuyor.', 3, HUB_CHECK, None),
]

# Prosedürdeki yedek parça adı → IPD'deki parça; numaralar aynı olur.

# Ek arızaların belirtileri ve arızaları.
SYMPTOMS += [
    ('sym.rear_wheel_shift', 'Arka tekerlek kadroda kayıyor, pedala '
     'yüklenince yamuluyor'),
    ('sym.saddle_creak', 'Sele raylarından ya da sele kelepçesinden '
     'gıcırtı geliyor'),
    ('sym.chainring_click', 'Her pedal turunda aynakoldan tık sesi '
     'geliyor'),
]

FAULTS += [
    ('f.qr_rear.loose', 'wheel.rear.qr',
     ['sym.rear_wheel_shift', 'sym.wheel_play'],
     'Arka çabuk sökme mandalı gevşek kapatılmış; tekerlek pedal '
     'kuvvetiyle kayıyor.', 3, WHEEL_ISOLATE, QR_ADJUST),
    ('f.hub_front.dry', 'wheel.front.bearings', ['sym.hub_rough'],
     'Ön göbek rulmanlarının gresi kurumuş ya da içine su girmiş.', 1,
     WHEEL_ISOLATE, HUB_SERVICE),
    ('f.valve_rear.leak', 'wheel.rear.valve', ['sym.slow_leak'],
     'Arka sibobun içi gevşemiş ya da sibop dibinden kaçırıyor.', 1,
     WHEEL_ISOLATE, VALVE),
    ('f.tire_rear.worn', 'wheel.rear.tire', ['sym.tire_wear'],
     'Arka lastiğin tırtılları aşınmış; çekiş azalmış.', 2, WHEEL_ISOLATE,
     TIRE),
    ('f.rim_front.out_of_true', 'wheel.front.rim', ['sym.wobble'],
     'Ön jant darbeyle eğrilmiş.', 2, WHEEL_ISOLATE, TRUING),
    ('f.rim_tape_front.shifted', 'wheel.front.rim_tape', ['sym.flat'],
     'Ön jant bandı kaymış; tel deliği iç lastiği içeriden kesiyor.', 1,
     WHEEL_ISOLATE, TUBE),
    ('f.tire_rear.pressure_low', 'wheel.rear.tire',
     ['sym.pinch_flat', 'sym.flat'],
     'Arka lastik düşük basınçla sürülmüş; iç lastik darbede jantla taş '
     'arasında sıkışıyor.', 2, WHEEL_ISOLATE, INFLATE),
    ('f.brake_rear.adapter_loose', 'brakes.rear.adapter',
     ['sym.brake_clunk'],
     'Arka kaliper adaptörünün cıvataları gevşemiş.', 3, BRAKE_ISOLATE,
     CALIPER),
    ('f.chainring.bolts', 'drive.chainrings',
     ['sym.chainring_click', 'sym.crank_creak'],
     'Aynakol cıvataları gevşemiş; aynalar birbirine göre oynuyor.', 2,
     CRANK_ISOLATE, CRANK_CHECK),
    ('f.spokes_rear.broken', 'wheel.rear.spokes',
     ['sym.spoke_ping', 'sym.wobble', 'sym.brake_rub'],
     'Arka tekerlekte tel kopmuş; jant kopan telin karşı yanına eğilmiş.',
     3, WHEEL_ISOLATE, SPOKE_REPLACE),
    ('f.saddle.creak', 'seat.saddle', ['sym.saddle_creak'],
     'Sele rayları ile kelepçe arasındaki temas kurumuş ya da kirlenmiş.',
     1, SEAT_ISOLATE, SADDLE_ADJUST),
]

SPARE_PARTS = {
    'Zincir, 8 vites': 'drive.chain',
    'Kaset, 8 dişli': 'drive.cassette',
    'Pedal takımı': 'drive.pedals',
    'Fren balatası çifti': 'brakes.front.pads',
    'İç lastik': 'wheel.front.tube',
    'Dış lastik, 27,5 × 2,25': 'wheel.front.tire',
    'Sibop içi (otomobil tipi)': 'wheel.front.valve',
    'Jant teli, 2 mm, nipeliyle': 'wheel.front.spokes',
    'Fren diski, 160 mm': 'brakes.front.rotor',
    'Mekanik disk kaliper': 'brakes.front',
    'Fren teli ve kılıfı takımı': 'brakes.cables',
    'Fren kolu': 'cockpit.brake_levers',
    'Vites teli ve kılıfı takımı': 'drive.shift_cables',
    'Tetik vites kolu, sağ 8 vites': 'cockpit.shifters',
    'Arka vites değiştirici, 8 vites': 'drive.rear_derailleur',
    'Vites askısı': 'drive.hanger',
    'Makara takımı, 11 diş': 'drive.jockey_wheels',
    'Orta göbek kartuşu, kare mil': 'drive.bottom_bracket',
    'Ayna, 42 diş': 'drive.chainrings',
    'Elcik çifti': 'cockpit.grips',
    'Toz keçesi takımı': 'fork.seals',
    'Furç rulmanı takımı': 'fork.headset',
}


# --- Söyleyişler ------------------------------------------------------------
#
# Sürücünün arızayı kendi sözleriyle anlatışı; teşhis serbest metni bunlarla
# eşleştirir. Her metin arızaya bir belirti olarak eklenir
# (`Content.add_phrasings`). Ön ve arka parçalardaki aynı arızalar ancak bu
# söyleyişlerle birbirinden ayrılır.

PHRASINGS = {
    # Kadro, çatal ve kumanda
    'f.frame.crack': [
        'Kadronun kaynak yerinde boyada ince bir çizgi var, gittikçe uzuyor',
        'Ayağa kalkıp pedal basınca kadrodan çıt sesi geliyor',
    ],
    'f.headset.loose': [
        'Ön freni sıkıp bisikleti ileri geri itince gidon tarafından tık '
        'tık ses geliyor',
        'Kasislerde ön taraftan takırtı geliyor, gidon boğazı oynuyor gibi',
    ],
    'f.headset.worn': [
        'Gidonu çevirince ortada bir yerde tık diye oturuyor',
        'Düz giderken gidon kendiliğinden bir noktada duruyor',
    ],
    'f.fork.worn': [
        'Çatal çökerken içinden tok bir vuruntu geliyor',
        'Ön tekerleği tutup sallayınca çatal bacaklarında boşluk var',
    ],
    'f.fork.seals': [
        'Çatalın toz keçesinin çevresinde yağlı kir birikiyor',
        'Çatal iç borusunda her sürüşten sonra yağ izi kalıyor',
    ],
    'f.fork.stanchion': [
        'Çatal iç borusunda tırnağa takılan bir çizik var',
        'Çizik olan yerden yağ sızıyor',
    ],
    'f.fork.preload': [
        'Çatal küçük bir düşüşte sonuna kadar çöküp dibe vuruyor',
        'Çatal çok sert, hiç çalışmıyor gibi',
    ],
    'f.stem.loose': [
        'Ön tekerlek düz giderken gidon yamuk duruyor',
        'Gidona yüklenince gidon boğazıyla birlikte dönüyor',
    ],
    'f.bar.damaged': [
        'Gidonun kelepçe kenarında çizik ve çatlak var',
        'Düşüşten sonra gidon eğildi',
    ],
    'f.grips.worn': [
        'Elcikler yağmurda gidonda dönüyor',
        'Elciklerin lastiği yırtılmış ve kaygan',
    ],
    'f.shifter.faulty': [
        'Vites koluna basıyorum ama tık gelmiyor, kol boşa gidiyor',
        'Vites kolu basılı kalıyor, geri dönmüyor',
    ],
    'f.brake_lever.sticky': [
        'Fren kolunu bırakınca yavaşça yerine dönüyor',
        'Fren kolu düşüşten sonra eğildi ve takılıyor',
    ],
    'f.seatpost.slip': [
        'Sürerken sele yavaş yavaş aşağı iniyor',
        'Sele yüksekliği her sürüşte değişiyor',
    ],
    'f.seatpost.creak': [
        'Selede otururken sele borusunun kadroya girdiği yerden gıcırtı '
        'geliyor',
        'Ayakta pedal çevirince ses kesiliyor, oturunca başlıyor',
    ],
    'f.post_head.loose': [
        'Sele burnu aşağı ya da yukarı düştü',
        'Sele kasiste geriye yattı',
    ],
    # Aktarma organları
    'f.chain.worn': [
        'Yokuşta pedala yüklenince zincir tak diye boşa kaçıyor',
        'Zincir çok eski, ölçer takınca tam oturuyor',
        'Zincir aynakolun dişlerinden ileri doğru kalkıyor',
    ],
    'f.chain.dry': [
        'Pedal çevirirken zincirden cızırtı geliyor',
        'Yağmurdan sonra zincir paslanmış ve gıcırdıyor',
    ],
    'f.chain.stiff_link': [
        'Arka makaralardan geçerken zincir her turda bir kez sıçrıyor',
        'Pedalı geri çevirince zincirde bir bakla kıvrık kalıyor',
    ],
    'f.cassette.worn': [
        'Yeni zincir taktım, en çok kullandığım viteste zincir atlıyor',
        'Kasetin dişleri sivri ve köpek balığı yüzgeci gibi',
    ],
    'f.lockring.loose': [
        'Arka dişliler göbek üzerinde elle oynatılınca sallanıyor',
        'Kaset tarafından tıkırtı geliyor, kilit somunu gevşek',
    ],
    'f.crankset.worn_teeth': [
        'Ön aynanın dişleri sivrilmiş, zincir dişliden düşüyor',
        'Zincir yeni olmasına rağmen ön aynadan kayıyor',
    ],
    'f.crank.loose': [
        'Pedal kolu milde oynuyor, her turda tık sesi geliyor',
        'Pedal kolunun cıvatası gevşemiş, kol sallanıyor',
    ],
    'f.bottom_bracket.worn': [
        'Pedal kollarını yanlara itince orta göbekte boşluk var',
        'Pedalı çevirirken orta göbekten hırıltı ve tıkırtı geliyor',
    ],
    'f.front_derailleur.misadjusted': [
        'Ön vites büyük aynaya çıkmıyor',
        'Ön viteste zincir içe ya da dışa düşüyor',
    ],
    'f.front_derailleur.position': [
        'Ön vites değiştiricinin kafesi zincire sürtüyor, her turda ses '
        'var',
        'Ön vites kafesi eğri duruyor',
    ],
    'f.rear_derailleur.misadjusted': [
        'Arka vitesler bir sonraki dişliye geç geçiyor, iki dişli arasında '
        'kalıyor',
        'Arkada vites kendi kendine atlıyor, tıkırdıyor',
    ],
    'f.rear_derailleur.limit': [
        'En hafif viteste zincir tellere doğru kaçıyor',
        'En ağır viteste zincir kasetten kadroya düşüyor',
    ],
    'f.rear_derailleur.damaged': [
        'Arka vites değiştirici düşüşten sonra içe doğru eğildi',
        'Vites değiştiricinin kafesi yamuk ve zincir gevşek kalıyor',
    ],
    'f.hanger.bent': [
        'Bisiklet yan yattıktan sonra vitesler bozuldu',
        'Arkadan bakınca vites değiştirici kasetle aynı hizada değil',
    ],
    'f.jockey.worn': [
        'Arka vites değiştiricinin küçük tekerleklerinin dişleri aşınmış',
        'Makaralardan hırıltı geliyor',
    ],
    'f.pedal.bearing': [
        'Pedalın kendisi aks üzerinde yanlara oynuyor',
        'Pedala basınca pedaldan tıkırtı geliyor',
    ],
    'f.pedal_bearings.dry': [
        'Pedalı elle çevirince takılarak, kumlu gibi dönüyor',
        'Pedal elle çevrilince hemen duruyor',
    ],
    'f.shift_cable.stretched': [
        'Yeni bisiklette birkaç hafta sonra vitesler kaymaya başladı',
        'Vites ayarı sürekli bozuluyor',
    ],
    'f.shift_cable_rear.frayed': [
        'Arka vites kolunda tel ucunun lifleri dağılmış',
        'Arka vites kolu çok sert basıyor',
    ],
    'f.shift_cable_front.dirty': [
        'Ön vites kolu sert ve vites geç değişiyor',
        'Ön vites telinin kılıfı çamurlu ve paslı',
    ],
    # Frenler
    'f.brake_front.pads_worn': [
        'Ön frenden demir sürtme sesi geliyor',
        'Ön fren kolunu gidona kadar sıkmak gerekiyor',
    ],
    'f.brake_front.contaminated': [
        'Ön fren zincir yağı bulaştıktan sonra tutmuyor ve ötüyor',
        'Ön fren ıslakken korna gibi ötüyor',
    ],
    'f.brake_front.rotor_bent': [
        'Ön tekerlek dönerken diskten şı şı diye sürtme sesi geliyor',
        'Ön disk dönerken kaliperin içinde yalpalıyor',
    ],
    'f.brake_front.rotor_worn': [
        'Ön disk incelmiş ve kenarında basamak oluşmuş',
        'Ön balatalar yeni ama fren yine zayıf',
    ],
    'f.brake_front.caliper_misaligned': [
        'Ön teker elle çevrilince balata diske hafifçe sürtüyor',
        'Ön tekerleği söküp taktıktan sonra fren sürtmeye başladı',
    ],
    'f.brake_front.adapter_loose': [
        'Ön freni sıkınca çatal tarafında kaliper oynuyor, tok ses geliyor',
        'Ön kaliperin cıvatası gevşemiş',
    ],
    'f.brake_rear.pads_worn': [
        'Arka frenden metal sürtme sesi geliyor',
        'Arka fren kolu gidona kadar geliyor',
    ],
    'f.brake_rear.contaminated': [
        'Arka fren yağlanmış gibi kaygan ve ötüyor',
        'Zinciri yağlarken arka diske yağ sıçradı, fren tutmuyor',
    ],
    'f.brake_rear.rotor_bent': [
        'Arka tekerlek dönerken diskten sürtme sesi geliyor',
        'Arka disk düşüşten sonra eğildi',
    ],
    'f.brake_rear.rotor_worn': [
        'Arka disk çok incelmiş, kenarında çıkıntı var',
        'Arka balatalar değişti ama arka fren hâlâ zayıf',
    ],
    'f.brake_rear.caliper_misaligned': [
        'Arka teker elle çevrilince balata diske sürtüyor',
        'Arka tekerlek takıldıktan sonra arka fren sürtmeye başladı',
    ],
    'f.brake_cable.stretched': [
        'İki fren kolu da her hafta biraz daha gidona yaklaşıyor',
        'Fren kolu boşluğu yeni bisiklette çabuk arttı',
    ],
    'f.brake_cable_front.frayed': [
        'Ön fren teli kaliper ucunda dağılmış',
        'Ön fren kolu ağır çekiliyor ve geç dönüyor',
    ],
    'f.brake_cable_rear.frayed': [
        'Arka fren teli paslanmış ve kılıfta sürtüyor',
        'Arka fren kolu ağır çekiliyor ve geç dönüyor',
    ],
    # Tekerlekler
    'f.tube_front.puncture': [
        'Ön lastik bir anda indi',
        'Ön lastiğe diken batmış',
    ],
    'f.tube_rear.puncture': [
        'Arka lastik bir anda indi',
        'Arka lastikte çivi ya da cam parçası var',
    ],
    'f.rim.out_of_true': [
        'Arka tekerlek dönerken yanlara sallanıyor',
        'Arka jant fren diskine göre değil, kadroya göre yalpalıyor',
    ],
    'f.spokes.loose': [
        'Arka tekerlekteki teller elle sıkınca gevşek geliyor',
        'Arka tekerlekten tıkırtı ve tel çınlaması geliyor',
    ],
    'f.spokes_front.broken': [
        'Ön tekerlekte bir tel kopmuş, sarkıyor',
        'Ön jant birden eğildi ve çatala yaklaşıyor',
    ],
    'f.rim_tape.shifted': [
        'Arka iç lastik hep jant tarafından deliniyor',
        'Arka iç lastiğin iç yüzünde küçük kesikler var',
    ],
    'f.valve_front.leak': [
        'Ön lastik birkaç günde iniyor, sibopta sabun köpürüyor',
        'Ön sibobun ucu eğilmiş ve hava kaçırıyor',
    ],
    'f.tire_front.pressure_low': [
        'Ön iç lastikte yan yana iki delik var',
        'Taşa çarptıktan sonra ön lastik indi',
    ],
    'f.tire_front.worn': [
        'Ön lastiğin tırtılları yok olmuş, virajda kayıyor',
        'Ön lastik inceldi, içinden bez görünüyor',
    ],
    'f.tire_rear.damaged': [
        'Arka lastiğin yanağında kesik var, iç lastik dışarı fışkırıyor',
        'Arka lastikte bir yer balon gibi şişmiş',
    ],
    'f.hub_front.play': [
        'Ön tekerleği tutup yanlara sallayınca boşluk var',
        'Ön göbek tarafından tıkırtı geliyor',
    ],
    'f.qr_front.loose': [
        'Ön tekerlek çatalda oynuyor, mandal kolay kapanıyor',
        'Ön tekerlek mandalı açık kalmış gibi',
    ],
    'f.hub_rear.worn': [
        'Arka tekerleği elle çevirince göbekten hışırtı geliyor',
        'Arka göbekte boşluk var ve kaset sallanıyor',
    ],
    'f.freehub.slipping': [
        'Pedala basıyorum, pedal boşa dönüyor, bisiklet gitmiyor',
        'Pedal bazen kavrıyor bazen boşa kaçıyor, soğukta daha kötü',
    ],
    # Ek arızalar
    'f.qr_rear.loose': [
        'Ayağa kalkıp pedal basınca arka tekerlek kayıp frene sürtüyor',
        'Arka tekerlek mandalı gevşek kapatılmış',
    ],
    'f.hub_front.dry': [
        'Ön tekerleği elle çevirince göbekten hışırtı geliyor',
        'Ön tekerlek elle çevrilince çabuk duruyor',
    ],
    'f.valve_rear.leak': [
        'Arka lastik birkaç günde iniyor, delik bulamıyorum',
        'Arka sibobun dibinden hava kaçıyor',
    ],
    'f.tire_rear.worn': [
        'Arka lastik yokuşta patinaj yapıyor, tırtılları aşınmış',
        'Arka lastiğin ortası düzleşmiş',
    ],
    'f.rim_front.out_of_true': [
        'Ön tekerlek dönerken yanlara sallanıyor',
        'Çukura girdikten sonra ön jant eğildi',
    ],
    'f.rim_tape_front.shifted': [
        'Ön iç lastik hep jant tarafından deliniyor',
        'Ön jantta tel deliği açıkta kalmış',
    ],
    'f.tire_rear.pressure_low': [
        'Arka iç lastikte yan yana iki küçük delik var',
        'Kaldırımdan inince arka lastik indi',
    ],
    'f.brake_rear.adapter_loose': [
        'Arka freni sıkınca kaliper oynuyor, tok bir ses geliyor',
        'Arka kaliperin bağlantı cıvatası gevşemiş',
    ],
    'f.chainring.bolts': [
        'Aynakoldan her turda tık sesi geliyor',
        'Ön aynalar birbirine göre oynuyor',
    ],
    'f.spokes_rear.broken': [
        'Arka tekerlekte bir tel kopmuş, jant fren diskine doğru eğildi',
        'Arka tekerlekten çınlama geldi, sonra tekerlek yalpalamaya başladı',
    ],
    'f.saddle.creak': [
        'Selede otururken selenin altından gıcırtı geliyor',
        'Seleyi bastırınca raylardan ses geliyor',
    ],
}

C.zones, C.symptoms, C.faults = ZONES, SYMPTOMS, FAULTS
C.add_phrasings(PHRASINGS)
C.spare_parts = SPARE_PARTS
C.write()
