"""Corolla şablonunun S1000D içeriğini ve parça haritasını üretir.

    python3 make_content.py

`csdb/` altındaki DM, PM ve DML dosyaları ile `map/` altındaki parts,
faults ve zones dosyaları buradan yazılır. Elle düzenlemek yerine buradaki
tabloları değiştirip betiği yeniden çalıştırın; böylece DMC'ler, parça
haritası ve arızalar birbiriyle tutarlı kalır.

Bisiklet şablonunda DM'ler elle yazıldı. Corolla'da 40 DM ve 60 parça
olduğu için aynı biçim bir tablodan üretiliyor.
"""
import json
from pathlib import Path
from xml.sax.saxutils import escape, quoteattr

HERE = Path(__file__).resolve().parent.parent
CSDB = HERE / 'csdb'
MAP = HERE / 'map'

MODEL = 'NAYACAR'
COMPANY = 'NAYA0'
DATE = ('2026', '11', '23')
APPLIC = 'Toyota Corolla E100, 1ZZ-FE motorlu'

# --- SNS ------------------------------------------------------------------

# Sistem kodu → (başlık, {alt sistem: başlık}).
SNS = {
    'D00': ('Araç', {}),
    'DA0': ('Gövde', {'1': 'Kapılar', '2': 'Kaput ve bagaj kapağı',
                      '3': 'Tamponlar ve ızgara', '4': 'Camlar ve silecekler'}),
    'DA1': ('Motor', {'1': 'Blok, silindir kapağı ve pistonlar',
                      '2': 'Triger zinciri', '3': 'Yağlama',
                      '4': 'Soğutma', '5': 'Ateşleme',
                      '6': 'Emme ve egzoz'}),
    'DA2': ('Güç aktarma', {'1': 'Şanzıman ve debriyaj',
                            '2': 'Aks milleri'}),
    'DA3': ('Fren sistemi', {'1': 'Ön frenler', '2': 'Arka frenler',
                             '3': 'Fren servosu ve hidrolik'}),
    'DA4': ('Süspansiyon ve direksiyon', {'1': 'Ön süspansiyon',
                                          '2': 'Arka süspansiyon',
                                          '3': 'Direksiyon'}),
    'DA5': ('Tekerlekler', {'1': 'Lastikler'}),
    'DA6': ('Elektrik ve aydınlatma', {'1': 'Akü', '2': 'Farlar ve lambalar'}),
}

INFO_NAMES = {
    '022': 'İş kuralları', '040': 'Tanım', '241': 'Yağ değişimi',
    '271': 'Ayar', '300': 'Kontrol', '310': 'Gözle muayene',
    '361': 'Ölçüm', '421': 'Arıza bulma', '920': 'Değiştirme',
    '921': 'Yenisiyle değiştirme', '941': 'Resimli parça kataloğu',
}


def code(system, sub='0', info='040', disassy='00', item='A'):
    """DMC'nin parçaları. `str(code)` haritada kullanılan yazımı verir."""
    return Dmc(system, sub, info, disassy, item)


class Dmc:
    def __init__(self, system, sub, info, disassy, item):
        self.system, self.sub, self.info = system, sub, info
        self.disassy, self.item = disassy, item

    def __str__(self):
        return (f'DMC-{MODEL}-AAA-{self.system}-{self.sub}0-00-'
                f'{self.disassy}AA-{self.info}A-{self.item}')

    def file(self):
        return (f'DMC-{MODEL}-AAA-{self.system}-{self.sub}0-00-'
                f'{self.disassy}AA-{self.info}A-{self.item}_001-00_TR-TR.XML')

    def xml(self):
        return (f'<dmCode modelIdentCode="{MODEL}" systemDiffCode="AAA" '
                f'systemCode="{self.system}" subSystemCode="{self.sub}" '
                f'subSubSystemCode="0" assyCode="00" '
                f'disassyCode="{self.disassy}" disassyCodeVariant="AA" '
                f'infoCode="{self.info}" infoCodeVariant="A" '
                f'itemLocationCode="{self.item}"/>')

    def ref(self):
        return f'<dmRef><dmRefIdent>{self.xml()}</dmRefIdent></dmRef>'


BREX = code('D00', info='022', item='D')
IPD = code('D00', info='941', disassy='01')

# --- Çizimler ---------------------------------------------------------------

# Numara → başlık. Dosyalar `render_icn.py` ile modelden üretilir.
FIGURES = {
    1: 'Araç, soldan görünüş',
    2: 'Motor bölmesi',
    3: '1ZZ-FE motor',
    4: 'Ön fren ve süspansiyon',
    5: 'Ateşleme bobinleri ve bujiler',
    6: 'Tekerlek ve lastik',
}


def icn(number):
    return f'ICN-{MODEL}-AAA-D000000-0-{COMPANY}-{number:05d}-A-001-01'


# --- DM içerikleri ---------------------------------------------------------
#
# Her DM bir sözlük:
#   code, tech (konu), info (bilgi adı; yoksa bilgi koduna göre)
#   description: [(başlık, [paragraf...])]   → tanım DM'i
#   steps: [adım | (başlık, [alt adım...])]   → prosedür DM'i
#   isolation: {...}                          → arıza bulma DM'i
#   figure: çizim numarası
#   tools, supplies, spares: [(ad, adet)]
#   warnings, cautions: [metin]
#   conditions: [metin]
#   next: sonraki işlemin DMC'si

DMS = []


def dm(**kwargs):
    DMS.append(kwargs)
    return kwargs['code']


# Genel
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
            'Gövde: kapılar, kaput, bagaj kapağı, tamponlar, camlar.',
            'Motor: blok ve silindir kapağı, triger zinciri, yağlama, '
            'soğutma, ateşleme, emme ve egzoz.',
            'Güç aktarma: şanzıman, debriyaj ve iki ön aks mili.',
            'Fren sistemi: önde disk fren; bu modelde arkada da disk var '
            '(E100 sedanların çoğunda arkada kampana fren bulunur). Vakumlu '
            'fren servosu.',
            'Süspansiyon: önde ve arkada MacPherson tipi amortisörler, '
            'kremayer dişli direksiyon.',
            'Elektrik: 12 V akü, farlar ve arka lambalar.',
        ]),
        ('Teknik veriler', [
            'Motor: 1ZZ-FE, 4 silindir sıralı, 16 supap, çift eksantrik '
            '(DOHC), 1794 cm³.',
            'Lastikler: 175/65 R14. Lastik basıncı ön ve arka 2,2 bar.',
            'Motor yağı: 5W-30, filtreyle birlikte yaklaşık 3,7 litre.',
            'Soğutma suyu: uzun ömürlü antifriz karışımı, yaklaşık 6 litre.',
        ]),
    ])

dm(code=code('D00', info='300'), tech='Araç', info='Periyodik kontrol',
   conditions=['Araç düz zeminde, motor soğuk.'],
   steps=[
       'Motor yağı seviyesini kontrol edin. Her 10 000 km\'de ya da yılda '
       'bir yağı ve filtreyi değiştirin.',
       'Soğutma suyu seviyesini genleşme kabındaki FULL ve LOW çizgileri '
       'arasında tutun.',
       'Fren hidroliği seviyesini ve balata kalınlığını kontrol edin.',
       'Lastik basınçlarını ve diş derinliğini ölçün.',
       'Akünün kutup başlarında oksitlenme olup olmadığına bakın.',
       'Farları, stop lambalarını ve sinyalleri yakarak kontrol edin.',
       'Her 40 000 km\'de hava filtresini, her 100 000 km\'de bujileri '
       'değiştirin.',
   ])

