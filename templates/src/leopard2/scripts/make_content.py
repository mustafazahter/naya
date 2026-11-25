"""Leopard 2A6 şablonunun S1000D içeriğini ve parça haritasını üretir.

    python3 make_content.py

İçerik yalnız genel bakım bilgisidir: periyodik kontroller, seviye
kontrolleri, yağlama, temizlik, sarf parça değişimleri, gözle muayene ve
arıza bulma. Zırh, mühimmat, atış, atış kontrol sistemi ve araç başarım
bilgisi yoktur. Silahların yalnız dış muayenesi, optiklerin yalnız
temizliği anlatılır. Ölçü, basınç ve tork değerleri verilmez; DM'ler değer
gereken yerde aracın kendi teknik el kitabına yönlendirir.

DMC'ler kalıcıdır: var olan bir DM'in kodu değiştirilmez, yeni DM'ler yeni
kod alır. Aynı sistem, alt sistem ve bilgi kodunda ikinci bir DM gerekirse
ayrıştırma kodu (`disassy`) artırılır.
"""
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE.parent.parent / 'scripts'))

from s1000d_content import Content  # noqa: E402

# --- SNS ------------------------------------------------------------------

SNS = {
    'D00': ('Araç', {'1': 'Periyodik bakım', '2': 'Yağlama',
                     '3': 'Temizlik ve koruma', '4': 'Alet ve teçhizat'}),
    'DA0': ('Gövde ve kule', {'1': 'Gövde ve kapaklar', '2': 'Kule',
                              '3': 'Motor güvertesi',
                              '4': 'Çekme ve kurtarma donanımı',
                              '5': 'Yan etekler ve çamurluklar',
                              '6': 'Kule yatağı ve tahrik'}),
    'DA1': ('Güç paketi', {'1': 'Motor', '2': 'Yağlama', '3': 'Soğutma',
                           '4': 'Hava emme ve egzoz', '5': 'Yakıt sistemi'}),
    'DA2': ('Güç aktarma', {'1': 'Şanzıman', '2': 'Son dişliler',
                            '3': 'Frenler', '4': 'Sürüş kumandaları'}),
    'DA3': ('Yürüyen takım', {'1': 'Paletler',
                              '2': 'Yol tekerlekleri ve süspansiyon',
                              '3': 'Avara ve yürütücü dişliler'}),
    'DA4': ('Elektrik sistemi', {'1': 'Aküler', '2': 'Aydınlatma',
                                 '3': 'Şarj ve marş',
                                 '4': 'Kablo demetleri ve sigortalar',
                                 '5': 'İç haberleşme'}),
    'DA5': ('Silah ve optikler', {'1': 'Ana top', '2': 'Optikler',
                                  '3': 'Makineli tüfekler',
                                  '4': 'Sis bombası atıcıları'}),
    'DA6': ('Hidrolik sistem', {'1': 'Hidrolik ünite ve filtre',
                                '2': 'Hortumlar ve bağlantılar'}),
    'DA7': ('Mürettebat bölmesi donanımı', {
        '1': 'Havalandırma ve NBC koruma', '2': 'Yangın söndürme',
        '3': 'Isıtıcı'}),
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
    7: 'Motor güvertesi',
    8: 'Aküler, sürücü bölmesinde',
    9: 'Sol yan etek',
    10: 'Ön farlar ve köşe lambaları',
    11: 'Arka lambalar',
    12: 'Yakıt tankları',
    13: 'Şanzıman ve son dişliler',
    14: 'Hava filtreleri ve egzoz',
    15: 'Yol tekerlekleri ve salıncak kolları, yan etek sökülü',
    16: 'Kule',
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
WEAPONS_SAFE = ('Silah sorumlusunun izni olmadan kule üzerinde ve namlu '
                'önünde çalışmayın.')
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
            'kullandığı bir ana muharebe tankıdır. 2A6 bu ailenin '
            'sürümlerinden biridir.',
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
            'Silah ve optikler: kulenin dış donanımı; ana top, makineli '
            'tüfek kundağı, sis bombası atıcıları ve optikler. Bu şablon '
            'bunların yalnız dış muayenesini, namlu ağzı kapağını ve optik '
            'temizliğini kapsar.',
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
            'Kule bir yatak üzerinde döner. Üstünde ve çevresinde ana top, '
            'makineli tüfek kundağı, sis bombası atıcıları ve optikler '
            'bulunur.',
            'Komutan ve yükleyici kapakları kulenin üstündedir.',
        ]),
    ])

HULL_CHECK = dm(
   code=code('DA0', '1', '310'), tech='Gövde ve kapaklar', figure=1,
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
        'Sis bombası atıcılarının dış gövdesinde ezik ya da çatlak olup '
        'olmadığına bakın. Atıcılara elinizi ya da bir cisim sokmayın.',
        'Makineli tüfek kundağının kule üstündeki bağlantısını gözle kontrol '
        'edin; silahın kendisine dokunmayın.',
        'Antenlerin ve anten tabanlarının sağlam olduğunu kontrol edin.',
        'Bulduğunuz hasarı silah sorumlusuna ve birlik bakım kaydına '
        'bildirin.',
    ])

DECK_CLEAN = dm(
    code=code('DA0', '3', '250'), tech='Motor güvertesi ızgaraları',
    figure=7, conditions=[PARKED, 'Motor soğumuş.'],
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
            ('end-battery', 'Aküleri şarj edin; şarj tutmayan aküyü '
             'değiştirin.', code('DA4', '1', '210')),
            ('end-starter', 'Aküler dolu ama marş dönmüyor: marş devresini '
             'arayın.', code('DA4', '3', '421')),
            ('end-fuel', 'Yakıt ikmali yapın ya da kesme valfini açın.',
             code('DA1', '5', '210')),
            ('end-filter', 'Yakıt filtresindeki suyu boşaltın ve filtreyi '
             'kontrol edin.', code('DA1', '5', '300')),
            ('end-air', 'Hava filtresi elemanlarını değiştirin.',
             code('DA1', '4', '920')),
            ('end-service', 'Yakıt, hava ve elektrik normal: yakıt '
             'sisteminin havasını alın; motor yine çalışmazsa enjeksiyon '
             'sistemi ya da motor kontrol ünitesi arızalı olabilir, yetkili '
             'bakım birimine bildirin.', code('DA1', '5', '230')),
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
    supplies=[('Motor yağı', None)],
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
             'kontrol edin.', 'Seviye düşük mü?', 'stp-0004', 'stp-0003'),
            ('stp-0003', 'Motoru çalıştırın ve fanların döndüğünü '
             'ızgaralardan dinleyin ve hava akışını hissedin.',
             'İki fan da dönüyor mu?', 'stp-0005', 'end-fan'),
            ('stp-0004', 'Soğutma hortumlarına ve kelepçelerine bakın.',
             'Hortumda ıslaklık, beyaz kalıntı ya da çatlak var mı?',
             'end-hose', 'end-coolant'),
            ('stp-0005', 'Soğutma sıvısının rengine ve bakım kaydındaki '
             'değişim tarihine bakın.', 'Sıvı bulanık, paslı ya da '
             'değişimi gecikmiş mi?', 'end-coolant-change', 'end-radiator'),
        ],
        'ends': [
            ('end-grille', 'Izgaraları temizleyin.', code('DA0', '3', '250')),
            ('end-coolant', 'Soğutma sıvısını tamamlayın ve sızıntıyı '
             'arayın.', code('DA1', '3', '300')),
            ('end-hose', 'Sızdıran hortumu ya da kelepçeyi değiştirin.',
             code('DA1', '3', '920')),
            ('end-coolant-change', 'Soğutma sıvısını değiştirin.',
             code('DA1', '3', '220')),
            ('end-radiator', 'Fanlar çalışıyor: radyatör petekleri kirli '
             'olabilir; temizleyin.', code('DA1', '3', '250')),
            ('end-fan', 'Fan dönmüyor: fanları ve fan tahrikini muayene '
             'edin.', code('DA1', '3', '310')),
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
    supplies=[('Dizel yakıt', None)],
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
            'iletir. Tankın dönüşü de şanzımandan yönetilir: iki paletin '
            'hızını farklılaştırarak tank yön değiştirir.',
            'Servis frenleri şanzımanın içindedir. Son dişliler, şanzımanın '
            'çıkışını yürütücü dişlilere aktaran redüktörlerdir.',
        ]),
    ])

TRANS_LEVEL = dm(
   code=code('DA2', '1', '300'), tech='Şanzıman yağı',
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

FD_LEVEL = dm(
   code=code('DA2', '2', '300'), tech='Son dişliler',
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
                 'geliyor ya da tank engebede aşırı yalpalıyor.',
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
             'stp-0005'),
            ('stp-0005', 'Palet bağlantı parçalarını ve kama cıvatalarını '
             'kontrol edin.', 'Bağlantı parçası gevşek ya da eksik mi?',
             'end-connector', 'stp-0006'),
            ('stp-0006', 'Amortisörlere ve bağlantılarına bakın.',
             'Amortisörde yağ izi ya da kopuk bağlantı var mı?',
             'end-damper', 'stp-0007'),
            ('stp-0007', 'Destek makaralarına ve paletin üst koluna bakın.',
             'Makara dönmüyor, bandajı kopuk ya da üst kolda makara aşınma '
             'izi var mı?', 'end-roller', 'stp-0008'),
            ('stp-0008', 'Bakım kaydında salıncak kolu yataklarının son '
             'gresleme tarihine bakın.', 'Gresleme gecikmiş mi?', 'end-arm',
             'end-service'),
        ],
        'ends': [
            ('end-tension', 'Palet gerginliğini ayarlayın.',
             code('DA3', '1', '271')),
            ('end-sprocket', 'Yürütücü dişli çemberlerini değiştirin; '
             'avarayı da muayene edin.', code('DA3', '3', '920')),
            ('end-wheel', 'Yol tekerleklerini ve süspansiyonu muayene edin.',
             code('DA3', '2', '310')),
            ('end-pads', 'Palet tabanlarını değiştirin.',
             code('DA3', '1', '920')),
            ('end-connector', 'Palet bağlantı parçalarını değiştirin.',
             code('DA3', '1', '920', '01')),
            ('end-damper', 'Amortisörü değiştirin.',
             code('DA3', '2', '920', '01')),
            ('end-roller', 'Destek makaralarını muayene edin.',
             code('DA3', '2', '310', '01')),
            ('end-arm', 'Salıncak kolu yataklarını gresleyin.',
             code('DA3', '2', '240')),
            ('end-service', 'Görünür bir sorun yok: burulma çubukları ya da '
             'son dişliler arızalı olabilir; yetkili bakım birimine '
             'bildirin.', None),
        ],
    })

TRACK_TENSION = dm(
    code=code('DA3', '1', '271'), tech='Palet gerginliği', figure=6,
    tools=[('Palet gerdirme anahtarı', 1), ('Cetvel', 1)],
    conditions=[PARKED, 'Tank düz ve sert zeminde; palet üst kolu '
                'çekilmiş (tank kısa bir mesafe ileri sürülüp durdurulmuş).'],
    warnings=['Palet ve gerdirme tertibatı gerilim altındadır. Ayar '
              'sırasında paletin önünde ve avaranın yanında durmayın.'],
    steps=[
        'Paletin üst kolundaki sarkmayı iki tekerlek arasında cetvelle '
        'ölçün. ' + NO_VALUES,
        ('Gerginlik azsa', [
            'Gerdirme anahtarıyla avara gerdirme tertibatını ayarlayıp '
            'avarayı öne alın; palet gerilir.',
        ]),
        ('Gerginlik fazlaysa', [
            'Gerdirme tertibatını ters yönde ayarlayıp avarayı geri alın.',
        ]),
        'Tankı kısa bir mesafe sürüp yeniden ölçün. İki paleti de kontrol '
        'edin.',
        'Gerginlik sık sık azalıyorsa gerdirme tertibatını yetkili bakım '
        'birimine kontrol ettirin.',
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
    figure=3, conditions=[PARKED],
    steps=[
        'Yürütücü dişli dişlerinin profilini kontrol edin; dişler sivrilmiş '
        'ya da kancalaşmışsa palet atlamaya başlar.',
        'Dişli çemberlerinin bağlantı cıvatalarını kontrol edin.',
        'Avara tekerleğinin bandajını ve göbeğini kontrol edin.',
        'Avara gerdirme tertibatında sızıntı ya da hasar olup olmadığına '
        'bakın.',
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
            'Kulenin dış donanımı: önde ana top ve top kalkanı, yükleyici '
            'kapağında makineli tüfek kundağı, iki yanda sis bombası '
            'atıcıları.',
            'Nişancı optiği ve komutan periskobu kulenin üstündedir; '
            'sürücünün periskopları gövdenin önündedir.',
        ]),
        ('Bu şablonun kapsamı', [
            'Bu şablon yalnız dış muayeneyi, namlu ağzı kapağını ve optik '
            'temizliğini kapsar. Bunların dışındaki her iş yetkili '
            'personelindir ve aracın kendi el kitabına göre yapılır.',
        ]),
    ])

GUN_CHECK = dm(
   code=code('DA5', '1', '310'), tech='Ana top', info='Dış muayene',
   figure=1, conditions=[PARKED, 'Kule ve top kilitli.'],
   warnings=[WEAPONS_SAFE],
   steps=[
       'Namlu ağzı koruyucu kapağının takılı ve sağlam olduğunu kontrol '
       'edin.',
       'Namlunun dış yüzeyinde ve ısı kılıfında ezik, yırtık ya da gevşek '
       'parça olup olmadığına bakın.',
       'Top kalkanının çevresindeki toz körüğünde yırtık olup olmadığını '
       'kontrol edin.',
       'Bulduğunuz hasarı silah sorumlusuna bildirin; başka bir işlem '
       'yapmayın.',
   ])

OPTICS_CLEAN = dm(
    code=code('DA5', '2', '250'), tech='Optik camları', figure=5,
    tools=[('Yumuşak kıllı optik fırçası', 1), ('Optik hava pompası', 1)],
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

# --- Genişletilmiş içerik ----------------------------------------------------
#
# Periyodik bakımlar, yağlama, temizlik, alet ve teçhizat, kurtarma, kule
# yatağı, frenler, elektrik devreleri, iç haberleşme, hidrolik ve mürettebat
# bölmesi donanımı. Hepsi genel bakım düzeyinde; değerler el kitabında.

MASTER_OFF = 'Ana şalter kapalı.'
PPE = 'Koruyucu eldiven ve gözlük takın.'
HYD_PRESSURE = ('Hidrolik sistem motor durduktan sonra da basınç altında '
                'kalabilir. Basıncı aracın el kitabındaki yolla boşaltmadan '
                'hiçbir hidrolik bağlantıyı gevşetmeyin.')
FIRE_SYSTEM_SAFE = ('Otomatik yangın söndürme sisteminin tüplerine ve '
                    'tetikleme düzenine yetkisiz müdahale etmeyin; yanlışlıkla '
                    'boşalan söndürücü gaz mürettebat bölmesinde tehlikelidir.')

# Araç: güvenlik, periyodik bakım
SAFETY = dm(
    code=code('D00', info='012'), tech='Leopard 2A6',
    info='Güvenlik uyarıları',
    description=[
        ('Genel', [
            'Bu el kitabındaki işler eğitimli mürettebat ve bakım personeli '
            'içindir. Bir iş size verilen yetkinin dışındaysa durun ve '
            'yetkili bakım birimine bildirin.',
            'Her işe başlamadan önce tankı düz zemine alın, motoru durdurun, '
            'park frenini çekin ve gerekiyorsa ana şalteri kapatın.',
        ]),
        ('Silahlar', [
            WEAPONS_SAFE,
            'Bu şablon silahların yalnız dış muayenesini kapsar. Silahlara '
            've sis bombası atıcılarının içine müdahale etmeyin.',
        ]),
        ('Güç paketi ve sıvılar', [
            HOT,
            'Soğutma sistemi sıcakken basınç altındadır; doldurma kapağını '
            'motor soğumadan açmayın.',
            'Yakıt, yağ ve hidrolik yağı yanıcıdır; açık alevle yaklaşmayın, '
            'dökülenleri hemen silin ve atıkları ayrı toplayın.',
        ]),
        ('Kaldırma ve ağır parçalar', [
            'Paletler, tekerlekler, yan etek panelleri ve aküler ağırdır. '
            'Kaldırma düzeni olmadan tek başınıza taşımayın.',
            'Asılı yükün altında durmayın.',
        ]),
    ])

SCHEDULE = dm(
    code=code('D00', '1', '040'), tech='Periyodik bakım',
    info='Bakım düzeni', figure=1,
    description=[
        ('Bakım düzeyleri', [
            'Günlük kontrol: tankı her kullanmadan önce mürettebat yapar. '
            'Seviyeler, sızıntılar, paletler, lambalar ve optikler bakılır.',
            'Görev öncesi, görev sırası ve görev sonrası kontroller: arazi '
            'görevinin başında, molalarda ve sonunda yapılır.',
            'Haftalık ve aylık bakım: gresleme, temizlik, akü ve kablo '
            'kontrolü, filtre göstergeleri, alet sayımı.',
            'Dönemsel bakım: yağ ve filtre değişimleri, soğutma sıvısı '
            'değişimi ve kapsamlı muayeneler. Aralıklar çalışma saatine ve '
            'kilometreye bağlıdır; aracın el kitabındaki çizelgeyi kullanın.',
        ]),
        ('Kayıt', [
            'Her kontrolün sonucu ve bulunan her eksik araç bakım kaydına '
            'yazılır. Mürettebatın gideremediği eksik yetkili bakım birimine '
            'bildirilir.',
            'Tozlu, çamurlu, çok sıcak ya da çok soğuk çalışma koşullarında '
            'filtre ve gresleme aralıkları kısalır.',
        ]),
    ])

BEFORE_OP = dm(
    code=code('D00', '1', '300', '00'), tech='Tank',
    info='Görev öncesi kontrol', figure=1,
    conditions=[PARKED], warnings=[WEAPONS_SAFE],
    steps=[
        'Günlük kontrolü yapın.',
        'Yakıt seviyesini kontrol edin; gerekiyorsa ikmal yapın.',
        'Hava filtresi tıkanıklık göstergesine ve yakıt filtresinin su '
        'ayırıcısına bakın.',
        'Palet gerginliğini gözle kontrol edin; üst kolda belirgin sarkma '
        'varsa ayarlayın.',
        'Kapakların kapandığını ve kilitlendiğini, contaların yerinde '
        'olduğunu kontrol edin.',
        'İç haberleşme düzenini ve bütün mürettebat başlıklarını deneyin.',
        'El tipi yangın söndürücülerin yerinde ve dolu olduğunu kontrol '
        'edin; yangın söndürme sisteminin gösterge panelinde uyarı '
        'olmamalıdır.',
        'Alet ve teçhizatın yerinde ve bağlı olduğunu kontrol edin.',
        'Çeki halatlarının ve kancalarının takılı olduğunu kontrol edin.',
    ])

DURING_OP = dm(
    code=code('D00', '1', '300', '01'), tech='Tank',
    info='Görev sırasında kontrol',
    steps=[
        'Sürüş sırasında motor sıcaklığı, yağ basıncı, akü şarjı ve '
        'şanzıman uyarılarını izleyin.',
        'Olağan dışı ses, titreşim, yanık kokusu ya da duman fark ederseniz '
        'tankı güvenli bir yerde durdurun.',
        ('Molalarda', [
            'Tankın çevresinde dolaşıp sızıntı izi arayın.',
            'Yol tekerleği göbeklerinin sıcaklığını elinizin tersiyle '
            'karşılaştırın.',
            'Palet gerginliğine ve palet bağlantı parçalarına bakın.',
            'Motor güvertesi ızgaralarındaki yaprak ve çamuru temizleyin.',
            'Hava filtresi göstergesine bakın.',
        ]),
    ])

AFTER_OP = dm(
    code=code('D00', '1', '300', '02'), tech='Tank',
    info='Görev sonrası kontrol', figure=3,
    conditions=[PARKED],
    steps=[
        'Paletlere, tekerleklere ve yan eteklerin içine yapışan çamuru ve '
        'taşları temizleyin.',
        'Yol tekerleklerini, salıncak kollarını ve amortisörleri gözle '
        'kontrol edin.',
        'Motor yağı, soğutma sıvısı ve şanzıman yağı seviyelerini kontrol '
        'edin.',
        'Yakıt ikmali yapın; tankları dolu bırakmak yoğuşmayla suyun '
        'birikmesini azaltır.',
        'Optiklerin camlarını temizleyin, koruyucu kapakları kapatın.',
        'Kullanılan sarf malzemelerini ve bulunan eksikleri bakım kaydına '
        'yazın.',
    ])

WEEKLY = dm(
    code=code('D00', '1', '300', '03'), tech='Tank', info='Haftalık bakım',
    conditions=[PARKED, MASTER_OFF],
    steps=[
        'Akü kutup başlarını ve kablo bağlantılarını kontrol edin.',
        'Yol tekerleği ve avara göbeklerinde, son dişlilerde yağ sızıntısı '
        'arayın.',
        'Hava filtresinin ön temizleyicisini ve toz atma çıkışını '
        'temizleyin.',
        'Kapak menteşelerini ve kilitlerini gresleyin.',
        'NBC ve havalandırma ünitesinin filtre göstergesine bakın.',
        'Hidrolik yağı seviyesini kontrol edin.',
        'Alet ve teçhizatı sayın.',
    ])

MONTHLY = dm(
    code=code('D00', '1', '300', '04'), tech='Tank', info='Aylık bakım',
    conditions=[PARKED, MASTER_OFF],
    steps=[
        'Yağlama çizelgesindeki bütün gresörlükleri gresleyin.',
        'Kule yatağını gresleyin.',
        'Kablo demetlerini sürtünme ve ezilmeye karşı kontrol edin.',
        'Yangın söndürme tüplerinin göstergelerini ve el tipi söndürücüleri '
        'kontrol edin.',
        'Isıtıcıyı kısa süre çalıştırarak deneyin.',
        'Boya hasarlarını ve paslanmaya başlayan yerleri koruyun.',
        'Gövde içindeki suyu ve kiri boşaltın.',
    ])

COLD = dm(
    code=code('D00', '1', '300', '05'), tech='Tank',
    info='Soğuk havada çalıştırma hazırlığı',
    conditions=[PARKED],
    warnings=['Isıtıcıyı ve motor ön ısıtıcısını kapalı alanda '
              'çalıştırmayın; egzoz gazı zehirlidir.'],
    steps=[
        'Akülerin dolu olduğunu kontrol edin; soğukta akü kapasitesi düşer.',
        'Soğutma sıvısının antifriz oranının mevsime uygun olduğunu '
        'el kitabındaki yolla kontrol edin.',
        'Yakıt filtresinin su ayırıcısını boşaltın; donmuş su yakıt akışını '
        'keser.',
        'Paletlerin zemine donmadığını kontrol edin; donmuşsa zorla '
        'sürmeyin, buzu çözün.',
        'Motoru el kitabındaki soğuk çalıştırma yöntemiyle çalıştırın ve '
        'yük vermeden önce ısınmasını bekleyin.',
    ])

LUBE_CHART = dm(
    code=code('D00', '2', '040'), tech='Yağlama', info='Yağlama çizelgesi',
    figure=1,
    description=[
        ('Yağlama noktaları', [
            'Motor: motor yağı, yağ çubuğundan kontrol, dönemsel değişim.',
            'Şanzıman: şanzıman yağı, çubuktan kontrol, dönemsel değişim ve '
            'filtre.',
            'Son dişliler: dişli yağı, seviye tapasından kontrol.',
            'Yürüyen takım: salıncak kolu yatakları, avara gerdirme '
            'tertibatı ve destek makaraları; gres.',
            'Kule: kule yatağı ve kapak menteşeleri; gres.',
            'Sürüş kumandaları: bağlantı mafsalları; hafif yağ ya da gres.',
            'Hidrolik sistem: hidrolik yağı, depodan seviye kontrolü.',
        ]),
        ('Kurallar', [
            'Yağ ve gres türünü aracın el kitabından ve yağlama plakasından '
            'seçin; farklı yağları karıştırmayın.',
            'Gresörlüğü greslemeden önce silin; kirli gres yatağı aşındırır.',
            'Eski gres yatağın kenarından taze gres görünene kadar basın; '
            'taşan gresi silin.',
        ]),
    ])

GREASE = dm(
    code=code('D00', '2', '240'), tech='Gresörlükler', info='Gresleme',
    figure=15,
    tools=[('Gres pompası', 1), ('Temiz bez', None)],
    supplies=[('Gres', None)],
    conditions=[PARKED],
    steps=[
        'Yağlama çizelgesindeki noktaları sırayla bulun.',
        'Her gresörlüğün başını temiz bezle silin.',
        'Gres pompasını takın ve taze gres yatağın kenarından görünene '
        'kadar basın.',
        'Gres almayan gresörlüğü işaretleyin; tıkalı gresörlük değiştirilir.',
        'Taşan gresi silin ve yapılan greslemeyi kayda geçirin.',
    ])

WASH = dm(
    code=code('D00', '3', '250', '00'), tech='Tank', info='Dış yıkama',
    tools=[('Basınçlı su makinesi', 1), ('Yumuşak kıllı fırça', 1)],
    conditions=[PARKED, MASTER_OFF, 'Bütün kapaklar kapalı.'],
    cautions=['Basınçlı suyu optiklere, lamba camlarına, elektrik '
              'konnektörlerine ve havalandırma girişlerine doğrudan '
              'tutmayın.',
              'Motor güvertesi ızgaralarını basınçlı suyla yakından '
              'yıkamayın; radyatör kanatçıkları ezilir.'],
    steps=[
        'Önce yürüyen takımdaki çamuru ve taşları kaba temizleyin.',
        'Gövdeyi yukarıdan aşağıya doğru yıkayın.',
        'Yan eteklerin arkasını ve yol tekerleklerinin arasını yıkayın.',
        'Optikleri ve lamba camlarını en son, optik temizleme yöntemiyle '
        'temizleyin.',
        'Yıkamadan sonra kapak contalarının ve gresörlüklerin çevresini '
        'kurulayın; gerekiyorsa gresleyin.',
    ],
    next=code('D00', '2', '240'))

INTERIOR_CLEAN = dm(
    code=code('D00', '3', '250', '01'), tech='Mürettebat bölmesi',
    info='İç temizlik',
    tools=[('Elektrikli süpürge', 1), ('Temiz bez', None)],
    conditions=[PARKED, MASTER_OFF],
    warnings=[WEAPONS_SAFE],
    steps=[
        'Gevşek teçhizatı çıkarın ve yerlerini not edin.',
        'Tabandaki toz, kum ve atıkları süpürün.',
        'Gösterge panellerini ve konnektörleri kuru bezle silin; sıvı '
        'temizleyici püskürtmeyin.',
        'Gövde içinde su ya da yağ birikmişse boşaltın ve kaynağını arayın.',
        'Teçhizatı yerine koyup bağlayın.',
    ],
    next=code('DA0', '1', '220'))

CORROSION = dm(
    code=code('D00', '3', '250', '02'), tech='Boya ve metal yüzeyler',
    info='Korozyon koruma',
    tools=[('Tel fırça', 1), ('Boya fırçası', 1)],
    supplies=[('Rötuş boyası', None), ('Korozyon önleyici', None)],
    conditions=[PARKED, 'Yüzey temiz ve kuru.'],
    cautions=['Optik camlarına, contalara ve lastik parçalara boya ya da '
              'korozyon önleyici sürmeyin.'],
    steps=[
        'Boyası kalkmış ve paslanmaya başlamış yerleri bulun.',
        'Gevşek pası tel fırçayla alın, yüzeyi silin.',
        'Rötuş boyasını ince katlar halinde sürün.',
        'Açıkta kalan çıplak metal bağlantılara korozyon önleyici sürün.',
    ])

TOOLS_DESC = dm(
    code=code('D00', '4', '040'), tech='Alet ve teçhizat', figure=16,
    description=[
        ('Araç alet takımı', [
            'Her tankta mürettebatın kullandığı bir alet takımı bulunur: '
            'anahtarlar, lokma takımı, palet aletleri, gres pompası, kürek '
            've kazma, kriko ve çeki donanımı.',
            'Takımın listesi ve her aletin yeri aracın el kitabındadır. '
            'Aletler kule arka sepetinde, gövde üstündeki kutularda ve '
            'mürettebat bölmesinde belirli yerlerde bağlı durur.',
        ]),
        ('Kurallar', [
            'Her alet kullanıldıktan sonra temizlenip yerine bağlanır.',
            'Kayıp ya da kırık alet bakım kaydına yazılır ve tamamlanır.',
        ]),
    ])

TOOLS_CHECK = dm(
    code=code('D00', '4', '300'), tech='Alet ve teçhizat',
    info='Sayım ve kontrol', figure=16,
    conditions=[PARKED],
    steps=[
        'Alet listesini alın ve aletleri tek tek sayın.',
        'Aletlerde kırık, çatlak ya da aşınmış ağız olup olmadığına bakın.',
        'Palet aletlerinin ve gres pompasının çalıştığını kontrol edin.',
        'Kule arka sepetindeki ve dış kutulardaki bağlama kayışlarını '
        'kontrol edin.',
        'Eksik ve hasarlı aletleri kayda geçirin.',
    ])

# Gövde, kapaklar, kurtarma, yan etekler, kule yatağı
HATCH_ISOLATE = dm(
    code=code('DA0', '1', '421'), tech='Kapaklar',
    info='Kapak su alıyor ya da kapanmıyor: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA0-001',
        'descr': 'Kapaktan içeri su ya da toz giriyor, kapak zor kapanıyor '
                 'ya da kilit kavramıyor.',
        'steps': [
            ('stp-0001', 'Kapağı açın ve contayı çevresi boyunca gözle '
             'kontrol edin.', 'Contada yırtık, ezilme ya da sertleşme var '
             'mı?', 'end-seal', 'stp-0002'),
            ('stp-0002', 'Conta oturma yüzeyine bakın.',
             'Yüzeyde kir, buz ya da boya birikintisi var mı?', 'end-clean',
             'stp-0003'),
            ('stp-0003', 'Kapağı yavaşça açıp kapatın.',
             'Menteşe sıkışıyor ya da kilit zor dönüyor mu?', 'end-grease',
             'end-service'),
        ],
        'ends': [
            ('end-seal', 'Kapak contasını değiştirin.',
             code('DA0', '1', '920')),
            ('end-clean', 'Oturma yüzeyini temizleyin ve kapağı yeniden '
             'deneyin.', code('DA0', '1', '310')),
            ('end-grease', 'Menteşeleri ve kilitleri gresleyin.',
             code('DA0', '2', '240')),
            ('end-service', 'Kapak ya da menteşe eğilmiş olabilir; yetkili '
             'bakım birimine bildirin.', None),
        ],
    })

