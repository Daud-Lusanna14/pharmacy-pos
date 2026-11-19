import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const String supabaseAnonKey = 'YOUR_ANON_KEY';

String hashText(String input) {
  int hash = 5381;
  for (int i = 0; i < input.length; i++) {
    hash = ((hash << 5) + hash) + input.codeUnitAt(i);
    hash = hash & 0x7FFFFFFF;
  }
  return hash.toRadixString(16);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SmartPharmaApp());
}

// ============================================================================
// 1. DATA MODELS
// ============================================================================

class DukaProfile {
  String shopId;
  String jinaLaDuka;
  String eneo;
  String simu;
  String sarafu;

  DukaProfile({
    required this.shopId,
    required this.jinaLaDuka,
    required this.eneo,
    required this.simu,
    this.sarafu = 'TZS',
  });

  Map<String, dynamic> toJson() => {
        'shopId': shopId,
        'jinaLaDuka': jinaLaDuka,
        'eneo': eneo,
        'simu': simu,
        'sarafu': sarafu,
      };

  factory DukaProfile.fromJson(Map<String, dynamic> json) => DukaProfile(
        shopId: json['shopId'] ?? '',
        jinaLaDuka: json['jinaLaDuka'] ?? 'SmartPharma',
        eneo: json['eneo'] ?? '',
        simu: json['simu'] ?? '',
        sarafu: json['sarafu'] ?? 'TZS',
      );
}

class Mtumiaji {
  String id;
  String jina;
  String pinHash;
  bool niAdmin;
  bool anaruhusiwa;

  Mtumiaji({
    required this.id,
    required this.jina,
    required this.pinHash,
    this.niAdmin = false,
    this.anaruhusiwa = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jina': jina,
        'pinHash': pinHash,
        'niAdmin': niAdmin,
        'anaruhusiwa': anaruhusiwa,
      };

  factory Mtumiaji.fromJson(Map<String, dynamic> json) => Mtumiaji(
        id: json['id'] ?? '',
        jina: json['jina'] ?? '',
        pinHash: json['pinHash'] ?? '',
        niAdmin: json['niAdmin'] ?? false,
        anaruhusiwa: json['anaruhusiwa'] ?? true,
      );
}

class MzigoDawa {
  String id;
  String jina;
  String aina;
  double beiKununua;
  double beiKuuza;
  int idadiStoo;
  String tareheExpiry;

  MzigoDawa({
    required this.id,
    required this.jina,
    required this.aina,
    required this.beiKununua,
    required this.beiKuuza,
    required this.idadiStoo,
    required this.tareheExpiry,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'jina': jina,
        'aina': aina,
        'beiKununua': beiKununua,
        'beiKuuza': beiKuuza,
        'idadiStoo': idadiStoo,
        'tareheExpiry': tareheExpiry,
      };

  factory MzigoDawa.fromJson(Map<String, dynamic> json) => MzigoDawa(
        id: json['id'] ?? '',
        jina: json['jina'] ?? '',
        aina: json['aina'] ?? 'General',
        beiKununua: (json['beiKununua'] ?? 0).toDouble(),
        beiKuuza: (json['beiKuuza'] ?? 0).toDouble(),
        idadiStoo: (json['idadiStoo'] ?? 0).toInt(),
        tareheExpiry: json['tareheExpiry'] ?? '2099-12-31',
      );
}

class Muamala {
  String id;
  String tarehe;
  String saa;
  String maelezo;
  double jumlaBei;
  double jumlaFaida;
  String mhudumu;

  Muamala({
    required this.id,
    required this.tarehe,
    required this.saa,
    required this.maelezo,
    required this.jumlaBei,
    required this.jumlaFaida,
    required this.mhudumu,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tarehe': tarehe,
        'saa': saa,
        'maelezo': maelezo,
        'jumlaBei': jumlaBei,
        'jumlaFaida': jumlaFaida,
        'mhudumu': mhudumu,
      };

  factory Muamala.fromJson(Map<String, dynamic> json) => Muamala(
        id: json['id'] ?? '',
        tarehe: json['tarehe'] ?? '',
        saa: json['saa'] ?? '',
        maelezo: json['maelezo'] ?? '',
        jumlaBei: (json['jumlaBei'] ?? 0).toDouble(),
        jumlaFaida: (json['jumlaFaida'] ?? 0).toDouble(),
        mhudumu: json['mhudumu'] ?? '',
      );
}

class KipengeleChaKikapu {
  MzigoDawa mzigo;
  int idadi;

