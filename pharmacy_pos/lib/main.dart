
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String brandOwner = 'Powered by Mj14';
const String vodaLipaNamba = 'INAANDALIWA';
const String jinaLaLipaNamba = 'MJ14 SMARTPHARMA';
const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
const int currentAppVersion = 3;

String get _s1 => 'MJ14_SP_';
String get _s2 => 'G99X_SEC_';
String get _s3 => '887711_TZ';
String get secretSignatureSalt => '$_s1$_s2$_s3';

String hashText(String input) {
  final bytes = utf8.encode('$input-$secretSignatureSalt');
  return sha256.convert(bytes).toString();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartPharmaApp());
}

class AppLang {
  static String current = 'sw';
  static bool get isRTL => current == 'ar';

  static String t(String key) {
    const Map<String, Map<String, String>> dict = {
      'register_biz': {'sw': 'Sajili Duka Jipya (Admin)', 'en': 'Register New Shop (Admin)', 'fr': 'Nouvelle Pharmacie', 'es': 'Registrar Farmacia', 'ar': 'تسجيل صيدلية جديدة'},
      'join_biz': {'sw': 'Jiunge na Duka (Mhudumu)', 'en': 'Join Existing Shop (Staff)', 'fr': 'Rejoindre Pharmacie', 'es': 'Unirse a Farmacia', 'ar': 'الانضمام إلى صيدلية'},
      'shop_name': {'sw': 'Jina la Duka / Famasi *', 'en': 'Pharmacy / Shop Name *', 'fr': 'Nom de la Pharmacie *', 'es': 'Nombre de Farmacia *', 'ar': 'اسم الصيدلية *'},
      'location': {'sw': 'Mtaa / Wilaya / Mkoa', 'en': 'Street / City / Region', 'fr': 'Rue / Ville / Région', 'es': 'Calle / Ciudad', 'ar': 'الشارع / المدينة'},
      'phone': {'sw': 'Namba ya Simu ya Duka *', 'en': 'Shop Phone Number *', 'fr': 'Numéro de Téléphone *', 'es': 'Teléfono *', 'ar': 'رقم الهاتف *'},
      'admin_name': {'sw': 'Jina Lako (Admin) *', 'en': 'Your Name (Admin) *', 'fr': 'Votre Nom (Admin) *', 'es': 'Su Nombre (Admin) *', 'ar': 'اسم المدير *'},
      'create_pin': {'sw': 'Tengeneza PIN (Tarakimu 4) *', 'en': 'Create 4-Digit PIN *', 'fr': 'Créer Code PIN *', 'es': 'Crear PIN (4 Dígitos) *', 'ar': 'إنشاء رمز PIN *'},
      'start_trial': {'sw': 'Anza Siku 14 Bure', 'en': 'Start 14-Day Free Trial', 'fr': 'Essai Gratuit 14 Jours', 'es': 'Iniciar Prueba 14 Días', 'ar': 'ابدأ التجربة المجانية'},
      'pos_stock': {'sw': 'Mauzo & Stoo', 'en': 'POS & Stock', 'fr': 'Ventes & Stock', 'es': 'Ventas y Stock', 'ar': 'المبيعات والمخزون'},
      'reports_cap': {'sw': 'Ripoti & Mtaji', 'en': 'Reports & Capital', 'fr': 'Rapports & Capital', 'es': 'Informes y Capital', 'ar': 'التقارير ورأس المال'},
      'search_med': {'sw': 'Tafuta dawa stoo...', 'en': 'Search medicine...', 'fr': 'Rechercher médicament...', 'es': 'Buscar medicamento...', 'ar': 'البحث عن دواء...'},
      'add_med': {'sw': 'Sajili Dawa', 'en': 'Add Medicine', 'fr': 'Ajouter Médicament', 'es': 'Agregar Medicamento', 'ar': 'إضافة دواء'},
      'add_cart': {'sw': '+ KIKAPU', 'en': '+ CART', 'fr': '+ PANIER', 'es': '+ CARRITO', 'ar': '+ السلة'},
      'confirm_sale': {'sw': 'Thibitisha Mauzo', 'en': 'Confirm Sale', 'fr': 'Confirmer la Vente', 'es': 'Confirmar Venta', 'ar': 'تأكيد البيع'},
      'receipt_ask': {'sw': 'Je, mteja anahitaji risiti?', 'en': 'Does the customer need a receipt?', 'fr': 'Besoin d\'un reçu ?', 'es': '¿Necesita recibo?', 'ar': 'هل يحتاج العميل إلى إيصال؟'},
      'no_close': {'sw': 'Hapana / Funga', 'en': 'No / Close', 'fr': 'Non / Fermer', 'es': 'No / Cerrar', 'ar': 'لا / إغلاق'},
      'send_receipt': {'sw': 'Tuma Risiti (WhatsApp/SMS)', 'en': 'Send Receipt (WhatsApp/SMS)', 'fr': 'Envoyer Reçu', 'es': 'Enviar Recibo', 'ar': 'إرسال الإيصال'},
    };
    return dict[key]?[current] ?? dict[key]?['en'] ?? key;
  }
}