HATCH_SEAL = dm(
    code=code('DA0', '1', '920'), tech='Kapak contası', figure=16,
    tools=[('Plastik spatula', 1), ('Temiz bez', None)],
    supplies=[('Conta yapıştırıcısı', None)],
    spares=[('Kapak contası', 1)],
    conditions=[PARKED, 'Kapak açık ve emniyet kilidiyle tutturulmuş.'],
    warnings=['Açık kapağı emniyet kilidiyle tutturmadan çalışmayın; kapak '
              'ağırdır ve kendiliğinden kapanabilir.'],
    steps=[
        'Eski contayı yuvasından plastik spatulayla çıkarın.',
        'Yuvadaki eski yapıştırıcıyı ve kiri temizleyin, kurulayın.',
        'Yeni contayı köşelerden başlayarak, gerdirmeden yuvaya yerleştirin; '
        'gerekiyorsa el kitabındaki yapıştırıcıyı kullanın.',
        'Kapağı kapatıp kilitleyin; contanın her yerde eşit bastığını '
        'kontrol edin.',
    ])

HULL_DRAIN = dm(
    code=code('DA0', '1', '220'), tech='Gövde içi su', info='Boşaltma',
    tools=[('Lokma takımı', 1)],
    spares=[('Boşaltma tapası contası', 1)],
    conditions=[PARKED, MASTER_OFF],
    cautions=['Yağlı ya da yakıtlı suyu toprağa boşaltmayın; toplayın.'],
    steps=[
        'Gövde tabanındaki boşaltma tapalarının yerini el kitabından bulun.',
        'Tapanın altına toplama kabı koyun ve tapayı sökün.',
        'Su akmayı bırakınca tapayı yeni contasıyla takın.',
        'Suyun rengine bakın: yağlı ya da yakıtlı su bir sızıntıya işaret '
        'eder; kaynağını arayın.',
        'Su sık sık birikiyorsa kapak contalarını kontrol edin.',
    ])

ESCAPE_HATCH = dm(
    code=code('DA0', '1', '310', '01'), tech='Taban kaçış kapağı',
    conditions=[PARKED, MASTER_OFF],
    steps=[
        'Kaçış kapağının üstünde ve çevresinde teçhizat olmadığını kontrol '
        'edin; kapak her zaman açılabilir olmalıdır.',
        'Kilit kolunun serbest döndüğünü ve emniyet pimini kontrol edin.',
        'Kapak contasında yırtık ya da sertleşme olup olmadığına bakın.',
        'Kapağı yalnız el kitabındaki denetimlerde ve tank yerdeyken açın.',
    ])

HATCH_GREASE = dm(
    code=code('DA0', '2', '240'), tech='Kapak menteşeleri ve kilitleri',
    info='Gresleme', figure=5,
    tools=[('Gres pompası', 1), ('Temiz bez', None)],
    supplies=[('Gres', None)],
    conditions=[PARKED, 'Kule kilitli.'],
    warnings=[WEAPONS_SAFE],
    steps=[
        'Sürücü, komutan ve yükleyici kapaklarının menteşe gresörlüklerini '
        'silin.',
        'Gres taze olarak görünene kadar basın.',
        'Kilit mekanizmalarına hafif yağ sürün.',
        'Kapakları birkaç kez açıp kapatarak gresin dağılmasını sağlayın; '
        'taşanı silin.',
    ])

DECK_HATCHES = dm(
    code=code('DA0', '3', '310'), tech='Motor güvertesi kapakları',
    figure=7, conditions=[PARKED, 'Motor soğumuş.'],
    warnings=[HOT, 'Güverte kapakları ağırdır; açık kapağı dayama koluyla '
              'tutturun.'],
    steps=[
        'Güverte kapaklarının kilitlerini ve menteşelerini kontrol edin.',
        'Izgaraların bağlantı vidalarını ve çerçevelerini kontrol edin.',
        'Kapak contalarında yırtık olup olmadığına bakın.',
        'Kapakların üstündeki tutamakların ve yakıt doldurma kapaklarının '
        'sağlam olduğunu kontrol edin.',
    ])

RECOVERY = dm(
    code=code('DA0', '4', '040'), tech='Çekme ve kurtarma donanımı',
    figure=1,
    description=[
        ('Donanım', [
            'Tankın önünde ve arkasında çeki kancaları bulunur. Çeki '
            'halatları gövde üstünde taşınır ve iki uçlarındaki göz '
            'kancalara takılır.',
            'Çeki demiri, arızalı tankın kurtarma aracı ya da başka bir '
            'tankla kısa mesafede çekilmesinde kullanılır.',
        ]),
        ('Kurallar', [
            'Çekme ve kurtarma, kurtarma ekibinin yönetiminde ve aracın el '
            'kitabındaki sınırlar içinde yapılır.',
            'Gergin halatın ve çeki demirinin yanında durmayın; kopan halat '
            'ağır yaralanmaya yol açar.',
        ]),
    ])

TOW_CHECK = dm(
    code=code('DA0', '4', '310'),
    tech='Çeki halatları, kancalar ve çeki demiri', figure=1,
    tools=[('İş eldiveni', 1)],
    conditions=[PARKED],
    steps=[
        'Çeki halatlarını eldivenle boydan boya elden geçirin; kopuk tel, '
        'ezilme, bükülme ya da paslanma arayın.',
        'Halat gözlerinin ve preslerin sağlam olduğunu kontrol edin.',
        'Çeki kancalarında çatlak, eğilme ve aşınma olup olmadığına bakın; '
        'kanca pimlerinin ve emniyetlerinin yerinde olduğunu kontrol edin.',
        'Çeki demirinin göz ve pimlerini kontrol edin.',
        'Hasarlı halatı kullanmayın; ayırıp bakım kaydına yazın.',
    ])

TOWING = dm(
    code=code('DA0', '4', '200'), tech='Tank', info='Çekmeye hazırlama',
    figure=1,
    tools=[('Çeki demiri ya da çeki halatı', 2)],
    conditions=['Kurtarma ekibi ve çeken araç hazır.'],
    warnings=['Çekme sırasında gergin halatın ve çeki demirinin yanında '
              'durmayın.', 'Çekilen tankta sürücü yerinde olmalı ve '
              'çeken araçla haberleşmelidir.'],
    steps=[
        'Çekilecek tankın kulesini seyir konumuna alın ve kilitleyin.',
        'Aracın el kitabına göre şanzımanı çekme konumuna alın; gerekiyorsa '
        'son dişli bağlantılarını yetkili birim ayırır.',
        'Çeki demirini ya da halatları iki aracın kancalarına takın ve '
        'emniyetleyin.',
        'Çekilen tankın frenlerinin ve lambalarının çalıştığını kontrol '
        'edin.',
        'Çekmeyi el kitabındaki hız ve mesafe sınırları içinde, ani '
        'kalkış ve duruş yapmadan yapın.',
    ])

SKIRT_CHECK = dm(
    code=code('DA0', '5', '310'), tech='Yan etekler ve çamurluklar',
    figure=9, conditions=[PARKED],
    steps=[
        'Yan etek panellerinde eğilme, çatlak ya da kopuk köşe olup '
        'olmadığına bakın.',
        'Panel bağlantı cıvatalarının ve tutamakların yerinde olduğunu '
        'kontrol edin.',
        'Alt kenardaki lastik paletlik parçalarının yırtık olmadığını '
        'kontrol edin.',
        'Panellerin arkasında sıkışmış taş, dal ya da çamur varsa temizleyin.',
        'Çamurlukların ve üstündeki kutuların bağlantılarını kontrol edin.',
    ])

SKIRT_CHANGE = dm(
    code=code('DA0', '5', '920'), tech='Yan etek paneli', figure=9,
    tools=[('Lokma takımı', 1), ('Kaldırma askısı', 1)],
    spares=[('Yan etek paneli', 1)],
    conditions=[PARKED],
    warnings=['Yan etek panelleri ağırdır; iki kişiyle ya da kaldırma '
              'düzeniyle çalışın.'],
    steps=[
        'Değiştirilecek paneli kaldırma askısıyla ya da ikinci bir kişiyle '
        'destekleyin.',
        'Panel bağlantı cıvatalarını sökün ve paneli ayırın.',
        'Bağlantı yuvalarını temizleyin, dişleri kontrol edin.',
        'Yeni paneli yerine tutun ve cıvatalarını takın; el kitabındaki '
        'torkta sıkın.',
        'Panelin palete ve tekerleklere değmediğini kontrol edin.',
    ])

TURRET_RING = dm(
    code=code('DA0', '6', '040'), tech='Kule yatağı ve tahrik', figure=16,
    description=[
        ('Genel', [
            'Kule, gövdenin üstündeki büyük bir bilyalı yatak üzerinde '
            'döner. Yatağın çevresindeki conta su ve tozun içeri girmesini '
            'önler.',
            'Kule tahrik düzenleri kulenin içindedir. Mürettebat bunların '
            'yalnız çevresini temiz tutar ve dışarıdan gözle bakar; ayar ve '
            'onarım yetkili birimindir.',
            'Kule kilidi, seyir ve bakım sırasında kuleyi gövdeye sabitler.',
        ]),
    ])

RING_GREASE = dm(
    code=code('DA0', '6', '240'), tech='Kule yatağı', info='Gresleme',
    figure=16,
    tools=[('Gres pompası', 1), ('Temiz bez', None)],
    supplies=[('Gres', None)],
    conditions=[PARKED, 'Kuleyi yalnız yetkili bir mürettebat üyesi '
                'döndürür.'],
    warnings=[WEAPONS_SAFE, 'Kule dönerken kule ile gövde arasına elinizi '
              've aletlerinizi sokmayın.'],
    steps=[
        'Kule yatağının gresörlüklerini el kitabındaki sırayla bulun ve '
        'silin.',
        'Erişebildiğiniz gresörlüklere gres basın.',
        'Kuleyi yetkili mürettebata yavaşça döndürtün ve kalan '
        'gresörlükleri gresleyin.',
        'Kuleyi tam bir tur döndürtüp gresin dağılmasını sağlayın.',
        'Kuleyi seyir konumunda kilitleyin, taşan gresi silin.',
    ])

RING_CHECK = dm(
    code=code('DA0', '6', '310'), tech='Kule yatağı contası ve tahrik',
    figure=16, conditions=[PARKED, 'Kule kilitli.'],
    warnings=[WEAPONS_SAFE],
    steps=[
        'Kule ile gövde arasındaki contayı çevresi boyunca kontrol edin; '
        'yırtık ya da yerinden çıkmış conta su alır.',
        'Kule tabanının çevresinde kum, taş ya da buz birikmişse temizleyin.',
        'Kule kilidinin kavradığını ve serbest kaldığını kontrol edin.',
        'Mürettebat bölmesinde tahrik düzenlerinin çevresinde yağ izi ya da '
        'gevşek kablo olup olmadığına bakın; tahriklere müdahale etmeyin.',
    ])

RING_ISOLATE = dm(
    code=code('DA0', '6', '421'), tech='Kule',
    info='Dönerken ses ya da sıkışma: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA0-002',
        'descr': 'Kule dönerken gıcırtı ya da tıkırtı geliyor, kule bir '
                 'noktada zorlanıyor ya da kule kilidi açılmıyor.',
        'steps': [
            ('stp-0001', 'Kule kilidinin tamamen açık olduğunu kontrol '
             'edin.', 'Kilit tam açık mı?', 'stp-0002', 'end-lock'),
            ('stp-0002', 'Kule tabanının çevresine ve conta boyunca bakın.',
             'Kum, taş, buz ya da sıkışmış bir cisim var mı?', 'end-debris',
             'stp-0003'),
            ('stp-0003', 'Bakım kaydında kule yatağının son gresleme '
             'tarihine bakın.', 'Gresleme gecikmiş mi?', 'end-grease',
             'end-service'),
        ],
        'ends': [
            ('end-lock', 'Kule kilidini kontrol edin ve tam açın.',
             code('DA0', '6', '310')),
            ('end-debris', 'Yabancı cismi çıkarın, conta çevresini '
             'temizleyin.', code('DA0', '6', '310')),
            ('end-grease', 'Kule yatağını gresleyin.',
             code('DA0', '6', '240')),
            ('end-service', 'Yatak ya da tahrik arızalı olabilir; kuleyi '
             'zorlamayın, yetkili bakım birimine bildirin.', None),
        ],
    })

# Güç paketi
ENGINE_TEST = dm(
    code=code('DA1', '1', '320'), tech='Motor',
    info='Çalıştırma ve rölanti testi', figure=2,
    conditions=[PARKED, 'Seviyeler kontrol edilmiş.',
                'Tankın önü ve arkası boş.'],
    warnings=['Motoru kapalı alanda çalıştırmayın; egzoz gazı zehirlidir.'],
    steps=[
        'Ana şalteri açın; uyarı lambalarının yandığını kontrol edin.',
        'Motoru el kitabındaki yöntemle çalıştırın.',
        'Yağ basıncının yükseldiğini ve uyarı lambalarının söndüğünü izleyin.',
        'Rölantide olağan dışı ses, titreşim ya da duman olup olmadığını '
        'kontrol edin.',
        'Motor sıcaklığının yavaşça yükseldiğini ve akü şarj göstergesinin '
        'şarjı gösterdiğini izleyin.',
        'Motoru durdurun ve güç paketinin altında sızıntı arayın.',
    ])

POWER_ISOLATE = dm(
    code=code('DA1', '1', '421'), tech='Motor', info='Güç kaybı: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA1-003',
        'descr': 'Motor çalışıyor ama çekmiyor; tank yokuşta ve yüklü '
                 'sürüşte hızlanmıyor.',
        'steps': [
            ('stp-0001', 'Hava filtresi tıkanıklık göstergesine bakın.',
             'Gösterge kırmızı mı?', 'stp-0005', 'stp-0002'),
            ('stp-0002', 'Yakıt filtresinin su ayırıcısına bakın.',
             'Su ya da tortu var mı?', 'end-water', 'stp-0003'),
            ('stp-0003', 'Motor güvertesini açın ve hava emme kanallarını, '
             'kelepçeleri ve turboşarj bağlantılarını kontrol edin.',
             'Gevşek kelepçe, yırtık kanal ya da kurum izi var mı?',
             'end-intake', 'stp-0004'),
            ('stp-0004', 'Motor kontrol uyarılarına bakın.',
             'Gösterge panelinde motor arıza uyarısı var mı?', 'end-ecu',
             'end-fuel'),
            ('stp-0005', 'Ön temizleyicinin girişlerine ve toz atma '
             'çıkışına bakın.', 'Giriş ya da toz atma çıkışı tıkalı mı?',
             'end-precleaner', 'end-air'),
        ],
        'ends': [
            ('end-precleaner', 'Ön temizleyiciyi ve toz atma çıkışını '
             'temizleyin; gösterge yine kırmızıysa filtre elemanlarını '
             'değiştirin.', code('DA1', '4', '250')),
            ('end-air', 'Hava filtresi elemanlarını değiştirin.',
             code('DA1', '4', '920')),
            ('end-water', 'Su ayırıcıyı boşaltın.', code('DA1', '5', '300')),
            ('end-intake', 'Hava emme kanallarını ve kelepçeleri onarın.',
             code('DA1', '4', '310', '01')),
            ('end-ecu', 'Motor kontrol ünitesi ya da bir algılayıcı '
             'arızalı olabilir; yetkili bakım birimine bildirin. Onarımdan '
             'sonra çalıştırma testini yapın.', code('DA1', '1', '320')),
            ('end-fuel', 'Yakıt filtresi tıkanmış olabilir; filtre '
             'elemanını değiştirin.', code('DA1', '5', '920')),
        ],
    })

SMOKE_ISOLATE = dm(
    code=code('DA1', '1', '421', '01'), tech='Egzoz dumanı',
    info='Aşırı duman: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA1-004',
        'descr': 'Motor ısındıktan sonra da egzozdan koyu siyah, mavi ya '
                 'da beyaz duman çıkıyor.',
        'steps': [
            ('stp-0001', 'Motoru rölantide çalıştırın ve dumanın rengine '
             'bakın.', 'Duman siyah mı?', 'stp-0002', 'stp-0003'),
            ('stp-0002', 'Hava filtresi göstergesine ve hava emme '
             'kanallarına bakın.', 'Filtre tıkalı ya da kanal açık mı?',
             'end-air', 'end-injection'),
            ('stp-0003', 'Duman mavi ise motor yağı seviyesine bakın.',
             'Duman mavi ve yağ hızla eksiliyor mu?', 'end-oil',
             'stp-0004'),
            ('stp-0004', 'Duman beyaz ise soğutma sıvısı seviyesine bakın.',
             'Soğutma sıvısı eksiliyor mu?', 'end-coolant', 'end-exhaust'),
        ],
        'ends': [
            ('end-air', 'Hava filtresini değiştirin, kanalları onarın.',
             code('DA1', '4', '920')),
            ('end-injection', 'Hava yolu normal: enjeksiyon sistemi arızalı '
             'olabilir; motoru zorlamayın, yetkili bakım birimine bildirin. '
             'Onarımdan sonra çalıştırma testini yapın.',
             code('DA1', '1', '320')),
            ('end-oil', 'Motor yağ yakıyor; seviyeyi tamamlayın ve yetkili '
             'bakım birimine bildirin.', code('DA1', '2', '300')),
            ('end-coolant', 'Soğutma sıvısı yanma odasına geçiyor olabilir; '
             'motoru çalıştırmayın ve bildirin.', code('DA1', '3', '300')),
            ('end-exhaust', 'Soğuk motorda kısa süreli beyaz duman olağandır; '
             'egzoz borularını ve kelepçeleri kontrol edin.',
             code('DA1', '4', '310')),
        ],
    })

MOUNTS = dm(
    code=code('DA1', '1', '310', '01'), tech='Güç paketi bağlantı takozları',
    figure=2, conditions=[PARKED, 'Motor güvertesi açık.'],
    warnings=[HOT],
    steps=[
        'Güç paketinin gövdeye bağlandığı takozları el kitabındaki '
        'yerlerinde bulun.',
        'Lastik takozlarda çatlak, ayrılma ya da yağ şişmesi olup olmadığına '
        'bakın.',
        'Bağlantı cıvatalarının yerinde olduğunu ve işaret çizgilerinin '
        'kaymadığını kontrol edin.',
        'Motor çalışırken paketin aşırı sallanması takoz arızasına işaret '
        'eder; bildirin.',
    ])

OIL_ISOLATE = dm(
    code=code('DA1', '2', '421'), tech='Motor yağlama',
    info='Yağ basıncı uyarısı: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA1-005',
        'descr': 'Motor çalışırken yağ basıncı uyarısı yanıyor ya da '
                 'gösterge düşük basınç gösteriyor.',
        'steps': [
            ('stp-0001', 'Motoru hemen durdurun. Birkaç dakika sonra yağ '
             'seviyesini kontrol edin.', 'Seviye düşük mü?', 'stp-0002',
             'stp-0003'),
            ('stp-0002', 'Güç paketinin altına ve yağ soğutucusuna bakın.',
             'Belirgin bir yağ sızıntısı var mı?', 'end-leak', 'end-fill'),
            ('stp-0003', 'Yağın rengine ve kokusuna bakın.',
             'Yağ süt gibi açık renkli ya da yakıt kokulu mu?',
             'end-contaminated', 'stp-0004'),
            ('stp-0004', 'Bakım kaydından son yağ değişimine bakın; yağın '
             'koyuluğunu ve kokusunu kontrol edin.',
             'Değişim zamanı geçmiş ya da yağ çok koyu ve yanık kokulu mu?',
             'end-change', 'end-sensor'),
        ],
        'ends': [
            ('end-leak', 'Sızıntının yerini belirleyin; yağ soğutucusu ya '
             'da conta sızdırıyorsa bildirin.', code('DA1', '1', '310')),
            ('end-fill', 'Yağı tamamlayın ve motoru yeniden deneyin.',
             code('DA1', '2', '300')),
            ('end-contaminated', 'Yağa soğutma sıvısı ya da yakıt '
             'karışmış; motoru çalıştırmayın. Soğutma sıvısı seviyesini '
             'kontrol edip yetkili bakım birimine bildirin.',
             code('DA1', '3', '300')),
            ('end-change', 'Motor yağını ve yağ filtrelerini değiştirin.',
             code('DA1', '2', '241')),
            ('end-sensor', 'Seviye ve yağ normal: uyarı lambası ve gösterge '
             'devresini sınayın. Devre sağlamsa basınç algılayıcısı ya da yağ '
             'pompası arızalı olabilir; motoru çalıştırmayın ve bildirin.',
             code('DA4', '4', '320')),
        ],
    })

COOLANT_CHANGE = dm(
    code=code('DA1', '3', '220'), tech='Soğutma sıvısı',
    info='Boşaltma ve doldurma', figure=4,
    tools=[('Toplama kabı', 1), ('Lokma takımı', 1)],
    supplies=[('Soğutma sıvısı', None)],
    conditions=[PARKED, 'Motor soğumuş.', 'Motor güvertesi açık.'],
    warnings=['Soğutma sistemi sıcakken basınç altındadır. Motor soğumadan '
              'doldurma kapağını açmayın.', PPE],
    cautions=['Antifrizli suyu toprağa dökmeyin; toplayıp atık olarak '
              'verin.'],
    steps=[
        'Genleşme kabının kapağını yavaşça açın.',
        'Boşaltma tapalarının altına toplama kabı koyun ve tapaları açın.',
        'Sıvı bitince tapaları yeni contalarıyla kapatın.',
        'Sistemi el kitabındaki karışım oranında soğutma sıvısıyla '
        'doldurun.',
        'Motoru çalıştırıp sistemin havasını el kitabındaki yolla alın.',
        'Motor soğuduktan sonra seviyeyi yeniden kontrol edin ve '
        'tamamlayın.',
    ])

HOSE_CHANGE = dm(
    code=code('DA1', '3', '920'), tech='Soğutma hortumu', figure=4,
    tools=[('Tornavida takımı', 1), ('Toplama kabı', 1)],
    supplies=[('Soğutma sıvısı', None)],
    spares=[('Soğutma hortumu', 1), ('Hortum kelepçesi', 2)],
    conditions=[PARKED, 'Motor soğumuş.', 'Motor güvertesi açık.'],
    warnings=['Motor soğumadan soğutma sistemini açmayın.'],
    steps=[
        'Sistemdeki sıvıyı hortumun altına kadar boşaltın.',
        'Kelepçeleri gevşetin ve eski hortumu çıkarın.',
        'Boru ağızlarını temizleyin; çapak ve eski hortum parçası '
        'kalmamalıdır.',
        'Yeni hortumu ve yeni kelepçeleri takın, kelepçeleri sıkın.',
        'Sistemi doldurun, havasını alın ve motoru çalıştırıp kaçak '
        'kontrolü yapın.',
    ],
    next=code('DA1', '3', '220'))

FAN_CHECK = dm(
    code=code('DA1', '3', '310'), tech='Soğutma fanları ve fan tahriki',
    figure=4,
    conditions=[PARKED, 'Motor soğumuş.', 'Motor güvertesi açık.'],
    warnings=[HOT, 'Fan çevresinde çalışırken motorun çalıştırılmayacağından '
              'emin olun.'],
    steps=[
        'Fan kanatlarında çatlak, kırık ya da eğilme olup olmadığını kontrol '
        'edin.',
        'Fanları elle çevirin; sürtünme, takılma ya da boşluk olmamalıdır.',
        'Fan tahrikinin çevresinde yağ sızıntısı olup olmadığına bakın.',
        'Fan muhafazasının ve koruyucu ızgaranın bağlantılarını kontrol edin.',
        'Arızalı fan tahrikini yetkili bakım birimine bildirin.',
    ])

PRECLEANER = dm(
    code=code('DA1', '4', '250'), tech='Ön temizleyici ve toz atma çıkışı',
    figure=14,
    tools=[('Yumuşak kıllı fırça', 1), ('Basınçlı hava tabancası', 1)],
    conditions=[PARKED, 'Motor güvertesi açık.'],
    cautions=['Basınçlı havayı filtre elemanının içinden dışına tutmayın; '
              'eleman yırtılır.'],
    steps=[
        'Ön temizleyicinin girişlerindeki toz ve yaprakları fırçayla alın.',
        'Toz atma çıkışının ve hortumunun açık olduğunu kontrol edin.',
        'Toz atma fanının serbest döndüğünü kontrol edin.',
        'Tozlu arazide bu temizliği her gün yapın.',
    ])

INTAKE_CHECK = dm(
    code=code('DA1', '4', '310', '01'), tech='Hava emme kanalları',
    figure=14,
    tools=[('Tornavida takımı', 1)],
    spares=[('Hortum kelepçesi', 2)],
    conditions=[PARKED, 'Motor güvertesi açık.'],
    warnings=[HOT],
    cautions=['Filtreden sonraki kanala sızan toz motoru kısa sürede '
              'aşındırır; açık kanalla motoru çalıştırmayın.'],
    steps=[
        'Filtre yuvasından turboşarjlara giden kanalları boydan boya '
        'kontrol edin.',
        'Kanallarda yırtık, çatlak ya da sürtünme izi arayın.',
        'Kelepçeleri kontrol edin; gevşek kelepçeyi sıkın, bozuk olanı '
        'değiştirin.',
        'Filtreden sonraki kanalın içinde toz izi varsa bildirin.',
    ])

FUEL_FILTER = dm(
    code=code('DA1', '5', '920'), tech='Yakıt filtresi elemanı', figure=12,
    tools=[('Filtre anahtarı', 1), ('Toplama kabı', 1)],
    spares=[('Yakıt filtresi elemanı', 1)],
    conditions=[PARKED, MASTER_OFF],
    warnings=['Yakıt buharı yanıcıdır; açık alev bulundurmayın.', PPE],
    steps=[
        'Filtrenin altına toplama kabı koyun.',
        'Filtre kabını ya da elemanı sökün; yakıtı kaba boşaltın.',
        'Filtre yuvasını temizleyin, yeni elemanı ve contayı takın.',
        'Yakıt sisteminin havasını alın.',
        'Motoru çalıştırıp filtrede kaçak olmadığını kontrol edin.',
    ],
    next=code('DA1', '5', '230'))

