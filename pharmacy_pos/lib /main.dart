import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'paywall_and_login.dart';
import 'dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartPharmaApp());
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
      setState(() {
        dukaLimesajiliwa = false;
        inapakia = false;
      });
      return;
    }

    final duka = DukaProfile.fromJson(jsonDecode(dukaJson));
    AppLang.current = duka.lugha;
    shopId = duka.shopId;

    final sasaMs = DateTime.now().millisecondsSinceEpoch;
    final String? lastSeenStr = await _secureStorage.read(key: 'sp_last_seen_ms');
    if (lastSeenStr != null && sasaMs < (int.parse(lastSeenStr) - 600000)) {
      setState(() {
        dukaLimesajiliwa = true;
        saaImechezewa = true;
        inapakia = false;
      });
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_update_warning, size: 64, color: Colors.white),
              const SizedBox(height: 12),
              const Text('CLOCK SECURITY ALERT\nWeka Automatic Date & Time kwenye simu yako.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () { setState(() { inapakia = true; saaImechezewa = false; }); kaguaUsalamaNaLeseni(); }, child: const Text('Jaribu Tena'))
            ],
          ),
        ),
      );
    }
    if (kifurushiKimeisha) {
      return OfflineSmsPaywall(shopId: shopId, onUnlocked: () { setState(() { inapakia = true; kifurushiKimeisha = false; }); kaguaUsalamaNaLeseni(); });
    }
    return PinLoginScreen(
      kifurushiChaSasa: kifurushiChaSasa,
      sikuZilizobaki: sikuZilizobakiZaLeseni,
      onLoginSuccess: (duka, mhusika, siku) => SmartPharmaDashboard(
        duka: duka,
        mtumiajiAliyeingia: mhusika,
        sikuZilizobakiZaLeseni: siku,
        onLogout: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StartupGatekeeper())),
      ),
    );
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