  KipengeleChaKikapu({required this.mzigo, this.idadi = 1});

  double get jumlaBei => mzigo.beiKuuza * idadi;
  double get jumlaFaida => (mzigo.beiKuuza - mzigo.beiKununua) * idadi;
}

// ============================================================================
// 2. ROOT APP & STARTUP GATEKEEPER
// ============================================================================

class SmartPharmaApp extends StatelessWidget {
  const SmartPharmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartPharma POS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        useMaterial3: true,
      ),
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
  final storage = const FlutterSecureStorage();
  bool inapakia = true;
  int sikuZilizobaki = 14;
  DukaProfile? duka;
  List<Mtumiaji> watumiaji = [];
  Mtumiaji? mtumiajiAliyeingia;

  @override
  void initState() {
    super.initState();
    kaguaHaliYaMfumo();
  }

  Future<void> kaguaHaliYaMfumo() async {
    setState(() => inapakia = true);
    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    String? expStr = await storage.read(key: 'sp_license_expiry_ms');
    int expMs;
    if (expStr == null) {
      expMs = nowMs + const Duration(days: 14).inMilliseconds;
      await storage.write(key: 'sp_license_expiry_ms', value: expMs.toString());
    } else {
      expMs = int.tryParse(expStr) ?? nowMs;
    }

    final diffMs = expMs - nowMs;
    sikuZilizobaki = diffMs > 0 ? (diffMs / Duration.millisecondsPerDay).ceil() : 0;

    final dukaStr = prefs.getString('sp_duka_profile');
    final usersStr = prefs.getString('sp_watumiaji');

    if (dukaStr != null) {
      duka = DukaProfile.fromJson(jsonDecode(dukaStr));
    } else {
      duka = null;
    }

    if (usersStr != null) {
      watumiaji = (jsonDecode(usersStr) as List)
          .map((e) => Mtumiaji.fromJson(e))
          .toList();
    } else {
      watumiaji = [];
    }

    setState(() => inapakia = false);
  }

  @override
  Widget build(BuildContext context) {
    if (inapakia) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (sikuZilizobaki <= 0) {
      return PaywallScreen(onActivated: kaguaHaliYaMfumo);
    }

    if (duka == null || watumiaji.isEmpty) {
      return ShopSetupScreen(onCompleted: kaguaHaliYaMfumo);
    }

    if (mtumiajiAliyeingia == null) {
      return PinLoginScreen(
        duka: duka!,
        watumiaji: watumiaji,
        sikuZilizobaki: sikuZilizobaki,
        onLoginSuccess: (user) => setState(() => mtumiajiAliyeingia = user),
        onResetShop: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('sp_duka_profile');
          await prefs.remove('sp_watumiaji');
          kaguaHaliYaMfumo();
        },
      );
    }

    return SmartPharmaDashboard(
      duka: duka!,
      mtumiajiAliyeingia: mtumiajiAliyeingia!,
      sikuZilizobakiZaLeseni: sikuZilizobaki,
      onLogout: () => setState(() => mtumiajiAliyeingia = null),
    );
  }
}

// ============================================================================
// 3. PAYWALL, SHOP SETUP & PIN LOGIN SCREENS
// ============================================================================

class PaywallScreen extends StatefulWidget {
  final VoidCallback onActivated;
  const PaywallScreen({super.key, required this.onActivated});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final codeCtrl = TextEditingController();
  String ujumbe = '';