FUEL_ISOLATE = dm(
    code=code('DA1', '5', '421'), tech='Yakıt sistemi',
    info='Motor tekliyor ya da zor çalışıyor: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA1-006',
        'descr': 'Motor zor çalışıyor, tekliyor ya da yük altında '
                 'duruyor; çevrede yakıt kokusu olabilir.',
        'steps': [
            ('stp-0001', 'Yakıt göstergesine ve tank kesme valflerine '
             'bakın.', 'Yakıt var ve valfler açık mı?', 'stp-0002',
             'end-refuel'),
            ('stp-0002', 'Yakıt borularında, filtrede ve tank '
             'bağlantılarında ıslaklık arayın.', 'Yakıt sızıntısı var mı?',
             'end-leak', 'stp-0003'),
            ('stp-0003', 'Su ayırıcıya bakın.', 'Su ya da tortu var mı?',
             'end-water', 'stp-0004'),
            ('stp-0004', 'Son yakıt ikmalinde ya da filtre değişiminde '
             'sistemin açılıp açılmadığını bakım kaydından kontrol edin.',
             'Sistem yakın zamanda açıldı ya da yakıt bitti mi?', 'end-air',
             'end-filter'),
        ],
        'ends': [
            ('end-refuel', 'Yakıt ikmali yapın ya da valfleri açın.',
             code('DA1', '5', '210')),
            ('end-leak', 'Motoru çalıştırmayın; sızıntının yerini belirleyip '
             'boruları muayene edin.', code('DA1', '5', '310')),
            ('end-water', 'Su ayırıcıyı boşaltın.', code('DA1', '5', '300')),
            ('end-air', 'Sistemde hava var; havasını alın.',
             code('DA1', '5', '230')),
            ('end-filter', 'Yakıt filtresi elemanını değiştirin. Sorun '
             'sürerse besleme pompası arızalı olabilir; bildirin.',
             code('DA1', '5', '920')),
        ],
    })

FUEL_BLEED = dm(
    code=code('DA1', '5', '230'), tech='Yakıt sistemi', info='Hava alma',
    figure=12,
    tools=[('Toplama kabı', 1), ('Temiz bez', None)],
    conditions=[PARKED, 'Tanklarda yakıt var.'],
    warnings=['Yakıt buharı yanıcıdır; açık alev bulundurmayın.'],
    steps=[
        'Filtre üstündeki hava alma vidasının altına bez ve kap koyun.',
        'Vidayı gevşetin ve el pompasıyla ya da el kitabındaki yolla yakıt '
        'basın.',
        'Kabarcıksız yakıt gelince vidayı sıkın.',
        'Motoru çalıştırın; ilk çalıştırmada birkaç deneme gerekebilir. '
        'Marşı uzun süre kesintisiz çevirmeyin.',
        'Dökülen yakıtı silin.',
    ])

FUEL_LINES = dm(
    code=code('DA1', '5', '310'), tech='Yakıt boruları ve doldurma kapakları',
    figure=12, conditions=[PARKED],
    warnings=['Yakıt buharı yanıcıdır; açık alev bulundurmayın.'],
    steps=[
        'Yakıt borularını ve hortumlarını erişebildiğiniz yerlerde boydan '
        'boya kontrol edin; ıslaklık, çatlak ve sürtünme arayın.',
        'Bağlantı rakorlarında ve kelepçelerde yakıt izi olup olmadığına '
        'bakın.',
        'Doldurma kapaklarının contalarını kontrol edin; bozuk conta yakıta '
        'su ve toz girmesine yol açar.',
        'Sızıntı varsa motoru çalıştırmayın ve bildirin.',
    ])

# Güç aktarma
TRANS_OIL_CHANGE = dm(
    code=code('DA2', '1', '241'), tech='Şanzıman yağı ve filtresi',
    info='Değişim', figure=13,
    tools=[('Lokma takımı', 1), ('Yağ toplama kabı', 1)],
    supplies=[('Şanzıman yağı', None)],
    spares=[('Şanzıman yağ filtresi elemanı', 1)],
    conditions=[PARKED, 'Şanzıman çalışma sıcaklığında, motor durdurulmuş.'],
    warnings=['Sıcak yağ yakar. ' + PPE],
    cautions=['Atık yağı toprağa dökmeyin.'],
    steps=[
        'Boşaltma tapasının altına toplama kabını koyun ve tapayı sökün.',
        'Yağ bitince tapayı yeni contasıyla takın.',
        'Filtre kapağını açın, eski elemanı çıkarın, yeni elemanı ve '
        'contayı takın.',
        'Şanzımanı el kitabında belirtilen yağla doldurun.',
        'Motoru çalıştırıp vitesleri el kitabındaki sırayla geçirin.',
        'Seviyeyi el kitabındaki sıcaklıkta yeniden kontrol edin.',
    ])

TRANS_ISOLATE = dm(
    code=code('DA2', '1', '421'), tech='Şanzıman',
    info='Vites ve dönüş sorunları: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA2-001',
        'descr': 'Vitesler sert ya da geç geçiyor, tank dönüşlerde '
                 'zorlanıyor ya da şanzıman sıcaklık uyarısı yanıyor.',
        'steps': [
            ('stp-0001', 'Şanzıman yağı seviyesini kontrol edin.',
             'Seviye düşük mü?', 'stp-0002', 'stp-0003'),
            ('stp-0002', 'Şanzımanın altına ve yağ soğutucusuna bakın.',
             'Yağ sızıntısı var mı?', 'end-leak', 'end-fill'),
            ('stp-0003', 'Yağın rengine ve kokusuna bakın.',
             'Yağ koyu ve yanık kokulu mu?', 'end-change', 'stp-0004'),
            ('stp-0004', 'Sıcaklık uyarısı yanıyorsa radyatörleri ve '
             'ızgaraları kontrol edin.', 'Radyatör ya da ızgara kirli mi?',
             'end-clean', 'stp-0005'),
            ('stp-0005', 'Sürüş kumandalarını ve vites seçiciyi kontrol '
             'edin.', 'Kumanda bağlantısı gevşek ya da sıkışık mı?',
             'end-controls', 'end-service'),
        ],
        'ends': [
            ('end-leak', 'Sızıntının yerini belirleyin ve bildirin.',
             code('DA2', '1', '310')),
            ('end-fill', 'Şanzıman yağını tamamlayın.',
             code('DA2', '1', '300')),
            ('end-change', 'Yağı ve filtreyi değiştirin; metal parçacık '
             'varsa bildirin.', code('DA2', '1', '241')),
            ('end-clean', 'Radyatörleri ve ızgaraları temizleyin.',
             code('DA1', '3', '250')),
            ('end-controls', 'Kumanda bağlantılarını yağlayın; boşluk ya '
             'da hasar varsa bildirin.', code('DA2', '4', '240')),
            ('end-service', 'Şanzıman içi arıza olabilir; yetkili bakım '
             'birimine bildirin.', None),
        ],
    })

TRANS_CHECK = dm(
    code=code('DA2', '1', '310'), tech='Şanzıman ve yağ soğutucusu',
    figure=13, conditions=[PARKED, 'Motor güvertesi açık.'],
    warnings=[HOT],
    steps=[
        'Şanzıman gövdesinde, tapalarda ve contalarda yağ izi arayın.',
        'Şanzıman yağ soğutucusunun borularını ve bağlantılarını kontrol '
        'edin.',
        'Havalandırma (nefeslik) çıkışının tıkalı olmadığını kontrol edin.',
        'Kablo ve kumanda bağlantılarının yerinde olduğunu kontrol edin.',
    ])

FD_OIL_CHANGE = dm(
    code=code('DA2', '2', '241'), tech='Son dişli yağı', info='Değişim',
    figure=13,
    tools=[('Lokma takımı', 1), ('Yağ toplama kabı', 1)],
    supplies=[('Dişli yağı', None)],
    conditions=[PARKED],
    warnings=['Sıcak yağ yakar. ' + PPE],
    steps=[
        'Boşaltma tapasının altına toplama kabını koyun, boşaltma ve seviye '
        'tapalarını sökün.',
        'Tapanın mıknatısındaki metal tozuna bakın; iri parçacık varsa '
        'bildirin.',
        'Boşaltma tapasını yeni contasıyla takın.',
        'Seviye tapası deliğinden taşana kadar el kitabındaki yağdan '
        'doldurun, tapayı takın.',
        'İki yanı da aynı şekilde değiştirin.',
    ])

BRAKE_TEST = dm(
    code=code('DA2', '3', '320'), tech='Servis ve park freni',
    info='Çalışma testi',
    conditions=['Tank düz, sert ve boş bir zeminde.',
                'Çevrede kimse yok.'],
    warnings=['Testi yalnız eğitimli sürücü yapar; gözlemci tankın önünde '
              've arkasında durmaz.'],
    steps=[
        'Motoru çalıştırın, yağ basıncının ve fren uyarılarının normal '
        'olduğunu kontrol edin.',
        'Tankı yavaş hızda sürün ve servis frenine basın; tank düz '
        'çizgide durmalıdır.',
        'Bir yana çekme, sarsıntı ya da olağan dışı ses varsa kayda geçirin.',
        'Park frenini çekin ve el kitabındaki yolla tutup tutmadığını '
        'deneyin.',
        'Test sonrası fren bölgesinden yanık kokusu ya da duman gelmemelidir.',
    ])

BRAKE_ISOLATE = dm(
    code=code('DA2', '3', '421'), tech='Frenler',
    info='Fren zayıf ya da tank bir yana çekiyor: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA2-002',
        'descr': 'Servis freni zayıf tutuyor, frenlemede tank bir yana '
                 'çekiyor ya da park freni tutmuyor.',
        'steps': [
            ('stp-0001', 'Gösterge panelinde fren ya da şanzıman uyarısı '
             'olup olmadığına bakın.', 'Uyarı var mı?', 'end-trans',
             'stp-0002'),
            ('stp-0002', 'Yalnız park freni tutmuyorsa park freni '
             'bağlantısını kontrol edin.', 'Sorun yalnız park freninde mi?',
             'end-park', 'stp-0004'),
            ('stp-0004', 'Kısa bir sürüşten sonra yanık balata kokusu olup '
             'olmadığına, park freni uyarısının sürüşte yanıp yanmadığına '
             've park freni kolunun tam inip inmediğine bakın.',
             'Park freni tam çözülmüyor mu?', 'end-park', 'stp-0003'),
            ('stp-0003', 'Palet gerginliğini iki yanda karşılaştırın.',
             'İki paletin gerginliği belirgin farklı mı?', 'end-track',
             'end-service'),
        ],
        'ends': [
            ('end-trans', 'Şanzıman yağı ve sıcaklığını kontrol edin.',
             code('DA2', '1', '421')),
            ('end-park', 'Park freni kumandasını ve bağlantısını muayene '
             'edin.', code('DA2', '4', '310')),
            ('end-track', 'Palet gerginliğini ayarlayıp freni yeniden '
             'deneyin.', code('DA3', '1', '271')),
            ('end-service', 'Servis frenleri aşınmış olabilir; tankı '
             'kullanmayın, yetkili bakım birimine bildirin.',
             code('DA2', '3', '320')),
        ],
    })

CONTROLS_CHECK = dm(
    code=code('DA2', '4', '310'), tech='Sürüş kumandaları',
    conditions=[PARKED, MASTER_OFF],
    steps=[
        'Sürücü yerinde direksiyon kumandasının, fren ve gaz pedallarının '
        'serbest hareket ettiğini kontrol edin.',
        'Vites seçicinin her konuma rahatça geçtiğini kontrol edin.',
        'Park freni kolunun kavradığını ve bıraktığını kontrol edin.',
        'Pedalların altında ve kumanda bağlantılarının çevresinde yabancı '
        'cisim olmadığını kontrol edin.',
        'Gevşek, sıkışık ya da boşluklu kumandayı bildirin.',
    ])

CONTROLS_GREASE = dm(
    code=code('DA2', '4', '240'), tech='Kumanda bağlantıları',
    info='Yağlama',
    tools=[('Yağdanlık', 1), ('Temiz bez', None)],
    supplies=[('Hafif makine yağı', None)],
    conditions=[PARKED, MASTER_OFF],
    steps=[
        'Pedal ve kol mafsallarını silin.',
        'Mafsallara birkaç damla yağ verin.',
        'Kumandaları birkaç kez hareket ettirip yağın dağılmasını sağlayın.',
        'Taşan yağı silin; pedallar kaygan kalmamalıdır.',
    ])

# Yürüyen takım
TRACK_REMOVE = dm(
    code=code('DA3', '1', '520'), tech='Palet', info='Sökme ve takma',
    figure=6,
    tools=[('Palet aletleri', 1), ('Palet gerdirme anahtarı', 1),
           ('Kaldırma askısı', 1)],
    conditions=[PARKED, 'Tank düz ve sert zeminde.'],
    warnings=['Palet ağırdır ve gerilim altındadır. Gerginliği almadan '
              'bağlantıyı açmayın; paletin önünde durmayın.',
              'Bu işi en az üç kişi yapar.'],
    steps=[
        'Paletin açılacak bağlantısını yürütücü dişli ile avara arasında, '
        'üst kolda olacak şekilde getirin.',
        'Gerdirme tertibatıyla avarayı geri alarak gerginliği boşaltın.',
        'Palet aletleriyle bağlantı parçasını sökün ve paleti ayırın.',
        'Tankı paletin üstünden yavaşça sürerek ya da paleti çekerek '
        'ayırın.',
        ('Takarken', [
            'Paleti tankın önüne serin, tankı üstüne sürün.',
            'Paleti yürütücü dişlinin ve avaranın üstünden geçirip iki ucu '
            'palet aletleriyle birleştirin.',
            'Bağlantı parçasını takın ve gerginliği ayarlayın.',
        ]),
    ],
    next=code('DA3', '1', '271'))

CONNECTORS = dm(
    code=code('DA3', '1', '920', '01'), tech='Palet bağlantı parçaları',
    figure=3,
    tools=[('Palet aletleri', 1), ('Tork anahtarı', 1)],
    spares=[('Palet bağlantı parçası', 2)],
    conditions=[PARKED],
    warnings=['Palet gerilim altındadır; işe başlamadan gerginliği '
              'boşaltın.'],
    steps=[
        'Değiştirilecek bağlantı parçasını erişilebilir yere getirin.',
        'Palet gerginliğini boşaltın.',
        'Bağlantı parçasının kama cıvatasını sökün ve parçayı çıkarın.',
        'Pim uçlarını temizleyin, yeni bağlantı parçasını takın.',
        'Kama cıvatasını el kitabındaki torkta sıkın ve gerginliği '
        'ayarlayın.',
        'Kısa bir sürüşten sonra cıvataları yeniden kontrol edin.',
    ],
    next=code('DA3', '1', '271'))

HUB_ISOLATE = dm(
    code=code('DA3', '2', '421'), tech='Yol tekerleği',
    info='Göbek ısınıyor: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA3-002',
        'descr': 'Sürüşten sonra bir tekerlek göbeği diğerlerinden çok '
                 'daha sıcak ya da göbekten yağ sızıyor.',
        'steps': [
            ('stp-0001', 'Sıcak göbeğin kapağına ve çevresine bakın.',
             'Göbekten yağ sızıyor ya da kapak eksik mi?', 'end-hub',
             'stp-0002'),
            ('stp-0002', 'Tekerleğin lastik bandajına bakın.',
             'Bandaj parçalanmış ya da ayrılmış mı?', 'end-wheel',
             'stp-0003'),
            ('stp-0003', 'Tekerleğin diğerleriyle aynı hizada durduğunu '
             'kontrol edin.', 'Tekerlek belirgin şekilde yukarıda ya da '
             'aşağıda mı?', 'end-torsion', 'end-bearing'),
        ],
        'ends': [
            ('end-hub', 'Göbek keçesi ya da rulman arızalı; tekerleği '
             'değiştirin.', code('DA3', '2', '920')),
            ('end-wheel', 'Yol tekerleğini değiştirin.',
             code('DA3', '2', '920')),
            ('end-torsion', 'Burulma çubuğu ya da salıncak kolu arızalı '
             'olabilir; yetkili bakım birimine bildirin.',
             code('DA3', '2', '310')),
            ('end-bearing', 'Rulman aşınmış olabilir; tekerleği değiştirin.',
             code('DA3', '2', '920')),
        ],
    })

WHEEL_CHANGE = dm(
    code=code('DA3', '2', '920'), tech='Yol tekerleği', figure=15,
    tools=[('Palet aletleri', 1), ('Kriko', 1), ('Lokma takımı', 1),
           ('Tork anahtarı', 1)],
    spares=[('Yol tekerleği', 1)],
    conditions=[PARKED, 'Palet gerginliği boşaltılmış.'],
    warnings=['Yol tekerleği ağırdır; kaldırma düzeni kullanın.',
              'Kriko ile kaldırılmış salıncak kolunun altına elinizi '
              'sokmayın.'],
    steps=[
        'Yan etek panelini sökün.',
        'Palet gerginliğini boşaltın ve paleti tekerleğin üstünden kaldırın.',
        'Salıncak kolunu el kitabındaki yolla kaldırıp destekleyin.',
        'Tekerlek somunlarını sökün ve tekerleği çıkarın.',
        'Göbek yüzeyini temizleyin, yeni tekerleği takın ve somunları el '
        'kitabındaki torkta sıkın.',
        'Salıncak kolunu indirin, paleti yerine alın ve gerginliği ayarlayın.',
    ],
    next=code('DA3', '1', '271'))

DAMPER_CHANGE = dm(
    code=code('DA3', '2', '920', '01'), tech='Amortisör', figure=15,
    tools=[('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Amortisör', 1)],
    conditions=[PARKED, 'Salıncak kolu desteklenmiş.'],
    warnings=['Salıncak kolunu desteklemeden amortisörü sökmeyin.'],
    steps=[
        'Yan etek panelini sökün.',
        'Amortisörün alt ve üst bağlantı cıvatalarını sökün.',
        'Amortisörü çıkarın; bağlantı burçlarını kontrol edin.',
        'Yeni amortisörü takın ve cıvataları el kitabındaki torkta sıkın.',
        'Yan etek panelini takın.',
    ])

ARM_GREASE = dm(
    code=code('DA3', '2', '240'), tech='Salıncak kolu yatakları',
    info='Gresleme', figure=15,
    tools=[('Gres pompası', 1), ('Temiz bez', None)],
    supplies=[('Gres', None)],
    conditions=[PARKED],
    steps=[
        'Gerekiyorsa yan etek panellerini sökün.',
        'Her salıncak kolu yatağının gresörlüğünü silin.',
        'Gres taze olarak görünene kadar basın.',
        'Destek makaralarının gresörlüklerini de aynı şekilde gresleyin.',
        'Taşan gresi silin, panelleri takın.',
    ])

ROLLERS = dm(
    code=code('DA3', '2', '310', '01'), tech='Destek makaraları', figure=15,
    conditions=[PARKED],
    steps=[
        'Paletin üst kolunu taşıyan destek makaralarına yan eteklerin '
        'altından ya da paneller sökülerek bakın.',
        'Makaraların lastik bandajlarında kopma, göbeklerinde yağ sızıntısı '
        'olup olmadığını kontrol edin.',
        'Sürüşten sonra makaraların döndüğünü gösteren parlak iz olmalıdır; '
        'dönmeyen makara palet üstünde aşınma izi bırakır.',
        'Arızalı makarayı bildirin.',
    ])

SPROCKET_RING = dm(
    code=code('DA3', '3', '920'), tech='Yürütücü dişli çemberi', figure=3,
    tools=[('Palet aletleri', 1), ('Lokma takımı', 1), ('Tork anahtarı', 1)],
    spares=[('Yürütücü dişli çemberi', 1)],
    conditions=[PARKED, 'Palet yürütücü dişliden ayrılmış.'],
    warnings=['Dişli çemberi ağırdır; iki kişiyle çalışın.'],
    steps=[
        'Paleti yürütücü dişliden ayırın.',
        'Çemberin bağlantı cıvatalarını sökün ve çemberi çıkarın.',
        'Göbek yüzeyini temizleyin.',
        'Yeni çemberi takın ve cıvataları el kitabındaki torkta, çapraz '
        'sırayla sıkın.',
        'Dişli çemberleri her iki yanda birlikte değiştirmek palet ömrünü '
        'korur.',
        'Paleti takın ve gerginliği ayarlayın.',
    ],
    next=code('DA3', '1', '520'))

IDLER_GREASE = dm(
    code=code('DA3', '3', '240'), tech='Avara ve gerdirme tertibatı',
    info='Gresleme', figure=6,
    tools=[('Gres pompası', 1), ('Temiz bez', None)],
    supplies=[('Gres', None)],
    conditions=[PARKED],
    steps=[
        'Avara kolunun ve gerdirme tertibatının gresörlüklerini silin.',
        'Gres taze olarak görünene kadar basın.',
        'Gerdirme tertibatının vidasını ve korumasını temizleyin.',
        'Taşan gresi silin.',
    ])

# Elektrik
ELECTRICAL = dm(
    code=code('DA4'), tech='Elektrik sistemi', figure=8,
    description=[
        ('Genel', [
            '24 V doğru akım sistemi motor dururken akülerden, motor '
            'çalışırken jeneratörden beslenir.',
            'Aküler sürücü bölmesinin yanındaki akü kutularındadır. Ana '
            'şalter aküleri sistemden ayırır.',
            'Sigorta ve devre kesici panoları sürücü bölmesinde ve kulededir. '
            'Kablo demetleri gövde ile kule arasında döner bağlantıdan geçer.',
            'Takviye prizi, başka bir araçtan ya da dış kaynaktan '
            'çalıştırma ve şarj için kullanılır.',
        ]),
        ('İç haberleşme', [
            'Mürettebat başlıkları ve kumanda kutularıyla dört kişi birbiriyle '
            'konuşur. Bu şablon yalnız düzenin denenmesini ve bağlantı '
            'kontrollerini kapsar.',
        ]),
    ])

CHARGE_ISOLATE = dm(
    code=code('DA4', info='421'), tech='Elektrik sistemi',
    info='Aküler şarj olmuyor: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA4-001',
        'descr': 'Motor çalışırken şarj göstergesi şarjı göstermiyor, '
                 'farlar sönük ya da aküler sık sık boşalıyor.',
        'steps': [
            ('stp-0001', 'Motoru çalıştırın ve şarj göstergesine bakın.',
             'Gösterge şarjı gösteriyor mu?', 'stp-0003', 'stp-0002'),
            ('stp-0002', 'Jeneratör kablolarını ve bağlantılarını kontrol '
             'edin.', 'Gevşek, kopuk ya da oksitli bağlantı var mı?',
             'end-wiring', 'end-generator'),
            ('stp-0003', 'Akü kutup başlarını ve akü gerilimini kontrol '
             'edin.', 'Kutup başları oksitli ya da gevşek mi?', 'end-terminals',
             'stp-0004'),
            ('stp-0004', 'Motor dururken akülerin kısa sürede boşalıp '
             'boşalmadığını kayıtlardan kontrol edin.',
             'Aküler bekleyişte boşalıyor mu?', 'end-drain', 'end-battery'),
        ],
        'ends': [
            ('end-wiring', 'Bağlantıları temizleyin ve sıkın.',
             code('DA4', '3', '310')),
            ('end-generator', 'Jeneratör ya da gerilim düzenleyici arızalı '
             'olabilir; yetkili bakım birimine bildirin.',
             code('DA4', '3', '310')),
            ('end-terminals', 'Kutup başlarını temizleyin ve sıkın.',
             code('DA4', '1', '300')),
            ('end-drain', 'Bir devre akım çekiyor olabilir; kablo '
             'demetlerini kontrol edin.', code('DA4', '4', '310')),
            ('end-battery', 'Aküleri şarj edin; şarj tutmayan aküyü '
             'değiştirin.', code('DA4', '1', '210')),
        ],
    })

BATTERY_CHARGE = dm(
    code=code('DA4', '1', '210'), tech='Aküler', info='Şarj', figure=8,
    tools=[('Akü şarj cihazı', 1), ('Voltmetre', 1)],
    conditions=[PARKED, MASTER_OFF, 'Çevre iyi havalandırılmış.'],
    warnings=['Şarj sırasında patlayıcı gaz çıkar; kıvılcım ve açık alev '
              'bulundurmayın.', 'Akü asidi yakıcıdır. ' + PPE],
    steps=[
        'Akü bölmesini açın ve havalandırın.',
        'Şarj cihazını kapalıyken akülere doğru kutuplarla bağlayın.',
        'Cihazı el kitabındaki şarj yöntemine göre ayarlayıp açın.',
        'Şarj bitince cihazı kapatın, sonra kabloları ayırın.',
        'Akü gerilimini ölçün; şarj tutmayan aküyü değiştirin.',
    ])

LIGHT_ISOLATE = dm(
    code=code('DA4', '2', '421'), tech='Aydınlatma',
    info='Lamba yanmıyor: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA4-002',
        'descr': 'Bir far, köşe lambası ya da arka lamba yanmıyor ya da '
                 'kesik kesik yanıyor.',
        'steps': [
            ('stp-0001', 'Aynı devredeki diğer lambalara bakın.',
             'Devredeki bütün lambalar mı yanmıyor?', 'stp-0002',
             'stp-0003'),
            ('stp-0002', 'Devrenin sigortasını ya da devre kesicisini '
             'kontrol edin.', 'Sigorta atmış mı?', 'end-fuse', 'end-wiring'),
            ('stp-0003', 'Lamba muhafazasını açıp ampule ve sokete bakın.',
             'Ampul yanmış ya da soket oksitli mi?', 'end-bulb', 'stp-0004'),
            ('stp-0004', 'Lamba camında ve muhafazasında kırık ya da su '
             'birikmesi var mı bakın.', 'Muhafaza hasarlı mı?', 'end-unit',
             'end-wiring'),
        ],
        'ends': [
            ('end-fuse', 'Sigortayı değiştirin; yeniden atarsa kısa devre '
             'arayın.', code('DA4', '4', '920')),
            ('end-wiring', 'Lamba kablosunu ve konnektörünü kontrol edin.',
             code('DA4', '4', '310')),
            ('end-bulb', 'Ampulü değiştirin, soketi temizleyin.',
             code('DA4', '2', '920')),
            ('end-unit', 'Lamba grubunu değiştirin.',
             code('DA4', '2', '920', '01')),
        ],
    })

LIGHT_CHECK = dm(
    code=code('DA4', '2', '310'), tech='Aydınlatma ve sinyal lambaları',
    figure=10, conditions=[PARKED],
    steps=[
        'Farları, köşe lambalarını, arka lambaları ve konvoy lambasını '
        'sırayla yakın; ikinci bir kişi çevreden kontrol etsin.',
        'Fren lambalarını ve sinyalleri deneyin.',
        'Lamba camlarında kırık, buğu ya da su birikmesi olup olmadığına '
        'bakın.',
        'Lamba koruyucularının ve bağlantılarının sağlam olduğunu kontrol '
        'edin.',
        'İç aydınlatmayı ve gösterge aydınlatmasını deneyin.',
    ])

TAIL_CHANGE = dm(
    code=code('DA4', '2', '920', '01'), tech='Arka lamba grubu', figure=11,
    tools=[('Tornavida takımı', 1), ('Lokma takımı', 1)],
    spares=[('Arka lamba grubu', 1)],
    conditions=[PARKED, 'Aydınlatma anahtarı kapalı.'],
    steps=[
        'Lamba grubunun konnektörünü ayırın.',
        'Bağlantı vidalarını sökün ve lamba grubunu çıkarın.',
        'Yuvayı temizleyin; konnektörde oksit varsa temizleyin.',
        'Yeni lamba grubunu contasıyla takın ve konnektörü bağlayın.',
        'Bütün arka lambaları yakarak kontrol edin.',
    ])

