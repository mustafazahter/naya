"""F-16F Block 60 şablonunun S1000D içeriğini ve parça haritasını üretir.

    python3 make_content.py

İçerik yalnız genel bakım bilgisidir: periyodik muayeneler, yer işlemleri
(çekme, krikolama, park), ikmal ve servis, gözle muayene, çalışma
testleri, parça değişimi, temizlik, korozyon kontrolü ve arıza bulma.
Silah, aviyonik, elektronik harp ve performans bilgisi yoktur. Ölçü, basınç
ve tork değerleri verilmez; DM'ler değer gereken yerde uçağın kendi teknik
el kitabına yönlendirir.

Sistem kodları ATA 100 bölüm numaralarına benzer (32 iniş takımı, 72 motor).
Arıza bulma DM'leri belirtiden başlayıp onarım ya da değiştirme DM'ine
yönlendirir.

Kaynak modelin adı "F-16D Block 60"; iki kişilik Block 60'ın adı F-16F
(tek kişilik E). Şablon ve içerik F-16F adını kullanır.
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE.parent.parent / 'scripts'))

from s1000d_content import Content  # noqa: E402

# --- SNS ------------------------------------------------------------------

SNS = {
    '00': ('Uçak', {}),
    '05': ('Periyodik muayeneler', {'1': 'Faz muayenesi',
                                    '2': 'Özel muayeneler'}),
    '07': ('Kaldırma ve krikolama', {'1': 'Krikolama'}),
    '09': ('Çekme ve taksi', {'1': 'Çekme'}),
    '10': ('Park, bağlama ve depolama', {'1': 'Park ve bağlama',
                                         '2': 'Depolama'}),
    '12': ('İkmal ve servis', {'1': 'Servis noktaları', '2': 'Uçak yıkama'}),
    '20': ('Standart uygulamalar', {'1': 'Emniyet teli ve bağlantılar',
                                    '2': 'Elektrik konnektörleri',
                                    '3': 'Yabancı cisim (FOD) önleme',
                                    '4': 'Korozyon kontrolü'}),
    '21': ('Klima ve basınçlandırma', {'1': 'Klima ünitesi',
                                       '2': 'Dağıtım kanalları',
                                       '3': 'Basınç kontrolü'}),
    '24': ('Elektrik gücü', {'2': 'Jeneratörler', '3': 'Akü',
                             '4': 'Dış güç', '5': 'Acil güç ünitesi',
                             '6': 'Kablo demetleri'}),
    '25': ('Kokpit donanımı', {'1': 'Fırlatma koltukları',
                               '2': 'Koltuk kemerleri ve takımlar',
                               '3': 'Kokpit iç donanımı'}),
    '26': ('Yangından korunma', {'1': 'Yangın ve aşırı ısı algılama'}),
    '27': ('Uçuş kumandaları', {'1': 'Flaperonlar', '2': 'Dümen',
                                '3': 'Yatay kuyruklar',
                                '4': 'Hücum kenarı flapları',
                                '5': 'Hava frenleri',
                                '6': 'Kumanda bilgisayarı',
                                '7': 'Pilot kumandaları'}),
    '28': ('Yakıt sistemi', {'1': 'Gövde içi tanklar',
                             '2': 'Konformal yakıt tankları',
                             '3': 'Pompalar, valfler ve hatlar',
                             '4': 'Yakıt miktar göstergesi',
                             '5': 'Havada ikmal ağzı'}),
    '29': ('Hidrolik güç', {'1': 'Hidrolik sistemler', '2': 'Pompalar',
                            '3': 'Akümülatörler'}),
    '32': ('İniş takımı', {'1': 'Ana iniş takımı', '2': 'Burun iniş takımı',
                           '3': 'Açma-kapama ve kilitler',
                           '4': 'Tekerlekler ve frenler',
                           '5': 'Kuyruk kancası',
                           '6': 'Burun tekerleği yönlendirme'}),
    '33': ('Işıklar', {'1': 'Kokpit aydınlatması', '4': 'Dış aydınlatma'}),
    '34': ('Hava verileri', {'1': 'Pitot-statik sistemi'}),
    '35': ('Oksijen', {'1': 'Oksijen üretimi',
                       '2': 'Dağıtım ve acil oksijen'}),
    '36': ('Pnömatik', {'1': 'Hava alma (bleed) sistemi'}),
    '49': ('Motor çalıştırma ünitesi', {'1': 'Jet yakıtlı çalıştırıcı'}),
    '52': ('Kapaklar', {'1': 'Erişim kapakları',
                        '3': 'İniş takımı kapakları'}),
    '53': ('Gövde', {'1': 'Gövde yapısı', '2': 'Radom', '3': 'Hava alığı'}),
    '56': ('Kanopi', {'1': 'Kanopi camı ve çerçevesi'}),
    '57': ('Kanatlar ve kuyruk', {'1': 'Kanatlar', '2': 'Kuyruk'}),
    '72': ('Motor', {'1': 'Fan ve kompresörler', '2': 'Yanma odası',
                     '3': 'Türbinler', '4': 'Miller ve yataklar',
                     '5': 'Art yakıcı ve lüle',
                     '6': 'Aksesuar dişli kutusu'}),
    '73': ('Motor yakıtı ve kontrolü', {'1': 'Yakıt pompası ve kontrol',
                                        '2': 'Art yakıcı yakıt sistemi'}),
    '74': ('Ateşleme', {'1': 'Ateşleme sistemi'}),
    '77': ('Motor göstergeleri', {'1': 'Sıcaklık ve devir algılayıcıları'}),
    '79': ('Motor yağı', {'1': 'Yağ sistemi'}),
}

# --- Çizimler ---------------------------------------------------------------

# Numara → başlık. Dosyalar `render_icn.py` ile modelden üretilir.
FIGURES = {
    1: 'Uçak, soldan görünüş',
    2: 'Motorun uçaktaki yeri',
    3: 'Ana iniş takımı',
    4: 'Uçuş kumanda yüzeyleri',
    5: 'Kanopi ve kokpit',
    6: 'Turbofan motor',
    7: 'Hava alığı',
    8: 'Fan',
    9: 'Dış aydınlatma',
    10: 'Burun iniş takımı',
    11: 'Konformal yakıt tankları ve kanatlar',
    12: 'Radom ve burun',
    13: 'Kuyruk',
    14: 'Aksesuar dişli kutusu',
    15: 'Art yakıcı ve lüle',
    16: 'Kokpit ve fırlatma koltukları',
}

C = Content(
    HERE, model='NAYAJET',
    applic='F-16F Block 60, iki kişilik',
    product='F-16F Block 60',
    manual='F-16F Block 60 genel bakım el kitabı',
    sns=SNS, figures=FIGURES, general='00',
    liquids=('yağı', 'sıvısı', 'yakıt'))
code, dm, part = C.code, C.dm, C.part

# Her prosedürde tekrarlanan güvenlik koşulları.
SAFE = ('Uçak takozlu ve topraklı; iniş takımı emniyet pimleri ve fırlatma '
        'koltuğu emniyet pimleri takılı.')
ENGINE_OFF = 'Motor durdurulmuş, ana şalter kapalı.'
INTAKE = ('Motor çalışırken hava alığının önündeki tehlike bölgesine '
          'girmeyin; emme insanı ve gevşek eşyayı içine çeker.')
HOT = ('Motor durduktan sonra lüle, art yakıcı ve frenler uzun süre sıcak '
       'kalır; soğumasını bekleyin.')
NO_VALUES = ('Ölçü, basınç ve tork değerleri bu şablonda verilmez; uçağın '
             'kendi teknik el kitabındaki değerleri kullanın.')
POWER_OFF = ('Elektrik gücü kesik; ilgili devre kesiciler açık ve '
             'etiketli.')
HYD_OFF = 'Hidrolik sistemlerde basınç yok.'
TEST = ('Takılan parçanın çalışma testini uçağın kendi teknik el kitabına '
        'göre yapın ve sonucu kayda geçirin.')
TORQUE = ('Bağlantı elemanlarını el kitabındaki torkta sıkın ve '
          'emniyetleyin.')


def proc(code, tech, steps, info=None, conditions=None, **kw):
    """Prosedür DM'i; koşullar verilmezse uçak emniyetli ve motor
    durdurulmuş kabul edilir."""
    return dm(code=code, tech=tech, info=info, steps=steps,
              conditions=[SAFE, ENGINE_OFF] if conditions is None
              else conditions, **kw)


def replace(code, tech, removal, install, test=TEST, **kw):
    """Değiştirme DM'i: sökme, takma ve çalışma testi."""
    return proc(code, tech, [('Sökme', removal), ('Takma', install), test],
                **kw)


def isolate(code, tech, info, fault, descr, checks, fallback):
    """Zincir biçimli arıza bulma DM'i. [checks]: (yapılacak iş, soru,
    evetse yapılacak, evetse gidilecek DM). Her soruda "evet" bir sonuca,
    "hayır" bir sonraki adıma gider; son "hayır" [fallback]'e
    (metin, DM)."""
    steps, ends = [], []
    for i, (action, question, result, target) in enumerate(checks, 1):
        later = f'stp-{i + 1:04d}' if i < len(checks) else 'end-last'
        steps.append((f'stp-{i:04d}', action, question, f'end-{i:04d}',
                      later))
        ends.append((f'end-{i:04d}', result, target))
    ends.append(('end-last', *fallback))
    return dm(code=code, tech=tech, info=info, isolation={
        'fault': fault, 'descr': descr, 'steps': steps, 'ends': ends})


# --- DM içerikleri ---------------------------------------------------------
#
# Alanlar `templates/scripts/s1000d_content.py` başında anlatılıyor.

# Genel
AIRCRAFT = dm(
    code=code('00'), tech='F-16F Block 60', figure=1,
    description=[
        ('Genel', [
            'F-16, General Dynamics (bugün Lockheed Martin) tarafından '
            'geliştirilen tek motorlu bir askerî uçaktır. Block 60 '
            'sürümünün tek kişilik olanı E, iki kişilik olanı F adını taşır; '
            'F\'de ön ve arka kokpit art arda dizilidir.',
            'Block 60 sürümünde gövdenin üstünde iki yanda konformal yakıt '
            'tankları bulunur; bu tanklar gövde içi tanklara ek yakıt '
            'taşır ve onlarla birlikte doldurulup muayene edilir.',
        ]),
        ('Sistemler', [
            'Gövde: tek parça kanat-gövde birleşimi, burunda radom, gövdenin '
            'altında hava alığı, üstte kabarcık biçimli kanopi.',
            'Uçuş kumandaları: elektrikli (fly-by-wire) kumanda; flaperonlar, '
            'hücum kenarı flapları, tek parça hareket eden yatay kuyruklar, '
            'dümen ve kuyruk yanlarındaki hava frenleri.',
            'İniş takımı: gövdenin içine katlanan ana iniş takımları ve '
            'geriye katlanan burun iniş takımı; ana tekerleklerde disk '
            'frenler.',
            'Güç: tek bir art yakıcılı turbofan motor; iki ayrı hidrolik '
            'sistem kumanda yüzeylerini ve iniş takımını çalıştırır.',
        ]),
        ('Bu el kitabı hakkında', [
            'Bu şablon eğitim amaçlıdır ve yalnız genel bakım bilgisi içerir. '
            + NO_VALUES,
            'Dış yükler (füzeler, bombalar, dış yakıt tankları ve pilonlar) '
            'modelde gösterilmez.',
            'Modeldeki motor genel bir çift milli turbofan modelidir; Block '
            '60\'ın gerçek motoru (General Electric F110-GE-132) değildir. Ana '
            'bölümleri aynıdır: fan, kompresörler, yanma odası, türbinler. Art '
            'yakıcı kanalı temsilidir.',
        ]),
    ])

PREFLIGHT = dm(
    code=code('00', info='300'), tech='Uçak', info='Uçuş öncesi dış kontrol',
    figure=1, conditions=[SAFE, ENGINE_OFF],
    steps=[
        'Uçağın çevresinde burundan başlayıp saat yönünde dolaşın; yerde '
        'yakıt, yağ ya da hidrolik sıvısı lekesi olup olmadığına bakın.',
        ('Burun ve gövde', [
            'Radomda çatlak, erozyon ya da yıldırım izi olup olmadığına '
            'bakın.',
            'Erişim panellerinin kapalı ve kilitli olduğunu kontrol edin.',
            'Hava alığı kapağını çıkarın; alığın içinde yabancı cisim (FOD) '
            'olmadığını el feneriyle kontrol edin.',
        ]),
        ('Kanatlar ve kuyruk', [
            'Hücum kenarı flaplarını, flaperonları, yatay kuyrukları ve '
            'dümeni hasar ve gevşek bağlantı açısından kontrol edin.',
            'Hava frenlerinin kapalı olduğunu ve lülede yabancı cisim '
            'olmadığını kontrol edin.',
        ]),
        ('İniş takımı', [
            'Lastiklerin aşınmasını ve şişkinliğini kontrol edin.',
            'Amortisör dikmelerinin uzamasını ve sızıntı olup olmadığını '
            'kontrol edin.',
            'Fren aşınma pimlerine bakın.',
        ]),
        'Bütün kapakları, kılıfları ve emniyet pimlerini (uçuş için '
        'çıkarılanlar) sayın ve kaydedin.',
    ])

POSTFLIGHT = dm(
    code=code('00', info='310'), tech='Uçak', info='Uçuş sonrası gözle muayene',
    figure=1, conditions=[ENGINE_OFF],
    warnings=[HOT],
    steps=[
        'İniş takımı ve koltuk emniyet pimlerini takın; takozları koyun.',
        'Hava alığına, lüleye ve pitot tüpüne kılıflarını takın.',
        'Lastiklerde kesik, frenlerde aşırı ısınma izi olup olmadığına '
        'bakın.',
        'Gövde altında yeni bir sızıntı izi olup olmadığını kontrol edin.',
        'Pilotun bildirdiği arızaları ve uçuşta görülen uyarıları kayda '
        'geçirin.',
    ])

# Kokpit
dm(code=code('25', '1', '300'), tech='Fırlatma koltukları',
   info='Emniyet kontrolü', figure=5,
   conditions=[SAFE, ENGINE_OFF],
   warnings=['Fırlatma koltuğu patlayıcı eleman içerir. Koltuk emniyet '
             'pimleri takılı olmadan kokpite girmeyin.',
             'Koltuk üzerindeki her bakım işini yalnız yetkili koltuk '
             'personeli yapar.'],
   steps=[
       'Kokpite girmeden önce iki koltuğun emniyet pimlerinin takılı '
       'olduğunu dışarıdan kontrol edin.',
       'Kanopi emniyet pimlerinin takılı olduğunu kontrol edin.',
       'Koltuk kemerlerinde ve paraşüt kılıfında yırtık ya da aşınma olup '
       'olmadığına bakın.',
       'Bulduğunuz eksikliği koltuk personeline bildirin; koltuğa müdahale '
       'etmeyin.',
   ], next=code('25', '3', '310'))

# Uçuş kumandaları
CONTROLS = dm(
    code=code('27'), tech='Uçuş kumandaları', figure=4,
    description=[
        ('Genel', [
            'F-16\'nın uçuş kumandası elektriklidir (fly-by-wire). Pilotun '
            'kumandası uçuş kumanda bilgisayarına gider; '
            'bilgisayar kumanda yüzeylerinin hidrolik eyleyicilerini '
            'çalıştırır.',
        ]),
        ('Yüzeyler', [
            'Flaperonlar kanatların firar kenarındadır; hem kanatçık hem flap '
            'görevi görür.',
            'Hücum kenarı flapları hıza ve hücum açısına göre kendiliğinden '
            'hareket eder.',
            'Yatay kuyruklar tek parça döner (stabilatör); birlikte dönünce '
            'yunuslama, ters yönde dönünce yatış sağlar.',
            'Dümen dikey kuyruğun firar kenarındadır. Hava frenleri lülenin '
            'iki yanında açılır.',
        ]),
    ])

CONTROLS_CHECK = dm(
    code=code('27', info='310'), tech='Kumanda yüzeyleri', figure=4,
    conditions=[SAFE, ENGINE_OFF],
    warnings=['Hidrolik basınç verilmişken kumanda yüzeylerinin hareket '
              'alanında durmayın; yüzeyler aniden hareket edebilir.'],
    steps=[
        'Flaperonları, hücum kenarı flaplarını, yatay kuyrukları ve dümeni '
        'sırayla kontrol edin.',
        'Yüzeylerde ezik, çatlak, delik ya da kaplama ayrılması olup '
        'olmadığına bakın.',
        'Menteşe bağlantılarının ve eyleyici bağlantılarının yerinde '
        'olduğunu, emniyet tellerinin sağlam olduğunu kontrol edin.',
        'Eyleyicilerin çevresinde hidrolik sıvısı sızıntısı olup olmadığına '
        'bakın.',
        'Yüzey hareket testleri uçuş kumanda personelince, hidrolik basınç '
        'verilerek yapılır.',
    ])

SPEED_BRAKES = dm(
    code=code('27', '5', '310'), tech='Hava frenleri', figure=4,
    conditions=[SAFE, ENGINE_OFF],
    warnings=[HOT],
    steps=[
        'Hava frenlerinin kapalı konumda gövdeye tam oturduğunu kontrol '
        'edin.',
        'Fren panellerinin iç yüzünde ısı izi, çatlak ya da gevşek perçin '
        'olup olmadığına bakın.',
        'Eyleyicide ve hidrolik hatlarında sızıntı olup olmadığını kontrol '
        'edin.',
    ])

# Yakıt
REFUEL = dm(
    code=code('28', '1', '210'), tech='Yakıt', info='Yerde ikmal',
    figure=1, supplies=[('Jet yakıtı', None)],
    conditions=[SAFE, ENGINE_OFF, 'Yangın söndürücü hazır.'],
    warnings=['Yakıt buharı yanıcıdır. İkmal sırasında uçağın çevresinde '
              'sigara içmeyin, telsiz ve cep telefonu kullanmayın.',
              'Uçağı ve ikmal aracını ikmalden önce topraklayın.'],
    steps=[
        'İkmal paneli kapağını açın.',
        'Tek nokta ikmal ağzının kapağını çıkarın, ağzı temizleyin.',
        'İkmal tabancasını takın ve kilitleyin.',
        'İkmali başlatın; panel göstergelerinden tankların dolmasını izleyin.',
        'İkmal bitince tabancayı çıkarın, kapakları kapatın ve dökülen '
        'yakıtı temizleyin.',
    ])

FUEL_DRAIN = dm(
    code=code('28', '1', '300'), tech='Yakıt tankları',
    info='Su boşaltma kontrolü',
    tools=[('Yakıt örnek kabı', 1)],
    conditions=[SAFE, ENGINE_OFF, 'İkmalden sonra yakıtın dinlenmesi için '
                'beklenmiş.'],
    warnings=['Yakıt cilde zararlıdır; eldiven ve gözlük takın.'],
    steps=[
        'Tank boşaltma valflerinden örnek kabına bir miktar yakıt alın.',
        'Örneği ışığa tutun: yakıt berrak olmalı, dipte su damlası ya da '
        'tortu olmamalıdır.',
        'Su varsa temiz yakıt gelene kadar boşaltmayı sürdürün ve kayda '
        'geçirin.',
    ])

CFT = dm(
    code=code('28', '2', '310'), tech='Konformal yakıt tankları', figure=1,
    conditions=[SAFE, ENGINE_OFF],
    steps=[
        'Tankların gövdeye bağlantı hattı boyunca yakıt izi ya da ıslaklık '
        'olup olmadığına bakın.',
        'Tank yüzeyinde ezik, çatlak ya da kaplama kalkması olup olmadığını '
        'kontrol edin.',
        'Erişim kapaklarının ve bağlantı elemanlarının yerinde olduğunu '
        'kontrol edin.',
    ])

# Hidrolik
HYD_CHECK = dm(
    code=code('29', '1', '300'), tech='Hidrolik sıvısı',
    info='Seviye kontrolü',
    conditions=[SAFE, ENGINE_OFF, 'Hidrolik sistemlerde basınç yok.'],
    warnings=['Hidrolik sıvısı göze ve cilde zararlıdır; gözlük ve eldiven '
              'takın.'],
    steps=[
        'A ve B sistemlerinin depo seviye göstergelerini okuyun.',
        'Seviye düşükse el kitabında belirtilen sıvıyla, servis arabası '
        'kullanarak tamamlayın.',
        'Seviye sık sık düşüyorsa sızıntı arayın.',
    ])

HYD_ISOLATE = dm(
    code=code('29', info='421'), tech='Hidrolik sistem',
    info='Basınç düşük: arıza bulma',
    isolation={
        'fault': 'NAYAJET-29-001',
        'descr': 'A ya da B hidrolik sisteminde basınç uyarısı yanıyor ya da '
                 'basınç düşük gösteriyor.',
        'steps': [
            ('stp-0001', 'Uyarı veren sistemin depo seviyesini kontrol edin.',
             'Seviye düşük mü?', 'stp-0002', 'end-pump'),
            ('stp-0002', 'Eyleyicileri, iniş takımı yuvalarını ve gövde '
             'altını sızıntı açısından kontrol edin.',
             'Görünür bir sızıntı var mı?', 'end-leak', 'end-refill'),
        ],
        'ends': [
            ('end-pump', 'Seviye normal: hidrolik pompası ya da basınç '
             'göstergesi arızalı olabilir; pompayı değiştirmeden önce '
             'hidrolik personeline gösterge devresini kontrol ettirin.',
             code('29', '2', '920')),
            ('end-leak', 'Sızan hattı, hortumu ya da bağlantıyı hat '
             'muayenesiyle bulun ve onartın; sonra sıvıyı tamamlayın.',
             code('29', '1', '310')),
            ('end-refill', 'Sıvıyı tamamlayın ve sonraki uçuşlarda seviyeyi '
             'izleyin.', code('29', '1', '300')),
        ],
    })

# İniş takımı
GEAR = dm(
    code=code('32'), tech='İniş takımı', figure=3,
    description=[
        ('Genel', [
            'Üç tekerlekli iniş takımı hidrolikle açılıp kapanır. Ana iniş '
            'takımları gövdenin içine, burun iniş takımı geriye, hava '
            'alığının arkasına katlanır.',
            'Her dikmede yağ ve azot dolu bir amortisör iniş darbesini '
            'sönümler.',
            'Ana tekerleklerde kilitlenme önleyici (anti-skid) sistemli disk '
            'frenler vardır. Burun tekerleği yerde yönlendirme için döner.',
        ]),
    ])

GEAR_ISOLATE = dm(
    code=code('32', info='421'), tech='İniş takımı',
    info='Taksi sorunları: arıza bulma',
    isolation={
        'fault': 'NAYAJET-32-001',
        'descr': 'Uçak taksi sırasında bir yana çekiyor, frenler zayıf '
                 'tutuyor ya da burun tekerleği titriyor.',
        'steps': [
            ('stp-0001', 'Lastikleri kontrol edin.',
             'Bir lastik inik, kesik ya da aşınma sınırında mı?', 'end-tire',
             'stp-0002'),
            ('stp-0002', 'Fren aşınma pimlerine bakın.',
             'Pim gövdeyle aynı hizaya inmiş mi?', 'end-brake', 'stp-0003'),
            ('stp-0003', 'Burun iniş takımının dikmesini ve tork kolunu '
             'kontrol edin.', 'Boşluk ya da sızıntı var mı?', 'end-nose',
             'end-service'),
        ],
        'ends': [
            ('end-tire', 'Lastik basıncını ölçün ya da tekeri değiştirin.',
             code('32', '4', '300')),
            ('end-brake', 'Fren aşınmış: freni değiştirtin.',
             code('32', '4', '310')),
            ('end-nose', 'Burun iniş takımını muayene edin.',
             code('32', '2', '310')),
            ('end-service', 'Görünür bir sorun yok: fren kumandası ya da '
             'yönlendirme sistemi arızalı olabilir; burun tekerleği '
             'yönlendirmesini kontrol edin.', code('32', '6', '421')),
        ],
    })

MAIN_GEAR = dm(
    code=code('32', '1', '310'), tech='Ana iniş takımı', figure=3,
    conditions=[SAFE, ENGINE_OFF],
    warnings=['İniş takımı emniyet pimleri takılı olmadan iniş takımı '
              'yuvasına girmeyin.'],
    steps=[
        'Amortisör dikmesinin parlak krom kısmının uzunluğunu kontrol edin; '
        'çok kısa dikme azot ya da yağ kaybına işaret eder.',
        'Dikmenin krom yüzeyinde çizik, pas ya da yağ izi olup olmadığına '
        'bakın.',
        'Yan dikmeyi, kilit mekanizmasını ve hidrolik hatları kontrol edin.',
        'İniş takımı kapaklarının menteşelerini ve bağlantılarını kontrol '
        'edin.',
    ], next=code('32', '1', '210'))

NOSE_GEAR = dm(
    code=code('32', '2', '310'), tech='Burun iniş takımı', figure=1,
    conditions=[SAFE, ENGINE_OFF],
    steps=[
        'Burun dikmesinin uzamasını ve krom yüzeyini kontrol edin.',
        'Tork kolunda (makas) boşluk ya da aşınma olup olmadığına bakın.',
        'Yönlendirme mekanizmasında ve hatlarında sızıntı olup olmadığını '
        'kontrol edin.',
        'Burun tekerleğinin lastiğini ve kapaklarını kontrol edin.',
    ])

TIRES = dm(
    code=code('32', '4', '300'), tech='Lastikler',
    info='Basınç ve aşınma kontrolü', figure=3,
    tools=[('Lastik basınç ölçer', 1), ('Diş derinliği ölçer', 1)],
    supplies=[('Azot', None)],
    conditions=[SAFE, ENGINE_OFF, 'Lastikler soğuk.'],
    warnings=['Sıcak frenli tekerleğe yaklaşmayın; lastik patlayabilir. '
              'Tekerleğe yan taraftan yaklaşın.'],
    steps=[
        'Lastik basıncını soğuk lastikte ölçün. ' + NO_VALUES,
        'Basınç düşükse azotla tamamlayın; lastikleri hava ile doldurmayın.',
        'Diş derinliğini ve aşınma işaretlerini kontrol edin.',
        'Yanaklarda kesik, şişkinlik ya da kord görünmesi olup olmadığına '
        'bakın. Kord görünen lastiği değiştirin.',
    ], next=code('32', '4', '920'))