  Future<void> wezeshaLeseni() async {
    final code = codeCtrl.text.trim().toUpperCase();
    int daysToAdd = 0;
    if (code == 'PHARMA30' || code == 'MJ14-30') {
      daysToAdd = 30;
    } else if (code == 'PHARMA365' || code == 'MJ14-365') {
      daysToAdd = 365;
    } else if (code == 'TRIAL7') {
      daysToAdd = 7;
    }

    if (daysToAdd > 0) {
      final newExp = DateTime.now().add(Duration(days: daysToAdd)).millisecondsSinceEpoch;
      await const FlutterSecureStorage().write(
        key: 'sp_license_expiry_ms',
        value: newExp.toString(),
      );
      widget.onActivated();
    } else {
      setState(() => ujumbe = 'Kodi si sahihi. Wasiliana na mtoa huduma.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D40),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_clock, size: 56, color: Colors.teal),
                const SizedBox(height: 12),
                const Text(
                  'Muda wa Leseni Umeisha',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ingiza kodi ya malipo (Activation Code) kuendelea kutumia SmartPharma POS.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Activation Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (ujumbe.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(ujumbe, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: wezeshaLeseni,
                    child: const Text('Washa Leseni Sasa'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShopSetupScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const ShopSetupScreen({super.key, required this.onCompleted});

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  final jinaDukaCtrl = TextEditingController();
  final eneoCtrl = TextEditingController();
  final simuCtrl = TextEditingController();
  final adminJinaCtrl = TextEditingController();
  final adminPinCtrl = TextEditingController();
  String sarafu = 'TZS';

  Future<void> hifadhiUsajili() async {
    if (jinaDukaCtrl.text.trim().isEmpty ||
        adminJinaCtrl.text.trim().isEmpty ||
        adminPinCtrl.text.trim().length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jaza jina la duka, jina lako na PIN ya tarakimu 4.')),
      );
      return;
    }

    final shopId = 'SP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final duka = DukaProfile(
      shopId: shopId,
      jinaLaDuka: jinaDukaCtrl.text.trim(),
      eneo: eneoCtrl.text.trim(),
      simu: simuCtrl.text.trim(),
      sarafu: sarafu,
    );

    final admin = Mtumiaji(
      id: 'ADM-1',
      jina: adminJinaCtrl.text.trim(),
      pinHash: hashText(adminPinCtrl.text.trim()),
      niAdmin: true,
      anaruhusiwa: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sp_duka_profile', jsonEncode(duka.toJson()));
    await prefs.setString('sp_watumiaji', jsonEncode([admin.toJson()]));
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sajili Duka Jipya')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: jinaDukaCtrl,
              decoration: const InputDecoration(labelText: 'Jina la Duka la Dawa *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: eneoCtrl,
              decoration: const InputDecoration(labelText: 'Eneo / Mtaa'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: simuCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Namba ya Simu'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: sarafu,
              decoration: const InputDecoration(labelText: 'Sarafu (Currency)'),
              items: ['TZS', 'KES', 'UGX', 'USD']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => sarafu = v ?? 'TZS'),
            ),
            const Divider(height: 32),
            TextField(
              controller: adminJinaCtrl,
              decoration: const InputDecoration(labelText: 'Jina la Mmiliki / Admin *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: adminPinCtrl,
              maxLength: 4,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Tengeneza PIN ya Siri (Tarakimu 4) *'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hifadhiUsajili,
                child: const Text('Kamilisha Usajili wa Duka'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PinLoginScreen extends StatefulWidget {
  final DukaProfile duka;
  final List<Mtumiaji> watumiaji;
  final int sikuZilizobaki;
  final Function(Mtumiaji) onLoginSuccess;
  final VoidCallback onResetShop;

  const PinLoginScreen({
    super.key,
    required this.duka,
    required this.watumiaji,
    required this.sikuZilizobaki,
    required this.onLoginSuccess,
    required this.onResetShop,
  });

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  String pinIliyoingizwa = '';
  String ujumbeWaKosa = '';

  void bonyeza(String n) {
    if (pinIliyoingizwa.length >= 4) return;
    setState(() {
      pinIliyoingizwa += n;
      ujumbeWaKosa = '';
    });

    if (pinIliyoingizwa.length == 4) {
      final hashed = hashText(pinIliyoingizwa);
      final match = widget.watumiaji.where((u) => u.pinHash == hashed).toList();
      if (match.isNotEmpty) {
        final user = match.first;
        if (!user.anaruhusiwa) {
          setState(() {
            ujumbeWaKosa = 'Akaunti hii imefungwa na Admin.';
            pinIliyoingizwa = '';
          });
        } else {
          widget.onLoginSuccess(user);
        }
      } else {
        setState(() {
          ujumbeWaKosa = 'PIN si sahihi, jaribu tena.';
          pinIliyoingizwa = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D40),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_pharmacy, size: 56, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                widget.duka.jinaLaDuka,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'Shop ID: ${widget.duka.shopId} • Siku ${widget.sikuZilizobaki} zimebaki',
                style: const TextStyle(color: Colors.tealAccent, fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < pinIliyoingizwa.length ? Colors.tealAccent : Colors.white24,
                    ),
                  ),
                ),
              ),
              if (ujumbeWaKosa.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(ujumbeWaKosa, style: const TextStyle(color: Colors.redAccent)),
              ],
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map(
                    (n) => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white12,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => bonyeza(n),
                      child: Text(n, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => bonyeza('0'),
                    child: const Text('0', style: TextStyle(fontSize: 20)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (pinIliyoingizwa.isNotEmpty) {
                        setState(() => pinIliyoingizwa = pinIliyoingizwa.substring(0, pinIliyoingizwa.length - 1));
                      }
                    },
                    child: const Icon(Icons.backspace),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: widget.onResetShop,
                child: const Text('Badili Duka / Reset', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 4. MAIN DASHBOARD (POS, STOO, RIPOTI)
// ============================================================================

class SmartPharmaDashboard extends StatefulWidget {
  final DukaProfile duka;
  final Mtumiaji mtumiajiAliyeingia;
  final int sikuZilizobakiZaLeseni;
  final VoidCallback onLogout;

  const SmartPharmaDashboard({
    super.key,
    required this.duka,
    required this.mtumiajiAliyeingia,
    required this.sikuZilizobakiZaLeseni,
    required this.onLogout,
  });

  @override
  State<SmartPharmaDashboard> createState() => _SmartPharmaDashboardState();
}

class _SmartPharmaDashboardState extends State<SmartPharmaDashboard> {
  late DukaProfile dukaLaSasa;
  int tabIndex = 0;
  List<MzigoDawa> mizigo = [];
  List<Muamala> miamala = [];
  List<Mtumiaji> watumiaji = [];
  List<KipengeleChaKikapu> kikapu = [];
  String utafutaji = '';

  @override
  void initState() {
    super.initState();
    dukaLaSasa = widget.duka;
    pakiaData();
  }

  String get leo => DateTime.now().toIso8601String().split('T').first;
  String get mweziHuu => leo.substring(0, 7);

  Future<void> pakiaData() async {
    final prefs = await SharedPreferences.getInstance();
    final dStr = prefs.getString('sp_mizigo_v2');
    final mStr = prefs.getString('sp_miamala');
    final uStr = prefs.getString('sp_watumiaji');

    if (dStr != null) {
      mizigo = (jsonDecode(dStr) as List).map((e) => MzigoDawa.fromJson(e)).toList();
    }
    if (mStr != null) {
      miamala = (jsonDecode(mStr) as List).map((e) => Muamala.fromJson(e)).toList();
    }
    if (uStr != null) {
      watumiaji = (jsonDecode(uStr) as List).map((e) => Mtumiaji.fromJson(e)).toList();
    }
    setState(() {});
  }

  Future<void> hifadhiData() async {
    final prefs = await SharedPreferences.getInstance();
    mizigo.sort((a, b) => a.tareheExpiry.compareTo(b.tareheExpiry));
    await prefs.setString('sp_duka_profile', jsonEncode(dukaLaSasa.toJson()));
    await prefs.setString('sp_mizigo_v2', jsonEncode(mizigo.map((e) => e.toJson()).toList()));
    await prefs.setString('sp_miamala', jsonEncode(miamala.map((e) => e.toJson()).toList()));
    await prefs.setString('sp_watumiaji', jsonEncode(watumiaji.map((e) => e.toJson()).toList()));
    syncCloud();
  }

  Future<void> syncCloud() async {
    if (supabaseUrl.contains('YOUR_PROJECT_ID')) return;
    try {
      final expStr = await const FlutterSecureStorage().read(key: 'sp_license_expiry_ms');
      await http.post(
        Uri.parse('$supabaseUrl/rest/v1/duka_backups'),
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $supabaseAnonKey',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: jsonEncode({
          'shop_id': dukaLaSasa.shopId,
          'jina_duka': dukaLaSasa.jinaLaDuka,
          'eneo': dukaLaSasa.eneo,
          'simu': dukaLaSasa.simu,
          'sarafu': dukaLaSasa.sarafu,
          'license_expiry_ms': int.tryParse(expStr ?? '0'),
          'staff_json': watumiaji.map((u) => u.toJson()).toList(),
          'data_json': {
            'mizigo': mizigo.map((e) => e.toJson()).toList(),
            'miamala': miamala.map((e) => e.toJson()).toList(),
          },
          'updated_at': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  String fmt(double v) =>
      '${dukaLaSasa.sarafu} ${v.toStringAsFixed(dukaLaSasa.sarafu == 'TZS' ? 0 : 2)}';

  Future<void> ingizaCSV() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );
      if (res == null || res.files.single.bytes == null) return;
      final content = utf8.decode(res.files.single.bytes!);
      final rows = const CsvToListConverter().convert(content);
      if (rows.length <= 1) return;

      int count = 0;
      setState(() {
        for (int i = 1; i < rows.length; i++) {
          final r = rows[i];
          if (r.length >= 6 && r[0].toString().trim().isNotEmpty) {
            mizigo.add(MzigoDawa(
              id: '${DateTime.now().millisecondsSinceEpoch}_$i',
              jina: r[0].toString().trim(),
              aina: r[1].toString().trim().isEmpty ? 'General' : r[1].toString().trim(),
              beiKununua: double.tryParse(r[2].toString()) ?? 0,
              beiKuuza: double.tryParse(r[3].toString()) ?? 0,
              idadiStoo: int.tryParse(r[4].toString()) ?? 0,
              tareheExpiry: r[5].toString().trim(),
            ));
            count++;
          }
        }
      });
      await hifadhiData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dawa $count zimeingizwa!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void hamishaCSV() {
    final rows = [
      ['Name', 'Type', 'BuyPrice', 'SellPrice', 'Stock', 'Expiry'],
      ...mizigo.map((d) => [d.jina, d.aina, d.beiKununua, d.beiKuuza, d.idadiStoo, d.tareheExpiry])
    ];
    Share.share(
      const ListToCsvConverter().convert(rows),
      subject: 'Stock Backup - ${dukaLaSasa.jinaLaDuka} ($leo)',
    );
  }

  void simamiaWahudumu() {
    final jinaCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Wahudumu wa Duka (Staff)'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Shop ID: ${dukaLaSasa.shopId}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 12),
                  ),
                  const Divider(),
                  ...watumiaji.map(
                    (u) => ListTile(
                      dense: true,
                      title: Text('${u.jina} ${u.niAdmin ? "(Admin)" : ""}'),
                      subtitle: Text(u.anaruhusiwa ? 'Active' : 'Blocked'),
                      trailing: u.niAdmin
                          ? null
                          : Switch(
                              value: u.anaruhusiwa,
                              onChanged: (val) {
                                setDlg(() => u.anaruhusiwa = val);
                                hifadhiData();
                              },
                            ),
                    ),
                  ),
                  const Divider(),
                  TextField(
                    controller: jinaCtrl,
                    decoration: const InputDecoration(labelText: 'Jina la Mhudumu Mpya'),
                  ),
                  TextField(
                    controller: pinCtrl,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'PIN yake (Tarakimu 4)'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (jinaCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
                        setDlg(() => watumiaji.add(Mtumiaji(
                              id: 'STF-${DateTime.now().millisecondsSinceEpoch}',
                              jina: jinaCtrl.text.trim(),
                              pinHash: hashText(pinCtrl.text.trim()),
                              niAdmin: false,
                            )));
                        jinaCtrl.clear();
                        pinCtrl.clear();
                        hifadhiData();
                      }
                    },
                    child: const Text('+ Ongeza Mhudumu'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Funga')),
          ],
        ),
      ),
    );
  }

  void tumaMaoni() {
    final maoniCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tuma Maoni / Tatizo'),
        content: TextField(
          controller: maoniCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Andika maoni yako...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          ElevatedButton(
            onPressed: () async {
              if (maoniCtrl.text.trim().isEmpty) return;
              if (!supabaseUrl.contains('YOUR_PROJECT_ID')) {
                try {
                  await http.post(
                    Uri.parse('$supabaseUrl/rest/v1/maoni_ya_wateja'),
                    headers: {
                      'apikey': supabaseAnonKey,
                      'Authorization': 'Bearer $supabaseAnonKey',
                      'Content-Type': 'application/json',
                    },
                    body: jsonEncode({
                      'shop_id': dukaLaSasa.shopId,
                      'jina_duka': dukaLaSasa.jinaLaDuka,
                      'ujumbe': maoniCtrl.text.trim(),
                    }),
                  );
                } catch (_) {}
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Asante! Maoni yametumwa.'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Tuma'),
          ),
        ],
      ),
    );
  }

  void ongezaAuHaririDawa([MzigoDawa? dawa]) {
    final jinaCtrl = TextEditingController(text: dawa?.jina ?? '');
    final ainaCtrl = TextEditingController(text: dawa?.aina ?? '');
    final nunuaCtrl = TextEditingController(text: dawa != null ? dawa.beiKununua.toString() : '');
    final uzaCtrl = TextEditingController(text: dawa != null ? dawa.beiKuuza.toString() : '');
    final stooCtrl = TextEditingController(text: dawa != null ? dawa.idadiStoo.toString() : '');
    final expCtrl = TextEditingController(text: dawa?.tareheExpiry ?? '2027-12-31');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dawa == null ? 'Ongeza Dawa Mpya' : 'Hariri Dawa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jinaCtrl,
                decoration: const InputDecoration(labelText: 'Jina la Dawa'),
              ),
              TextField(
                controller: ainaCtrl,
                decoration: const InputDecoration(labelText: 'Aina (mf. Vidonge, Syrup)'),
              ),
              TextField(
                controller: nunuaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bei ya Kununua'),
              ),
              TextField(
                controller: uzaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Bei ya Kuuza'),
              ),
              TextField(
                controller: stooCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Idadi iliyopo Stoo'),
              ),
              TextField(
                controller: expCtrl,
                decoration: const InputDecoration(labelText: 'Tarehe ya Expiry (YYYY-MM-DD)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          ElevatedButton(
            onPressed: () {
              if (jinaCtrl.text.trim().isEmpty) return;
              setState(() {
                if (dawa == null) {
                  mizigo.add(MzigoDawa(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    jina: jinaCtrl.text.trim(),
                    aina: ainaCtrl.text.trim().isEmpty ? 'General' : ainaCtrl.text.trim(),
                    beiKununua: double.tryParse(nunuaCtrl.text) ?? 0,
                    beiKuuza: double.tryParse(uzaCtrl.text) ?? 0,
                    idadiStoo: int.tryParse(stooCtrl.text) ?? 0,
                    tareheExpiry: expCtrl.text.trim().isEmpty ? '2099-12-31' : expCtrl.text.trim(),
                  ));
                } else {
                  dawa.jina = jinaCtrl.text.trim();
                  dawa.aina = ainaCtrl.text.trim().isEmpty ? 'General' : ainaCtrl.text.trim();
                  dawa.beiKununua = double.tryParse(nunuaCtrl.text) ?? 0;
                  dawa.beiKuuza = double.tryParse(uzaCtrl.text) ?? 0;
                  dawa.idadiStoo = int.tryParse(stooCtrl.text) ?? 0;
                  dawa.tareheExpiry = expCtrl.text.trim().isEmpty ? '2099-12-31' : expCtrl.text.trim();
                }
              });
              hifadhiData();
              Navigator.pop(ctx);
            },
            child: const Text('Hifadhi'),
          ),
        ],
      ),
    );
  }

  void kamilishaMauzo() {
    if (kikapu.isEmpty) return;
    double jumla = kikapu.fold(0, (s, i) => s + i.jumlaBei);
    double faida = kikapu.fold(0, (s, i) => s + i.jumlaFaida);
    final sasa = DateTime.now();
    final saa = '${sasa.hour.toString().padLeft(2, '0')}:${sasa.minute.toString().padLeft(2, '0')}';
    final maelezo = kikapu.map((k) => '${k.mzigo.jina} x${k.idadi}').join(', ');

    setState(() {
      for (var item in kikapu) {
        item.mzigo.idadiStoo -= item.idadi;
      }
      miamala.insert(
        0,
        Muamala(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tarehe: leo,
          saa: saa,
          maelezo: maelezo,
          jumlaBei: jumla,
          jumlaFaida: faida,
          mhudumu: widget.mtumiajiAliyeingia.jina,
        ),
      );
      kikapu.clear();
    });
    hifadhiData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mauzo yamekamilika: ${fmt(jumla)}'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dawaZilizochujwa = mizigo
        .where((d) =>
            d.jina.toLowerCase().contains(utafutaji.toLowerCase()) ||
            d.aina.toLowerCase().contains(utafutaji.toLowerCase()))
        .toList();

    final mauzoLeo = miamala.where((m) => m.tarehe == leo).fold(0.0, (s, m) => s + m.jumlaBei);
    final faidaLeo = miamala.where((m) => m.tarehe == leo).fold(0.0, (s, m) => s + m.jumlaFaida);
    final mauzoMwezi =
        miamala.where((m) => m.tarehe.startsWith(mweziHuu)).fold(0.0, (s, m) => s + m.jumlaBei);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dukaLaSasa.jinaLaDuka, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              'Mhudumu: ${widget.mtumiajiAliyeingia.jina} • Siku ${widget.sikuZilizobakiZaLeseni}',
              style: const TextStyle(fontSize: 11, color: Colors.tealAccent),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.feedback_outlined), onPressed: tumaMaoni),
          if (widget.mtumiajiAliyeingia.niAdmin)
            IconButton(icon: const Icon(Icons.people), onPressed: simamiaWahudumu),
          IconButton(icon: const Icon(Icons.logout), onPressed: widget.onLogout),
        ],
      ),
      body: IndexedStack(
        index: tabIndex,
        children: [
          // TAB 0: MAUZO (POS)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Tafuta dawa ya kuuza...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => utafutaji = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: dawaZilizochujwa.length,
                  itemBuilder: (_, i) {
                    final d = dawaZilizochujwa[i];
                    return ListTile(
                      title: Text(d.jina, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Bei: ${fmt(d.beiKuuza)} | Stoo: ${d.idadiStoo}'),
                      trailing: ElevatedButton(
                        onPressed: d.idadiStoo <= 0
                            ? null
                            : () {
                                setState(() {
                                  final idx = kikapu.indexWhere((k) => k.mzigo.id == d.id);
                                  if (idx >= 0) {
                                    if (kikapu[idx].idadi < d.idadiStoo) {
                                      kikapu[idx].idadi++;
                                    }
                                  } else {
                                    kikapu.add(KipengeleChaKikapu(mzigo: d, idadi: 1));
                                  }
                                });
                              },
                        child: const Text('+ Kikapu'),
                      ),
                    );
                  },
                ),
              ),
              if (kikapu.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.teal.shade50,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...kikapu.map(
                        (k) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${k.mzigo.jina} x${k.idadi}')),
                            Text(fmt(k.jumlaBei)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (k.idadi > 1) {
                                    k.idadi--;
                                  } else {
                                    kikapu.remove(k);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'JUMLA: ${fmt(kikapu.fold(0, (s, i) => s + i.jumlaBei))}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: kamilishaMauzo,
                            icon: const Icon(Icons.check),
                            label: const Text('Kamilisha Mauzo'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // TAB 1: STOO (INVENTORY)
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => ongezaAuHaririDawa(),
                      icon: const Icon(Icons.add),
                      label: const Text('Ongeza Dawa'),
                    ),
                    OutlinedButton.icon(
                      onPressed: ingizaCSV,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Import CSV'),
                    ),
                    OutlinedButton.icon(
                      onPressed: hamishaCSV,
                      icon: const Icon(Icons.download),
                      label: const Text('Export CSV'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: mizigo.length,
                  itemBuilder: (_, i) {
                    final d = mizigo[i];
                    return ListTile(
                      title: Text(d.jina, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Nunua: ${fmt(d.beiKununua)} | Uza: ${fmt(d.beiKuuza)} | Stoo: ${d.idadiStoo} | Exp: ${d.tareheExpiry}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => ongezaAuHaririDawa(d),
                          ),
                          if (widget.mtumiajiAliyeingia.niAdmin)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => mizigo.removeAt(i));
                                hifadhiData();
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // TAB 2: RIPOTI (REPORTS)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('Mauzo Leo', style: TextStyle(fontSize: 12)),
                              Text(fmt(mauzoLeo), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              const Text('Faida Leo', style: TextStyle(fontSize: 12)),
                              Text(fmt(faidaLeo), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Card(
                  child: ListTile(
                    title: const Text('Jumla ya Mauzo Mwezi Huu'),
                    trailing: Text(
                      fmt(mauzoMwezi),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Miamala ya Hivi Karibuni:', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView.builder(
                    itemCount: miamala.length,
                    itemBuilder: (_, i) {
                      final m = miamala[i];
                      return ListTile(
                        dense: true,
                        title: Text(m.maelezo),
                        subtitle: Text('${m.tarehe} ${m.saa} • Na: ${m.mhudumu}'),
                        trailing: Text(fmt(m.jumlaBei), style: const TextStyle(fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabIndex,
        onTap: (i) => setState(() => tabIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Mauzo'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stoo'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Ripoti'),
        ],
      ),
    );
  }
}