STARTER_ISOLATE = dm(
    code=code('DA4', '3', '421'), tech='Marş sistemi',
    info='Marş dönmüyor: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA4-003',
        'descr': 'Marşa basınca marş motoru dönmüyor ya da yalnız tık sesi '
                 'geliyor; aküler dolu görünüyor.',
        'steps': [
            ('stp-0001', 'Ana şalterin açık olduğunu ve uyarı lambalarının '
             'yandığını kontrol edin.', 'Lambalar yanıyor mu?', 'stp-0002',
             'end-master'),
            ('stp-0002', 'Vites seçicinin el kitabındaki çalıştırma '
             'konumunda olduğunu kontrol edin.', 'Seçici doğru konumda mı?',
             'stp-0003', 'end-neutral'),
            ('stp-0003', 'Marşa basarken marş motoru bölgesini dinleyin.',
             'Yalnız tık sesi mi geliyor?', 'stp-0004', 'end-starter'),
            ('stp-0004', 'Takviyeyle çalıştırma denendiyse takviye prizine '
             'bakın.', 'Takviye prizi ısınmış, kararmış ya da içinde kir ve '
             'pas var mı?', 'end-slave', 'end-cables'),
        ],
        'ends': [
            ('end-master', 'Ana şalteri ve akü bağlantılarını kontrol edin.',
             code('DA4', '1', '300')),
            ('end-neutral', 'Vites seçiciyi çalıştırma konumuna alın ve '
             'yeniden deneyin.', code('DA2', '4', '310')),
            ('end-cables', 'Marş motoru kablolarını ve bağlantılarını '
             'kontrol edin; gerekiyorsa takviyeyle çalıştırın.',
             code('DA4', '3', '310')),
            ('end-slave', 'Takviye prizini muayene edin ve temizleyin.',
             code('DA4', '4', '310', '01')),
            ('end-starter', 'Marş motoru ya da rölesi arızalı olabilir; '
             'yetkili bakım birimine bildirin.', None),
        ],
    })

CHARGE_CHECK = dm(
    code=code('DA4', '3', '310'), tech='Jeneratör ve marş motoru bağlantıları',
    figure=2, tools=[('Lokma takımı', 1), ('Kutup başı fırçası', 1)],
    conditions=[PARKED, MASTER_OFF, 'Motor güvertesi açık.'],
    warnings=[HOT],
    steps=[
        'Jeneratörün ve marş motorunun kablo bağlantılarını kontrol edin.',
        'Oksitli bağlantıyı ayırıp temizleyin, yeniden sıkın.',
        'Kabloların sıcak parçalara ve keskin kenarlara değmediğini kontrol '
        'edin.',
        'Jeneratörün çevresinde yağ ya da su olup olmadığına bakın.',
    ])

HARNESS = dm(
    code=code('DA4', '4', '310'), tech='Kablo demetleri ve konnektörler',
    conditions=[PARKED, MASTER_OFF],
    steps=[
        'Erişebildiğiniz kablo demetlerini boydan boya kontrol edin; '
        'sürtünme, ezilme, yanık izi ve açıkta kalmış tel arayın.',
        'Konnektörlerin tam oturduğunu ve kilitlerinin kapalı olduğunu '
        'kontrol edin.',
        'Gevşek demet bağlarını ve kelepçeleri tamamlayın.',
        'Islak konnektörü ayırıp kurulayın; oksit varsa temizleyin.',
        'Hasarlı demeti yetkili bakım birimine bildirin.',
    ])

FUSE = dm(
    code=code('DA4', '4', '920'), tech='Sigorta',
    spares=[('Sigorta takımı', 1)],
    conditions=[PARKED, 'İlgili devrenin anahtarı kapalı.'],
    cautions=['Sigortayı yalnız aynı değerde bir sigortayla değiştirin; '
              'daha büyük sigorta kablo yangınına yol açabilir.'],
    steps=[
        'Arızalı devrenin sigortasını panodaki etiketten bulun.',
        'Sigortayı çıkarın ve teline bakın.',
        'Aynı değerde yeni sigortayı takın.',
        'Devreyi açıp deneyin. Sigorta yeniden atarsa kısa devre vardır; '
        'kablo demetini kontrol edin.',
    ])

SLAVE = dm(
    code=code('DA4', '4', '200'), tech='Tank', info='Takviyeyle çalıştırma',
    figure=8,
    tools=[('Takviye kablosu', 1)],
    conditions=['Takviye veren araç ya da kaynak hazır.'],
    warnings=['Takviye kablosunu yalnız takviye prizinden bağlayın; akü '
              'kutup başlarına doğrudan kıskaç takmayın.',
              'İki aracın da ana şalteri kapalıyken bağlantı yapın.'],
    steps=[
        'Takviye prizinin kapağını açın; prizi temizleyin.',
        'Takviye kablosunu önce takviye veren araca, sonra bu tanka takın.',
        'Takviye veren aracın motorunu çalıştırın.',
        'Bu tankın ana şalterini açın ve motoru el kitabındaki yolla '
        'çalıştırın.',
        'Motor çalışınca kabloyu ters sırayla ayırın ve priz kapağını '
        'kapatın.',
    ])

INTERCOM_TEST = dm(
    code=code('DA4', '5', '320'), tech='İç haberleşme düzeni',
    info='Çalışma testi',
    conditions=[PARKED, 'Ana şalter açık.'],
    steps=[
        'Dört mürettebat yerindeki başlıkları ve kumanda kutularını takın.',
        'Her yerden sırayla konuşup diğer üç yerde duyulduğunu kontrol '
        'edin.',
        'Başlık kablolarında ve fişlerinde kopukluk ya da gevşeklik olup '
        'olmadığına bakın.',
        'Gövde dışı konuşma düzeni varsa onu da deneyin.',
    ])

INTERCOM_ISOLATE = dm(
    code=code('DA4', '5', '421'), tech='İç haberleşme',
    info='Ses yok ya da cızırtı var: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA4-004',
        'descr': 'Bir ya da daha çok mürettebat yerinde ses gelmiyor, ses '
                 'kesik kesik geliyor ya da cızırtı var.',
        'steps': [
            ('stp-0001', 'Sorunlu yerin başlığını başka bir yerde deneyin.',
             'Sorun başlıkla birlikte taşınıyor mu?', 'end-headset',
             'stp-0002'),
            ('stp-0002', 'Kumanda kutusunun fişini ve kablosunu kontrol '
             'edin.', 'Fiş gevşek ya da kablo hasarlı mı?', 'end-cable',
             'stp-0003'),
            ('stp-0003', 'Düzenin sigortasını kontrol edin.',
             'Sigorta atmış mı?', 'end-fuse', 'end-service'),
        ],
        'ends': [
            ('end-headset', 'Başlığı değiştirin.', code('DA4', '5', '320')),
            ('end-cable', 'Bağlantıyı düzeltin ya da kabloyu değiştirin.',
             code('DA4', '4', '310')),
            ('end-fuse', 'Sigortayı değiştirin.', code('DA4', '4', '920')),
            ('end-service', 'Kumanda kutusu ya da ana ünite arızalı '
             'olabilir; yetkili bakım birimine bildirin.', None),
        ],
    })

# Silah ve optikler (yalnız dış muayene ve optik temizliği)
OPTICS_ISOLATE = dm(
    code=code('DA5', '2', '421'), tech='Optikler',
    info='Görüntü bulanık ya da buğulu: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA5-001',
        'descr': 'Nişancı optiğinden, komutan periskobundan ya da sürücü '
                 'periskobundan görüntü bulanık, lekeli ya da buğulu.',
        'steps': [
            ('stp-0001', 'Optiğin dış camına bakın.',
             'Camda toz, çamur ya da su lekesi var mı?', 'end-clean',
             'stp-0002'),
            ('stp-0002', 'Koruyucu kapağın ve camın kenarlarına bakın.',
             'Camda çatlak ya da kırık var mı?', 'end-damaged', 'stp-0003'),
            ('stp-0003', 'Camın iç yüzüne bakın.', 'Buğu camın içinde mi?',
             'end-moisture', 'end-clean'),
        ],
        'ends': [
            ('end-clean', 'Optik camını temizleyin.', code('DA5', '2', '250')),
            ('end-damaged', 'Sürücü periskobu ise değiştirin; kule '
             'optiklerini yetkili birime bildirin.',
             code('DA5', '2', '920')),
            ('end-moisture', 'Optiğin içine nem girmiş; optiği açmayın, '
             'yetkili bakım birimine bildirin.', code('DA5', '2', '310')),
        ],
    })

OPTICS_COVERS = dm(
    code=code('DA5', '2', '310'), tech='Optik koruyucu kapakları ve camları',
    figure=5, conditions=[PARKED, 'Kule kilitli.'], warnings=[WEAPONS_SAFE],
    steps=[
        'Nişancı optiğinin ve komutan periskobunun koruyucu kapaklarını açıp '
        'kapatın; menteşe ve kilitleri kontrol edin.',
        'Camlarda çizik, çatlak ve kaplama hasarı olup olmadığına bakın.',
        'Kapak contalarının yerinde olduğunu kontrol edin.',
        'Sürücü ve kapak periskoplarının camlarını kontrol edin.',
        'Optiklerin içine müdahale etmeyin; hasarı bildirin.',
    ])

PERISCOPE = dm(
    code=code('DA5', '2', '920'), tech='Sürücü periskobu',
    tools=[('Tornavida takımı', 1)],
    spares=[('Sürücü periskobu', 1)],
    conditions=[PARKED, 'Sürücü kapağı kapalı.'],
    cautions=['Periskobun camlarına çıplak elle dokunmayın.'],
    steps=[
        'Periskobun iç tarafındaki tutucuyu açın.',
        'Periskobu yuvasından aşağı doğru çıkarın.',
        'Yuvayı ve contayı temizleyin.',
        'Yeni periskobu contasıyla yerleştirin ve tutucuyu kilitleyin.',
        'Dış camı temizleyin ve görüşü kontrol edin.',
    ])

MUZZLE_COVER = dm(
    code=code('DA5', '1', '920'), tech='Namlu ağzı koruyucu kapağı',
    figure=16,
    spares=[('Namlu ağzı koruyucu kapağı', 1)],
    conditions=[PARKED, 'Kule ve top kilitli.'],
    warnings=[WEAPONS_SAFE],
    steps=[
        'Eski kapağı namlu ağzından çıkarın; namluya hiçbir cisim '
        'sokmayın.',
        'Yeni kapağı namlu ağzına tam oturacak şekilde takın.',
        'Kapağın bağlantı kayışını sabitleyin.',
        'Değişikliği silah sorumlusuna bildirin.',
    ])

MG_CHECK = dm(
    code=code('DA5', '3', '310'), tech='Makineli tüfek kundağı',
    info='Dış muayene', figure=5,
    conditions=[PARKED, 'Kule kilitli.'],
    warnings=[WEAPONS_SAFE],
    steps=[
        'Yükleyici kapağındaki kundağın kule üstüne bağlantısını gözle '
        'kontrol edin.',
        'Kundağın döner halkasında çamur ya da buz birikmesi varsa '
        'temizleyin.',
        'Kundağın kilit kolunun ve emniyet pimlerinin yerinde olduğunu '
        'kontrol edin.',
        'Silaha dokunmayın; hasarı silah sorumlusuna bildirin.',
    ])

SMOKE_CHECK = dm(
    code=code('DA5', '4', '310'), tech='Sis bombası atıcıları',
    info='Dış muayene', figure=5,
    conditions=[PARKED, 'Kule kilitli.'],
    warnings=[WEAPONS_SAFE, 'Atıcıların önünde durmayın.'],
    steps=[
        'Atıcıların dış gövdesinde ezik, çatlak ya da kopuk parça olup '
        'olmadığına bakın.',
        'Koruyucu kapakların yerinde olduğunu kontrol edin.',
        'Taşıyıcı plakaların kuleye bağlantısını gözle kontrol edin.',
        'Atıcılara elinizi ya da bir cisim sokmayın; hasarı bildirin.',
    ])

SMOKE_CLEAN = dm(
    code=code('DA5', '4', '250'), tech='Sis bombası atıcıları',
    info='Dış temizlik', figure=5,
    tools=[('Yumuşak kıllı fırça', 1), ('Temiz bez', None)],
    conditions=[PARKED, 'Kule kilitli.', 'Silah sorumlusu izin vermiş.'],
    warnings=[WEAPONS_SAFE],
    steps=[
        'Atıcıların ve taşıyıcı plakaların dış yüzündeki çamuru fırçayla '
        'alın.',
        'Koruyucu kapakların çevresini kuru bezle silin.',
        'Atıcılara su ya da temizleyici tutmayın.',
        'Temizlikten sonra koruyucu kapakları kontrol edin.',
    ])

# Hidrolik sistem (genel)
HYDRAULICS = dm(
    code=code('DA6'), tech='Hidrolik sistem', figure=16,
    description=[
        ('Genel', [
            'Hidrolik sistem, bir pompa, depo, filtre, akümülatör, hortumlar '
            've bağlantılardan oluşur; bazı kumanda ve tahrik düzenlerine '
            'güç sağlar.',
            'Mürettebat hidrolik yağı seviyesini, hortumları ve '
            'bağlantıları kontrol eder ve filtreyi değiştirir. Basınç '
            'ayarı ve iç onarım yetkili birimindir.',
        ]),
        ('Güvenlik', [HYD_PRESSURE,
                      'Basınçlı yağ deriyi delebilir; sızıntıyı elinizle '
                      'aramayın, bir karton parçası kullanın.']),
    ])

HYD_ISOLATE = dm(
    code=code('DA6', info='421'), tech='Hidrolik sistem',
    info='Kaçak, ses ya da yavaş çalışma: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA6-001',
        'descr': 'Hidrolik düzen yavaş çalışıyor, pompadan ses geliyor, '
                 'hidrolik uyarısı yanıyor ya da yağ izi var.',
        'steps': [
            ('stp-0001', 'Hidrolik yağı seviyesini kontrol edin.',
             'Seviye düşük mü?', 'stp-0002', 'stp-0003'),
            ('stp-0002', 'Hortumlara ve bağlantılara karton parçasıyla '
             'bakın.', 'Görünür bir kaçak var mı?', 'end-hose', 'end-fill'),
            ('stp-0003', 'Filtre tıkanıklık göstergesine bakın.',
             'Gösterge tıkanıklığı gösteriyor mu?', 'end-filter',
             'stp-0004'),
            ('stp-0004', 'Depodaki yağın rengine bakın.',
             'Yağ bulanık, köpüklü ya da koyulaşmış mı?', 'end-filter',
             'stp-0005'),
            ('stp-0005', 'Motor çalışırken hidrolik ünitesini dinleyin; '
             'düzen kullanılmadığı hâlde pompa sık sık devreye giriyor mu, '
             'ona bakın.', 'Pompa sık sık devreye giriyor ya da hiç '
             'durmuyor mu?', 'end-accumulator', 'end-service'),
        ],
        'ends': [
            ('end-hose', 'Kaçak yapan hortumu ya da bağlantıyı değiştirin.',
             code('DA6', '2', '920')),
            ('end-fill', 'Hidrolik yağını tamamlayın ve seviyeyi izleyin.',
             code('DA6', '1', '300')),
            ('end-filter', 'Hidrolik filtre elemanını değiştirin. Yağ '
             'bulanık ya da köpüklüyse bunu da kayda geçirip bildirin.',
             code('DA6', '1', '920')),
            ('end-accumulator', 'Akümülatör ön dolumunu yitirmiş olabilir; '
             'akümülatöre dışarıdan bakın ve bildirin.',
             code('DA6', '1', '310')),
            ('end-service', 'Pompa ya da akümülatör arızalı olabilir; '
             'yetkili bakım birimine bildirin.', None),
        ],
    })

HYD_LEVEL = dm(
    code=code('DA6', '1', '300'), tech='Hidrolik yağı',
    info='Seviye kontrolü', figure=16,
    supplies=[('Hidrolik yağı', None)],
    conditions=[PARKED, 'Hidrolik düzen el kitabındaki kontrol konumunda.'],
    warnings=[HYD_PRESSURE],
    cautions=['Depoya toz ve su kaçırmayın; kapağın çevresini açmadan önce '
              'silin.'],
    steps=[
        'Hidrolik deposunun gözetleme camından ya da çubuğundan seviyeyi '
        'okuyun.',
        'Seviye işaretler arasında olmalıdır; eksikse el kitabındaki yağdan '
        'tamamlayın.',
        'Yağın rengine bakın: köpüklü ya da bulanık yağ hava ya da su '
        'karıştığını gösterir; bildirin.',
        'Kapağı kapatın ve çevresini silin.',
    ])

HYD_FILTER = dm(
    code=code('DA6', '1', '920'), tech='Hidrolik filtre elemanı',
    tools=[('Filtre anahtarı', 1), ('Toplama kabı', 1)],
    spares=[('Hidrolik filtre elemanı', 1)],
    conditions=[PARKED, 'Hidrolik basınç boşaltılmış.'],
    warnings=[HYD_PRESSURE, PPE],
    steps=[
        'Filtre kabının altına toplama kabı koyun.',
        'Filtre kabını sökün ve eski elemanı çıkarın.',
        'Kabı temizleyin, yeni elemanı ve contayı takın.',
        'Filtre göstergesini sıfırlayın.',
        'Düzeni çalıştırıp filtrede kaçak olmadığını kontrol edin ve '
        'seviyeyi tamamlayın.',
    ],
    next=code('DA6', '1', '300'))

HYD_HOSES = dm(
    code=code('DA6', '2', '310'), tech='Hidrolik hortumları ve bağlantıları',
    tools=[('Karton parçası', 1)],
    conditions=[PARKED],
    warnings=[HYD_PRESSURE, 'Sızıntıyı elinizle aramayın.'],
    steps=[
        'Hortumları boydan boya kontrol edin: çatlak, şişme, sürtünme ve '
        'ıslaklık arayın.',
        'Rakorların çevresinde yağ izi olup olmadığına bakın.',
        'Hortum kelepçelerinin ve tutucularının yerinde olduğunu kontrol '
        'edin.',
        'Hasarlı hortumu bildirin ya da değiştirin.',
    ])

HYD_HOSE_CHANGE = dm(
    code=code('DA6', '2', '920'), tech='Hidrolik hortumu',
    tools=[('Açık ağızlı anahtar takımı', 1), ('Toplama kabı', 1),
           ('Tapa takımı', 1)],
    supplies=[('Hidrolik yağı', None)],
    spares=[('Hidrolik hortumu', 1)],
    conditions=[PARKED, 'Hidrolik basınç boşaltılmış.'],
    warnings=[HYD_PRESSURE, PPE],
    cautions=['Açık bağlantı ağızlarını hemen tapayla kapatın; sisteme kir '
              'girmemelidir.'],
    steps=[
        'Bağlantının altına toplama kabı koyun.',
        'Hortumun iki ucundaki rakorları gevşetip sökün, ağızları tapayla '
        'kapatın.',
        'Yeni hortumu eski hortumun güzergâhından, bükmeden geçirin.',
        'Rakorları takıp el kitabındaki yolla sıkın, tutucuları takın.',
        'Seviyeyi tamamlayın, düzeni çalıştırıp kaçak kontrolü yapın.',
    ],
    next=code('DA6', '1', '300'))

# Mürettebat bölmesi donanımı
CREW = dm(
    code=code('DA7'), tech='Mürettebat bölmesi donanımı',
    description=[
        ('Havalandırma ve NBC koruma', [
            'Havalandırma ünitesi mürettebat bölmesine filtrelenmiş hava '
            'verir. NBC koruma durumunda hava özel filtrelerden geçer ve '
            'bölme hafif basınç altında tutulur.',
            'Mürettebat ünitenin çalışmasını, filtre göstergesini ve filtre '
            'değişimini yapar.',
        ]),
        ('Yangın söndürme', [
            'Motor bölmesinde ve mürettebat bölmesinde yangın algılayıcıları '
            've söndürücü tüpler bulunur. Ayrıca el tipi söndürücüler vardır.',
            FIRE_SYSTEM_SAFE,
        ]),
        ('Isıtıcı', [
            'Yakıtla çalışan ısıtıcı soğukta mürettebat bölmesini ısıtır. '
            'Egzozu gövde dışına verilir.',
        ]),
    ])

NBC_CHECK = dm(
    code=code('DA7', '1', '300'), tech='NBC koruma ve havalandırma ünitesi',
    info='Çalışma kontrolü',
    conditions=[PARKED, 'Ana şalter açık.', 'Kapaklar kapalı.'],
    steps=[
        'Havalandırma ünitesini çalıştırın; fan sesini ve hava akışını '
        'kontrol edin.',
        'Filtre göstergesine bakın; gösterge değişim bölgesindeyse filtreyi '
        'değiştirin.',
        'Hava giriş ızgarasının dışarıdan tıkalı olmadığını kontrol edin.',
        'NBC koruma kipini el kitabındaki yolla kısa süre deneyin; uyarı '
        'lambalarını izleyin.',
        'Üniteyi kapatın ve sonuçları kayda geçirin.',
    ])

NBC_FILTER = dm(
    code=code('DA7', '1', '920'), tech='NBC filtre elemanı',
    tools=[('Lokma takımı', 1)],
    spares=[('NBC filtre elemanı', 1)],
    conditions=[PARKED, MASTER_OFF],
    warnings=['Kullanılmış filtre zararlı madde tutmuş olabilir. Koruyucu '
              'eldiven ve maske takın; eski filtreyi kapalı torbaya koyup '
              'birliğin talimatına göre teslim edin.'],
    steps=[
        'Filtre kapağını açın.',
        'Eski filtre elemanını sarsmadan çıkarın ve torbaya koyun.',
        'Filtre yuvasını ve contasını kontrol edin.',
        'Yeni elemanı ok yönüne dikkat ederek takın ve kapağı kapatın.',
        'Üniteyi çalıştırıp göstergeyi kontrol edin; değişimi kayda geçirin.',
    ])

NBC_ISOLATE = dm(
    code=code('DA7', '1', '421'), tech='Havalandırma',
    info='Hava akışı zayıf: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA7-001',
        'descr': 'Havalandırma ünitesi çalışıyor ama hava akışı zayıf, '
                 'fan ses yapıyor ya da filtre uyarısı yanıyor.',
        'steps': [
            ('stp-0001', 'Hava giriş ızgarasına dışarıdan bakın.',
             'Izgara çamur, kar ya da yaprakla tıkalı mı?', 'end-grille',
             'stp-0002'),
            ('stp-0002', 'Filtre göstergesine bakın.',
             'Gösterge değişim bölgesinde mi?', 'end-filter', 'stp-0003'),
            ('stp-0003', 'Üniteyi çalıştırıp fanı dinleyin.',
             'Fan hiç dönmüyor ve ses gelmiyor mu?', 'end-fuse', 'stp-0004'),
            ('stp-0004', 'Fan dönerken sesi dinleyin.',
             'Sürtünme, vınlama ya da titreşim sesi var mı?', 'end-fan',
             'end-check'),
        ],
        'ends': [
            ('end-grille', 'Izgarayı temizleyin.', code('DA7', '1', '300')),
            ('end-filter', 'NBC filtre elemanını değiştirin.',
             code('DA7', '1', '920')),
            ('end-fan', 'Fan rulmanı ya da kanadı arızalı olabilir; üniteyi '
             'kapatın ve yetkili bakım birimine bildirin.', None),
            ('end-fuse', 'Ünitenin sigortasını ve kablosunu kontrol edin; '
             'sigorta sağlamsa fan motoru arızalı olabilir, bildirin.',
             code('DA4', '4', '920')),
            ('end-check', 'Hava kanallarını ve ünitenin çalışmasını '
             'kontrol edin.', code('DA7', '1', '300')),
        ],
    })

FIRE_CHECK = dm(
    code=code('DA7', '2', '310'), tech='Yangın söndürme sistemi',
    conditions=[PARKED, MASTER_OFF],
    warnings=[FIRE_SYSTEM_SAFE],
    steps=[
        'Söndürücü tüplerinin dolum göstergelerine bakın; gösterge normal '
        'bölgede olmalıdır.',
        'Tüplerin tutucularının ve emniyet pimlerinin yerinde olduğunu '
        'kontrol edin.',
        'Algılayıcıların üstünde yağ, toz ya da hasar olup olmadığına bakın.',
        'Gösterge panelinde sistem uyarısı olmadığını kontrol edin.',
        'Boşalmış ya da göstergesi düşük tüpü yetkili bakım birimine '
        'bildirin.',
    ])

EXTINGUISHER = dm(
    code=code('DA7', '2', '300'), tech='El tipi yangın söndürücüler',
    info='Kontrol',
    spares=[('El tipi yangın söndürücü', 1)],
    conditions=[PARKED],
    steps=[
        'Söndürücülerin yerinde ve tutucularına bağlı olduğunu kontrol edin.',
        'Basınç göstergesinin normal bölgede olduğuna bakın.',
        'Emniyet piminin ve mührünün yerinde olduğunu kontrol edin.',
        'Gövdede ezik ya da paslanma olup olmadığına bakın.',
        'Kullanılmış, mührü kopmuş ya da göstergesi düşük söndürücüyü '
        'yenisiyle değiştirin.',
    ])

FIRE_ISOLATE = dm(
    code=code('DA7', '2', '421'), tech='Yangın söndürme sistemi',
    info='Arıza uyarısı: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA7-002',
        'descr': 'Gösterge panelinde yangın söndürme sistemi arıza uyarısı '
                 'yanıyor ya da el tipi söndürücünün göstergesi düşük; '
                 'yangın belirtisi yok.',
        'steps': [
            ('stp-0001', 'Önce gerçek bir yangın belirtisi (duman, koku, '
             'ısı) olup olmadığını kontrol edin.', 'Yangın belirtisi var mı?',
             'end-fire', 'stp-0004'),
            ('stp-0004', 'El tipi söndürücülerin göstergelerine ve '
             'mühürlerine bakın.', 'Bir söndürücünün göstergesi düşük ya da '
             'mührü kopuk mu?', 'end-extinguisher', 'stp-0002'),
            ('stp-0002', 'Söndürücü tüplerinin göstergelerine bakın.',
             'Bir tüpün göstergesi düşük mü?', 'end-bottle', 'stp-0003'),
            ('stp-0003', 'Algılayıcıların ve kablolarının üstüne bakın.',
             'Algılayıcı kirli ya da kablosu hasarlı mı?', 'end-detector',
             'end-service'),
        ],
        'ends': [
            ('end-fire', 'Motoru durdurun, mürettebatı tahliye edin ve el '
             'kitabındaki yangın talimatını uygulayın.', None),
            ('end-extinguisher', 'Söndürücüyü yenisiyle değiştirin.',
             code('DA7', '2', '300')),
            ('end-bottle', 'Tüpü yetkili bakım birimine değiştirtin.',
             code('DA7', '2', '310')),
            ('end-detector', 'Algılayıcıyı silin, kablo hasarını bildirin.',
             code('DA7', '2', '310')),
            ('end-service', 'Kontrol ünitesi arızalı olabilir; yetkili bakım '
             'birimine bildirin.', None),
        ],
    })

HEATER_TEST = dm(
    code=code('DA7', '3', '320'), tech='Isıtıcı', info='Çalışma testi',
    conditions=[PARKED, 'Tanklarda yakıt var.', 'Isıtıcı egzozu açık.'],
    warnings=['Isıtıcıyı kapalı alanda ya da egzoz çıkışı tıkalıyken '
              'çalıştırmayın.'],
    steps=[
        'Isıtıcı kumanda anahtarını açın.',
        'Fanın çalıştığını ve ısıtıcının el kitabındaki sürede ateş '
        'aldığını izleyin.',
        'Bölmeye sıcak hava geldiğini ve yanık kokusu olmadığını kontrol '
        'edin.',
        'Isıtıcıyı kapatın; fan soğutma için bir süre daha çalışır.',
    ])

HEATER_ISOLATE = dm(
    code=code('DA7', '3', '421'), tech='Isıtıcı',
    info='Çalışmıyor ya da duman yapıyor: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA7-003',
        'descr': 'Isıtıcı ateş almıyor, bir süre sonra sönüyor ya da '
                 'egzozundan yoğun duman çıkıyor.',
        'steps': [
            ('stp-0001', 'Isıtıcının sigortasını ve akü gerilimini kontrol '
             'edin.', 'Sigorta sağlam ve gerilim yeterli mi?', 'stp-0002',
             'end-power'),
            ('stp-0002', 'Isıtıcının hava girişine ve egzoz çıkışına bakın.',
             'Giriş ya da çıkış tıkalı mı?', 'end-blocked', 'stp-0003'),
            ('stp-0003', 'Isıtıcının yakıt bağlantısında yakıt izi ya da '
             'hava kabarcığı arayın.', 'Yakıt bağlantısında sorun var mı?',
             'end-fuel', 'end-service'),
        ],
        'ends': [
            ('end-power', 'Sigortayı değiştirin ya da aküleri şarj edin.',
             code('DA4', '4', '920')),
            ('end-blocked', 'Giriş ve çıkışı temizleyin.',
             code('DA7', '3', '310')),
            ('end-fuel', 'Yakıt bağlantısını kontrol edin.',
             code('DA7', '3', '310')),
            ('end-service', 'Isıtıcının yanma odası ya da kumanda ünitesi '
             'arızalı olabilir; yetkili bakım birimine bildirin.', None),
        ],
    })

