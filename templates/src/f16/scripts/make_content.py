"""F-16D Block 60 şablonunun S1000D içeriğini ve parça haritasını üretir.

    python3 make_content.py

İçerik yalnız genel bakım bilgisidir: uçuş öncesi ve sonrası kontroller,
ikmal, seviye kontrolleri, gözle muayene, teker değişimi ve arıza bulma.
Silah, aviyonik, elektronik harp ve performans bilgisi yoktur. Ölçü, basınç
ve tork değerleri verilmez; DM'ler değer gereken yerde uçağın kendi teknik
el kitabına yönlendirir.

Sistem kodları ATA 100 bölüm numaralarına benzer (32 iniş takımı, 72 motor).
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE.parent.parent / 'scripts'))

from s1000d_content import Content  # noqa: E402

# --- SNS ------------------------------------------------------------------

SNS = {
    '00': ('Uçak', {}),
    '25': ('Kokpit donanımı', {'1': 'Fırlatma koltukları'}),
    '27': ('Uçuş kumandaları', {'1': 'Flaperonlar', '2': 'Dümen',
                                '3': 'Yatay kuyruklar',
                                '4': 'Hücum kenarı flapları',
                                '5': 'Hava frenleri'}),
    '28': ('Yakıt sistemi', {'1': 'Gövde içi tanklar',
                             '2': 'Konformal yakıt tankları'}),
    '29': ('Hidrolik güç', {'1': 'Hidrolik sistemler'}),
    '32': ('İniş takımı', {'1': 'Ana iniş takımı', '2': 'Burun iniş takımı',
                           '4': 'Tekerlekler ve frenler',
                           '5': 'Kuyruk kancası'}),
    '53': ('Gövde', {'1': 'Gövde yapısı', '2': 'Radom', '3': 'Hava alığı'}),
    '56': ('Kanopi', {'1': 'Kanopi camı ve çerçevesi'}),
    '57': ('Kanatlar ve kuyruk', {'1': 'Kanatlar', '2': 'Kuyruk'}),
    '72': ('Motor', {'1': 'Fan ve kompresörler', '2': 'Yanma odası',
                     '3': 'Türbinler', '5': 'Art yakıcı ve lüle'}),
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
}

C = Content(
    HERE, model='NAYAJET',
    applic='F-16D Block 60, iki kişilik',
    product='F-16D Block 60',
    manual='F-16D Block 60 genel bakım el kitabı',
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


# --- DM içerikleri ---------------------------------------------------------
#
# Alanlar `templates/scripts/s1000d_content.py` başında anlatılıyor.

# Genel
AIRCRAFT = dm(
    code=code('00'), tech='F-16D Block 60', figure=1,
    description=[
        ('Genel', [
            'F-16, General Dynamics (bugün Lockheed Martin) tarafından '
            'geliştirilen tek motorlu, çok rollü bir savaş uçağıdır. D '
            'sürümü iki kişiliktir: ön ve arka kokpit art arda dizilidir.',
            'Block 60 sürümünde gövdenin üstünde iki yanda konformal yakıt '
            'tankları bulunur; bu tanklar menzili artırır ve dış yük '
            'istasyonlarını boş bırakır.',
        ]),
        ('Sistemler', [
            'Gövde: tek parça kanat-gövde birleşimi, burunda radom, gövdenin '
            'altında hava alığı, üstte kabarcık biçimli kanopi.',
            'Uçuş kumandaları: elektrikli (fly-by-wire) kumanda; flaperonlar, '
            'hücum kenarı flapları, tek parça hareket eden yatay kuyruklar, '
            'dümen ve kuyruk yanlarındaki hava frenleri.',
            'İniş takımı: içe katlanan ana iniş takımları ve öne katlanan '
            'burun iniş takımı; ana tekerleklerde disk frenler.',
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
    figure=1, conditions=[SAFE, ENGINE_OFF],
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
   ])

# Uçuş kumandaları
CONTROLS = dm(
    code=code('27'), tech='Uçuş kumandaları', figure=4,
    description=[
        ('Genel', [
            'F-16 elektrikli (fly-by-wire) kumandalı ilk savaş uçaklarından '
            'biridir. Pilotun kumandası uçuş kumanda bilgisayarına gider; '
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
    figure=1, supplies=[('Jet yakıtı', 1)],
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
             'göstergesi arızalı olabilir; hidrolik personeline bildirin.',
             None),
            ('end-leak', 'Sızıntıyı kayda geçirin ve sızan parçayı '
             'onartın; sonra sıvıyı tamamlayın.', code('29', '1', '300')),
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
            'takımları gövdenin altına içe doğru, burun iniş takımı hava '
            'alığının arkasına katlanır.',
            'Her dikmede yağ ve azot dolu bir amortisör iniş darbesini '
            'sönümler.',
            'Ana tekerleklerde kilitlenmeyi önleyen sistemli disk frenler '
            'vardır. Burun tekerleği yerde yönlendirme için döner.',
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
             'yönlendirme sistemi arızalı olabilir; iniş takımı personeline '
             'bildirin.', None),
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
    ])

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
    supplies=[('Azot', 1)],
    conditions=[SAFE, ENGINE_OFF, 'Lastikler soğuk.'],
    warnings=['Sıcak frenli tekerleğe yaklaşmayın; lastik patlayabilir. '
              'Tekerleğe yan taraftan yaklaşın.'],
    steps=[
        'Lastik basıncını soğuk lastikte ölçün. ' + NO_VALUES,
        'Basınç düşükse azotla tamamlayın; lastikleri hava ile doldurmayın.',
        'Diş derinliğini ve aşınma işaretlerini kontrol edin.',
        'Yanaklarda kesik, şişkinlik ya da kord görünmesi olup olmadığına '
        'bakın. Kord görünen lastiği değiştirin.',
    ])

WHEEL_CHANGE = dm(
    code=code('32', '4', '920'), tech='Ana tekerlek', figure=3,
    tools=[('Aks krikosu', 1), ('Tekerlek somunu anahtarı', 1),
           ('Tork anahtarı', 1)],
    spares=[('Ana tekerlek, lastiğiyle', 1)],
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
    ])

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
    ])

INTAKE_CHECK = dm(
    code=code('53', '3', '310'), tech='Hava alığı',
    info='Yabancı cisim (FOD) muayenesi', figure=2,
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
    ])

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
            'Art yakıcı, türbinden çıkan gaza yeniden yakıt püskürterek kısa '
            'süreli ek itki sağlar. Lüle çıkış alanını itki ihtiyacına göre '
            'açar ve kapatır.',
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
             'Ateşleyiciler çalışıyor mu?', 'end-nozzles', 'end-igniters'),
        ],
        'ends': [
            ('end-fuel', 'Yakıt ikmali yapın ya da valf konumlarını '
             'düzeltin.', code('28', '1', '210')),
            ('end-igniters', 'Ateşleyiciler ya da ateşleme ünitesi '
             'arızalı olabilir; motor personeline bildirin.', None),
            ('end-nozzles', 'Ateşleme var ama motor tutmuyor: yakıt '
             'enjektörleri tıkalı olabilir; boroskop muayenesi yaptırın.',
             code('72', '2', '310')),
        ],
    })

FAN_CHECK = dm(
    code=code('72', '1', '310'), tech='Fan ve kompresör girişi', figure=6,
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
    ])

OIL_CHECK = dm(
    code=code('79', '1', '300'), tech='Motor yağı', info='Seviye kontrolü',
    figure=2, supplies=[('Motor yağı, sentetik türbin yağı', 1)],
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
     {'inspect': RADOME})
part('airframe.intake', 'Hava alığı', 'airframe', '53-30', ['intake'],
     'z.fuselage', 'Gövdenin altındaki alık; havayı motora taşır.',
     {'inspect': INTAKE_CHECK})
part('airframe.canopy', 'Kanopi', 'airframe', '56-10', ['canopy'],
     'z.cockpit', 'İki kokpiti örten tek parça kabarcık kanopi ve çerçevesi.',
     {'inspect': CANOPY_CHECK, 'clean': CANOPY_CLEAN})
part('airframe.panels', 'Erişim panelleri', 'airframe', '53-10',
     ['fuselage'], 'z.fuselage',
     'Sistemlere erişim için sökülebilen gövde panelleri.',
     {'inspect': PREFLIGHT})

part('cockpit', 'Kokpit', None, '25-00', ['cockpit'], 'z.cockpit',
     'Ön ve arka kokpit: koltuklar, gösterge panelleri, kumandalar.')
part('cockpit.seats', 'Fırlatma koltukları', 'cockpit', '25-10',
     ['cockpit'], 'z.cockpit',
     'Acil durumda pilotu uçaktan çıkaran koltuklar.',
     {'inspect': code('25', '1', '300')}, quantity=2)
part('cockpit.panels', 'Gösterge panelleri ve HUD', 'cockpit', '25-00',
     ['cockpit'], 'z.cockpit',
     'Çok işlevli ekranlar ve ön kokpitteki baş üstü gösterge.')

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
     {'inspect': SPEED_BRAKES}, quantity=2)

part('flight_controls', 'Uçuş kumanda sistemi', None, '27-00', SURFACES,
     'z.fuselage',
     'Elektrikli (fly-by-wire) kumanda: bilgisayar ve hidrolik eyleyiciler.',
     {'inspect': CONTROLS_CHECK})
part('flight_controls.actuators', 'Kumanda eyleyicileri', 'flight_controls',
     '27-00', SURFACES, 'z.wings',
     'Kumanda yüzeylerini hareket ettiren hidrolik silindirler.',
     {'inspect': CONTROLS_CHECK})

part('fuel', 'Yakıt sistemi', None, '28-00', ['conformal_tanks', 'fuselage'],
     'z.fuselage', 'Gövde ve kanat içi tanklar, konformal tanklar, '
     'pompalar ve hatlar.', {'refill': REFUEL})
part('fuel.internal', 'Gövde içi tanklar', 'fuel', '28-10', ['fuselage'],
     'z.fuselage', 'Gövdedeki ve kanatlardaki yakıt tankları.',
     {'refill': REFUEL, 'inspect': FUEL_DRAIN})
part('fuel.cft', 'Konformal yakıt tankları', 'fuel', '28-20',
     ['conformal_tanks'], 'z.fuselage',
     'Gövdenin üstüne iki yandan oturan, sökülebilir ek tanklar.',
     {'inspect': CFT}, quantity=2)

part('hydraulics', 'Hidrolik sistem', None, '29-10', ['fuselage'],
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
     'dikmeler.', {'inspect': MAIN_GEAR}, quantity=3)
part('gear.wheels', 'Tekerlekler ve lastikler', 'landing_gear', '32-40',
     GEAR_NODES, 'z.gear', 'Azotla şişirilen lastikler ve jantlar.',
     {'inspect': TIRES, 'replace': WHEEL_CHANGE}, quantity=3)
part('gear.brakes', 'Tekerlek frenleri', 'landing_gear', '32-40',
     ['main_gear_l', 'main_gear_r'], 'z.gear',
     'Ana tekerleklerdeki çok diskli frenler; aşınma pimiyle izlenir.',
     {'inspect': BRAKES}, quantity=2)
part('tail_hook', 'Kuyruk kancası', None, '32-50', ['tail_hook'], 'z.tail',
     'Acil durumda pistteki durdurucu kabloyu yakalayan kanca.',
     {'inspect': HOOK})

part('engine', 'Motor', None, '72-00', ENGINE_NODES, 'z.engine',
     'Art yakıcılı çift milli turbofan motor.',
     {'isolate': ENGINE_ISOLATE, 'inspect': BORESCOPE})
part('engine.fan', 'Fan', 'engine', '72-10', ['engine_fan'], 'z.engine',
     'Havayı emen ön kanat katı; bir kısmını baypas kanalına gönderir.',
     {'inspect': FAN_CHECK})
part('engine.casing', 'Motor gövdesi ve baypas kanalı', 'engine', '72-00',
     ['engine_casing'], 'z.engine',
     'Fan kasası ve çekirdeği saran dış gövde.')
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
     {'isolate': ENGINE_ISOLATE}, quantity=2)
part('engine.hpt', 'Yüksek basınç türbini', 'engine', '72-30',
     ['engine_hpt'], 'z.engine',
     'Yanma odasından çıkan gazla döner ve yüksek basınç kompresörünü '
     'çevirir.', {'inspect': BORESCOPE})
part('engine.lpt', 'Alçak basınç türbini', 'engine', '72-30',
     ['engine_lpt'], 'z.engine',
     'Fanı ve alçak basınç kompresörünü çevirir.', {'inspect': BORESCOPE})
part('engine.shafts', 'Miller ve yataklar', 'engine', '72-00',
     ['engine_shafts'], 'z.engine',
     'İç içe iki mil: alçak basınç mili ve yüksek basınç mili.')
part('engine.gearbox', 'Aksesuar dişli kutusu', 'engine', '72-00',
     ['engine_gearbox'], 'z.engine',
     'Yakıt ve yağ pompalarını, jeneratörü çalıştırır.')
part('engine.oil', 'Motor yağ sistemi', 'engine', '79-10',
     ['engine_gearbox'], 'z.engine',
     'Yatakları ve dişlileri yağlayan depo, pompa ve filtre.',
     {'inspect': OIL_CHECK})
part('engine.afterburner', 'Art yakıcı', 'engine', '72-50',
     ['afterburner'], 'z.engine',
     'Türbin çıkışındaki gaza yeniden yakıt püskürterek ek itki sağlar.',
     {'inspect': NOZZLE})
part('engine.nozzle', 'Egzoz lülesi', 'engine', '72-50', ['engine_nozzle'],
     'z.tail', 'Çıkış alanını itki ihtiyacına göre değiştiren yapraklı '
     'lüle.', {'inspect': NOZZLE})

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
]

# (id, parça, belirtiler, neden, önem 1-3, arıza bulma, onarım)
FAULTS = [
    ('f.igniters', 'engine.igniters', ['sym.no_light'],
     'Ateşleyiciler ya da ateşleme ünitesi kıvılcım üretmiyor.', 2,
     ENGINE_ISOLATE, None),
    ('f.fuel_nozzles', 'engine.fuel_nozzles',
     ['sym.no_light', 'sym.egt_high'],
     'Yakıt enjektörleri kısmen tıkanmış; alev düzensiz.', 2, BORESCOPE,
     None),
    ('f.fan.fod', 'engine.fan', ['sym.fan_damage', 'sym.engine_vibration'],
     'Fan kanatları yabancı cisim (FOD) çarpmasıyla hasarlanmış.', 3,
     FAN_CHECK, None),
    ('f.hpc.erosion', 'engine.hpc', ['sym.power_loss', 'sym.egt_high'],
     'Kompresör kanatları aşınmış; motor verimi düşmüş.', 2, BORESCOPE,
     None),
    ('f.hpt.blade', 'engine.hpt', ['sym.egt_high', 'sym.engine_vibration'],
     'Yüksek basınç türbini kanatlarında yanma ya da kaplama kaybı.', 3,
     BORESCOPE, None),
    ('f.oil.leak', 'engine.oil', ['sym.oil_low', 'sym.oil_pressure'],
     'Motor yağ sisteminde sızıntı ya da yatak keçesinden kaçak.', 3,
     OIL_CHECK, None),
    ('f.afterburner', 'engine.afterburner', ['sym.ab_no_light'],
     'Art yakıcı ateşlemesi ya da yakıt püskürtme halkası arızalı.', 2,
     NOZZLE, None),
    ('f.nozzle.flaps', 'engine.nozzle', ['sym.nozzle_damage'],
     'Lüle yaprakları ısıdan çatlamış ya da yanmış.', 2, NOZZLE, None),
    ('f.hyd.leak', 'hydraulics', ['sym.hyd_low', 'sym.hyd_leak'],
     'Hidrolik hatta, bağlantıda ya da eyleyicide sızıntı.', 3, HYD_ISOLATE,
     HYD_CHECK),
    ('f.actuator', 'flight_controls.actuators',
     ['sym.flcs_light', 'sym.hyd_leak'],
     'Bir kumanda eyleyicisi sızdırıyor ya da geri bildirimi bozuk.', 3,
     CONTROLS_CHECK, None),
    ('f.speed_brake', 'speed_brakes', ['sym.speedbrake'],
     'Hava freni eyleyicisi ya da menteşesi arızalı.', 2, SPEED_BRAKES,
     None),
    ('f.fuel.water', 'fuel.internal', ['sym.fuel_water'],
     'Tanklarda su birikmiş; yoğuşma ya da kirli yakıt.', 2, FUEL_DRAIN,
     FUEL_DRAIN),
    ('f.cft.seal', 'fuel.cft', ['sym.fuel_leak'],
     'Konformal tank bağlantı contası sızdırıyor.', 2, CFT, None),
    ('f.tire.worn', 'gear.wheels', ['sym.tire_wear', 'sym.pull'],
     'Lastik aşınma sınırına gelmiş.', 2, TIRES, WHEEL_CHANGE),
    ('f.tire.pressure', 'gear.wheels', ['sym.tire_low', 'sym.pull'],
     'Lastik basıncı düşük; supap ya da jant contası kaçırıyor olabilir.',
     2, TIRES, None),
    ('f.brakes.worn', 'gear.brakes', ['sym.brake_pin', 'sym.brake_weak'],
     'Fren diskleri aşınma sınırına gelmiş.', 3, BRAKES, None),
    ('f.strut.service', 'gear.struts', ['sym.strut_low', 'sym.hyd_leak'],
     'Amortisör dikmesi azot ya da yağ kaybetmiş.', 2, MAIN_GEAR, None),
    ('f.nose.torque_link', 'nose_gear', ['sym.shimmy'],
     'Burun iniş takımı tork kolunda boşluk ya da titreşim sönümleyicide '
     'arıza.', 2, GEAR_ISOLATE, None),
    ('f.canopy.seal', 'airframe.canopy', ['sym.canopy_seal'],
     'Kanopi contası yırtılmış ya da sertleşmiş.', 2, CANOPY_CHECK, None),
    ('f.canopy.scratch', 'airframe.canopy', ['sym.canopy_vision'],
     'Kanopi camı kirli ya da yanlış temizlikle çizilmiş.', 1, CANOPY_CHECK,
     CANOPY_CLEAN),
    ('f.radome.erosion', 'airframe.radome', ['sym.radome_damage'],
     'Radom yüzeyi yağmur erozyonu ya da yıldırım çarpmasıyla hasarlanmış.',
     2, RADOME, None),
    ('f.hook.wear', 'tail_hook', ['sym.hook_damage'],
     'Kuyruk kancası ucu aşınmış.', 1, HOOK, None),
]

# Yedek parça adı → IPD'deki parça.
SPARE_PARTS = {
    'Ana tekerlek, lastiğiyle': 'gear.wheels',
}

C.zones, C.symptoms, C.faults = ZONES, SYMPTOMS, FAULTS
C.spare_parts = SPARE_PARTS
C.write()
