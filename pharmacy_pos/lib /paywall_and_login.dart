import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class OfflineSmsPaywall extends StatefulWidget {
  final String shopId;
  final VoidCallback onUnlocked;
  const OfflineSmsPaywall({super.key, required this.shopId, required this.onUnlocked});
  @override
  State<OfflineSmsPaywall> createState() => _OfflineSmsPaywallState();
}

class _OfflineSmsPaywallState extends State<OfflineSmsPaywall> {
  final _smsCtrl = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  int kifurushi = 0;
  final List<Map<String, dynamic>> vifurushi = [
    {'jina': 'Starter (Kifaa 1 - Mwezi)', 'kiasi': 2000, 'siku': 30},
    {'jina': 'Pro (Watumishi Wengi - Mwezi)', 'kiasi': 5000, 'siku': 30},
    {'jina': 'Mwaka Mzima (Ofa)', 'kiasi': 20000, 'siku': 365},
  ];

  Future<void> hakikiSmsOffline() async {
    final sms = _smsCtrl.text.trim().toUpperCase();
    final plan = vifurushi[kifurushi];
    final int kiasi = plan['kiasi'];
    if (sms.length < 20) {
      _kosa('Bandika ujumbe kamili wa muamala.');
      return;
    }
    final bool inaJina = sms.contains('MJ14') || sms.contains('SMARTPHARMA') || sms.contains(vodaLipaNamba);
    final bool imethibitishwa = sms.contains('IMETHIBITISHWA') || sms.contains('CONFIRMED');
    final String kiasiComma = kiasi.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m},');
    final bool inaKiasi = sms.contains(kiasiComma) || sms.contains('$kiasi');
    final String? txnId = RegExp(r'\b[A-Z0-9]{9,12}\b').firstMatch(sms)?.group(0);

    if (!inaJina || !imethibitishwa || !inaKiasi || txnId == null) {
      _kosa('Ujumbe si sahihi au kiasi hakilingani.');
      return;
    }

    final String usedStr = await _secureStorage.read(key: 'sp_used_txns') ?? '';
    final List<String> usedList = usedStr.split(',');
    if (usedList.contains(txnId)) {
      _kosa('Muamala huu ($txnId) umeshatumika!');
      return;
    }