HEATER_CHECK = dm(
    code=code('DA7', '3', '310'), tech='Isıtıcı egzozu ve yakıt bağlantısı',
    conditions=[PARKED, 'Isıtıcı soğumuş.'],
    warnings=['Isıtıcının egzozu çalışırken çok sıcaktır.'],
    steps=[
        'Isıtıcının gövde dışındaki egzoz çıkışının ve hava girişinin açık '
        'olduğunu kontrol edin; kar ve çamuru temizleyin.',
        'Egzoz borusunda çatlak ya da gevşek kelepçe olup olmadığına bakın.',
        'Yakıt borusunda ve bağlantılarında yakıt izi arayın.',
        'Kablo bağlantısının yerinde olduğunu kontrol edin.',
    ])

VIBRATION_ISOLATE = dm(
    code=code('DA1', '1', '421', '02'), tech='Güç paketi',
    info='Aşırı titreşim: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA1-007',
        'descr': 'Güç paketi rölantide ya da yük altında olağandan çok '
                 'titriyor; titreşim gövdeye geçiyor.',
        'steps': [
            ('stp-0001', 'Motoru durdurun, motor güvertesini açın ve fan '
             'kanatlarına bakın.', 'Kırık ya da eğilmiş kanat var mı?',
             'end-fan', 'stp-0002'),
            ('stp-0002', 'Güç paketi bağlantı takozlarına bakın.',
             'Takozlarda çatlak ya da ayrılma var mı?', 'end-mounts',
             'stp-0003'),
            ('stp-0003', 'Motoru çalıştırıp dinleyin.',
             'Motor tekliyor ya da siyah duman veriyor mu?', 'end-fuel',
             'end-service'),
        ],
        'ends': [
            ('end-fan', 'Fanları muayene edin; kırık fanla motoru '
             'çalıştırmayın.', code('DA1', '3', '310')),
            ('end-mounts', 'Takozları muayene edin ve bildirin.',
             code('DA1', '1', '310', '01')),
            ('end-fuel', 'Yakıt ve enjeksiyon sistemini arayın.',
             code('DA1', '5', '421')),
            ('end-service', 'Motor ya da şanzıman içi arıza olabilir; '
             'yetkili bakım birimine bildirin.', None),
        ],
    })

FD_ISOLATE = dm(
    code=code('DA2', '2', '421'), tech='Son dişliler',
    info='Yağ izi ya da ses: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA2-003',
        'descr': 'Yürütücü dişlinin iç tarafında yağ izi var ya da son '
                 'dişliden uğultu geliyor.',
        'steps': [
            ('stp-0001', 'Son dişlinin yağ seviyesini kontrol edin.',
             'Seviye düşük mü?', 'stp-0002', 'stp-0003'),
            ('stp-0002', 'Yürütücü dişli göbeğinin iç tarafına bakın.',
             'Keçe bölgesinden yağ sızıyor mu?', 'end-seal', 'end-fill'),
            ('stp-0003', 'Boşaltma tapasının mıknatısına bakın.',
             'İri metal parçacık var mı?', 'end-service', 'end-change'),
        ],
        'ends': [
            ('end-seal', 'Yağı tamamlayın ve keçe değişimi için bildirin.',
             code('DA2', '2', '300')),
            ('end-fill', 'Yağı tamamlayın ve seviyeyi izleyin.',
             code('DA2', '2', '300')),
            ('end-service', 'Dişliler aşınıyor olabilir; tankı kullanmayın, '
             'yetkili bakım birimine bildirin.', None),
            ('end-change', 'Yağ eskimiş olabilir; yağı değiştirin.',
             code('DA2', '2', '241')),
        ],
    })

EXTERIOR_ISOLATE = dm(
    code=code('DA0', info='421'), tech='Dış donanım',
    info='Hasar ve eksik: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA0-003',
        'descr': 'Yan etek, çamurluk, çeki halatı, motor güvertesi '
                 'kapakları, dış kutular, kule sepeti ya da antenlerde hasar '
                 'ya da eksik var.',
        'steps': [
            ('stp-0001', 'Hasarlı parçanın yan etek paneli olup olmadığına '
             'bakın.', 'Yan etek paneli eğilmiş ya da gevşek mi?',
             'end-skirt', 'stp-0002'),
            ('stp-0002', 'Çeki halatlarını, kancaları ve çeki demirini '
             'kontrol edin.', 'Halatta kopuk tel ya da ezilme, demirde '
             'eksik pim ya da çatlak var mı?', 'end-cable', 'stp-0003'),
            ('stp-0003', 'Motor güvertesi kapaklarının kilitlerine bakın.',
             'Kapak kilitlenmiyor ya da sürüşte takırdıyor mu?', 'end-deck',
             'stp-0004'),
            ('stp-0004', 'Çamurluk üstündeki kutulara ve kutu kapaklarına '
             'bakın.', 'Kutu ezik, kapağı açılıyor ya da kilidi kayıp mı?',
             'end-fender', 'stp-0005'),
            ('stp-0005', 'Kule arka sepetine ve antenlere bakın.',
             'Sepet eğilmiş, kayışı kopmuş ya da anten kırık mı?',
             'end-turret', 'end-hull'),
        ],
        'ends': [
            ('end-skirt', 'Paneli muayene edin; gerekiyorsa değiştirin.',
             code('DA0', '5', '920')),
            ('end-cable', 'Halatı ayırın ve muayene edin.',
             code('DA0', '4', '310')),
            ('end-deck', 'Motor güvertesi kapaklarını ve kilitlerini muayene '
             'edin.', code('DA0', '3', '310')),
            ('end-fender', 'Çamurlukları ve dış kutuları muayene edin.',
             code('DA0', '5', '310')),
            ('end-turret', 'Kule üstü donanımını muayene edin.',
             code('DA0', '2', '310')),
            ('end-hull', 'Gövde ve kapakları muayene edin.',
             code('DA0', '1', '310')),
        ],
    })

WEAPON_EXT_ISOLATE = dm(
    code=code('DA5', info='421'), tech='Silah dış donanımı',
    info='Dış hasar: arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA5-002',
        'descr': 'Namlu ağzı kapağı, sis bombası atıcıları ya da makineli '
                 'tüfek kundağında dışarıdan görülen hasar var.',
        'steps': [
            ('stp-0001', 'Silah sorumlusundan izin alın. Namlu ağzı '
             'kapağına bakın.',
             'Kapak yırtık ya da kayıp mı?', 'end-cover', 'stp-0002'),
            ('stp-0002', 'Sis bombası atıcılarına dışarıdan bakın.',
             'Atıcı ezik ya da koruyucu kapak eksik mi?', 'end-smoke',
             'stp-0003'),
            ('stp-0003', 'Top kalkanı ile kule arasındaki toz körüğüne '
             'bakın.', 'Körük yırtık, çatlak ya da yerinden çıkmış mı?',
             'end-boot', 'end-mount'),
        ],
        'ends': [
            ('end-cover', 'Namlu ağzı kapağını değiştirin.',
             code('DA5', '1', '920')),
            ('end-smoke', 'Atıcıları muayene edin ve silah sorumlusuna '
             'bildirin.', code('DA5', '4', '310')),
            ('end-boot', 'Ana topun dış muayenesini yapın ve körük hasarını '
             'silah sorumlusuna bildirin.', code('DA5', '1', '310')),
            ('end-mount', 'Makineli tüfek kundağını muayene edin.',
             code('DA5', '3', '310')),
        ],
    })


# --- Arıza bulmanın götürdüğü ek prosedürler ---------------------------------

WARNING_CIRCUIT = dm(
    code=code('DA4', '4', '320'), tech='Uyarı lambaları ve gösterge devresi',
    info='Çalışma testi',
    tools=[('Multimetre', 1)],
    conditions=[PARKED, 'Ana şalter açık; motor durdurulmuş.', NO_VALUES],
    steps=[
        'Gösterge panelindeki lamba sınama düğmesine basın; bütün uyarı '
        'lambalarının yandığını kontrol edin. Yanmayan lambanın ampulünü '
        'ya da ışık birimini değiştirin.',
        'Şüpheli uyarının algılayıcısına gidin; konnektörünü ayırıp '
        'temas yüzeylerinde nem, oksit ya da eğilmiş pim arayın.',
        'Konnektör ayrıkken uyarının davranışını izleyin. Uyarı sönüyor ya '
        'da yanıyorsa devre çalışıyordur; algılayıcının kendisini '
        'el kitabındaki yolla ölçün.',
        'Algılayıcı ile gösterge paneli arasındaki kablo demetini sürtünme '
        've ezilmeye karşı gözden geçirin.',
        'Konnektörü temizleyip takın; uyarıyı motor çalışırken yeniden '
        'izleyin.',
        'Devre ve algılayıcı sağlamsa ama uyarı sürüyorsa gerçek bir '
        'arıza vardır: motoru çalıştırmayın ve yetkili bakım birimine '
        'bildirin.',
    ])

SLAVE_SOCKET = dm(
    code=code('DA4', '4', '310', '01'), tech='Takviye prizi',
    info='Gözle muayene ve temizlik',
    tools=[('Tel fırça', 1), ('El feneri', 1)],
    supplies=[('Kontak temizleyici', None), ('Kontak gresi', None)],
    conditions=[PARKED, 'Ana şalter kapalı.'],
    warnings=['Takviye prizinde akülerin tam akımı vardır. Ana şalter '
              'kapalıyken çalışın; metal aleti iki kontağa birden '
              'değdirmeyin.'],
    steps=[
        'Priz kapağını açın; kapağın contasına ve menteşesine bakın.',
        'Kontaklarda kararma, erime izi, pas ya da kir arayın.',
        'Kiri ve pası tel fırçayla, kontak temizleyiciyle giderin; '
        'kurumasını bekleyin.',
        'Kontaklara ince bir kat kontak gresi sürün.',
        'Erime izi ya da gevşek kontak varsa prizi kullanmayın; yetkili '
        'bakım birimine bildirin.',
        'Kapağı kapatın ve kilitlendiğini kontrol edin.',
    ])

ACCUMULATOR_CHECK = dm(
    code=code('DA6', '1', '310'), tech='Hidrolik akümülatörü',
    info='Gözle muayene',
    tools=[('El feneri', 1)],
    conditions=[PARKED, WEAPONS_SAFE, 'Hidrolik sistem basınçsız.',
                NO_VALUES],
    warnings=['Akümülatör, düzen kapalıyken de basınç taşır. Dolum '
              'vanasını ve bağlantılarını açmayın; ön dolum işini yalnız '
              'yetkili bakım birimi yapar.'],
    steps=[
        'Akümülatör gövdesine ezik, çizik ve pas izine karşı bakın.',
        'Bağlantı rakorlarında ve dolum vanasında yağ izi arayın.',
        'Bağlantı kelepçelerinin sıkı ve hasarsız olduğunu kontrol edin.',
        'Hidrolik düzeni çalıştırıp pompanın ne sıklıkla devreye girdiğini '
        'mürettebatın gözlemiyle karşılaştırın; sık devreye giriyorsa '
        'ön dolum kaybı olabilir.',
        'Bulguları bakım kaydına yazın ve yetkili bakım birimine bildirin.',
    ])

# --- Avara ve yürütücü dişli -------------------------------------------------

DRIVE_IDLER_ISOLATE = dm(
    code=code('DA3', '3', '421'), tech='Avara tekerlekleri ve yürütücü '
    'dişliler', info='Arıza bulma',
    isolation={
        'fault': 'NAYATANK-DA3-101',
        'descr': 'Avara ya da yürütücü dişli tarafından ses geliyor, göbek '
                 'ısınıyor ya da dişli çemberi oynuyor.',
        'steps': [
            ('stp-0001', 'Sürüşten hemen sonra avara ve yürütücü dişli '
             'göbeklerine elinizin tersiyle yaklaşıp iki yanı '
             'karşılaştırın.', 'Bir göbek diğerinden belirgin sıcak mı?',
             'stp-0002', 'stp-0003'),
            ('stp-0002', 'Sıcak göbeğin gresörlüğüne ve keçesine bakın.',
             'Gres kaçağı ya da kuru gresörlük var mı?', 'end-grease',
             'end-bearing'),
            ('stp-0003', 'Yürütücü dişli çemberinin cıvatalarına ve '
             'dişlerine bakın.', 'Cıvata gevşek ya da eksik, dişler '
             'sivrilmiş mi?', 'end-ring', 'end-tension'),
        ],
        'ends': [
            ('end-grease', 'Avara göbeğini ve gerdirme tertibatını '
             'gresleyin; sürüşten sonra sıcaklığı yeniden karşılaştırın.',
             IDLER_GREASE),
            ('end-bearing', 'Rulman aşınmış olabilir; tankı kullanmayın ve '
             'yetkili bakım birimine bildirin.', None),
            ('end-ring', 'Dişli çemberini muayene edin; gerekiyorsa '
             'değiştirin.', SPROCKET_RING),
            ('end-tension', 'Palet gerginliğini kontrol edin.',
             TRACK_TENSION),
        ],
    })

# --- Çalışma ilkesi ----------------------------------------------------------
#
# Her sistem kökü için sade bir çalışma anlatımı. Değer yazılmaz; sistemde
# zaten bir tanım DM'i varsa bu anlatım yanına '01' sökme koduyla eklenir.

HOW = 'Çalışma ilkesi'

dm(code=code('DA0', '1', '040'), tech='Gövde', info=HOW,
   description=[
       ('Gövdenin görevi', [
           'Gövde zırh plakalarının kaynakla birleştirildiği kapalı bir '
           'kutudur. Önde sürücü bölmesi, ortada kule altındaki savaş '
           'bölmesi, arkada güç paketi bölmesi bulunur; bölmeleri yangın '
           'perdesi ayırır.',
           'Yürüyen takımın salıncak kolları, burulma çubukları ve son '
           'dişliler gövdeye bağlanır; gövde bütün yükü taşır.',
       ]),
       ('Kapaklar ve sızdırmazlık', [
           'Sürücü kapağı ve taban kaçış kapağı contalarla kapanır. '
           'Contalar suyu, tozu ve NBC koruma sırasında iç basıncı tutar; '
           'conta yırtılırsa yağmurda ya da yıkamada gövdede su birikir.',
           'Gövde boşaltma tapaları biriken suyu ve yıkama suyunu dışarı '
           'almak içindir; her açılıştan sonra contalarıyla sıkıca '
           'kapatılmalıdır.',
       ]),
       ('Dış donanım', [
           'Yan etekler paletin üst kolunu ve yol tekerleklerini toz, çamur '
           've darbeye karşı örter. Çamurluk üstündeki kutular aletleri ve '
           'teçhizatı taşır. Çeki kancaları ve halatlar kurtarma içindir.',
       ]),
   ])

dm(code=code('DA0', '2', '040'), tech='Kule', info=HOW,
   description=[
       ('Kule yatağı', [
           'Kule, gövdenin tavanındaki büyük çaplı bir rulmanlı yatağın '
           'üstünde döner. Yatağın contası tozu ve suyu dışarıda tutar; '
           'yatak belirli aralıklarla greslenir.',
           'Yatak çevresine taş, kum ya da buz sıkışırsa kule o noktada '
           'zorlanır ya da gıcırdar. Kule kilidi yürüyüşte ve bakımda '
           'kuleyi sabitler.',
       ]),
       ('Tahrik', [
           'Kule ve top, hidrolik ya da elektrikli tahrik düzenleriyle '
           'döndürülür ve yükseltilir; güç kesilince elle çalıştırma '
           'düzeniyle hareket ettirilebilir. Tahriklerin bakımı silah '
           'sorumlusunun izniyle yapılır.',
       ]),
       ('Kule üstü', [
           'Komutan ve yükleyici kapakları, periskoplar, nişancı ve komutan '
           'optikleri, antenler, sis bombası atıcıları ve arka sepet '
           'kulenin üstündedir. Optiklerin koruyucu kapakları camları '
           'taş ve tozdan korur.',
       ]),
   ])

dm(code=code('DA1', info='040', disassy='01'), tech='Güç paketi', info=HOW,
   description=[
       ('Tek blok halinde güç', [
           'Güç paketi, motorun, şanzımanın ve soğutma düzeninin birlikte '
           'sökülüp takılabilen bir bloğudur. Arızalı bir güç paketi '
           'sahada bütün olarak değiştirilir; tank kısa sürede yeniden '
           'kullanılabilir.',
       ]),
       ('Motor', [
           'Motor turboşarjlı bir dizel motordur. Hava filtrelerinden geçen '
           'hava turboşarjlarla sıkıştırılıp silindirlere basılır; yakıt '
           'yüksek basınçla püskürtülür ve sıkışmanın ısısıyla tutuşur. '
           'Bujisi yoktur.',
           'Motor kontrol ünitesi algılayıcılardan gelen bilgiyle yakıtı '
           'ayarlar ve bir sorun görürse sürücüye uyarı verir.',
       ]),
       ('Soğutma ve hava', [
           'Soğutma sıvısı motorun ısısını radyatörlere taşır; fanlar '
           'motor güvertesinin ızgaralarından havayı çekerek radyatörlerden '
           'geçirir. Izgaralar ya da petekler tıkanırsa motor sıcaklığı '
           'yükselir.',
           'Ön temizleyici havadaki iri tozu ayırıp dışarı atar; ince tozu '
           'filtre elemanları tutar. Tozlu arazide filtre göstergesi daha '
           'sık izlenir.',
       ]),
       ('Şanzıman ve frenler', [
           'Şanzıman motorun gücünü iki yandaki son dişlilere ve '
           'yürütücü dişlilere iletir; tankın dönüşünü de iki paletin hızını '
           'farklılaştırarak sağlar. Servis frenleri ve yavaşlatıcı '
           'şanzımanın içindedir.',
       ]),
   ])

dm(code=code('DA1', '5', '040'), tech='Yakıt sistemi', info=HOW,
   description=[
       ('Yakıtın yolu', [
           'Yakıt gövdedeki tanklarda durur. Besleme pompası yakıtı '
           'tanklardan çeker, su ayırıcılı filtreden geçirip enjeksiyon '
           'sistemine gönderir.',
           'Su yakıttan ağırdır; filtrenin altındaki haznede toplanır ve '
           'buradan boşaltılır. Hazne dolarsa su motora gider; motor '
           'tekler ya da durur.',
       ]),
       ('Hava alma', [
           'Yakıt tamamen bittiğinde ya da filtre değiştirildiğinde '
           'sisteme hava girer. Dizel motor havalı yakıtla çalışmaz; '
           'sistemin havası el kitabındaki yolla alınmadan motor ateş '
           'almaz.',
       ]),
       ('Temizlik', [
           'Doldurma kapaklarının contaları yakıta su ve toz girmesini '
           'önler. İkmalden önce kapak çevresi temizlenir; ikmalde temiz '
           'kap ve hortum kullanılır.',
       ]),
   ])

dm(code=code('DA3', info='040', disassy='01'), tech='Yürüyen takım',
   info=HOW,
   description=[
       ('Palet', [
           'Her yanda bir palet, tabanları birbirine bağlayan pimler ve '
           'bağlantı parçalarıyla oluşan sonsuz bir zincirdir. Arkadaki '
           'yürütücü dişli paleti çeker; öndeki avara tekerleği paleti '
           'yönlendirir ve gerdirme tertibatıyla gerginliğini ayarlar.',
           'Palet kullanıldıkça uzar ve gevşer. Gevşek palet sarkar, '
           'vuruntu yapar ve sert dönüşte atabilir; aşırı gergin palet '
           'rulmanları ve dişlileri hızla aşındırır.',
       ]),
       ('Tekerlekler ve süspansiyon', [
           'Yol tekerlekleri tankın ağırlığını paletin alt koluna verir. '
           'Her tekerlek bir salıncak koluna bağlıdır; salıncak kolu gövde '
           'boyunca uzanan bir burulma çubuğunu burarak yay görevi görür.',
           'Amortisörler bazı tekerleklerin salınımını söndürür. Destek '
           'makaraları paletin üst kolunu taşır. Tekerleklerin lastik '
           'bandajları sarsıntıyı azaltır.',
           'Göbekler ve kollar gresle yağlanır. Rulmanı bozulan göbek '
           'sürüşten sonra diğerlerinden sıcak olur; bu, en erken uyarıdır.',
       ]),
   ])

dm(code=code('DA4', info='040', disassy='01'), tech='Elektrik sistemi',
   info=HOW,
   description=[
       ('Güç kaynakları', [
           'Aküler motoru çalıştırır ve motor dururken telsiz, iç '
           'haberleşme ve lambaları besler. Ana şalter akülerin bütün '
           'araçla bağlantısını keser.',
           'Motor çalışırken jeneratör bütün tüketicileri besler ve aküleri '
           'doldurur. Şarj göstergesi jeneratörün çalıştığını gösterir.',
       ]),
       ('Dağıtım ve koruma', [
           'Akım, sigorta ve devre kesici panolarından devrelere dağılır. '
           'Kablo demetleri gövde içinde kanallardan geçer; konnektörler '
           'sızdırmazdır. Sürtünen ya da nem alan bir konnektör kesik kesik '
           'arızalara yol açar.',
           'Takviye prizi, akü boşaldığında başka bir araçtan ya da '
           'kaynaktan güç almayı sağlar; aynı priz başka araca takviye '
           'vermek için de kullanılır.',
       ]),
       ('Göstergeler', [
           'Algılayıcılar sıcaklık, basınç ve seviye bilgisini sürücü '
           'gösterge paneline gönderir. Bir uyarı yandığında önce gerçek '
           'arıza düşünülür; devre arızası ancak seviye ve ölçümler normal '
           'çıkınca aranır.',
       ]),
   ])

dm(code=code('DA6', info='040', disassy='01'), tech='Hidrolik sistem',
   info=HOW,
   description=[
       ('Basınç kaynağı', [
           'Hidrolik ünite depodaki yağı pompayla basınçlandırır. '
           'Akümülatör basınçlı yağı depolar; düzen ani güç istediğinde '
           'yağı pompadan önce akümülatör verir ve pompa daha az çalışır.',
           'Filtre yağdaki parçacıkları tutar; tıkanınca göstergesi bunu '
           'belirtir. Kirli ya da köpüklü yağ düzeni yavaşlatır ve pompayı '
           'aşındırır.',
       ]),
       ('Hortumlar', [
           'Yağ hortumlar ve borularla kule tahriklerine ve diğer '
           'tüketicilere gider. Basınçlı hattaki küçük bir sızıntı bile '
           'tehlikelidir: yüksek basınçlı yağ deriyi delebilir. Kaçak, '
           'sistem basınçsızken ve gözle aranır.',
       ]),
   ])

dm(code=code('DA7', info='040', disassy='01'),
   tech='Mürettebat bölmesi donanımı', info=HOW,
   description=[
       ('Havalandırma ve NBC koruma', [
           'Ünite dış havayı ızgaradan emer, filtre elemanından geçirip '
           'mürettebat bölmesine basar. Bölmedeki hafif aşırı basınç, '
           'kirli havanın kapak aralıklarından içeri sızmasını önler.',
           'Filtre doldukça hava akışı azalır; gösterge değişim bölgesine '
           'gelince eleman değiştirilir.',
       ]),
       ('Yangın söndürme', [
           'Algılayıcılar güç paketi bölmesinde ve mürettebat bölmesinde '
           'yangını algılar; sistem söndürücü tüplerini kendiliğinden ya da '
           'elle boşaltır. El tipi söndürücüler küçük yangınlar içindir.',
           'Sistemin arıza uyarısı yanarsa tank koruması azalmış demektir; '
           'uyarı giderilmeden göreve çıkılmaz.',
       ]),
       ('Isıtıcı', [
           'Yakıtla çalışan ısıtıcı mürettebat bölmesini ısıtır. Hava '
           'girişi ve egzozu açık olmalıdır; tıkanırsa ısıtıcı ateş almaz '
           'ya da duman yapar.',
       ]),
   ])

dm(code=code('D00', '4', '040', '01'), tech='Alet ve teçhizat', info=HOW,
   description=[
       ('Yerleşim', [
           'Araç alet takımı, palet aletleri ve kurtarma teçhizatının her '
           'parçasının tankta belirli bir yeri vardır; yerleşim çizelgesi '
           'aracın el kitabındadır. Parçalar yürüyüşte ses yapmayacak ve '
           'düşmeyecek biçimde bağlanır.',
       ]),
       ('Sayım', [
           'Aletler görev öncesinde ve haftalık bakımda sayılır. Eksik ya da '
           'hasarlı alet bakım kaydına yazılır. Palet aletleri olmadan '
           'palet gerginliği ayarlanamaz ve palet bağlantısı sökülemez; bu '
           'yüzden sahada en önemli aletlerdir.',
       ]),
   ])

# --- Bakım takvimi, sıvılar ve terimler --------------------------------------
#
# Askerî araçlarda aralık, miktar ve tip değerleri yazılmaz; neye, ne zaman
# ve nasıl bakılacağı anlatılır.

dm(code=code('D00', info='000'), tech='Leopard 2A6', info='Bakım takvimi',
   description=[
       ('Kullanım', [
           'Takvim, bakım düzeylerinde hangi sistemlere bakılacağını özetler. '
           'Aralıklar çalışma saatine, kilometreye ve takvime bağlıdır; '
           'kesin aralıklar aracın kendi bakım çizelgesindedir.',
           'Tozlu, çamurlu, çok sıcak ya da çok soğuk koşullarda filtre, '
           'gresleme ve temizlik daha sık yapılır.',
       ]),
       ('Her kullanımdan önce', [
           ('Mürettebat bakar:', [
               'Motor yağı, soğutma sıvısı, şanzıman yağı ve hidrolik yağı '
               'seviyeleri.',
               'Güç paketi bölmesinin altında ve tank çevresinde sızıntı '
               'izi.',
               'Palet gerginliği, palet bağlantı parçaları ve yol '
               'tekerleği bandajları.',
               'Hava filtresi göstergesi ve yakıt filtresinin su haznesi.',
               'Lambalar, iç haberleşme, optik camları ve kapak contaları.',
               'Yangın söndürme sisteminde uyarı olmaması ve el tipi '
               'söndürücüler.',
           ]),
       ]),
       ('Molalarda ve görev sonunda', [
           ('Mürettebat bakar:', [
               'Yol tekerleği, avara ve yürütücü dişli göbeklerinin iki '
               'yanda karşılaştırmalı sıcaklığı.',
               'Motor güvertesi ızgaralarındaki yaprak ve çamur.',
               'Yeni sızıntı, gevşek bağlantı ve kopuk palet tabanı.',
               'Görev sonunda yakıt ikmali, temizlik ve bulunan eksiklerin '
               'kaydı.',
           ]),
       ]),
       ('Haftalık', [
           ('Yapılacaklar:', [
               'Yürüyen takımın gresörlükleri, kapak menteşeleri ve sürüş '
               'kumandaları.',
               'Akülerin durumu, kutup başları ve kablo bağlantıları.',
               'Kule yatağı çevresinin temizliği; kule kilidinin çalışması.',
               'Alet ve teçhizat sayımı.',
           ]),
       ]),
       ('Aylık', [
           ('Yapılacaklar:', [
               'Kablo demetleri, konnektörler ve takviye prizi.',
               'Hidrolik hortumları, akümülatörün dışı ve filtre göstergesi.',
               'NBC filtre göstergesi ve havalandırma ızgarası.',
               'Isıtıcının hava girişi ve egzozu.',
               'Gövde boşaltma tapaları ve korozyon kontrolü.',
           ]),
       ]),
       ('Dönemsel bakım', [
           ('Yetkili bakım birimiyle:', [
               'Motor yağı ve yağ filtreleri, şanzıman yağı ve filtresi, son '
               'dişli yağı değişimi.',
               'Soğutma sıvısının değişimi ve antifriz koruma kontrolü.',
               'Hava filtresi elemanlarının ve yakıt filtresinin değişimi.',
               'Kule yatağının greslenmesi ve tahriklerin muayenesi.',
               'Güç paketinin çalışma testi ve kayıtlardaki uyarıların '
               'gözden geçirilmesi.',
           ]),
       ]),
   ])