class SmartPharmaApp extends StatelessWidget {
  const SmartPharmaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartPharma POS',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)), useMaterial3: true),
      builder: (context, child) => Directionality(textDirection: AppLang.isRTL ? TextDirection.rtl : TextDirection.ltr, child: child!),
      home: const StartupGatekeeper(),
    );
  }
}

class DukaProfile {
  String shopId, jinaLaDuka, eneo, simu, tin, lugha, sarafu, ujumbeWaRisiti;
  DukaProfile({required this.shopId, required this.jinaLaDuka, required this.eneo, required this.simu, this.tin = '', this.lugha = 'sw', this.sarafu = 'TZS', this.ujumbeWaRisiti = 'Asante kwa kutuhudumia!'});
  Map<String, dynamic> toJson() => {'shopId': shopId, 'jinaLaDuka': jinaLaDuka, 'eneo': eneo, 'simu': simu, 'tin': tin, 'lugha': lugha, 'sarafu': sarafu, 'ujumbeWaRisiti': ujumbeWaRisiti};
  factory DukaProfile.fromJson(Map<String, dynamic> json) => DukaProfile(shopId: json['shopId'], jinaLaDuka: json['jinaLaDuka'], eneo: json['eneo'], simu: json['simu'], tin: json['tin'] ?? '', lugha: json['lugha'] ?? 'sw', sarafu: json['sarafu'] ?? 'TZS', ujumbeWaRisiti: json['ujumbeWaRisiti'] ?? 'Asante!');
}

class Mtumiaji {
  String id, jina, pinHash;
  bool niAdmin, anaruhusiwa;
  Mtumiaji({required this.id, required this.jina, required this.pinHash, required this.niAdmin, this.anaruhusiwa = true});
  Map<String, dynamic> toJson() => {'id': id, 'jina': jina, 'pinHash': pinHash, 'niAdmin': niAdmin, 'anaruhusiwa': anaruhusiwa};
  factory Mtumiaji.fromJson(Map<String, dynamic> json) => Mtumiaji(id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), jina: json['jina'], pinHash: json['pinHash'] ?? hashText(json['pin'] ?? '0000'), niAdmin: json['niAdmin'] ?? false, anaruhusiwa: json['anaruhusiwa'] ?? true);
}