    usedList.add(txnId);
    await _secureStorage.write(key: 'sp_used_txns', value: usedList.join(','));
    final newExpiry = DateTime.now().add(Duration(days: plan['siku'])).millisecondsSinceEpoch;
    await _secureStorage.write(key: 'sp_license_expiry_ms', value: newExpiry.toString());
    await _secureStorage.write(key: 'sp_license_plan', value: plan['jina']);
    await _secureStorage.write(key: 'sp_last_seen_ms', value: DateTime.now().millisecondsSinceEpoch.toString());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imefunguliwa! ${plan['jina']}'), backgroundColor: Colors.green));
    widget.onUnlocked();
  }

  void _kosa(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF004D40),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_open, size: 48, color: Color(0xFF00695C)),
                  const Text('SmartPharma — Fungua Offline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text(brandOwner, style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('Shop ID: ${widget.shopId}', style: const TextStyle(color: Colors.teal)),
                  ...List.generate(vifurushi.length, (i) => RadioListTile(value: i, groupValue: kifurushi, onChanged: (val) => setState(() => kifurushi = val!), title: Text('${vifurushi[i]['jina']} — TZS ${vifurushi[i]['kiasi']}'))),
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)), child: const Text('Lipa kwenda Voda Lipa Namba: $vodaLipaNamba ($jinaLaLipaNamba)\nKisha bandika SMS ya muamala hapa chini:', style: TextStyle(fontSize: 12))),
                  const SizedBox(height: 10),
                  TextField(controller: _smsCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Bandika SMS ya muamala hapa...', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  SizedBox(width: double.infinity, height: 48, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), foregroundColor: Colors.white), onPressed: hakikiSmsOffline, child: const Text('Thibitisha SMS na Fungua'))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PinLoginScreen extends StatefulWidget {
  final String kifurushiChaSasa;
  final int sikuZilizobaki;
  final Widget Function(DukaProfile, Mtumiaji, int) onLoginSuccess;
  const PinLoginScreen({super.key, required this.kifurushiChaSasa, required this.sikuZilizobaki, required this.onLoginSuccess});
  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  DukaProfile? duka;
  List<Mtumiaji> watumiaji = [];
  String pinIliyoingizwa = "", ujumbeWaKosa = "";
  int majaribio = 0;
  DateTime? mudaWaKufunguliwa;

  @override
  void initState() {
    super.initState();
    pakia();
  }

  Future<void> pakia() async {
    final prefs = await SharedPreferences.getInstance();
    final dJson = prefs.getString('sp_duka_profile');
    final uJson = prefs.getString('sp_watumiaji');
    if (dJson != null) {
      duka = DukaProfile.fromJson(jsonDecode(dJson));
      AppLang.current = duka!.lugha;
    }
    if (uJson != null) watumiaji = (jsonDecode(uJson) as List).map((u) => Mtumiaji.fromJson(u)).toList();
    setState(() {});
  }

  void bonyeza(String n) {
    if (mudaWaKufunguliwa != null && DateTime.now().isBefore(mudaWaKufunguliwa!)) {
      setState(() => ujumbeWaKosa = "Imefungwa! Subiri sekunde ${mudaWaKufunguliwa!.difference(DateTime.now()).inSeconds}.");
      return;
    }
    if (pinIliyoingizwa.length < 4) {
      setState(() {
        pinIliyoingizwa += n;
        ujumbeWaKosa = "";
      });
      if (pinIliyoingizwa.length == 4) hakiki();
    }
  }

  void hakiki() {
    final inputHash = hashText(pinIliyoingizwa);
    try {
      final mhusika = watumiaji.firstWhere((u) => u.pinHash == inputHash);
      if (!mhusika.anaruhusiwa) {
        setState(() {
          pinIliyoingizwa = "";
          ujumbeWaKosa = "Akaunti imefungiwa na Admin!";
        });
        return;
      }
      majaribio = 0;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => widget.onLoginSuccess(duka!, mhusika, widget.sikuZilizobaki)));
    } catch (_) {
      majaribio++;
      setState(() {
        pinIliyoingizwa = "";
        if (majaribio >= 5) {
          mudaWaKufunguliwa = DateTime.now().add(const Duration(minutes: 2));
          ujumbeWaKosa = "Umekosea mara 5! Subiri dakika 2.";
        } else {
          ujumbeWaKosa = "PIN si sahihi ($majaribio / 5)";
        }
      });
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
              Text(duka?.jinaLaDuka ?? 'SmartPharma POS', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Shop ID: ${duka?.shopId ?? ""} • ${widget.sikuZilizobaki} days left', style: const TextStyle(color: Colors.tealAccent, fontSize: 12)),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 10), width: 16, height: 16, decoration: BoxDecoration(shape: BoxShape.circle, color: i < pinIliyoingizwa.length ? Colors.tealAccent : Colors.white24)))),
              if (ujumbeWaKosa.isNotEmpty) ...[const SizedBox(height: 10), Text(ujumbeWaKosa, style: const TextStyle(color: Colors.redAccent))],
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((n) => ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white), onPressed: () => bonyeza(n), child: Text(n, style: const TextStyle(fontSize: 20)))),
                  const SizedBox(),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white), onPressed: () => bonyeza('0'), child: const Text('0', style: TextStyle(fontSize: 20))),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, foregroundColor: Colors.white), onPressed: () { if (pinIliyoingizwa.isNotEmpty) setState(() => pinIliyoingizwa = pinIliyoingizwa.substring(0, pinIliyoingizwa.length - 1)); }, child: const Icon(Icons.backspace)),
                ],
              ),
              const SizedBox(height: 20),