WHEEL_CHANGE = dm(
    code=code('32', '4', '920'), tech='Tekerlek', figure=3,
    tools=[('Aks krikosu', 1), ('Tekerlek somunu anahtarı', 1),
           ('Tork anahtarı', 1)],
    spares=[('Tekerlek, lastiğiyle', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Frenler ve tekerlek soğuk.'],
    warnings=['Lastik sökülmeden önce havası (azotu) boşaltılmalıdır; '
              'basınçlı tekerleği sökmeyin.'],
    steps=[
        'Diğer tekerleklere takoz koyun.',
        'Krikoyu aks altındaki krikolama noktasına yerleştirin ve tekerleği '
        'yerden biraz kaldırın.',
        'Lastiğin basıncını boşaltın.',
        'Göbek kapağını ve aks somununu sökün; tekerleği frenden ayırarak '
        'çıkarın.',
        'Yeni tekerleği aksa takın, somunu el kitabındaki torkta sıkın ve '
        'emniyetleyin.',
        'Krikoyu indirin ve lastik basıncını kontrol edin.',
    ])

BRAKES = dm(
    code=code('32', '4', '310'), tech='Tekerlek frenleri', figure=3,
    conditions=[SAFE, ENGINE_OFF, 'Park freni çekili.'],
    warnings=[HOT],
    steps=[
        'Park freni çekiliyken aşınma pimlerinin fren gövdesinden ne kadar '
        'çıktığına bakın; pim gövdeyle aynı hizadaysa fren aşınma '
        'sınırındadır.',
        'Fren gövdesinde ve hatlarında hidrolik sıvısı sızıntısı olup '
        'olmadığını kontrol edin.',
        'Fren disklerinde aşırı ısınma izi (renk değişimi) olup olmadığına '
        'bakın.',
    ], next=code('32', '4', '920', '01'))

HOOK = dm(
    code=code('32', '5', '310'), tech='Kuyruk kancası', figure=1,
    conditions=[SAFE, ENGINE_OFF],
    warnings=['Kanca altında çalışırken kancanın kilitli olduğundan emin '
              'olun; kanca serbest kalırsa ağır yaralanmaya yol açar.'],
    steps=[
        'Kancanın yuvasında kilitli olduğunu kontrol edin.',
        'Kanca ucunda aşınma, çentik ya da çatlak olup olmadığına bakın.',
        'Sönümleyicide ve hatlarında sızıntı olup olmadığını kontrol edin.',
    ])

# Gövde
RADOME = dm(
    code=code('53', '2', '310'), tech='Radom', figure=1,
    conditions=[SAFE, ENGINE_OFF],
    cautions=['Radomu boyamayın ve üzerine metal bantlar yapıştırmayın.'],
    steps=[
        'Radom yüzeyinde erozyon, kabarma ya da boya kalkması olup '
        'olmadığına bakın.',
        'Yıldırım çarpması izlerine (yanık nokta, delik) dikkat edin; '
        'yıldırım koruma şeritlerinin yerinde olduğunu kontrol edin.',
        'Radom kilitlerinin kapalı olduğunu kontrol edin.',
    ], next=code('53', '2', '920'))

INTAKE_CHECK = dm(
    code=code('53', '3', '310'), tech='Hava alığı',
    info='Yabancı cisim (FOD) muayenesi', figure=7,
    tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF],
    warnings=[INTAKE],
    cautions=['Alığa girmeden önce ceplerinizi boşaltın ve aletlerinizi '
              'sayın; içeride bırakılan her eşya motora zarar verir.'],
    steps=[
        'Alık kapağını çıkarın.',
        'Alık kanalını el feneriyle girişten fan yüzüne kadar kontrol edin.',
        'Kanal kaplamasında gevşek perçin, çatlak ya da eksik parça olup '
        'olmadığına bakın.',
        'Bulunan yabancı cismi çıkarın ve kayda geçirin; fan kanatlarını da '
        'muayene edin.',
        'Çıkarken aletlerinizi yeniden sayın.',
    ],
    next=code('72', '1', '310'))

# Kanopi
CANOPY_CLEAN = dm(
    code=code('56', '1', '250'), tech='Kanopi camı', figure=5,
    supplies=[('Kanopi temizleme sıvısı', 1), ('Yumuşak pamuklu bez', 2)],
    conditions=[SAFE, ENGINE_OFF],
    cautions=['Kanopi camı kolay çizilir. Kuru bezle silmeyin, kâğıt havlu '
              've çözücü kullanmayın.'],
    steps=[
        'Camdaki tozu bol temiz suyla yıkayarak alın.',
        'Temizleme sıvısını cama püskürtün.',
        'Yumuşak bezle düz hareketlerle, tek yönde silin; dairesel '
        'hareketlerden kaçının.',
        'Camı ışığa karşı kontrol edin; çizik ve çatlakları kayda geçirin.',
    ])

CANOPY_CHECK = dm(
    code=code('56', '1', '310'), tech='Kanopi', figure=5,
    conditions=[SAFE, ENGINE_OFF],
    warnings=['Kanopi açma ve atma sistemi patlayıcı eleman içerir; kanopi '
              'emniyet pimleri takılı olmalıdır.'],
    steps=[
        'Kanopi camında çatlak, çizik ya da renk değişimi olup olmadığına '
        'bakın.',
        'Kanopi çerçevesinin kilit pimlerini ve menteşesini kontrol edin.',
        'Kanopi contasında yırtık ya da sertleşme olup olmadığını kontrol '
        'edin; bozuk conta kokpit basıncını tutmaz.',
    ], next=code('56', '1', '250'))

# Kanatlar ve kuyruk
dm(code=code('57', info='310'), tech='Kanatlar ve kuyruk', figure=4,
   conditions=[SAFE, ENGINE_OFF],
   steps=[
       'Kanat üst ve alt yüzeylerinde ezik, çatlak ya da gevşek bağlantı '
       'elemanı olup olmadığına bakın.',
       'Kanat altı panellerinde ve bağlantı noktalarında yakıt sızıntısı '
       'olup olmadığını kontrol edin.',
       'Dikey kuyruğun ve dümen menteşelerinin çevresini kontrol edin.',
       'Kanat uçlarındaki seyir lambalarının camlarını kontrol edin.',
   ])

# Motor
ENGINE = dm(
    code=code('72'), tech='Motor', figure=6,
    description=[
        ('Genel', [
            'Turbofan motorda hava önce fandan geçer. Havanın bir kısmı '
            'çekirdeğe girer, bir kısmı çekirdeğin çevresinden dolaşan baypas '
            'kanalından geçer.',
            'Çekirdekte alçak ve yüksek basınç kompresörleri havayı sıkıştırır. '
            'Yanma odasında yakıt yakılır; sıcak gaz yüksek ve alçak basınç '
            'türbinlerini döndürür. Türbinler miller üzerinden kompresörleri '
            've fanı çevirir.',
            'Art yakıcı, türbinden çıkan gaza yeniden yakıt püskürterek '
            'yakan bölümdür. Lüle, çıkış alanını motorun çalışma durumuna '
            'göre açar ve kapatır.',
        ]),
        ('Aksesuar dişli kutusu', [
            'Motorun altındaki aksesuar dişli kutusu, yüksek basınç milinden '
            'bir dikey milde aldığı hareketle yakıt pompası, yağ pompası ve '
            'jeneratör gibi yardımcıları çalıştırır.',
        ]),
        ('Bu modeldeki motor', [
            'Modeldeki motor genel bir çift milli turbofan modelidir; F110 '
            'motorunun birebir modeli değildir. Art yakıcı kanalı temsilidir.',
        ]),
    ])

ENGINE_ISOLATE = dm(
    code=code('72', info='421'), tech='Motor',
    info='Çalıştırmada ateşleme yok: arıza bulma',
    isolation={
        'fault': 'NAYAJET-72-001',
        'descr': 'Motor çalıştırma sırasında dönüyor ama ateşleme olmuyor ya '
                 'da egzoz sıcaklığı yükselmiyor.',
        'steps': [
            ('stp-0001', 'Yakıt miktar göstergesini ve yakıt valflerinin '
             'konumunu kontrol edin.', 'Yakıt var ve valfler açık mı?',
             'stp-0002', 'end-fuel'),
            ('stp-0002', 'Çalıştırma sırasında ateşleyicilerin çıtırtısını '
             'yetkili personel eşliğinde dinleyin.',
             'Ateşleyiciler çalışıyor mu?', 'end-nozzles', 'stp-0003'),
            ('stp-0003', 'Ateşleme ünitesinin çıkışını yetkili motor '
             'personeline el kitabındaki yöntemle kontrol ettirin.',
             'Ünite yüksek gerilim üretiyor mu?', 'end-igniters',
             'end-unit'),
        ],
        'ends': [
            ('end-fuel', 'Yakıt ikmali yapın ya da valf konumlarını '
             'düzeltin.', code('28', '1', '210')),
            ('end-igniters', 'Ünite sağlam: ateşleyicileri değiştirin.',
             code('74', '1', '920')),
            ('end-unit', 'Ateşleme ünitesi arızalı: üniteyi değiştirtin ve '
             'ateşleme sistemini test edin.', code('74', '1', '320')),
            ('end-nozzles', 'Ateşleme var ama motor tutmuyor: yakıt '
             'enjektörleri tıkalı olabilir; boroskop muayenesi yaptırın.',
             code('72', '2', '310')),
        ],
    })

FAN_CHECK = dm(
    code=code('72', '1', '310'), tech='Fan ve kompresör girişi', figure=8,
    tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF],
    warnings=[INTAKE],
    steps=[
        'Hava alığından fan yüzüne bakın.',
        'Fan kanatlarının hücum kenarlarında çentik, eğilme ya da çatlak olup '
        'olmadığını kontrol edin.',
        'Fanı yavaşça elle çevirin (yetkili personel); sürtünme ya da '
        'takılma sesi olmamalıdır.',
        'Hasar bulursanız motorun çalıştırılmasını durdurun ve motor '
        'personeline bildirin.',
    ])