dm(code=code('D00', info='030'), tech='Leopard 2A6',
   info='Sıvılar ve kapasiteler',
   description=[
       ('Genel', [
           'Bu şablonda sıvıların tipi, sınıfı ve miktarı verilmez. Her '
           'sıvının tipini ve miktarını aracın teknik el kitabından ve '
           'birliğin onaylı malzeme listesinden alın; farklı sıvıları '
           'karıştırmayın.',
       ]),
       ('Sıvılar ve nereye bakılır', [
           ('Tankta kullanılan sıvılar:', [
               'Yakıt: motor ve ısıtıcı aynı tanklardan beslenir. İkmalde '
               'yalnız onaylı yakıt kullanılır; yakıtta su olup olmadığı '
               'filtrenin su haznesinden izlenir.',
               'Motor yağı: seviye güç paketindeki çubukla ya da göstergeyle '
               'motor durmuşken ve tank düz zemindeyken okunur.',
               'Şanzıman yağı: seviye el kitabında belirtilen sıcaklıkta ve '
               'koşulda okunur; soğuk ve sıcak okuma farklıdır.',
               'Son dişli yağı: her yanda ayrı; doldurma ve kontrol tapası '
               'yürütücü dişlinin iç tarafındadır.',
               'Soğutma sıvısı: genleşme kabında, motor soğukken okunur; '
               'antifriz koruması mevsime göre denetlenir.',
               'Hidrolik yağı: hidrolik ünitesinin deposunda, düzen '
               'basınçsızken okunur.',
               'Gres: yürüyen takım, kule yatağı ve kapak menteşeleri için '
               'yağlama çizelgesindeki gres.',
           ]),
       ]),
       ('Uyarılar', [
           'Sıcak motorda soğutma kabının kapağını açmayın; basınçlı ve '
           'kaynar sıvı fışkırır.',
           'Dökülen yakıt ve yağı hemen temizleyin; güç paketi bölmesinde '
           'yangın riski oluşturur.',
           'Kullanılmış yağ ve filtreler ayrı toplanır ve yönergeye göre '
           'teslim edilir.',
       ]),
   ])

dm(code=code('D00', info='006'), tech='Leopard 2A6', info='Terimler sözlüğü',
   description=[
       ('Güç paketi ve aktarma', [
           ('Terimler:', [
               'Güç paketi: motor, şanzıman ve soğutma düzeninin birlikte '
               'değiştirilen bloğu.',
               'Turboşarj: egzoz gazıyla dönüp emme havasını sıkıştıran '
               'kompresör.',
               'Ön temizleyici: hava filtresinden önce iri tozu ayıran '
               'düzen.',
               'Su ayırıcı: yakıttaki suyu ayırıp haznesinde toplayan '
               'filtre.',
               'Hava alma: yakıt ya da hidrolik sisteme giren havanın '
               'boşaltılması.',
               'Son dişli: şanzımandan yürütücü dişliye gücü ileten '
               'dişli kutusu.',
               'Yavaşlatıcı: şanzımandaki, tankı aşınmasız yavaşlatan '
               'düzen.',
               'Servis freni: sürüşte kullanılan ana fren.',
           ]),
       ]),
       ('Yürüyen takım', [
           ('Terimler:', [
               'Palet: tabanların pim ve bağlantı parçalarıyla birleştiği '
               'sonsuz zincir.',
               'Palet tabanı: paletin yere basan lastik yastığı.',
               'Bağlantı parçası: iki palet halkasını uçlarından birleştiren '
               'parça; kama cıvatasıyla sıkılır.',
               'Yürütücü dişli: paleti çeken dişli tekerlek.',
               'Avara tekerleği: paleti yönlendiren ve germeye yarayan '
               'tekerlek.',
               'Gerdirme tertibatı: avarayı itip palet gerginliğini ayarlayan '
               'düzen.',
               'Yol tekerleği: tankın ağırlığını palete veren tekerlek.',
               'Bandaj: yol tekerleğinin çevresindeki lastik kaplama.',
               'Destek makarası: paletin üst kolunu taşıyan küçük makara.',
               'Salıncak kolu: yol tekerleğini gövdeye bağlayan kol.',
               'Burulma çubuğu: burularak yay görevi gören çelik çubuk.',
               'Palet atma: paletin dişliden ya da tekerleklerden çıkması.',
           ]),
       ]),
       ('Gövde, kule ve donanım', [
           ('Terimler:', [
               'Kule yatağı: kulenin üstünde döndüğü büyük rulman.',
               'Kule kilidi: kuleyi gövdeye göre sabitleyen kilit.',
               'Periskop: kapalı kapaktan dışarıyı görmeye yarayan aynalı '
               'optik.',
               'Namlu ağzı kapağı: topun ağzını toz ve sudan koruyan kılıf.',
               'Toz körüğü: top kalkanı ile kule arasındaki esnek kılıf.',
               'Yan etek: paletin üstünü örten zırhlı panel.',
               'Takviye prizi: dışarıdan elektrik almaya ya da vermeye '
               'yarayan priz.',
               'Ana şalter: akülerle araç arasındaki ana bağlantıyı açıp '
               'kesen şalter.',
               'NBC: nükleer, biyolojik ve kimyasal tehditlere karşı koruma.',
               'Aşırı basınç: mürettebat bölmesinin içini dış havadan biraz '
               'yüksek basınçta tutma.',
               'Gresörlük: gres pompasının takıldığı küçük yağlama nipeli.',
               'Bakım kaydı: yapılan her kontrolün ve bulunan eksiğin '
               'yazıldığı kayıt.',
           ]),
       ]),
   ])

# --- Parça haritası --------------------------------------------------------

# Düğümü olmayan parçalar içinde bulundukları düğüme bağlı; seçilince o
# düğüm vurgulanır.

POWERPACK_NODES = ['engine', 'transmission', 'radiators', 'cooling_fans',
                   'air_filters', 'exhaust']
TRACKS = ['track_l', 'track_r']
WHEELS = ['road_wheels_l', 'road_wheels_r']
SUSPENSION = ['suspension_l', 'suspension_r']
IDLERS = ['idler_l', 'idler_r']
SPROCKETS = ['sprocket_l', 'sprocket_r']
SKIRTS = ['side_skirt_l', 'side_skirt_r']
LAMPS = ['headlights', 'taillights']

# Gövde
part('hull', 'Gövde', None, 'DA0-10',
     ['hull', 'engine_deck', 'side_skirt_l', 'side_skirt_r'], 'z.hull',
     'Mürettebatı, güç paketini ve kuleyi taşıyan kaynaklı çelik yapı.',
     {'inspect': HULL_CHECK, 'clean': WASH})
part('hull.engine_deck', 'Motor güvertesi', 'hull', 'DA0-30',
     ['engine_deck'], 'z.engine',
     'Motor bölmesinin üstünü örter; ızgaralardan soğutma havası girer.',
     {'clean': DECK_CLEAN, 'inspect': DECK_HATCHES})
part('hull.engine_deck.grilles', 'Motor güvertesi ızgaraları',
     'hull.engine_deck', 'DA0-30', ['engine_deck'], 'z.engine',
     'Fanların soğutma havasını çektiği yuvarlak ızgaralar.',
     {'clean': DECK_CLEAN}, quantity=2)
part('hull.engine_deck.hatches', 'Motor güvertesi erişim kapakları',
     'hull.engine_deck', 'DA0-30', ['engine_deck'], 'z.engine',
     'Güç paketine, doldurma ağızlarına ve filtrelere erişim kapakları.',
     {'inspect': DECK_HATCHES})
part('hull.side_skirt_l', 'Sol yan etek', 'hull', 'DA0-50', ['side_skirt_l'],
     'z.running', 'Sol yürüyen takımın üstünü örten sökülebilir paneller.',
     {'inspect': SKIRT_CHECK, 'replace': SKIRT_CHANGE})
part('hull.side_skirt_r', 'Sağ yan etek', 'hull', 'DA0-50', ['side_skirt_r'],
     'z.running', 'Sağ yürüyen takımın üstünü örten sökülebilir paneller.',
     {'inspect': SKIRT_CHECK, 'replace': SKIRT_CHANGE})
part('hull.fenders', 'Çamurluklar ve dış kutular', 'hull', 'DA0-50',
     ['hull'], 'z.hull',
     'Paletlerin üstündeki çamurluklar ve üstlerindeki teçhizat kutuları.',
     {'inspect': SKIRT_CHECK, 'isolate': EXTERIOR_ISOLATE})
part('hull.driver_hatch', 'Sürücü kapağı', 'hull', 'DA0-10', ['hull'],
     'z.driver', 'Sürücü bölmesinin üstündeki kapak ve periskoplar.',
     {'inspect': HULL_CHECK, 'isolate': HATCH_ISOLATE,
      'lubricate': HATCH_GREASE})
part('hull.hatch_seals', 'Kapak contaları', 'hull', 'DA0-10', ['hull'],
     'z.hull', 'Sürücü, komutan ve yükleyici kapaklarının su ve toz '
     'contaları.', {'isolate': HATCH_ISOLATE, 'replace': HATCH_SEAL},
     quantity=3)
part('hull.escape_hatch', 'Taban kaçış kapağı', 'hull', 'DA0-10', ['hull'],
     'z.driver', 'Gövde tabanındaki acil durum çıkış kapağı.',
     {'inspect': ESCAPE_HATCH})
part('hull.drain_plugs', 'Gövde boşaltma tapaları', 'hull', 'DA0-10',
     ['hull'], 'z.hull', 'Gövde içinde biriken suyun boşaltıldığı tapalar.',
     {'clean': HULL_DRAIN})
part('hull.towing', 'Çeki kancaları ve halatı', 'hull', 'DA0-40', ['hull'],
     'z.hull', 'Tankın çekilmesi ve kurtarılması için ön ve arka kancalar.',
     {'inspect': TOW_CHECK}, quantity=4)
part('hull.towing.cables', 'Çeki halatları', 'hull.towing', 'DA0-40',
     ['hull'], 'z.hull', 'Gövde üstünde taşınan, gözlü çelik çeki halatları.',
     {'inspect': TOW_CHECK}, quantity=2)
part('hull.towing.bar', 'Çeki demiri', 'hull.towing', 'DA0-40', ['hull'],
     'z.hull', 'Arızalı tankın kısa mesafede çekilmesinde kullanılan demir.',
     {'inspect': TOW_CHECK})

# Kule
part('turret', 'Kule', None, 'DA0-20',
     ['turret', 'main_gun', 'optics', 'machine_gun', 'smoke_dischargers'],
     'z.turret',
     'Gövdenin üstündeki dönen kule; mürettebattan üç kişi buradadır.',
     {'inspect': TURRET_CHECK})
part('turret.hatches', 'Komutan ve yükleyici kapakları', 'turret', 'DA0-20',
     ['turret'], 'z.turret', 'Kule üstündeki iki mürettebat kapağı.',
     {'inspect': TURRET_CHECK, 'isolate': HATCH_ISOLATE,
      'lubricate': HATCH_GREASE}, quantity=2)
part('turret.ring', 'Kule yatağı ve contası', 'turret', 'DA0-60',
     ['turret'], 'z.turret',
     'Kulenin üzerinde döndüğü bilyalı yatak ve su geçirmez conta.',
     {'isolate': RING_ISOLATE, 'inspect': RING_CHECK,
      'lubricate': RING_GREASE})
part('turret.drives', 'Kule tahrik düzenleri', 'turret', 'DA0-60',
     ['turret'], 'z.turret',
     'Kulenin içindeki tahrik düzenleri; yalnız dışarıdan gözle bakılır.',
     {'inspect': RING_CHECK, 'isolate': RING_ISOLATE})
part('turret.lock', 'Kule kilidi', 'turret', 'DA0-60', ['turret'],
     'z.turret', 'Seyir ve bakımda kuleyi gövdeye sabitleyen kilit.',
     {'inspect': RING_CHECK})
part('turret.basket', 'Kule arka sepeti', 'turret', 'D00-40', ['turret'],
     'z.turret', 'Kulenin arkasındaki teçhizat sepeti.',
     {'inspect': TOOLS_CHECK})
part('turret.antennas', 'Antenler', 'turret', 'DA0-20', ['turret'],
     'z.turret', 'Kule üstündeki telsiz antenleri ve anten tabanları.',
     {'inspect': TURRET_CHECK}, quantity=2)
part('turret.main_gun', 'Ana top', 'turret', 'DA5-10', ['main_gun'],
     'z.turret', 'Kulenin önündeki top; namlu, ısı kılıfı ve top kalkanı.',
     {'inspect': GUN_CHECK, 'isolate': WEAPON_EXT_ISOLATE})
part('turret.main_gun.muzzle_cover', 'Namlu ağzı koruyucu kapağı',
     'turret.main_gun', 'DA5-10', ['main_gun'], 'z.turret',
     'Namluyu su, toz ve yabancı cisme karşı kapatan kapak.',
     {'inspect': GUN_CHECK, 'replace': MUZZLE_COVER})
part('turret.main_gun.boot', 'Top kalkanı toz körüğü', 'turret.main_gun',
     'DA5-10', ['main_gun'], 'z.turret',
     'Top kalkanı ile kule arasındaki esnek körük.',
     {'inspect': GUN_CHECK})
part('turret.optics', 'Kule optikleri', 'turret', 'DA5-20',
     ['optics'], 'z.turret',
     'Kule üstündeki nişancı optiği ve komutan periskobu.',
     {'clean': OPTICS_CLEAN, 'inspect': OPTICS_COVERS,
      'isolate': OPTICS_ISOLATE})
part('turret.optics.gunner', 'Nişancı optiği', 'turret.optics',
     'DA5-20', ['optics'], 'z.turret',
     'Kulenin ön sağ tavanındaki koruyucu kapaklı optik.',
     {'clean': OPTICS_CLEAN, 'isolate': OPTICS_ISOLATE})
part('turret.optics.commander', 'Komutan periskobu', 'turret.optics',
     'DA5-20', ['optics'], 'z.turret',
     'Komutan kapağının önünde yükselen dönen gözetleme optiği.',
     {'clean': OPTICS_CLEAN, 'isolate': OPTICS_ISOLATE})
part('turret.periscopes', 'Kapak periskopları', 'turret', 'DA5-20',
     ['turret'], 'z.turret',
     'Komutan ve yükleyici kapaklarının çevresindeki gözetleme blokları.',
     {'clean': OPTICS_CLEAN, 'inspect': OPTICS_COVERS})
part('turret.machine_gun', 'Makineli tüfek', 'turret', 'DA5-30',
     ['machine_gun'], 'z.turret', 'Yükleyici kapağındaki kundağa takılı.',
     {'inspect': MG_CHECK})
part('turret.smoke_dischargers', 'Sis bombası atıcıları', 'turret', 'DA5-40',
     ['smoke_dischargers'], 'z.turret',
     'Kulenin iki yanındaki atıcılar ve taşıyıcı plakaları.',
     {'inspect': SMOKE_CHECK, 'clean': SMOKE_CLEAN}, quantity=2)

# Güç paketi
part('powerpack', 'Güç paketi', None, 'DA1-00', POWERPACK_NODES, 'z.engine',
     'Motor ve şanzımandan oluşan, tek parça sökülüp takılan paket.',
     {'replace': POWERPACK_CHANGE, 'isolate': ENGINE_ISOLATE,
      'inspect': ENGINE_TEST})
part('powerpack.mounts', 'Güç paketi bağlantı takozları', 'powerpack',
     'DA1-10', ['engine'], 'z.engine',
     'Paketi gövdeye bağlayan, titreşimi sönümleyen lastik takozlar.',
     {'inspect': MOUNTS}, quantity=4)
part('engine', 'Motor', 'powerpack', 'DA1-10', ['engine'], 'z.engine',
     'Turboşarjlı V12 dizel motor.',
     {'inspect': ENGINE_CHECK, 'isolate': POWER_ISOLATE})
part('engine.turbochargers', 'Turboşarjlar', 'engine', 'DA1-40', ['engine'],
     'z.engine', 'Egzoz gazıyla dönüp motora sıkıştırılmış hava gönderir.',
     {'inspect': ENGINE_CHECK, 'isolate': POWER_ISOLATE}, quantity=2)
part('engine.oil', 'Motor yağı ve yağ filtreleri', 'engine', 'DA1-20',
     ['engine'], 'z.engine',
     'Yataklara ve hareketli parçalara yağ basar; filtreler yağı temizler.',
     {'inspect': OIL_CHECK, 'lubricate': OIL_CHANGE, 'isolate': OIL_ISOLATE})
part('engine.oil_cooler', 'Motor yağ soğutucusu', 'engine', 'DA1-20',
     ['radiators'], 'z.engine',
     'Motor yağını soğutma havasıyla soğutan petek.',
     {'inspect': ENGINE_CHECK, 'isolate': OIL_ISOLATE})
part('engine.starter', 'Marş motoru', 'engine', 'DA4-30', ['engine'],
     'z.engine', 'Motoru ilk çalıştırmada döndürür.',
     {'isolate': STARTER_ISOLATE, 'inspect': CHARGE_CHECK})
part('engine.generator', 'Jeneratör', 'engine', 'DA4-30', ['engine'],
     'z.engine', 'Motor çalışırken aküleri şarj eder ve elektrik sağlar.',
     {'inspect': CHARGE_CHECK, 'isolate': CHARGE_ISOLATE})
part('engine.control', 'Motor kontrol ünitesi ve algılayıcılar', 'engine',
     'DA1-10', ['engine'], 'z.engine',
     'Motoru yöneten elektronik ünite, sıcaklık ve basınç algılayıcıları.',
     {'isolate': POWER_ISOLATE, 'inspect': ENGINE_TEST})
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
     {'clean': RADIATOR_CLEAN, 'inspect': FAN_CHECK}, quantity=2)
part('cooling.fan_drive', 'Fan tahriki', 'cooling', 'DA1-30',
     ['cooling_fans'], 'z.engine', 'Soğutma fanlarını motordan döndürür.',
     {'inspect': FAN_CHECK, 'isolate': OVERHEAT})
part('cooling.coolant', 'Soğutma sıvısı ve genleşme kabı', 'cooling',
     'DA1-30', ['radiators'], 'z.engine',
     'Antifrizli soğutma sıvısı, genleşme kabı ve basınç kapağı.',
     {'inspect': COOLANT_CHECK, 'refill': COOLANT_CHANGE})
part('cooling.hoses', 'Soğutma hortumları ve kelepçeleri', 'cooling',
     'DA1-30', ['engine'], 'z.engine',
     'Motor, radyatörler ve genleşme kabı arasındaki hortumlar.',
     {'replace': HOSE_CHANGE, 'inspect': ENGINE_CHECK}, quantity=8)
part('air_filters', 'Hava filtreleri', 'powerpack', 'DA1-40',
     ['air_filters'], 'z.engine',
     'Motora giren havadaki tozu tutar; toz atma çıkışı tozu dışarı atar.',
     {'replace': AIR_FILTER, 'isolate': POWER_ISOLATE}, quantity=2)
part('air_filters.precleaner', 'Ön temizleyici ve toz atma fanı',
     'air_filters', 'DA1-40', ['air_filters'], 'z.engine',
     'İri tozu filtreye ulaşmadan ayırıp dışarı atar.',
     {'clean': PRECLEANER}, quantity=2)
part('air_filters.ducts', 'Hava emme kanalları', 'air_filters', 'DA1-40',
     ['air_filters'], 'z.engine',
     'Filtrelerden turboşarjlara temiz hava taşıyan kanallar.',
     {'inspect': INTAKE_CHECK})
part('exhaust', 'Egzoz', 'powerpack', 'DA1-40', ['exhaust'], 'z.engine',
     'Egzoz gazını turboşarjlardan gövdenin arkasına taşır.',
     {'inspect': EXHAUST_CHECK, 'isolate': SMOKE_ISOLATE})
part('transmission', 'Şanzıman', 'powerpack', 'DA2-10', ['transmission'],
     'z.engine',
     'Otomatik şanzıman; vitesleri ve tankın dönüşünü yönetir.',
     {'inspect': TRANS_LEVEL, 'isolate': TRANS_ISOLATE})
part('transmission.oil', 'Şanzıman yağı ve filtresi', 'transmission',
     'DA2-10', ['transmission'], 'z.engine',
     'Şanzımanı yağlayan ve soğutan yağ ile yağ filtresi.',
     {'inspect': TRANS_LEVEL, 'lubricate': TRANS_OIL_CHANGE})
part('transmission.oil_cooler', 'Şanzıman yağ soğutucusu', 'transmission',
     'DA2-10', ['radiators'], 'z.engine',
     'Şanzıman yağını soğutma havasıyla soğutan petek.',
     {'inspect': TRANS_CHECK, 'isolate': TRANS_ISOLATE})
part('transmission.brakes', 'Servis frenleri', 'transmission', 'DA2-30',
     ['transmission'], 'z.engine', 'Şanzımanın içindeki fren tertibatı.',
     {'inspect': BRAKE_TEST, 'isolate': BRAKE_ISOLATE})
part('transmission.parking_brake', 'Park freni', 'transmission', 'DA2-30',
     ['transmission'], 'z.engine',
     'Duran tankı yerinde tutan fren ve kumandası.',
     {'inspect': BRAKE_TEST, 'isolate': BRAKE_ISOLATE})
part('transmission.final_drives', 'Son dişliler', 'transmission', 'DA2-20',
     ['transmission'], 'z.engine',
     'Şanzımanın çıkışını iki yandaki yürütücü dişlilere aktarır.',
     {'inspect': FD_LEVEL, 'lubricate': FD_OIL_CHANGE,
      'isolate': FD_ISOLATE}, quantity=2)
part('transmission.controls', 'Sürüş kumandaları', 'transmission', 'DA2-40',
     ['hull'], 'z.driver',
     'Direksiyon kumandası, pedallar, vites seçici ve park freni kolu.',
     {'inspect': CONTROLS_CHECK, 'lubricate': CONTROLS_GREASE})

# Yakıt
part('fuel', 'Yakıt sistemi', None, 'DA1-50', ['fuel_tanks'], 'z.engine',
     'Yakıt tankları, filtreler ve borular.',
     {'inspect': FUEL_CHECK, 'refill': REFUEL, 'isolate': FUEL_ISOLATE})
part('fuel.tanks', 'Yakıt tankları', 'fuel', 'DA1-50', ['fuel_tanks'],
     'z.engine', 'Motor bölmesinin iki yanındaki dizel yakıt tankları.',
     {'refill': REFUEL}, quantity=2)
part('fuel.filter', 'Yakıt filtresi ve su ayırıcı', 'fuel', 'DA1-50',
     ['fuel_tanks'], 'z.engine',
     'Yakıttaki suyu ve tortuyu enjeksiyon sistemine ulaşmadan tutar.',
     {'inspect': FUEL_CHECK, 'replace': FUEL_FILTER})
part('fuel.lines', 'Yakıt boruları ve hortumları', 'fuel', 'DA1-50',
     ['fuel_tanks'], 'z.engine',
     'Tanklar, filtre, besleme pompası ve motor arasındaki borular.',
     {'inspect': FUEL_LINES, 'isolate': FUEL_ISOLATE})
part('fuel.caps', 'Yakıt doldurma kapakları', 'fuel', 'DA1-50',
     ['engine_deck'], 'z.engine',
     'Motor güvertesindeki contalı doldurma kapakları.',
     {'inspect': FUEL_LINES, 'refill': REFUEL}, quantity=2)
part('fuel.pump', 'Yakıt besleme pompası', 'fuel', 'DA1-50', ['engine'],
     'z.engine', 'Yakıtı tanklardan filtre üzerinden motora gönderir.',
     {'isolate': FUEL_ISOLATE, 'adjust': FUEL_BLEED})
part('fuel.injection', 'Yakıt enjeksiyon sistemi', 'fuel', 'DA1-50',
     ['engine'], 'z.engine',
     'Yakıtı silindirlere püskürten sistem; yalnız yetkili birim açar.',
     {'isolate': SMOKE_ISOLATE})

# Yürüyen takım
part('running_gear', 'Yürüyen takım', None, 'DA3-00',
     [*TRACKS, *WHEELS, *SUSPENSION, *IDLERS, *SPROCKETS], 'z.running',
     'Paletler, yol tekerlekleri, süspansiyon, avaralar ve yürütücü '
     'dişliler.', {'isolate': RUNNING_ISOLATE, 'lubricate': GREASE})
part('track_l', 'Sol palet', 'running_gear', 'DA3-10', ['track_l'],
     'z.running', 'Pimle bağlı çelik baklalar ve lastik tabanlar.',
     {'inspect': TRACK_CHECK, 'adjust': TRACK_TENSION,
      'remove': TRACK_REMOVE})
part('track_r', 'Sağ palet', 'running_gear', 'DA3-10', ['track_r'],
     'z.running', 'Pimle bağlı çelik baklalar ve lastik tabanlar.',
     {'inspect': TRACK_CHECK, 'adjust': TRACK_TENSION,
      'remove': TRACK_REMOVE})
part('tracks.pads', 'Palet tabanları', 'running_gear', 'DA3-10', TRACKS,
     'z.running', 'Baklaların altındaki lastik tabanlar; yolu korur.',
     {'replace': TRACK_PADS})
part('tracks.connectors', 'Palet bağlantı parçaları', 'running_gear',
     'DA3-10', TRACKS, 'z.running',
     'Bakla pimlerinin uçlarını birleştiren parçalar ve kama cıvataları.',
     {'replace': CONNECTORS, 'inspect': TRACK_CHECK})
part('road_wheels', 'Yol tekerlekleri', 'running_gear', 'DA3-20', WHEELS,
     'z.running', 'Her yanda yedi çift lastik bandajlı tekerlek.',
     {'inspect': ROAD_WHEELS, 'isolate': HUB_ISOLATE,
      'replace': WHEEL_CHANGE}, quantity=14)
part('road_wheels_l', 'Sol yol tekerlekleri', 'road_wheels', 'DA3-20',
     ['road_wheels_l'], 'z.running',
     'Yedi çift lastik bandajlı tekerlek; tankın ağırlığını paletlere '
     'aktarır.', {'inspect': ROAD_WHEELS, 'replace': WHEEL_CHANGE},
     quantity=7)
part('road_wheels_r', 'Sağ yol tekerlekleri', 'road_wheels', 'DA3-20',
     ['road_wheels_r'], 'z.running',
     'Yedi çift lastik bandajlı tekerlek; tankın ağırlığını paletlere '
     'aktarır.', {'inspect': ROAD_WHEELS, 'replace': WHEEL_CHANGE},
     quantity=7)
part('road_wheels.hubs', 'Tekerlek göbekleri ve rulmanları', 'road_wheels',
     'DA3-20', WHEELS, 'z.running',
     'Tekerleklerin döndüğü rulmanlar, keçeler ve göbek kapakları.',
     {'isolate': HUB_ISOLATE, 'replace': WHEEL_CHANGE}, quantity=14)
part('suspension', 'Süspansiyon', 'running_gear', 'DA3-20', SUSPENSION,
     'z.running',
     'Burulma çubuklarına bağlı salıncak kolları ve amortisörler.',
     {'inspect': ROAD_WHEELS, 'lubricate': ARM_GREASE})
part('suspension.dampers', 'Amortisörler', 'suspension', 'DA3-20',
     SUSPENSION, 'z.running', 'Tekerleklerin salınımını sönümler.',
     {'inspect': ROAD_WHEELS, 'replace': DAMPER_CHANGE})
part('suspension.arms', 'Salıncak kolları', 'suspension', 'DA3-20',
     SUSPENSION, 'z.running',
     'Yol tekerleklerini burulma çubuklarına bağlayan kollar.',
     {'inspect': ROAD_WHEELS, 'lubricate': ARM_GREASE}, quantity=14)
part('suspension.torsion_bars', 'Burulma çubukları', 'suspension', 'DA3-20',
     SUSPENSION, 'z.running',
     'Gövde tabanı boyunca uzanan, yay görevi gören çelik çubuklar.',
     {'inspect': ROAD_WHEELS, 'isolate': HUB_ISOLATE}, quantity=14)
part('suspension.support_rollers', 'Destek makaraları', 'suspension',
     'DA3-20', SUSPENSION, 'z.running',
     'Paletin üst kolunu taşıyan küçük makaralar.',
     {'inspect': ROLLERS, 'lubricate': ARM_GREASE}, quantity=8)
part('idlers', 'Avara tekerlekleri', 'running_gear', 'DA3-30', IDLERS,
     'z.running', 'Önde paleti döndürür ve gerginliğini ayarlar.',
     {'inspect': SPROCKET, 'adjust': TRACK_TENSION,
      'lubricate': IDLER_GREASE}, quantity=2)
part('idlers.tensioner', 'Palet gerdirme tertibatları', 'idlers', 'DA3-30',
     IDLERS, 'z.running',
     'Avarayı öne ya da geri alarak paletin gerginliğini ayarlar.',
     {'adjust': TRACK_TENSION, 'lubricate': IDLER_GREASE}, quantity=2)