# Motor
ENGINE = dm(
    code=code('DA1'), tech='Motor', figure=3,
    description=[
        ('Genel', [
            '1ZZ-FE alüminyum bloklu, dört silindirli bir benzinli '
            'motordur. Silindir kapağında iki eksantrik mili ve silindir '
            'başına dört supap vardır.',
            'Krank mili pistonlardan gelen gidip gelme hareketini dönme '
            'hareketine çevirir. Eksantrik milleri krank miline triger '
            'zinciriyle bağlıdır.',
        ]),
        ('Çalışma', [
            'Emme manifoldundan gelen hava yakıtla karışır, silindirde '
            'sıkıştırılır ve bujinin kıvılcımıyla yanar. Yanmış gazlar '
            'egzoz manifoldundan çıkar.',
            'Her silindirin kendi ateşleme bobini vardır; bobin bujinin '
            'üstüne oturur.',
        ]),
        ('Bakım', [
            'Triger zinciri motor ömrü boyunca çalışacak şekilde '
            'tasarlanmıştır; düzenli değişimi yoktur. Zincirin ömrü yağın '
            'temizliğine bağlıdır.',
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
            ('end-starter', 'Akü dolu ama marş dönmüyor: marş motoru, '
             'marş rölesi ya da kablolar arızalı olabilir; yetkili servise '
             'başvurun.', None),
            ('end-ignition', 'Hiçbir silindirde kıvılcım yoksa EFI ya da IG '
             'sigortası, krank konum sensörü ya da motor beyni arızalı '
             'olabilir; yetkili servise başvurun.', None),
            ('end-fuel', 'Yakıt pompası sigortasını ve rölesini kontrol '
             'edin; sorun sürerse yakıt pompası arızalıdır.', None),
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

COOLING_CHECK = dm(
    code=code('DA1', '4', '300'), tech='Soğutma sistemi', figure=2,
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
             'karşı kontrol edin.', 'Bir kaçak izi var mı?', 'end-leak',
             'stp-0004'),
            ('stp-0003', 'Motoru rölantide ısıtın ve fanın devreye girip '
             'girmediğini izleyin.', 'Fan çalışıyor mu?', 'stp-0004',
             'end-fan'),
            ('stp-0004', 'Motor çalışırken genleşme kabında sürekli kabarcık '
             'çıkıp çıkmadığına bakın.', 'Sürekli kabarcık var mı?',
             'end-gasket', 'end-thermostat'),
        ],
        'ends': [
            ('end-leak', 'Kaçağı giderin; su pompasından sızıyorsa pompayı '
             'değiştirin.', code('DA1', '4', '920')),
            ('end-fan', 'Fan sigortasını, rölesini ve fan motorunu kontrol '
             'edin.', None),
            ('end-gasket', 'Yanma gazı soğutma suyuna karışıyor: silindir '
             'kapak contası yanmış olabilir. Önce kompresyonu ölçün.',
             code('DA1', '1', '361')),
            ('end-thermostat', 'Termostat kapalı kalmış ya da radyatör '
             'tıkanmış olabilir; ikisini de kontrol edin, sonra sistemin '
             'havasını alın.', None),
        ],
    })

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
    ])

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
        'Yeni bujilerin tırnak aralığını kontrol edin: 1,0-1,1 mm.',
        'Bujileri önce elle, sonra 25 N·m\'de sıkın.',
        'Bobinleri yerine takın, soketleri bağlayın.',
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
             'yer değiştirdi mi?', 'end-coil', 'end-plug'),
            ('stp-0003', 'Hava filtresini çıkarın ve kontrol edin.',
             'Filtre çok kirli mi?', 'end-filter', 'end-shop'),
        ],
        'ends': [
            ('end-coil', 'Ateşleme bobini arızalı; bobini değiştirin.', None),
            ('end-plug', 'Bujiyi değiştirin.', code('DA1', '5', '920')),
            ('end-filter', 'Hava filtresini değiştirin.',
             code('DA1', '6', '920')),
            ('end-shop', 'Enjektör, yakıt basıncı ya da sensör arızası '
             'olabilir; arıza kodlarını okutmak için yetkili servise '
             'başvurun.', None),
        ],
    })

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
    code=code('DA1', '6', '300'), tech='Egzoz sistemi',
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

# Güç aktarma
GEARBOX = dm(
    code=code('DA2', '1', '300'), tech='Şanzıman',
    info='Yağ seviyesi kontrolü', figure=2,
    tools=[('Lokma, 24 mm', 1)],
    supplies=[('Şanzıman yağı, 75W-90', 1)],
    steps=[
        'Aracı düz olarak kaldırın.',
        'Şanzımanın yanındaki doldurma tapasını sökün.',
        'Yağ seviyesi tapa deliğinin alt kenarına kadar olmalıdır.',
        'Seviye düşükse delikten yağ taşana kadar ekleyin.',
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
             'edin.', 'Seviye düşük mü?', 'end-hydraulic', 'end-clutch'),
            ('stp-0004', 'Şanzıman yağı seviyesini kontrol edin.',
             'Seviye düşük mü?', 'end-oil', 'end-shop'),
        ],
        'ends': [
            ('end-clutch', 'Debriyaj balatası aşınmış ya da ayarsız; '
             'debriyaj setinin değişimi için yetkili servise başvurun.',
             None),
            ('end-hydraulic', 'Hidrolik kaçağını bulun, hidroliği tamamlayın '
             've havasını alın.', None),
            ('end-oil', 'Şanzıman yağını tamamlayın.', code('DA2', '1', '300')),
            ('end-shop', 'Senkromeç aşınmış olabilir; yetkili servise '
             'başvurun.', None),
        ],
    })

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