class MzigoDawa {
  String id, jina, aina, tareheExpiry;
  double beiKununua, beiKuuza;
  int idadiStoo;
  MzigoDawa({required this.id, required this.jina, required this.aina, required this.beiKununua, required this.beiKuuza, required this.idadiStoo, required this.tareheExpiry});
  int get sikuZilizobaki {
    try {
      final expDate = DateTime.parse(tareheExpiry);
      final leo = DateTime.now();
      return expDate.difference(DateTime(leo.year, leo.month, leo.day)).inDays;
    } catch (e) { return 999; }
  }
  bool get imeExpire => sikuZilizobaki <= 0;
  Map<String, dynamic> toJson() => {'id': id, 'jina': jina, 'aina': aina, 'beiKununua': beiKununua, 'beiKuuza': beiKuuza, 'idadiStoo': idadiStoo, 'tareheExpiry': tareheExpiry};
  factory MzigoDawa.fromJson(Map<String, dynamic> json) => MzigoDawa(id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), jina: json['jina'], aina: json['aina'] ?? 'General', beiKununua: (json['beiKununua'] as num).toDouble(), beiKuuza: (json['beiKuuza'] as num).toDouble(), idadiStoo: json['idadiStoo'], tareheExpiry: json['tareheExpiry']);
}

class KipengeleChaKikapu {
  MzigoDawa mzigo;
  int idadi;
  KipengeleChaKikapu({required this.mzigo, required this.idadi});
  double get jumlaBei => mzigo.beiKuuza * idadi;
  double get jumlaFaida => (mzigo.beiKuuza - mzigo.beiKununua) * idadi;
}

class Muamala {
  String id, maelezoYaBidhaa, mhudumu, tarehe, mwezi, mwaka, saa;
  double jumlaMauzo, jumlaFaida;
  Muamala({required this.id, required this.maelezoYaBidhaa, required this.jumlaMauzo, required this.jumlaFaida, required this.mhudumu, required this.tarehe, required this.mwezi, required this.mwaka, required this.saa});
  Map<String, dynamic> toJson() => {'id': id, 'maelezoYaBidhaa': maelezoYaBidhaa, 'jumlaMauzo': jumlaMauzo, 'jumlaFaida': jumlaFaida, 'mhudumu': mhudumu, 'tarehe': tarehe, 'mwezi': mwezi, 'mwaka': mwaka, 'saa': saa};
  factory Muamala.fromJson(Map<String, dynamic> json) => Muamala(id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(), maelezoYaBidhaa: json['maelezoYaBidhaa'] ?? '', jumlaMauzo: (json['jumlaMauzo'] as num).toDouble(), jumlaFaida: (json['jumlaFaida'] as num).toDouble(), mhudumu: json['mhudumu'] ?? 'Staff', tarehe: json['tarehe'] ?? '', mwezi: json['mwezi'] ?? '', mwaka: json['mwaka'] ?? '', saa: json['saa'] ?? '');
}
class StartupGatekeeper extends StatefulWidget {
  const StartupGatekeeper({super.key});
  @override
  State<StartupGatekeeper> createState() => _StartupGatekeeperState();
}

