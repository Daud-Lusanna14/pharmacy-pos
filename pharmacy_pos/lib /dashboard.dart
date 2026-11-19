import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

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
  String utafutaji = "";

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

    if (dStr != null) mizigo = (jsonDecode(dStr) as List).map((e) => MzigoDawa.fromJson(e)).toList();
    if (mStr != null) miamala = (jsonDecode(mStr) as List).map((e) => Muamala.fromJson(e)).toList();
    if (uStr != null) watumiaji = (jsonDecode(uStr) as List).map((e) => Mtumiaji.fromJson(e)).toList();
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
      final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['csv'], withData: true);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dawa $count zimeingizwa!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV Error: $e'), backgroundColor: Colors.red));
    }
  }

  void hamishaCSV() {
    final rows = [
      ['Name', 'Type', 'BuyPrice', 'SellPrice', 'Stock', 'Expiry'],
      ...mizigo.map((d) => [d.jina, d.aina, d.beiKununua, d.beiKuuza, d.idadiStoo, d.tareheExpiry])
    ];
    Share.share(const ListToCsvConverter().convert(rows), subject: 'Stock Backup - ${dukaLaSasa.jinaLaDuka} ($leo)');
  }

  void simamiaWahudumu() {
    final jinaCtrl = TextEditingController(), pinCtrl = TextEditingController();
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
                  Text('Wape wahudumu Shop ID hii kujiunga: ${dukaLaSasa.shopId}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 12)),
                  const Divider(),
                  ...watumiaji.map((u) => ListTile(
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
                      )),
                  const Divider(),
                  TextField(controller: jinaCtrl, decoration: const InputDecoration(labelText: 'Jina la Mhudumu Mpya')),
                  TextField(controller: pinCtrl, maxLength: 4, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'PIN yake (Tarakimu 4)')),
                  ElevatedButton(
                    onPressed: () {
                      if (jinaCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
                        setDlg(() => watumiaji.add(Mtumiaji(id: 'STF-${DateTime.now().millisecondsSinceEpoch}', jina: jinaCtrl.text.trim(), pinHash: hashText(pinCtrl.text.trim()), niAdmin: false)));
                        jinaCtrl.clear();
                        pinCtrl.clear();
                        hifadhiData();
                      }
                    },
                    child: const Text('+ Ongeza Mhudumu'),
                  )
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
        content: TextField(controller: maoniCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Andika maoni yako kwa Mj14...', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ghairi')),
          ElevatedButton(
            onPressed: () async {
              if (maoniCtrl.text.trim().isEmpty) return;
              if (!supabaseUrl.contains('YOUR_PROJECT_ID')) {
                try {
                  await http.post(
                    Uri.parse('$supabaseUrl/rest/v1/maoni_ya_wateja'),
                    headers: {'apikey': supabaseAnonKey, 'Authorization': 'Bearer $supabaseAnonKey', 'Content-Type': 'application/json'},
                    body: jsonEncode({'shop_id': dukaLaSasa.shopId, 'jina_duka': dukaLaSasa.jinaLaDuka, 'ujumbe': maoniCtrl.text.trim()}),
                  );
                } catch (_) {}
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asante! Maoni yametumwa.'), backgroundColor: Colors.green));
            },
            child: const Text('Tuma'),
          ),
        ],
      ),
    );
  }

  void kamilishaMauzo() {
    double jumla = kikapu.fold(0, (s, i) => s + i.jumlaBei), faida = kikapu.fold(0, (s, i) => s + i.jumlaFaida);
    final sasa = DateTime.now();
    final saa = "${sasa.hour.toString().padLeft(2, '0')}:${sasa.minute.toString().padLeft(2, '0')}";
    final maelezo = kikapu.map((k) => '${k.mzigo.jina} x${k.idadi}').join(', ');

    setState(() {
      for (var item in kikapu) {
        item.mzigo.idadiStoo -= item.idadi;
      }
