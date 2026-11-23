"""Leopard 2A6 şablonunun S1000D içeriğini ve parça haritasını üretir.

    python3 make_content.py

İçerik yalnız genel bakım bilgisidir: seviye kontrolleri, temizlik, sarf
parça değişimleri, gözle muayene ve arıza bulma. Zırh, mühimmat, atış ve
atış kontrol sistemi bilgisi yoktur. Ölçü ve tork değerleri verilmez; DM'ler
değer gereken yerde aracın kendi teknik el kitabına yönlendirir.
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE.parent.parent / 'scripts'))

from s1000d_content import Content  # noqa: E402

# --- SNS ------------------------------------------------------------------

SNS = {
    'D00': ('Araç', {}),
    'DA0': ('Gövde ve kule', {'1': 'Gövde ve kapaklar', '2': 'Kule',
                              '3': 'Motor güvertesi'}),
    'DA1': ('Güç paketi', {'1': 'Motor', '2': 'Yağlama', '3': 'Soğutma',
                           '4': 'Hava emme ve egzoz', '5': 'Yakıt sistemi'}),
    'DA2': ('Güç aktarma', {'1': 'Şanzıman', '2': 'Son dişliler'}),
    'DA3': ('Yürüyen takım', {'1': 'Paletler',
                              '2': 'Yol tekerlekleri ve süspansiyon',
                              '3': 'Avara ve yürütücü dişliler'}),
    'DA4': ('Elektrik sistemi', {'1': 'Aküler', '2': 'Aydınlatma'}),
    'DA5': ('Silah ve optikler', {'1': 'Ana top', '2': 'Optikler'}),
}

# --- Çizimler ---------------------------------------------------------------

# Numara → başlık. Dosyalar `render_icn.py` ile modelden üretilir.
FIGURES = {
    1: 'Tank, soldan görünüş',
    2: 'Güç paketi',
    3: 'Sol yürüyen takım',
    4: 'Motor güvertesi altında soğutma',
    5: 'Kule üstü donanımı',
    6: 'Ön avara ve palet',
}

C = Content(
    HERE, model='NAYATANK',
    applic='Leopard 2A6 ana muharebe tankı',
    product='Leopard 2A6',
    manual='Leopard 2A6 genel bakım el kitabı',
    sns=SNS, figures=FIGURES, liquids=('yağı', 'sıvısı', 'yakıt'))
code, dm, part = C.code, C.dm, C.part

# Her prosedürde tekrarlanan güvenlik uyarıları.
PARKED = 'Tank düz zeminde, motor durdurulmuş, park freni çekili.'
WEAPONS_SAFE = ('Silahların boş ve emniyette olduğu silah sorumlusu '
                'tarafından doğrulanmadan kule üzerinde çalışmayın.')
HOT = ('Motor durduktan sonra güç paketi, egzoz ve radyatörler uzun süre '
       'sıcak kalır; soğumasını bekleyin.')
NO_VALUES = ('Ölçü ve ayar değerleri bu şablonda verilmez; aracın kendi '
             'teknik el kitabındaki değerleri kullanın.')


# --- DM içerikleri ---------------------------------------------------------
#
# Alanlar `templates/scripts/s1000d_content.py` başında anlatılıyor.

# Genel
VEHICLE = dm(
    code=code('D00'), tech='Leopard 2A6', figure=1,
    description=[
        ('Genel', [
            'Leopard 2, Almanya\'da geliştirilen ve birçok ülkenin '
            'kullandığı bir ana muharebe tankıdır. 2A6 sürümü, 2000\'li '
            'yıllarda daha uzun namlulu topla güncellenmiş sürümdür.',
            'Mürettebat dört kişidir: komutan, nişancı, yükleyici ve '
            'sürücü. Sürücü gövdenin önünde sağda; komutan, nişancı ve '
            'yükleyici kulededir.',
        ]),
        ('Sistemler', [
            'Gövde ve kule: kaynaklı çelik gövde, dönen kule, sürücü ve kule '
            'kapakları, yan etekler, motor güvertesi.',
            'Güç paketi: gövdenin arkasında V12 dizel motor, şanzıman, '
            'soğutma sistemi, hava filtreleri ve egzoz. Motor ve şanzıman '
            'tek bir paket olarak birlikte sökülüp takılır.',
            'Yürüyen takım: her yanda yedi yol tekerleği, burulma çubuklu '
            'süspansiyon, önde avara, arkada yürütücü dişli ve lastik '
            'tabanlı paletler.',
            'Elektrik: 24 V doğru akım sistemi, aküler, farlar ve arka '
            'lambalar.',
            'Silah ve optikler: kulede ana top, makineli tüfek, sis bombası '
            'atıcıları ve nişan ile gözetleme optikleri. Bu şablon silah '
            'sistemlerinin yalnız dış muayenesini ve temizliğini kapsar.',
        ]),
        ('Bu el kitabı hakkında', [
            'Bu şablon eğitim amaçlıdır ve yalnız genel bakım bilgisi içerir. '
            + NO_VALUES,
            'Modeldeki güç paketi (motor, şanzıman, soğutma, filtreler, '
            'tanklar) temsilidir; yeri ve görevi doğru, biçimi ve ölçüleri '
            'gerçek değildir.',
        ]),
    ])

DAILY = dm(
    code=code('D00', info='300'), tech='Tank', info='Günlük kontrol',
    figure=1, conditions=[PARKED],
    warnings=[WEAPONS_SAFE],
    steps=[
        ('Çalıştırmadan önce', [
            'Tankın çevresinde dolaşın; altında yağ, yakıt ya da soğutma '
            'sıvısı lekesi olup olmadığına bakın.',
            'Motor yağı, soğutma sıvısı ve şanzıman yağı seviyelerini '
            'kontrol edin.',
            'Paletleri, palet tabanlarını, yol tekerleklerini ve yan '
            'etekleri gözle kontrol edin.',
            'Motor güvertesi ızgaralarının üstünde yaprak, çamur ya da '
            'yabancı cisim kalmadığından emin olun.',
            'Farları, arka lambaları ve sinyalleri yakarak kontrol edin.',
            'Optiklerin koruyucu kapaklarını açın, camların temiz olduğunu '
            'kontrol edin.',
        ]),
        ('Çalıştırdıktan sonra', [
            'Motoru rölantide çalıştırın; yağ basıncı ve akü şarj '
            'göstergelerinin normal bölgeye geldiğini izleyin.',
            'Güç paketinden olağan dışı ses, titreşim ya da duman gelip '
            'gelmediğini dinleyin.',
        ]),
        ('Görevden sonra', [
            'Paletlere ve yürüyen takıma yapışan çamuru ve taşları '
            'temizleyin.',
            'Yol tekerleği göbeklerine elinizin tersiyle dokunun; '
            'diğerlerinden çok daha sıcak olan göbek rulman arızasına '
            'işaret eder.',
            'Yakıt ikmali yapın ve bulunan eksikleri kayda geçirin.',
        ]),
    ])

# Gövde ve kule
HULL = dm(
    code=code('DA0'), tech='Gövde ve kule', figure=1,
    description=[
        ('Gövde', [
            'Gövde, mürettebatı ve güç paketini taşıyan kaynaklı çelik '
            'yapıdır. Önde sürücü bölmesi, ortada savaş bölmesi, arkada '
            'motor bölmesi bulunur.',
            'Yan etekler yürüyen takımın üst kısmını örter; bakım için '
            'parça parça sökülebilir.',
            'Motor güvertesi motor bölmesinin üstünü örter. Izgaralardan '
            'soğutma havası girer; kapaklar güç paketine erişim sağlar.',
        ]),
        ('Kule', [
            'Kule bir yatak üzerinde döner ve ana topu, makineli tüfeği, sis '
            'bombası atıcılarını ve optikleri taşır.',
            'Komutan ve yükleyici kapakları kulenin üstündedir.',
        ]),
    ])

dm(code=code('DA0', '1', '310'), tech='Gövde ve kapaklar', figure=1,
   conditions=[PARKED],
   steps=[
       'Gövdenin dış yüzeyinde çatlak, derin çizik, eğilme ya da gevşek '
       'cıvata olup olmadığını kontrol edin.',
       'Sürücü kapağını açıp kapatın; menteşenin sıkışmadan döndüğünü ve '
       'kilidin kavradığını kontrol edin.',
       'Kapak contalarında yırtık ya da sertleşme olup olmadığına bakın; '
       'conta su ve toz geçirmemelidir.',
       'Çeki kancalarının ve çeki halatının yerinde ve sağlam olduğunu '
       'kontrol edin.',
       'Yan eteklerin bağlantı cıvatalarını kontrol edin; eğilmiş ya da '
       'çatlamış etek parçasını kayda geçirin.',
   ])

TURRET_CHECK = dm(
    code=code('DA0', '2', '310'), tech='Kule üstü donanımı', figure=5,
    conditions=[PARKED, 'Kule kilitli.'],
    warnings=[WEAPONS_SAFE,
              'Kule üstünde çalışırken düşmeye karşı dikkatli olun; ıslak '
              've buzlu yüzeyler kaygandır.'],
    steps=[
        'Komutan ve yükleyici kapaklarını açıp kapatın; menteşe ve '
        'kilitleri kontrol edin.',
        'Sis bombası atıcılarının tüplerinde ezik, çatlak ya da su birikmesi '
        'olup olmadığına dışarıdan bakın. Tüplere elinizi ya da bir cisim '
        'sokmayın.',
        'Makineli tüfek kundağının kule üstündeki bağlantısını gözle kontrol '
        'edin; silahın kendisine dokunmayın.',
        'Antenlerin ve anten tabanlarının sağlam olduğunu kontrol edin.',
        'Bulduğunuz hasarı silah sorumlusuna ve birlik bakım kaydına '
        'bildirin.',
    ])

DECK_CLEAN = dm(
    code=code('DA0', '3', '250'), tech='Motor güvertesi ızgaraları',
    figure=4, conditions=[PARKED, 'Motor soğumuş.'],
    tools=[('Yumuşak kıllı fırça', 1), ('Basınçlı hava tabancası', 1)],
    warnings=[HOT],
    cautions=['Izgaraları sivri bir aletle kazımayın; petek ve kanatçıklar '
              'kolayca ezilir.'],
    steps=[
        'Izgaraların üstündeki yaprak, dal ve çamuru elle ve fırçayla '
        'temizleyin.',
        'Izgara gözlerini içeriden dışarıya basınçlı havayla temizleyin.',
        'Izgaraların bağlantılarını ve kilitlerini kontrol edin.',
        'Tıkanmış ızgara motorun ısınmasına yol açar; arazide sık sık '
        'kontrol edin.',
    ],
    next=code('DA1', '3', '250'))

# Güç paketi
POWERPACK = dm(
    code=code('DA1'), tech='Güç paketi', figure=2,
    description=[
        ('Genel', [
            'Güç paketi gövdenin arka bölümünde durur: önde V12 dizel motor, '
            'arkasında şanzıman. Motor ve şanzıman birbirine bağlı tek bir '
            'paket olarak sökülüp takılır; böylece arızalı paket sahada '
            'kısa sürede yedeğiyle değiştirilebilir.',
            'Motorun iki yanındaki turboşarjlar havayı sıkıştırarak motora '
            'gönderir. Hava, motorun iki yanındaki hava filtrelerinden '
            'geçer.',
        ]),
        ('Soğutma', [
            'Radyatörler ve iki büyük soğutma fanı şanzımanın üstünde, motor '
            'güvertesindeki ızgaraların altındadır. Fanlar havayı '
            'ızgaralardan çekip radyatörlerden geçirir.',
        ]),
        ('Yakıt', [
            'Yakıt tankları motor bölmesinin iki yanındadır. Yakıt, filtreden '
            'geçtikten sonra enjeksiyon pompasına gelir.',
        ]),
    ])

ENGINE_ISOLATE = dm(
    code=code('DA1', info='421'), tech='Motor',
    info='Çalışmıyor: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA1-001',
        'descr': 'Motor çalışmıyor: marş dönmüyor ya da marş dönüyor ama '
                 'motor ateş almıyor.',
        'steps': [
            ('stp-0001', 'Ana şalteri açın ve marşa basın.',
             'Marş motoru dönüyor mu?', 'stp-0003', 'stp-0002'),
            ('stp-0002', 'Akü gerilimini göstergeden ya da voltmetreyle '
             'kontrol edin.', 'Gerilim düşük mü?', 'end-battery',
             'end-starter'),
            ('stp-0003', 'Yakıt göstergesini ve yakıt kesme valfinin '
             'konumunu kontrol edin.', 'Tankta yakıt var ve valf açık mı?',
             'stp-0004', 'end-fuel'),
            ('stp-0004', 'Yakıt filtresinin su ayırıcısında su ya da tortu '
             'olup olmadığına bakın.', 'Filtrede su ya da tortu var mı?',
             'end-filter', 'stp-0005'),
            ('stp-0005', 'Hava filtresi tıkanıklık göstergesine bakın.',
             'Gösterge kırmızı mı?', 'end-air', 'end-service'),
        ],
        'ends': [
            ('end-battery', 'Aküleri şarj edin ya da değiştirin.',
             code('DA4', '1', '300')),
            ('end-starter', 'Aküler dolu ama marş dönmüyor: marş motoru, '
             'rölesi ya da kabloları arızalı olabilir; yetkili bakım '
             'birimine bildirin.', None),
            ('end-fuel', 'Yakıt ikmali yapın ya da kesme valfini açın.',
             code('DA1', '5', '210')),
            ('end-filter', 'Yakıt filtresindeki suyu boşaltın ve filtreyi '
             'kontrol edin.', code('DA1', '5', '300')),
            ('end-air', 'Hava filtresi elemanlarını değiştirin.',
             code('DA1', '4', '920')),
            ('end-service', 'Yakıt, hava ve elektrik normal: enjeksiyon '
             'sistemi ya da motor kontrol ünitesi arızalı olabilir; yetkili '
             'bakım birimine bildirin.', None),
        ],
    })

ENGINE_CHECK = dm(
    code=code('DA1', '1', '310'), tech='Motor', figure=2,
    conditions=[PARKED, 'Motor güvertesi kapakları açık.'],
    warnings=[HOT],
    steps=[
        'Motorun ve turboşarjların çevresinde yağ, yakıt ya da soğutma sıvısı '
        'sızıntısı olup olmadığına bakın.',
        'Hortumların ve kelepçelerin çatlak, şişme ya da gevşeklik '
        'göstermediğini kontrol edin.',
        'Kablo demetlerinin sürtünme izi taşımadığını ve bağlantıların '
        'yerinde olduğunu kontrol edin.',
        'Turboşarj hava bağlantılarında kurum izi varsa hava kaçağı vardır; '
        'kayda geçirin.',
    ])

POWERPACK_CHANGE = dm(
    code=code('DA1', '1', '920'), tech='Güç paketi', figure=2,
    info='Değiştirme (genel akış)',
    tools=[('Güç paketi kaldırma vinci ya da kurtarma aracı', 1),
           ('Kaldırma askısı', 1)],
    spares=[('Güç paketi, yedek', 1)],
    conditions=[PARKED, 'Yetkili bakım birimi ve kaldırma ekibi hazır.'],
    warnings=[HOT, 'Asılı yükün altında durmayın. Kaldırma işini yalnız '
              'eğitimli ekip yapar.'],
    steps=[
        'Ana şalteri kapatın ve akü bağlantısını ayırın.',
        'Motor güvertesini açın ya da sökün.',
        'Güç paketinin yakıt, elektrik, kumanda ve soğutma bağlantılarını '
        'hızlı bağlantı noktalarından ayırın.',
        'Paketin bağlantı cıvatalarını sökün ve son dişlilerle bağlantısını '
        'çözün.',
        'Kaldırma askısını paketin kaldırma noktalarına takın ve paketi '
        'dikey olarak kaldırın.',
        'Yedek paketi aynı yoldan indirin, bağlantıları ters sırayla takın.',
        'Seviyeleri kontrol edin, motoru çalıştırıp kaçak ve gösterge '
        'kontrolü yapın.',
    ])

OIL_CHECK = dm(
    code=code('DA1', '2', '300'), tech='Motor yağı', info='Seviye kontrolü',
    figure=2, conditions=[PARKED, 'Motor durdurulalı birkaç dakika olmuş.'],
    warnings=[HOT],
    steps=[
        'Motor güvertesindeki yağ kontrol kapağını açın.',
        'Yağ çubuğunu çekin, temizleyin, yerine itin ve yeniden çekin.',
        'Yağ izi iki işaret arasında olmalıdır. Eksikse doldurma ağzından '
        'el kitabında belirtilen yağdan tamamlayın.',
        'Yağın rengine bakın: süt gibi açık renkli yağ soğutma sıvısının '
        'yağa karıştığını gösterir; motoru çalıştırmayın ve bildirin.',
    ])

OIL_CHANGE = dm(
    code=code('DA1', '2', '241'), tech='Motor yağı ve yağ filtreleri',
    info='Değişim', figure=2,
    tools=[('Lokma takımı', 1), ('Yağ toplama kabı', 1)],
    supplies=[('Motor yağı', 1)],
    spares=[('Motor yağ filtresi elemanı', 1)],
    conditions=[PARKED, 'Motor çalışma sıcaklığında durdurulmuş.'],
    warnings=['Sıcak yağ yakar. Koruyucu eldiven ve gözlük takın.'],
    cautions=['Atık yağı toprağa dökmeyin; atık yağ kabına toplayın.'],
    steps=[
        'Boşaltma tapasının altına yağ toplama kabını yerleştirin.',
        'Tapayı sökün ve yağın tamamen akmasını bekleyin. Tapayı yeni '
        'contasıyla takın.',
        ('Filtreleri değiştirin', [
            'Filtre kapaklarını açın ve eski elemanları çıkarın.',
            'Filtre yuvalarını temizleyin, yeni elemanları ve contaları '
            'takın.',
        ]),
        'Motoru el kitabında belirtilen miktarda yağla doldurun.',
        'Motoru çalıştırıp yağ basıncının yükseldiğini izleyin; tapada ve '
        'filtrelerde kaçak olmadığını kontrol edin.',
        'Motoru durdurun ve birkaç dakika sonra seviyeyi yeniden kontrol '
        'edin.',
    ])

COOLANT_CHECK = dm(
    code=code('DA1', '3', '300'), tech='Soğutma sıvısı',
    info='Seviye kontrolü', figure=4,
    conditions=[PARKED, 'Motor soğumuş.'],
    warnings=['Soğutma sistemi sıcakken basınç altındadır. Motor soğumadan '
              'doldurma kapağını açmayın.'],
    steps=[
        'Genleşme kabındaki seviyeyi kontrol edin; seviye işaretler '
        'arasında olmalıdır.',
        'Eksikse el kitabında belirtilen antifriz karışımıyla tamamlayın.',
        'Radyatör ve hortum bağlantılarında beyaz kalıntı ya da ıslaklık '
        'olup olmadığına bakın; bunlar sızıntı belirtisidir.',
        'Sık sık eksilme varsa motor yağına bakın; sıvı yağa karışıyor '
        'olabilir.',
    ])

OVERHEAT = dm(
    code=code('DA1', '3', '421'), tech='Soğutma sistemi',
    info='Hararet: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA1-002',
        'descr': 'Motor sıcaklık göstergesi yükseliyor ya da hararet uyarısı '
                 'yanıyor.',
        'steps': [
            ('stp-0001', 'Motoru rölantiye alın, tankı durdurup motoru '
             'soğumaya bırakın. Motor güvertesi ızgaralarına bakın.',
             'Izgaralar yaprak ya da çamurla tıkalı mı?', 'end-grille',
             'stp-0002'),
            ('stp-0002', 'Motor soğuduktan sonra soğutma sıvısı seviyesini '
             'kontrol edin.', 'Seviye düşük mü?', 'end-coolant', 'stp-0003'),
            ('stp-0003', 'Motoru çalıştırın ve fanların döndüğünü '
             'ızgaralardan dinleyin ve hava akışını hissedin.',
             'İki fan da dönüyor mu?', 'end-radiator', 'end-fan'),
        ],
        'ends': [
            ('end-grille', 'Izgaraları temizleyin.', code('DA0', '3', '250')),
            ('end-coolant', 'Soğutma sıvısını tamamlayın ve sızıntıyı '
             'arayın.', code('DA1', '3', '300')),
            ('end-radiator', 'Fanlar çalışıyor: radyatör petekleri kirli '
             'olabilir; temizleyin.', code('DA1', '3', '250')),
            ('end-fan', 'Fan dönmüyor: fan tahriki arızalı olabilir; yetkili '
             'bakım birimine bildirin.', None),
        ],
    })

RADIATOR_CLEAN = dm(
    code=code('DA1', '3', '250'), tech='Radyatörler ve soğutma fanları',
    figure=4,
    tools=[('Basınçlı hava tabancası', 1), ('Yumuşak kıllı fırça', 1)],
    conditions=[PARKED, 'Motor soğumuş.', 'Motor güvertesi açık.'],
    warnings=[HOT, 'Fanlar elle döndürülebilir; motoru çalıştırmadan önce '
              'fan çevresinde alet ve bez kalmadığından emin olun.'],
    cautions=['Radyatör kanatçıklarını ezmeyin; ezilen kanatçık hava '
              'akışını azaltır.'],
    steps=[
        'Radyatör peteklerine yapışan toz ve böcekleri fırçayla alın.',
        'Petekleri hava akışının tersi yönünde basınçlı havayla temizleyin.',
        'Fan kanatlarında çatlak ya da kırık olup olmadığını kontrol edin.',
        'Fanları elle çevirin; sürtünme ya da takılma olmamalıdır.',
        'Motor güvertesini kapatın.',
    ])

AIR_FILTER = dm(
    code=code('DA1', '4', '920'), tech='Hava filtresi elemanları', figure=2,
    tools=[('Lokma takımı', 1)],
    spares=[('Hava filtresi elemanı', 2)],
    conditions=[PARKED, 'Motor güvertesi kapakları açık.'],
    cautions=['Filtre yuvası açıkken içine toz ve yabancı cisim '
              'kaçmamasına dikkat edin.'],
    steps=[
        'Filtre yuvalarının kapaklarını açın.',
        'Eski elemanları dikkatle çıkarın; tozu yuvaya dökmeyin.',
        'Yuvanın içini nemli bezle silin. Toz atma çıkışının açık olduğunu '
        'kontrol edin.',
        'Yeni elemanları takın ve kapakları kapatın.',
        'Tıkanıklık göstergesini sıfırlayın.',
        'Tozlu arazide filtreler çok daha çabuk tıkanır; göstergeyi her gün '
        'kontrol edin.',
    ])

EXHAUST_CHECK = dm(
    code=code('DA1', '4', '310'), tech='Egzoz', figure=2,
    conditions=[PARKED, 'Motor soğumuş.'],
    warnings=[HOT],
    steps=[
        'Egzoz borularında çatlak, gevşek kelepçe ya da kurum izi olup '
        'olmadığına bakın.',
        'Gövde arkasındaki egzoz çıkışlarının tıkalı olmadığını kontrol '
        'edin.',
        'Motor çalışırken çıkan dumanın rengine dikkat edin: siyah duman '
        'hava eksikliği ya da aşırı yakıt, mavi duman yağ yanması, beyaz '
        'duman soğutma sıvısı ya da soğuk motor belirtisidir.',
    ])

REFUEL = dm(
    code=code('DA1', '5', '210'), tech='Yakıt', info='İkmal',
    supplies=[('Dizel yakıt', 1)],
    conditions=[PARKED, 'Yangın söndürücü hazır.'],
    warnings=['İkmal sırasında sigara içmeyin ve açık alev bulundurmayın.',
              'İkmal aracını ve tankı topraklayın.'],
    steps=[
        'Ana şalteri kapatın.',
        'Yakıt doldurma kapaklarını açın; ağızların çevresini temizleyin.',
        'Tankları doldurun; ağızdan taşırmayın.',
        'Kapakları kapatın, dökülen yakıtı silin.',
    ])

FUEL_CHECK = dm(
    code=code('DA1', '5', '300'), tech='Yakıt sistemi', figure=2,
    tools=[('Toplama kabı', 1)],
    conditions=[PARKED],
    warnings=['Yakıt buharı yanıcıdır; çevrede açık alev bulundurmayın.'],
    steps=[
        'Yakıt filtresinin su ayırıcısındaki boşaltma vidasını açın.',
        'Su ve tortu bitip temiz yakıt gelene kadar boşaltın; vidayı '
        'kapatın.',
        'Yakıt borularında ve tank bağlantılarında sızıntı olup olmadığına '
        'bakın.',
        'Su sık sık birikiyorsa yakıt kaynağını ve tank kapaklarının '
        'contalarını kontrol edin.',
    ])

# Güç aktarma
TRANSMISSION = dm(
    code=code('DA2'), tech='Güç aktarma', figure=2,
    description=[
        ('Genel', [
            'Otomatik şanzıman motorun gücünü iki yandaki son dişlilere '
            'iletir. Tankın dönüşü de şanzımandan yönetilir: bir yandaki '
            'paleti yavaşlatarak tank yön değiştirir.',
            'Servis frenleri şanzımanın içindedir. Son dişliler, şanzımanın '
            'çıkışını yürütücü dişlilere aktaran redüktörlerdir.',
        ]),
    ])

dm(code=code('DA2', '1', '300'), tech='Şanzıman yağı',
   info='Seviye kontrolü', figure=2,
   conditions=[PARKED, 'Şanzıman el kitabında belirtilen sıcaklıkta.'],
   warnings=[HOT],
   steps=[
       'Şanzıman yağı kontrol kapağını açın.',
       'Seviyeyi çubuktan okuyun; el kitabında belirtilen işaretler arasında '
       'olmalıdır.',
       'Eksikse belirtilen yağdan tamamlayın. Yağda yanık kokusu ya da '
       'metal parçacıkları varsa bildirin.',
   ])

dm(code=code('DA2', '2', '300'), tech='Son dişliler',
   info='Yağ seviyesi kontrolü', figure=3,
   conditions=[PARKED],
   tools=[('Lokma takımı', 1)],
   steps=[
       'Son dişlinin seviye tapasını sökün.',
       'Yağ, tapa deliğinin alt kenarına kadar olmalıdır; eksikse '
       'tamamlayın.',
       'Yürütücü dişlinin iç tarafında yağ izi varsa keçe sızdırıyordur; '
       'kayda geçirin.',
       'Tapayı takın. İki yanı da kontrol edin.',
   ])

# Yürüyen takım
RUNNING_GEAR = dm(
    code=code('DA3'), tech='Yürüyen takım', figure=3,
    description=[
        ('Genel', [
            'Her yanda yedi çift yol tekerleği vardır. Tekerlekler burulma '
            'çubuklarına bağlı salıncak kollarıyla gövdeye bağlanır; bazı '
            'kollarda ayrıca amortisör bulunur.',
            'Palet önde avaradan, arkada yürütücü dişliden döner. Yürütücü '
            'dişli son dişliden güç alır; avara palet gerginliğini ayarlar.',
            'Palet, birbirine pimle bağlanan çelik baklalardan oluşur. '
            'Baklaların altındaki lastik tabanlar asfaltı korur ve aşındıkça '
            'değiştirilir.',
        ]),
    ])

RUNNING_ISOLATE = dm(
    code=code('DA3', info='421'), tech='Yürüyen takım',
    info='Palet ve tekerlek sorunları: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA3-001',
        'descr': 'Palet atıyor ya da gevşek, yürüyen takımdan vuruntu sesi '
                 'geliyor ya da tank bir yana çekiyor.',
        'steps': [
            ('stp-0001', 'Tankı durdurun ve paletin üst kolundaki sarkmaya '
             'bakın.', 'Palet belirgin şekilde sarkık mı?', 'end-tension',
             'stp-0002'),
            ('stp-0002', 'Yürütücü dişlinin dişlerine bakın.',
             'Dişler sivrilmiş ya da kancalaşmış mı?', 'end-sprocket',
             'stp-0003'),
            ('stp-0003', 'Yol tekerleklerinin lastik bandajlarına ve '
             'göbeklerine bakın.',
             'Bandajda kopuk parça ya da göbekte yağ izi var mı?',
             'end-wheel', 'stp-0004'),
            ('stp-0004', 'Palet tabanlarını kontrol edin.',
             'Tabanlar aşınma sınırında ya da eksik mi?', 'end-pads',
             'end-service'),
        ],
        'ends': [
            ('end-tension', 'Palet gerginliğini ayarlayın.',
             code('DA3', '1', '271')),
            ('end-sprocket', 'Yürütücü dişliyi ve avarayı muayene edin.',
             code('DA3', '3', '310')),
            ('end-wheel', 'Yol tekerleklerini ve süspansiyonu muayene edin.',
             code('DA3', '2', '310')),
            ('end-pads', 'Palet tabanlarını değiştirin.',
             code('DA3', '1', '920')),
            ('end-service', 'Görünür bir sorun yok: burulma çubukları ya da '
             'son dişliler arızalı olabilir; yetkili bakım birimine '
             'bildirin.', None),
        ],
    })

TRACK_TENSION = dm(
    code=code('DA3', '1', '271'), tech='Palet gerginliği', figure=6,
    tools=[('Palet gerdirme anahtarı', 1), ('Gres pompası', 1),
           ('Cetvel', 1)],
    supplies=[('Gres', 1)],
    conditions=[PARKED, 'Tank düz ve sert zeminde; palet üst kolu '
                'çekilmiş (tank kısa bir mesafe ileri sürülüp durdurulmuş).'],
    warnings=['Gerdirme silindirindeki gres yüksek basınç altındadır. '
              'Boşaltma valfini yavaşça açın ve önünde durmayın.'],
    steps=[
        'Paletin üst kolundaki sarkmayı iki tekerlek arasında cetvelle '
        'ölçün. ' + NO_VALUES,
        ('Gerginlik azsa', [
            'Avaranın gerdirme silindirine gres pompasıyla gres basın.',
            'Avara öne doğru ilerler ve palet gerilir.',
        ]),
        ('Gerginlik fazlaysa', [
            'Boşaltma valfini yavaşça açıp bir miktar gres boşaltın.',
            'Valfi kapatın.',
        ]),
        'Tankı kısa bir mesafe sürüp yeniden ölçün. İki paleti de kontrol '
        'edin.',
        'Gerginlik sık sık azalıyorsa gerdirme silindiri sızdırıyordur.',
    ])

TRACK_CHECK = dm(
    code=code('DA3', '1', '310'), tech='Paletler', figure=3,
    conditions=[PARKED],
    steps=[
        'Palet baklalarında çatlak ya da kırık olup olmadığını kontrol edin.',
        'Bakla pimlerinin ve bağlantı cıvatalarının yerinde olduğunu '
        'kontrol edin.',
        'Palet tabanlarının aşınmasına bakın; kopmuş ya da aşınma sınırına '
        'gelmiş tabanları işaretleyin.',
        'Paletin iç yüzündeki kılavuz dişlerde aşınma ya da eğilme olup '
        'olmadığını kontrol edin.',
    ])

TRACK_PADS = dm(
    code=code('DA3', '1', '920'), tech='Palet tabanları', figure=3,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Palet tabanı', 8)],
    conditions=[PARKED],
    steps=[
        'Değiştirilecek tabanı paletin alt koluna gelmeyecek şekilde, '
        'erişilebilir bir yere getirin.',
        'Tabanın bağlantı somununu sökün ve eski tabanı çıkarın.',
        'Yuvayı temizleyin, yeni tabanı takın.',
        'Somunu el kitabında belirtilen torkta sıkın.',
        'Kısa bir sürüşten sonra somunları yeniden kontrol edin.',
    ])

ROAD_WHEELS = dm(
    code=code('DA3', '2', '310'), tech='Yol tekerlekleri ve süspansiyon',
    figure=3, conditions=[PARKED],
    steps=[
        'Yol tekerleklerinin lastik bandajlarında kopma, yırtık ya da ayrılma '
        'olup olmadığını kontrol edin.',
        'Tekerlek göbeklerinde yağ sızıntısı olup olmadığına bakın; göbek '
        'kapaklarının yerinde olduğunu kontrol edin.',
        'Sürüşten hemen sonra göbek sıcaklıklarını karşılaştırın; çok sıcak '
        'göbek rulman arızasına işaret eder.',
        'Salıncak kollarında çatlak, amortisörlerde yağ sızıntısı olup '
        'olmadığını kontrol edin.',
        'Tekerleklerden birinin diğerlerinden belirgin şekilde yukarıda ya da '
        'aşağıda durması kırık burulma çubuğuna işaret eder; bildirin.',
    ])

SPROCKET = dm(
    code=code('DA3', '3', '310'), tech='Avara ve yürütücü dişliler',
    figure=6, conditions=[PARKED],
    steps=[
        'Yürütücü dişli dişlerinin profilini kontrol edin; dişler sivrilmiş '
        'ya da kancalaşmışsa palet atlamaya başlar.',
        'Dişli çemberlerinin bağlantı cıvatalarını kontrol edin.',
        'Avara tekerleğinin bandajını ve göbeğini kontrol edin.',
        'Avara gerdirme silindirinde gres sızıntısı olup olmadığına bakın.',
    ])

# Elektrik
BATTERY_CHECK = dm(
    code=code('DA4', '1', '300'), tech='Aküler', info='Kontrol',
    conditions=[PARKED, 'Ana şalter kapalı.'],
    tools=[('Voltmetre', 1), ('Kutup başı fırçası', 1)],
    warnings=['Akü asidi yakıcıdır; gözlük ve eldiven takın.',
              'Akülerin yakınında kıvılcım çıkarmayın; şarj sırasında '
              'patlayıcı gaz çıkar.'],
    steps=[
        'Akü bölmesinin kapağını açın.',
        'Kutup başlarında oksitlenme ve gevşeklik olup olmadığına bakın; '
        'gerekiyorsa temizleyin.',
        'Akü gerilimini ölçün ve el kitabındaki değerle karşılaştırın.',
        'Akü kutularında çatlak ya da sızıntı olup olmadığını kontrol edin.',
        'Kapağı kapatın.',
    ])

BATTERY = dm(
    code=code('DA4', '1', '920'), tech='Akü',
    tools=[('Lokma takımı', 1)],
    spares=[('Akü, 12 V', 1)],
    conditions=[PARKED, 'Ana şalter kapalı.'],
    warnings=['Önce eksi (−) kutup başını sökün, en son takın; kısa devre '
              'riskini azaltır.', 'Aküler ağırdır; iki kişiyle taşıyın.'],
    steps=[
        'Akü bölmesini açın.',
        'Eksi kablolarını, sonra artı kablolarını sökün.',
        'Tutucuları gevşetin ve aküyü çıkarın.',
        'Yeni aküyü yerleştirin, tutucuları sıkın.',
        'Önce artı, sonra eksi kablolarını takın; kutup başlarına koruyucu '
        'sürün.',
        'Ana şalteri açıp gerilimi kontrol edin.',
    ])

LIGHTS = dm(
    code=code('DA4', '2', '920'), tech='Farlar ve lambalar',
    tools=[('Tornavida takımı', 1)],
    spares=[('Far ampulü, 24 V', 1)],
    conditions=[PARKED, 'Aydınlatma anahtarı kapalı.'],
    steps=[
        'Lamba muhafazasının vidalarını sökün ve muhafazayı çıkarın.',
        'Arızalı ampulü çıkarın; yuvada oksitlenme varsa temizleyin.',
        'Yeni ampulü takın, cama çıplak elle dokunmayın.',
        'Muhafazayı contasıyla takın ve lambayı yakarak kontrol edin.',
    ])

# Silah ve optikler
WEAPONS = dm(
    code=code('DA5'), tech='Silah ve optikler', figure=5,
    description=[
        ('Genel', [
            'Kule ana topu, ana topa eş eksenli bir makineli tüfeği, '
            'yükleyici kapağındaki makineli tüfeği ve iki yandaki sis '
            'bombası atıcılarını taşır.',
            'Nişancının ve komutanın nişan optikleri kulenin üstündedir; '
            'sürücünün periskopları gövdenin önündedir.',
        ]),
        ('Bu şablonun kapsamı', [
            'Bu şablon silahların yalnız dış muayenesini ve optiklerin '
            'temizliğini kapsar. Silahların sökülmesi, ayarı ve atışla ilgili '
            'her iş yalnız yetkili silah personelince, aracın kendi '
            'el kitabına göre yapılır.',
        ]),
    ])

dm(code=code('DA5', '1', '310'), tech='Ana top', info='Dış muayene',
   figure=1, conditions=[PARKED, 'Kule ve top kilitli.'],
   warnings=[WEAPONS_SAFE],
   steps=[
       'Namlu ağzı koruyucu kapağının takılı ve sağlam olduğunu kontrol '
       'edin.',
       'Namlunun dış yüzeyinde ve ısı kılıfında ezik, yırtık ya da gevşek '
       'parça olup olmadığına bakın.',
       'Top kalkanının çevresindeki toz körüğünde yırtık olup olmadığını '
       'kontrol edin.',
       'Bulduğunuz hasarı silah sorumlusuna bildirin; namluya ya da '
       'mekanizmaya müdahale etmeyin.',
   ])

OPTICS_CLEAN = dm(
    code=code('DA5', '2', '250'), tech='Optik camları', figure=5,
    tools=[('Yumuşak kıllı optik fırçası', 1)],
    supplies=[('Optik temizleme bezi', 2), ('Optik temizleme sıvısı', 1)],
    conditions=[PARKED],
    cautions=['Optik camlarını kuru bezle ovmayın; toz taneleri camı ve '
              'kaplamasını çizer.',
              'Benzin, tiner gibi çözücüler kullanmayın.'],
    steps=[
        'Koruyucu kapakları açın.',
        'Camdaki tozu önce fırçayla ya da hava pompasıyla alın.',
        'Temizleme sıvısıyla nemlendirdiğiniz bezle camı ortadan kenara '
        'doğru silin.',
        'Sürücü periskoplarının dış camlarını da aynı şekilde temizleyin.',
        'Kullanmadığınız zaman koruyucu kapakları kapalı tutun.',
    ])


# --- Parça haritası --------------------------------------------------------

# Düğümü olmayan parçalar içinde bulundukları düğüme bağlı.

POWERPACK_NODES = ['engine', 'transmission', 'radiators', 'cooling_fans',
                   'air_filters', 'exhaust']
TRACKS = ['track_l', 'track_r']
WHEELS = ['road_wheels_l', 'road_wheels_r']
SUSPENSION = ['suspension_l', 'suspension_r']
IDLERS = ['idler_l', 'idler_r']
SPROCKETS = ['sprocket_l', 'sprocket_r']

part('hull', 'Gövde', None, 'DA0-10',
     ['hull', 'engine_deck', 'side_skirt_l', 'side_skirt_r'], 'z.hull',
     'Mürettebatı, güç paketini ve kuleyi taşıyan kaynaklı çelik yapı.',
     {'inspect': code('DA0', '1', '310')})
part('hull.engine_deck', 'Motor güvertesi', 'hull', 'DA0-30',
     ['engine_deck'], 'z.engine',
     'Motor bölmesinin üstünü örter; ızgaralardan soğutma havası girer.',
     {'clean': DECK_CLEAN})
part('hull.side_skirt_l', 'Sol yan etek', 'hull', 'DA0-10', ['side_skirt_l'],
     'z.running', 'Sol yürüyen takımın üstünü örten sökülebilir paneller.',
     {'inspect': code('DA0', '1', '310')})
part('hull.side_skirt_r', 'Sağ yan etek', 'hull', 'DA0-10', ['side_skirt_r'],
     'z.running', 'Sağ yürüyen takımın üstünü örten sökülebilir paneller.',
     {'inspect': code('DA0', '1', '310')})
part('hull.driver_hatch', 'Sürücü kapağı', 'hull', 'DA0-10', ['hull'],
     'z.driver', 'Sürücü bölmesinin üstündeki kapak ve periskoplar.',
     {'inspect': code('DA0', '1', '310')})
part('hull.towing', 'Çeki kancaları ve halatı', 'hull', 'DA0-10', ['hull'],
     'z.hull', 'Tankın çekilmesi ve kurtarılması için ön ve arka kancalar.',
     {'inspect': code('DA0', '1', '310')}, quantity=4)

part('turret', 'Kule', None, 'DA0-20',
     ['turret', 'main_gun', 'optics', 'machine_gun', 'smoke_dischargers'],
     'z.turret', 'Dönen kule; silahları, optikleri ve üç mürettebatı taşır.',
     {'inspect': TURRET_CHECK})
part('turret.hatches', 'Komutan ve yükleyici kapakları', 'turret', 'DA0-20',
     ['turret'], 'z.turret', 'Kule üstündeki iki mürettebat kapağı.',
     {'inspect': TURRET_CHECK}, quantity=2)
part('turret.main_gun', 'Ana top', 'turret', 'DA5-10', ['main_gun'],
     'z.turret', 'Kulenin önündeki top; namlu, ısı kılıfı ve top kalkanı.',
     {'inspect': code('DA5', '1', '310')})
part('turret.optics', 'Nişan ve gözetleme optikleri', 'turret', 'DA5-20',
     ['optics'], 'z.turret',
     'Nişancının ve komutanın kule üstündeki optikleri.',
     {'clean': OPTICS_CLEAN})
part('turret.machine_gun', 'Makineli tüfek', 'turret', 'DA5-10',
     ['machine_gun'], 'z.turret', 'Yükleyici kapağındaki kundağa takılı.',
     {'inspect': TURRET_CHECK})
part('turret.smoke_dischargers', 'Sis bombası atıcıları', 'turret', 'DA0-20',
     ['smoke_dischargers'], 'z.turret',
     'Kulenin iki yanındaki atıcı tüpleri; tankı sis perdesiyle gizler.',
     {'inspect': TURRET_CHECK}, quantity=2)

part('powerpack', 'Güç paketi', None, 'DA1-00', POWERPACK_NODES, 'z.engine',
     'Motor ve şanzımandan oluşan, tek parça sökülüp takılan paket.',
     {'replace': POWERPACK_CHANGE, 'isolate': ENGINE_ISOLATE})
part('engine', 'Motor', 'powerpack', 'DA1-10', ['engine'], 'z.engine',
     'Turboşarjlı V12 dizel motor.',
     {'inspect': ENGINE_CHECK, 'isolate': ENGINE_ISOLATE})
part('engine.turbochargers', 'Turboşarjlar', 'engine', 'DA1-40', ['engine'],
     'z.engine', 'Egzoz gazıyla dönüp motora sıkıştırılmış hava gönderir.',
     {'inspect': ENGINE_CHECK}, quantity=2)
part('engine.oil', 'Motor yağı ve yağ filtreleri', 'engine', 'DA1-20',
     ['engine'], 'z.engine',
     'Yataklara ve hareketli parçalara yağ basar; filtreler yağı temizler.',
     {'inspect': OIL_CHECK, 'lubricate': OIL_CHANGE})
part('engine.starter', 'Marş motoru', 'engine', 'DA1-10', ['engine'],
     'z.engine', 'Motoru ilk çalıştırmada döndürür.',
     {'isolate': ENGINE_ISOLATE})
part('engine.generator', 'Jeneratör', 'engine', 'DA4-10', ['engine'],
     'z.engine', 'Motor çalışırken aküleri şarj eder ve elektrik sağlar.',
     {'inspect': BATTERY_CHECK})
part('cooling', 'Soğutma sistemi', 'powerpack', 'DA1-30',
     ['radiators', 'cooling_fans'], 'z.engine',
     'Motorun ve şanzımanın ısısını havaya atar.',
     {'isolate': OVERHEAT, 'inspect': COOLANT_CHECK})
part('cooling.radiators', 'Radyatörler', 'cooling', 'DA1-30', ['radiators'],
     'z.engine', 'Soğutma sıvısını fanların çektiği havayla soğutur.',
     {'clean': RADIATOR_CLEAN})
part('cooling.fans', 'Soğutma fanları', 'cooling', 'DA1-30',
     ['cooling_fans'], 'z.engine',
     'Motor güvertesi ızgaralarından havayı çekip radyatörlerden geçirir.',
     {'clean': RADIATOR_CLEAN}, quantity=2)
part('air_filters', 'Hava filtreleri', 'powerpack', 'DA1-40',
     ['air_filters'], 'z.engine',
     'Motora giren havadaki tozu tutar; toz atma çıkışı tozu dışarı atar.',
     {'replace': AIR_FILTER}, quantity=2)
part('exhaust', 'Egzoz', 'powerpack', 'DA1-40', ['exhaust'], 'z.engine',
     'Egzoz gazını turboşarjlardan gövdenin arkasına taşır.',
     {'inspect': EXHAUST_CHECK})
part('transmission', 'Şanzıman', 'powerpack', 'DA2-10', ['transmission'],
     'z.engine',
     'Otomatik şanzıman; vitesleri ve tankın dönüşünü yönetir.',
     {'inspect': code('DA2', '1', '300')})
part('transmission.brakes', 'Servis frenleri', 'transmission', 'DA2-10',
     ['transmission'], 'z.engine', 'Şanzımanın içindeki fren tertibatı.')
part('transmission.final_drives', 'Son dişliler', 'transmission', 'DA2-20',
     ['transmission'], 'z.engine',
     'Şanzımanın çıkışını iki yandaki yürütücü dişlilere aktarır.',
     {'inspect': code('DA2', '2', '300')}, quantity=2)

part('fuel', 'Yakıt sistemi', None, 'DA1-50', ['fuel_tanks'], 'z.engine',
     'Yakıt tankları, filtreler ve borular.',
     {'inspect': FUEL_CHECK, 'refill': REFUEL})
part('fuel.tanks', 'Yakıt tankları', 'fuel', 'DA1-50', ['fuel_tanks'],
     'z.engine', 'Motor bölmesinin iki yanındaki dizel yakıt tankları.',
     {'refill': REFUEL}, quantity=2)
part('fuel.filter', 'Yakıt filtresi ve su ayırıcı', 'fuel', 'DA1-50',
     ['fuel_tanks'], 'z.engine',
     'Yakıttaki suyu ve tortuyu enjeksiyon sistemine ulaşmadan tutar.',
     {'inspect': FUEL_CHECK})

part('running_gear', 'Yürüyen takım', None, 'DA3-00',
     [*TRACKS, *WHEELS, *SUSPENSION, *IDLERS, *SPROCKETS], 'z.running',
     'Paletler, yol tekerlekleri, süspansiyon, avaralar ve yürütücü '
     'dişliler.', {'isolate': RUNNING_ISOLATE})
part('track_l', 'Sol palet', 'running_gear', 'DA3-10', ['track_l'],
     'z.running', 'Pimle bağlı çelik baklalar ve lastik tabanlar.',
     {'inspect': TRACK_CHECK, 'adjust': TRACK_TENSION})
part('track_r', 'Sağ palet', 'running_gear', 'DA3-10', ['track_r'],
     'z.running', 'Pimle bağlı çelik baklalar ve lastik tabanlar.',
     {'inspect': TRACK_CHECK, 'adjust': TRACK_TENSION})
part('tracks.pads', 'Palet tabanları', 'running_gear', 'DA3-10', TRACKS,
     'z.running', 'Baklaların altındaki lastik tabanlar; yolu korur.',
     {'replace': TRACK_PADS})
part('road_wheels_l', 'Sol yol tekerlekleri', 'running_gear', 'DA3-20',
     ['road_wheels_l'], 'z.running',
     'Yedi çift lastik bandajlı tekerlek; tankın ağırlığını paletlere '
     'aktarır.', {'inspect': ROAD_WHEELS}, quantity=7)
part('road_wheels_r', 'Sağ yol tekerlekleri', 'running_gear', 'DA3-20',
     ['road_wheels_r'], 'z.running',
     'Yedi çift lastik bandajlı tekerlek; tankın ağırlığını paletlere '
     'aktarır.', {'inspect': ROAD_WHEELS}, quantity=7)
part('suspension', 'Süspansiyon', 'running_gear', 'DA3-20', SUSPENSION,
     'z.running',
     'Burulma çubuklarına bağlı salıncak kolları ve amortisörler.',
     {'inspect': ROAD_WHEELS})
part('suspension.dampers', 'Amortisörler', 'suspension', 'DA3-20',
     SUSPENSION, 'z.running', 'Tekerleklerin salınımını sönümler.',
     {'inspect': ROAD_WHEELS})
part('idlers', 'Avara tekerlekleri', 'running_gear', 'DA3-30', IDLERS,
     'z.running', 'Önde paleti döndürür ve gerginliğini ayarlar.',
     {'inspect': SPROCKET, 'adjust': TRACK_TENSION}, quantity=2)
part('idlers.tensioner', 'Palet gerdirme silindirleri', 'idlers', 'DA3-30',
     IDLERS, 'z.running',
     'Gres basılarak avarayı öne iten ve paleti geren silindir.',
     {'adjust': TRACK_TENSION}, quantity=2)
part('sprockets', 'Yürütücü dişliler', 'running_gear', 'DA3-30', SPROCKETS,
     'z.running', 'Arkada son dişliden güç alıp paleti döndürür.',
     {'inspect': SPROCKET}, quantity=2)

part('electrical', 'Elektrik sistemi', None, 'DA4-00',
     ['batteries', 'headlights', 'taillights'], 'z.hull',
     '24 V doğru akım sistemi: aküler, jeneratör, aydınlatma.',
     {'inspect': BATTERY_CHECK})
part('electrical.batteries', 'Aküler', 'electrical', 'DA4-10',
     ['batteries'], 'z.driver',
     'Sürücü bölmesindeki akü kutuları; marş ve motor dururken elektrik.',
     {'inspect': BATTERY_CHECK, 'replace': BATTERY}, quantity=4)
part('electrical.headlights', 'Farlar', 'electrical', 'DA4-20',
     ['headlights'], 'z.hull', 'Gövdenin önündeki far ve sinyal lambaları.',
     {'replace': LIGHTS}, quantity=2)
part('electrical.taillights', 'Arka lambalar', 'electrical', 'DA4-20',
     ['taillights'], 'z.hull', 'Gövdenin arkasındaki stop ve konvoy '
     'lambaları.', {'replace': LIGHTS}, quantity=2)

ZONES = [
    ('z.hull', 'Gövde', None),
    ('z.driver', 'Sürücü bölmesi', 'z.hull'),
    ('z.engine', 'Motor bölmesi', 'z.hull'),
    ('z.turret', 'Kule', None),
    ('z.running', 'Yürüyen takım', None),
]

# --- Arızalar ---------------------------------------------------------------

SYMPTOMS = [
    ('sym.no_start', 'Motor çalışmıyor'),
    ('sym.slow_crank', 'Marş ağır dönüyor'),
    ('sym.power_loss', 'Motor çekmiyor, tank hızlanmıyor'),
    ('sym.black_smoke', 'Egzozdan siyah duman çıkıyor'),
    ('sym.blue_smoke', 'Egzozdan mavi duman çıkıyor'),
    ('sym.whistle', 'Güç paketinden ıslık sesi geliyor'),
    ('sym.overheat', 'Motor sıcaklığı yükseliyor'),
    ('sym.coolant_loss', 'Soğutma sıvısı eksiliyor'),
    ('sym.oil_pressure', 'Yağ basıncı uyarısı yanıyor'),
    ('sym.oil_leak', 'Motor bölmesinin altına yağ damlıyor'),
    ('sym.air_filter_light', 'Hava filtresi göstergesi kırmızı'),
    ('sym.water_in_fuel', 'Yakıt filtresinde su birikiyor'),
    ('sym.shift', 'Vitesler sert ya da geç geçiyor'),
    ('sym.sprocket_leak', 'Yürütücü dişlinin iç tarafında yağ izi var'),
    ('sym.brake_weak', 'Fren zayıf tutuyor'),
    ('sym.track_slack', 'Palet sarkık, palet atıyor'),
    ('sym.track_noise', 'Yürüyen takımdan vuruntu ya da şıkırtı geliyor'),
    ('sym.vibration', 'Asfaltta sürüşte titreşim artmış'),
    ('sym.hot_hub', 'Bir yol tekerleği göbeği çok ısınıyor'),
    ('sym.rubber_loss', 'Tekerlek bandajından lastik parçaları kopuyor'),
    ('sym.pitching', 'Tank engebede aşırı yalpalıyor'),
    ('sym.pull', 'Tank bir yana çekiyor'),
    ('sym.dim_lights', 'Farlar sönük yanıyor'),
    ('sym.light_out', 'Bir lamba yanmıyor'),
    ('sym.blurry_optics', 'Optikten görüntü bulanık'),
]

# (id, parça, belirtiler, neden, önem 1-3, arıza bulma, onarım)
FAULTS = [
    ('f.batteries.flat', 'electrical.batteries',
     ['sym.no_start', 'sym.slow_crank', 'sym.dim_lights'],
     'Aküler boşalmış ya da ömrünü doldurmuş.', 2, ENGINE_ISOLATE, BATTERY),
    ('f.generator.failed', 'engine.generator', ['sym.dim_lights'],
     'Jeneratör aküleri şarj etmiyor.', 2, BATTERY_CHECK, None),
    ('f.fuel.water', 'fuel.filter', ['sym.water_in_fuel', 'sym.power_loss',
                                     'sym.no_start'],
     'Yakıta su karışmış; filtre ve su ayırıcı dolmuş.', 2, ENGINE_ISOLATE,
     FUEL_CHECK),
    ('f.air_filter.clogged', 'air_filters',
     ['sym.air_filter_light', 'sym.power_loss', 'sym.black_smoke'],
     'Hava filtresi elemanları tozla tıkanmış.', 1, ENGINE_ISOLATE,
     AIR_FILTER),
    ('f.turbo.leak', 'engine.turbochargers',
     ['sym.whistle', 'sym.power_loss', 'sym.black_smoke'],
     'Turboşarj hava bağlantısında kaçak var.', 2, ENGINE_CHECK, None),
    ('f.engine.oil_burning', 'engine', ['sym.blue_smoke', 'sym.oil_pressure'],
     'Motor yağ yakıyor; turboşarj keçeleri ya da segmanlar aşınmış '
     'olabilir.', 3, OIL_CHECK, None),
    ('f.oil.low', 'engine.oil', ['sym.oil_pressure', 'sym.oil_leak'],
     'Motor yağı eksik ya da bir conta sızdırıyor.', 3, OIL_CHECK,
     OIL_CHANGE),
    ('f.grilles.blocked', 'hull.engine_deck', ['sym.overheat'],
     'Motor güvertesi ızgaraları yaprak ya da çamurla tıkanmış.', 2,
     OVERHEAT, DECK_CLEAN),
    ('f.radiator.dirty', 'cooling.radiators', ['sym.overheat'],
     'Radyatör petekleri toz ve kirle kaplanmış.', 2, OVERHEAT,
     RADIATOR_CLEAN),
    ('f.fan.drive', 'cooling.fans', ['sym.overheat'],
     'Soğutma fanlarından biri dönmüyor; fan tahriki arızalı.', 3, OVERHEAT,
     None),
    ('f.coolant.leak', 'cooling', ['sym.coolant_loss', 'sym.overheat'],
     'Soğutma sisteminde hortum ya da bağlantı sızdırıyor.', 2, OVERHEAT,
     COOLANT_CHECK),
    ('f.transmission.oil', 'transmission', ['sym.shift'],
     'Şanzıman yağı eksik ya da eskimiş.', 2, code('DA2', '1', '300'), None),
    ('f.brakes.worn', 'transmission.brakes', ['sym.brake_weak'],
     'Servis frenleri aşınmış.', 3, None, None),
    ('f.final_drive.seal', 'transmission.final_drives',
     ['sym.sprocket_leak', 'sym.track_noise'],
     'Son dişli keçesi sızdırıyor; yağ eksilirse dişliler aşınır.', 2,
     code('DA2', '2', '300'), None),
    ('f.track.slack', 'idlers.tensioner', ['sym.track_slack', 'sym.track_noise'],
     'Palet gerginliği azalmış; gerdirme silindiri gres kaçırıyor '
     'olabilir.', 3, RUNNING_ISOLATE, TRACK_TENSION),
    ('f.pads.worn', 'tracks.pads', ['sym.vibration', 'sym.track_noise'],
     'Palet tabanları aşınmış ya da kopmuş.', 1, RUNNING_ISOLATE, TRACK_PADS),
    ('f.wheel.bearing', 'road_wheels_l', ['sym.hot_hub', 'sym.track_noise'],
     'Yol tekerleği rulmanı aşınmış ya da göbekte yağ kalmamış.', 2,
     ROAD_WHEELS, None),
    ('f.wheel.tyre', 'road_wheels_r', ['sym.rubber_loss', 'sym.vibration'],
     'Yol tekerleğinin lastik bandajı parçalanıyor.', 2, ROAD_WHEELS, None),
    ('f.damper.leak', 'suspension.dampers', ['sym.pitching', 'sym.pull'],
     'Amortisör yağını kaçırmış; sönümleme yok.', 2, ROAD_WHEELS, None),
    ('f.sprocket.worn', 'sprockets', ['sym.track_slack', 'sym.track_noise'],
     'Yürütücü dişli dişleri aşınmış; palet atlıyor.', 2, SPROCKET, None),
    ('f.lights.bulb', 'electrical.headlights', ['sym.light_out'],
     'Ampul yanmış ya da soket oksitlenmiş.', 1, None, LIGHTS),
    ('f.optics.dirty', 'turret.optics', ['sym.blurry_optics'],
     'Optik camı kirli ya da nemlenmiş.', 1, None, OPTICS_CLEAN),
]

# Yedek parça adı → IPD'deki parça.
SPARE_PARTS = {
    'Güç paketi, yedek': 'powerpack',
    'Motor yağ filtresi elemanı': 'engine.oil',
    'Hava filtresi elemanı': 'air_filters',
    'Palet tabanı': 'tracks.pads',
    'Akü, 12 V': 'electrical.batteries',
    'Far ampulü, 24 V': 'electrical.headlights',
}

C.zones, C.symptoms, C.faults = ZONES, SYMPTOMS, FAULTS
C.spare_parts = SPARE_PARTS
C.write()