class _StartupGatekeeperState extends State<StartupGatekeeper> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool inapakia = true, dukaLimesajiliwa = false, kifurushiKimeisha = false, saaImechezewa = false, toleoLaZamani = false;
  String shopId = "", kifurushiChaSasa = "Trial";
  int sikuZilizobakiZaLeseni = 14;

  @override
  void initState() {
    super.initState();
    kaguaUsalamaNaLeseni();
  }

  Future<void> kaguaUsalamaNaLeseni() async {
    final prefs = await SharedPreferences.getInstance();
    final String? dukaJson = prefs.getString('sp_duka_profile');
    await kaguaRemoteSettings();

    if (dukaJson == null) {
      setState(() { dukaLimesajiliwa = false; inapakia = false; });
      return;
    }

    final duka = DukaProfile.fromJson(jsonDecode(dukaJson));
    AppLang.current = duka.lugha;
    shopId = duka.shopId;

    final sasaMs = DateTime.now().millisecondsSinceEpoch;
    final String? lastSeenStr = await _secureStorage.read(key: 'sp_last_seen_ms');
    if (lastSeenStr != null && sasaMs < (int.parse(lastSeenStr) - 600000)) {
      setState(() { dukaLimesajiliwa = true; saaImechezewa = true; inapakia = false; });
      return;
    }
    await _secureStorage.write(key: 'sp_last_seen_ms', value: sasaMs.toString());
    await vutaDataKutokaCloud(shopId);

    String? expiryMsStr = await _secureStorage.read(key: 'sp_license_expiry_ms');
    String? planName = await _secureStorage.read(key: 'sp_license_plan');

    if (expiryMsStr == null) {
      final trialExpiry = DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch;
      await _secureStorage.write(key: 'sp_license_expiry_ms', value: trialExpiry.toString());
      await _secureStorage.write(key: 'sp_license_plan', value: 'Trial (14 Days)');
      expiryMsStr = trialExpiry.toString();
      planName = 'Trial (14 Days)';
    }

    final int expiryMs = int.parse(expiryMsStr);
    final int sikuZilizobaki = ((expiryMs - sasaMs) / (1000 * 60 * 60 * 24)).ceil();

    setState(() {
      dukaLimesajiliwa = true;
      kifurushiChaSasa = planName ?? 'Starter';
      sikuZilizobakiZaLeseni = sikuZilizobaki > 0 ? sikuZilizobaki : 0;
      kifurushiKimeisha = sasaMs >= expiryMs;
      inapakia = false;
    });
  }

  Future<void> kaguaRemoteSettings() async {
    if (supabaseUrl.contains('YOUR_PROJECT_ID')) return;
    try {
      final res = await http.get(Uri.parse('$supabaseUrl/rest/v1/app_settings?id=eq.1'), headers: {'apikey': supabaseAnonKey, 'Authorization': 'Bearer $supabaseAnonKey'}).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty && currentAppVersion < (data.first['min_version'] ?? 1)) {
          setState(() => toleoLaZamani = true);
        }
      }
    } catch (_) {}
  }

  Future<void> vutaDataKutokaCloud(String sId) async {
    if (supabaseUrl.contains('YOUR_PROJECT_ID')) return;
    try {
      final res = await http.get(Uri.parse('$supabaseUrl/rest/v1/duka_backups?shop_id=eq.$sId'), headers: {'apikey': supabaseAnonKey, 'Authorization': 'Bearer $supabaseAnonKey'}).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          final row = data.first;
          final prefs = await SharedPreferences.getInstance();
          if (row['staff_json'] != null) await prefs.setString('sp_watumiaji', jsonEncode(row['staff_json']));
          if (row['license_expiry_ms'] != null) {
            final int cloudExpiry = row['license_expiry_ms'];
            final int localExp = int.tryParse(await _secureStorage.read(key: 'sp_license_expiry_ms') ?? '0') ?? 0;
            if (cloudExpiry > localExp) {
              await _secureStorage.write(key: 'sp_license_expiry_ms', value: cloudExpiry.toString());
              await _secureStorage.write(key: 'sp_license_plan', value: row['plan_name'] ?? 'Pro');
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (inapakia) {
      return const Scaffold(
        backgroundColor: Color(0xFF004D40),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_pharmacy, size: 64, color: Colors.white),
              SizedBox(height: 12),
              Text('SmartPharma', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(brandOwner, style: TextStyle(color: Colors.tealAccent, fontSize: 13)),
              SizedBox(height: 24),
              CircularProgressIndicator(color: Colors.tealAccent),
            ],
          ),
        ),
      );
    }
    if (toleoLaZamani) {
      return const Scaffold(backgroundColor: Color(0xFF004D40), body: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Toleo jipya la SmartPharma linapatikana. Tafadhali sasisha app yako.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))));
    }
    if (!dukaLimesajiliwa) return const OnboardingScreen();
    if (saaImechezewa) {
      return Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.security_update_warning, size: 64, color: Colors.white),
          const SizedBox(height: 12),
          const Text('CLOCK SECURITY ALERT\nWeka Automatic Date & Time kwenye simu yako.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () { setState(() { inapakia = true; saaImechezewa = false; }); kaguaUsalamaNaLeseni(); }, child: const Text('Jaribu Tena'))
        ])),
      );
    }
    if (kifurushiKimeisha) {
      return OfflineSmsPaywall(shopId: shopId, onUnlocked: () { setState(() { inapakia = true; kifurushiKimeisha = false; }); kaguaUsalamaNaLeseni(); });
    }
    return PinLoginScreen(kifurushiChaSasa: kifurushiChaSasa, sikuZilizobaki: sikuZilizobakiZaLeseni);
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool niKujiungaNaDuka = false, inatafutaDuka = false;
  final _jinaDukaCtrl = TextEditingController(), _eneoCtrl = TextEditingController(), _simuCtrl = TextEditingController(), _adminJinaCtrl = TextEditingController(), _adminPinCtrl = TextEditingController(), _joinShopIdCtrl = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String lughaIliyochaguliwa = 'sw';

  Future<void> kamilishaUsajiliMpya() async {
    if (_jinaDukaCtrl.text.trim().isEmpty || _simuCtrl.text.trim().isEmpty || _adminJinaCtrl.text.trim().isEmpty || _adminPinCtrl.text.trim().length != 4) {
      _ujumbe('Jaza taarifa zote muhimu na PIN ya tarakimu 4!', Colors.red);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final rand = Random().nextInt(899) + 100;
    final String shopId = 'MJ14-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}$rand';
    final duka = DukaProfile(shopId: shopId, jinaLaDuka: _jinaDukaCtrl.text.trim(), eneo: _eneoCtrl.text.trim().isEmpty ? 'Tanzania' : _eneoCtrl.text.trim(), simu: _simuCtrl.text.trim(), lugha: lughaIliyochaguliwa, sarafu: lughaIliyochaguliwa == 'sw' ? 'TZS' : 'USD');
    final admin = Mtumiaji(id: 'ADM-1', jina: _adminJinaCtrl.text.trim(), pinHash: hashText(_adminPinCtrl.text.trim()), niAdmin: true);

    await prefs.setString('sp_duka_profile', jsonEncode(duka.toJson()));
    await prefs.setString('sp_watumiaji', jsonEncode([admin.toJson()]));

    final trialExpiry = DateTime.now().add(const Duration(days: 14)).millisecondsSinceEpoch;
    await _secureStorage.write(key: 'sp_license_expiry_ms', value: trialExpiry.toString());
    await _secureStorage.write(key: 'sp_license_plan', value: 'Trial (14 Days)');
    await _secureStorage.write(key: 'sp_last_seen_ms', value: DateTime.now().millisecondsSinceEpoch.toString());

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StartupGatekeeper()));
  }

  Future<void> jiungeNaDukaLililopo() async {
    final sId = _joinShopIdCtrl.text.trim().toUpperCase();
    if (sId.isEmpty) { _ujumbe('Weka Shop ID uliyopewa na Admin wako', Colors.red); return; }
    if (supabaseUrl.contains('YOUR_PROJECT_ID')) { _ujumbe('Seva haijaunganishwa bado', Colors.red); return; }

    setState(() => inatafutaDuka = true);
    try {
      final res = await http.get(Uri.parse('$supabaseUrl/rest/v1/duka_backups?shop_id=eq.$sId'), headers: {'apikey': supabaseAnonKey, 'Authorization': 'Bearer $supabaseAnonKey'});
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isEmpty) {
          _ujumbe('Shop ID ($sId) haikupatikana.', Colors.red);
        } else {
          final row = data.first;
          final prefs = await SharedPreferences.getInstance();
          final duka = DukaProfile(shopId: sId, jinaLaDuka: row['jina_duka'] ?? 'SmartPharma', eneo: row['eneo'] ?? '', simu: row['simu'] ?? '', lugha: lughaIliyochaguliwa, sarafu: row['sarafu'] ?? 'TZS');
          await prefs.setString('sp_duka_profile', jsonEncode(duka.toJson()));
          if (row['staff_json'] != null) await prefs.setString('sp_watumiaji', jsonEncode(row['staff_json']));