# Fren
BRAKES = dm(
    code=code('DA3'), tech='Fren sistemi', figure=4,
    description=[
        ('Genel', [
            'Fren pedalına basılınca fren servosu kuvveti artırır, ana '
            'merkez hidroliği dört tekerleğin frenlerine iletir.',
            'Kaliperdeki piston balataları diske bastırır; sürtünme aracı '
            'yavaşlatır.',
        ]),
        ('Aşınma', [
            'Balatalar ve diskler kullanıldıkça incelir. Frenleme sırasında '
            'ağırlık öne aktarıldığı için ön frenler daha hızlı aşınır.',
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
             'end-disc', 'end-shop'),
        ],
        'ends': [
            ('end-booster', 'Fren servosu vakum almıyor: vakum hortumunu ve '
             'servoyu kontrol edin.', code('DA3', '3', '300')),
            ('end-leak', 'Kaçağı giderin, hidroliği tamamlayın ve sistemin '
             'havasını alın. Kaçak giderilmeden aracı kullanmayın.', None),
            ('end-pads', 'Ön balataları değiştirin.', code('DA3', '1', '921')),
            ('end-disc', 'Diskleri ölçün ve gerekirse değiştirin.',
             code('DA3', '1', '361')),
            ('end-shop', 'Kaliper pistonu sıkışmış olabilir; yetkili '
             'servise başvurun.', None),
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

REAR_BRAKES = dm(
    code=code('DA3', '2', '300'), tech='Arka frenler',
    steps=[
        'Aracın arkasını kaldırın ve tekerlekleri sökün.',
        'Balata kalınlığını kontrol edin; 1 mm\'nin altındaysa değiştirin.',
        'Kaliper ve hortumlarda kaçak olup olmadığına bakın.',
        'El freni kolunu çekin; 5-8 diş arasında tam tutmalıdır. Daha '
        'fazlaysa el freni telini ayarlatın.',
    ])

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
        'Fren hidroliği deposunda seviyenin MIN ve MAX arasında olduğunu '
        've hidroliğin koyulaşmadığını kontrol edin.',
    ])

# Süspansiyon ve direksiyon
SUSPENSION_CHECK = dm(
    code=code('DA4', '1', '300'), tech='Ön süspansiyon', figure=4,
    steps=[
        'Aracın ön köşesine bastırıp bırakın. Gövde bir kez inip kalkarak '
        'durmalıdır; birden çok salınım amortisörün zayıfladığını '
        'gösterir.',
        'Amortisörün gövdesinde yağ sızıntısı olup olmadığına bakın.',
        'Aracı kaldırın, tekerleği üstten ve alttan tutup sallayın. Boşluk '
        'rotil ya da tekerlek rulmanı aşınmasını gösterir.',
        'Salıncak burçlarında çatlak ve yırtık olup olmadığını kontrol '
        'edin.',
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
        'Fren hortumunun ve ABS kablosunun amortisördeki tutucularını '
        'çıkarın.',
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

SUSPENSION_ISOLATE = dm(
    code=code('DA4', info='421'), tech='Süspansiyon ve direksiyon',
    info='Arıza bulma',
    isolation={
        'fault': 'NAYACAR-DA4-001',
        'descr': 'Araç bir yana çekiyor, direksiyon titriyor, tümseklerde '
                 'vuruntu sesi geliyor ya da lastikler düzensiz aşınıyor.',
        'steps': [
            ('stp-0001', 'Lastik basınçlarını ölçün.', 'Sağ ve sol '
             'arasında fark var mı?', 'end-pressure', 'stp-0002'),
            ('stp-0002', 'Ön lastiklerin iç ve dış kenarlarına bakın.',
             'Lastik bir kenarından aşınmış mı?', 'end-alignment',
             'stp-0003'),
            ('stp-0003', 'Aracı yavaşça tümsekten geçirin ve sesi dinleyin.',
             'Önden vuruntu sesi geliyor mu?', 'end-strut', 'stp-0004'),
            ('stp-0004', 'Belirli bir hızda direksiyonda titreme olup '
             'olmadığını izleyin.', 'Titreme var mı?', 'end-balance',
             'end-shop'),
        ],
        'ends': [
            ('end-pressure', 'Lastik basınçlarını 2,2 bara ayarlayın.',
             code('DA5', '1', '300')),
            ('end-alignment', 'Ön düzen ayarı yaptırın.',
             code('DA4', '3', '271')),
            ('end-strut', 'Amortisörü, takozunu, salıncak burcunu ve rotili '
             'kontrol edin.',
             code('DA4', '1', '300')),
            ('end-balance', 'Tekerlek balansı bozulmuş olabilir; balans '
             'yaptırın.', None),
            ('end-shop', 'Direksiyon kutusu ya da rot başları aşınmış '
             'olabilir; yetkili servise başvurun.', None),
        ],
    })

REAR_SUSPENSION = dm(
    code=code('DA4', '2', '300'), tech='Arka süspansiyon',
    steps=[
        'Aracın arka köşesine bastırıp bırakın; birden çok salınım '
        'amortisörün zayıfladığını gösterir.',
        'Arka amortisörlerde yağ sızıntısı olup olmadığına bakın.',
        'Salıncakların ve viraj demirinin burçlarını çatlak ve yırtığa '
        'karşı kontrol edin.',
        'Aracı kaldırın, arka tekerleği sallayarak rulman boşluğunu '
        'kontrol edin.',
    ])

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

# Tekerlekler
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
        'Aşınma düzensizse (iç ya da dış kenar) ön düzen ayarı yaptırın.',
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

# Elektrik
BATTERY_CHECK = dm(
    code=code('DA6', '1', '300'), tech='Akü', figure=2,
    tools=[('Voltmetre', 1)],
    warnings=['Akü patlayıcı hidrojen gazı çıkarır; yakınında kıvılcım '
              'çıkarmayın, sigara içmeyin.'],
    steps=[
        'Motor kapalıyken akü kutup başları arasındaki gerilimi ölçün. '
        '12,6 V ve üstü tam dolu, 12,4 V yaklaşık %75 dolu aküyü gösterir; '
        '12,2 V\'un altındaysa akü şarj edilmelidir.',
        'Motoru çalıştırın ve gerilimi yeniden ölçün. 13,8-14,4 V arası '
        'şarj sisteminin çalıştığını gösterir.',
        'Gerilim 13,5 V\'un altındaysa alternatör kayışını ve alternatörü '
        'kontrol ettirin.',
        'Kutup başlarındaki beyaz oksidi sıcak su ve tel fırçayla '
        'temizleyin; kelepçeleri sıkın.',
    ])

BATTERY = dm(
    code=code('DA6', '1', '920'), tech='Akü', figure=2,
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

# Gövde
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

DOORS = dm(
    code=code('DA0', '1', '300'), tech='Kapılar',
    supplies=[('Beyaz gres', 1)],
    steps=[
        'Kapıları açıp kapatın; zorlanma ya da sarkma olmamalıdır.',
        'Menteşeleri ve kapı gergilerini temizleyip ince bir kat gresle '
        'yağlayın.',
        'Kapı fitillerini çatlak ve yırtığa karşı kontrol edin; yağmur suyu '
        'içeri giriyorsa fitili değiştirin.',
        'Kapı altındaki su tahliye deliklerini açık tutun.',
    ])

BODY = dm(
    code=code('DA0'), tech='Gövde', figure=1,
    description=[
        ('Genel', [
            'Gövde tek parça (monokok) çelik kasadır; ayrı bir şasi yoktur. '
            'Ön çamurluklar, kaput, kapılar ve bagaj kapağı sökülebilir.',
            'Ön ve arka tamponlar plastiktir; içlerinde darbe emici '
            'köpük ve çelik bir travers bulunur.',
        ]),
        ('Paslanma', [
            'Paslanma en çok kapı altlarında, çamurluk kenarlarında ve '
            'bagaj tabanında başlar. Boyadaki taş izleri zamanında '
            'kapatılmalıdır.',
        ]),
    ])

# --- Parça haritası --------------------------------------------------------

# (id, ad, üst parça, sns, düğümler, bölge, işlev, prosedürler, IPD adet)
# Düğümü olmayan parçalar içinde bulundukları düğüme bağlı.
P = []


def part(id, name, parent, sns, nodes, zone, function, procedures=None,
         quantity=1, part_number=None):
    P.append(dict(id=id, name=name, parent=parent, sns=sns, nodes=nodes,
                  zone=zone, function=function,
                  procedures=procedures or {}, quantity=quantity,
                  part_number=part_number))


ENGINE_NODES = [
    'engine_block', 'engine_head', 'engine_head_gasket', 'engine_head_cover',
    'engine_camshafts', 'engine_timing_chain', 'engine_timing_cover',
    'engine_crankshaft', 'engine_pistons', 'engine_rods', 'engine_oil_pan',
    'engine_oil_pump', 'engine_oil_filter', 'engine_water_pump',
    'engine_crank_pulley', 'engine_intake', 'engine_exhaust_manifold',
    'engine_coils', 'engine_spark_plugs', 'air_filter',
]

part('body', 'Gövde', None, 'DA0-00',
     ['body', 'hood', 'trunk', 'door_fl', 'door_fr', 'door_rl', 'door_rr',
      'fender_l', 'fender_r', 'bumper_front', 'bumper_rear', 'grille',
      'mirror_l', 'mirror_r', 'headlight_l', 'headlight_r', 'taillight_l',
      'taillight_r'], 'z.cabin',
     'Bütün parçaları taşıyan çelik monokok kasa.')
part('body.hood', 'Kaput', 'body', 'DA0-20', ['hood'], 'z.front',
     'Motor bölmesini örter.')
part('body.trunk', 'Bagaj kapağı', 'body', 'DA0-20', ['trunk'], 'z.rear',
     'Bagaj bölmesini kapatır.')
part('body.door_fl', 'Sol ön kapı', 'body', 'DA0-10', ['door_fl'], 'z.cabin',
     'Ön yolcu kapısı; camı, kilidi ve iç döşemesiyle.', {'inspect': DOORS})
part('body.door_fr', 'Sağ ön kapı', 'body', 'DA0-10', ['door_fr'], 'z.cabin',
     'Sürücü kapısı. Modeldeki araç sağdan direksiyonlu (Japonya modeli).',
     {'inspect': DOORS})
part('body.door_rl', 'Sol arka kapı', 'body', 'DA0-10', ['door_rl'],
     'z.cabin', 'Arka yolcu kapısı.', {'inspect': DOORS})
part('body.door_rr', 'Sağ arka kapı', 'body', 'DA0-10', ['door_rr'],
     'z.cabin', 'Arka yolcu kapısı.', {'inspect': DOORS})
part('body.fender_l', 'Sol ön çamurluk', 'body', 'DA0-00', ['fender_l'],
     'z.front', 'Ön tekerleğin üstünü örten sökülebilir panel.')
part('body.fender_r', 'Sağ ön çamurluk', 'body', 'DA0-00', ['fender_r'],
     'z.front', 'Ön tekerleğin üstünü örten sökülebilir panel.')
part('body.bumper_front', 'Ön tampon', 'body', 'DA0-30', ['bumper_front'],
     'z.front', 'Küçük çarpmalarda darbeyi emer.')
part('body.bumper_rear', 'Arka tampon', 'body', 'DA0-30', ['bumper_rear'],
     'z.rear', 'Küçük çarpmalarda darbeyi emer.')
part('body.wipers', 'Silecekler', 'body', 'DA0-40', ['body'], 'z.cabin',
     'Ön camı yağmurda temiz tutar.', {'replace': WIPERS}, quantity=2)
part('body.headlights', 'Farlar', 'body', 'DA6-20',
     ['headlight_l', 'headlight_r'], 'z.front',
     'Kısa ve uzun far, ön sinyal.', {'replace': HEADLIGHT}, quantity=2)
part('body.taillights', 'Stop lambaları', 'body', 'DA6-20',
     ['taillight_l', 'taillight_r'], 'z.rear',
     'Stop, park, sinyal ve geri vites lambası.', quantity=2)

part('engine', 'Motor', None, 'DA1-00', ENGINE_NODES, 'z.engine',
     '1,8 litre, dört silindirli 1ZZ-FE benzinli motor.',
     {'isolate': ENGINE_ISOLATE})
part('engine.block', 'Silindir bloğu', 'engine', 'DA1-10',
     ['engine_block'], 'z.engine',
     'Silindirleri ve krank milini taşıyan alüminyum gövde.',
     {'measure': COMPRESSION})
part('engine.head', 'Silindir kapağı', 'engine', 'DA1-10', ['engine_head'],
     'z.engine', 'Supapları, eksantrikleri ve yanma odalarını taşır.',
     {'measure': COMPRESSION})
part('engine.head_gasket', 'Silindir kapak contası', 'engine.head',
     'DA1-10', ['engine_head_gasket'], 'z.engine',
     'Blok ile kapak arasını sızdırmaz yapar; yağ, su ve yanma gazını '
     'birbirinden ayırır.', {'replace': HEAD_GASKET})
part('engine.head_cover', 'Supap kapağı', 'engine', 'DA1-10',
     ['engine_head_cover'], 'z.engine',
     'Eksantrikleri örter; yağ doldurma kapağı üstündedir.')
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
part('engine.oil_pan', 'Karter', 'engine', 'DA1-30', ['engine_oil_pan'],
     'z.engine', 'Motor yağını toplar; boşaltma tapası altındadır.',
     {'lubricate': OIL_CHANGE, 'inspect': OIL_CHECK})
part('engine.oil_pump', 'Yağ pompası', 'engine', 'DA1-30',
     ['engine_oil_pump'], 'z.engine',
     'Yağı karterden emip yataklara basınçla gönderir.')
part('engine.oil_filter', 'Yağ filtresi', 'engine', 'DA1-30',
     ['engine_oil_filter'], 'z.engine', 'Yağdaki metal ve is parçalarını '
     'tutar.', {'replace': OIL_CHANGE})
part('engine.water_pump', 'Su pompası', 'engine', 'DA1-40',
     ['engine_water_pump'], 'z.engine',
     'Soğutma suyunu motor ile radyatör arasında dolaştırır.',
     {'inspect': COOLING_CHECK, 'replace': WATER_PUMP})
part('engine.coils', 'Ateşleme bobinleri', 'engine', 'DA1-50',
     ['engine_coils'], 'z.engine',
     'Bujiye kıvılcım için gereken yüksek gerilimi üretir.',
     {'isolate': IGNITION}, quantity=4)
part('engine.spark_plugs', 'Bujiler', 'engine', 'DA1-50',
     ['engine_spark_plugs'], 'z.engine',
     'Silindirdeki yakıt-hava karışımını ateşler.',
     {'replace': PLUGS}, quantity=4)
part('engine.intake', 'Emme manifoldu', 'engine', 'DA1-60',
     ['engine_intake'], 'z.engine', 'Havayı silindirlere dağıtır.')
part('engine.exhaust_manifold', 'Egzoz manifoldu', 'engine', 'DA1-60',
     ['engine_exhaust_manifold'], 'z.engine',
     'Silindirlerden çıkan gazları egzoz borusuna toplar.',
     {'inspect': EXHAUST})
part('engine.air_filter', 'Hava filtresi', 'engine', 'DA1-60',
     ['air_filter'], 'z.engine', 'Motora giren havadaki tozu tutar.',
     {'replace': AIR_FILTER})

part('cooling', 'Soğutma sistemi', None, 'DA1-40',
     ['radiator', 'coolant_tank'], 'z.front',
     'Motorun ısısını radyatörden havaya atar.',
     {'isolate': OVERHEAT, 'inspect': COOLING_CHECK})
part('cooling.radiator', 'Radyatör', 'cooling', 'DA1-40', ['radiator'],
     'z.front', 'Soğutma suyunu geçen havayla soğutur; fan arkasındadır.',
     {'inspect': COOLING_CHECK})
part('cooling.tank', 'Genleşme kabı', 'cooling', 'DA1-40', ['coolant_tank'],
     'z.engine', 'Isınan soğutma suyunun fazlasını toplar; seviye buradan '
     'okunur.', {'inspect': COOLING_CHECK})

part('battery', 'Akü', None, 'DA6-10', ['battery'], 'z.engine',
     'Marş için gereken akımı ve motor dururken elektriği sağlar.',
     {'inspect': BATTERY_CHECK, 'replace': BATTERY})

part('drivetrain', 'Güç aktarma', None, 'DA2-00',
     ['transaxle', 'driveshaft_front'], 'z.engine',
     'Motorun gücünü ön tekerleklere iletir.')
part('drivetrain.transaxle', 'Şanzıman', 'drivetrain', 'DA2-10',
     ['transaxle'], 'z.engine',
     'Beş ileri manuel şanzıman ve diferansiyel tek gövdede.',
     {'inspect': GEARBOX, 'isolate': CLUTCH})
part('drivetrain.clutch', 'Debriyaj', 'drivetrain.transaxle', 'DA2-10',
     ['transaxle'], 'z.engine',
     'Vites değiştirirken motoru şanzımandan ayırır.', {'isolate': CLUTCH})
part('drivetrain.driveshafts', 'Aks milleri', 'drivetrain', 'DA2-20',
     ['driveshaft_front'], 'z.front',
     'Diferansiyelden ön tekerleklere gücü aks kafalarıyla (homokinetik '
     'mafsal) iletir.',
     {'inspect': DRIVESHAFT}, quantity=2)

part('brakes', 'Fren sistemi', None, 'DA3-00',
     ['brake_front', 'brake_rear', 'brake_booster'], 'z.front',
     'Aracı yavaşlatır ve durdurur.', {'isolate': BRAKE_ISOLATE})
part('brakes.front', 'Ön frenler', 'brakes', 'DA3-10', ['brake_front'],
     'z.front', 'Disk, kaliper ve balatalar.',
     {'isolate': BRAKE_ISOLATE, 'measure': DISCS}, quantity=2)
part('brakes.front.pads', 'Ön balatalar', 'brakes.front', 'DA3-10',
     ['brake_front'], 'z.front', 'Diske sürtünerek frenleme yapar.',
     {'replace': PADS}, quantity=2)
part('brakes.front.discs', 'Ön fren diskleri', 'brakes.front', 'DA3-10',
     ['brake_front'], 'z.front', 'Tekerlekle dönen, havalandırmalı disk.',
     {'measure': DISCS})
part('brakes.rear', 'Arka frenler', 'brakes', 'DA3-20', ['brake_rear'],
     'z.rear', 'Arka disk frenler ve el freni.', {'inspect': REAR_BRAKES},
     quantity=2)
part('brakes.booster', 'Fren servosu', 'brakes', 'DA3-30',
     ['brake_booster'], 'z.engine',
     'Motor vakumuyla pedal kuvvetini artırır; ana merkez önündedir.',
     {'inspect': BOOSTER})

part('chassis', 'Süspansiyon ve direksiyon', None, 'DA4-00',
     ['subframe_front', 'strut_front', 'control_arm_front',
      'suspension_rear', 'steering_rack', 'steering_wheel'], 'z.front',
     'Tekerlekleri gövdeye bağlar, yoldan gelen darbeleri sönümler ve '
     'aracı yönlendirir.', {'isolate': SUSPENSION_ISOLATE})
part('chassis.strut_front', 'Ön amortisörler', 'chassis', 'DA4-10',
     ['strut_front'], 'z.front',
     'MacPherson amortisör ve helezon yay; tekerleği taşır ve sönümler.',
     {'inspect': SUSPENSION_CHECK, 'replace': STRUT}, quantity=2)
part('chassis.control_arm', 'Ön salıncaklar', 'chassis', 'DA4-10',
     ['control_arm_front'], 'z.front',
     'Aks taşıyıcısını travers ile bağlar; ucundaki rotil döner.',
     {'inspect': SUSPENSION_CHECK}, quantity=2)
part('chassis.suspension_rear', 'Arka süspansiyon', 'chassis', 'DA4-20',
     ['suspension_rear'], 'z.rear',
     'Arka amortisörler, salıncaklar ve viraj demiri.',
     {'inspect': REAR_SUSPENSION})
part('chassis.steering_rack', 'Direksiyon kutusu', 'chassis', 'DA4-30',
     ['steering_rack'], 'z.front',
     'Kremayer dişliyle direksiyon dönüşünü tekerleklere iletir.',
     {'adjust': ALIGNMENT})
part('chassis.steering_wheel', 'Direksiyon simidi', 'chassis', 'DA4-30',
     ['steering_wheel'], 'z.cabin', 'Sürücünün aracı yönlendirdiği simit.')

part('exhaust', 'Egzoz sistemi', None, 'DA1-60', ['exhaust'], 'z.under',
     'Egzoz gazını aracın arkasına taşır; susturucu sesi azaltır.',
     {'inspect': EXHAUST})

# Lastik arızaları dört tekerleğin hepsinde olabilir; tek bir tekerleğe değil
# "Lastikler" parçasına bağlı.
WHEEL_NODES = ['wheel_fl', 'wheel_fr', 'wheel_rl', 'wheel_rr']
part('wheels', 'Tekerlekler', None, 'DA5-00', WHEEL_NODES, 'z.under',
     'Dört tekerlek: 175/65 R14 lastik, çelik jant ve göbek kapağı.',
     {'inspect': TIRES, 'replace': WHEEL}, quantity=4)
part('wheels.tires', 'Lastikler', 'wheels', 'DA5-10', WHEEL_NODES,
     'z.under', '175/65 R14 lastikler; basınç ön ve arka 2,2 bar.',
     {'inspect': TIRES}, quantity=4)
for wid, wname, wnode, wzone in [
        ('wheel.fl', 'Sol ön tekerlek', 'wheel_fl', 'z.front'),
        ('wheel.fr', 'Sağ ön tekerlek', 'wheel_fr', 'z.front'),
        ('wheel.rl', 'Sol arka tekerlek', 'wheel_rl', 'z.rear'),
        ('wheel.rr', 'Sağ arka tekerlek', 'wheel_rr', 'z.rear')]:
    part(wid, wname, 'wheels', 'DA5-10', [wnode], wzone,
         'Lastik, çelik jant ve göbek kapağı.',
         {'inspect': TIRES, 'replace': WHEEL})

ZONES = [
    ('z.front', 'Ön', None), ('z.engine', 'Motor bölmesi', 'z.front'),
    ('z.cabin', 'Kabin', None), ('z.rear', 'Arka', None),
    ('z.under', 'Araç altı', None),
]

# --- Arızalar ---------------------------------------------------------------

SYMPTOMS = [
    ('sym.no_start', 'Motor çalışmıyor ya da marş basmıyor'),
    ('sym.slow_crank', 'Marş ağır dönüyor'),
    ('sym.misfire', 'Motor tekliyor ya da rölantide titriyor'),
    ('sym.power_loss', 'Motor çekmiyor, hızlanmıyor'),
    ('sym.overheat', 'Hararet göstergesi yükseliyor'),
    ('sym.coolant_loss', 'Soğutma suyu eksiliyor'),
    ('sym.white_smoke', 'Egzozdan beyaz duman çıkıyor'),
    ('sym.blue_smoke', 'Egzozdan mavi duman çıkıyor, motor yağ eksiltiyor'),
    ('sym.oil_light', 'Yağ lambası yanıyor'),
    ('sym.oil_leak', 'Aracın altına yağ damlıyor'),
    ('sym.engine_rattle', 'Soğuk çalıştırmada motordan şıkırtı geliyor'),
    ('sym.exhaust_noise', 'Egzozdan yüksek ya da üfleme sesi geliyor'),
    ('sym.clutch_slip', 'Gaza basınca devir yükseliyor ama araç hızlanmıyor'),
    ('sym.hard_shift', 'Vites zor geçiyor ya da cızırdıyor'),
    ('sym.turn_click', 'Direksiyon kırıkken önden tıkırtı geliyor'),
    ('sym.brake_weak', 'Fren yeterince tutmuyor'),
    ('sym.brake_noise', 'Frenlerken ciyaklama ya da sürtme sesi geliyor'),
    ('sym.brake_pulse', 'Frenlerken pedal ve direksiyon titriyor'),
    ('sym.pedal_hard', 'Fren pedalı çok sert'),
    ('sym.bounce', 'Araç tümseklerde fazla zıplıyor'),
    ('sym.knock', 'Tümseklerde önden vuruntu sesi geliyor'),
    ('sym.pull', 'Araç bir yana çekiyor'),
    ('sym.tire_wear', 'Lastikler bir kenarından aşınıyor'),
    ('sym.flat', 'Lastik iniyor'),
    ('sym.vibration', 'Belli bir hızda direksiyon titriyor'),
    ('sym.dim_lights', 'Farlar sönük yanıyor'),
    ('sym.headlight_out', 'Farlardan biri yanmıyor'),
    ('sym.wiper_streak', 'Silecekler camda iz bırakıyor'),
]

# (id, parça, belirtiler, neden, önem 1-3, arıza bulma, onarım)
FAULTS = [
    ('f.battery.flat', 'battery', ['sym.no_start', 'sym.slow_crank',
                                   'sym.dim_lights'],
     'Akü boşalmış ya da ömrünü doldurmuş.', 2, BATTERY_CHECK, BATTERY),
    ('f.plugs.worn', 'engine.spark_plugs', ['sym.misfire', 'sym.power_loss'],
     'Bujilerin elektrotları aşınmış ya da islenmiş; kıvılcım zayıf.', 1,
     IGNITION, PLUGS),
    ('f.coils.failed', 'engine.coils', ['sym.misfire', 'sym.power_loss'],
     'Bir ateşleme bobini arızalı; o silindir çalışmıyor.', 2, IGNITION,
     None),
    ('f.air_filter.clogged', 'engine.air_filter', ['sym.power_loss',
                                                   'sym.misfire'],
     'Hava filtresi tıkanmış; motor yeterince hava alamıyor.', 1,
     IGNITION, AIR_FILTER),
    ('f.head_gasket.blown', 'engine.head_gasket',
     ['sym.overheat', 'sym.white_smoke', 'sym.coolant_loss'],
     'Silindir kapak contası yanmış; soğutma suyu yanma odasına giriyor.',
     3, COMPRESSION, HEAD_GASKET),
    ('f.pistons.rings_worn', 'engine.pistons', ['sym.power_loss',
                                                'sym.blue_smoke'],
     'Segmanlar aşınmış; kompresyon düşük, motor yağ yakıyor.', 2,
     COMPRESSION, None),
    ('f.water_pump.leak', 'engine.water_pump', ['sym.coolant_loss',
                                                'sym.overheat'],
     'Su pompası keçesi sızdırıyor.', 2, OVERHEAT, WATER_PUMP),
    ('f.radiator.clogged', 'cooling.radiator', ['sym.overheat'],
     'Radyatör petekleri tıkanmış ya da fan çalışmıyor.', 2, OVERHEAT,
     COOLING_CHECK),
    ('f.oil.low', 'engine.oil_pan', ['sym.oil_light', 'sym.oil_leak',
                                     'sym.engine_rattle'],
     'Motor yağı eksik ya da yağ değişimi gecikmiş; karter tapasından ya '
     'da contasından sızıntı olabilir.', 3,
     OIL_CHECK, OIL_CHANGE),
    ('f.timing_chain.stretched', 'engine.timing_chain',
     ['sym.engine_rattle', 'sym.power_loss'],
     'Triger zinciri uzamış ya da gergisi yağ basıncını tutamıyor. '
     'Zincir atlarsa supaplar pistonlara çarpar.', 3,
     TIMING_CHECK, None),
    ('f.exhaust.leak', 'exhaust', ['sym.exhaust_noise'],
     'Egzoz borusu delinmiş ya da susturucu askısı kopmuş.', 1, EXHAUST,
     None),
    ('f.clutch.worn', 'drivetrain.clutch', ['sym.clutch_slip'],
     'Debriyaj balatası aşınmış.', 2, CLUTCH, None),
    ('f.transaxle.oil_low', 'drivetrain.transaxle', ['sym.hard_shift'],
     'Şanzıman yağı eksik.', 2, CLUTCH, GEARBOX),
    ('f.driveshaft.boot', 'drivetrain.driveshafts', ['sym.turn_click'],
     'Aks mili körüğü yırtılmış; aks kafası aşınmış.', 2, DRIVESHAFT,
     None),
    ('f.pads.worn', 'brakes.front.pads', ['sym.brake_weak',
                                          'sym.brake_noise'],
     'Ön balatalar aşınma sınırına gelmiş.', 3, BRAKE_ISOLATE, PADS),
    ('f.discs.warped', 'brakes.front.discs', ['sym.brake_pulse',
                                              'sym.brake_noise'],
     'Ön diskler eğrilmiş ya da MIN kalınlığın altına inmiş.', 2, DISCS,
     None),
    ('f.booster.vacuum', 'brakes.booster', ['sym.pedal_hard',
                                            'sym.brake_weak'],
     'Fren servosu vakum almıyor; hortum çatlak ya da diyafram yırtık.', 3,
     BRAKE_ISOLATE, BOOSTER),
    ('f.strut.worn', 'chassis.strut_front', ['sym.bounce', 'sym.knock'],
     'Ön amortisör yağını kaçırmış ya da takozu yırtılmış.', 2,
     SUSPENSION_CHECK, STRUT),
    ('f.control_arm.bushing', 'chassis.control_arm', ['sym.knock',
                                                      'sym.pull'],
     'Salıncak burcu ya da rotil aşınmış.', 2, SUSPENSION_ISOLATE, None),
    ('f.alignment', 'chassis.steering_rack', ['sym.pull', 'sym.tire_wear'],
     'Ön düzen bozulmuş.', 1, SUSPENSION_ISOLATE, ALIGNMENT),
    ('f.tire.puncture', 'wheels.tires', ['sym.flat', 'sym.pull'],
     'Lastik delinmiş ya da sibop kaçırıyor.', 2, TIRES, WHEEL),
    ('f.tire.balance', 'wheels.tires', ['sym.vibration'],
     'Tekerlek balansı bozulmuş.', 1, SUSPENSION_ISOLATE, None),
    ('f.headlight.bulb', 'body.headlights', ['sym.headlight_out'],
     'Far ampulü yanmış.', 1, None, HEADLIGHT),
    ('f.wipers.worn', 'body.wipers', ['sym.wiper_streak'],
     'Silecek lastikleri sertleşmiş.', 1, None, WIPERS),
]


# --- XML yazımı ---------------------------------------------------------------

def t(text):
    return escape(text)


def dm_status(applic=APPLIC):
    return f'''    <dmStatus issueType="new">
      <security securityClassification="01"/>
      <responsiblePartnerCompany enterpriseCode="{COMPANY}"><enterpriseName>NAYA</enterpriseName></responsiblePartnerCompany>
      <originator enterpriseCode="{COMPANY}"><enterpriseName>NAYA</enterpriseName></originator>
      <applic><displayText><simplePara>{t(applic)}</simplePara></displayText></applic>
      <brexDmRef>{BREX.ref()}</brexDmRef>
      <qualityAssurance><unverified/></qualityAssurance>
    </dmStatus>'''


def dm_xml(dmc, tech, info, schema, body, figures=()):
    entities = ''.join(
        f'<!ENTITY {icn(n)} SYSTEM "{icn(n)}.JPG" NDATA JPEG>\n'
        for n in sorted(set(figures)))
    doctype = ('<!DOCTYPE dmodule [\n<!NOTATION JPEG SYSTEM "JPEG">\n'
               f'{entities}]>\n') if figures else ''
    year, month, day = DATE
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
{dm_status()}
  </identAndStatusSection>
  <content>
{body}
  </content>
</dmodule>
'''


def figure_xml(number, indent):
    return (f'{indent}<figure id="fig-{number:04d}"><title>{t(FIGURES[number])}'
            f'</title><graphic infoEntityIdent="{icn(number)}"/></figure>')


def description_body(d):
    lines = ['    <description>']
    for i, (title, paras) in enumerate(d['description']):
        lines.append('      <levelledPara>')
        lines.append(f'        <title>{t(title)}</title>')
        lines += [f'        <para>{t(p)}</para>' for p in paras]
        lines.append('      </levelledPara>')
        if i == 0 and d.get('figure'):
            lines.append(figure_xml(d['figure'], '      '))
    lines.append('    </description>')
    return '\n'.join(lines)


def items(kind, entries, prefix, unit):
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
        ident = (f'<identNumber><manufacturerCode>{COMPANY}</manufacturerCode>'
                 f'<partAndSerialNumber><partNumber>'
                 f'{item_number(prefix, name)}'
                 '</partNumber></partAndSerialNumber></identNumber>')
        # Sıvılar litreyle, gerisi adetle.
        liquid = any(w in name for w in ('yağı', 'suyu', 'hidroliği'))
        unit_of = 'L' if unit == 'L' and liquid else 'EA'
        rows.append(f'<{descr} id="{prefix.lower()}-{i:04d}"><name>{t(name)}'
                    f'</name>{ident}<{req} unitOfMeasure="{unit_of}">'
                    f'{quantity}</{req}></{descr}>')
    return f'<{group}>{"".join(rows)}</{group}>'


# Yedek parçalar IPD'deki parçanın numarasını taşır; böylece prosedürdeki
# parça katalogda bulunur.
SPARE_PARTS = {
    'Silindir kapak contası': 'engine.head_gasket',
    'Yağ filtresi': 'engine.oil_filter',
    'Su pompası, contasıyla': 'engine.water_pump',
    'Buji, iridyum': 'engine.spark_plugs',
    'Hava filtresi elemanı': 'engine.air_filter',
    'Ön balata takımı': 'brakes.front.pads',
    'Ön amortisör': 'chassis.strut_front',
    'Akü, 12 V 45 Ah': 'battery',
    'Silecek süpürgesi, sürücü tarafı 550 mm': 'body.wipers',
    'Silecek süpürgesi, yolcu tarafı 400 mm': 'body.wipers',
}

_numbers = {}


def part_number(part_id):
    """Parçanın IPD'deki numarası."""
    for i, p in enumerate(P, 1):
        if p['id'] == part_id:
            return p['part_number'] or f'NC-{p["sns"]}-{i:03d}'
    raise KeyError(part_id)


def item_number(prefix, name):
    """Alet, sarf ve yedek parçaların numarası; aynı ad her DM'de aynı
    numarayı alır."""
    if prefix == 'PT' and name in SPARE_PARTS:
        return part_number(SPARE_PARTS[name])
    key = (prefix, name)
    if key not in _numbers:
        count = sum(1 for k in _numbers if k[0] == prefix) + 1
        _numbers[key] = f'NC-{prefix}-{count:03d}'
    return _numbers[key]


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


def conditions(d):
    conds = d.get('conditions', [])
    if not conds:
        return '<noConds/>'
    return ''.join(f'<reqCondNoRef><reqCond>{t(c)}</reqCond></reqCondNoRef>'
                   for c in conds)


def prelim(d):
    return ('      <preliminaryRqmts>\n'
            f'        <reqCondGroup>{conditions(d)}</reqCondGroup>\n'
            '        <reqSupportEquips>'
            f'{items("supportEquips", d.get("tools"), "TL", "EA")}'
            '</reqSupportEquips>\n'
            f'        <reqSupplies>{items("supplies", d.get("supplies"), "SP", "L")}'
            '</reqSupplies>\n'
            f'        <reqSpares>{items("spares", d.get("spares"), "PT", "EA")}'
            '</reqSpares>\n'
            f'        <reqSafety>{safety(d)}</reqSafety>\n'
            '      </preliminaryRqmts>')


def procedure_body(d):
    steps = []
    for i, step in enumerate(d['steps']):
        figure = figure_xml(d['figure'], '') if i == 0 and d.get(
            'figure') else ''
        if isinstance(step, tuple):
            title, subs = step
            inner = ''.join(f'<proceduralStep><para>{t(s)}</para>'
                            '</proceduralStep>' for s in subs)
            steps.append(f'        <proceduralStep><title>{t(title)}</title>'
                         f'{figure}{inner}</proceduralStep>')
        else:
            steps.append(f'        <proceduralStep><para>{t(step)}</para>'
                         f'{figure}</proceduralStep>')
    nxt = d.get('next')
    close = ('<reqCondGroup><reqCondDm><reqCond>Sonraki işlem:</reqCond>'
             f'{nxt.ref()}</reqCondDm></reqCondGroup>') if nxt else (
        '<reqCondGroup><noConds/></reqCondGroup>')
    return ('    <procedure>\n' + prelim(d) + '\n      <mainProcedure>\n'
            + '\n'.join(steps) + '\n      </mainProcedure>\n'
            f'      <closeRqmts>{close}</closeRqmts>\n    </procedure>')


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
        rows.append(f'            <isolationProcedureEnd id="{eid}"><action>'
                    f'{t(action)}{ref}</action></isolationProcedureEnd>')
    empty = ('<preliminaryRqmts><reqCondGroup><noConds/></reqCondGroup>'
             '<reqSupportEquips><noSupportEquips/></reqSupportEquips>'
             '<reqSupplies><noSupplies/></reqSupplies><reqSpares><noSpares/>'
             '</reqSpares><reqSafety><noSafety/></reqSafety>'
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


def ipd_body():
    rows = [figure_xml(1, '      ')]
    depth = {}
    for i, p in enumerate(P, 1):
        depth[p['id']] = 1 if p['parent'] is None else depth[p['parent']] + 1
        number = part_number(p['id'])
        rows.append(
            f'      <catalogSeqNumber figureNumber="01" item="{i:03d}" '
            f'indenture="{min(depth[p["id"]], 9)}">\n'
            '        <itemSeqNumber itemSeqNumberValue="00A">\n'
            '          <quantityPerNextHigherAssy>'
            f'{p["quantity"]}</quantityPerNextHigherAssy>\n'
            f'          <partRef manufacturerCodeValue="{COMPANY}" '
            f'partNumberValue={quoteattr(number)}/>\n'
            '          <partSegment><itemIdentData><descrForPart>'
            f'{t(p["name"])}</descrForPart></itemIdentData></partSegment>\n'
            '        </itemSeqNumber>\n'
            '      </catalogSeqNumber>')
        p['item'] = f'{i:03d}'
    return ('    <illustratedPartsCatalog>\n' + '\n'.join(rows)
            + '\n    </illustratedPartsCatalog>')


def brex_body():
    systems = []
    for system, (title, subs) in SNS.items():
        inner = ''.join(
            f'<snsSubSystem><snsCode>{sub}</snsCode><snsTitle>{t(name)}'
            f'</snsTitle><snsSubSubSystem><snsCode>0</snsCode><snsTitle>'
            f'{t(name)}</snsTitle><snsAssy><snsCode>00</snsCode><snsTitle>'
            f'{t(name)}</snsTitle></snsAssy></snsSubSubSystem></snsSubSystem>'
            for sub, name in subs.items())
        systems.append(f'          <snsSystem><snsCode>{system}</snsCode>'
                       f'<snsTitle>{t(title)}</snsTitle>{inner}</snsSystem>')
    return ('    <brex>\n      <snsRules>\n        <snsDescr>\n'
            + '\n'.join(systems)
            + '\n        </snsDescr>\n      </snsRules>\n'
              '      <contextRules/>\n    </brex>')


def info_name(d):
    return d.get('info') or INFO_NAMES[d['code'].info]


def write_dms():
    CSDB.mkdir(exist_ok=True)
    for old in CSDB.glob('*.XML'):
        old.unlink()
    written = []
    for d in DMS:
        if 'description' in d:
            body, schema = description_body(d), 'descript'
        elif 'isolation' in d:
            body, schema = isolation_body(d), 'fault'
        else:
            body, schema = procedure_body(d), 'proced'
        figures = [d['figure']] if d.get('figure') else []
        (CSDB / d['code'].file()).write_text(
            dm_xml(d['code'], d['tech'], info_name(d), schema, body,
                   figures), encoding='utf-8')
        written.append((d['code'], d['tech'], info_name(d)))
    (CSDB / IPD.file()).write_text(
        dm_xml(IPD, 'Toyota Corolla E100', INFO_NAMES['941'], 'ipd',
               ipd_body(), [1]), encoding='utf-8')
    written.append((IPD, 'Toyota Corolla E100', INFO_NAMES['941']))
    (CSDB / BREX.file()).write_text(
        dm_xml(BREX, 'Toyota Corolla E100', INFO_NAMES['022'], 'brex',
               brex_body()), encoding='utf-8')
    written.append((BREX, 'Toyota Corolla E100', INFO_NAMES['022']))
    return written


def write_pm(written):
    year, month, day = DATE
    by_system = {}
    for dmc, tech, info in written:
        if dmc.info == '022':
            continue
        by_system.setdefault(dmc.system, []).append((dmc, tech, info))
    entries = []
    for system, (title, _) in SNS.items():
        refs = ''.join(
            f'<dmRef><dmRefIdent>{dmc.xml()}</dmRefIdent><dmRefAddressItems>'
            f'<dmTitle><techName>{t(tech)}</techName><infoName>{t(info)}'
            '</infoName></dmTitle></dmRefAddressItems></dmRef>'
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
        <pmCode modelIdentCode="{MODEL}" pmIssuer="{COMPANY}" pmNumber="00001" pmVolume="00"/>
        <language languageIsoCode="tr" countryIsoCode="TR"/>
        <issueInfo issueNumber="001" inWork="00"/>
      </pmIdent>
      <pmAddressItems>
        <issueDate year="{year}" month="{month}" day="{day}"/>
        <pmTitle>Toyota Corolla E100 bakım el kitabı</pmTitle>
      </pmAddressItems>
    </pmAddress>
    <pmStatus issueType="new">
      <security securityClassification="01"/>
      <responsiblePartnerCompany enterpriseCode="{COMPANY}"><enterpriseName>NAYA</enterpriseName></responsiblePartnerCompany>
      <applic><displayText><simplePara>{t(APPLIC)}</simplePara></displayText></applic>
      <brexDmRef>{BREX.ref()}</brexDmRef>
      <qualityAssurance><unverified/></qualityAssurance>
    </pmStatus>
  </identAndStatusSection>
  <content>
{chr(10).join(entries)}
  </content>
</pm>
'''
    (CSDB / PM_FILE).write_text(xml, encoding='utf-8')


PM_FILE = f'PMC-{MODEL}-{COMPANY}-00001-00_001-00_TR-TR.XML'


def write_dml(written):
    year, month, day = DATE
    rows = ''.join(
        f'\n    <dmlEntry issueType="new">{dmc.ref()}<responsiblePartnerCompany '
        f'enterpriseCode="{COMPANY}"><enterpriseName>NAYA</enterpriseName>'
        '</responsiblePartnerCompany></dmlEntry>'
        for dmc, _, _ in sorted(written, key=lambda r: str(r[0])))
    xml = f'''<?xml version="1.0" encoding="UTF-8"?>
<dml xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.s1000d.org/S1000D_5-0/xml_schema_flat/dml.xsd">
  <identAndStatusSection>
    <dmlAddress>
      <dmlIdent>
        <dmlCode modelIdentCode="{MODEL}" senderIdent="{COMPANY}" dmlType="s" yearOfDataIssue="{year}" seqNumber="00001"/>
        <issueInfo issueNumber="001" inWork="00"/>
      </dmlIdent>
      <dmlAddressItems><issueDate year="{year}" month="{month}" day="{day}"/></dmlAddressItems>
    </dmlAddress>
    <dmlStatus issueType="new"><security securityClassification="01"/><brexDmRef>{BREX.ref()}</brexDmRef></dmlStatus>
  </identAndStatusSection>
  <dmlContent>{rows}
  </dmlContent>
</dml>
'''
    (CSDB / f'DML-{MODEL}-{COMPANY}-S-{year}-00001_001-00.XML').write_text(
        xml, encoding='utf-8')


def write_maps():
    MAP.mkdir(exist_ok=True)
    parts = []
    for p in P:
        entry = {'id': p['id'], 'name': p['name']}
        if p['parent']:
            entry['parent'] = p['parent']
        entry.update({
            'sns': p['sns'], 'meshNodes': p['nodes'], 'zone': p['zone'],
            'function': p['function'],
            'ipd': {'dmc': str(IPD), 'figure': '01', 'item': p['item']},
        })
        if p['procedures']:
            entry['procedures'] = {k: str(v)
                                   for k, v in p['procedures'].items()}
        parts.append(entry)
    dump(MAP / 'parts.json', {'parts': parts})

    faults = []
    for fid, pid, symptoms, cause, severity, isolation, repair in FAULTS:
        f = {'id': fid, 'part': pid, 'symptoms': symptoms, 'cause': cause,
             'severity': severity}
        if isolation:
            f['isolation'] = str(isolation)
        if repair:
            f['repair'] = str(repair)
        faults.append(f)
    dump(MAP / 'faults.json', {
        'symptoms': [{'id': i, 'text': text} for i, text in SYMPTOMS],
        'faults': faults,
    })
    dump(MAP / 'zones.json', {'zones': [
        {'id': i, 'name': n, **({'parent': p} if p else {})}
        for i, n, p in ZONES]})


def dump(path, data):
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n',
                    encoding='utf-8')


def main():
    ids = [p['id'] for p in P]
    assert len(ids) == len(set(ids)), 'aynı kimlikli iki parça var'
    written = write_dms()
    write_pm(written)
    write_dml(written)
    write_maps()
    print(f'{len(written)} DM, {len(P)} parça, {len(FAULTS)} arıza, '
          f'{len(SYMPTOMS)} belirti')


main()