BORESCOPE = dm(
    code=code('72', '2', '310'), tech='Motor iç parçaları',
    info='Boroskop muayenesi', figure=6,
    tools=[('Boroskop', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Motor soğumuş.',
                'Muayene sertifikalı motor personelince yapılır.'],
    warnings=[HOT],
    steps=[
        'Motor üzerindeki boroskop deliklerinin kapaklarını sökün.',
        'Boroskobu sırayla kompresör, yanma odası ve türbin bölgelerine '
        'sokun.',
        'Kompresör kanatlarında çentik ve aşınma, yanma odası astarında '
        'çatlak ve yanık, yakıt enjektörlerinde tıkanma ve türbin '
        'kanatlarında yanma ya da kaplama kaybı arayın.',
        'Görüntüleri kaydedin ve el kitabındaki kabul sınırlarıyla '
        'karşılaştırın.',
        'Kapakları yeni contalarıyla takın.',
    ])

NOZZLE = dm(
    code=code('72', '5', '310'), tech='Art yakıcı ve egzoz lülesi',
    figure=2, tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Motor soğumuş.'],
    warnings=[HOT],
    steps=[
        'Lüle kapaklarını (yaprakları) çatlak, yanık ve eksik parça açısından '
        'kontrol edin.',
        'Lülenin içinden art yakıcı astarına bakın; astarda çatlak ya da '
        'çökme olmamalıdır.',
        'Alev tutucu halkalarında ve yakıt püskürtme halkalarında yanık izi '
        'olup olmadığını kontrol edin.',
        'Lüle eyleyicilerinde sızıntı olup olmadığına bakın.',
    ], next=[code('72', '5', '920'), code('72', '0', '520')])

OIL_CHECK = dm(
    code=code('79', '1', '300'), tech='Motor yağı', info='Seviye kontrolü',
    figure=2, supplies=[('Motor yağı, sentetik türbin yağı', None)],
    conditions=[SAFE, ENGINE_OFF,
                'Motor durdurulduktan sonra el kitabındaki süre içinde.'],
    warnings=['Sıcak yağ ve sentetik türbin yağı cilde zararlıdır; eldiven '
              'takın.'],
    steps=[
        'Motor yağ deposunun gözetleme camından ya da seviye göstergesinden '
        'seviyeyi okuyun.',
        'Seviye düşükse doldurma kapağından el kitabında belirtilen yağdan '
        'tamamlayın; farklı yağları karıştırmayın.',
        'Eklenen yağ miktarını kaydedin; yağ tüketimindeki artış motor '
        'arızasının ilk belirtisi olabilir.',
    ])

# Genel uyarılar
SAFETY = dm(
    code=code('00', info='012'), tech='F-16F Block 60',
    info='Genel uyarılar ve emniyet', figure=1,
    description=[
        ('Uçağın çevresinde', [
            'Uçağa yaklaşmadan önce iniş takımı emniyet pimlerinin, fırlatma '
            'koltuğu ve kanopi emniyet pimlerinin takılı olduğunu kontrol '
            'edin. Pimlerin kırmızı bayrakları dışarıdan görünür.',
            'Motor çalışırken hava alığının önü emme, lülenin arkası sıcak '
            'egzoz tehlike bölgesidir. Bu bölgelere hiçbir koşulda girmeyin.',
            'Hidrolik basınç verilmişken kumanda yüzeylerinin, hava '
            'frenlerinin, iniş takımı kapaklarının ve kanopinin hareket '
            'alanında durmayın.',
            'Uçak her zaman topraklı olmalıdır. Yakıt ikmali, boşaltma ve '
            'elektrik işlerinde topraklama kablosunu ilk takılan, son sökülen '
            'bağlantı yapın.',
        ]),
        ('Patlayıcı ve tehlikeli maddeler', [
            'Fırlatma koltukları ve kanopi atma sistemi patlayıcı eleman '
            'içerir. Bu sistemlere yalnız yetkili koltuk personeli dokunur.',
            'Acil güç ünitesinin yakıtı zehirli ve yanıcı bir sıvıdır. Sızıntı '
            'şüphesinde bölgeyi boşaltın ve yetkili ekibi çağırın.',
            'Jet yakıtı, hidrolik sıvısı, sentetik türbin yağı ve temizlik '
            'maddeleri cilde ve göze zararlıdır; eldiven ve gözlük kullanın.',
        ]),
        ('Bu şablon hakkında', [
            'Prosedürler genel bakım bilgisidir ve eğitim amaçlıdır. ' +
            NO_VALUES,
            'Her işten önce ve sonra alet sayımı yapın; uçakta unutulan alet '
            'motor için yabancı cisimdir.',
        ]),
    ])

# Periyodik muayeneler
PHASE = proc(
    code('05', '1', '300'), 'Uçak', info='Faz muayenesi', figure=1,
    tools=[('El feneri', 1), ('Ayna', 1), ('Boroskop', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, HYD_OFF,
                'Uçak hangarda; erişim panelleri muayene planına göre '
                'açılmış.'],
    warnings=[HOT],
    steps=[
        'Muayene aralığını ve ek işleri uçağın bakım programından alın; '
        'önceki muayenede açık kalan kayıtları gözden geçirin.',
        ('Gövde ve kanatlar', [
            'Gövde, kanat, kuyruk ve konformal tank yüzeylerini çatlak, ezik, '
            'korozyon ve gevşek bağlantı elemanı açısından muayene edin.',
            'Radomu, hava alığını ve iniş takımı kapaklarını muayene edin.',
            'Statik boşaltıcıları ve anten tabanlarını kontrol edin.',
        ]),
        ('Sistemler', [
            'Uçuş kumanda yüzeylerinin menteşe ve eyleyici bağlantılarını '
            'muayene edin.',
            'Hidrolik ve yakıt hatlarını, bağlantı noktalarını ve pompaları '
            'sızıntı ve sürtünme açısından kontrol edin.',
            'Kablo demetlerini, konnektörleri ve topraklama şeritlerini '
            'kontrol edin.',
            'Oksijen, klima ve hava alma kanallarını muayene edin.',
        ]),
        ('İniş takımı', [
            'Dikmeleri, tork kollarını, açma-kapama eyleyicilerini ve '
            'kilitleri muayene edin.',
            'Tekerlekleri, lastikleri ve frenleri muayene edin.',
        ]),
        ('Motor', [
            'Fanı, kompresör girişini ve lüleyi muayene edin.',
            'Yağ filtresini ve talaş algılayıcıyı kontrol edin; yağ örneği '
            'alın.',
            'Bakım programı gerektiriyorsa boroskop muayenesi yapın.',
        ]),
        'Bulunan her eksikliği kayda geçirin, giderilmesini izleyin ve '
        'panelleri kapatmadan önce alet sayımı yapın.',
    ])

HARD_LANDING = proc(
    code('05', '2', '300'), 'Uçak', info='Sert iniş sonrası muayene',
    figure=3, tools=[('El feneri', 1)],
    steps=[
        'Sert iniş kaydını ve pilotun bildirimini gözden geçirin.',
        'Ana ve burun iniş takımı dikmelerini, tork kollarını ve bağlantı '
        'noktalarını çatlak, eğilme ve sızıntı açısından muayene edin.',
        'Tekerlekleri ve lastikleri muayene edin.',
        'İniş takımı yuvalarında ve çevresindeki gövde yapısında buruşma, '
        'çatlak ya da gevşek perçin arayın.',
        'Kanat ve gövde birleşim bölgesini, motor bağlantılarını kontrol '
        'edin.',
        'Bulgu varsa uçağı uçuştan alıkoyun ve yapı personeline bildirin.',
    ])

LIGHTNING = proc(
    code('05', '2', '300', disassy='01'), 'Uçak',
    info='Yıldırım çarpması sonrası muayene', figure=12,
    steps=[
        'Yıldırımın giriş ve çıkış noktalarını bulun: genellikle radom, '
        'kanat uçları, kuyruk ucu ve lüle.',
        'Bu bölgelerde yanık nokta, delik, erimiş metal ve boya kalkması '
        'arayın.',
        'Radomun yıldırım koruma şeritlerini ve statik boşaltıcıları '
        'kontrol edin.',
        'Menteşelerde ve yataklarda ark izi olup olmadığına bakın.',
        'Pitot ısıtıcısının, lambaların ve elektrik sistemlerinin çalışma '
        'testlerini yapın.',
    ])

OVERTEMP = proc(
    code('05', '2', '300', disassy='02'), 'Motor',
    info='Aşırı sıcaklık sonrası muayene', figure=6,
    tools=[('Boroskop', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Motor soğumuş.',
                'Muayene sertifikalı motor personelince yapılır.'],
    warnings=[HOT],
    steps=[
        'Aşırı sıcaklık kaydını (süre ve sıcaklık) motor kayıtlarından alın.',
        'Lüleyi ve art yakıcı astarını renk değişimi ve çatlak açısından '
        'muayene edin.',
        'Türbin bölgesinin boroskop muayenesini yapın.',
        'Sonucu el kitabındaki aşırı sıcaklık sınırlarıyla karşılaştırın; '
        'sınır aşıldıysa motorun sökülmesine karar verilir.',
    ],
    next=code('72', '2', '310'))

FOD_INGEST = proc(
    code('05', '2', '300', disassy='03'), 'Motor',
    info='Yabancı cisim yutma sonrası muayene', figure=8,
    tools=[('El feneri', 1), ('Boroskop', 1)],
    warnings=[INTAKE, HOT],
    steps=[
        'Hava alığını girişten fan yüzüne kadar muayene edin; yabancı cismin '
        'kalıntılarını toplayın.',
        'Fan kanatlarını hasar açısından muayene edin.',
        'Kompresör girişinin boroskop muayenesini yapın.',
        'Pisti ve park yerini yabancı cisim için taratın.',
        'Hasar el kitabındaki sınırların dışındaysa motoru çalıştırmayın.',
    ],
    next=code('72', '1', '310'))

# Yer işlemleri
JACKING = proc(
    code('07', '1', '200'), 'Uçak', info='Krikoya alma ve indirme', figure=1,
    tools=[('Uçak krikosu', 3), ('Kriko adaptörü', 3)],
    conditions=[SAFE, ENGINE_OFF, 'Uçak düz, sağlam zeminde ve rüzgârdan '
                'korunan bir yerde.', 'Ağırlık ve denge el kitabına uygun.'],
    warnings=['Uçak krikodayken altında yalnız gerekli kişiler çalışır; '
              'krikoların emniyet somunlarını her kaldırma adımında '
              'indirin.'],
    steps=[
        'Krikoları gövdedeki işaretli krikolama noktalarının altına '
        'yerleştirin ve adaptörleri takın.',
        'Krikoları aynı anda ve dengeli yükseltin; uçağın yatay kalmasını '
        'izleyin.',
        'Tekerlekler yerden kesildiğinde emniyet somunlarını indirin.',
        'İndirirken sırayı tersine izleyin; tekerlekler yere oturunca '
        'krikoları ve adaptörleri çıkarın.',
    ])

TOWING = proc(
    code('09', '1', '200'), 'Uçak', info='Çekme', figure=10,
    tools=[('Çeki demiri', 1), ('Çekici', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Kokpitte fren için yetkili bir kişi var.',
                'Kanat uçlarında ve kuyrukta gözcüler var.'],
    warnings=['Çekme sırasında burun tekerleğinin dönüş sınırını aşmayın; '
              'aşılırsa yönlendirme mekanizması hasar görür.'],
    steps=[
        'Burun tekerleği yönlendirmesinin devre dışı olduğunu kontrol edin.',
        'Çeki demirini burun iniş takımındaki bağlantı noktasına takın.',
        'Takozları çekin, park frenini bırakın.',
        'Uçağı yavaş ve sarsıntısız çekin; gözcülerin işaretlerini izleyin.',
        'Park yerinde frenleri uygulayın, takozları koyun ve çeki demirini '
        'sökün.',
    ])

PARKING = proc(
    code('10', '1', '200'), 'Uçak', info='Park ve bağlama', figure=1,
    tools=[('Takoz', 6), ('Kılıf takımı', 1)],
    conditions=[ENGINE_OFF],
    steps=[
        'Uçağı rüzgâra karşı park edin ve takozları koyun.',
        'İniş takımı, koltuk ve kanopi emniyet pimlerini takın.',
        'Topraklama kablosunu takın.',
        'Hava alığı, lüle, pitot tüpü ve kanopi kılıflarını takın.',
        'Kuvvetli rüzgâr beklentisinde uçağı bağlama noktalarından bağlayın.',
    ])

STORAGE = proc(
    code('10', '2', '800'), 'Uçak', info='Kısa süreli depolama',
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    steps=[
        'Uçağı temizleyin ve korozyon kontrolü yapın.',
        'Yakıt tanklarını el kitabına göre dolu ya da boş bırakın; su '
        'boşaltma kontrolünü yapın.',
        'Aküyü sökün ya da bağlantısını ayırın ve şarjlı saklayın.',
        'Bütün açıklıkları kılıflarla kapatın, nem alıcıları yerleştirin.',
        'Depolama süresince periyodik kontrolleri kayda geçirin.',
    ])

SERVICE_POINTS = dm(
    code=code('12', '1', '040'), tech='Servis noktaları', figure=1,
    description=[
        ('Genel', [
            'Uçağın günlük servisi yakıt, motor yağı, hidrolik sıvısı, '
            'lastik ve amortisör azotu, oksijen ve çalıştırma akümülatörleri '
            'için yapılır.',
            'Her servis noktası panel üzerinde etiketlidir; doğru sıvıyı '
            'etiketten ve uçağın kendi el kitabından doğrulayın. ' + NO_VALUES,
        ]),
        ('Servis noktaları', [
            'Yakıt: gövdenin altındaki tek nokta ikmal ağzı; havada ikmal ağzı '
            'kanopinin arkasında, gövdenin üstündedir.',
            'Motor yağı: motor bölmesinde, alt erişim panelinin arkasındaki '
            'depo.',
            'Hidrolik: A ve B sistemlerinin depoları; seviye göstergeleri '
            'erişim panellerinin arkasında.',
            'Lastikler ve amortisörler: her dikmenin ve tekerleğin üstündeki '
            'dolum valfleri.',
            'Dış güç: gövdenin altındaki dış güç prizi.',
        ]),
    ])

WASH = proc(
    code('12', '2', '250'), 'Uçak', info='Uçak yıkama', figure=1,
    supplies=[('Uçak yıkama deterjanı', None), ('Temiz su', None),
              ('Yumuşak fırça', 2)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, 'Uçak gölgede, yüzeyler soğuk.'],
    cautions=['Pitot tüpüne, statik portlara, hava alığına ve lüleye doğrudan '
              'su tutmayın; önce kılıflarını takın.',
              'Kanopiyi uçak deterjanıyla değil, kendi temizleyicisiyle '
              'temizleyin.'],
    steps=[
        'Açıklıkların kılıflarını ve kapaklarını takın.',
        'Uçağı yukarıdan aşağıya doğru temiz suyla ıslatın.',
        'Deterjanı yumuşak fırçayla uygulayın; iniş takımı yuvalarına ve '
        'yağlı bölgelere özen gösterin.',
        'Bol suyla durulayın, kurulayın ve kılıfları çıkarın.',
        'Yıkamadan sonra yağlama noktalarını el kitabına göre yağlayın.',
    ])

SAFETY_WIRE = proc(
    code('20', '1', '310'), 'Emniyet teli ve bağlantı elemanları',
    tools=[('Emniyet teli pensi', 1)],
    steps=[
        'Emniyet tellerinin yerinde, gergin ve doğru yönde sarılmış olduğunu '
        'kontrol edin; tel bağlantı elemanını sıkma yönünde çekmelidir.',
        'Kopuk ya da kullanılmış teli yeniden kullanmayın; yenisiyle '
        'değiştirin.',
        'Kilitli somunlarda ve hızlı açılır panel kilitlerinde eksik ya da '
        'gevşek eleman arayın.',
        'Tork işaretlerinin (boya çizgisi) kaymış olup olmadığına bakın.',
    ])

CONNECTORS = proc(
    code('20', '2', '310'), 'Elektrik konnektörleri',
    supplies=[('Konnektör temizleyici', None)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    cautions=['Konnektör pinlerine metal aletle dokunmayın; pinler eğilir.'],
    steps=[
        'Konnektörün kilit halkasının tam oturduğunu kontrol edin.',
        'Ayrılan konnektörde pinleri korozyon, eğilme ve yanık açısından '
        'muayene edin.',
        'Gerekirse konnektör temizleyiciyle temizleyin ve kurumasını '
        'bekleyin.',
        'Konnektörü takın, kilitleyin ve kablo demetinin kelepçelerini '
        'kontrol edin.',
    ])

FOD = proc(
    code('20', '3', '300'), 'Yabancı cisim (FOD) önleme',
    info='Alet ve FOD kontrolü', figure=7,
    conditions=[],
    steps=[
        'İşe başlamadan önce alet çantasındaki aletleri sayın ve kaydedin.',
        'Ceplerinizi boşaltın; takı ve gevşek eşyayı çıkarın.',
        'İş bitince aletleri yeniden sayın; eksik alet bulunana kadar uçağı '
        'serbest bırakmayın.',
        'Park ve çalışma alanını yabancı cisim için düzenli olarak taratın.',
    ])

CORROSION = proc(
    code('20', '4', '250'), 'Korozyon kontrolü',
    info='Korozyon temizliği ve koruma', figure=1,
    supplies=[('Korozyon önleyici bileşik', None),
              ('Aşındırmayan temizleme pedi', 2)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    cautions=['Kompozit yüzeylerde ve radomda aşındırıcı malzeme '
              'kullanmayın.'],
    steps=[
        'Korozyona açık bölgeleri muayene edin: iniş takımı yuvaları, '
        'akü bölmesi, panel kenarları, bağlantı elemanlarının çevresi, '
        'lüle bölgesi.',
        'Korozyon izi (beyaz toz, kabarma, çukurlanma) bulursanız yerini ve '
        'boyutunu kayda geçirin.',
        'Hafif yüzey korozyonunu aşındırmayan pedle temizleyin.',
        'Temizlenen bölgeye korozyon önleyici bileşik uygulayın ve boyayı '
        'onarın.',
        'Derin korozyonu yapı personeline bildirin; sınırlar el kitabındadır.',
    ])

# Klima
ECS = dm(
    code=code('21'), tech='Klima ve basınçlandırma',
    description=[
        ('Genel', [
            'Klima sistemi motordan alınan sıcak havayı soğutur ve kokpite, '
            'kanopi contasına ve elektronik bölmelere dağıtır.',
            'Kokpit basıncı bir basınç kontrol valfiyle ayarlanır; kanopi '
            'contası şişirilerek kokpitin sızdırmazlığı sağlanır.',
        ]),
        ('Ana bölümler', [
            'Klima ünitesi: ısı değiştiriciler ve soğutma türbini.',
            'Dağıtım kanalları ve valfler.',
            'Basınç kontrol valfi ve kanopi contası şişirme hattı.',
        ]),
    ])

ECS_PACK = proc(
    code('21', '1', '310'), 'Klima ünitesi', tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, 'Sistem soğumuş.'],
    warnings=['Klima kanalları motor çalıştıktan sonra uzun süre sıcak '
              'kalır.'],
    steps=[
        'Erişim panelini açın; ısı değiştiricilerin hava girişlerinde '
        'tıkanma ve yabancı cisim olup olmadığına bakın.',
        'Ünite bağlantılarını, kelepçeleri ve yalıtımı kontrol edin.',
        'Su ayırıcının boşaltma deliğinin açık olduğunu kontrol edin.',
        'Ünitede yağ izi ya da yanık kokusu varsa ünitenin değiştirilmesi '
        'için kayda geçirin.',
    ])

ECS_PACK_REPL = replace(
    code('21', '1', '920'), 'Klima ünitesi',
    ['Erişim panelini açın.', 'Hava kanallarının kelepçelerini ve elektrik '
     'konnektörlerini ayırın; açıklıkları kapatın.',
     'Üniteyi taşıma noktalarından destekleyerek bağlantılarını sökün ve '
     'çıkarın.'],
    ['Yeni üniteyi yerine yerleştirin. ' + TORQUE,
     'Kanalları yeni contalarla bağlayın, konnektörleri takın.',
     'Erişim panelini kapatın.'],
    spares=[('Klima ünitesi', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, 'Sistem soğumuş.'])

ECS_DUCTS = proc(
    code('21', '2', '310'), 'Klima kanalları', tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    steps=[
        'Kanalları ezik, çatlak ve yalıtım hasarı açısından muayene edin.',
        'Kelepçelerin ve contaların yerinde olduğunu kontrol edin.',
        'Kanal çevresindeki yapıda ısı izi (renk değişimi) olup olmadığına '
        'bakın; sızan sıcak hava kablo ve hatlara zarar verir.',
    ])

ECS_PRESS_TEST = proc(
    code('21', '3', '320'), 'Kokpit basınçlandırma',
    info='Basınçlandırma çalışma testi', figure=5,
    tools=[('Yer basınç test seti', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Kanopi kapalı ve kilitli.',
                'Test yetkili personelce yapılır.'],
    steps=[
        'Test setini kokpit basınç test bağlantısına takın.',
        'Kanopi contasını şişirin ve kokpiti el kitabındaki test değerine '
        'basınçlandırın.',
        'Basınç düşüşünü el kitabındaki süre boyunca izleyin.',
        'Sızıntı varsa sabunlu suyla kanopi contasında, kablo ve hat '
        'geçişlerinde sızıntı noktasını arayın.',
        'Basıncı boşaltın ve test setini sökün.',
    ])

ECS_ISO = isolate(
    code('21', info='421'), 'Klima sistemi',
    'Kokpit sıcaklığı: arıza bulma', 'NAYAJET-21-001',
    'Kokpit soğumuyor ya da aşırı ısınıyor; klima kanalı çevresinde ısı '
    'izi var.',
    [('Klima kanallarını ve kelepçelerini sızıntı ve ısı izi açısından '
      'kontrol edin.', 'Kanal çatlak ya da kelepçe gevşek mi?',
      'Kanalı onartın ve kanal muayenesini tamamlayın.',
      code('21', '2', '310')),
     ('Klima ünitesinin ısı değiştirici girişlerini ve su ayırıcısını '
      'kontrol edin.', 'Giriş tıkalı ya da ünitede yağ izi var mı?',
      'Klima ünitesini değiştirin.', code('21', '1', '920')),
     ('Motordan gelen sıcak hava beslemesini kontrol edin.',
      'Hava alma kanalı aşırı ısı uyarısı da var mı?',
      'Hava alma sistemi arızasını arayın.', code('36', '1', '421'))],
    ('Bulgu yok: klima ünitesini muayene edin ve sıcaklık kumandasını '
     'yetkili personele kontrol ettirin.', code('21', '1', '310')))

# Elektrik
ELEC = dm(
    code=code('24'), tech='Elektrik gücü',
    description=[
        ('Genel', [
            'Ana jeneratör ve yedek jeneratör motorun aksesuar dişli kutusundan '
            'çalışır. Akü, motor çalışmadan önce ve acil durumda temel '
            'devreleri besler.',
            'Yerde uçak dış güç prizinden beslenebilir.',
            'Acil güç ünitesi, motor ve jeneratörler devre dışı kaldığında '
            'uçuş kumandaları için elektrik ve hidrolik güç sağlar.',
        ]),
    ])

GEN_REPL = replace(
    code('24', '2', '920'), 'Jeneratör', figure=14,
    removal=['Erişim panelini açın.', 'Elektrik konnektörünü ve soğutma '
             'kanalını ayırın.', 'Jeneratörü destekleyerek bağlantı '
             'kelepçesini açın ve dişli kutusundan çıkarın.',
             'Dişli kutusu çıkışını kapatın.'],
    install=['Tahrik milinin kanallarını ve contayı kontrol edin; contayı '
             'yenileyin.', 'Jeneratörü yerine oturtun ve kelepçeyi sıkın. '
             + TORQUE, 'Konnektörü ve soğutma kanalını takın.'],
    test='Motor yer çalıştırmasında jeneratör uyarısının söndüğünü '
         'kontrol edin ve kayda geçirin.',
    spares=[('Ana jeneratör', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF])

ELEC_ISO = isolate(
    code('24', info='421'), 'Elektrik gücü', 'Jeneratör uyarısı: arıza bulma',
    'NAYAJET-24-001',
    'Motor çalışırken ana ya da yedek jeneratör uyarı ışığı yanıyor.',
    [('Uyarının hangi jeneratör için olduğunu ve arıza kayıtlarını '
      'okuyun.', 'Uyarı yalnız yedek jeneratör için mi?',
      'Yedek jeneratörü ve bağlantısını kontrol edin; arızalıysa değiştirin.',
      code('24', '2', '920')),
     ('Jeneratör konnektörünü ve kablolarını kontrol edin.',
      'Konnektör gevşek ya da kablolarda hasar var mı?',
      'Konnektörü ve kabloyu onarın.', code('24', '6', '310')),
     ('Dişli kutusu tahrik milini kontrol edin.',
      'Tahrik mili kırık ya da kanalları aşınmış mı?',
      'Dişli kutusunu muayene edin.', code('72', '6', '310'))],
    ('Bağlantılar sağlam: ana jeneratörü değiştirin.',
     code('24', '2', '920')))

BATTERY = proc(
    code('24', '3', '300'), 'Akü', info='Akü kontrolü',
    tools=[('Akü test cihazı', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    warnings=['Akü elektroliti yakıcıdır; gözlük ve eldiven takın.'],
    steps=[
        'Akü bölmesini açın; aküyü sızıntı, şişme ve korozyon açısından '
        'muayene edin.',
        'Kutup başlarını ve konnektörü kontrol edin.',
        'Akü test cihazıyla akünün durumunu ölçün. ' + NO_VALUES,
        'Akü zayıfsa şarj edin ya da değiştirin.',
    ])

BATTERY_REPL = replace(
    code('24', '3', '920'), 'Akü',
    ['Akü konnektörünü ayırın.', 'Tutucuları açın ve aküyü çıkarın.'],
    ['Akü bölmesini temizleyin ve korozyon açısından kontrol edin.',
     'Şarjlı yeni aküyü yerleştirin, tutucuları kapatın.',
     'Konnektörü takın ve kilitleyin.'],
    test='Akü gerilimini kokpit göstergesinden kontrol edin ve kayda '
         'geçirin.',
    spares=[('Akü', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    warnings=['Akü elektroliti yakıcıdır; gözlük ve eldiven takın.'])

BATTERY_ISO = isolate(
    code('24', '3', '421'), 'Akü', 'Akü zayıf: arıza bulma', 'NAYAJET-24-002',
    'Akü uyarısı yanıyor ya da motor çalıştırmadan önce akü gerilimi '
    'düşük.',
    [('Akü konnektörünü ve kutup başlarını kontrol edin.',
      'Konnektör gevşek ya da korozyonlu mu?',
      'Konnektörü temizleyin ve sıkıca takın.', code('20', '2', '310')),
     ('Aküyü test edin.', 'Akü şarj tutmuyor mu?',
      'Aküyü değiştirin.', code('24', '3', '920'))],
    ('Akü sağlam: şarj devresi ya da jeneratör arızalı olabilir; jeneratör '
     'arızasını arayın.', code('24', info='421')))

EXT_POWER = proc(
    code('24', '4', '200'), 'Dış güç', info='Dış güç bağlama ve ayırma',
    tools=[('Yer güç ünitesi', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Yer güç ünitesi kapalı.'],
    cautions=['Yer güç ünitesini fişi takmadan önce açmayın; prizde ark '
              'oluşur.'],
    steps=[
        'Dış güç prizinin kapağını açın; pinleri yanık ve korozyon açısından '
        'kontrol edin.',
        'Fişi tam oturacak şekilde takın, sonra yer güç ünitesini açın.',
        'Ayırırken önce yer güç ünitesini kapatın, sonra fişi çıkarın.',
        'Priz kapağını kapatın.',
    ])

EXT_POWER_CHECK = proc(
    code('24', '4', '310'), 'Dış güç prizi',
    tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, 'Yer güç ünitesi ayrılmış.'],
    steps=[
        'Priz kapağını açın; kapağın contasını ve kilidini kontrol edin.',
        'Pinlerde yanık, ark izi, korozyon ve eğilme olup olmadığına bakın.',
        'Prizin gövdeye bağlantısının sıkı, arkasındaki kabloların sağlam '
        'olduğunu kontrol edin.',
        'Hafif kirli pinleri konnektör temizleyiciyle temizleyin; yanık ya '
        'da eğik pini olan prizi değiştirin.',
    ])

EXT_POWER_REPL = replace(
    code('24', '4', '920'), 'Dış güç prizi',
    removal=['Erişim panelini açın.', 'Prizin arkasındaki kablo '
             'bağlantılarını etiketleyip ayırın.',
             'Priz bağlantı elemanlarını sökün ve prizi çıkarın.'],
    install=['Yeni prizi yerleştirin. ' + TORQUE,
             'Kabloları etiketlerine göre bağlayın ve el kitabındaki torkta '
             'sıkın.', 'Erişim panelini kapatın.'],
    test='Yer güç ünitesini bağlayıp uçağa elektrik geldiğini kontrol edin; '
         'sonucu kayda geçirin.',
    spares=[('Dış güç prizi', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, 'Yer güç ünitesi ayrılmış.'])

EXT_POWER_ISO = isolate(
    code('24', '4', '421'), 'Dış güç', 'Dış güç gelmiyor: arıza bulma',
    'NAYAJET-24-003',
    'Yer güç ünitesi bağlanınca uçağa elektrik gelmiyor ya da kesik kesik '
    'geliyor.',
    [('Yer güç ünitesinin çıkışını ve kablosunu kontrol edin.',
      'Ünite ya da kablosu arızalı mı?',
      'Başka bir yer güç ünitesiyle deneyin; arızalı üniteyi yer '
      'ekipmanı bakımına gönderin.', None),
     ('Dış güç prizini muayene edin.', 'Pinlerde yanık, korozyon ya da '
      'eğilme var mı?', 'Prizi değiştirin.', code('24', '4', '920')),
     ('Prizin arkasındaki kabloları ve konnektörleri kontrol edin.',
      'Kablo ya da bağlantı hasarlı mı?', 'Kabloyu onarın.',
      code('24', '6', '310'))],
    ('Bulgu yok: elektrik dağıtımını kontrol edin.',
     code('24', info='421')))

EPU = proc(
    code('24', '5', '310'), 'Acil güç ünitesi', tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF,
                'Ünitenin emniyet pimi takılı.'],
    warnings=['Ünitenin yakıtı zehirli ve yanıcıdır. Koku, sızıntı ya da '
              'renk değişimi görürseniz bölgeden uzaklaşın ve yetkili ekibi '
              'çağırın; kendiniz müdahale etmeyin.'],
    steps=[
        'Erişim panelini açmadan önce bölgede koku olup olmadığını kontrol '
        'edin.',
        'Yakıt deposunun miktar göstergesini okuyun ve kaydedin.',
        'Depo, hat ve ünite çevresinde sızıntı izi olup olmadığına dışarıdan '
        'bakın.',
        'Ünitenin egzoz çıkışının açık ve temiz olduğunu kontrol edin.',
    ])

WIRING = proc(
    code('24', '6', '310'), 'Kablo demetleri', tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    steps=[
        'Kablo demetlerini yapıya ya da hatlara sürtünme, ezilme ve yalıtım '
        'hasarı açısından muayene edin.',
        'Kelepçelerin ve destek parçalarının yerinde olduğunu kontrol edin.',
        'Isı kaynaklarının yakınındaki kablolarda renk değişimi arayın.',
        'Topraklama şeritlerini ve bağlantılarını kontrol edin.',
        'Hasarlı kabloyu onarım için kayda geçirin.',
    ],
    next=code('20', '2', '310'))

# Kokpit
HARNESS = proc(
    code('25', '2', '310'), 'Koltuk kemerleri ve takımlar', figure=16,
    conditions=[SAFE, ENGINE_OFF],
    warnings=['Koltuk emniyet pimleri takılı olmadan kokpite girmeyin.'],
    steps=[
        'Kemerlerde yırtık, aşınma, kesik ve leke olup olmadığına bakın.',
        'Toka ve bağlantı parçalarının kolay açılıp kapandığını kontrol '
        'edin.',
        'Omuz kemerlerinin makaradan düzgün çıkıp geri sarıldığını kontrol '
        'edin.',
        'Kusurlu kemeri koltuk personeline bildirin.',
    ])

COCKPIT_CLEAN = proc(
    code('25', '3', '250'), 'Kokpit', info='Kokpit temizliği', figure=16,
    supplies=[('Ekran temizleme bezi', 2), ('Kanopi temizleme sıvısı', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    cautions=['Ekranları ve gösterge camlarını çözücüyle ya da kuru, sert '
              'bezle silmeyin; kaplamaları zarar görür.'],
    steps=[
        'Kokpitteki gevşek eşyaları ve çöpü toplayın.',
        'Tabanı ve konsolları elektrikli süpürgeyle temizleyin.',
        'Ekranları ve gösterge camlarını yumuşak bezle, tek yönde silin.',
        'HUD camını yalnız kendi temizleme malzemesiyle temizleyin.',
    ])

COCKPIT_CHECK = proc(
    code('25', '3', '310'), 'Kokpit', info='Kokpit muayenesi', figure=16,
    tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF],
    warnings=['Koltuk emniyet pimleri takılı olmadan kokpite girmeyin.'],
    steps=[
        'Koltukların altını ve konsol aralarını gevşek eşya için el '
        'feneriyle kontrol edin; kumanda yollarına sıkışan eşya tehlikelidir.',
        'Gösterge ve ekran camlarında çatlak olup olmadığına bakın.',
        'Anahtar ve düğmelerin koruyucu kapaklarını kontrol edin.',
        'Yan kumanda kolunun, gaz kolunun ve pedalların serbest olduğunu '
        'kontrol edin.',
    ], next=code('25', '3', '250'))

# Yangından korunma
FIRE = dm(
    code=code('26'), tech='Yangından korunma',
    description=[
        ('Genel', [
            'Motor bölmesindeki algılayıcı halkalar yangın ve aşırı ısıyı '
            'algılar ve kokpitte uyarı verir.',
            'Uyarı devresi kokpitteki test anahtarıyla sınanır.',
        ]),
    ])

FIRE_TEST = proc(
    code('26', '1', '320'), 'Yangın ve aşırı ısı uyarısı',
    info='Uyarı devresi çalışma testi',
    conditions=[SAFE, ENGINE_OFF, 'Uçağa elektrik gücü verilmiş.'],
    steps=[
        'Kokpitteki yangın ve aşırı ısı test anahtarını test konumuna alın.',
        'İlgili uyarı ışıklarının yandığını kontrol edin.',
        'Anahtarı bırakın; ışıkların söndüğünü kontrol edin.',
        'Sonucu kayda geçirin.',
    ])

FIRE_DET_REPL = replace(
    code('26', '1', '920'), 'Yangın algılayıcısı', figure=2,
    removal=['Motor bölmesi erişim panelini açın.', 'Algılayıcı halkanın '
             'konnektörlerini ayırın.', 'Destek kelepçelerini açın ve '
             'algılayıcıyı çıkarın.'],
    install=['Yeni algılayıcıyı aynı güzergâhta, kelepçelere oturtarak '
             'yerleştirin; keskin bükülmeden kaçının.', 'Konnektörleri '
             'takın ve emniyetleyin.'],
    test='Uyarı devresi çalışma testini yapın.',
    spares=[('Yangın algılayıcı halkası', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, 'Motor soğumuş.'])

FIRE_ISO = isolate(
    code('26', '1', '421'), 'Yangın ve aşırı ısı uyarısı',
    'Uyarı arızası: arıza bulma', 'NAYAJET-26-001',
    'Yangın ya da aşırı ısı uyarısı yerde nedensiz yanıyor ya da test '
    'sırasında yanmıyor.',
    [('Motor bölmesini gerçek ısı, yangın izi ve sıcak hava sızıntısı '
      'açısından kontrol edin.', 'Isı izi ya da sızıntı var mı?',
      'Sızıntının kaynağını giderin: hava alma kanallarını muayene edin.',
      code('36', '1', '310')),
     ('Uyarı devresi testini yapın.', 'Test sırasında ışıklar yanmıyor mu?',
      'Uyarı lambalarını ve test devresini kontrol edin.',
      code('26', '1', '320')),
     ('Algılayıcı halkanın konnektörlerini ve güzergâhını kontrol edin.',
      'Halka ezik ya da konnektör nemli mi?',
      'Algılayıcıyı değiştirin.', code('26', '1', '920'))],
    ('Bulgu yok: algılayıcıyı değiştirin ve uyarıyı izleyin.',
     code('26', '1', '920')))

# Uçuş kumandaları
ACTUATOR_REPL = replace(
    code('27', info='920'), 'Kumanda eyleyicisi', figure=4,
    removal=['Hidrolik basıncın sıfır olduğunu kontrol edin.',
             'Hidrolik hatları ve elektrik konnektörünü ayırın; açıklıkları '
             'kapatın.', 'Yüzey ve yapı bağlantı pimlerini sökün, eyleyiciyi '
             'çıkarın.'],
    install=['Yeni eyleyiciyi yerleştirin ve bağlantı pimlerini takın. '
             + TORQUE, 'Hatları yeni contalarla bağlayın, konnektörü takın.',
             'Hidrolik sistemin havasını alın ve seviyeyi tamamlayın.'],
    test='Kumanda yüzeyleri çalışma testini yapın.',
    spares=[('Kumanda eyleyicisi', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, HYD_OFF],
    warnings=['Hidrolik basınç verilmişken yüzeylerin hareket alanında '
              'durmayın.'])

CONTROLS_TEST = proc(
    code('27', info='320'), 'Kumanda yüzeyleri', info='Çalışma testi',
    figure=4,
    conditions=[SAFE, ENGINE_OFF, 'Uçağa elektrik ve yer hidrolik gücü '
                'verilmiş.', 'Yüzeylerin hareket alanı boş; gözcüler var.'],
    warnings=['Hidrolik basınç verilmişken yüzeylerin hareket alanında '
              'durmayın.'],
    steps=[
        'Kumanda bilgisayarının kendi kendini sınama (BIT) testini '
        'başlatın ve sonucu okuyun.',
        'Yan kumanda koluyla yunuslama ve yatış, pedallarla yön kumandası '
        'verin; flaperonların, yatay kuyrukların ve dümenin doğru yönde '
        'hareket ettiğini gözcüyle doğrulayın.',
        'Hareket sırasında takılma, ses ya da sarsıntı olmamalıdır.',
        'Hücum kenarı flaplarının iki yanda birlikte hareket ettiğini kontrol '
        'edin.',
        'Testten sonra gücü kesin ve sonucu kayda geçirin.',
    ])

LEF_TEST = proc(
    code('27', '4', '320'), 'Hücum kenarı flapları', info='Çalışma testi',
    figure=4,
    conditions=[SAFE, ENGINE_OFF, 'Uçağa elektrik ve yer hidrolik gücü '
                'verilmiş.'],
    warnings=['Flapların hareket alanında durmayın.'],
    steps=[
        'Hücum kenarı flaplarını test konumuna sürün.',
        'İki yandaki flapların aynı anda ve aynı konuma geldiğini kontrol '
        'edin.',
        'Tahrik milleri ve dişli kutularında ses ya da takılma olmamalıdır.',
        'Flapları geri alın, gücü kesin ve sonucu kayda geçirin.',
    ])

PILOT_CONTROLS = proc(
    code('27', '7', '310'), 'Pilot kumandaları', figure=16,
    conditions=[SAFE, ENGINE_OFF],
    steps=[
        'Yan kumanda kolunun tabanında gevşeklik ve hasar olup olmadığına '
        'bakın.',
        'Pedalların ayar mekanizmasının çalıştığını ve kilitlendiğini '
        'kontrol edin.',
        'Gaz kolunun tüm yolunda düzgün hareket ettiğini kontrol edin.',
        'Kumanda yollarında sıkışmış eşya olmadığını kontrol edin.',
    ])

FLCS_ISO = isolate(
    code('27', '6', '421'), 'Uçuş kumanda sistemi',
    'Kumanda uyarısı: arıza bulma', 'NAYAJET-27-001',
    'Uçuş kumanda uyarısı yanıyor ya da kumanda bilgisayarı arıza kaydı '
    'veriyor.',
    [('Kumanda bilgisayarının arıza kayıtlarını okuyun ve kendi kendini '
      'sınama testini yapın.', 'Arıza bir eyleyiciyi mi gösteriyor?',
      'Eyleyiciyi ve çevresini sızıntı açısından muayene edin; arızalıysa '
      'değiştirin.', code('27', info='920')),
     ('Hücum kenarı flaplarının konumunu iki yanda karşılaştırın.',
      'Flaplar farklı konumda mı?', 'Hücum kenarı flap tahrikini test edin.',
      code('27', '4', '320')),
     ('Hidrolik basınçları ve uyarıları kontrol edin.',
      'Hidrolik uyarısı da var mı?', 'Hidrolik basınç arızasını arayın.',
      code('29', info='421'))],
    ('Arıza tekrar etmiyor: yüzeylerin çalışma testini yapın ve uçuş '
     'kumanda personeline bildirin.', code('27', info='320')))

SPEEDBRAKE_ISO = isolate(
    code('27', '5', '421'), 'Hava frenleri', 'Hava freni arızası: arıza bulma',
    'NAYAJET-27-002',
    'Hava frenleri tam açılmıyor, tam kapanmıyor ya da iki panel farklı '
    'açılıyor.',
    [('Panelleri ve menteşeleri hasar açısından muayene edin.',
      'Panel ya da menteşe hasarlı mı?', 'Hasarı onartın.',
      code('27', '5', '310')),
     ('Eyleyiciyi ve hatlarını sızıntı açısından kontrol edin.',
      'Sızıntı var mı?', 'Eyleyiciyi değiştirin.', code('27', info='920'))],
    ('Görünür bir sorun yok: kumanda devresini uçuş kumanda personeline '
     'kontrol ettirin.', code('27', info='320')))

# Yakıt
FUEL = dm(
    code=code('28'), tech='Yakıt sistemi', figure=11,
    description=[
        ('Genel', [
            'Yakıt gövde içindeki ve kanatlardaki tanklarda, Block 60\'ta ayrıca '
            'gövdenin üstündeki konformal tanklarda taşınır.',
            'Pompalar yakıtı tanklardan motora ve tanklar arasında aktarır; '
            'valfler aktarımın sırasını ve dengesini sağlar.',
            'Yerde ikmal gövde altındaki tek nokta ikmal ağzından yapılır. '
            'Havada ikmal ağzı kanopinin arkasındadır.',
        ]),
        ('Göstergeler', [
            'Tanklardaki algılayıcılar yakıt miktarını kokpitteki göstergeye '
            'bildirir.',
        ]),
    ])

DEFUEL = proc(
    code('28', '1', '220'), 'Yakıt', info='Yakıt boşaltma', figure=11,
    tools=[('Yakıt boşaltma aracı', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Yangın söndürücü hazır.',
                'Uçak ve yakıt aracı topraklı.'],
    warnings=['Yakıt buharı yanıcıdır. Boşaltma sırasında uçağın çevresinde '
              'kıvılcım çıkaracak iş yapmayın.'],
    steps=[
        'Yakıt aracının hortumunu tek nokta ikmal ağzına takın.',
        'Boşaltma işlemini el kitabındaki sıraya göre başlatın.',
        'Kalan yakıtı tank boşaltma valflerinden onaylı kaplara alın.',
        'Hortumu sökün, kapakları kapatın ve dökülen yakıtı temizleyin.',
    ])

FUEL_PUMP_REPL = replace(
    code('28', '3', '920'), 'Yakıt pompası',
    removal=['Tankı boşaltın ve havalandırın; tank girişi gerekiyorsa '
             'kapalı alan emniyet kurallarını uygulayın.',
             'Pompanın elektrik konnektörünü ve yakıt hatlarını ayırın.',
             'Bağlantı elemanlarını sökün ve pompayı çıkarın.'],
    install=['Yeni pompayı yeni contayla yerleştirin. ' + TORQUE,
             'Hatları ve konnektörü bağlayın.', 'Tankı doldurun ve '
             'bağlantıları sızıntı açısından kontrol edin.'],
    spares=[('Yakıt pompası', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, 'Tank boşaltılmış.'],
    warnings=['Yakıt buharı yanıcı ve zehirlidir; tank içine yalnız '
              'havalandırma ve ölçüm yapıldıktan sonra girilir.'])

FUEL_LINES = proc(
    code('28', '3', '310'), 'Yakıt valfleri ve hatları',
    tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    warnings=['Yakıt cilde zararlıdır; eldiven takın.'],
    steps=[
        'Erişilebilen yakıt hatlarını ve bağlantıları ıslaklık, leke ve '
        'sürtünme açısından muayene edin.',
        'Valflerin konum göstergelerini ve elektrik konnektörlerini kontrol '
        'edin.',
        'Havalandırma çıkışlarının açık ve temiz olduğunu kontrol edin.',
        'Sızıntıyı yerini ve şiddetini belirterek kayda geçirin.',
    ])

FUEL_QTY_TEST = proc(
    code('28', '4', '320'), 'Yakıt miktar göstergesi', info='Çalışma testi',
    conditions=[SAFE, ENGINE_OFF, 'Uçağa elektrik gücü verilmiş.'],
    steps=[
        'Göstergenin test konumunu seçin ve göstergenin test değerine '
        'geldiğini kontrol edin.',
        'Gösterilen miktarı ikmal kaydındaki miktarla karşılaştırın.',
        'Fark el kitabındaki sınırın dışındaysa algılayıcı devresini kontrol '
        'ettirin.',
    ])

FUEL_QTY_ISO = isolate(
    code('28', '4', '421'), 'Yakıt miktar göstergesi',
    'Tutarsız gösterge: arıza bulma', 'NAYAJET-28-001',
    'Yakıt miktar göstergesi ikmal edilen miktarla uyuşmuyor ya da '
    'dalgalanıyor.',
    [('Göstergenin çalışma testini yapın.', 'Test değeri tutmuyor mu?',
      'Gösterge ya da devresi arızalı: göstergeyi kontrol ettirin.',
      code('28', '4', '320')),
     ('Tanklarda su olup olmadığını boşaltma valflerinden kontrol edin.',
      'Yakıtta su var mı?', 'Suyu boşaltın; su algılayıcıları yanıltır.',
      code('28', '1', '300')),
     ('Tank algılayıcılarının konnektörlerini erişilebildiği yerden kontrol '
      'edin.', 'Konnektör gevşek ya da nemli mi?',
      'Konnektörü temizleyin ve takın.', code('20', '2', '310'))],
    ('Bulgu yok: göstergeyi bir sonraki ikmalde yeniden karşılaştırın.',
     code('28', '4', '320')))

FUEL_ISO = isolate(
    code('28', info='421'), 'Yakıt sistemi',
    'Yakıt basıncı ya da aktarım arızası: arıza bulma', 'NAYAJET-28-002',
    'Yakıt basıncı uyarısı yanıyor, tanklar arasında dengesizlik oluşuyor '
    'ya da yerde ikmal yavaş ilerliyor.',
    [('Yerde görünür yakıt sızıntısı olup olmadığını kontrol edin.',
      'Sızıntı var mı?', 'Hatları ve bağlantıları muayene edin.',
      code('28', '3', '310')),
     ('Uyarının hangi tank ya da pompa için olduğunu okuyun.',
      'Uyarı bir pompayı mı gösteriyor?', 'Pompayı değiştirin.',
      code('28', '3', '920')),
     ('Valflerin konum göstergelerini kontrol edin.',
      'Bir valf yanlış konumda mı kalmış?',
      'Valfi ve hattı muayene edin.', code('28', '3', '310'))],
    ('Bulgu yok: ikmal ağzını ve havalandırmayı kontrol edin, ikmali '
     'yeniden deneyin.', code('28', '1', '210')))

RECEPTACLE = proc(
    code('28', '5', '310'), 'Havada ikmal ağzı', figure=11,
    tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    steps=[
        'Ağız kapağının gövdeye tam oturduğunu ve kapandığını kontrol edin.',
        'Ağzın çevresinde çizik, ezik ve yakıt izi olup olmadığına bakın.',
        'Ağız içindeki contayı ve kilit mekanizmasını hasar açısından '
        'muayene edin.',
        'Ağız lambasının camını kontrol edin.',
    ])

# Hidrolik
HYD = dm(
    code=code('29'), tech='Hidrolik güç',
    description=[
        ('Genel', [
            'İki bağımsız hidrolik sistem (A ve B) motorun aksesuar dişli '
            'kutusundan çalışan pompalarla basınçlanır.',
            'İki sistem birlikte kumanda yüzeylerinin eyleyicilerini besler; '
            'biri arızalanınca diğeri kumandayı sürdürür.',
            'B sistemi ayrıca iniş takımını, frenleri, burun tekerleği '
            'yönlendirmesini ve motor çalıştırıcısının akümülatörlerini '
            'besler.',
        ]),
        ('Ana bölümler', [
            'Pompalar, depolar, akümülatörler, filtreler, hatlar ve '
            'eyleyiciler.',
        ]),
    ])

HYD_PUMP_REPL = replace(
    code('29', '2', '920'), 'Hidrolik pompası', figure=14,
    removal=['Sistemin basıncını boşaltın.', 'Basınç, emme ve kaçak '
             'hatlarını ayırın; açıklıkları kapatın.', 'Pompayı '
             'destekleyerek bağlantılarını sökün ve dişli kutusundan '
             'çıkarın.'],
    install=['Pompanın tahrik milini ve contasını kontrol edin.', 'Pompayı '
             'yerine oturtun. ' + TORQUE, 'Hatları yeni contalarla '
             'bağlayın, depoyu doldurun ve sistemin havasını alın.'],
    test='Yer hidrolik gücüyle sistemi basınçlandırın, sızıntı kontrolü '
         'yapın ve sonucu kayda geçirin.',
    spares=[('Hidrolik pompası', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF, HYD_OFF])

ACCUMULATOR = proc(
    code('29', '3', '300'), 'Hidrolik akümülatörleri',
    info='Ön dolum kontrolü', tools=[('Azot servis seti', 1)],
    supplies=[('Azot', None)],
    conditions=[SAFE, ENGINE_OFF, HYD_OFF],
    warnings=['Akümülatörde basınçlı azot vardır; dolum valfini yalnız '
              'uygun servis setiyle açın.'],
    steps=[
        'Hidrolik basıncın sıfır olduğunu kontrol edin.',
        'Akümülatörün ön dolum göstergesini okuyun. ' + NO_VALUES,
        'Ön dolum düşükse servis setiyle azot tamamlayın.',
        'Dolum valfinin kapağını takın ve sızıntı kontrolü yapın.',
    ])

HYD_FILTER = proc(
    code('29', '1', '921'), 'Hidrolik filtre elemanı',
    info='Yenisiyle değiştirme',
    spares=[('Hidrolik filtre elemanı', 1)],
    conditions=[SAFE, ENGINE_OFF, HYD_OFF],
    warnings=['Hidrolik sıvısı göze ve cilde zararlıdır.'],
    steps=[
        'Filtre gövdesinin altına toplama kabı koyun.',
        'Filtre kabını sökün ve eski elemanı çıkarın.',
        'Kabın içini temizleyin; elemanda metal parçacık varsa kayda '
        'geçirin.',
        'Yeni elemanı ve contayı takın, kabı sıkın ve emniyetleyin.',
        'Tıkanma göstergesini sıfırlayın; sistemi basınçlandırıp sızıntı '
        'kontrolü yapın.',
    ])

HYD_LINES = proc(
    code('29', '1', '310'), 'Hidrolik hatları', tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, HYD_OFF],
    steps=[
        'Hatları, esnek hortumları ve bağlantıları sızıntı, sürtünme ve '
        'ezilme açısından muayene edin.',
        'Hortumlarda çatlak, şişme ve dış örgü hasarı arayın.',
        'Filtrelerin tıkanma göstergelerine bakın.',
        'Sızıntının yerini ve şiddetini kayda geçirin.',
    ], next=code('29', '1', '921'))

# İniş takımı
RETRACT = proc(
    code('32', '3', '310'), 'Açma-kapama eyleyicileri ve kilitler',
    figure=3, tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, HYD_OFF],
    warnings=['İniş takımı emniyet pimleri takılı olmadan yuvaya '
              'girmeyin.'],
    steps=[
        'Açma-kapama eyleyicilerini ve hatlarını sızıntı açısından muayene '
        'edin.',
        'Aşağı ve yukarı kilitleri, yaylarını ve algılayıcılarını kontrol '
        'edin.',
        'Yer/hava (ağırlık) algılayıcılarının bağlantılarını kontrol edin.',
        'Mafsalları el kitabındaki yağlama noktalarından yağlayın.',
    ])

GEAR_SWING = proc(
    code('32', '3', '320'), 'İniş takımı', info='Açma-kapama testi',
    figure=3, tools=[('Uçak krikosu', 3), ('Yer hidrolik ünitesi', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Uçak krikoda, tekerlekler yerden '
                'kesilmiş.', 'İniş takımı emniyet pimleri test için '
                'çıkarılmış; gözcüler yerinde.'],
    warnings=['İniş takımının ve kapakların hareket alanında kimse '
              'olmamalıdır.'],
    steps=[
        'Yer hidrolik ünitesini bağlayın ve sistemi basınçlandırın.',
        'İniş takımını kaldırın; kapakların ve takımın sırayla kapandığını, '
        'kilitlendiğini ve konum ışıklarını izleyin.',
        'İniş takımını indirin; aşağı kilitlerin oturduğunu ve konum '
        'ışıklarının yandığını kontrol edin.',
        'Acil indirme sistemini el kitabına göre deneyin.',
        'Emniyet pimlerini takın, basıncı boşaltın ve uçağı indirin.',
    ],
    next=code('07', '1', '200'))

GEAR_IND_ISO = isolate(
    code('32', '3', '421'), 'İniş takımı',
    'Konum göstergesi arızası: arıza bulma', 'NAYAJET-32-002',
    'İniş takımı konum ışıklarından biri yanmıyor, geç yanıyor ya da '
    'takım ve kapaklar tam kapanmıyor.',
    [('Gösterge lambalarının testini yapın.', 'Lamba yanmıyor mu?',
      'Lambayı değiştirin.', code('33', '4', '920')),
     ('İlgili takımın kilit algılayıcısını ve bağlantısını kontrol edin.',
      'Algılayıcı gevşek ya da konnektör hasarlı mı?',
      'Algılayıcıyı ve kilidi muayene edin.', code('32', '3', '310')),
     ('İniş takımı kapağının ayarını ve menteşelerini kontrol edin.',
      'Kapak takımın yolunu kesiyor mu?', 'Kapağı ayarlayın.',
      code('52', '3', '271'))],
    ('Bulgu yok: uçağı krikoya alıp açma-kapama testini yapın.',
     code('32', '3', '320')))

STEERING = proc(
    code('32', '6', '310'), 'Burun tekerleği yönlendirme', figure=10,
    conditions=[SAFE, ENGINE_OFF, HYD_OFF],
    steps=[
        'Yönlendirme eyleyicisini ve hatlarını sızıntı açısından muayene '
        'edin.',
        'Yönlendirme mekanizmasında boşluk ve aşınma olup olmadığına bakın.',
        'Titreşim sönümleyicinin bağlantılarını kontrol edin.',
        'Elektrik bağlantılarını kontrol edin.',
    ])

STEERING_ISO = isolate(
    code('32', '6', '421'), 'Burun tekerleği yönlendirme',
    'Yönlendirme arızası: arıza bulma', 'NAYAJET-32-003',
    'Burun tekerleği yönlendirmesi devreye girmiyor, uçak taksi sırasında '
    'bir yana çekiyor ya da burun tekerleği titriyor.',
    [('Yönlendirme eyleyicisini sızıntı açısından kontrol edin.',
      'Sızıntı var mı?', 'Mekanizmayı muayene edin ve eyleyiciyi onartın.',
      code('32', '6', '310')),
     ('Burun dikmesinin tork kolunu ve titreşim sönümleyiciyi kontrol edin.',
      'Boşluk var mı?', 'Burun iniş takımını muayene edin.',
      code('32', '2', '310')),
     ('Ağırlık algılayıcısının bağlantısını kontrol edin.',
      'Algılayıcı uçağı havada mı görüyor?',
      'Algılayıcıyı ve kilitleri muayene edin.', code('32', '3', '310'))],
    ('Bulgu yok: yönlendirme devresini iniş takımı personeline kontrol '
     'ettirin.', code('32', '6', '310')))

STRUT_SERVICE = proc(
    code('32', '1', '210'), 'Amortisör dikmeleri', info='Azot ve yağ servisi',
    figure=3, tools=[('Azot servis seti', 1)],
    supplies=[('Azot', None), ('Hidrolik sıvısı', None)],
    conditions=[SAFE, ENGINE_OFF, 'Uçağın yükü el kitabındaki servis '
                'koşuluna uygun.'],
    warnings=['Dikmede basınçlı azot vardır; dolum valfini yalnız servis '
              'setiyle açın. Dikmenin altında ya da yanında eğilerek '
              'durmayın.'],
    steps=[
        'Dikmenin açık krom uzunluğunu ölçün ve el kitabındaki çizelgeyle '
        'karşılaştırın. ' + NO_VALUES,
        'Gerekiyorsa önce yağ seviyesini el kitabındaki yönteme göre '
        'kontrol edin ve tamamlayın.',
        'Azotu servis setiyle tamamlayın.',
        'Dolum valfinin kapağını takın; dikmeyi sızıntı açısından kontrol '
        'edin.',
    ])

BRAKE_REPL = replace(
    code('32', '4', '920', disassy='01'), 'Tekerlek freni', figure=3,
    removal=['Tekerleği sökün.', 'Fren hattını ayırın ve kapatın.',
             'Fren bağlantı elemanlarını sökün ve freni akstan çekin.'],
    install=['Aksı ve fren bağlantı yüzeylerini temizleyip kontrol edin.',
             'Yeni freni yerleştirin. ' + TORQUE, 'Fren hattını bağlayın '
             've frenin havasını alın.', 'Tekerleği takın.'],
    test='Park frenini uygulayıp bırakarak freni deneyin; aşınma piminin '
         'konumunu kayda geçirin.',
    spares=[('Tekerlek freni', 1)],
    conditions=[SAFE, ENGINE_OFF, HYD_OFF, 'Frenler ve tekerlek soğuk.'],
    warnings=[HOT])

ANTISKID_TEST = proc(
    code('32', '4', '320'), 'Kilitlenme önleyici (anti-skid) sistem',
    info='Çalışma testi', figure=3,
    conditions=[SAFE, ENGINE_OFF, 'Uçağa elektrik ve yer hidrolik gücü '
                'verilmiş.'],
    steps=[
        'Anti-skid test anahtarını kullanarak sistem testini başlatın.',
        'Uyarı ışığının test sırasında yanıp söndüğünü kontrol edin.',
        'Tekerlek hız algılayıcılarının konnektörlerini kontrol edin.',
        'Sonucu kayda geçirin.',
    ])

ANTISKID_ISO = isolate(
    code('32', '4', '421'), 'Kilitlenme önleyici (anti-skid) sistem',
    'Anti-skid uyarısı: arıza bulma', 'NAYAJET-32-004',
    'Anti-skid uyarısı yanıyor ya da frenleme sırasında tekerlek kilitleniyor.',
    [('Tekerlek hız algılayıcısının konnektörünü ve kablosunu kontrol edin.',
      'Kablo ya da konnektör hasarlı mı?', 'Kabloyu onarın.',
      code('24', '6', '310')),
     ('Sistem testini yapın.', 'Test geçmiyor mu?',
      'Anti-skid kontrol ünitesini değiştirtin ve testi yineleyin.',
      code('32', '4', '320'))],
    ('Bulgu yok: frenleri ve lastikleri muayene edin.',
     code('32', '4', '310')))

# Işıklar
LIGHTS = dm(
    code=code('33'), tech='Işıklar', figure=9,
    description=[
        ('Dış aydınlatma', [
            'Kanat uçlarında seyir lambaları vardır: sol kanatta kırmızı, sağ '
            'kanatta yeşil. Dikey kuyruğun ucunda beyaz lamba vardır.',
            'İniş ve taksi lambaları burun iniş takımındadır; takım '
            'indirildiğinde kullanılır.',
            'Gövde ve kuyruktaki formasyon lambaları gece kol uçuşunda '
            'uçakların birbirini görmesini sağlar.',
        ]),
        ('Kokpit aydınlatması', [
            'Gösterge panelleri, konsollar ve taşkın aydınlatması kokpitten '
            'ayarlanır.',
        ]),
    ])

LIGHTS_TEST = proc(
    code('33', '4', '320'), 'Dış lambalar', info='Çalışma testi', figure=9,
    conditions=[SAFE, ENGINE_OFF, 'Uçağa elektrik gücü verilmiş.'],
    warnings=['İniş lambasına yakından bakmayın; ışık göze zarar verir.'],
    steps=[
        'Seyir lambalarını açın; sol kanat ucunda kırmızı, sağda yeşil, '
        'kuyrukta beyaz ışığı kontrol edin.',
        'Çarpışma önleyici lambanın yanıp söndüğünü kontrol edin.',
        'Formasyon lambalarının parlaklık ayarının çalıştığını kontrol edin.',
        'İniş ve taksi lambalarını kısa süre yakın.',
        'Lambaları kapatın; yanmayan lambayı kayda geçirin.',
    ])

LAMP_REPL = replace(
    code('33', '4', '920'), 'Lamba', figure=9,
    removal=['Lamba camının vidalarını sökün ve camı çıkarın.',
             'Arızalı lambayı ya da LED ünitesini çıkarın.'],
    install=['Yuvayı ve kontakları temizleyin.', 'Yeni lambayı takın.',
             'Camı yeni contasıyla takın ve vidaları sıkın.'],
    test='Dış lambalar çalışma testini yapın.',
    spares=[('Lamba ünitesi', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    cautions=['Lambanın camına çıplak elle dokunmayın.'])

LIGHT_ISO = isolate(
    code('33', '4', '421'), 'Dış lambalar', 'Lamba yanmıyor: arıza bulma',
    'NAYAJET-33-001',
    'Seyir, çarpışma önleyici, iniş ya da taksi lambalarından biri '
    'yanmıyor.',
    [('Lambanın devre kesicisini kontrol edin.', 'Devre kesici atmış mı?',
      'Devre kesiciyi kurun; yeniden atarsa kabloyu kontrol edin.',
      code('24', '6', '310')),
     ('Lamba camını sökün ve lambayı kontrol edin.',
      'Lamba yanmış ya da camın içi nemli mi?', 'Lambayı değiştirin.',
      code('33', '4', '920'))],
    ('Lamba sağlam: lamba konnektörünü ve kabloyu kontrol edin.',
     code('20', '2', '310')))

COCKPIT_LIGHTS = proc(
    code('33', '1', '320'), 'Kokpit aydınlatması', info='Çalışma testi',
    figure=16,
    conditions=[SAFE, ENGINE_OFF, 'Uçağa elektrik gücü verilmiş.'],
    steps=[
        'Panel ve konsol aydınlatmasını açın ve parlaklık ayarını '
        'deneyin.',
        'Uyarı ışıklarının testini yapın.',
        'Taşkın aydınlatmasını kontrol edin.',
        'Yanmayan ışıkları kayda geçirin ve lambalarını değiştirin.',
    ])

# Hava verileri
PITOT = proc(
    code('34', '1', '310'), 'Pitot tüpü ve statik portlar', figure=12,
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    warnings=['Pitot tüpü ısıtıcısı çalışırken çok sıcaktır; güç kesildikten '
              'sonra soğumasını bekleyin.'],
    cautions=['Pitot ve statik deliklere üflemeyin, tel sokmayın.'],
    steps=[
        'Pitot tüpü kılıfını çıkarın.',
        'Tüpte eğilme, ezik ve tıkanma olup olmadığına bakın.',
        'Statik portların temiz ve açık olduğunu, çevresinde boya ya da '
        'çizik olmadığını kontrol edin.',
        'Hücum açısı algılayıcılarının serbest döndüğünü ve hasarsız olduğunu '
        'kontrol edin.',
    ], next=code('34', '1', '920'))

PITOT_HEAT = proc(
    code('34', '1', '320'), 'Pitot ısıtıcısı', info='Çalışma testi',
    figure=12,
    conditions=[SAFE, ENGINE_OFF, 'Uçağa elektrik gücü verilmiş.'],
    warnings=['Isıtılmış tüpe çıplak elle dokunmayın.'],
    steps=[
        'Pitot ısıtma anahtarını açın.',
        'El kitabındaki süre sonunda tüpün ısındığını elin tersini yakın '
        'tutarak kontrol edin.',
        'Anahtarı kapatın ve sonucu kayda geçirin.',
    ])

PITOT_REPL = replace(
    code('34', '1', '920'), 'Hava verileri algılayıcısı', figure=12,
    removal=['Algılayıcının bağlantı vidalarını sökün.',
             'Hatları ve elektrik konnektörünü ayırın; hat uçlarını kapatın.'],
    install=['Yeni algılayıcıyı contasıyla yerleştirin. ' + TORQUE,
             'Hatları ve konnektörü bağlayın.'],
    test='Pitot-statik sızıntı testini yetkili personele yaptırın; ısıtıcı '
         'çalışma testini yapın.',
    spares=[('Pitot tüpü', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF])

AIRDATA_ISO = isolate(
    code('34', '1', '421'), 'Pitot-statik sistemi',
    'Hız ya da irtifa göstergesi tutarsız: arıza bulma', 'NAYAJET-34-001',
    'Yerde ya da kalkışta hız veya irtifa göstergesi tutarsız; pitot ısıtma '
    'uyarısı yanıyor.',
    [('Pitot tüpünü ve statik portları muayene edin.',
      'Tıkanma, kılıf ya da hasar var mı?', 'Tıkanmayı giderin; hasarlı '
      'algılayıcıyı değiştirin.', code('34', '1', '310')),
     ('Pitot ısıtıcısının çalışma testini yapın.', 'Tüp ısınmıyor mu?',
      'Pitot tüpünü değiştirin.', code('34', '1', '920'))],
    ('Bulgu yok: pitot-statik sızıntı testini yetkili personele yaptırın.',
     code('34', '1', '310')))

# Oksijen
OXYGEN = dm(
    code=code('35'), tech='Oksijen',
    description=[
        ('Genel', [
            'Uçakta motor havasından oksijen ayıran bir oksijen üretim '
            'sistemi vardır; ayrı bir sıvı oksijen deposu gerekmez.',
            'Her koltukta regülatör ve maske hortumu, ayrıca acil durum için '
            'koltuğa bağlı küçük bir oksijen tüpü bulunur.',
        ]),
    ])

OXYGEN_CHECK = proc(
    code('35', '2', '310'), 'Oksijen regülatörü ve hortumlar', figure=16,
    conditions=[SAFE, ENGINE_OFF],
    warnings=['Oksijen bağlantılarının yakınında yağ ve gres kullanmayın; '
              'yangına yol açar.'],
    steps=[
        'Maske hortumlarında çatlak, kesik ve bükülme olup olmadığına bakın.',
        'Bağlantı ağızlarının temiz ve kilitlerinin çalışır olduğunu kontrol '
        'edin.',
        'Regülatörün anahtarlarını ve göstergesini kontrol edin.',
    ])

OXYGEN_EMERGENCY = proc(
    code('35', '2', '300'), 'Acil oksijen tüpü', info='Kontrol', figure=16,
    conditions=[SAFE, ENGINE_OFF],
    warnings=['Koltuk emniyet pimleri takılı olmadan kokpite girmeyin.'],
    steps=[
        'Koltuktaki acil oksijen tüpünün göstergesini okuyun.',
        'Gösterge düşük bölgedeyse tüpü koltuk personeline değiştirtin.',
        'Tetik kablosunun ve emniyetinin yerinde olduğunu kontrol edin.',
    ])

OBOGS_REPL = replace(
    code('35', '1', '920'), 'Oksijen üretim ünitesi',
    removal=['Erişim panelini açın.', 'Hava ve oksijen hatlarını, elektrik '
             'konnektörünü ayırın; açıklıkları kapatın.',
             'Üniteyi bağlantılarından sökün.'],
    install=['Yeni üniteyi yerleştirin. ' + TORQUE, 'Hatları temiz, yağsız '
             'ellerle ve yeni contalarla bağlayın; konnektörü takın.'],
    spares=[('Oksijen üretim ünitesi', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    warnings=['Oksijen bağlantılarının yakınında yağ ve gres '
              'kullanmayın.'])

OXYGEN_ISO = isolate(
    code('35', info='421'), 'Oksijen sistemi',
    'Oksijen uyarısı: arıza bulma', 'NAYAJET-35-001',
    'Oksijen uyarısı yanıyor ya da maskeye akış zayıf.',
    [('Maske hortumunu ve bağlantı ağzını kontrol edin.',
      'Hortum hasarlı ya da bağlantı gevşek mi?',
      'Hortumu ve bağlantıyı muayene edin.', code('35', '2', '310')),
     ('Oksijen üretim ünitesinin hava girişini ve arıza göstergesini '
      'kontrol edin.', 'Ünite arıza gösteriyor mu?',
      'Üniteyi değiştirin.', code('35', '1', '920'))],
    ('Bulgu yok: acil oksijen tüpünü kontrol edin ve uyarıyı izleyin.',
     code('35', '2', '300')))

# Pnömatik
BLEED = proc(
    code('36', '1', '310'), 'Hava alma kanalları', tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Motor soğumuş.'],
    warnings=[HOT],
    steps=[
        'Motordan alınan sıcak hava kanallarını ve kelepçeleri muayene edin.',
        'Kanal çevresindeki yapıda ve kablolarda ısı izi arayın.',
        'Aşırı ısı algılayıcılarının bağlantılarını kontrol edin.',
        'Hava alma valflerinin konnektörlerini kontrol edin.',
    ])

BLEED_ISO = isolate(
    code('36', '1', '421'), 'Hava alma sistemi',
    'Kanal aşırı ısı uyarısı: arıza bulma', 'NAYAJET-36-001',
    'Hava alma kanalı aşırı ısı uyarısı yanıyor ya da kokpite sıcak hava '
    'gelmiyor.',
    [('Kanalları ve kelepçeleri sızıntı ve ısı izi açısından kontrol edin.',
      'Kanal çatlak ya da kelepçe gevşek mi?', 'Kanalı onartın.',
      code('36', '1', '310')),
     ('Klima ünitesinin girişini kontrol edin.', 'Giriş tıkalı mı?',
      'Klima ünitesini muayene edin.', code('21', '1', '310'))],
    ('Bulgu yok: aşırı ısı algılayıcısını ve uyarı devresini kontrol edin.',
     code('26', '1', '421')))

# Motor çalıştırma ünitesi
JFS = dm(
    code=code('49'), tech='Motor çalıştırma ünitesi', figure=14,
    description=[
        ('Genel', [
            'Jet yakıtlı çalıştırıcı (JFS) küçük bir gaz türbinidir. Motoru '
            'aksesuar dişli kutusu üzerinden döndürerek çalıştırır.',
            'JFS hidrolik akümülatörlerle ya da aküyle çalıştırılır; '
            'akümülatörler B hidrolik sisteminden dolar.',
        ]),
    ])

JFS_CHECK = proc(
    code('49', '1', '310'), 'Jet yakıtlı çalıştırıcı', figure=14,
    tools=[('El feneri', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Çalıştırıcı soğumuş.'],
    warnings=['Çalıştırıcının egzoz çıkışı çalıştıktan sonra sıcaktır.'],
    steps=[
        'Çalıştırıcının hava girişinde ve egzoz çıkışında yabancı cisim '
        'olup olmadığına bakın.',
        'Yakıt ve hidrolik hatlarını sızıntı açısından kontrol edin.',
        'Akümülatörlerin basınç göstergelerini okuyun.',
        'Çalıştırıcının bağlantılarını ve konnektörlerini kontrol edin.',
    ])

JFS_ACC = proc(
    code('49', '1', '210'), 'Çalıştırma akümülatörleri', info='Doldurma',
    figure=14, tools=[('El pompası', 1)],
    conditions=[SAFE, ENGINE_OFF],
    warnings=['Akümülatörler yüksek basınçlıdır; dolum sırasında hat '
              'bağlantılarının önünde durmayın.'],
    steps=[
        'Akümülatör basınç göstergelerini okuyun.',
        'Basınç düşükse el pompasıyla ya da yer hidrolik ünitesiyle el '
        'kitabındaki değere doldurun. ' + NO_VALUES,
        'Ön dolum azotunu ayrıca kontrol edin.',
        'Pompayı kapatın ve göstergelerin sabit kaldığını kontrol edin.',
    ])

JFS_ISO = isolate(
    code('49', '1', '421'), 'Jet yakıtlı çalıştırıcı',
    'Çalıştırıcı çalışmıyor: arıza bulma', 'NAYAJET-49-001',
    'Çalıştırıcı devreye girmiyor ya da motoru döndüremeden duruyor.',
    [('Akümülatör basınçlarını okuyun.', 'Basınç düşük mü?',
      'Akümülatörleri doldurun.', code('49', '1', '210')),
     ('Akü gerilimini kontrol edin.', 'Akü zayıf mı?', 'Aküyü kontrol '
      'edin.', code('24', '3', '300')),
     ('Çalıştırıcının yakıt beslemesini ve hatlarını kontrol edin.',
      'Sızıntı ya da yakıt kesik mi?', 'Hatları onartın.',
      code('49', '1', '310'))],
    ('Bulgu yok: çalıştırıcıyı motor personeline muayene ettirin.',
     code('49', '1', '310')))

# Kapaklar
ACCESS_DOORS = proc(
    code('52', '1', '310'), 'Erişim kapakları', figure=1,
    conditions=[SAFE, ENGINE_OFF],
    steps=[
        'Kapakların gövdeye düz oturduğunu ve kilitlerinin kapalı olduğunu '
        'kontrol edin.',
        'Hızlı açılır kilitlerde ve vidalarda eksik ya da gevşek eleman '
        'arayın.',
        'Kapak contalarını ve menteşelerini kontrol edin.',
        'Eksik bağlantı elemanını aynı parça numarasıyla tamamlayın.',
    ])

GEAR_DOORS = proc(
    code('52', '3', '310'), 'İniş takımı kapakları', figure=3,
    conditions=[SAFE, ENGINE_OFF, HYD_OFF],
    warnings=['Hidrolik basınç verilmişken kapakların hareket alanında '
              'durmayın.'],
    steps=[
        'Kapakları ezik, çatlak ve kenar hasarı açısından muayene edin.',
        'Menteşeleri, bağlantı çubuklarını ve kilitleri kontrol edin.',
        'Kapak contalarını kontrol edin.',
    ])

GEAR_DOOR_ADJ = proc(
    code('52', '3', '271'), 'İniş takımı kapağı', info='Ayar', figure=3,
    tools=[('Uçak krikosu', 3)],
    conditions=[SAFE, ENGINE_OFF, 'Uçak krikoda.'],
    warnings=['Kapakların hareket alanında kimse olmamalıdır.'],
    steps=[
        'Kapağı yavaşça kapalı konuma getirin ve gövdeyle arasındaki '
        'boşluğu kontrol edin.',
        'Bağlantı çubuğunun uzunluğunu el kitabındaki yönteme göre ayarlayın.',
        'Kilit somununu sıkın ve emniyetleyin.',
        'Açma-kapama testinde kapağın takıma sürtünmediğini kontrol edin.',
    ],
    next=code('32', '3', '320'))

# Gövde
STRUCTURE = proc(
    code('53', '1', '310'), 'Gövde yapısı', figure=1,
    tools=[('El feneri', 1), ('Büyüteç', 1)],
    conditions=[SAFE, ENGINE_OFF],
    steps=[
        'Gövde kaplamasında ezik, çatlak ve buruşma olup olmadığına bakın.',
        'Perçin başlarının çevresinde siyah iz (gevşek perçin belirtisi) '
        'arayın.',
        'Gövde ile kanat, kuyruk ve konformal tank birleşim hatlarını '
        'kontrol edin.',
        'Korozyon izi bulursanız korozyon kontrolü yapın.',
    ],
    next=code('20', '4', '250'))

VENTRAL = proc(
    code('53', '1', '310', disassy='01'), 'Alt kuyruk kanatçıkları',
    figure=13, conditions=[SAFE, ENGINE_OFF],
    steps=[
        'Gövdenin arkasındaki iki alt kanatçığı ezik, çatlak ve yer teması '
        'izi açısından muayene edin.',
        'Bağlantı elemanlarını ve gövdeyle birleşimi kontrol edin.',
    ])

RADOME_REPL = replace(
    code('53', '2', '920'), 'Radom', figure=12,
    removal=['Radom kilitlerini açın.', 'Radomu iki kişiyle destekleyerek '
             'menteşesinden ayırın ve yumuşak bir altlığa koyun.'],
    install=['Conta ve yıldırım koruma şeritlerini kontrol edin.',
             'Radomu menteşesine takın, kapatın ve kilitleri kapatın.'],
    test='Radomun gövdeyle aynı hizada oturduğunu ve kilitlerin kapalı '
         'olduğunu kontrol edin.',
    spares=[('Radom', 1)],
    conditions=[SAFE, ENGINE_OFF, POWER_OFF],
    cautions=['Radom kompozittir; darbe ve çizikten koruyun, üzerine '
              'basmayın.'])

# Kanopi
CANOPY_SEAL = replace(
    code('56', '1', '920'), 'Kanopi contası', figure=5,
    removal=['Kanopiyi açın ve emniyet desteğini takın.',
             'Conta şişirme hattını ayırın.', 'Eski contayı yuvasından '
             'dikkatle çekin.'],
    install=['Yuvayı temizleyin ve kontrol edin.', 'Yeni contayı yuvaya '
             'bükmeden yerleştirin.', 'Şişirme hattını bağlayın.'],
    test='Kokpit basınçlandırma çalışma testini yapın.',
    spares=[('Kanopi contası', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Kanopi ve koltuk emniyet pimleri takılı.'],
    warnings=['Kanopi açma ve atma sistemi patlayıcı eleman içerir.'])

CANOPY_ISO = isolate(
    code('56', '1', '421'), 'Kanopi', 'Kokpit basınçlanmıyor: arıza bulma',
    'NAYAJET-56-001',
    'Kokpit basınçlanmıyor, kanopiden ıslık sesi geliyor ya da kanopi '
    'kilit uyarısı yanıyor.',
    [('Kanopi contasını yırtık ve sertleşme açısından kontrol edin.',
      'Conta hasarlı mı?', 'Contayı değiştirin.', code('56', '1', '920')),
     ('Kanopi kilit pimlerini ve algılayıcısını kontrol edin.',
      'Kilit tam oturmuyor mu?', 'Kanopiyi muayene edin.',
      code('56', '1', '310'))],
    ('Bulgu yok: basınçlandırma testini yaparak sızıntı noktasını bulun.',
     code('21', '3', '320')))

# Kanatlar
DISCHARGERS = proc(
    code('57', '1', '310'), 'Statik boşaltıcılar', figure=4,
    conditions=[SAFE, ENGINE_OFF],
    steps=[
        'Kanat, yatay kuyruk ve dikey kuyruk firar kenarlarındaki statik '
        'boşaltıcıları sayın.',
        'Kırık, eğik ya da eksik boşaltıcıyı kayda geçirin.',
        'Tabanlarının sıkı ve korozyonsuz olduğunu kontrol edin.',
        'Eksik boşaltıcıyı aynı parça numarasıyla değiştirin.',
    ])

# Motor: genel işler
ENGINE_COND = [SAFE, ENGINE_OFF, POWER_OFF, 'Motor soğumuş.',
               'İş sertifikalı motor personelince yapılır.']

ENGINE_REMOVE = proc(
    code('72', info='520'), 'Motor', info='Sökme (genel)', figure=2,
    tools=[('Motor taşıma arabası', 1), ('Motor sökme takımı', 1)],
    conditions=ENGINE_COND + ['Yakıt sistemi boşaltılmış ya da motor '
                              'girişleri kapatılmış.'],
    warnings=['Motor ağırdır; yalnız onaylı taşıma arabası ve kaldırma '
              'ekipmanıyla taşıyın.'],
    steps=[
        'Gövdenin arka bölümünü motor sökme için el kitabına göre ayırın ya '
        'da erişim kapaklarını açın.',
        'Yakıt, hidrolik, hava ve elektrik bağlantılarını ayırın; her '
        'açıklığı kapatın ve etiketleyin.',
        'Motor kumanda bağlantılarını ayırın.',
        'Taşıma arabasını motorun altına yerleştirin ve motoru destekleyin.',
        'Motor bağlantılarını sökün ve motoru raylar üzerinden dikkatle '
        'çekin.',
    ],
    next=code('72', info='720'))

ENGINE_INSTALL = proc(
    code('72', info='720'), 'Motor', info='Takma (genel)', figure=2,
    tools=[('Motor taşıma arabası', 1), ('Motor sökme takımı', 1)],
    conditions=ENGINE_COND,
    warnings=['Motor ağırdır; yalnız onaylı taşıma arabası ve kaldırma '
              'ekipmanıyla taşıyın.'],
    steps=[
        'Motor bölmesini yabancı cisim için kontrol edin.',
        'Motoru raylar üzerinden yerine sürün ve bağlantılarını takın. '
        + TORQUE,
        'Yakıt, hidrolik, hava ve elektrik bağlantılarını yeni contalarla '
        'yapın; etiketleri ve kapakları çıkarın.',
        'Motor kumanda bağlantılarını takın ve ayarlarını kontrol ettirin.',
        'Yağ ve hidrolik seviyelerini tamamlayın; sızıntı kontrolü ve yer '
        'çalıştırmasını el kitabına göre yaptırın.',
    ])

ENGINE_MOUNTS = proc(
    code('72', info='310'), 'Motor bağlantıları', figure=2,
    tools=[('El feneri', 1)],
    conditions=ENGINE_COND,
    steps=[
        'Ön ve arka motor bağlantılarını çatlak, aşınma ve gevşeklik '
        'açısından muayene edin.',
        'Bağlantı pimlerinin emniyetlerini kontrol edin.',
        'Bağlantı çevresindeki yapıda çatlak ya da sürtünme izi arayın.',
    ])

ENGINE_WASH = proc(
    code('72', '1', '250'), 'Kompresör', info='Kompresör yıkama', figure=8,
    tools=[('Motor yıkama arabası', 1)],
    supplies=[('Motor yıkama sıvısı', None)],
    conditions=[SAFE, ENGINE_OFF, 'Motor soğumuş.',
                'Yıkama sırasında motor yalnız çalıştırıcıyla döndürülür; '
                'ateşleme kapalı.'],
    warnings=[INTAKE],
    steps=[
        'Hava alığını ve fan yüzünü kontrol edin.',
        'Yıkama arabasının püskürtme ağzını hava alığına yerleştirin.',
        'Motoru çalıştırıcıyla döndürürken yıkama sıvısını püskürtün; sonra '
        'temiz suyla durulayın.',
        'Motoru kurutma için el kitabındaki süre boyunca döndürün.',
        'Ekipmanı çıkarın ve alet sayımı yapın.',
    ])

VSV = proc(
    code('72', '1', '300'), 'Değişken stator kanatları',
    info='Bağlantı ve eyleyici kontrolü', figure=6,
    tools=[('El feneri', 1)],
    conditions=ENGINE_COND,
    steps=[
        'Değişken stator kanatlarının bağlantı halkasını ve kollarını '
        'aşınma ve boşluk açısından muayene edin.',
        'Eyleyicileri ve hatlarını sızıntı açısından kontrol edin.',
        'Kanatların konumunun el kitabına uygun olduğunu motor personeline '
        'ölçtürün.',
    ])

GEARBOX = proc(
    code('72', '6', '310'), 'Aksesuar dişli kutusu', figure=14,
    tools=[('El feneri', 1)],
    conditions=ENGINE_COND,
    steps=[
        'Dişli kutusu gövdesini çatlak ve yağ sızıntısı açısından muayene '
        'edin.',
        'Jeneratör, hidrolik pompaları, yakıt pompası ve çalıştırıcı '
        'bağlantılarını kontrol edin.',
        'Talaş algılayıcıyı çıkarıp kontrol edin.',
        'Tahrik mili contalarında kaçak olup olmadığına bakın.',
    ],
    next=code('79', '1', '310'))

NOZZLE_TEST = proc(
    code('72', '5', '320'), 'Lüle eyleyicileri', info='Çalışma testi',
    figure=15,
    conditions=[SAFE, ENGINE_OFF, 'Yer hidrolik ve elektrik gücü verilmiş.',
                'Lülenin çevresi boş.'],
    warnings=['Lüle yaprakları hareket ederken parmaklarınızı aralarına '
              'sokmayın.'],
    steps=[
        'Lüleyi test konumlarına sürün; yaprakların birlikte ve düzgün '
        'hareket ettiğini izleyin.',
        'Eyleyicilerde ve hatlarda sızıntı olup olmadığına bakın.',
        'Konum göstergesinin lülenin konumuyla uyduğunu kontrol edin.',
        'Lüleyi kapalı konuma alın, gücü kesin ve sonucu kayda geçirin.',
    ])

NOZZLE_FLAP_REPL = replace(
    code('72', '5', '920'), 'Lüle yaprağı', figure=15,
    removal=['Yaprağın bağlantı pimlerinin emniyetini sökün.',
             'Pimleri çıkarın ve yaprağı ayırın.'],
    install=['Yuvayı ve komşu yaprakları kontrol edin.',
             'Yeni yaprağı yerleştirin, pimleri takın ve emniyetleyin.'],
    test='Lüle eyleyicileri çalışma testini yapın.',
    spares=[('Lüle yaprağı', 1)],
    conditions=ENGINE_COND, warnings=[HOT])

AB_ISO = isolate(
    code('72', '5', '421'), 'Art yakıcı',
    'Art yakıcı devreye girmiyor: arıza bulma', 'NAYAJET-72-005',
    'Art yakıcı devreye girmiyor, tutuşup sönüyor ya da lüle konum uyarısı '
    'yanıyor.',
    [('Lüle eyleyicilerinin çalışma testini yapın.',
      'Lüle doğru açılıp kapanmıyor mu?', 'Eyleyicileri onartın ve testi '
      'yineleyin.', code('72', '5', '320')),
     ('Art yakıcı yakıt hatlarını ve püskürtücülerini muayene edin.',
      'Sızıntı ya da tıkanma var mı?', 'Art yakıcı yakıt sistemini '
      'onartın.', code('73', '2', '310')),
     ('Alev tutucuyu ve astarı lüleden muayene edin.',
      'Yanık ya da çatlak var mı?', 'Art yakıcıyı muayene edin.',
      code('72', '5', '310'))],
    ('Bulgu yok: art yakıcı ateşleme devresini motor personeline kontrol '
     'ettirin.', code('74', '1', '320')))

ENGINE_VIB_ISO = isolate(
    code('72', info='421', disassy='01'), 'Motor',
    'Titreşim yüksek: arıza bulma', 'NAYAJET-72-002',
    'Motor titreşim göstergesi yüksek ya da pilot gövdede titreşim '
    'bildiriyor.',
    [('Fan kanatlarını hasar açısından muayene edin.',
      'Kanatta çentik, eğilme ya da kopma var mı?', 'Yabancı cisim yutma '
      'sonrası muayeneyi yapın; hasar sınır dışındaysa motoru çalıştırmayın.',
      code('05', '2', '300', disassy='03')),
     ('Talaş algılayıcıyı ve yağ filtresini kontrol edin.',
      'Metal parçacık var mı?', 'Yatak hasarı olabilir: talaş algılayıcı '
      'muayenesi ve yağ analiziyle doğrulayın; doğrulanırsa motoru sökün.',
      code('72', info='520')),
     ('Motor bağlantılarını kontrol edin.', 'Bağlantıda boşluk ya da '
      'çatlak var mı?', 'Bağlantıları muayene edin.',
      code('72', info='310'))],
    ('Bulgu yok: titreşim algılayıcısını ve göstergesini kontrol edin.',
     code('77', '1', '310')))

ENGINE_EGT_ISO = isolate(
    code('72', info='421', disassy='02'), 'Motor',
    'Egzoz sıcaklığı yüksek: arıza bulma', 'NAYAJET-72-003',
    'Egzoz sıcaklığı aynı ayarda normalden yüksek okunuyor.',
    [('Sıcaklık algılayıcılarını ve göstergeyi kontrol edin.',
      'Algılayıcı ya da bağlantısı arızalı mı?', 'Algılayıcıları muayene '
      'edin.', code('77', '1', '310')),
     ('Fanı ve kompresör girişini kirlilik ve hasar açısından kontrol edin.',
      'Kompresör kirli mi?', 'Kompresörü yıkayın.', code('72', '1', '250')),
     ('Boroskop muayenesi yapın.', 'Yanma odası ya da türbinde hasar var '
      'mı?', 'Hasarı değerlendirin; sınır dışındaysa motoru sökün.',
      code('72', info='520'))],
    ('Bulgu yok: yakıt kontrol ünitesini kontrol ettirin.',
     code('73', '1', '920')))

ENGINE_POWER_ISO = isolate(
    code('72', info='421', disassy='03'), 'Motor',
    'İtki düşük ya da devir dalgalanıyor: arıza bulma', 'NAYAJET-72-004',
    'Motor itkisi düşük, devir dalgalanıyor, motor tekliyor ya da yakıt '
    'filtresi uyarısı yanıyor.',
    [('Motor yakıt filtresinin tıkanma göstergesini kontrol edin.',
      'Gösterge çıkmış mı?', 'Filtreyi değiştirin.',
      code('73', '1', '921')),
     ('Hava alığını ve fanı kontrol edin.', 'Tıkanma ya da hasar var mı?',
      'Hava alığını muayene edin.', code('53', '3', '310')),
     ('Değişken stator kanatlarının bağlantılarını kontrol edin.',
      'Boşluk ya da eyleyici sızıntısı var mı?', 'Bağlantıları onartın.',
      code('72', '1', '300'))],
    ('Bulgu yok: yakıt kontrol ünitesini değiştirin.',
     code('73', '1', '920')))

# Motor yakıtı
FUEL_CONTROL_REPL = replace(
    code('73', '1', '920'), 'Motor yakıt kontrol ünitesi', figure=14,
    removal=['Yakıt hatlarını ve elektrik konnektörlerini ayırın; '
             'açıklıkları kapatın.', 'Üniteyi destekleyerek bağlantılarını '
             'sökün.'],
    install=['Yeni üniteyi yeni contalarla yerleştirin. ' + TORQUE,
             'Hatları ve konnektörleri bağlayın.'],
    test='Yer çalıştırmasında motor devrinin kararlı olduğunu ve sızıntı '
         'olmadığını motor personeline kontrol ettirin.',
    spares=[('Motor yakıt kontrol ünitesi', 1)],
    conditions=ENGINE_COND,
    warnings=['Yakıt cilde zararlıdır; eldiven takın.'])

ENGINE_FUEL_FILTER = proc(
    code('73', '1', '921'), 'Motor yakıt filtresi',
    info='Yenisiyle değiştirme', figure=14,
    spares=[('Motor yakıt filtresi elemanı', 1)],
    conditions=ENGINE_COND,
    warnings=['Yakıt cilde zararlıdır; eldiven ve gözlük takın.'],
    steps=[
        'Filtre kabının altına toplama kabı koyun.',
        'Kabı sökün, eski elemanı çıkarın ve kirliliği kayda geçirin.',
        'Yeni elemanı ve contaları takın; kabı sıkın ve emniyetleyin.',
        'Tıkanma göstergesini sıfırlayın ve yer çalıştırmasında sızıntı '
        'kontrolü yaptırın.',
    ])

AB_FUEL = proc(
    code('73', '2', '310'), 'Art yakıcı yakıt sistemi', figure=15,
    tools=[('El feneri', 1)],
    conditions=ENGINE_COND, warnings=[HOT],
    steps=[
        'Art yakıcı yakıt hatlarını ve bağlantılarını sızıntı açısından '
        'muayene edin.',
        'Püskürtme halkalarını lüleden bakarak yanık ve tıkanma açısından '
        'kontrol edin.',
        'Art yakıcı yakıt kontrol ünitesinin bağlantılarını kontrol edin.',
    ])

# Ateşleme
IGNITION_TEST = proc(
    code('74', '1', '320'), 'Ateşleme sistemi', info='Çalışma testi',
    figure=6,
    conditions=[SAFE, ENGINE_OFF, 'Motor bölmesi boş; yakıt kesik.',
                'Test yetkili motor personelince yapılır.'],
    warnings=['Ateşleme ünitesi öldürücü yüksek gerilim üretir. Test '
              'sırasında ateşleyicilere ve kablolarına dokunmayın; testten '
              'sonra el kitabındaki süre kadar bekleyin.'],
    steps=[
        'Ateşleme sistemini test konumunda çalıştırın.',
        'Her iki ateşleyicinin düzenli çıtırtısını dinleyin.',
        'Sistemi kapatın ve boşalma süresini bekleyin.',
        'Sesi duyulmayan ateşleyiciyi ya da üniteyi değiştirin.',
    ])

IGNITER_REPL = replace(
    code('74', '1', '920'), 'Ateşleyici', figure=6,
    removal=['Ateşleme ünitesinin kapalı olduğunu ve boşalma süresinin '
             'geçtiğini kontrol edin.', 'Ateşleme kablosunu ayırın.',
             'Ateşleyiciyi yuvasından sökün.'],
    install=['Yeni ateşleyiciyi contasıyla takın. ' + TORQUE,
             'Kabloyu takın ve emniyetleyin.'],
    test='Ateşleme sistemi çalışma testini yapın.',
    spares=[('Ateşleyici', 1)],
    conditions=ENGINE_COND,
    warnings=['Ateşleme ünitesi öldürücü yüksek gerilim üretir.'])

# Motor göstergeleri
ENGINE_SENSORS = proc(
    code('77', '1', '310'), 'Motor algılayıcıları', figure=6,
    tools=[('El feneri', 1)],
    conditions=ENGINE_COND,
    steps=[
        'Egzoz sıcaklık algılayıcılarını, devir algılayıcılarını ve '
        'titreşim algılayıcısını bağlantı ve hasar açısından muayene edin.',
        'Algılayıcı kablolarında sürtünme ve ısı izi arayın.',
        'Konnektörleri kontrol edin.',
    ],
    next=code('20', '2', '310'))

ENGINE_IND_ISO = isolate(
    code('77', '1', '421'), 'Motor göstergeleri',
    'Tutarsız motor göstergesi: arıza bulma', 'NAYAJET-77-001',
    'Motor sıcaklık, devir ya da titreşim göstergesi dalgalanıyor veya '
    'diğer göstergelerle uyuşmuyor.',
    [('Algılayıcıların konnektörlerini ve kablolarını kontrol edin.',
      'Konnektör gevşek ya da kablo hasarlı mı?', 'Kabloyu onarın.',
      code('24', '6', '310')),
     ('Algılayıcıları muayene edin.', 'Algılayıcı hasarlı mı?',
      'Algılayıcıyı değiştirtin.', code('77', '1', '310'))],
    ('Bulgu yok: göstergeyi bir sonraki yer çalıştırmasında izleyin.',
     code('77', '1', '310')))

# Motor yağı
OIL_FILTER = proc(
    code('79', '1', '921'), 'Motor yağ filtresi', info='Yenisiyle değiştirme',
    figure=14, spares=[('Motor yağ filtresi elemanı', 1)],
    conditions=ENGINE_COND,
    warnings=['Sentetik türbin yağı cilde zararlıdır; eldiven takın.'],
    steps=[
        'Filtre kabının altına toplama kabı koyun.',
        'Kabı sökün ve elemanı çıkarın; elemanda metal parçacık arayın.',
        'Parçacık varsa kayda geçirin ve yağ örneği alın.',
        'Yeni elemanı ve contaları takın; kabı sıkın ve emniyetleyin.',
        'Tıkanma göstergesini sıfırlayın ve yağ seviyesini kontrol edin.',
    ],
    next=code('79', '1', '300'))

CHIP = proc(
    code('79', '1', '310'), 'Manyetik talaş algılayıcı', figure=14,
    supplies=[('Temiz bez', 1)],
    conditions=ENGINE_COND,
    steps=[
        'Talaş algılayıcıyı yuvasından çıkarın; yuvanın valfi yağı tutar.',
        'Mıknatıslı uçta metal parçacık olup olmadığına bakın.',
        'Parçacıkları temiz bir kâğıda alıp kayda geçirin ve analiz için '
        'saklayın.',
        'Ucu temizleyin, contasını yenileyin ve algılayıcıyı takın.',
        'Parçacık bulunduysa motor personeline bildirin; yatak hasarı '
        'olabilir.',
    ])

OIL_SAMPLE = proc(
    code('79', '1', '361'), 'Motor yağı', info='Yağ örneği alma', figure=14,
    tools=[('Örnek şişesi', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Motor durdurulduktan sonra el kitabındaki '
                'süre içinde.'],
    warnings=['Sıcak yağ cildi yakar; eldiven takın.'],
    steps=[
        'Örnek alma noktasını temizleyin.',
        'Temiz örnek şişesini el kitabındaki yönteme göre doldurun.',
        'Şişeyi etiketleyin: uçak, motor, tarih ve çalışma saati.',
        'Örneği analiz laboratuvarına gönderin; sonucu motor kaydına geçirin.',
    ])

OIL_ISO = isolate(
    code('79', info='421'), 'Motor yağ sistemi',
    'Yağ basıncı ya da talaş uyarısı: arıza bulma', 'NAYAJET-79-001',
    'Yağ basıncı uyarısı, talaş uyarısı ya da yağ filtresi tıkanma '
    'göstergesi.',
    [('Yağ seviyesini kontrol edin.', 'Seviye düşük mü?', 'Yağı tamamlayın '
      've sızıntı arayın.', code('79', '1', '300')),
     ('Aksesuar dişli kutusunun gövdesini ve tahrik mili contalarını '
      'kontrol edin.', 'Yağ sızıntısı ya da çatlak var mı?',
      'Dişli kutusunu muayene edin.', code('72', '6', '310')),
     ('Talaş algılayıcıyı çıkarıp kontrol edin.', 'Metal parçacık var mı?',
      'Talaş algılayıcı muayenesini tamamlayın ve yağ örneği alın.',
      code('79', '1', '310')),
     ('Yağ filtresinin tıkanma göstergesini kontrol edin.',
      'Gösterge çıkmış mı?', 'Yağ filtresini değiştirin.',
      code('79', '1', '921'))],
    ('Bulgu yok: yağ basıncı algılayıcısını ve göstergesini kontrol edin.',
     code('77', '1', '310')))


# --- Ek arıza bulma ----------------------------------------------------------

BRAKE_HEAT_ISO = isolate(
    code('32', '4', '421', '01'), 'Tekerlek frenleri',
    'Aşırı ısınma: arıza bulma', 'NAYAJET-32-101',
    'Taksiden ya da inişten sonra bir tekerlek ve fren aşırı sıcak; uçak '
    'taksi sırasında bir yana çekiyor.',
    [
        ('Tekerleğe yan taraftan değil önden ya da arkadan yaklaşın; ısı '
         'sigortası tapalarına ve lastiğe uzaktan bakın.',
         'Isı sigortası tapası erimiş ya da lastik inmiş mi?',
         'Tekerleği soğumaya bırakın, sonra tekerleği ve lastiği '
         'değiştirin.', code('32', '4', '920')),
        ('Fren soğuduktan sonra disklere ve fren gövdesine bakın.',
         'Disklerde renk değişimi, çatlak ya da aşınma pimi sınırda mı?',
         'Fren grubunu değiştirin.', code('32', '4', '920', '01')),
        ('Uçağı çekerek tekerleğin serbest dönüp dönmediğini kontrol '
         'edin.', 'Fren bırakıldığı hâlde tekerlek sürtüyor mu?',
         'Fren grubu geri çekilmiyor; değiştirin.',
         code('32', '4', '920', '01')),
    ],
    ('Fren ve tekerlek muayenesini yapın; ısınma pilot kullanımından '
     'kaynaklanmış olabilir, kayda geçirin.', code('32', '4', '310')))

INTAKE_ISO = isolate(
    code('53', '3', '421'), 'Hava alığı', 'Arıza bulma', 'NAYAJET-53-101',
    'Hava alığında yabancı cisim, kaplama hasarı ya da gevşek bağlantı '
    'elemanı görüldü.',
    [
        ('Motor durmuşken hava alığına el feneriyle bakın; içeri '
         'girmeden önce alığın emniyetini sağlayın.',
         'Alıkta ya da fan önünde yabancı cisim ya da cisim izi var mı?',
         'Yabancı cisim yutma muayenesini yapın.', code('05', '2', '300',
                                                       '03')),
        ('Alık kaplamasını ve bağlantı elemanlarını kontrol edin.',
         'Gevşek, eksik bağlantı elemanı ya da kalkmış kaplama var mı?',
         'Hava alığı muayenesini yapın ve eksikleri kayda geçirin.',
         code('53', '3', '310')),
    ],
    ('Alık temiz: fan kanatlarına bakın.', code('72', '1', '310')))

# --- Nasıl çalışır -----------------------------------------------------------
#
# Her sistem kökü için sade bir çalışma anlatımı. Değer ve iç yapı ayrıntısı
# yazılmaz; sistemde zaten bir tanım DM'i varsa bu anlatım yanına '01' sökme
# koduyla eklenir.

HOW = 'Nasıl çalışır'

dm(code=code('53', '1', '040'), tech='Gövde', info=HOW,
   description=[
       ('Yapı', [
           'Gövde, çerçeveler ve kirişlerle taşınan, dış kaplaması perçin ve '
           'vidalarla bağlanmış yarı monokok bir yapıdır. Kanatlar, kuyruk, '
           'iniş takımı ve motor bağlantıları bu yapıya yük aktarır.',
           'Erişim panelleri sistemlere ulaşmak için açılır. Her panelin '
           'bağlantı elemanı tam ve doğru takılmalıdır; gevşek bir eleman '
           'uçuşta kopup motora yabancı cisim olarak girebilir.',
       ]),
       ('Radom ve hava alığı', [
           'Burundaki radom, içindeki anteni korurken radyo dalgalarını '
           'geçiren özel bir kompozittir. Yüzeyindeki erozyon ve boya '
           'hasarı hem yapıyı hem de sinyali bozar.',
           'Hava alığı motorun havasını gövdenin altından alır. Alığın içi '
           'düzgün ve temiz olmalıdır; içerideki her cisim doğrudan fana '
           'gider.',
       ]),
       ('Korozyon', [
           'Alüminyum yapı nem, tuz ve farklı metallerin teması nedeniyle '
           'korozyona uğrar. Korozyon önce boya altında kabarma, beyaz toz '
           'ya da bağlantı elemanı çevresinde iz olarak görülür.',
       ]),
   ])

dm(code=code('25', '0', '040'), tech='Kokpit', info=HOW,
   description=[
       ('Yerleşim', [
           'İki kişilik kokpitte ön ve arka koltuk, her birinin önünde '
           'gösterge panelleri ve ekranlar, sağda yan kumanda kolu, solda '
           'gaz kolu ve ayakta pedallar bulunur.',
           'Yan kumanda kolu az hareket eder; pilotun uyguladığı kuvveti '
           'elektrik sinyaline çevirip uçuş kumanda bilgisayarına gönderir.',
       ]),
       ('Fırlatma koltuğu', [
           'Fırlatma koltuğu patlayıcı elemanlarla çalışır. Yerde emniyet '
           'pimleri takılıdır; pimler yalnız uçuşa hazırlıkta yetkili kişi '
           'tarafından çıkarılır. Koltuk çevresinde gevşek eşya, kumanda '
           'hareketini kilitleyebilir.',
       ]),
       ('Kanopi', [
           'Kanopi kokpiti kapatır; şişirilebilir conta kanopi ile gövde '
           'arasını sızdırmaz yapar ve kokpitin basınçlanmasını sağlar. '
           'Kanopi camı yalnız onaylı malzemeyle temizlenir; yanlış bez ya '
           'da temizleyici camı çizer.',
       ]),
   ])

dm(code=code('57', '1', '040'), tech='Kanatlar', info=HOW,
   description=[
       ('Kanat ve kumanda yüzeyleri', [
           'Kanat taşımayı üretir. Arka kenardaki flaperonlar hem kanatçık '
           'hem flap görevi görür: birlikte inip kalkarak taşımayı, ters '
           'yönde hareket ederek yatışı değiştirir.',
           'Hücum kenarı flapları kanadın ön kenarını uçuş koşuluna göre '
           'aşağı indirir; yüksek hücum açısında havanın kanattan '
           'kopmasını geciktirir. İki yanın flapı her zaman aynı konumda '
           'olmalıdır.',
       ]),
       ('Statik boşaltıcılar', [
           'Kanat ve kuyruk uçlarındaki ince çubuklar uçuşta gövdede biriken '
           'statik elektriği havaya boşaltır; telsiz parazitini azaltır.',
       ]),
   ])

dm(code=code('57', '2', '040'), tech='Kuyruk', info=HOW,
   description=[
       ('Kuyruk yüzeyleri', [
           'Dikey kuyruk ve dümen uçağı yön ekseninde dengeler. Yatay '
           'kuyruk iki parçadır ve her biri tümüyle döner; birlikte '
           'dönünce burnu kaldırıp indirir, ters dönünce yatışa yardım '
           'eder.',
           'Hava frenleri kuyruğun iki yanındaki yaprakların açılmasıyla '
           'uçağı yavaşlatır. Alt kuyruk kanatçıkları yön kararlılığına '
           'katkı sağlar; yerde çarpmaya açıktır.',
       ]),
   ])

dm(code=code('27', '0', '040', '01'), tech='Uçuş kumandaları', info=HOW,
   description=[
       ('Elektronik kumanda', [
           'Kumanda yüzeyleri ile pilot arasında mekanik bağlantı yoktur. '
           'Yan kumanda kolu ve pedallar sinyal üretir; uçuş kumanda '
           'bilgisayarı bu sinyali uçuş koşuluyla birleştirip eyleyicilere '
           'komut verir.',
           'Bilgisayar ve algılayıcılar yedekli çalışır; biri arızalanınca '
           'diğerleri devam eder ve pilota uyarı verilir. Yerde kendini '
           'sınama testi bu yedekliliği denetler.',
       ]),
       ('Eyleyiciler', [
           'Her kumanda yüzeyi hidrolik eyleyicilerle hareket eder; '
           'eyleyiciler iki ayrı hidrolik sistemden beslenir. Eyleyici '
           'konum algılayıcısı yüzeyin gerçek konumunu bilgisayara geri '
           'bildirir.',
       ]),
   ])

dm(code=code('28', '0', '040', '01'), tech='Yakıt sistemi', info=HOW,
   description=[
       ('Tanklar ve aktarma', [
           'Yakıt gövde ve kanat içindeki tanklarda, konformal tanklarda ve '
           'varsa dış tanklarda taşınır. Yakıt tanklardan bir besleme '
           'tankına aktarılır; besleme tankındaki pompalar yakıtı motora '
           'basar.',
           'Aktarma, uçağın ağırlık merkezini dengede tutacak sırayla '
           'yapılır. Valflerden biri yanlış konumda kalırsa tanklar arasında '
           'dengesizlik oluşur.',
       ]),
       ('İkmal', [
           'Yerde yakıt tek nokta ikmal ağzından basınçla doldurulur; '
           'tanklar dolunca valfler kendiliğinden kapanır. Havada ikmal '
           'ağzı gövdenin üstündedir.',
           'Tanklarda yoğuşan su dibe çöker; boşaltma noktalarından alınan '
           'yakıt örneğiyle izlenir.',
       ]),
       ('Miktar ölçümü', [
           'Tanklardaki algılayıcılar yakıt miktarını ölçer; kokpitteki '
           'gösterge toplam ve tank bazında miktarı gösterir.',
       ]),
   ])

dm(code=code('29', '0', '040', '01'), tech='Hidrolik sistem', info=HOW,
   description=[
       ('İki bağımsız sistem', [
           'Uçakta birbirinden bağımsız iki hidrolik sistem vardır. Her '
           'sistemin motorun aksesuar dişli kutusundan dönen kendi pompası, '
           'deposu, filtreleri ve akümülatörü bulunur.',
           'Uçuş kumanda eyleyicileri iki sistemden birden beslenir; biri '
           'kaybedilse de kumanda sürer. İniş takımı, frenler, burun '
           'tekerleği yönlendirmesi ve hava frenleri sistemlerden birine '
           'bağlıdır.',
       ]),
       ('Temizlik ve sızdırmazlık', [
           'Hidrolik sıvısındaki parçacıkları filtreler tutar; filtre '
           'göstergesi çıktıysa sistemde aşınma olabilir. Akümülatörler ani '
           'ihtiyaçta basıncı destekler ve azotla ön doldurulmuştur.',
           'Basınçlı hidrolik sıvısı deriyi delebilir; sızıntı yalnız sistem '
           'basınçsızken aranır.',
       ]),
   ])

dm(code=code('32', '0', '040', '01'), tech='İniş takımı', info=HOW,
   description=[
       ('Dikmeler', [
           'Ana ve burun iniş takımlarının dikmeleri azot ve hidrolik '
           'sıvısıyla dolu amortisörlerdir; inişte darbeyi emerler. Dikme '
           'normalden kısa duruyorsa azot ya da sıvı kaybı vardır.',
       ]),
       ('Açma-kapama ve kilitler', [
           'Takımlar hidrolik eyleyicilerle açılıp kapanır; açık ve kapalı '
           'konumda mekanik kilitlerle tutulur. Kilit algılayıcıları '
           'kokpitteki konum ışıklarını yakar.',
           'Yer/hava algılayıcıları uçağın yerde mi havada mı olduğunu '
           'bildirir; birçok sistem bu bilgiye göre çalışır.',
       ]),
       ('Fren ve yönlendirme', [
           'Ana tekerleklerdeki çok diskli frenler hidrolikle sıkışır. '
           'Kilitlenme önleyici sistem tekerlek hızını izleyip patinajı '
           'önler. Burun tekerleği yönlendirmesi yerde pedallarla çalışır.',
           'Ağır frenlemeden sonra fren ve tekerlek çok ısınır; tekerlekteki '
           'ısı sigortası tapaları lastiğin patlamasını önlemek için erir.',
       ]),
   ])

dm(code=code('32', '5', '040'), tech='Kuyruk kancası', info=HOW,
   description=[
       ('Görev', [
           'Kuyruk kancası acil durumda pist sonundaki yakalama kablosuna '
           'takılıp uçağı durdurmak içindir. Normal uçuşta yukarıda '
           'kilitlidir; kokpitten indirilir.',
           'Kancanın ucu kabloya temas eden aşınma parçasıdır; çentik ve '
           'aşınma her kullanımdan sonra kontrol edilir.',
       ]),
   ])

dm(code=code('72', '0', '040', '01'), tech='Motor', info=HOW,
   description=[
       ('Turbofan', [
           'Fan havayı emer; havanın bir kısmı motorun çevresindeki baypas '
           'kanalından geçer, kalanı kompresörde sıkıştırılır. Sıkışan '
           'havaya yanma odasında yakıt püskürtülüp yakılır.',
           'Sıcak gaz önce yüksek basınç türbinini, sonra alçak basınç '
           'türbinini döndürür. Türbinler aynı milden kompresörü ve fanı '
           'çevirir. Kalan gaz lüleden hızla çıkıp itki üretir.',
       ]),
       ('Art yakıcı ve lüle', [
           'Art yakıcı, türbinden çıkan gaza ve baypas havasına yeniden '
           'yakıt püskürterek itkiyi artırır. Alev tutucu alevin yerinde '
           'kalmasını sağlar; astar art yakıcı gövdesini ısıdan korur.',
           'Lüle yaprakları eyleyicilerle açılıp kapanır; art yakıcı '
           'çalışırken lüle açılır.',
       ]),
       ('Kontrol ve izleme', [
           'Motor yakıt kontrol ünitesi gaz kolu konumuna ve motorun '
           'durumuna göre yakıtı ayarlar. Değişken stator kanatları '
           'kompresörde havanın akışını devire göre düzenler.',
           'Egzoz sıcaklığı, devir, yağ basıncı ve titreşim izlenir. Yağdaki '
           'metal parçacığı talaş algılayıcısı yakalar; yatak aşınmasının '
           'erken işaretidir.',
       ]),
   ])

dm(code=code('21', '0', '040', '01'), tech='Klima ve basınçlandırma',
   info=HOW,
   description=[
       ('Havanın yolu', [
           'Motorun kompresöründen alınan sıcak ve basınçlı hava (bleed) '
           'klima ünitesine gelir. Ünitede ısı değiştiricilerden ve '
           'soğutma türbininden geçerek soğur; su ayırıcı havadaki nemi '
           'alır.',
           'Soğutulmuş hava kokpite, aviyonik cihazlara ve kanopi '
           'contasına gider. Basınç kontrol valfi kokpit basıncını yüksekliğe '
           'göre ayarlar.',
       ]),
       ('Belirtiler', [
           'Kanallardan biri çatlarsa çevresinde ısı izi oluşur ve aşırı ısı '
           'uyarısı yanabilir. Su ayırıcı tıkanırsa çıkışlardan buğu ya da su '
           'damlası gelir.',
       ]),
   ])

dm(code=code('24', '0', '040', '01'), tech='Elektrik gücü', info=HOW,
   description=[
       ('Kaynaklar', [
           'Ana jeneratör motorun aksesuar dişli kutusundan döner ve '
           'uçağın elektriğini üretir. Ana jeneratör kaybedilirse yedek '
           'jeneratör ve gerektiğinde acil güç ünitesi devreye girer.',
           'Akü çalıştırma ve acil durum içindir. Yerde dış güç prizinden '
           'uçağa elektrik verilebilir.',
       ]),
       ('Dağıtım', [
           'Elektrik baralar üzerinden sistemlere dağıtılır; önemli '
           'sistemler birden çok kaynaktan beslenebilen baralara bağlıdır. '
           'Kablo demetleri yapıya kelepçelerle tutturulur; sürtünme ve '
           'nem, ara ara gelen arızaların başlıca nedenidir.',
       ]),
   ])

dm(code=code('33', '0', '040', '01'), tech='Işıklar', info=HOW,
   description=[
       ('Dış ışıklar', [
           'Seyir lambaları uçağın yönünü, çarpışma önleyici lamba varlığını '
           'gösterir. Formasyon lambaları gece kol uçuşunda diğer uçağın '
           'konumunu belli eder. İniş ve taksi lambaları burun iniş '
           'takımındadır.',
       ]),
       ('Kokpit ışıkları', [
           'Panel ve konsol aydınlatması parlaklık ayarıyla kısılır. Uyarı '
           've ikaz ışıkları test düğmesiyle topluca denenir.',
       ]),
   ])

dm(code=code('34', '0', '040'), tech='Hava verileri', info=HOW,
   description=[
       ('Basınç ölçümü', [
           'Pitot tüpü uçağın ilerleyişiyle oluşan toplam basıncı, statik '
           'portlar çevredeki hava basıncını alır. İkisinin farkından hız, '
           'statik basınçtan yükseklik hesaplanır.',
           'Pitot ya da statik port tıkanırsa hız ve yükseklik yanlış '
           'okunur. Yerde koruyucu kılıflar takılı olur; uçuştan önce mutlaka '
           'çıkarılır.',
       ]),
       ('Hücum açısı', [
           'Hücum açısı algılayıcıları kanadın havaya göre açısını ölçer; '
           'uçuş kumanda bilgisayarı bu bilgiyi sınırlamalarda kullanır. '
           'Algılayıcı serbest dönmeli ve eğilmemiş olmalıdır.',
           'Pitot ısıtıcısı buzlanmayı önler; yerde çalışırken çok ısınır.',
       ]),
   ])

dm(code=code('35', '0', '040', '01'), tech='Oksijen sistemi', info=HOW,
   description=[
       ('Üretim ve dağıtım', [
           'Oksijen üretim ünitesi motordan alınan havadan oksijeni ayırıp '
           'regülatörlere gönderir. Regülatör oksijeni pilotun nefesine '
           'göre maskeye verir.',
           'Ünite arızalanırsa ya da acil durumda koltuktaki acil oksijen '
           'tüpü kullanılır.',
       ]),
       ('Temizlik', [
           'Oksijen bağlantılarına yağ ve gres değmemelidir; yağ oksijenle '
           'yanabilir. Hortum ve maske bağlantıları çatlak ve gevşekliğe '
           'karşı kontrol edilir.',
       ]),
   ])

dm(code=code('26', '0', '040', '01'), tech='Yangından korunma', info=HOW,
   description=[
       ('Algılama', [
           'Motor bölmesinde ve sıcak hava kanallarının çevresinde algılayıcı '
           'halkalar bulunur. Halka belirli bir sıcaklığı görünce kokpitte '
           'yangın ya da aşırı ısı uyarısı yanar.',
           'Uyarı ışıkları ve algılama devresi kokpitteki test düğmesiyle '
           'denenir. Ezilmiş bir halka ya da nem almış bir konnektör yerde '
           'nedensiz uyarıya yol açar.',
       ]),
   ])

dm(code=code('49', '0', '040', '01'), tech='Motor çalıştırma ünitesi',
   info=HOW,
   description=[
       ('Çalıştırma', [
           'Jet yakıtlı çalıştırıcı (JFS) küçük bir gaz türbinidir. '
           'Kendisi çalıştırma akümülatörlerindeki basınçlı hidrolik '
           'sıvısıyla döndürülür, denetim devresini akü besler. Çalışınca '
           'aksesuar dişli kutusu üzerinden ana motoru döndürür.',
           'Ana motor yeterli devre gelip ateş alınca çalıştırıcı ayrılır '
           've durur. Akümülatörler motor çalışırken yeniden dolar.',
       ]),
   ])

# --- Bakım takvimi, sıvılar ve terimler --------------------------------------
#
# Askerî uçakta aralık, miktar ve tip değerleri yazılmaz; neye, ne zaman ve
# nasıl bakılacağı anlatılır.

dm(code=code('00', info='000'), tech='F-16F', info='Bakım takvimi',
   description=[
       ('Kullanım', [
           'Takvim, muayene türlerinde hangi sistemlere bakılacağını '
           'özetler. Aralıklar uçuş saatine, takvime ve olaylara bağlıdır; '
           'kesin aralıklar uçağın kendi bakım programındadır.',
       ]),
       ('Her uçuştan önce', [
           ('Uçuş öncesi muayenede bakılır:', [
               'Koruyucu kılıflar, emniyet pimleri ve hava alığının '
               'temizliği.',
               'Lastikler, frenlerin aşınma pimleri, dikmelerin boyu ve '
               'yuvalardaki sızıntı izi.',
               'Hidrolik, yağ ve oksijen göstergeleri; yakıt örneğinde su.',
               'Kumanda yüzeyleri, erişim panelleri ve bağlantı '
               'elemanları.',
               'Kanopi, conta ve kokpitte gevşek eşya.',
           ]),
       ]),
       ('Her uçuştan sonra', [
           ('Uçuş sonrası muayenede bakılır:', [
               'Lüle, art yakıcı ve motor çevresinde yeni iz ya da hasar.',
               'Lastik ve fren aşınması, sıcak fren varsa soğuma.',
               'Talaş algılayıcı ve filtre göstergeleri.',
               'Pilotun bildirdiği arızaların kayda geçirilmesi.',
           ]),
       ]),
       ('Dönemsel (faz) muayene', [
           ('Bakım programına göre:', [
               'Yapı ve korozyon muayenesi, panellerin içi.',
               'Motor boroskop muayenesi ve yağ analizi.',
               'Hidrolik ve motor yakıt filtrelerinin değişimi.',
               'Uçuş kumanda, iniş takımı açma-kapama ve fren çalışma '
               'testleri.',
               'Yangın algılama, ışıklar ve hava verileri testleri.',
           ]),
       ]),
       ('Olaya bağlı muayeneler', [
           ('Gerektiğinde:', [
               'Sert iniş, yıldırım çarpması, aşırı egzoz sıcaklığı ve '
               'yabancı cisim yutma sonrasında özel muayene.',
               'Uzun süre bekleyen uçakta depolama ve yeniden hizmete alma '
               'işlemleri.',
           ]),
       ]),
   ])

dm(code=code('00', info='030'), tech='F-16F', info='Sıvılar ve kapasiteler',
   description=[
       ('Genel', [
           'Bu şablonda sıvıların tipi, sınıfı ve miktarı verilmez. Her '
           'sıvının tipini, miktarını ve servis yöntemini uçağın teknik el '
           'kitabından alın; onaylı olmayan sıvı kullanmayın, farklı '
           'sıvıları karıştırmayın.',
       ]),
       ('Servis edilen sıvılar ve gazlar', [
           ('Uçakta servis edilenler:', [
               'Yakıt: tek nokta ikmal ağzından basınçla; ikmalden sonra '
               'tanklardan su örneği alınır.',
               'Motor yağı: motorun yağ deposundan, el kitabındaki süre '
               'içinde ve motor durduktan sonra kontrol edilir.',
               'Hidrolik sıvısı: iki sistemin depolarından, sistem '
               'basınçsızken; gösterge el kitabındaki koşulda okunur.',
               'Dikme amortisörleri: azot ve hidrolik sıvısıyla; dikme boyu '
               'uçak ağırlığına göre değerlendirilir.',
               'Lastikler: azotla şişirilir; basınç lastik soğukken '
               'ölçülür.',
               'Akümülatörler: azot ön dolumu, sistem basınçsızken.',
               'Acil oksijen ve acil güç ünitesi: yalnız yetkili ekiple ve '
               'özel önlemlerle.',
           ]),
       ]),
       ('Uyarılar', [
           'Sıvıları servis ederken uçak topraklı olmalıdır.',
           'Oksijen bağlantılarına yağ, gres ya da kirli el değmemelidir.',
           'Dökülen yakıt, yağ ve hidrolik sıvısı hemen temizlenir.',
       ]),
   ])

dm(code=code('00', info='006'), tech='F-16F', info='Terimler sözlüğü',
   description=[
       ('Motor', [
           ('Terimler:', [
               'Turbofan: havanın bir kısmını çekirdeğin çevresinden geçiren '
               'jet motoru.',
               'Baypas: çekirdek motorun çevresinden geçen hava.',
               'Art yakıcı: türbin çıkışında yeniden yakıt yakarak itkiyi '
               'artıran bölüm.',
               'Alev tutucu: art yakıcıda alevin yerinde kalmasını sağlayan '
               'halkalar.',
               'Lüle: motor çıkışında açılıp kapanan yapraklı ağız.',
               'Boroskop: motorun içini sökmeden görmeye yarayan esnek '
               'kamera.',
               'Talaş algılayıcı: yağdaki metal parçacıkları tutan mıknatıslı '
               'tıpa.',
               'Aksesuar dişli kutusu: pompaları, jeneratörü ve '
               'çalıştırıcıyı motora bağlayan dişli kutusu.',
               'JFS: ana motoru çalıştıran küçük jet yakıtlı türbin.',
               'Bleed: motor kompresöründen alınan basınçlı hava.',
               'FOD: motora ya da uçağa zarar veren yabancı cisim.',
           ]),
       ]),
       ('Uçuş kumandaları ve yapı', [
           ('Terimler:', [
               'Fly-by-wire: kumandaların elektrik sinyaliyle çalışması.',
               'Flaperon: hem flap hem kanatçık görevi gören yüzey.',
               'Hücum kenarı flapı: kanadın ön kenarındaki hareketli yüzey.',
               'Eyleyici: kumanda yüzeyini hareket ettiren hidrolik silindir.',
               'Hücum açısı: kanadın hava akımına göre açısı.',
               'Pitot tüpü ve statik port: hız ve yükseklik için basınç '
               'alan girişler.',
               'Radom: radarı örten burun kapağı.',
               'Konformal tank: gövdeye yapışık biçimde takılan yakıt tankı.',
               'Statik boşaltıcı: statik elektriği havaya boşaltan çubuk.',
               'Korozyon: metalin nem ve tuzla bozulması.',
           ]),
       ]),
       ('İniş takımı ve yer işleri', [
           ('Terimler:', [
               'Dikme: iniş takımının amortisörlü bacağı.',
               'Tork kolu: dikmenin dönmesini önleyen makaslı kol.',
               'Anti-skid: frenlemede tekerleğin kilitlenmesini önleyen '
               'sistem.',
               'Isı sigortası tapası: aşırı ısınan tekerlekte eriyip '
               'havayı boşaltan tapa.',
               'Yer/hava algılayıcısı: uçağın yerde olduğunu bildiren '
               'anahtar.',
               'Emniyet pimi: yerde bir düzenin yanlışlıkla çalışmasını '
               'önleyen kırmızı bayraklı pim.',
               'Takoz ve topraklama: uçağın kaymasını ve statik '
               'boşalmayı önleyen yer önlemleri.',
               'Faz muayenesi: belirli uçuş saatlerinde yapılan kapsamlı '
               'dönemsel muayene.',
           ]),
       ]),
   ])

# --- Parça haritası --------------------------------------------------------

# Düğümü olmayan parçalar içinde bulundukları düğüme bağlı.

ENGINE_NODES = ['engine_fan', 'engine_casing', 'engine_lpc', 'engine_hpc',
                'engine_combustor', 'engine_hpt', 'engine_lpt',
                'engine_shafts', 'engine_gearbox', 'afterburner',
                'engine_nozzle']
SURFACES = ['lef_l', 'lef_r', 'flaperon_l', 'flaperon_r',
            'horizontal_tail_l', 'horizontal_tail_r', 'rudder',
            'speed_brakes']
GEAR_NODES = ['nose_gear', 'main_gear_l', 'main_gear_r']

part('airframe', 'Gövde', None, '53-10',
     ['fuselage', 'radome', 'intake', 'canopy', 'conformal_tanks'],
     'z.fuselage', 'Kanatlarla tek parça birleşen alüminyum gövde yapısı.')
part('airframe.radome', 'Radom', 'airframe', '53-20', ['radome'], 'z.nose',
     'Burundaki, radar dalgalarını geçiren kompozit koni.',
     {'inspect': RADOME, 'replace': RADOME_REPL})
part('airframe.intake', 'Hava alığı', 'airframe', '53-30', ['intake'],
     'z.fuselage', 'Gövdenin altındaki alık; havayı motora taşır.',
     {'inspect': INTAKE_CHECK})
part('airframe.canopy', 'Kanopi', 'airframe', '56-10', ['canopy'],
     'z.cockpit', 'İki kokpiti örten tek parça kabarcık kanopi ve çerçevesi.',
     {'inspect': CANOPY_CHECK, 'clean': CANOPY_CLEAN})
part('airframe.panels', 'Erişim panelleri', 'airframe', '53-10',
     ['fuselage'], 'z.fuselage',
     'Sistemlere erişim için sökülebilen gövde panelleri.',
     {'inspect': ACCESS_DOORS})

part('cockpit', 'Kokpit', None, '25-00', ['cockpit'], 'z.cockpit',
     'Ön ve arka kokpit: koltuklar, gösterge panelleri, kumandalar.',
     {'inspect': COCKPIT_CHECK, 'clean': COCKPIT_CLEAN})
part('cockpit.seats', 'Fırlatma koltukları', 'cockpit', '25-10',
     ['cockpit'], 'z.cockpit',
     'Acil durumda pilotu uçaktan çıkaran koltuklar.',
     {'inspect': code('25', '1', '300')}, quantity=2)
part('cockpit.panels', 'Gösterge panelleri ve ekranlar', 'cockpit',
     '25-30', ['cockpit'], 'z.cockpit',
     'Ön ve arka kokpitteki göstergeler, ekranlar ve HUD camı.',
     {'inspect': COCKPIT_CHECK, 'clean': COCKPIT_CLEAN})

part('wings', 'Kanatlar', None, '57-10',
     ['wing_l', 'wing_r', 'lef_l', 'lef_r', 'flaperon_l', 'flaperon_r'],
     'z.wings', 'Gövdeyle birleşik, kesik delta biçimli kanatlar.',
     {'inspect': code('57', '0', '310')})
part('wing_l', 'Sol kanat', 'wings', '57-10', ['wing_l'], 'z.wings',
     'Sol kanat yapısı; içinde yakıt tankı bölümleri.',
     {'inspect': code('57', '0', '310')})
part('wing_r', 'Sağ kanat', 'wings', '57-10', ['wing_r'], 'z.wings',
     'Sağ kanat yapısı; içinde yakıt tankı bölümleri.',
     {'inspect': code('57', '0', '310')})
part('lef_l', 'Sol hücum kenarı flapı', 'wings', '27-40', ['lef_l'],
     'z.wings', 'Hıza ve hücum açısına göre kendiliğinden hareket eder.',
     {'inspect': CONTROLS_CHECK})
part('lef_r', 'Sağ hücum kenarı flapı', 'wings', '27-40', ['lef_r'],
     'z.wings', 'Hıza ve hücum açısına göre kendiliğinden hareket eder.',
     {'inspect': CONTROLS_CHECK})
part('flaperon_l', 'Sol flaperon', 'wings', '27-10', ['flaperon_l'],
     'z.wings', 'Kanatçık ve flap görevini birlikte yapan firar kenarı '
     'yüzeyi.', {'inspect': CONTROLS_CHECK})
part('flaperon_r', 'Sağ flaperon', 'wings', '27-10', ['flaperon_r'],
     'z.wings', 'Kanatçık ve flap görevini birlikte yapan firar kenarı '
     'yüzeyi.', {'inspect': CONTROLS_CHECK})

part('empennage', 'Kuyruk', None, '57-20',
     ['vertical_tail', 'rudder', 'horizontal_tail_l', 'horizontal_tail_r',
      'speed_brakes'], 'z.tail',
     'Dikey kuyruk, dümen, yatay kuyruklar ve hava frenleri.')
part('vertical_tail', 'Dikey kuyruk', 'empennage', '57-20',
     ['vertical_tail'], 'z.tail', 'Yön kararlılığını sağlar.',
     {'inspect': code('57', '0', '310')})
part('rudder', 'Dümen', 'empennage', '27-20', ['rudder'], 'z.tail',
     'Dikey kuyruğun firar kenarındaki yön kumanda yüzeyi.',
     {'inspect': CONTROLS_CHECK})
part('horizontal_tail_l', 'Sol yatay kuyruk', 'empennage', '27-30',
     ['horizontal_tail_l'], 'z.tail',
     'Tek parça dönen stabilatör; yunuslama ve yatış kumandası.',
     {'inspect': CONTROLS_CHECK})
part('horizontal_tail_r', 'Sağ yatay kuyruk', 'empennage', '27-30',
     ['horizontal_tail_r'], 'z.tail',
     'Tek parça dönen stabilatör; yunuslama ve yatış kumandası.',
     {'inspect': CONTROLS_CHECK})
part('speed_brakes', 'Hava frenleri', 'empennage', '27-50',
     ['speed_brakes'], 'z.tail',
     'Lülenin iki yanında açılan, uçağı yavaşlatan paneller.',
     {'inspect': SPEED_BRAKES, 'isolate': SPEEDBRAKE_ISO}, quantity=2)

part('flight_controls', 'Uçuş kumanda sistemi', None, '27-00', SURFACES,
     'z.fuselage',
     'Elektrikli (fly-by-wire) kumanda: bilgisayar ve hidrolik eyleyiciler.',
     {'inspect': CONTROLS_CHECK, 'isolate': FLCS_ISO})
part('flight_controls.actuators', 'Kumanda eyleyicileri', 'flight_controls',
     '27-00', SURFACES, 'z.wings',
     'Kumanda yüzeylerini hareket ettiren hidrolik silindirler.',
     {'inspect': CONTROLS_CHECK, 'isolate': FLCS_ISO,
      'replace': ACTUATOR_REPL})

part('fuel', 'Yakıt sistemi', None, '28-00', ['conformal_tanks', 'fuselage'],
     'z.fuselage', 'Gövde ve kanat içi tanklar, konformal tanklar, '
     'pompalar ve hatlar.', {'refill': REFUEL, 'isolate': FUEL_ISO})
part('fuel.internal', 'Gövde içi tanklar', 'fuel', '28-10', ['fuselage'],
     'z.fuselage', 'Gövdedeki ve kanatlardaki yakıt tankları.',
     {'refill': REFUEL, 'inspect': FUEL_DRAIN})
part('fuel.cft', 'Konformal yakıt tankları', 'fuel', '28-20',
     ['conformal_tanks'], 'z.fuselage',
     'Gövdenin üstüne iki yandan oturan, sökülebilir ek tanklar.',
     {'inspect': CFT}, quantity=2)

part('hydraulics', 'Hidrolik sistem', None, '29-00', ['fuselage'],
     'z.fuselage', 'İki ayrı sistem (A ve B); kumanda yüzeylerini, iniş '
     'takımını ve frenleri çalıştırır.',
     {'inspect': HYD_CHECK, 'isolate': HYD_ISOLATE})

part('landing_gear', 'İniş takımı', None, '32-00', GEAR_NODES, 'z.gear',
     'Burun ve iki ana iniş takımı; hidrolikle açılır ve kapanır.',
     {'isolate': GEAR_ISOLATE})
part('nose_gear', 'Burun iniş takımı', 'landing_gear', '32-20',
     ['nose_gear'], 'z.gear', 'Yönlendirilebilir burun tekerleği ve dikmesi.',
     {'inspect': NOSE_GEAR})
part('main_gear_l', 'Sol ana iniş takımı', 'landing_gear', '32-10',
     ['main_gear_l'], 'z.gear', 'Sol dikme, tekerlek, fren ve kapaklar.',
     {'inspect': MAIN_GEAR})
part('main_gear_r', 'Sağ ana iniş takımı', 'landing_gear', '32-10',
     ['main_gear_r'], 'z.gear', 'Sağ dikme, tekerlek, fren ve kapaklar.',
     {'inspect': MAIN_GEAR})
part('gear.struts', 'Amortisör dikmeleri', 'landing_gear', '32-10',
     GEAR_NODES, 'z.gear', 'Yağ ve azot dolu, iniş darbesini sönümleyen '
     'dikmeler.', {'inspect': MAIN_GEAR, 'refill': STRUT_SERVICE},
     quantity=3)
part('gear.wheels', 'Tekerlekler ve lastikler', 'landing_gear', '32-40',
     GEAR_NODES, 'z.gear', 'Azotla şişirilen lastikler ve jantlar.',
     {'inspect': TIRES, 'replace': WHEEL_CHANGE}, quantity=3)
part('gear.brakes', 'Tekerlek frenleri', 'landing_gear', '32-40',
     ['main_gear_l', 'main_gear_r'], 'z.gear',
     'Ana tekerleklerdeki çok diskli frenler; aşınma pimiyle izlenir.',
     {'inspect': BRAKES, 'isolate': ANTISKID_ISO, 'replace': BRAKE_REPL},
     quantity=2)
part('tail_hook', 'Kuyruk kancası', None, '32-50', ['tail_hook'], 'z.tail',
     'Acil durumda pistteki durdurucu kabloyu yakalayan kanca.',
     {'inspect': HOOK})

part('engine', 'Motor', None, '72-00', ENGINE_NODES, 'z.engine',
     'Art yakıcılı çift milli turbofan motor.',
     {'isolate': ENGINE_ISOLATE, 'inspect': BORESCOPE,
      'remove': ENGINE_REMOVE, 'install': ENGINE_INSTALL})
part('engine.fan', 'Fan', 'engine', '72-10', ['engine_fan'], 'z.engine',
     'Havayı emen ön kanat katı; bir kısmını baypas kanalına gönderir.',
     {'inspect': FAN_CHECK})
part('engine.casing', 'Motor gövdesi ve baypas kanalı', 'engine', '72-00',
     ['engine_casing'], 'z.engine',
     'Fan kasası ve çekirdeği saran dış gövde.', {'inspect': BORESCOPE})
part('engine.lpc', 'Alçak basınç kompresörü', 'engine', '72-10',
     ['engine_lpc'], 'z.engine', 'Havayı çekirdeğe girerken ilk kez '
     'sıkıştırır; fanla aynı milde döner.', {'inspect': BORESCOPE})
part('engine.hpc', 'Yüksek basınç kompresörü', 'engine', '72-10',
     ['engine_hpc'], 'z.engine',
     'Havayı yanma odasına girmeden önce son kez sıkıştırır.',
     {'inspect': BORESCOPE})
part('engine.combustor', 'Yanma odası', 'engine', '72-20',
     ['engine_combustor'], 'z.engine',
     'Sıkıştırılmış havayla yakıtın yandığı halka biçimli oda.',
     {'inspect': BORESCOPE})
part('engine.fuel_nozzles', 'Yakıt enjektörleri', 'engine.combustor',
     '72-20', ['engine_combustor'], 'z.engine',
     'Yakıtı yanma odasına ince damlacıklar halinde püskürtür.',
     {'inspect': BORESCOPE})
part('engine.igniters', 'Ateşleyiciler', 'engine.combustor', '72-20',
     ['engine_combustor'], 'z.engine',
     'Çalıştırmada yakıt-hava karışımını kıvılcımla tutuşturur.',
     {'isolate': ENGINE_ISOLATE, 'inspect': IGNITION_TEST,
      'replace': IGNITER_REPL}, quantity=2)
part('engine.hpt', 'Yüksek basınç türbini', 'engine', '72-30',
     ['engine_hpt'], 'z.engine',
     'Yanma odasından çıkan gazla döner ve yüksek basınç kompresörünü '
     'çevirir.', {'inspect': BORESCOPE})
part('engine.lpt', 'Alçak basınç türbini', 'engine', '72-30',
     ['engine_lpt'], 'z.engine',
     'Fanı ve alçak basınç kompresörünü çevirir.', {'inspect': BORESCOPE})
part('engine.shafts', 'Miller ve yataklar', 'engine', '72-40',
     ['engine_shafts'], 'z.engine',
     'İç içe iki mil: alçak basınç mili ve yüksek basınç mili.',
     {'isolate': ENGINE_VIB_ISO, 'inspect': CHIP})
part('engine.gearbox', 'Aksesuar dişli kutusu', 'engine', '72-60',
     ['engine_gearbox'], 'z.engine',
     'Yakıt ve yağ pompalarını, jeneratörü çalıştırır.',
     {'inspect': GEARBOX})
part('engine.oil', 'Motor yağ sistemi', 'engine', '79-10',
     ['engine_gearbox'], 'z.engine',
     'Yatakları ve dişlileri yağlayan depo, pompa ve filtre.',
     {'inspect': OIL_CHECK})
part('engine.afterburner', 'Art yakıcı', 'engine', '72-50',
     ['afterburner'], 'z.engine',
     'Türbin çıkışındaki gaza yeniden yakıt püskürterek yakan bölüm.',
     {'inspect': NOZZLE})
part('engine.nozzle', 'Egzoz lülesi', 'engine', '72-50', ['engine_nozzle'],
     'z.tail', 'Çıkış alanını motorun çalışma durumuna göre değiştiren '
     'yapraklı lüle.', {'inspect': NOZZLE, 'replace': NOZZLE_FLAP_REPL})

# Gövde ve kapaklar
part('airframe.structure', 'Gövde yapısı ve kaplama', 'airframe', '53-10',
     ['fuselage'], 'z.fuselage',
     'Gövdenin çerçeveleri, kirişleri ve dış kaplaması.',
     {'inspect': STRUCTURE, 'clean': CORROSION})
part('airframe.ventral_fins', 'Alt kuyruk kanatçıkları', 'airframe', '53-10',
     ['fuselage'], 'z.tail',
     'Gövdenin arkasında, altta iki küçük kanatçık; yön kararlılığına '
     'yardım eder.', {'inspect': VENTRAL}, quantity=2)
part('airframe.gear_doors', 'İniş takımı kapakları', 'airframe', '52-30',
     GEAR_NODES, 'z.gear',
     'İniş takımı kalkınca yuvaları kapatan, hidrolikle hareket eden '
     'kapaklar.', {'inspect': GEAR_DOORS, 'adjust': GEAR_DOOR_ADJ},
     quantity=6)
part('airframe.canopy_seal', 'Kanopi contası', 'airframe.canopy', '56-10',
     ['canopy'], 'z.cockpit',
     'Kanopi çerçevesinin altındaki şişirilebilir conta; kokpitin '
     'sızdırmazlığını sağlar.',
     {'isolate': CANOPY_ISO, 'replace': CANOPY_SEAL})

# Kokpit
part('cockpit.harness', 'Koltuk kemerleri ve takımlar', 'cockpit.seats',
     '25-20', ['cockpit'], 'z.cockpit',
     'Pilotu koltuğa bağlayan kemerler, tokalar ve paraşüt bağlantıları.',
     {'inspect': HARNESS}, quantity=2)
part('cockpit.controls', 'Yan kumanda kolu, gaz kolu ve pedallar',
     'cockpit', '27-70', ['cockpit'], 'z.cockpit',
     'Her kokpitte pilotun uçuş ve motor kumandaları.',
     {'inspect': PILOT_CONTROLS}, quantity=2)

# Kanatlar
part('wings.dischargers', 'Statik boşaltıcılar', 'wings', '57-10',
     ['wing_l', 'wing_r', 'horizontal_tail_l', 'horizontal_tail_r',
      'vertical_tail'], 'z.wings',
     'Firar kenarlarındaki ince çubuklar; uçuşta biriken statik elektriği '
     'boşaltır.', {'inspect': DISCHARGERS}, quantity=12)

# Uçuş kumandaları
part('flight_controls.computer', 'Uçuş kumanda bilgisayarı',
     'flight_controls', '27-60', ['fuselage'], 'z.fuselage',
     'Pilotun kumandasını eyleyicilere ileten bilgisayar; kendi kendini '
     'sınar.', {'isolate': FLCS_ISO, 'inspect': CONTROLS_TEST})
part('flight_controls.lef_drive', 'Hücum kenarı flap tahriki',
     'flight_controls', '27-40', ['lef_l', 'lef_r'], 'z.wings',
     'Hücum kenarı flaplarını iki yanda birlikte süren tahrik ünitesi ve '
     'milleri.', {'inspect': LEF_TEST, 'isolate': FLCS_ISO})

# Yakıt
part('fuel.pumps', 'Yakıt pompaları', 'fuel', '28-30', ['fuselage'],
     'z.fuselage', 'Yakıtı tanklardan motora ve tanklar arasında aktaran '
     'pompalar.', {'isolate': FUEL_ISO, 'replace': FUEL_PUMP_REPL},
     quantity=4)
part('fuel.valves', 'Yakıt valfleri ve hatları', 'fuel', '28-30',
     ['fuselage', 'wing_l', 'wing_r'], 'z.fuselage',
     'Aktarımı ve dengeyi yöneten valfler, hatlar ve havalandırma.',
     {'inspect': FUEL_LINES, 'isolate': FUEL_ISO})
part('fuel.quantity', 'Yakıt miktar göstergesi', 'fuel', '28-40',
     ['fuselage'], 'z.fuselage',
     'Tanklardaki algılayıcılar ve kokpitteki gösterge.',
     {'isolate': FUEL_QTY_ISO, 'inspect': FUEL_QTY_TEST})
part('fuel.spr', 'Tek nokta ikmal ağzı', 'fuel', '28-10', ['fuselage'],
     'z.fuselage', 'Yerde bütün tankların tek ağızdan doldurulduğu ve '
     'boşaltıldığı bağlantı.', {'refill': REFUEL, 'remove': DEFUEL})
part('fuel.receptacle', 'Havada ikmal ağzı', 'fuel', '28-50',
     ['fuselage', 'conformal_tanks'], 'z.fuselage',
     'Kanopinin arkasında, gövdenin üstündeki kapaklı ikmal ağzı.',
     {'inspect': RECEPTACLE})

# Hidrolik
part('hydraulics.pumps', 'Hidrolik pompaları', 'hydraulics', '29-20',
     ['engine_gearbox'], 'z.engine',
     'A ve B sistemlerini basınçlandıran, dişli kutusundan çalışan pompalar.',
     {'isolate': HYD_ISOLATE, 'replace': HYD_PUMP_REPL}, quantity=2)
part('hydraulics.reservoirs', 'Hidrolik depolar', 'hydraulics', '29-10',
     ['fuselage'], 'z.fuselage', 'A ve B sistemlerinin sıvı depoları ve '
     'seviye göstergeleri.', {'inspect': HYD_CHECK, 'refill': HYD_CHECK},
     quantity=2)
part('hydraulics.accumulators', 'Hidrolik akümülatörleri', 'hydraulics',
     '29-30', ['fuselage'], 'z.fuselage',
     'Basınç dalgalanmalarını sönümleyen, ani ihtiyaçta sıvı veren azot '
     'ön dolumlu kaplar.', {'inspect': ACCUMULATOR})
part('hydraulics.filters', 'Hidrolik filtreler', 'hydraulics', '29-10',
     ['fuselage'], 'z.fuselage',
     'Sıvıdaki parçacıkları tutan, tıkanma göstergeli filtreler.',
     {'replace': HYD_FILTER, 'inspect': HYD_LINES})
part('hydraulics.lines', 'Hidrolik hatlar ve hortumlar', 'hydraulics',
     '29-10', ['fuselage', 'main_gear_l', 'main_gear_r', 'nose_gear'],
     'z.fuselage', 'Sistemleri eyleyicilere bağlayan sert hatlar ve esnek '
     'hortumlar.', {'inspect': HYD_LINES, 'isolate': HYD_ISOLATE})

# İniş takımı
part('gear.retraction', 'Açma-kapama eyleyicileri ve kilitler',
     'landing_gear', '32-30', GEAR_NODES, 'z.gear',
     'İniş takımını kaldırıp indiren eyleyiciler ve aşağı-yukarı kilitler.',
     {'inspect': RETRACT, 'isolate': GEAR_IND_ISO})
part('gear.wow', 'Yer/hava algılayıcıları', 'landing_gear', '32-30',
     ['main_gear_l', 'main_gear_r', 'nose_gear'], 'z.gear',
     'Uçağın yerde mi havada mı olduğunu dikmelerden algılar.',
     {'inspect': RETRACT})
part('gear.steering', 'Burun tekerleği yönlendirme', 'landing_gear',
     '32-60', ['nose_gear'], 'z.gear',
     'Yerde burun tekerleğini pedallarla döndüren hidrolik sistem.',
     {'inspect': STEERING, 'isolate': STEERING_ISO})
part('gear.antiskid', 'Kilitlenme önleyici (anti-skid) sistem',
     'landing_gear', '32-40', ['main_gear_l', 'main_gear_r'], 'z.gear',
     'Frenlemede tekerleklerin kilitlenmesini önler.',
     {'inspect': ANTISKID_TEST, 'isolate': ANTISKID_ISO})

# Klima
part('ecs', 'Klima ve basınçlandırma', None, '21-00', ['fuselage'],
     'z.fuselage', 'Kokpiti ve elektronik bölmeleri soğutur, kokpiti '
     'basınçlandırır.', {'isolate': ECS_ISO})
part('ecs.pack', 'Klima ünitesi', 'ecs', '21-10', ['fuselage'],
     'z.fuselage', 'Sıcak motor havasını soğutan ısı değiştiriciler ve '
     'soğutma türbini.', {'inspect': ECS_PACK, 'isolate': ECS_ISO,
                          'replace': ECS_PACK_REPL})
part('ecs.ducts', 'Klima kanalları', 'ecs', '21-20', ['fuselage'],
     'z.fuselage', 'Şartlandırılmış havayı dağıtan kanallar ve valfler.',
     {'inspect': ECS_DUCTS, 'isolate': ECS_ISO})
part('ecs.pressure', 'Basınç kontrol valfi', 'ecs', '21-30', ['cockpit'],
     'z.cockpit', 'Kokpit basıncını ayarlayan valf ve kanopi contası '
     'şişirme hattı.', {'inspect': ECS_PRESS_TEST})

# Elektrik
part('electrical', 'Elektrik gücü', None, '24-00',
     ['fuselage', 'engine_gearbox'], 'z.fuselage',
     'Jeneratörler, akü, dış güç ve dağıtım.')
part('electrical.generator', 'Ana jeneratör', 'electrical', '24-20',
     ['engine_gearbox'], 'z.engine',
     'Dişli kutusundan çalışan ana elektrik kaynağı.',
     {'isolate': ELEC_ISO, 'replace': GEN_REPL})
part('electrical.standby', 'Yedek jeneratör', 'electrical', '24-20',
     ['engine_gearbox'], 'z.engine',
     'Ana jeneratör devre dışı kalınca temel devreleri besler.',
     {'isolate': ELEC_ISO, 'replace': GEN_REPL})
part('electrical.battery', 'Akü', 'electrical', '24-30', ['fuselage'],
     'z.fuselage', 'Motor çalışmadan önce ve acil durumda temel devreleri '
     'besler.', {'inspect': BATTERY, 'isolate': BATTERY_ISO,
                 'replace': BATTERY_REPL})
part('electrical.external', 'Dış güç prizi', 'electrical', '24-40',
     ['fuselage'], 'z.fuselage', 'Yerde uçağı yer güç ünitesinden besler.',
     {'inspect': EXT_POWER_CHECK, 'isolate': EXT_POWER_ISO,
      'replace': EXT_POWER_REPL})
part('electrical.epu', 'Acil güç ünitesi', 'electrical', '24-50',
     ['fuselage'], 'z.fuselage',
     'Motor ve jeneratörler devre dışı kalınca acil elektrik ve hidrolik '
     'güç sağlar.', {'inspect': EPU})
part('electrical.wiring', 'Kablo demetleri ve konnektörler', 'electrical',
     '24-60', ['fuselage'], 'z.fuselage',
     'Sistemleri birbirine bağlayan kablolar, konnektörler ve topraklama '
     'şeritleri.', {'inspect': WIRING, 'clean': CONNECTORS})

# Işıklar
part('lights', 'Işıklar', None, '33-00', ['lights'], 'z.fuselage',
     'Dış aydınlatma ve kokpit aydınlatması.')
part('lights.position', 'Seyir lambaları', 'lights', '33-40', ['lights'],
     'z.wings', 'Kanat uçlarında sol kırmızı, sağ yeşil; kuyrukta beyaz '
     'lamba.', {'inspect': LIGHTS_TEST, 'isolate': LIGHT_ISO,
                'replace': LAMP_REPL}, quantity=3)
part('lights.anticollision', 'Çarpışma önleyici lamba', 'lights', '33-40',
     ['lights'], 'z.tail', 'Dikey kuyruktaki yanıp sönen lamba.',
     {'inspect': LIGHTS_TEST, 'isolate': LIGHT_ISO, 'replace': LAMP_REPL})
part('lights.landing', 'İniş ve taksi lambaları', 'lights', '33-40',
     ['lights'], 'z.gear', 'Burun iniş takımındaki lambalar.',
     {'inspect': LIGHTS_TEST, 'isolate': LIGHT_ISO, 'replace': LAMP_REPL},
     quantity=2)
part('lights.formation', 'Formasyon lambaları', 'lights', '33-40',
     ['fuselage', 'vertical_tail'], 'z.fuselage',
     'Gövde ve kuyruktaki şerit lambalar; gece kol uçuşu için.',
     {'inspect': LIGHTS_TEST, 'isolate': LIGHT_ISO})
part('lights.cockpit', 'Kokpit aydınlatması', 'lights', '33-10',
     ['cockpit'], 'z.cockpit',
     'Panel, konsol, uyarı ve taşkın aydınlatması.',
     {'inspect': COCKPIT_LIGHTS})

# Hava verileri
part('air_data', 'Hava verileri', None, '34-00', ['radome', 'fuselage'],
     'z.nose', 'Pitot tüpü, statik portlar ve hücum açısı algılayıcıları.')
part('air_data.pitot', 'Pitot tüpü', 'air_data', '34-10', ['radome'],
     'z.nose', 'Burnun ucundaki ısıtmalı hava basıncı algılayıcısı.',
     {'inspect': PITOT, 'isolate': AIRDATA_ISO, 'replace': PITOT_REPL})
part('air_data.static', 'Statik portlar', 'air_data', '34-10',
     ['fuselage'], 'z.nose', 'Gövde yanlarındaki statik basınç delikleri.',
     {'inspect': PITOT, 'isolate': AIRDATA_ISO}, quantity=2)
part('air_data.aoa', 'Hücum açısı algılayıcıları', 'air_data', '34-10',
     ['fuselage'], 'z.nose',
     'Burnun iki yanındaki, akışa göre dönen kanatçıklı algılayıcılar.',
     {'inspect': PITOT, 'replace': PITOT_REPL}, quantity=2)

# Oksijen
part('oxygen', 'Oksijen sistemi', None, '35-00', ['cockpit'], 'z.cockpit',
     'Oksijen üretim ünitesi, regülatörler ve acil oksijen.')
part('oxygen.generator', 'Oksijen üretim ünitesi', 'oxygen', '35-10',
     ['fuselage'], 'z.fuselage', 'Motor havasından oksijen ayırır.',
     {'isolate': OXYGEN_ISO, 'replace': OBOGS_REPL})
part('oxygen.regulators', 'Oksijen regülatörleri ve hortumlar', 'oxygen',
     '35-20', ['cockpit'], 'z.cockpit',
     'Her kokpitte maskeye oksijen veren regülatör ve hortum.',
     {'inspect': OXYGEN_CHECK, 'isolate': OXYGEN_ISO}, quantity=2)
part('oxygen.emergency', 'Acil oksijen tüpleri', 'oxygen', '35-20',
     ['cockpit'], 'z.cockpit', 'Koltuklardaki küçük acil oksijen tüpleri.',
     {'inspect': OXYGEN_EMERGENCY}, quantity=2)

# Yangından korunma
part('fire', 'Yangından korunma', None, '26-00', ['engine_casing'],
     'z.engine', 'Motor bölmesinde yangın ve aşırı ısı algılama.')
part('fire.detectors', 'Yangın ve aşırı ısı algılayıcıları', 'fire',
     '26-10', ['engine_casing'], 'z.engine',
     'Motor bölmesini saran algılayıcı halkalar.',
     {'isolate': FIRE_ISO, 'replace': FIRE_DET_REPL})
part('fire.warning', 'Uyarı ışıkları ve test devresi', 'fire', '26-10',
     ['cockpit'], 'z.cockpit', 'Kokpitteki yangın ve aşırı ısı uyarıları.',
     {'inspect': FIRE_TEST, 'isolate': FIRE_ISO})

# Motor çalıştırma ve hava alma
part('jfs', 'Motor çalıştırma ünitesi', None, '49-00', ['engine_gearbox'],
     'z.engine', 'Motoru çalıştıran jet yakıtlı çalıştırıcı (JFS).')
part('jfs.unit', 'Jet yakıtlı çalıştırıcı', 'jfs', '49-10',
     ['engine_gearbox'], 'z.engine',
     'Dişli kutusu üzerinden motoru döndüren küçük gaz türbini.',
     {'inspect': JFS_CHECK, 'isolate': JFS_ISO})
part('jfs.accumulators', 'Çalıştırma akümülatörleri', 'jfs', '49-10',
     ['fuselage'], 'z.fuselage',
     'Çalıştırıcıyı döndüren hidrolik enerjiyi saklayan akümülatörler.',
     {'refill': JFS_ACC, 'isolate': JFS_ISO}, quantity=2)
part('engine.bleed', 'Hava alma (bleed) sistemi', 'engine', '36-10',
     ['engine_hpc'], 'z.engine',
     'Kompresörden klimaya ve sistemlere sıcak hava alan valfler ve '
     'kanallar.', {'inspect': BLEED, 'isolate': BLEED_ISO})

# Motor ek parçaları
part('engine.mounts', 'Motor bağlantıları', 'engine', '72-00',
     ['engine_casing'], 'z.engine', 'Motoru gövdeye bağlayan ön ve arka '
     'bağlantılar.', {'inspect': ENGINE_MOUNTS})
part('engine.vsv', 'Değişken stator kanatları', 'engine.hpc', '72-10',
     ['engine_hpc'], 'z.engine',
     'Kompresöre giren havanın açısını devre göre ayarlayan kanatlar ve '
     'eyleyicileri.', {'inspect': VSV, 'isolate': ENGINE_POWER_ISO})
part('engine.fuel_control', 'Motor yakıt kontrol ünitesi', 'engine',
     '73-10', ['engine_gearbox'], 'z.engine',
     'Motora giden yakıtı gaz koluna ve motor durumuna göre ayarlar.',
     {'isolate': ENGINE_POWER_ISO, 'replace': FUEL_CONTROL_REPL})
part('engine.fuel_filter', 'Motor yakıt filtresi', 'engine', '73-10',
     ['engine_gearbox'], 'z.engine',
     'Motor yakıt pompasından önce yakıtı süzen, tıkanma göstergeli filtre.',
     {'replace': ENGINE_FUEL_FILTER})
part('engine.ab_fuel', 'Art yakıcı yakıt püskürtücüleri',
     'engine.afterburner', '73-20', ['afterburner'], 'z.engine',
     'Türbin çıkışındaki gaza yakıt püskürten halkalar.',
     {'inspect': AB_FUEL, 'isolate': AB_ISO})
part('engine.flameholder', 'Alev tutucu', 'engine.afterburner', '72-50',
     ['afterburner'], 'z.engine',
     'Art yakıcıda alevin sönmeden durmasını sağlayan halkalar.',
     {'inspect': NOZZLE})
part('engine.ab_liner', 'Art yakıcı astarı', 'engine.afterburner', '72-50',
     ['afterburner'], 'z.engine',
     'Art yakıcı kanalının içini ısıdan koruyan delikli astar.',
     {'inspect': NOZZLE})
part('engine.nozzle_actuators', 'Lüle eyleyicileri', 'engine.nozzle',
     '72-50', ['engine_nozzle'], 'z.tail',
     'Lüle yapraklarını açıp kapayan hidrolik eyleyiciler.',
     {'inspect': NOZZLE_TEST, 'isolate': AB_ISO})
part('engine.ignition_unit', 'Ateşleme ünitesi', 'engine.combustor',
     '74-10', ['engine_combustor'], 'z.engine',
     'Ateşleyicilere yüksek gerilim veren ünite.',
     {'inspect': IGNITION_TEST, 'isolate': ENGINE_ISOLATE})
part('engine.sensors', 'Motor algılayıcıları', 'engine', '77-10',
     ['engine_lpt', 'engine_casing'], 'z.engine',
     'Egzoz sıcaklığı, devir ve titreşim algılayıcıları.',
     {'inspect': ENGINE_SENSORS, 'isolate': ENGINE_IND_ISO})
part('engine.oil_filter', 'Motor yağ filtresi', 'engine.oil', '79-10',
     ['engine_gearbox'], 'z.engine', 'Yağdaki parçacıkları tutan, tıkanma '
     'göstergeli filtre.', {'replace': OIL_FILTER, 'isolate': OIL_ISO})
part('engine.chip_detector', 'Manyetik talaş algılayıcı', 'engine.oil',
     '79-10', ['engine_gearbox'], 'z.engine',
     'Yağdaki metal parçacıkları yakalar; yatak ve dişli aşınmasının erken '
     'belirtisi.', {'inspect': CHIP, 'isolate': OIL_ISO,
                    'measure': OIL_SAMPLE})

ZONES = [
    ('z.nose', 'Burun', None),
    ('z.cockpit', 'Kokpit', None),
    ('z.fuselage', 'Gövde', None),
    ('z.engine', 'Motor bölmesi', 'z.fuselage'),
    ('z.wings', 'Kanatlar', None),
    ('z.tail', 'Kuyruk', None),
    ('z.gear', 'İniş takımı', None),
]

# --- Arızalar ---------------------------------------------------------------

SYMPTOMS = [
    ('sym.no_light', 'Motor çalıştırmada ateş almıyor'),
    ('sym.egt_high', 'Egzoz sıcaklığı normalden yüksek'),
    ('sym.power_loss', 'Motor itkisi düşük'),
    ('sym.engine_vibration', 'Motor titreşimi artmış'),
    ('sym.fan_damage', 'Fan kanadında çentik ya da eğilme görülüyor'),
    ('sym.oil_low', 'Motor yağ seviyesi sık sık düşüyor'),
    ('sym.oil_pressure', 'Motor yağ basıncı uyarısı'),
    ('sym.ab_no_light', 'Art yakıcı devreye girmiyor'),
    ('sym.nozzle_damage', 'Lüle yapraklarında çatlak ya da yanık var'),
    ('sym.hyd_low', 'Hidrolik basınç uyarısı yanıyor'),
    ('sym.hyd_leak', 'Gövde altında ya da yuvalarda hidrolik sıvısı izi'),
    ('sym.flcs_light', 'Uçuş kumanda uyarısı yanıyor'),
    ('sym.speedbrake', 'Hava frenleri tam açılmıyor ya da kapanmıyor'),
    ('sym.fuel_water', 'Yakıt örneğinde su görülüyor'),
    ('sym.fuel_leak', 'Konformal tank bağlantısında yakıt izi'),
    ('sym.tire_wear', 'Lastik aşınma işaretine kadar aşınmış'),
    ('sym.tire_low', 'Lastik basıncı düşük'),
    ('sym.pull', 'Uçak taksi sırasında bir yana çekiyor'),
    ('sym.brake_weak', 'Frenler zayıf tutuyor'),
    ('sym.brake_pin', 'Fren aşınma pimi gövdeyle aynı hizada'),
    ('sym.strut_low', 'Amortisör dikmesi çok kısa duruyor'),
    ('sym.shimmy', 'Burun tekerleği taksi sırasında titriyor'),
    ('sym.canopy_seal', 'Kokpit basınçlanmıyor ya da kanopiden ıslık sesi '
                        'geliyor'),
    ('sym.canopy_vision', 'Kanopiden görüş bulanık ya da çizikli'),
    ('sym.radome_damage', 'Radomda erozyon ya da yıldırım izi var'),
    ('sym.hook_damage', 'Kuyruk kancası ucunda çentik ya da aşınma'),
    # Genişletilmiş içerik
    ('sym.cockpit_temp', 'Kokpit soğumuyor ya da aşırı ısınıyor'),
    ('sym.duct_hot', 'Klima ya da hava alma kanalı çevresinde ısı izi'),
    ('sym.gen_light', 'Jeneratör uyarı ışığı yanıyor'),
    ('sym.battery_low', 'Akü gerilimi düşük ya da akü uyarısı'),
    ('sym.ext_power', 'Dış güç bağlanınca uçağa elektrik gelmiyor'),
    ('sym.intermittent', 'Bir sistem ara ara arıza veriyor, kendiliğinden '
                         'düzeliyor'),
    ('sym.epu_smell', 'Acil güç ünitesi bölgesinde keskin koku ya da sızıntı '
                      'izi'),
    ('sym.fire_light', 'Yangın ya da aşırı ısı uyarısı yerde nedensiz '
                       'yanıyor'),
    ('sym.fire_test', 'Yangın uyarısı testinde ışıklar yanmıyor'),
    ('sym.harness_wear', 'Koltuk kemerinde yırtık ya da aşınma'),
    ('sym.display_scratch', 'Ekran ya da gösterge camı çizik veya kirli'),
    ('sym.loose_object', 'Kokpitte gevşek eşya ya da kumandada sıkışma'),
    ('sym.lef_split', 'Hücum kenarı flapları iki yanda farklı konumda'),
    ('sym.stick_play', 'Kumanda kolu ya da pedallarda boşluk'),
    ('sym.fuel_pressure', 'Yakıt basıncı uyarısı yanıyor'),
    ('sym.fuel_imbalance', 'Tanklar arasında yakıt dengesizliği oluşuyor'),
    ('sym.fuel_qty', 'Yakıt miktar göstergesi tutarsız'),
    ('sym.refuel_slow', 'Yerde ikmal yavaş ya da kendiliğinden kesiliyor'),
    ('sym.receptacle', 'Havada ikmal ağzının kapağı tam kapanmıyor'),
    ('sym.accumulator', 'Akümülatör ön dolumu düşük görünüyor'),
    ('sym.hyd_filter', 'Hidrolik filtre tıkanma göstergesi çıkmış'),
    ('sym.gear_light', 'İniş takımı konum ışığı uygun yanmıyor'),
    ('sym.gear_door', 'İniş takımı kapağı tam kapanmıyor'),
    ('sym.steering', 'Burun tekerleği yönlendirmesi devreye girmiyor'),
    ('sym.antiskid', 'Anti-skid uyarısı yanıyor'),
    ('sym.brake_leak', 'Fren gövdesinde hidrolik sızıntısı'),
    ('sym.light_out', 'Dış lambalardan biri yanmıyor'),
    ('sym.cockpit_light', 'Kokpit panel aydınlatması yanmıyor'),
    ('sym.airspeed', 'Hız göstergesi tutarsız'),
    ('sym.altitude', 'İrtifa göstergesi tutarsız'),
    ('sym.pitot_heat', 'Pitot ısıtma uyarısı yanıyor'),
    ('sym.aoa_damage', 'Hücum açısı algılayıcısı eğik ya da dönmüyor'),
    ('sym.oxygen', 'Oksijen uyarısı yanıyor ya da maskeye akış zayıf'),
    ('sym.oxygen_bottle', 'Acil oksijen tüpü göstergesi düşük'),
    ('sym.jfs', 'Motor çalıştırıcısı (JFS) devreye girmiyor'),
    ('sym.fastener', 'Panel bağlantı elemanı eksik ya da gevşek'),
    ('sym.corrosion', 'Kaplamada kabarma, beyaz toz ya da çukurlanma'),
    ('sym.discharger', 'Statik boşaltıcı kırık ya da eksik'),
    ('sym.ventral', 'Alt kuyruk kanatçığında ezik ya da yer teması izi'),
    ('sym.chip_light', 'Talaş uyarısı ya da talaş algılayıcıda metal '
                       'parçacık'),
    ('sym.oil_filter', 'Yağ filtresi tıkanma göstergesi çıkmış'),
    ('sym.fuel_filter', 'Motor yakıt filtresi tıkanma göstergesi çıkmış'),
    ('sym.rpm_fluct', 'Motor devri dalgalanıyor'),
    ('sym.stall', 'Motor tekliyor ya da patlama sesi geliyor'),
    ('sym.engine_ind', 'Motor göstergeleri birbiriyle uyuşmuyor'),
    ('sym.nozzle_fault', 'Lüle konum uyarısı yanıyor'),
    ('sym.ab_liner', 'Art yakıcı astarında çatlak ya da çökme'),
]

# (id, parça, belirtiler, neden, önem 1-3, arıza bulma, onarım)
FAULTS = [
    ('f.igniters', 'engine.igniters', ['sym.no_light'],
     'Ateşleyiciler kıvılcım üretmiyor.', 2, ENGINE_ISOLATE, IGNITER_REPL),
    ('f.fuel_nozzles', 'engine.fuel_nozzles',
     ['sym.no_light', 'sym.egt_high'],
     'Yakıt enjektörleri kısmen tıkanmış; alev düzensiz.', 2, ENGINE_ISOLATE,
     BORESCOPE),
    ('f.fan.fod', 'engine.fan', ['sym.fan_damage', 'sym.engine_vibration'],
     'Fan kanatları yabancı cisim (FOD) çarpmasıyla hasarlanmış.', 3,
     ENGINE_VIB_ISO, FOD_INGEST),
    ('f.hpc.erosion', 'engine.hpc', ['sym.power_loss', 'sym.egt_high'],
     'Kompresör kanatları aşınmış; motor verimi düşmüş.', 2,
     ENGINE_EGT_ISO, ENGINE_REMOVE),
    ('f.hpt.blade', 'engine.hpt', ['sym.egt_high', 'sym.engine_vibration'],
     'Yüksek basınç türbini kanatlarında yanma ya da kaplama kaybı.', 3,
     ENGINE_EGT_ISO, ENGINE_REMOVE),
    ('f.oil.leak', 'engine.oil', ['sym.oil_low', 'sym.oil_pressure'],
     'Motor yağ sisteminde sızıntı ya da yatak keçesinden kaçak.', 3,
     OIL_ISO, OIL_CHECK),
    ('f.afterburner', 'engine.afterburner', ['sym.ab_no_light'],
     'Art yakıcı ateşlemesi ya da yakıt püskürtme halkası arızalı.', 2,
     AB_ISO, NOZZLE),
    ('f.nozzle.flaps', 'engine.nozzle', ['sym.nozzle_damage'],
     'Lüle yaprakları ısıdan çatlamış ya da yanmış.', 2, NOZZLE,
     NOZZLE_FLAP_REPL),
    ('f.hyd.leak', 'hydraulics.lines', ['sym.hyd_low', 'sym.hyd_leak'],
     'Hidrolik hatta, bağlantıda ya da hortumda sızıntı.', 3, HYD_ISOLATE,
     HYD_LINES),
    ('f.actuator', 'flight_controls.actuators',
     ['sym.flcs_light', 'sym.hyd_leak'],
     'Bir kumanda eyleyicisi sızdırıyor ya da geri bildirimi bozuk.', 3,
     FLCS_ISO, ACTUATOR_REPL),
    ('f.speed_brake', 'speed_brakes', ['sym.speedbrake'],
     'Hava freni eyleyicisi ya da menteşesi arızalı.', 2, SPEEDBRAKE_ISO,
     SPEED_BRAKES),
    ('f.fuel.water', 'fuel.internal', ['sym.fuel_water'],
     'Tanklarda su birikmiş; yoğuşma ya da kirli yakıt.', 2, FUEL_DRAIN,
     FUEL_DRAIN),
    ('f.cft.seal', 'fuel.cft', ['sym.fuel_leak'],
     'Konformal tank bağlantı contası sızdırıyor.', 2, CFT, CFT),
    ('f.tire.worn', 'gear.wheels', ['sym.tire_wear', 'sym.pull'],
     'Lastik aşınma sınırına gelmiş.', 2, TIRES, WHEEL_CHANGE),
    ('f.tire.pressure', 'gear.wheels', ['sym.tire_low', 'sym.pull'],
     'Lastik basıncı düşük; supap ya da jant contası kaçırıyor olabilir.',
     2, TIRES, TIRES),
    ('f.brakes.worn', 'gear.brakes', ['sym.brake_pin', 'sym.brake_weak'],
     'Fren diskleri aşınma sınırına gelmiş.', 3, BRAKES, BRAKE_REPL),
    ('f.strut.service', 'gear.struts', ['sym.strut_low', 'sym.hyd_leak'],
     'Amortisör dikmesi azot ya da yağ kaybetmiş.', 2, MAIN_GEAR,
     STRUT_SERVICE),
    ('f.nose.torque_link', 'nose_gear', ['sym.shimmy'],
     'Burun iniş takımı tork kolunda boşluk ya da titreşim sönümleyicide '
     'arıza.', 2, GEAR_ISOLATE, NOSE_GEAR),
    ('f.canopy.seal', 'airframe.canopy_seal', ['sym.canopy_seal'],
     'Kanopi contası yırtılmış ya da sertleşmiş.', 2, CANOPY_ISO,
     CANOPY_SEAL),
    ('f.canopy.scratch', 'airframe.canopy', ['sym.canopy_vision'],
     'Kanopi camı kirli ya da yanlış temizlikle çizilmiş.', 1, CANOPY_CHECK,
     CANOPY_CLEAN),
    ('f.radome.erosion', 'airframe.radome', ['sym.radome_damage'],
     'Radom yüzeyi yağmur erozyonu ya da yıldırım çarpmasıyla hasarlanmış.',
     2, RADOME, RADOME_REPL),
    ('f.hook.wear', 'tail_hook', ['sym.hook_damage'],
     'Kuyruk kancası ucu aşınmış.', 1, HOOK, HOOK),
    # Klima ve pnömatik
    ('f.ecs.pack', 'ecs.pack', ['sym.cockpit_temp'],
     'Klima ünitesinin ısı değiştiricisi tıkanmış ya da soğutma türbini '
     'arızalı.', 2, ECS_ISO, ECS_PACK_REPL),
    ('f.ecs.duct', 'ecs.ducts', ['sym.cockpit_temp', 'sym.duct_hot'],
     'Klima kanalı çatlamış ya da kelepçesi gevşemiş.', 2, ECS_ISO,
     ECS_DUCTS),
    ('f.ecs.pressure', 'ecs.pressure', ['sym.canopy_seal'],
     'Basınç kontrol valfi ya da conta şişirme hattı arızalı.', 2,
     CANOPY_ISO, ECS_PRESS_TEST),
    ('f.bleed.leak', 'engine.bleed', ['sym.duct_hot', 'sym.fire_light'],
     'Hava alma kanalından sıcak hava sızıyor.', 3, BLEED_ISO, BLEED),
    # Elektrik
    ('f.gen.main', 'electrical.generator', ['sym.gen_light'],
     'Ana jeneratör arızalı ya da tahrik mili kırık.', 3, ELEC_ISO,
     GEN_REPL),
    ('f.gen.standby', 'electrical.standby', ['sym.gen_light'],
     'Yedek jeneratör arızalı.', 2, ELEC_ISO, GEN_REPL),
    ('f.battery', 'electrical.battery', ['sym.battery_low', 'sym.jfs'],
     'Akü şarj tutmuyor ya da kutup başları korozyonlu.', 2, BATTERY_ISO,
     BATTERY_REPL),
    ('f.ext_power', 'electrical.external', ['sym.ext_power'],
     'Dış güç prizinin pinleri yanmış ya da korozyonlu.', 1,
     EXT_POWER_ISO, EXT_POWER_REPL),
    ('f.wiring', 'electrical.wiring', ['sym.intermittent', 'sym.light_out'],
     'Kablo demeti yapıya sürtünüp yalıtımı aşınmış ya da konnektör '
     'gevşemiş.', 2, ELEC_ISO, WIRING),
    ('f.epu.leak', 'electrical.epu', ['sym.epu_smell'],
     'Acil güç ünitesinin yakıt hattında ya da deposunda sızıntı.', 3, EPU,
     EPU),
    # Yangından korunma
    ('f.fire.detector', 'fire.detectors', ['sym.fire_light'],
     'Algılayıcı halka ezilmiş ya da konnektörü nem almış.', 2, FIRE_ISO,
     FIRE_DET_REPL),
    ('f.fire.test', 'fire.warning', ['sym.fire_test'],
     'Uyarı lambası ya da test devresi arızalı.', 2, FIRE_ISO, FIRE_TEST),
    # Kokpit
    ('f.harness', 'cockpit.harness', ['sym.harness_wear'],
     'Koltuk kemeri aşınmış ya da tokası zor açılıyor.', 2, HARNESS,
     HARNESS),
    ('f.seat.pins', 'cockpit.seats', ['sym.loose_object'],
     'Koltuk emniyet pimi ya da bayrağı eksik; koltuk çevresinde gevşek '
     'eşya.', 3, code('25', '1', '300'), COCKPIT_CHECK),
    ('f.displays', 'cockpit.panels', ['sym.display_scratch'],
     'Ekran ve gösterge camları yanlış malzemeyle temizlenmiş ya da '
     'kirlenmiş.', 1, COCKPIT_CHECK, COCKPIT_CLEAN),
    ('f.controls.play', 'cockpit.controls', ['sym.stick_play',
                                             'sym.loose_object'],
     'Kumanda kolu tabanında ya da pedal mekanizmasında boşluk.', 2,
     PILOT_CONTROLS, PILOT_CONTROLS),
    # Uçuş kumandaları
    ('f.flcs.computer', 'flight_controls.computer', ['sym.flcs_light',
                                                     'sym.intermittent'],
     'Kumanda bilgisayarı kendi kendini sınamada arıza veriyor.', 3,
     FLCS_ISO, CONTROLS_TEST),
    ('f.lef.drive', 'flight_controls.lef_drive', ['sym.lef_split',
                                                  'sym.flcs_light'],
     'Hücum kenarı flap tahrik ünitesi ya da mili arızalı.', 3, FLCS_ISO,
     LEF_TEST),
    # Yakıt
    ('f.fuel.pump', 'fuel.pumps', ['sym.fuel_pressure'],
     'Yakıt pompası arızalı.', 3, FUEL_ISO, FUEL_PUMP_REPL),
    ('f.fuel.valve', 'fuel.valves', ['sym.fuel_imbalance',
                                     'sym.refuel_slow'],
     'Aktarma ya da ikmal valfi yanlış konumda kalmış.', 2, FUEL_ISO,
     FUEL_LINES),
    ('f.fuel.qty', 'fuel.quantity', ['sym.fuel_qty'],
     'Yakıt miktar algılayıcısı ya da devresi arızalı.', 2, FUEL_QTY_ISO,
     FUEL_QTY_TEST),
    ('f.fuel.spr', 'fuel.spr', ['sym.refuel_slow'],
     'Tek nokta ikmal ağzının contası ya da valfi arızalı.', 1, FUEL_ISO,
     REFUEL),
    ('f.fuel.receptacle', 'fuel.receptacle', ['sym.receptacle'],
     'Havada ikmal ağzının kapağı ya da kilidi hasarlı.', 2, RECEPTACLE,
     RECEPTACLE),
    # Hidrolik
    ('f.hyd.pump', 'hydraulics.pumps', ['sym.hyd_low'],
     'Hidrolik pompası basınç üretmiyor.', 3, HYD_ISOLATE, HYD_PUMP_REPL),
    ('f.hyd.accumulator', 'hydraulics.accumulators', ['sym.accumulator'],
     'Akümülatörün azot ön dolumu kaçmış.', 2, ACCUMULATOR, ACCUMULATOR),
    ('f.hyd.filter', 'hydraulics.filters', ['sym.hyd_filter'],
     'Filtre elemanı tıkanmış; sistemde aşınma parçacığı olabilir.', 2,
     HYD_LINES, HYD_FILTER),
    ('f.hyd.reservoir', 'hydraulics.reservoirs', ['sym.hyd_low',
                                                  'sym.hyd_leak'],
     'Depo seviyesi düşük ya da seviye göstergesi yanlış okuyor.', 2,
     HYD_ISOLATE, HYD_CHECK),
    # İniş takımı
    ('f.gear.lock', 'gear.retraction', ['sym.gear_light'],
     'Kilit algılayıcısı gevşemiş ya da kilit tam oturmuyor.', 3,
     GEAR_IND_ISO, GEAR_SWING),
    ('f.gear.wow', 'gear.wow', ['sym.gear_light', 'sym.steering'],
     'Yer/hava algılayıcısı yanlış konum bildiriyor.', 2, STEERING_ISO,
     RETRACT),
    ('f.gear.door', 'airframe.gear_doors', ['sym.gear_door',
                                            'sym.gear_light'],
     'İniş takımı kapağının ayarı bozulmuş ya da menteşesi aşınmış.', 2,
     GEAR_IND_ISO, GEAR_DOOR_ADJ),
    ('f.steering', 'gear.steering', ['sym.steering', 'sym.pull'],
     'Yönlendirme eyleyicisi sızdırıyor ya da devresi arızalı.', 2,
     STEERING_ISO, STEERING),
    ('f.antiskid', 'gear.antiskid', ['sym.antiskid', 'sym.tire_wear'],
     'Tekerlek hız algılayıcısı ya da kablosu arızalı.', 2, ANTISKID_ISO,
     ANTISKID_TEST),
    ('f.brakes.leak', 'gear.brakes', ['sym.brake_leak', 'sym.brake_weak'],
     'Fren pistonu contası sızdırıyor.', 3, BRAKES, BRAKE_REPL),
    # Işıklar
    ('f.light.position', 'lights.position', ['sym.light_out'],
     'Seyir lambası yanmış ya da camın içine nem girmiş.', 1, LIGHT_ISO,
     LAMP_REPL),
    ('f.light.anticollision', 'lights.anticollision', ['sym.light_out'],
     'Çarpışma önleyici lamba arızalı.', 2, LIGHT_ISO, LAMP_REPL),
    ('f.light.landing', 'lights.landing', ['sym.light_out'],
     'İniş ya da taksi lambası yanmış.', 2, LIGHT_ISO, LAMP_REPL),
    ('f.light.cockpit', 'lights.cockpit', ['sym.cockpit_light'],
     'Panel aydınlatma lambası ya da parlaklık ayarı arızalı.', 1,
     COCKPIT_LIGHTS, COCKPIT_LIGHTS),
    # Hava verileri
    ('f.pitot.blocked', 'air_data.pitot', ['sym.airspeed'],
     'Pitot tüpü tıkanmış ya da kılıfı çıkarılmamış.', 3, AIRDATA_ISO,
     PITOT),
    ('f.pitot.heater', 'air_data.pitot', ['sym.pitot_heat'],
     'Pitot ısıtıcısı yanmış.', 2, AIRDATA_ISO, PITOT_REPL),
    ('f.static.blocked', 'air_data.static', ['sym.altitude',
                                             'sym.airspeed'],
     'Statik port boya, bant ya da kirle tıkanmış.', 3, AIRDATA_ISO, PITOT),
    ('f.aoa', 'air_data.aoa', ['sym.aoa_damage'],
     'Hücum açısı algılayıcısı darbe almış.', 2, PITOT, PITOT_REPL),
    # Oksijen
    ('f.oxygen.hose', 'oxygen.regulators', ['sym.oxygen'],
     'Maske hortumu çatlamış ya da bağlantı ağzı gevşek.', 3, OXYGEN_ISO,
     OXYGEN_CHECK),
    ('f.oxygen.generator', 'oxygen.generator', ['sym.oxygen'],
     'Oksijen üretim ünitesi arızalı.', 3, OXYGEN_ISO, OBOGS_REPL),
    ('f.oxygen.bottle', 'oxygen.emergency', ['sym.oxygen_bottle'],
     'Acil oksijen tüpü basınç kaybetmiş.', 2, OXYGEN_EMERGENCY,
     OXYGEN_EMERGENCY),
    # Çalıştırma
    ('f.jfs.unit', 'jfs.unit', ['sym.jfs'],
     'Çalıştırıcının yakıt beslemesi ya da kendisi arızalı.', 2, JFS_ISO,
     JFS_CHECK),
    ('f.jfs.accumulator', 'jfs.accumulators', ['sym.jfs', 'sym.accumulator'],
     'Çalıştırma akümülatörleri dolu değil ya da ön dolumu düşük.', 2,
     JFS_ISO, JFS_ACC),
    # Gövde
    ('f.fasteners', 'airframe.panels', ['sym.fastener'],
     'Erişim paneli bağlantı elemanı kaybolmuş ya da gevşemiş.', 2,
     ACCESS_DOORS, ACCESS_DOORS),
    ('f.corrosion', 'airframe.structure', ['sym.corrosion'],
     'Kaplamada ya da bağlantı elemanlarının çevresinde korozyon.', 2,
     STRUCTURE, CORROSION),
    ('f.discharger', 'wings.dischargers', ['sym.discharger'],
     'Statik boşaltıcı kırılmış ya da kopmuş.', 1, DISCHARGERS, DISCHARGERS),
    ('f.ventral', 'airframe.ventral_fins', ['sym.ventral'],
     'Alt kanatçık yere ya da yer ekipmanına çarpmış.', 2, VENTRAL, VENTRAL),
    # Motor
    ('f.engine.bearing', 'engine.shafts', ['sym.engine_vibration',
                                           'sym.chip_light'],
     'Mil yatağı aşınmış; yağda metal parçacık var.', 3, ENGINE_VIB_ISO,
     ENGINE_REMOVE),
    ('f.engine.mount', 'engine.mounts', ['sym.engine_vibration'],
     'Motor bağlantısında boşluk ya da çatlak.', 3, ENGINE_VIB_ISO,
     ENGINE_MOUNTS),
    ('f.engine.sensor', 'engine.sensors', ['sym.engine_ind',
                                           'sym.egt_high'],
     'Motor algılayıcısı ya da kablosu arızalı; gösterge yanlış okuyor.',
     2, ENGINE_IND_ISO, ENGINE_SENSORS),
    ('f.fuel_control', 'engine.fuel_control', ['sym.rpm_fluct',
                                               'sym.power_loss'],
     'Motor yakıt kontrol ünitesi arızalı.', 3, ENGINE_POWER_ISO,
     FUEL_CONTROL_REPL),
    ('f.engine.fuel_filter', 'engine.fuel_filter', ['sym.fuel_filter',
                                                    'sym.power_loss'],
     'Motor yakıt filtresi tıkanmış.', 2, ENGINE_POWER_ISO,
     ENGINE_FUEL_FILTER),
    ('f.vsv', 'engine.vsv', ['sym.stall', 'sym.power_loss'],
     'Değişken stator kanatlarının bağlantısında boşluk ya da eyleyici '
     'arızası.', 3, ENGINE_POWER_ISO, VSV),
    ('f.lpc.dirty', 'engine.lpc', ['sym.egt_high', 'sym.power_loss'],
     'Kompresör kanatları kir ve tuzla kaplanmış.', 1, ENGINE_EGT_ISO,
     ENGINE_WASH),
    ('f.ignition_unit', 'engine.ignition_unit', ['sym.no_light'],
     'Ateşleme ünitesi yüksek gerilim üretmiyor.', 2, ENGINE_ISOLATE,
     IGNITION_TEST),
    ('f.gearbox', 'engine.gearbox', ['sym.chip_light', 'sym.oil_low'],
     'Dişli kutusunda dişli ya da yatak aşınması; conta kaçağı.', 3,
     OIL_ISO, GEARBOX),
    ('f.oil.filter', 'engine.oil_filter', ['sym.oil_filter',
                                           'sym.oil_pressure'],
     'Yağ filtresi tıkanmış.', 2, OIL_ISO, OIL_FILTER),
    ('f.oil.chip', 'engine.chip_detector', ['sym.chip_light'],
     'Talaş algılayıcıda metal parçacık birikmiş.', 3, OIL_ISO, CHIP),
    ('f.nozzle.actuator', 'engine.nozzle_actuators', ['sym.nozzle_fault',
                                                      'sym.ab_no_light'],
     'Lüle eyleyicisi sızdırıyor ya da konum geri bildirimi bozuk.', 2,
     AB_ISO, NOZZLE_TEST),
    ('f.ab.fuel', 'engine.ab_fuel', ['sym.ab_no_light'],
     'Art yakıcı püskürtme halkası tıkanmış ya da hattı sızdırıyor.', 2,
     AB_ISO, AB_FUEL),
    ('f.ab.liner', 'engine.ab_liner', ['sym.ab_liner'],
     'Art yakıcı astarı ısıdan çatlamış ya da çökmüş.', 3, NOZZLE,
     ENGINE_REMOVE),
    ('f.flameholder', 'engine.flameholder', ['sym.ab_no_light',
                                             'sym.nozzle_damage'],
     'Alev tutucu halkaları yanmış.', 2, AB_ISO, NOZZLE),
]

# Yedek parça adı → IPD'deki parça.

# Ek arızaların belirtileri ve arızaları.
SYMPTOMS += [
    ('sym.tire_cut', 'Lastikte kesik, şişlik ya da batmış yabancı cisim var'),
    ('sym.hot_brake', 'Taksiden sonra bir fren ve tekerlek aşırı sıcak'),
    ('sym.fuse_plug', 'Tekerlekteki ısı sigortası tapası erimiş, lastik '
     'inmiş'),
    ('sym.intake_damage', 'Hava alığında yabancı cisim, gevşek bağlantı '
     'elemanı ya da kaplama hasarı var'),
    ('sym.cockpit_mist', 'Klima çıkışlarından buğu ya da su damlası '
     'geliyor'),
    ('sym.battery_corrosion', 'Akü konnektöründe korozyon ya da yanık izi '
     'var'),
    ('sym.formation_light', 'Formasyon lambalarının bir bölümü yanmıyor'),
    ('sym.paint_erosion', 'Hücum kenarlarında boya ve kaplama aşınmış'),
]

FAULTS += [
    ('f.tire.cut', 'gear.wheels', ['sym.tire_cut', 'sym.tire_low'],
     'Lastik yabancı cisimle kesilmiş ya da yanağı hasarlanmış.', 3,
     code('32', '4', '300'), code('32', '4', '920')),
    ('f.brakes.overheat', 'gear.brakes',
     ['sym.hot_brake', 'sym.fuse_plug'],
     'Ağır frenleme ya da sürtünen fren tekerleği aşırı ısıtmış; ısı '
     'sigortası tapası erimiş.', 3, BRAKE_HEAT_ISO, code('32', '4', '920')),
    ('f.brakes.drag', 'gear.brakes', ['sym.hot_brake', 'sym.pull'],
     'Fren grubu bırakıldıktan sonra tam geri çekilmiyor; tekerlek '
     'sürtüyor.', 2, BRAKE_HEAT_ISO, code('32', '4', '920', '01')),
    ('f.intake.fod', 'airframe.intake', ['sym.intake_damage'],
     'Hava alığına yabancı cisim girmiş ya da alıktaki bir bağlantı '
     'elemanı gevşemiş.', 3, INTAKE_ISO, code('53', '3', '310')),
    ('f.ecs.water', 'ecs.pack', ['sym.cockpit_mist', 'sym.cockpit_temp'],
     'Klima ünitesinin su ayırıcısı tıkanmış; nem kokpite geliyor.', 1,
     ECS_ISO, code('21', '1', '310')),
    ('f.battery.connector', 'electrical.battery',
     ['sym.battery_corrosion', 'sym.battery_low'],
     'Akü konnektörü korozyona uğramış ya da gevşek; akım geçişi '
     'zayıf.', 2, BATTERY_ISO, code('20', '2', '310')),
    ('f.light.formation', 'lights.formation', ['sym.formation_light'],
     'Formasyon lambası şeridi ya da bağlantısı arızalı.', 1, LIGHT_ISO,
     code('33', '4', '920')),
    ('f.paint.erosion', 'airframe.structure',
     ['sym.paint_erosion', 'sym.corrosion'],
     'Yağmur ve kum erozyonu hücum kenarlarındaki koruyucu kaplamayı '
     'aşındırmış; altındaki metal açığa çıkıyor.', 1,
     code('53', '1', '310'), code('20', '4', '250')),
]

SPARE_PARTS = {
    'Tekerlek, lastiğiyle': 'gear.wheels',
    'Tekerlek freni': 'gear.brakes',
    'Kumanda eyleyicisi': 'flight_controls.actuators',
    'Klima ünitesi': 'ecs.pack',
    'Dış güç prizi': 'electrical.external',
    'Ana jeneratör': 'electrical.generator',
    'Akü': 'electrical.battery',
    'Yangın algılayıcı halkası': 'fire.detectors',
    'Yakıt pompası': 'fuel.pumps',
    'Hidrolik pompası': 'hydraulics.pumps',
    'Hidrolik filtre elemanı': 'hydraulics.filters',
    'Lamba ünitesi': 'lights.position',
    'Pitot tüpü': 'air_data.pitot',
    'Oksijen üretim ünitesi': 'oxygen.generator',
    'Radom': 'airframe.radome',
    'Kanopi contası': 'airframe.canopy_seal',
    'Lüle yaprağı': 'engine.nozzle',
    'Motor yakıt kontrol ünitesi': 'engine.fuel_control',
    'Motor yakıt filtresi elemanı': 'engine.fuel_filter',
    'Ateşleyici': 'engine.igniters',
    'Motor yağ filtresi elemanı': 'engine.oil_filter',
}


# --- Söyleyişler ------------------------------------------------------------
#
# Pilotun ve teknisyenin arızayı kendi sözleriyle anlatışı; teşhis serbest
# metni bunlarla eşleştirir. Her metin arızaya bir belirti olarak eklenir
# (`Content.add_phrasings`).

PHRASINGS = {
    # Motor
    'f.igniters': [
        'Çalıştırmada ateşleyicilerin çıtırtısı duyulmuyor',
        'Motor dönüyor, yakıt geliyor ama alev almıyor',
    ],
    'f.fuel_nozzles': [
        'Çalıştırmada motor geç ateş aldı ve egzoz sıcaklığı sıçradı',
        'Rölantide egzoz sıcaklığı dalgalı, alev düzensiz gibi',
    ],
    'f.fan.fod': [
        'Fan kanadının ucunda çentik gördüm',
        'Uçuştan sonra fan önünde kuş kalıntısı ve kanatta ezik var',
        'Motor titreşimi yabancı cisim yuttuktan sonra arttı',
    ],
    'f.hpc.erosion': [
        'Aynı gaz konumunda itki eskisinden az, sıcaklık daha yüksek',
        'Motor zamanla güç kaybetti, kalkış mesafesi uzadı',
    ],
    'f.hpt.blade': [
        'Boroskopta türbin kanadında yanık ve kaplama kaybı görüldü',
        'Egzoz sıcaklığı yüksek ve motor hafif titriyor',
    ],
    'f.oil.leak': [
        'Motorun altında ve kaplamada yağ izi var',
        'Her uçuştan sonra yağ tamamlamak gerekiyor',
    ],
    'f.afterburner': [
        'Gaz kolunu art yakıcıya ittim ama art yakıcı yanmadı',
        'Art yakıcı bir yanıp bir sönüyor',
    ],
    'f.nozzle.flaps': [
        'Lüle yapraklarında çatlak ve yanık izi var',
        'Lüle yaprağının kenarı kopmuş',
    ],
    'f.speed_brake': [
        'Hava frenleri tam açılmıyor',
        'Hava freni yaprakları kapanınca aralık kalıyor',
    ],
    'f.ab.fuel': [
        'Art yakıcı geç yanıyor, yanınca da dengesiz',
        'Art yakıcı bölgesinde yakıt kokusu ve ıslaklık var',
    ],
    'f.ab.liner': [
        'Lülenin içinden bakınca astarda çatlak ve çökme görülüyor',
        'Art yakıcı astarında renk değişimi ve yırtık var',
    ],
    'f.flameholder': [
        'Art yakıcı yanıyor ama alev dengesiz, lülede yanık izleri var',
        'Alev tutucu halkalarında yanma ve eğilme var',
    ],
    'f.nozzle.actuator': [
        'Lüle konum uyarısı yandı, lüle tam açılmıyor',
        'Lüle eyleyicisinin çevresinde hidrolik ya da yakıt izi var',
    ],
    'f.engine.bearing': [
        'Talaş ışığı yandı ve motor titreşimi arttı',
        'Yağ analizinde metal parçacık çıktı',
    ],
    'f.engine.mount': [
        'Motor titreşimi gövdede hissediliyor, motor bağlantısında iz var',
        'Motor bağlantı noktasında çatlak ya da boşluk görüldü',
    ],
    'f.engine.sensor': [
        'Egzoz sıcaklığı göstergesi diğer göstergelerle uyuşmuyor',
        'Bir motor göstergesi aniden sıfıra düşüp geri geliyor',
    ],
    'f.fuel_control': [
        'Gaz kolunu sabit tutsam da motor devri iniş çıkış yapıyor',
        'Motor gaz koluna geç ve düzensiz tepki veriyor',
    ],
    'f.engine.fuel_filter': [
        'Motor yakıt filtresi göstergesi çıkmış',
        'Yüksek güçte motor itkisi düşüyor, filtre değişimi gecikmiş',
    ],
    'f.vsv': [
        'Gaz açarken motordan patlama sesi geldi',
        'Hızlanmada motor tekledi ve itki düştü',
    ],
    'f.lpc.dirty': [
        'Deniz kenarında uçtuktan sonra motor verimi düştü',
        'Fan arkasındaki kanatlar kir ve tuzla kaplı',
    ],
    'f.ignition_unit': [
        'Ateşleme testinde iki ateşleyici de çalışmıyor',
        'Ateşleme ünitesinden ses gelmiyor, motor alev almıyor',
    ],
    'f.gearbox': [
        'Aksesuar dişli kutusunun çevresinde yağ var ve talaş ışığı yandı',
        'Dişli kutusundan farklı bir uğultu geliyor',
    ],
    'f.oil.filter': [
        'Yağ filtresi tıkanma göstergesi dışarı çıkmış',
        'Yağ basıncı uyarısı ve filtre göstergesi birlikte geldi',
    ],
    'f.oil.chip': [
        'Talaş algılayıcının mıknatısında ince metal parçacıklar var',
        'Uçuşta talaş ışığı yandı',
    ],
    'f.bleed.leak': [
        'Hava alma kanalının çevresindeki boyada yanık ve renk değişimi '
        'var',
        'Yerde motor çalışırken aşırı ısı uyarısı yandı',
    ],
    # Hidrolik ve kumandalar
    'f.hyd.leak': [
        'Tekerlek yuvasında hidrolik sıvısı damlıyor',
        'Uçuşta hidrolik basınç uyarısı yandı, yerde sıvı izi var',
    ],
    'f.hyd.pump': [
        'Bir hidrolik sistemin basıncı motor çalışırken yükselmiyor',
        'Hidrolik pompanın çevresinde sızıntı yok ama basınç düşük',
    ],
    'f.hyd.accumulator': [
        'Akümülatör göstergesi ön dolumun düşük olduğunu gösteriyor',
        'Sistem basınçsızken akümülatör göstergesi beklenenden düşük',
    ],
    'f.hyd.filter': [
        'Hidrolik filtrenin tıkanma pimi dışarı çıkmış',
        'Filtre göstergesi çıktı, sistemde aşınma şüphesi var',
    ],
    'f.hyd.reservoir': [
        'Hidrolik depo seviyesi göstergesi düşük gösteriyor',
        'Depo seviyesi sızıntı olmadan azalıyor gibi',
    ],
    'f.actuator': [
        'Kumanda eyleyicisinin milinde hidrolik sıvısı var',
        'Uçuş kumanda uyarısı yandı, eyleyici çevresi ıslak',
    ],
    'f.flcs.computer': [
        'Kumanda sisteminin kendini sınama testi arıza verdi',
        'Uçuş kumanda uyarısı yanıp sönüyor, sonra kendiliğinden '
        'düzeliyor',
    ],
    'f.lef.drive': [
        'Hücum kenarı flapları iki yanda farklı açıda duruyor',
        'Hücum kenarı flap testi geçmiyor',
    ],
    'f.controls.play': [
        'Yan kumanda kolu tabanında boşluk hissediliyor',
        'Pedallarda oynama ve tıkırtı var',
    ],
    # Yakıt
    'f.fuel.water': [
        'Yakıt örneğinin dibinde su damlaları var',
        'Örnek kabındaki yakıt bulanık',
    ],
    'f.cft.seal': [
        'Konformal tankın gövdeyle birleştiği yerde yakıt izi var',
        'Konformal tank bağlantısından yakıt kokusu geliyor',
    ],
    'f.fuel.pump': [
        'Yakıt basıncı uyarısı yandı',
        'Yakıt pompası çalıştırıldığında ses gelmiyor',
    ],
    'f.fuel.valve': [
        'Uçuşta bir tank diğerlerinden hızlı boşaldı',
        'Yakıt aktarması beklenen sırayla yapılmıyor',
    ],
    'f.fuel.qty': [
        'Yakıt miktar göstergesi ikmalden sonra yanlış miktar gösteriyor',
        'Toplam yakıt ile tankların toplamı tutmuyor',
    ],
    'f.fuel.spr': [
        'Yerde ikmal çok yavaş gidiyor',
        'İkmal tanklar dolmadan kendiliğinden kesiliyor',
        'İkmal ağzının çevresinden yakıt sızıyor',
    ],
    'f.fuel.receptacle': [
        'Havada ikmal ağzının kapağı tam kapanmıyor',
        'Havada ikmal ağzının kilidi kavramıyor',
    ],
    # İniş takımı
    'f.tire.worn': [
        'Lastiğin aşınma işareti görünmüyor, sırtı düzleşmiş',
        'Lastiğin bir bölgesi düz aşınmış',
    ],
    'f.tire.pressure': [
        'Lastik basık görünüyor, basınç düşük ölçüldü',
        'Lastik her gün biraz basınç kaybediyor',
    ],
    'f.brakes.worn': [
        'Fren aşınma pimi gövdeyle aynı hizaya gelmiş',
        'Frenler eskisi kadar tutmuyor, iniş koşusu uzadı',
    ],
    'f.brakes.leak': [
        'Fren gövdesinin çevresi hidrolik sıvısıyla ıslak',
        'Frenleme zayıf ve tekerlek iç tarafında sıvı izi var',
    ],
    'f.strut.service': [
        'Ana iniş takımı dikmesi normalden kısa duruyor',
        'Uçak bir yana yatık duruyor, dikmede sıvı izi var',
    ],
    'f.nose.torque_link': [
        'Taksi sırasında burun tekerleği titriyor ve sallanıyor',
        'Burun iniş takımının tork kolunda boşluk var',
    ],
    'f.gear.lock': [
        'İniş takımı indirildi ama bir yeşil ışık yanmadı',
        'Takım kapandıktan sonra konum ışığı kırmızı kalıyor',
    ],
    'f.gear.wow': [
        'Yerdeyken uçak havadaymış gibi davranıyor, burun yönlendirmesi '
        'çalışmıyor',
        'Yer/hava anahtarı arızası nedeniyle bazı sistemler devreye '
        'girmiyor',
    ],
    'f.gear.door': [
        'İniş takımı kapağı kapanınca gövdeyle aynı hizaya gelmiyor',
        'Takım kapağının menteşesinde boşluk var',
    ],
    'f.steering': [
        'Burun tekerleği yönlendirmesi devreye girmiyor',
        'Taksi sırasında burun tekerleği istemeden bir yana dönüyor',
    ],
    'f.antiskid': [
        'Anti-skid uyarısı yandı',
        'Frenlemede bir tekerlek kilitlenip lastikte düz iz bıraktı',
    ],
    'f.hook.wear': [
        'Kuyruk kancasının ucunda derin çentik var',
        'Kanca ucu aşınmış, yüzeyi düzleşmiş',
    ],
    # Gövde ve kanopi
    'f.canopy.seal': [
        'Kanopi contası şişmiyor, kenarında yırtık var',
        'Uçuşta kanopi kenarından ıslık sesi geliyor',
    ],
    'f.ecs.pressure': [
        'Kanopi contası sağlam ama kokpit basınçlanmıyor',
        'Yükseldikçe kulaklarda basınç değişimi hissediliyor',
    ],
    'f.canopy.scratch': [
        'Kanopi camında ince çizikler ve hare var',
        'Güneşe karşı bakınca kanopiden görüş bulanık',
    ],
    'f.radome.erosion': [
        'Radomun ucunda boya kalkmış, yüzey aşınmış',
        'Radomda küçük yanık izi ya da delik var',
    ],
    'f.fasteners': [
        'Erişim panelinde bir vida eksik',
        'Panel kenarı kalkık, bağlantı elemanı gevşek',
    ],
    'f.corrosion': [
        'Bağlantı elemanlarının çevresinde beyaz toz var',
        'Boyanın altında kabarma ve çukurlanma görülüyor',
    ],
    'f.discharger': [
        'Kanat ucundaki statik boşaltıcı kırılmış',
        'Telsizde parazit arttı, bir boşaltıcı eksik',
    ],
    'f.ventral': [
        'Alt kuyruk kanatçığında sürtme ve ezik izi var',
        'Alt kanatçık yer ekipmanına çarpmış',
    ],
    # Klima ve elektrik
    'f.ecs.pack': [
        'Kokpit yerde ve alçak irtifada soğumuyor',
        'Klima çıkışından sıcak hava geliyor',
    ],
    'f.ecs.duct': [
        'Kokpit bir tarafta sıcak, klima akışı zayıf',
        'Klima kanalının kelepçesi gevşek ve çevresinde ısı izi var',
    ],
    'f.gen.main': [
        'Motor çalışırken ana jeneratör ışığı yanık kalıyor',
        'Uçuşta ana jeneratör düştü, yedek jeneratör devraldı',
    ],
    'f.gen.standby': [
        'Ana jeneratör çalışıyor ama yedek jeneratör ışığı yanıyor',
        'Yedek jeneratör testi geçmiyor',
    ],
    'f.battery': [
        'Akü gerilimi düşük, motor çalıştırıcısı devreye girmiyor',
        'Akü uyarısı yanıyor ve uçak bekleyince akü boşalıyor',
    ],
    'f.ext_power': [
        'Dış güç bağlandı ama uçağa elektrik gelmiyor',
        'Dış güç fişini takınca prizde kıvılcım oldu',
    ],
    'f.wiring': [
        'Bir sistem uçuşta arıza veriyor, yerde düzeliyor',
        'Kablo demetinde sürtünme ve aşınmış yalıtım gördüm',
    ],
    'f.epu.leak': [
        'Acil güç ünitesi bölmesinden keskin, amonyağa benzer koku geliyor',
        'Acil güç ünitesinin altında sıvı izi var',
    ],
    'f.fire.detector': [
        'Yerde nedensiz yangın uyarısı yandı, motor bölmesi soğuk',
        'Algılayıcı halkasında ezilme ve nemli konnektör var',
    ],
    'f.fire.test': [
        'Yangın uyarısı test düğmesine basınca ışıklar yanmıyor',
        'Yangın testinde ışıklardan biri yanmıyor',
    ],
    # Kokpit
    'f.harness': [
        'Koltuk kemerinde yıpranma ve kesik var',
        'Kemer tokası zor açılıyor',
    ],
    'f.seat.pins': [
        'Koltuk emniyet piminin bayrağı yerinde yok',
        'Koltuğun yanında düşmüş bir kalem ya da alet var',
    ],
    'f.displays': [
        'Ekran camında silme izi ve çizik var',
        'Gösterge camı tozlu, güneşte okunmuyor',
    ],
    # Işıklar, hava verileri, oksijen, çalıştırıcı
    'f.light.position': [
        'Sağ ya da sol seyir lambası yanmıyor',
        'Seyir lambasının camı buğulu',
    ],
    'f.light.anticollision': [
        'Çarpışma önleyici lamba çakmıyor',
        'Çarpışma önleyici lamba sürekli yanıyor ama çakmıyor',
    ],
    'f.light.landing': [
        'İniş lambası yanmıyor',
        'Taksi lambası açılınca hemen sönüyor',
    ],
    'f.light.cockpit': [
        'Panel aydınlatması gece yanmıyor',
        'Parlaklık düğmesini çevirince panel ışıkları titriyor',
    ],
    'f.pitot.blocked': [
        'Kalkış koşusunda hız göstergesi hareket etmedi',
        'Pitot kılıfı çıkarılmadan uçağa yaklaşıldı, hız tutarsız',
    ],
    'f.pitot.heater': [
        'Pitot ısıtma uyarısı yandı',
        'Pitot ısıtıcısı yerde testte ısınmıyor',
    ],
    'f.static.blocked': [
        'Yükseklik göstergesi tırmanışta değişmiyor',
        'Statik portun üzerinde boya ya da bant kalmış',
    ],
    'f.aoa': [
        'Hücum açısı algılayıcısı eğilmiş, elle çevirince takılıyor',
        'Yer ekipmanı hücum açısı algılayıcısına çarpmış',
    ],
    'f.oxygen.hose': [
        'Maskeye oksijen akışı zayıf, hortum bağlantısı gevşek',
        'Oksijen hortumunda çatlak var',
    ],
    'f.oxygen.generator': [
        'Oksijen uyarısı yandı, hortum ve maske sağlam',
        'Oksijen üretim ünitesi testte uyarı veriyor',
    ],
    'f.oxygen.bottle': [
        'Acil oksijen tüpünün göstergesi düşük bölgede',
        'Acil oksijen tüpü basınç kaybetmiş',
    ],
    'f.jfs.unit': [
        'Motor çalıştırıcısı dönüyor ama hızlanmıyor',
        'Çalıştırıcı devreye giriyor sonra kendiliğinden kapanıyor',
    ],
    'f.jfs.accumulator': [
        'Çalıştırma akümülatörleri dolmamış, çalıştırıcı hiç dönmüyor',
        'Çalıştırma akümülatörünün göstergesi düşük',
    ],
    # Ek arızalar
    'f.tire.cut': [
        'Lastiğin yanağında kesik var, iç kat görünüyor',
        'Lastiğe metal parça batmış',
    ],
    'f.brakes.overheat': [
        'İnişten sonra tekerleklerden biri dumanlıyor',
        'Isı sigortası tapası erimiş ve lastik inmiş',
    ],
    'f.brakes.drag': [
        'Taksi sırasında uçak bir yana çekiyor ve fren sıcak',
        'Uçağı çekerken tekerlek serbest dönmüyor',
    ],
    'f.intake.fod': [
        'Hava alığının içinde vida ya da küçük parça buldum',
        'Alık kaplamasında kalkmış bir parça var',
    ],
    'f.ecs.water': [
        'Kokpitte klima çıkışından sis gibi buhar geliyor',
        'Klima çıkışından su damlıyor',
    ],
    'f.battery.connector': [
        'Akü konnektöründe yeşil ya da beyaz korozyon var',
        'Akü fişi gevşek, yanık kokusu geliyor',
    ],
    'f.light.formation': [
        'Formasyon lambalarının bir parçası karanlık kalıyor',
        'Gece kol uçuşunda formasyon ışıkları zayıf görünüyor',
    ],
    'f.paint.erosion': [
        'Kanat hücum kenarında boya kalkmış, metal görünüyor',
        'Dikey kuyruğun ön kenarında kaplama aşınmış',
    ],
}

C.zones, C.symptoms, C.faults = ZONES, SYMPTOMS, FAULTS
C.add_phrasings(PHRASINGS)
C.spare_parts = SPARE_PARTS
C.write()