part('sprockets', 'Yürütücü dişliler', 'running_gear', 'DA3-30', SPROCKETS,
     'z.running', 'Arkada son dişliden güç alıp paleti döndürür.',
     {'inspect': SPROCKET}, quantity=2)
part('sprockets.rings', 'Yürütücü dişli çemberleri', 'sprockets', 'DA3-30',
     SPROCKETS, 'z.running', 'Göbeğe cıvatalı, değiştirilebilir dişli '
     'çemberler.', {'inspect': SPROCKET, 'replace': SPROCKET_RING},
     quantity=4)

# Elektrik
part('electrical', 'Elektrik sistemi', None, 'DA4-00',
     ['batteries', 'headlights', 'taillights'], 'z.hull',
     '24 V doğru akım sistemi: aküler, jeneratör, aydınlatma.',
     {'inspect': BATTERY_CHECK, 'isolate': CHARGE_ISOLATE})
part('electrical.batteries', 'Aküler', 'electrical', 'DA4-10',
     ['batteries'], 'z.driver',
     'Sürücü bölmesindeki akü kutuları; marş ve motor dururken elektrik.',
     {'inspect': BATTERY_CHECK, 'replace': BATTERY,
      'refill': BATTERY_CHARGE}, quantity=4)
part('electrical.master_switch', 'Ana şalter ve akü röleleri',
     'electrical', 'DA4-10', ['batteries'], 'z.driver',
     'Aküleri elektrik sisteminden ayıran şalter ve röleler.',
     {'isolate': STARTER_ISOLATE, 'inspect': BATTERY_CHECK})
part('electrical.headlights', 'Farlar', 'electrical', 'DA4-20',
     ['headlights'], 'z.hull', 'Gövdenin önündeki far ve sinyal lambaları.',
     {'replace': LIGHTS, 'inspect': LIGHT_CHECK, 'isolate': LIGHT_ISOLATE},
     quantity=2)
part('electrical.marker_lights', 'Ön köşe lambaları', 'electrical',
     'DA4-20', ['headlights'], 'z.hull',
     'Gövdenin ön köşelerindeki sarı işaret lambaları.',
     {'replace': LIGHTS, 'isolate': LIGHT_ISOLATE}, quantity=2)
part('electrical.taillights', 'Arka lambalar', 'electrical', 'DA4-20',
     ['taillights'], 'z.hull', 'Gövdenin arkasındaki stop ve konvoy '
     'lambaları.', {'replace': TAIL_CHANGE, 'inspect': LIGHT_CHECK,
                    'isolate': LIGHT_ISOLATE}, quantity=2)
part('electrical.harness', 'Kablo demetleri ve konnektörler', 'electrical',
     'DA4-40', ['hull'], 'z.hull',
     'Gövde ve kule boyunca uzanan kablo demetleri.',
     {'inspect': HARNESS, 'isolate': CHARGE_ISOLATE})
part('electrical.fuses', 'Sigorta ve devre kesici panoları', 'electrical',
     'DA4-40', ['hull'], 'z.driver',
     'Devreleri aşırı akıma karşı koruyan sigortalar ve devre kesiciler.',
     {'replace': FUSE, 'isolate': LIGHT_ISOLATE}, quantity=2)
part('electrical.slave_socket', 'Takviye prizi', 'electrical', 'DA4-40',
     ['hull'], 'z.hull',
     'Dış kaynaktan çalıştırma ve şarj için kapaklı priz.',
     {'inspect': SLAVE})
part('electrical.instruments', 'Sürücü gösterge paneli', 'electrical',
     'DA4-40', ['hull'], 'z.driver',
     'Motor, şanzıman ve elektrik göstergeleri ile uyarı lambaları.',
     {'inspect': ENGINE_TEST, 'isolate': CHARGE_ISOLATE})
part('electrical.intercom', 'İç haberleşme düzeni', 'electrical', 'DA4-50',
     ['turret'], 'z.turret',
     'Mürettebat başlıkları, kumanda kutuları ve ana ünite.',
     {'inspect': INTERCOM_TEST, 'isolate': INTERCOM_ISOLATE})

# Hidrolik
part('hydraulics', 'Hidrolik sistem', None, 'DA6-00', ['turret'],
     'z.turret', 'Pompa, depo, filtre, akümülatör, hortumlar ve bağlantılar.',
     {'isolate': HYD_ISOLATE, 'inspect': HYD_HOSES})
part('hydraulics.unit', 'Hidrolik ünite (pompa ve depo)', 'hydraulics',
     'DA6-10', ['turret'], 'z.turret',
     'Hidrolik yağını basan pompa ve yağ deposu.',
     {'refill': HYD_LEVEL, 'isolate': HYD_ISOLATE})
part('hydraulics.filter', 'Hidrolik filtre', 'hydraulics', 'DA6-10',
     ['turret'], 'z.turret', 'Hidrolik yağındaki kiri tutan filtre.',
     {'replace': HYD_FILTER})
part('hydraulics.accumulator', 'Hidrolik akümülatörü', 'hydraulics',
     'DA6-10', ['turret'], 'z.turret',
     'Basınçlı yağı depolar; yalnız yetkili birim açar.',
     {'isolate': HYD_ISOLATE})
part('hydraulics.hoses', 'Hidrolik hortumları ve bağlantıları',
     'hydraulics', 'DA6-20', ['turret'], 'z.turret',
     'Ünite ile tahrikler arasındaki yüksek basınç hortumları.',
     {'inspect': HYD_HOSES, 'replace': HYD_HOSE_CHANGE})

# Mürettebat bölmesi
part('crew_systems', 'Mürettebat bölmesi donanımı', None, 'DA7-00',
     ['hull'], 'z.hull',
     'Havalandırma ve NBC koruma, yangın söndürme ve ısıtıcı.',
     {'inspect': NBC_CHECK})
part('crew.nbc', 'NBC koruma ve havalandırma ünitesi', 'crew_systems',
     'DA7-10', ['hull'], 'z.hull',
     'Mürettebat bölmesine filtrelenmiş hava veren ünite.',
     {'inspect': NBC_CHECK, 'isolate': NBC_ISOLATE})
part('crew.nbc_filter', 'NBC filtre elemanı', 'crew.nbc', 'DA7-10',
     ['hull'], 'z.hull', 'Havadaki zararlı maddeleri tutan filtre.',
     {'replace': NBC_FILTER})
part('crew.fire_system', 'Yangın söndürme sistemi', 'crew_systems',
     'DA7-20', ['hull'], 'z.engine',
     'Motor ve mürettebat bölmesindeki algılayıcılar ve söndürücü tüpler.',
     {'inspect': FIRE_CHECK, 'isolate': FIRE_ISOLATE})
part('crew.fire_bottles', 'Söndürücü tüpleri', 'crew.fire_system',
     'DA7-20', ['hull'], 'z.engine',
     'Sistemin otomatik ya da elle boşaltılan söndürücü tüpleri.',
     {'inspect': FIRE_CHECK})
part('crew.fire_detectors', 'Yangın algılayıcıları', 'crew.fire_system',
     'DA7-20', ['hull'], 'z.engine',
     'Motor ve mürettebat bölmesindeki ısı ve alev algılayıcıları.',
     {'inspect': FIRE_CHECK, 'isolate': FIRE_ISOLATE})
part('crew.extinguishers', 'El tipi yangın söndürücüler', 'crew_systems',
     'DA7-20', ['hull'], 'z.driver',
     'Mürettebat bölmesinde ve dışarıda bağlı taşınabilir söndürücüler.',
     {'inspect': EXTINGUISHER}, quantity=2)
part('crew.heater', 'Isıtıcı', 'crew_systems', 'DA7-30', ['hull'],
     'z.hull', 'Yakıtla çalışan mürettebat bölmesi ısıtıcısı.',
     {'inspect': HEATER_CHECK, 'isolate': HEATER_ISOLATE})

# Alet ve teçhizat
part('equipment', 'Alet ve teçhizat', None, 'D00-40', ['turret', 'hull'],
     'z.hull', 'Mürettebatın kullandığı alet takımı ve dış teçhizat.',
     {'inspect': TOOLS_CHECK})
part('equipment.tool_kit', 'Araç alet takımı', 'equipment', 'D00-40',
     ['turret'], 'z.turret',
     'Anahtarlar, lokma takımı, gres pompası, kürek ve kazma.',
     {'inspect': TOOLS_CHECK})
part('equipment.track_tools', 'Palet aletleri', 'equipment', 'D00-40',
     ['hull'], 'z.hull',
     'Palet sökme, takma ve gerdirme için kullanılan aletler.',
     {'inspect': TOOLS_CHECK})

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
    ('sym.click_no_crank', 'Marşa basınca yalnız tık sesi geliyor'),
    ('sym.power_loss', 'Motor çekmiyor, tank hızlanmıyor'),
    ('sym.rough_running', 'Motor tekliyor ya da düzensiz çalışıyor'),
    ('sym.black_smoke', 'Egzozdan siyah duman çıkıyor'),
    ('sym.blue_smoke', 'Egzozdan mavi duman çıkıyor'),
    ('sym.white_smoke', 'Motor ısındıktan sonra da egzozdan beyaz duman '
     'çıkıyor'),
    ('sym.whistle', 'Güç paketinden ıslık sesi geliyor'),
    ('sym.engine_warning', 'Motor arıza uyarısı yanıyor'),
    ('sym.powerpack_vibration', 'Güç paketi aşırı titriyor'),
    ('sym.overheat', 'Motor sıcaklığı yükseliyor'),
    ('sym.coolant_loss', 'Soğutma sıvısı eksiliyor'),
    ('sym.oil_pressure', 'Yağ basıncı uyarısı yanıyor'),
    ('sym.oil_leak', 'Motor bölmesinin altına yağ damlıyor'),
    ('sym.milky_oil', 'Motor yağı süt gibi açık renkli'),
    ('sym.air_filter_light', 'Hava filtresi göstergesi kırmızı'),
    ('sym.dust_intake', 'Hava emme kanalında toz izi var'),
    ('sym.water_in_fuel', 'Yakıt filtresinde su birikiyor'),
    ('sym.fuel_smell', 'Motor bölmesinde yakıt kokusu var'),
    ('sym.hard_start_after_refuel', 'Yakıt bittikten ya da filtre '
     'değiştikten sonra motor çalışmıyor'),
    ('sym.exhaust_soot', 'Egzoz bağlantılarında kurum izi var'),
    ('sym.shift', 'Vitesler sert ya da geç geçiyor'),
    ('sym.trans_temp', 'Şanzıman sıcaklık uyarısı yanıyor'),
    ('sym.trans_leak', 'Şanzımanın altında yağ izi var'),
    ('sym.steering_stiff', 'Direksiyon kumandası ya da vites seçici zor '
     'hareket ediyor'),
    ('sym.sprocket_leak', 'Yürütücü dişlinin iç tarafında yağ izi var'),
    ('sym.brake_weak', 'Fren zayıf tutuyor'),
    ('sym.park_brake', 'Park freni tankı tutmuyor'),
    ('sym.pull', 'Tank bir yana çekiyor'),
    ('sym.track_slack', 'Palet sarkık, palet atıyor'),
    ('sym.track_noise', 'Yürüyen takımdan vuruntu ya da şıkırtı geliyor'),
    ('sym.loose_connector', 'Palet bağlantı parçası gevşemiş ya da eksik'),
    ('sym.vibration', 'Asfaltta sürüşte titreşim artmış'),
    ('sym.hot_hub', 'Bir yol tekerleği göbeği çok ısınıyor'),
    ('sym.rubber_loss', 'Tekerlek bandajından lastik parçaları kopuyor'),
    ('sym.pitching', 'Tank engebede aşırı yalpalıyor'),
    ('sym.wheel_height', 'Bir yol tekerleği diğerlerinden yukarıda ya da '
     'aşağıda duruyor'),
    ('sym.roller_wear', 'Paletin üst kolunda makara aşınma izi var'),
    ('sym.dim_lights', 'Farlar sönük yanıyor'),
    ('sym.light_out', 'Bir lamba yanmıyor'),
    ('sym.circuit_dead', 'Bir devredeki bütün donanım çalışmıyor'),
    ('sym.no_charge', 'Motor çalışırken şarj göstergesi şarjı göstermiyor'),
    ('sym.battery_drain', 'Aküler bekleyişte boşalıyor'),
    ('sym.intermittent_electric', 'Elektrikli donanım kesik kesik '
     'çalışıyor'),
    ('sym.no_power', 'Ana şalter açılınca hiçbir lamba yanmıyor'),
    ('sym.gauge_dead', 'Bir gösterge çalışmıyor'),
    ('sym.intercom_silent', 'İç haberleşmede ses gelmiyor ya da cızırtı var'),
    ('sym.blurry_optics', 'Optikten görüntü bulanık'),
    ('sym.optics_fog', 'Optiğin içinde buğu var'),
    ('sym.periscope_cracked', 'Periskop camı çatlak'),
    ('sym.water_in_hull', 'Gövde içinde su birikiyor'),
    ('sym.hatch_stiff', 'Kapak zor açılıyor ya da kilit kavramıyor'),
    ('sym.skirt_damaged', 'Yan etek paneli eğilmiş ya da gevşek'),
    ('sym.turret_noise', 'Kule dönerken gıcırtı ya da tıkırtı geliyor'),
    ('sym.turret_stiff', 'Kule bir noktada zorlanıyor'),
    ('sym.tow_cable_damaged', 'Çeki halatında kopuk tel ya da ezilme var'),
    ('sym.hydraulic_leak', 'Hidrolik hortumunda yağ izi var'),
    ('sym.hydraulic_slow', 'Hidrolik düzen yavaş çalışıyor'),
    ('sym.weak_ventilation', 'Mürettebat bölmesinde hava akışı zayıf'),
    ('sym.nbc_filter_light', 'NBC filtre göstergesi değişim bölgesinde'),
    ('sym.fire_system_warning', 'Yangın söndürme sistemi arıza uyarısı '
     'yanıyor'),
    ('sym.extinguisher_low', 'El tipi söndürücünün göstergesi düşük'),
    ('sym.heater_no_start', 'Isıtıcı ateş almıyor ya da sönüyor'),
    ('sym.heater_smoke', 'Isıtıcı egzozundan yoğun duman çıkıyor'),
    ('sym.muzzle_cover', 'Namlu ağzı kapağı yırtık ya da kayıp'),
    ('sym.smoke_tube_damage', 'Sis bombası atıcısı ezik ya da koruyucu '
     'kapağı eksik'),
]

# (id, parça, belirtiler, neden, önem 1-3, arıza bulma, onarım)
FAULTS = [
    # Elektrik ve marş
    ('f.batteries.flat', 'electrical.batteries',
     ['sym.no_start', 'sym.slow_crank', 'sym.dim_lights'],
     'Aküler boşalmış ya da ömrünü doldurmuş.', 2, ENGINE_ISOLATE,
     BATTERY_CHARGE),
    ('f.batteries.terminals', 'electrical.batteries',
     ['sym.slow_crank', 'sym.click_no_crank'],
     'Akü kutup başları oksitlenmiş ya da gevşemiş.', 1, STARTER_ISOLATE,
     BATTERY_CHECK),
    ('f.generator.failed', 'engine.generator', ['sym.dim_lights',
                                                'sym.no_charge'],
     'Jeneratör aküleri şarj etmiyor.', 2, CHARGE_ISOLATE, CHARGE_CHECK),
    ('f.electrical.drain', 'electrical.harness', ['sym.battery_drain'],
     'Bir devre motor dururken akım çekiyor.', 1, CHARGE_ISOLATE, HARNESS),
    ('f.harness.chafed', 'electrical.harness',
     ['sym.intermittent_electric', 'sym.circuit_dead'],
     'Kablo demeti sürtünmüş ya da konnektör gevşemiş.', 2, CHARGE_ISOLATE,
     HARNESS),
    ('f.fuse.blown', 'electrical.fuses', ['sym.circuit_dead',
                                          'sym.light_out'],
     'Devrenin sigortası atmış.', 1, LIGHT_ISOLATE, FUSE),
    ('f.starter.failed', 'engine.starter', ['sym.click_no_crank',
                                            'sym.no_start'],
     'Marş motoru ya da rölesi arızalı.', 2, STARTER_ISOLATE, CHARGE_CHECK),
    ('f.master_switch', 'electrical.master_switch', ['sym.no_power',
                                                     'sym.no_start'],
     'Ana şalter ya da akü rölesi temas etmiyor.', 2, STARTER_ISOLATE,
     BATTERY_CHECK),
    ('f.instruments.gauge', 'electrical.instruments', ['sym.gauge_dead'],
     'Gösterge ya da algılayıcı bağlantısı arızalı.', 1, CHARGE_ISOLATE,
     HARNESS),
    ('f.lights.bulb', 'electrical.headlights', ['sym.light_out'],
     'Ampul yanmış ya da soket oksitlenmiş.', 1, LIGHT_ISOLATE, LIGHTS),
    ('f.taillight.damaged', 'electrical.taillights', ['sym.light_out'],
     'Arka lamba grubu kırılmış ya da içine su girmiş.', 1, LIGHT_ISOLATE,
     TAIL_CHANGE),
    ('f.intercom.headset', 'electrical.intercom', ['sym.intercom_silent'],
     'Başlık ya da kumanda kutusu kablosu arızalı.', 1, INTERCOM_ISOLATE,
     INTERCOM_TEST),
    # Motor
    ('f.fuel.water', 'fuel.filter', ['sym.water_in_fuel', 'sym.power_loss',
                                     'sym.no_start'],
     'Yakıta su karışmış; filtre ve su ayırıcı dolmuş.', 2, ENGINE_ISOLATE,
     FUEL_CHECK),
    ('f.fuel.filter_clogged', 'fuel.filter', ['sym.power_loss',
                                              'sym.rough_running'],
     'Yakıt filtresi elemanı tortuyla tıkanmış.', 2, FUEL_ISOLATE,
     FUEL_FILTER),
    ('f.fuel.air', 'fuel.pump', ['sym.hard_start_after_refuel',
                                 'sym.rough_running'],
     'Yakıt sistemine hava girmiş.', 1, FUEL_ISOLATE, FUEL_BLEED),
    ('f.fuel.leak', 'fuel.lines', ['sym.fuel_smell'],
     'Yakıt borusu ya da bağlantısı sızdırıyor.', 3, FUEL_ISOLATE,
     FUEL_LINES),
    ('f.fuel.cap_seal', 'fuel.caps', ['sym.water_in_fuel'],
     'Doldurma kapağının contası bozuk; yakıta su giriyor.', 1, FUEL_ISOLATE,
     FUEL_LINES),
    ('f.injection.fault', 'fuel.injection', ['sym.black_smoke',
                                             'sym.rough_running'],
     'Enjeksiyon sisteminde arıza var.', 3, SMOKE_ISOLATE, ENGINE_TEST),
    ('f.air_filter.clogged', 'air_filters',
     ['sym.air_filter_light', 'sym.power_loss', 'sym.black_smoke'],
     'Hava filtresi elemanları tozla tıkanmış.', 1, POWER_ISOLATE,
     AIR_FILTER),
    ('f.precleaner.blocked', 'air_filters.precleaner',
     ['sym.air_filter_light'],
     'Ön temizleyici ya da toz atma çıkışı tıkanmış.', 1, POWER_ISOLATE,
     PRECLEANER),
    ('f.intake.leak', 'air_filters.ducts', ['sym.dust_intake',
                                            'sym.power_loss'],
     'Hava emme kanalı yırtık ya da kelepçesi gevşek; filtrelenmemiş hava '
     'giriyor.', 3, POWER_ISOLATE, INTAKE_CHECK),
    ('f.turbo.leak', 'engine.turbochargers',
     ['sym.whistle', 'sym.power_loss', 'sym.black_smoke'],
     'Turboşarj hava bağlantısında kaçak var.', 2, POWER_ISOLATE,
     INTAKE_CHECK),
    ('f.engine.control', 'engine.control', ['sym.engine_warning',
                                            'sym.power_loss'],
     'Motor kontrol ünitesi ya da bir algılayıcı arızalı.', 2, POWER_ISOLATE,
     ENGINE_TEST),
    ('f.engine.oil_burning', 'engine', ['sym.blue_smoke'],
     'Motor yağ yakıyor; turboşarj keçeleri ya da segmanlar aşınmış '
     'olabilir.', 3, SMOKE_ISOLATE, OIL_CHECK),
    ('f.engine.coolant_in_oil', 'engine', ['sym.milky_oil',
                                           'sym.white_smoke',
                                           'sym.coolant_loss'],
     'Soğutma sıvısı yağa ya da yanma odasına geçiyor.', 3, OIL_ISOLATE,
     COOLANT_CHECK),
    ('f.mounts.worn', 'powerpack.mounts', ['sym.powerpack_vibration'],
     'Güç paketi bağlantı takozları çatlamış ya da ayrılmış.', 2,
     VIBRATION_ISOLATE, MOUNTS),
    ('f.oil.low', 'engine.oil', ['sym.oil_pressure', 'sym.oil_leak'],
     'Motor yağı eksik ya da bir conta sızdırıyor.', 3, OIL_ISOLATE,
     OIL_CHECK),
    ('f.oil_cooler.leak', 'engine.oil_cooler', ['sym.oil_leak'],
     'Motor yağ soğutucusu ya da bağlantısı sızdırıyor.', 2, OIL_ISOLATE,
     ENGINE_CHECK),
    ('f.exhaust.leak', 'exhaust', ['sym.exhaust_soot', 'sym.whistle'],
     'Egzoz borusu çatlamış ya da kelepçesi gevşemiş.', 2, SMOKE_ISOLATE,
     EXHAUST_CHECK),
    # Soğutma
    ('f.grilles.blocked', 'hull.engine_deck.grilles', ['sym.overheat'],
     'Motor güvertesi ızgaraları yaprak ya da çamurla tıkanmış.', 2,
     OVERHEAT, DECK_CLEAN),
    ('f.radiator.dirty', 'cooling.radiators', ['sym.overheat'],
     'Radyatör petekleri toz ve kirle kaplanmış.', 2, OVERHEAT,
     RADIATOR_CLEAN),
    ('f.fan.drive', 'cooling.fan_drive', ['sym.overheat'],
     'Soğutma fanlarından biri dönmüyor; fan tahriki arızalı.', 3, OVERHEAT,
     FAN_CHECK),
    ('f.fan.blade', 'cooling.fans', ['sym.overheat',
                                     'sym.powerpack_vibration'],
     'Fan kanadı kırılmış ya da eğilmiş.', 2, VIBRATION_ISOLATE,
     FAN_CHECK),
    ('f.coolant.leak', 'cooling.hoses', ['sym.coolant_loss', 'sym.overheat'],
     'Soğutma hortumu ya da kelepçesi sızdırıyor.', 2, OVERHEAT,
     HOSE_CHANGE),
    ('f.coolant.old', 'cooling.coolant', ['sym.overheat'],
     'Soğutma sıvısı eskimiş ya da antifriz oranı bozulmuş.', 1, OVERHEAT,
     COOLANT_CHANGE),
    # Güç aktarma
    ('f.transmission.oil', 'transmission.oil', ['sym.shift'],
     'Şanzıman yağı eksik ya da eskimiş.', 2, TRANS_ISOLATE,
     TRANS_OIL_CHANGE),
    ('f.transmission.leak', 'transmission', ['sym.trans_leak', 'sym.shift'],
     'Şanzıman contası ya da tapası sızdırıyor.', 2, TRANS_ISOLATE,
     TRANS_CHECK),
    ('f.transmission.cooler', 'transmission.oil_cooler', ['sym.trans_temp'],
     'Şanzıman yağ soğutucusu kirli ya da sızdırıyor.', 2, TRANS_ISOLATE,
     RADIATOR_CLEAN),
    ('f.controls.stiff', 'transmission.controls', ['sym.steering_stiff',
                                                   'sym.shift'],
     'Kumanda bağlantıları kurumuş ya da kirlenmiş.', 1, TRANS_ISOLATE,
     CONTROLS_GREASE),
    ('f.brakes.worn', 'transmission.brakes', ['sym.brake_weak', 'sym.pull'],
     'Servis frenleri aşınmış ya da bir yandaki fren sürtüyor.', 3,
     BRAKE_ISOLATE, BRAKE_TEST),
    ('f.parking_brake', 'transmission.parking_brake', ['sym.park_brake'],
     'Park freni kumandası ya da bağlantısı ayarını kaybetmiş.', 2,
     BRAKE_ISOLATE, CONTROLS_CHECK),
    ('f.final_drive.seal', 'transmission.final_drives',
     ['sym.sprocket_leak', 'sym.track_noise'],
     'Son dişli keçesi sızdırıyor; yağ eksilirse dişliler aşınır.', 2,
     FD_ISOLATE, FD_LEVEL),
    # Yürüyen takım
    ('f.track.slack', 'idlers.tensioner', ['sym.track_slack',
                                           'sym.track_noise'],
     'Palet gerginliği azalmış; gerdirme tertibatı ayarını kaybetmiş '
     'olabilir.', 3, RUNNING_ISOLATE, TRACK_TENSION),
    ('f.pads.worn', 'tracks.pads', ['sym.vibration', 'sym.track_noise'],
     'Palet tabanları aşınmış ya da kopmuş.', 1, RUNNING_ISOLATE, TRACK_PADS),
    ('f.track.connector', 'tracks.connectors', ['sym.loose_connector',
                                                'sym.track_noise'],
     'Palet bağlantı parçasının kama cıvatası gevşemiş.', 3, RUNNING_ISOLATE,
     CONNECTORS),
    ('f.wheel.bearing', 'road_wheels.hubs', ['sym.hot_hub',
                                             'sym.track_noise'],
     'Yol tekerleği rulmanı aşınmış ya da göbekte yağ kalmamış.', 2,
     HUB_ISOLATE, WHEEL_CHANGE),
    ('f.wheel.tyre', 'road_wheels', ['sym.rubber_loss', 'sym.vibration'],
     'Yol tekerleğinin lastik bandajı parçalanıyor.', 2, HUB_ISOLATE,
     WHEEL_CHANGE),
    ('f.damper.leak', 'suspension.dampers', ['sym.pitching'],
     'Amortisör yağını kaçırmış; sönümleme yok.', 2, RUNNING_ISOLATE,
     DAMPER_CHANGE),
    ('f.torsion_bar.broken', 'suspension.torsion_bars', ['sym.wheel_height',
                                                          'sym.pitching'],
     'Burulma çubuğu kırılmış.', 3, HUB_ISOLATE, ROAD_WHEELS),
    ('f.arm.bearing', 'suspension.arms', ['sym.track_noise'],
     'Salıncak kolu yatağı greslenmemiş ve aşınmaya başlamış.', 1,
     RUNNING_ISOLATE, ARM_GREASE),
    ('f.support_roller', 'suspension.support_rollers', ['sym.roller_wear'],
     'Destek makarası dönmüyor ya da bandajı kopmuş.', 1, RUNNING_ISOLATE,
     ROLLERS),
    ('f.sprocket.worn', 'sprockets.rings', ['sym.track_slack',
                                            'sym.track_noise'],
     'Yürütücü dişli dişleri aşınmış; palet atlıyor.', 2, RUNNING_ISOLATE,
     SPROCKET_RING),
    # Gövde ve kule
    ('f.hatch.seal', 'hull.hatch_seals', ['sym.water_in_hull'],
     'Kapak contası yırtılmış ya da sertleşmiş.', 1, HATCH_ISOLATE,
     HATCH_SEAL),
    ('f.hatch.stiff', 'hull.driver_hatch', ['sym.hatch_stiff'],
     'Kapak menteşesi ve kilidi kurumuş ya da kirlenmiş.', 1, HATCH_ISOLATE,
     HATCH_GREASE),
    ('f.skirt_l.damaged', 'hull.side_skirt_l', ['sym.skirt_damaged'],
     'Sol yan etek paneli çarpmayla eğilmiş ya da cıvatası kopmuş.', 1,
     EXTERIOR_ISOLATE, SKIRT_CHANGE),
    ('f.skirt_r.damaged', 'hull.side_skirt_r', ['sym.skirt_damaged'],
     'Sağ yan etek paneli çarpmayla eğilmiş ya da cıvatası kopmuş.', 1,
     EXTERIOR_ISOLATE, SKIRT_CHANGE),
    ('f.tow_cable.worn', 'hull.towing.cables', ['sym.tow_cable_damaged'],
     'Çeki halatının telleri kopmuş ya da halat ezilmiş.', 2,
     EXTERIOR_ISOLATE,
     TOW_CHECK),
    ('f.turret_ring.debris', 'turret.ring', ['sym.turret_stiff',
                                             'sym.turret_noise'],
     'Kule yatağı çevresine taş, kum ya da buz sıkışmış.', 2, RING_ISOLATE,
     RING_CHECK),
    ('f.turret_ring.grease', 'turret.ring', ['sym.turret_noise'],
     'Kule yatağının greslemesi gecikmiş.', 1, RING_ISOLATE, RING_GREASE),
    ('f.optics.dirty', 'turret.optics', ['sym.blurry_optics'],
     'Optik camı kirli ya da nemlenmiş.', 1, OPTICS_ISOLATE, OPTICS_CLEAN),
    ('f.optics.moisture', 'turret.optics.commander', ['sym.optics_fog'],
     'Optiğin içine nem girmiş.', 2, OPTICS_ISOLATE, OPTICS_COVERS),
    ('f.periscope.cracked', 'turret.periscopes', ['sym.periscope_cracked',
                                                  'sym.blurry_optics'],
     'Periskop camı taş çarpmasıyla çatlamış.', 1, OPTICS_ISOLATE, PERISCOPE),
    ('f.muzzle_cover.lost', 'turret.main_gun.muzzle_cover',
     ['sym.muzzle_cover'],
     'Namlu ağzı koruyucu kapağı yırtılmış ya da kaybolmuş.', 1,
     WEAPON_EXT_ISOLATE,
     MUZZLE_COVER),
    ('f.smoke_tube.damaged', 'turret.smoke_dischargers',
     ['sym.smoke_tube_damage'],
     'Atıcının dış gövdesi dalla ya da çarpmayla ezilmiş, koruyucu kapağı '
     'düşmüş.', 2,
     WEAPON_EXT_ISOLATE, SMOKE_CHECK),
    # Hidrolik
    ('f.hydraulic.low', 'hydraulics.unit', ['sym.hydraulic_slow'],
     'Hidrolik yağı eksik.', 2, HYD_ISOLATE, HYD_LEVEL),
    ('f.hydraulic.hose', 'hydraulics.hoses', ['sym.hydraulic_leak',
                                              'sym.hydraulic_slow'],
     'Hidrolik hortumu ya da rakoru sızdırıyor.', 3, HYD_ISOLATE,
     HYD_HOSE_CHANGE),
    ('f.hydraulic.filter', 'hydraulics.filter', ['sym.hydraulic_slow'],
     'Hidrolik filtre elemanı tıkanmış.', 1, HYD_ISOLATE, HYD_FILTER),
    # Mürettebat bölmesi
    ('f.nbc.filter', 'crew.nbc_filter', ['sym.nbc_filter_light',
                                         'sym.weak_ventilation'],
     'NBC filtre elemanı dolmuş.', 2, NBC_ISOLATE, NBC_FILTER),
    ('f.nbc.intake', 'crew.nbc', ['sym.weak_ventilation'],
     'Havalandırma giriş ızgarası tıkanmış.', 1, NBC_ISOLATE, NBC_CHECK),
    ('f.fire.detector', 'crew.fire_detectors', ['sym.fire_system_warning'],
     'Yangın algılayıcısı kirlenmiş ya da kablosu hasarlı.', 2, FIRE_ISOLATE,
     FIRE_CHECK),
    ('f.fire.bottle', 'crew.fire_bottles', ['sym.fire_system_warning'],
     'Söndürücü tüpünün dolumu düşmüş.', 3, FIRE_ISOLATE, FIRE_CHECK),
    ('f.extinguisher.low', 'crew.extinguishers', ['sym.extinguisher_low'],
     'El tipi söndürücü kullanılmış ya da basıncı düşmüş.', 2,
     FIRE_ISOLATE, EXTINGUISHER),
    ('f.heater.blocked', 'crew.heater', ['sym.heater_no_start',
                                         'sym.heater_smoke'],
     'Isıtıcının hava girişi ya da egzozu kar veya çamurla tıkanmış.', 1,
     HEATER_ISOLATE, HEATER_CHECK),
    ('f.heater.fuel', 'crew.heater', ['sym.heater_no_start'],
     'Isıtıcının yakıt bağlantısında hava ya da sızıntı var.', 1,
     HEATER_ISOLATE, HEATER_CHECK),
]

