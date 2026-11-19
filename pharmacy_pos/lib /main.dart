import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ============================================================================
// 1. SUPABASE CONFIGURATION & HELPERS
// ============================================================================
const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
String hashText(String text) {
 final bytes = utf8.encode(text);
 return sha256.convert(bytes).toString();
}
// ============================================================================
// 2. DATA MODELS
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
 factory DukaProfile.fromJson(Map<String, dynamic> j) => DukaProfile(
 shopId: j['shopId'] ?? '',
 jinaLaDuka: j['jinaLaDuka'] ?? 'SmartPharma POS',
 eneo: j['eneo'] ?? '',
 simu: j['simu'] ?? '',
 sarafu: j['sarafu'] ?? 'TZS',
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
 factory Mtumiaji.fromJson(Map<String, dynamic> j) => Mtumiaji(
 id: j['id'] ?? '',
 jina: j['jina'] ?? '',
 pinHash: j['pinHash'] ?? '',
 niAdmin: j['niAdmin'] ?? false,
 anaruhusiwa: j['anaruhusiwa'] ?? true,
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
 factory MzigoDawa.fromJson(Map<String, dynamic> j) => MzigoDawa(
 id: j['id'] ?? '',
 jina: j['jina'] ?? '',
 aina: j['aina'] ?? 'General',
 beiKununua: (j['beiKununua'] ?? 0).toDouble(),
 beiKuuza: (j['beiKuuza'] ?? 0).toDouble(),
 idadiStoo: (j['idadiStoo'] ?? 0).toInt(),
 tareheExpiry: j['tareheExpiry'] ?? '2099-12-31',
 );
}
class KipengeleChaKikapu {
 MzigoDawa mzigo;
 int idadi;
 KipengeleChaKikapu({required this.mzigo, this.idadi = 1});
 double get jumlaBei => mzigo.beiKuuza * idadi;
 double get jumlaFaida => (mzigo.beiKuuza - mzigo.beiKununua) * idadi;
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
 factory Muamala.fromJson(Map<String, dynamic> j) => Muamala(
 id: j['id'] ?? '',
 tarehe: j['tarehe'] ?? '',
 saa: j['saa'] ?? '',
 maelezo: j['maelezo'] ?? '',
 jumlaBei: (j['jumlaBei'] ?? 0).toDouble(),
 jumlaFaida: (j['jumlaFaida'] ?? 0).toDouble(),
 mhudumu: j['mhudumu'] ?? '',
 );
}
// ============================================================================
// 3. APP ENTRY POINT & GATEKEEPER
// ============================================================================
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
 theme: ThemeData(
 colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00897B)),
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
 DukaProfile? duka;
 List<Mtumiaji> watumiaji = [];
 Mtumiaji? mtumiajiAliyeingia;
 int sikuZilizobaki = 30;
 @override
 void initState() {
 super.initState();
 kaguaHaliYaDuka();
 }
 Future<void> kaguaHaliYaDuka() async {
 final prefs = await SharedPreferences.getInstance();
 final dStr = prefs.getString('sp_duka_profile');
 final uStr = prefs.getString('sp_watumiaji');
 String? expStr = await storage.read(key: 'sp_license_expiry_ms');
 int expMs;
 if (expStr == null) {
 expMs = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
 await storage.write(key: 'sp_license_expiry_ms', value: expMs.toString());
 } else {
 expMs = int.tryParse(expStr) ?? 0;
 }
 final diff = DateTime.fromMillisecondsSinceEpoch(expMs).difference(DateTime.now()).inDays;
 sikuZilizobaki = diff < 0 ? 0 : diff;
 if (dStr != null) {
 duka = DukaProfile.fromJson(jsonDecode(dStr));
 }
 if (uStr != null) {
 watumiaji = (jsonDecode(uStr) as List).map((e) => Mtumiaji.fromJson(e)).toList();
 }
 setState(() => inapakia = false);
 }
 Future<void> hifadhiUsajili(DukaProfile dukaJipya, Mtumiaji adminMpya) async {
 final prefs = await SharedPreferences.getInstance();
 await prefs.setString('sp_duka_profile', jsonEncode(dukaJipya.toJson()));
 await prefs.setString('sp_watumiaji', jsonEncode([adminMpya.toJson()]));
 setState(() {
 duka = dukaJipya;
 watumiaji = [adminMpya];
 mtumiajiAliyeingia = adminMpya;
 });
 }
 Future<void> wekaLeseniMpya(int sikuZaKuongeza) async {
 final expMs = DateTime.now().add(Duration(days: sikuZaKuongeza)).millisecondsSinceEpoch;
 await storage.write(key: 'sp_license_expiry_ms', value: expMs.toString());
 setState(() => sikuZilizobaki = sikuZaKuongeza);
 }
 @override
 Widget build(BuildContext context) {
 if (inapakia) {
 return const Scaffold(body: Center(child: CircularProgressIndicator()));
 }
 if (sikuZilizobaki <= 0) {
 return PaywallScreen(onActivate: wekaLeseniMpya);
 }
 if (duka == null || watumiaji.isEmpty) {
 return SetupShopScreen(onComplete: hifadhiUsajili);
 }
 if (mtumiajiAliyeingia == null) {
 return PinLoginScreen(
 duka: duka!,
 watumiaji: watumiaji,
 sikuZilizobaki: sikuZilizobaki,
 onLoginSuccess: (u) => setState(() => mtumiajiAliyeingia = u),
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
// 4. PAYWALL, SHOP SETUP & PIN LOGIN SCREENS
// ============================================================================
class PaywallScreen extends StatefulWidget {
 final Future<void> Function(int days) onActivate;
 const PaywallScreen({super.key, required this.onActivate});
 @override
 State<PaywallScreen> createState() => _PaywallScreenState();
}
class _PaywallScreenState extends State<PaywallScreen> {
 final codeCtrl = TextEditingController();
 String kosa = '';
 void thibitishaKodi() {
 final code = codeCtrl.text.trim().toUpperCase();
 if (code == 'SP-30DAYS') {
 widget.onActivate(30);
 } else if (code == 'SP-365DAYS') {
 widget.onActivate(365);
 } else {
 setState(() => kosa = 'Kodi ya leseni si sahihi. Wasiliana na Mj14.');
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
 child: Card(
 child: Padding(
 padding: const EdgeInsets.all(20),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 const Icon(Icons.lock_clock, size: 52, color: Colors.red),
 const SizedBox(height: 12),
 const Text('Muda wa Leseni Umeisha', style: TextStyle(fontSize: 18, fontWeight:
FontWeight.bold)),
 const SizedBox(height: 8),
 const Text('Weka kodi ya malipo ili kuendelea kutumia SmartPharma POS.', textAlign:
TextAlign.center, style: TextStyle(fontSize: 13)),
 const SizedBox(height: 16),
 TextField(
 controller: codeCtrl,
 decoration: const InputDecoration(labelText: 'License Code', border:
OutlineInputBorder()),
 ),
 if (kosa.isNotEmpty) ...[
 const SizedBox(height: 8),
 Text(kosa, style: const TextStyle(color: Colors.red, fontSize: 12)),
 ],
 const SizedBox(height: 16),
 SizedBox(
 width: double.infinity,
 child: ElevatedButton(
 onPressed: thibitishaKodi,
 child: const Text('Washa Leseni'),
 ),
 ),
 ],
 ),
 ),
 ),
 ),
 ),
 );
 }
}
class SetupShopScreen extends StatefulWidget {
 final Future<void> Function(DukaProfile, Mtumiaji) onComplete;
 const SetupShopScreen({super.key, required this.onComplete});
 @override
 State<SetupShopScreen> createState() => _SetupShopScreenState();
}
class _SetupShopScreenState extends State<SetupShopScreen> {
 final dukaCtrl = TextEditingController();
 final eneoCtrl = TextEditingController();
 final simuCtrl = TextEditingController();
 final adminCtrl = TextEditingController();
 final pinCtrl = TextEditingController();
 String sarafu = 'TZS';
 void sajili() {
 if (dukaCtrl.text.trim().isEmpty || adminCtrl.text.trim().isEmpty || pinCtrl.text.trim().length != 4) {
 ScaffoldMessenger.of(context).showSnackBar(
 const SnackBar(content: Text('Jaza jina la duka, admin, na PIN ya tarakimu 4.')),
 );
 return;
 }
 final shopId = 'SHP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
 final duka = DukaProfile(
 shopId: shopId,
 jinaLaDuka: dukaCtrl.text.trim(),
 eneo: eneoCtrl.text.trim(),
 simu: simuCtrl.text.trim(),
 sarafu: sarafu,
 );
 final admin = Mtumiaji(
 id: 'ADM-${DateTime.now().millisecondsSinceEpoch}',
 jina: adminCtrl.text.trim(),
 pinHash: hashText(pinCtrl.text.trim()),
 niAdmin: true,
 );
 widget.onComplete(duka, admin);
 }
 @override
 Widget build(BuildContext context) {
 return Scaffold(
 appBar: AppBar(title: const Text('Sajili Duka Jipya')),
 body: Center(
 child: Container(
 constraints: const BoxConstraints(maxWidth: 420),
 padding: const EdgeInsets.all(20),
 child: SingleChildScrollView(
 child: Column(
 children: [
 TextField(controller: dukaCtrl, decoration: const InputDecoration(labelText: 'Jina la Duka /
Pharmacy *', border: OutlineInputBorder())),
 const SizedBox(height: 12),
 TextField(controller: eneoCtrl, decoration: const InputDecoration(labelText: 'Eneo / Mtaa',
border: OutlineInputBorder())),
 const SizedBox(height: 12),
 TextField(controller: simuCtrl, keyboardType: TextInputType.phone, decoration: const
InputDecoration(labelText: 'Namba ya Simu', border: OutlineInputBorder())),
 const SizedBox(height: 12),
 DropdownButtonFormField<String>(
 value: sarafu,
 decoration: const InputDecoration(labelText: 'Sarafu (Currency)', border:
OutlineInputBorder()),
 items: ['TZS', 'KES', 'UGX', 'USD'].map((s) => DropdownMenuItem(value: s, child:
Text(s))).toList(),
 onChanged: (v) => setState(() => sarafu = v ?? 'TZS'),
 ),
 const Divider(height: 28),
 TextField(controller: adminCtrl, decoration: const InputDecoration(labelText: 'Jina la
Mmiliki / Admin *', border: OutlineInputBorder())),
 const SizedBox(height: 12),
 TextField(controller: pinCtrl, maxLength: 4, keyboardType: TextInputType.number, obscureText:
true, decoration: const InputDecoration(labelText: 'PIN ya Admin (Tarakimu 4) *', border:
OutlineInputBorder())),
 const SizedBox(height: 16),
 SizedBox(
 width: double.infinity,
 height: 48,
 child: ElevatedButton(
 onPressed: sajili,
 child: const Text('Kamilisha Usajili'),
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
class PinLoginScreen extends StatefulWidget {
 final DukaProfile duka;
 final List<Mtumiaji> watumiaji;
 final int sikuZilizobaki;
 final void Function(Mtumiaji) onLoginSuccess;
 const PinLoginScreen({
 super.key,
 required this.duka,
 required this.watumiaji,
 required this.sikuZilizobaki,
 required this.onLoginSuccess,
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
 final h = hashText(pinIliyoingizwa);
 final found = widget.watumiaji.where((u) => u.pinHash == h && u.anaruhusiwa).toList();
 if (found.isNotEmpty) {
 widget.onLoginSuccess(found.first);
 } else {
 setState(() {
 ujumbeWaKosa = 'PIN si sahihi au akaunti imezuiwa!';
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
 Text(widget.duka.jinaLaDuka, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
color: Colors.white)),
 Text('Shop ID: ${widget.duka.shopId} • ${widget.sikuZilizobaki} days left', style: const
TextStyle(color: Colors.tealAccent, fontSize: 12)),
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
 style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor:
Colors.white),
 onPressed: () => bonyeza(n),
 child: Text(n, style: const TextStyle(fontSize: 20)),
 ),
 ),
 const SizedBox(),
 ElevatedButton(
 style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor:
Colors.white),
 onPressed: () => bonyeza('0'),
 child: const Text('0', style: TextStyle(fontSize: 20)),
 ),
 ElevatedButton(
 style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor:
Colors.white),
 onPressed: () {
 if (pinIliyoingizwa.isNotEmpty) {
 setState(() => pinIliyoingizwa = pinIliyoingizwa.substring(0, pinIliyoingizwa.length
- 1));
 }
 },
 child: const Icon(Icons.backspace),
 ),
 ],
 ),
 const SizedBox(height: 20),
 ],
 ),
 ),
 ),
 );
 }
}
// ============================================================================
// 5. MAIN DASHBOARD (POS, STOO, RIPOTI)
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
 String fmt(double v) => '${dukaLaSasa.sarafu} ${v.toStringAsFixed(dukaLaSasa.sarafu == 'TZS' ? 0 : 2)}';
 Future<void> ingizaCSV() async {
 try {
 final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'],
withData: true);
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
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dawa $count zimeingizwa!'),
backgroundColor: Colors.green));
 } catch (e) {
 if (!mounted) return;
 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV Error: $e'), backgroundColor:
Colors.red));
 }
 }
 void hamishaCSV() {
 final rows = [
 ['Name', 'Type', 'BuyPrice', 'SellPrice', 'Stock', 'Expiry'],
 ...mizigo.map((d) => [d.jina, d.aina, d.beiKununua, d.beiKuuza, d.idadiStoo, d.tareheExpiry])
 ];
 Share.share(const ListToCsvConverter().convert(rows), subject: 'Stock Backup - ${dukaLaSasa.jinaLaDuka}
($leo)');
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
 Text('Wape wahudumu Shop ID hii kujiunga: ${dukaLaSasa.shopId}', style: const
TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 12)),
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
 TextField(controller: jinaCtrl, decoration: const InputDecoration(labelText: 'Jina la
Mhudumu Mpya')),
 TextField(controller: pinCtrl, maxLength: 4, keyboardType: TextInputType.number,
decoration: const InputDecoration(labelText: 'PIN yake (Tarakimu 4)')),
 ElevatedButton(
 onPressed: () {
 if (jinaCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
 setDlg(() {
 watumiaji.add(Mtumiaji(
 id: 'STF-${DateTime.now().millisecondsSinceEpoch}',
 jina: jinaCtrl.text.trim(),
 pinHash: hashText(pinCtrl.text.trim()),
 niAdmin: false,
 ));
 });
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
 actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Funga'))],
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
 decoration: const InputDecoration(hintText: 'Andika maoni yako kwa Mj14...', border:
OutlineInputBorder()),
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
 final ainaCtrl = TextEditingController(text: dawa?.aina ?? 'General');
 final kununuaCtrl = TextEditingController(text: dawa != null ? dawa.beiKununua.toString() : '');
 final kuuzaCtrl = TextEditingController(text: dawa != null ? dawa.beiKuuza.toString() : '');
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
 TextField(controller: jinaCtrl, decoration: const InputDecoration(labelText: 'Jina la Dawa
*')),
 TextField(controller: ainaCtrl, decoration: const InputDecoration(labelText: 'Aina (mf.
Vidonge, Syrup)')),
 TextField(controller: kununuaCtrl, keyboardType: TextInputType.number, decoration: const
InputDecoration(labelText: 'Bei ya Kununua')),
 TextField(controller: kuuzaCtrl, keyboardType: TextInputType.number, decoration: const
InputDecoration(labelText: 'Bei ya Kuuza *')),
 TextField(controller: stooCtrl, keyboardType: TextInputType.number, decoration: const
InputDecoration(labelText: 'Idadi Stoo *')),
 TextField(controller: expCtrl, decoration: const InputDecoration(labelText: 'Tarehe ya Expiry
(YYYY-MM-DD)')),
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
 id: 'MED-${DateTime.now().millisecondsSinceEpoch}',
 jina: jinaCtrl.text.trim(),
 aina: ainaCtrl.text.trim().isEmpty ? 'General' : ainaCtrl.text.trim(),
 beiKununua: double.tryParse(kununuaCtrl.text) ?? 0,
 beiKuuza: double.tryParse(kuuzaCtrl.text) ?? 0,
 idadiStoo: int.tryParse(stooCtrl.text) ?? 0,
 tareheExpiry: expCtrl.text.trim().isEmpty ? '2099-12-31' : expCtrl.text.trim(),
 ));
 } else {
 dawa.jina = jinaCtrl.text.trim();
 dawa.aina = ainaCtrl.text.trim();
 dawa.beiKununua = double.tryParse(kununuaCtrl.text) ?? 0;
 dawa.beiKuuza = double.tryParse(kuuzaCtrl.text) ?? 0;
 dawa.idadiStoo = int.tryParse(stooCtrl.text) ?? 0;
 dawa.tareheExpiry = expCtrl.text.trim();
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
 void wekaKwenyeKikapu(MzigoDawa d) {
 if (d.idadiStoo <= 0) {
 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dawa hii imeisha stoo!'),
backgroundColor: Colors.red));
 return;
 }
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
 }
 void kamilishaMauzo() {
 if (kikapu.isEmpty) return;
 final double jumla = kikapu.fold(0, (s, i) => s + i.jumlaBei);
 final double faida = kikapu.fold(0, (s, i) => s + i.jumlaFaida);
 final sasa = DateTime.now();
 final saa = "${sasa.hour.toString().padLeft(2, '0')}:${sasa.minute.toString().padLeft(2, '0')}";
 final maelezo = kikapu.map((k) => '${k.mzigo.jina} x${k.idadi}').join(', ');
 setState(() {
 for (var item in kikapu) {
 item.mzigo.idadiStoo -= item.idadi;
 }
 miamala.insert(
 0,
 Muamala(
 id: 'TX-${sasa.millisecondsSinceEpoch}',
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
 SnackBar(content: Text('Mauzo ya ${fmt(jumla)} yamekamilika!'), backgroundColor: Colors.green),
 );
 }
 @override
 Widget build(BuildContext context) {
 final dawaZilizochujwa = mizigo.where((d) =>
d.jina.toLowerCase().contains(utafutaji.toLowerCase())).toList();
 final jumlaKikapu = kikapu.fold<double>(0, (s, i) => s + i.jumlaBei);
 final mauzoLeo = miamala.where((m) => m.tarehe == leo).fold<double>(0, (s, m) => s + m.jumlaBei);
 final faidaLeo = miamala.where((m) => m.tarehe == leo).fold<double>(0, (s, m) => s + m.jumlaFaida);
 return Scaffold(
 appBar: AppBar(
 backgroundColor: const Color(0xFF004D40),
 foregroundColor: Colors.white,
 title: Column(
 crossAxisAlignment: CrossAxisAlignment.start,
 children: [
 Text(dukaLaSasa.jinaLaDuka, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
 Text('${widget.mtumiajiAliyeingia.jina} • Leseni: siku ${widget.sikuZilizobakiZaLeseni}', style:
const TextStyle(fontSize: 11, color: Colors.tealAccent)),
 ],
 ),
 actions: [
 if (widget.mtumiajiAliyeingia.niAdmin)
 IconButton(icon: const Icon(Icons.people), tooltip: 'Wahudumu', onPressed: simamiaWahudumu),
 IconButton(icon: const Icon(Icons.feedback_outlined), tooltip: 'Maoni', onPressed: tumaMaoni),
 IconButton(icon: const Icon(Icons.logout), tooltip: 'Toka', onPressed: widget.onLogout),
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
 onChanged: (v) => setState(() => utafutaji = v),
 decoration: const InputDecoration(
 hintText: 'Tafuta dawa ya kuuza...',
 prefixIcon: Icon(Icons.search),
 border: OutlineInputBorder(),
 isDense: true,
 ),
 ),
 ),
 Expanded(
 child: dawaZilizochujwa.isEmpty
 ? const Center(child: Text('Hakuna dawa stoo. Nenda tab ya Stoo uongeze.'))
 : ListView.builder(
 itemCount: dawaZilizochujwa.length,
 itemBuilder: (_, i) {
 final d = dawaZilizochujwa[i];
 return ListTile(
 title: Text(d.jina, style: const TextStyle(fontWeight: FontWeight.bold)),
 subtitle: Text('Stoo: ${d.idadiStoo} • Exp: ${d.tareheExpiry}'),
 trailing: ElevatedButton(
 onPressed: d.idadiStoo > 0 ? () => wekaKwenyeKikapu(d) : null,
 child: Text(fmt(d.beiKuuza)),
 ),
 );
 },
 ),
 ),
 if (kikapu.isNotEmpty)
 Container(
 color: Colors.teal.shade50,
 padding: const EdgeInsets.all(12),
 child: Column(
 mainAxisSize: MainAxisSize.min,
 children: [
 SizedBox(
 height: 110,
 child: ListView.builder(
 itemCount: kikapu.length,
 itemBuilder: (_, i) {
 final k = kikapu[i];
 return Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Expanded(child: Text('${k.mzigo.jina} (x${k.idadi})', overflow:
TextOverflow.ellipsis)),
 Row(
 children: [
 IconButton(
 icon: const Icon(Icons.remove_circle_outline, size: 20),
 onPressed: () => setState(() {
 if (k.idadi > 1) {
 k.idadi--;
 } else {
 kikapu.removeAt(i);
 }
 }),
 ),
 IconButton(
 icon: const Icon(Icons.add_circle_outline, size: 20),
 onPressed: () {
 if (k.idadi < k.mzigo.idadiStoo) setState(() => k.idadi++);
 },
 ),
 Text(fmt(k.jumlaBei), style: const TextStyle(fontWeight:
FontWeight.bold)),
 ],
 ),
 ],
 );
 },
 ),
 ),
 const Divider(),
 Row(
 mainAxisAlignment: MainAxisAlignment.spaceBetween,
 children: [
 Text('JUMLA: ${fmt(jumlaKikapu)}', style: const TextStyle(fontSize: 16, fontWeight:
FontWeight.bold)),
 ElevatedButton.icon(
 style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor:
Colors.white),
 onPressed: kamilishaMauzo,
 icon: const Icon(Icons.check_circle),
 label: const Text('UZA SASA'),
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
 child: Row(
 children: [
 ElevatedButton.icon(onPressed: () => ongezaAuHaririDawa(), icon: const Icon(Icons.add),
label: const Text('Ongeza')),
 const SizedBox(width: 8),
 OutlinedButton.icon(onPressed: ingizaCSV, icon: const Icon(Icons.upload_file), label:
const Text('CSV')),
 const SizedBox(width: 8),
 OutlinedButton.icon(onPressed: hamishaCSV, icon: const Icon(Icons.share), label: const
Text('Backup')),
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
 subtitle: Text('Nunua: ${fmt(d.beiKununua)} | Uza: ${fmt(d.beiKuuza)} | Stoo: ${d.idadiStoo} | Exp: ${d.tareheExpiry}'),
 trailing: Row(
 mainAxisSize: MainAxisSize.min,
 children: [
 IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () =>
ongezaAuHaririDawa(d)),
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
 padding: const EdgeInsets.all(14),
 child: Column(
 children: [
 const Text('Mauzo ya Leo', style: TextStyle(fontSize: 12)),
 const SizedBox(height: 4),
 Text(fmt(mauzoLeo), style: const TextStyle(fontSize: 16, fontWeight:
FontWeight.bold, color: Colors.teal)),
 ],
 ),
 ),
 ),
 ),
 Expanded(
 child: Card(
 color: Colors.green.shade50,
 child: Padding(
 padding: const EdgeInsets.all(14),
 child: Column(
 children: [
 const Text('Faida ya Leo', style: TextStyle(fontSize: 12)),
 const SizedBox(height: 4),
 Text(fmt(faidaLeo), style: const TextStyle(fontSize: 16, fontWeight:
FontWeight.bold, color: Colors.green)),
 ],
 ),
 ),
 ),
 ),
 ],
 ),
 const SizedBox(height: 10),
 const Align(alignment: Alignment.centerLeft, child: Text('Historia ya Miamala', style:
TextStyle(fontWeight: FontWeight.bold))),
 const Divider(),
 Expanded(
 child: miamala.isEmpty
 ? const Center(child: Text('Hakuna mauzo yaliyofanyika bado.'))
 : ListView.builder(
 itemCount: miamala.length,
 itemBuilder: (_, i) {
 final m = miamala[i];
 return ListTile(
 dense: true,
 title: Text(m.maelezo),
 subtitle: Text('${m.tarehe} ${m.saa} • Na: ${m.mhudumu}'),
 trailing: Text(fmt(m.jumlaBei), style: const TextStyle(fontWeight:
FontWeight.bold)),
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
 onTap: (idx) => setState(() => tabIndex = idx),
 items: const [
 BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Mauzo'),
 BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stoo'),
 BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Ripoti'),
 ],
 ),
 );
 }
}