# Yedek parça adı → IPD'deki parça.

# Ek arızaların belirtileri ve arızaları.
SYMPTOMS += [
    ('sym.idler_hot', 'Avara ya da yürütücü dişli göbeği sürüşten sonra çok '
     'sıcak'),
    ('sym.sprocket_bolt', 'Yürütücü dişli çemberinde gevşek ya da eksik '
     'cıvata var'),
    ('sym.slave_socket', 'Takviye prizi kararmış, paslı ya da kontakları '
     'gevşek'),
    ('sym.false_warning', 'Uyarı yanıyor ama seviye ve ölçümler normal'),
    ('sym.pump_cycling', 'Hidrolik pompa düzen kullanılmadan sık sık '
     'devreye giriyor'),
    ('sym.deck_hatch', 'Motor güvertesi kapağı kilitlenmiyor ya da sürüşte '
     'takırdıyor'),
    ('sym.box_damaged', 'Çamurluk üstündeki kutu ezik ya da kapağı '
     'açılıyor'),
    ('sym.antenna', 'Anten kırık ya da eğilmiş'),
    ('sym.gun_boot', 'Top kalkanındaki toz körüğü yırtık ya da yerinden '
     'çıkmış'),
    ('sym.nbc_fan_dead', 'Havalandırma fanı hiç dönmüyor, ses gelmiyor'),
    ('sym.old_oil', 'Motor yağı çok koyu ve yanık kokulu, değişim zamanı '
     'geçmiş'),
    ('sym.park_brake_drag', 'Park freni indirildiği hâlde tank zor yürüyor'),
    ('sym.hydraulic_foam', 'Hidrolik yağı bulanık ya da köpüklü'),
]

FAULTS += [
    ('f.idler.bearing', 'idlers', ['sym.idler_hot', 'sym.track_noise'],
     'Avara tekerleği göbeği yeterince greslenmemiş ya da rulmanı '
     'aşınmaya başlamış.', 2, DRIVE_IDLER_ISOLATE, IDLER_GREASE),
    ('f.sprocket.bolts', 'sprockets.rings',
     ['sym.sprocket_bolt', 'sym.track_noise'],
     'Yürütücü dişli çemberinin bağlantı cıvataları gevşemiş.', 3,
     DRIVE_IDLER_ISOLATE, SPROCKET_RING),
    ('f.slave_socket.dirty', 'electrical.slave_socket',
     ['sym.slave_socket', 'sym.click_no_crank'],
     'Takviye prizinin kontakları kirlenmiş ya da oksitlenmiş; takviye '
     'akımı geçmiyor.', 1, STARTER_ISOLATE, SLAVE_SOCKET),
    ('f.warning.circuit', 'electrical.instruments',
     ['sym.false_warning', 'sym.oil_pressure'],
     'Uyarı devresinde konnektör nem almış ya da algılayıcı arızalı; '
     'uyarı gerçek bir durumu göstermiyor.', 2, OIL_ISOLATE,
     WARNING_CIRCUIT),
    ('f.accumulator.precharge', 'hydraulics.accumulator',
     ['sym.pump_cycling', 'sym.hydraulic_slow'],
     'Hidrolik akümülatörü ön dolumunu yitirmiş; pompa sürekli devreye '
     'giriyor.', 2, HYD_ISOLATE, ACCUMULATOR_CHECK),
    ('f.deck_hatch.latch', 'hull.engine_deck.hatches', ['sym.deck_hatch'],
     'Motor güvertesi kapağının kilidi kirlenmiş ya da ayarı bozulmuş.', 1,
     EXTERIOR_ISOLATE, DECK_HATCHES),
    ('f.fender_box.damaged', 'hull.fenders', ['sym.box_damaged'],
     'Çamurluk üstündeki kutu çarpmayla ezilmiş ya da kilidi kopmuş.', 1,
     EXTERIOR_ISOLATE, SKIRT_CHECK),
    ('f.antenna.broken', 'turret.antennas', ['sym.antenna'],
     'Anten dala ya da engele çarpıp kırılmış.', 1, EXTERIOR_ISOLATE,
     TURRET_CHECK),
    ('f.gun_boot.torn', 'turret.main_gun.boot', ['sym.gun_boot'],
     'Top kalkanı toz körüğü yırtılmış; içeri toz ve su giriyor.', 2,
     WEAPON_EXT_ISOLATE, GUN_CHECK),
    ('f.nbc.fan_power', 'crew.nbc',
     ['sym.nbc_fan_dead', 'sym.weak_ventilation'],
     'Havalandırma ünitesinin sigortası atmış ya da besleme kablosu '
     'kopuk.', 2, NBC_ISOLATE, FUSE),
    ('f.oil.old', 'engine.oil', ['sym.old_oil'],
     'Motor yağının değişim zamanı geçmiş; yağ yorulmuş ve kirlenmiş.', 2,
     OIL_ISOLATE, OIL_CHANGE),
    ('f.parking_brake.drag', 'transmission.parking_brake',
     ['sym.park_brake_drag'],
     'Park freni bağlantısı tam çözülmüyor; fren sürtüyor.', 2,
     BRAKE_ISOLATE, CONTROLS_CHECK),
    ('f.hydraulic.contaminated', 'hydraulics.unit',
     ['sym.hydraulic_foam', 'sym.hydraulic_slow'],
     'Hidrolik yağına su ya da hava karışmış; filtre çabuk doluyor.', 2,
     HYD_ISOLATE, HYD_FILTER),
]

SPARE_PARTS = {
    'Güç paketi, yedek': 'powerpack',
    'Motor yağ filtresi elemanı': 'engine.oil',
    'Hava filtresi elemanı': 'air_filters',
    'Palet tabanı': 'tracks.pads',
    'Akü, 12 V': 'electrical.batteries',
    'Far ampulü, 24 V': 'electrical.headlights',
    'Kapak contası': 'hull.hatch_seals',
    'Yan etek paneli': 'hull.side_skirt_l',
    'Soğutma hortumu': 'cooling.hoses',
    'Yakıt filtresi elemanı': 'fuel.filter',
    'Şanzıman yağ filtresi elemanı': 'transmission.oil',
    'Palet bağlantı parçası': 'tracks.connectors',
    'Yol tekerleği': 'road_wheels',
    'Amortisör': 'suspension.dampers',
    'Yürütücü dişli çemberi': 'sprockets.rings',
    'Arka lamba grubu': 'electrical.taillights',
    'Sürücü periskobu': 'hull.driver_hatch',
    'Namlu ağzı koruyucu kapağı': 'turret.main_gun.muzzle_cover',
    'Hidrolik filtre elemanı': 'hydraulics.filter',
    'Hidrolik hortumu': 'hydraulics.hoses',
    'NBC filtre elemanı': 'crew.nbc_filter',
    'El tipi yangın söndürücü': 'crew.extinguishers',
}


# --- Söyleyişler ------------------------------------------------------------
#
# Mürettebatın arızayı kendi sözleriyle anlatışı; teşhis serbest metni
# bunlarla eşleştirir. Her metin arızaya bir belirti olarak eklenir
# (`Content.add_phrasings`).

PHRASINGS = {
    # Elektrik
    'f.batteries.flat': [
        'Sabah ana şalteri açtım, göstergeler zayıf yandı ve marş dönmedi',
        'Soğuk gecenin ardından motor marşta zorlandı',
        'Akü göstergesi düşük gösteriyor, telsiz kendi kendine kapanıyor',
    ],
    'f.batteries.terminals': [
        'Akü kutup başlarında beyaz kabuk var',
        'Akü kablosu oynatınca marş basıyor',
    ],
    'f.generator.failed': [
        'Motor çalışırken şarj uyarısı yanık kalıyor',
        'Uzun sürüşten sonra aküler yine boş çıkıyor',
        'Motor bölmesinden yanık kablo kokusu geldi, şarj göstergesi düştü',
    ],
    'f.electrical.drain': [
        'Tank birkaç gün durunca ana şalter kapalı olmasına rağmen aküler '
        'bitiyor',
        'Ana şalteri kapattıktan sonra bir lamba ya da cihaz yanık kalıyor',
    ],
    'f.harness.chafed': [
        'Arazide sarsıntıda bazı lambalar ve cihazlar kesilip geliyor',
        'Kablo demetinin üstünde aşınmış izolasyon gördüm',
        'Bir konnektörün içi nemli ve yeşillenmiş',
    ],
    'f.fuse.blown': [
        'Bir gruptaki bütün lambalar aynı anda söndü',
        'Devre kesici attı, yeniden basınca yine atıyor',
    ],
    'f.starter.failed': [
        'Marş düğmesine basınca motor bölmesinden tek bir tık geliyor, '
        'aküler dolu',
        'Marş motoru boşta vınlıyor ama motoru çevirmiyor',
    ],
    'f.master_switch': [
        'Ana şalteri açınca tankta hiçbir şey yanmıyor',
        'Ana şalter açılıyor ama elektrik gidip geliyor',
    ],
    'f.instruments.gauge': [
        'Sürücü panelindeki bir ibre hep sıfırda kalıyor',
        'Göstergelerden biri titriyor ya da saçma değer gösteriyor',
    ],
    'f.lights.bulb': [
        'Farlardan biri yanmıyor',
        'Ön köşe lambası yanmıyor, ampul kararmış',
    ],
    'f.taillight.damaged': [
        'Arka lambanın camı kırılmış, içine su dolmuş',
        'Arka lambalar çarpmadan sonra yanmaz oldu',
    ],
    'f.intercom.headset': [
        'Başlıktan arkadaşları duyamıyorum, sadece cızırtı var',
        'Kabloyu oynatınca iç haberleşme bir gelip bir gidiyor',
        'Bir mürettebat yerinin mikrofonu ses iletmiyor',
    ],
    # Yakıt ve güç paketi
    'f.fuel.water': [
        'Yakıt filtresinin su haznesi suyla dolu',
        'Yağmurlu günlerden sonra motor tekliyor ve güç düşüyor',
        'İkmalden sonra motor kesik kesik çalışmaya başladı',
    ],
    'f.fuel.filter_clogged': [
        'Yokuşta tam gazda motor boğuluyor, tank hız almıyor',
        'Yakıt filtresi uzun süredir değişmedi, motor yükte bocalıyor',
    ],
    'f.fuel.air': [
        'Yakıt bitince ikmal yaptık ama motor bir türlü ateş almıyor',
        'Filtre değişiminden sonra motor çalışıp duruyor',
    ],
    'f.fuel.leak': [
        'Güç paketi bölmesinde mazot kokusu var',
        'Yakıt borusunun bağlantısında ıslaklık ve damla var',
    ],
    'f.fuel.cap_seal': [
        'Doldurma kapağının contası yırtılmış ya da yerinden çıkmış',
        'Yıkamadan sonra yakıt filtresinde su birikti',
    ],
    'f.injection.fault': [
        'Motor yükte kara duman atıyor ve sarsılıyor',
        'Rölantide motor düzensiz vuruyor, bir silindir eksik gibi',
    ],
    'f.air_filter.clogged': [
        'Tozlu arazide hava filtresi göstergesi kırmızıya geçti',
        'Hızlanırken egzozdan yoğun kara duman çıkıyor',
    ],
    'f.precleaner.blocked': [
        'Toz atma çıkışından toz çıkmıyor, filtre göstergesi hemen '
        'kırmızıya geçiyor',
        'Ön temizleyicinin girişi çamurla tıkanmış',
    ],
    'f.intake.leak': [
        'Hava kanalının kelepçesi gevşek, iç tarafta toz izi var',
        'Hava filtresinden sonraki kanalda yırtık gördüm',
    ],
    'f.turbo.leak': [
        'Gaza basınca güç paketinden yüksek bir ıslık geliyor',
        'Turboşarj bağlantısında yağlı is izi var, tank çekmiyor',
    ],
    'f.engine.control': [
        'Motor arıza uyarısı yandı, motor güç kesip yavaş moda geçti',
        'Uyarı yanınca motor devri yükselmiyor',
    ],
    'f.engine.oil_burning': [
        'Egzozdan mavimsi duman çıkıyor, yağ seviyesi hızla düşüyor',
        'Uzun rölantiden sonra gaza basınca mavi duman bulutu çıkıyor',
    ],
    'f.engine.coolant_in_oil': [
        'Yağ çubuğundaki yağ süt gibi açık renkli',
        'Soğutma sıvısı eksiliyor ama hiçbir yerde sızıntı yok',
        'Motor ısınmış olmasına rağmen egzozdan beyaz buhar çıkıyor',
    ],
    'f.mounts.worn': [
        'Rölantide bütün gövde titriyor, eskisinden çok daha fazla',
        'Kalkışta ve durmada güç paketi bölmesinden tok bir vuruntu geliyor',
    ],
    'f.oil.low': [
        'Yağ basıncı uyarısı virajda ya da eğimde yanıp sönüyor',
        'Yağ seviyesi alt işaretin altında',
        'Tankın durduğu yerde yağ lekesi kalıyor',
    ],
    'f.oil_cooler.leak': [
        'Yağ soğutucusunun bağlantılarından yağ sızıyor',
        'Radyatörlerin yanında yağlı toz birikmiş',
    ],
    'f.exhaust.leak': [
        'Egzoz kelepçesinin çevresinde kara kurum izi var',
        'Güç paketinden üfleme ve pırpır sesi geliyor',
    ],
    'f.grilles.blocked': [
        'Ormanlık arazide motor sıcaklığı yükseldi, güverte ızgaraları '
        'yaprakla dolu',
        'Çamurlu arazi sonrası ızgaralar çamurla kaplanmış, sıcaklık '
        'artıyor',
    ],
    'f.radiator.dirty': [
        'Izgaralar temiz ama radyatör petekleri tozla kaplı, sıcaklık '
        'yüksek',
        'Uzun süre tozlu yolda gittikten sonra motor ısınmaya başladı',
    ],
    'f.fan.drive': [
        'Soğutma fanlarından biri dönmüyor, diğeri dönüyor',
        'Sıcaklık yükseliyor ve fan sesi her zamankinden zayıf',
    ],
    'f.fan.blade': [
        'Fan tarafından vuruntu ve titreşim geliyor',
        'Fan kanadında kırık ya da eğiklik gördüm',
    ],
    'f.coolant.leak': [
        'Soğutma hortumunun kelepçesinden sıvı damlıyor',
        'Güç paketi bölmesinde tatlımsı soğutma sıvısı kokusu var',
    ],
    'f.coolant.old': [
        'Soğutma sıvısı paslı ve tortulu görünüyor',
        'Antifriz koruması soğuk hava için yetersiz çıktı',
    ],
    # Güç aktarma
    'f.transmission.oil': [
        'Vitesler soğukken sert ve gecikmeli geçiyor',
        'Şanzıman yağı koyu ve yanık kokulu',
    ],
    'f.transmission.leak': [
        'Şanzımanın tapasının çevresinde yağ var',
        'Güç paketinin altında, şanzıman tarafında yağ birikiyor',
    ],
    'f.transmission.cooler': [
        'Uzun sürüşte şanzıman sıcaklık uyarısı yandı',
        'Şanzıman yağ soğutucusunun petekleri kirle kaplanmış',
    ],
    'f.controls.stiff': [
        'Vites seçici ve direksiyon kumandası çok zor hareket ediyor',
        'Sürüş kumandası bir noktada takılıyor',
    ],
    'f.brakes.worn': [
        'Frene basınca tank geç ve uzun mesafede duruyor',
        'Frenlerken tank bir yana dönüyor',
        'Frenlerden yanık kokusu geliyor',
    ],
    'f.parking_brake': [
        'Park freni çekili olduğu hâlde tank eğimde kayıyor',
        'Park freni kolu sonuna kadar gidiyor ama tutmuyor',
    ],
    'f.final_drive.seal': [
        'Yürütücü dişlinin iç tarafı yağlı ve tozla kaplı',
        'Son dişli tarafından öğütme sesi geliyor',
    ],
    # Yürüyen takım
    'f.track.slack': [
        'Palet üst kolda belirgin şekilde sarkıyor',
        'Sert dönüşte palet atmak üzereydi',
        'Palet gerdirme ayarı kısa sürede yeniden gevşiyor',
    ],
    'f.pads.worn': [
        'Palet tabanlarının lastiği aşınmış, bazıları kopmuş',
        'Asfaltta giderken titreşim ve uğultu arttı',
    ],
    'f.track.connector': [
        'Palet bağlantı parçalarından biri dışarı çıkmış',
        'Bağlantı parçasının kama cıvatası gevşemiş ya da düşmüş',
    ],
    'f.wheel.bearing': [
        'Molada bir yol tekerleğinin göbeği elle dokunulamayacak kadar sıcak',
        'Bir yol tekerleğinden hırıltı geliyor, göbekten gres sızıyor',
    ],
    'f.wheel.tyre': [
        'Yol tekerleğinin lastik bandajı parça parça kopuyor',
        'Tekerlek bandajında derin yarık ve kopuk var',
    ],
    'f.damper.leak': [
        'Amortisörün gövdesi yağlı, tank engebede sekiyor',
        'Tank engebeden sonra uzun süre yalpalamaya devam ediyor',
    ],
    'f.torsion_bar.broken': [
        'Bir yol tekerleği yerden kalkmış ya da diğerlerinden yukarıda '
        'duruyor',
        'Düz zeminde tank bir köşeye doğru çökük',
    ],
    'f.arm.bearing': [
        'Salıncak kolunun yatağından gıcırtı geliyor',
        'Salıncak kolunun gresörlüğü kuru, gres almıyor',
    ],
    'f.support_roller': [
        'Destek makarası dönmüyor, palet üstünde sürtüyor',
        'Destek makarasının lastiği kopmuş',
    ],
    'f.sprocket.worn': [
        'Yürütücü dişlinin dişleri sivrilmiş, palet dişliden atlıyor',
        'Palet dişliye otururken takırtı geliyor',
    ],
    # Gövde ve kule
    'f.hatch.seal': [
        'Yağmurdan ya da yıkamadan sonra sürücü bölmesinde su var',
        'Kapak contası yırtık ve sertleşmiş',
    ],
    'f.hatch.stiff': [
        'Sürücü kapağı çok zor açılıyor',
        'Kapak kapanıyor ama kilidi kavramıyor',
    ],
    'f.skirt_l.damaged': [
        'Sol yan etek çarpmadan sonra içe doğru eğildi',
        'Sol yan eteğin cıvatası kopmuş, panel sallanıyor',
    ],
    'f.skirt_r.damaged': [
        'Sağ yan etek çarpmadan sonra içe doğru eğildi',
        'Sağ yan eteğin cıvatası kopmuş, panel sallanıyor',
    ],
    'f.tow_cable.worn': [
        'Çeki halatında kopuk teller dışarı çıkmış',
        'Çeki halatı ezilmiş ve bükülmüş',
    ],
    'f.turret_ring.debris': [
        'Kule döndürürken bir noktada takılıyor',
        'Kule yatağının çevresine taş ve kum sıkışmış',
        'Soğuk havada kule dönmüyor, yatak çevresinde buz var',
    ],
    'f.turret_ring.grease': [
        'Kule dönerken gıcırtı ve kuru sürtme sesi geliyor',
        'Kule yatağının greslenmesi uzun süredir yapılmadı',
    ],
    'f.optics.dirty': [
        'Nişancı optiğinden bakınca görüntü bulanık',
        'Optik camında çamur ve toz var',
    ],
    'f.optics.moisture': [
        'Komutan periskobunun içi buğulu, silince geçmiyor',
        'Optiğin içinde damlacıklar var',
    ],
    'f.periscope.cracked': [
        'Periskop camında taş izi ve çatlak var',
        'Kapak periskobundan bakınca görüntüde çizgi var',
    ],
    'f.muzzle_cover.lost': [
        'Namlu ağzı kapağı yerinde yok',
        'Namlu ağzı kapağı yırtılmış, ağız açıkta',
    ],
    'f.smoke_tube.damaged': [
        'Sis bombası atıcısı dala çarpıp ezilmiş',
        'Atıcının koruyucu kapağı düşmüş',
    ],
    # Hidrolik ve mürettebat bölmesi
    'f.hydraulic.low': [
        'Hidrolik depo göstergesinde seviye düşük',
        'Kule ve hidrolik düzen eskisinden yavaş tepki veriyor',
    ],
    'f.hydraulic.hose': [
        'Hidrolik hortumunun rakorunda yağ damlası var',
        'Hortumun dış kılıfı çatlamış ve yağlı',
    ],
    'f.hydraulic.filter': [
        'Hidrolik filtre göstergesi tıkanıklık gösteriyor',
        'Filtre değişimi gecikti, düzen ağır çalışıyor',
    ],
    'f.nbc.filter': [
        'NBC filtre göstergesi değişim bölgesinde',
        'Havalandırma çalışıyor ama içeri çok az hava geliyor',
    ],
    'f.nbc.intake': [
        'Havalandırma giriş ızgarası çamur ve yaprakla dolu',
        'Fan sesi normal ama hava akışı zayıf',
    ],
    'f.fire.detector': [
        'Yangın sistemi arıza uyarısı yanıyor, tüpler dolu',
        'Algılayıcının üstü yağ ve tozla kaplı',
    ],
    'f.fire.bottle': [
        'Söndürücü tüpünün göstergesi düşük',
        'Yangın sistemi arıza veriyor ve bir tüpün dolumu eksik',
    ],
    'f.extinguisher.low': [
        'El tipi söndürücünün ibresi kırmızı bölgede',
        'El söndürücüsü kullanıldı, yeniden doldurulmadı',
    ],
    'f.heater.blocked': [
        'Isıtıcı çalışıp birkaç dakika sonra sönüyor',
        'Isıtıcının egzozundan yoğun beyaz duman çıkıyor, girişi karla dolu',
    ],
    'f.heater.fuel': [
        'Isıtıcı ateş almıyor, yakıt kokusu geliyor',
        'Isıtıcının yakıt hortumunda kabarcık ve sızıntı var',
    ],
    # Ek arızalar
    'f.idler.bearing': [
        'Molada avara tekerleğinin göbeği diğer yandan çok daha sıcak',
        'Ön taraftan, avaradan hırıltı geliyor',
    ],
    'f.sprocket.bolts': [
        'Yürütücü dişli tarafından tıkırtı geliyor, bir cıvata eksik',
        'Dişli çemberi göbeğe göre oynuyor',
    ],
    'f.slave_socket.dirty': [
        'Takviye kablosunu taktık ama tank çalışmadı',
        'Takviye prizinin içi kararmış ve yanık kokuyor',
    ],
    'f.warning.circuit': [
        'Yağ basıncı uyarısı yanıyor ama yağ seviyesi tam ve motor sessiz',
        'Uyarı lambası arazide sarsıntıyla yanıp sönüyor',
    ],
    'f.accumulator.precharge': [
        'Hidrolik pompa düzen kullanılmadığı hâlde sürekli çalışıp duruyor',
        'Kule hareketi başlangıçta sert, sonra yavaşlıyor',
    ],
    'f.deck_hatch.latch': [
        'Güç paketi kapağı arazide takırdıyor',
        'Motor güvertesi kapağının kilidi kapanmıyor',
    ],
    'f.fender_box.damaged': [
        'Çamurluktaki alet kutusunun kapağı yolda açılıyor',
        'Dış kutu çarpmadan sonra ezildi',
    ],
    'f.antenna.broken': [
        'Ağaç dalına çarpınca anten kırıldı',
        'Anten eğilmiş, telsiz çekmiyor',
    ],
    'f.gun_boot.torn': [
        'Top kalkanının kenarındaki körük yırtılmış',
        'Körük yerinden çıkmış, aralıktan toz giriyor',
    ],
    'f.nbc.fan_power': [
        'Havalandırmayı açınca fan hiç çalışmıyor',
        'Havalandırma ünitesinden ne ses ne hava geliyor',
    ],
    'f.oil.old': [
        'Motor yağı kapkara ve yanık kokuyor',
        'Yağ değişimi bakım kaydına göre çoktan geçmiş',
    ],
    'f.parking_brake.drag': [
        'Park frenini indirdim ama tank frenli gibi zor yürüyor',
        'Kısa sürüşten sonra fren tarafından yanık balata kokusu geliyor',
    ],
    'f.hydraulic.contaminated': [
        'Hidrolik yağı süt gibi bulanık görünüyor',
        'Depoda hidrolik yağı köpüklü',
    ],
}

C.zones, C.symptoms, C.faults = ZONES, SYMPTOMS, FAULTS
C.add_phrasings(PHRASINGS)
C.spare_parts = SPARE_PARTS
C.write()
