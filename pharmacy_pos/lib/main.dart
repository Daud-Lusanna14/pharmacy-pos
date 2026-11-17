import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        useMaterial3: true,
      ),
      home: const PinLoginScreen(),
    );
  }
}

class Mtumiaji {
  String jina;
  String pin;
  bool niAdmin;

  Mtumiaji({required this.jina, required this.pin, required this.niAdmin});

  Map<String, dynamic> toJson() => {'jina': jina, 'pin': pin, 'niAdmin': niAdmin};
  factory Mtumiaji.fromJson(Map<String, dynamic> json) =>
      Mtumiaji(jina: json['jina'], pin: json['pin'], niAdmin: json['niAdmin']);
}

class MzigoDawa {
  String jina;
  String aina;
  double beiKununua;
  double beiKuuza;
  int idadiStoo;
  String tareheExpiry;

  MzigoDawa({
    required this.jina,
    required this.aina,
    required this.beiKununua,
    required this.beiKuuza,
    required this.idadiStoo,
    required this.tareheExpiry,
  });

  int get sikuZilizobaki {
    try {
      final expDate = DateTime.parse(tareheExpiry);
      final leo = DateTime.now();
      return expDate.difference(DateTime(leo.year, leo.month, leo.day)).inDays;
    } catch (e) {
      return 999;
    }
  }

  bool get imeExpire => sikuZilizobaki <= 0;
  bool get inakaribiaKuExpire => sikuZilizobaki > 0 && sikuZilizobaki <= 90;

  Map<String, dynamic> toJson() => {
        'jina': jina,
        'aina': aina,
        'beiKununua': beiKununua,
        'beiKuuza': beiKuuza,
        'idadiStoo': idadiStoo,
        'tareheExpiry': tareheExpiry,
      };

  factory MzigoDawa.fromJson(Map<String, dynamic> json) => MzigoDawa(
        jina: json['jina'],
        aina: json['aina'],
        beiKununua: (json['beiKununua'] as num).toDouble(),
        beiKuuza: (json['beiKuuza'] as num).toDouble(),
        idadiStoo: json['idadiStoo'],
        tareheExpiry: json['tareheExpiry'],
      );
}

class Muamala {
  String jinaDawa;
  int idadi;
  double jumlaMauzo;
  double jumlaFaida;
  String mhudumu;
  String tarehe;
  String mwezi;
  String mwaka;
  String saa;

  Muamala({
    required this.jinaDawa,
    required this.idadi,
    required this.jumlaMauzo,
    required this.jumlaFaida,
    required this.mhudumu,
    required this.tarehe,
    required this.mwezi,
    required this.mwaka,
    required this.saa,
  });

  Map<String, dynamic> toJson() => {
        'jinaDawa': jinaDawa,
        'idadi': idadi,
        'jumlaMauzo': jumlaMauzo,
        'jumlaFaida': jumlaFaida,
        'mhudumu': mhudumu,
        'tarehe': tarehe,
        'mwezi': mwezi,
        'mwaka': mwaka,
        'saa': saa,
      };

  factory Muamala.fromJson(Map<String, dynamic> json) => Muamala(
        jinaDawa: json['jinaDawa'],
        idadi: json['idadi'],
        jumlaMauzo: (json['jumlaMauzo'] as num).toDouble(),
        jumlaFaida: (json['jumlaFaida'] as num).toDouble(),
        mhudumu: json['mhudumu'],
        tarehe: json['tarehe'],
        mwezi: json['mwezi'],
        mwaka: json['mwaka'],
        saa: json['saa'],
      );
}

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({super.key});

  @override
  State<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  List<Mtumiaji> watumiaji = [];
  String pinIliyoingizwa = "";
  String ujumbeWaKosa = "";

  @override
  void initState() {
    super.initState();
    pakiaWatumiaji();
  }

  Future<void> pakiaWatumiaji() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString('sp_watumiaji');
    if (usersJson != null) {
      final List<dynamic> decoded = jsonDecode(usersJson);
      setState(() {
        watumiaji = decoded.map((u) => Mtumiaji.fromJson(u)).toList();
      });
    } else {
      watumiaji = [
        Mtumiaji(jina: 'Admin (Mmiliki)', pin: '1234', niAdmin: true),
      ];
      await prefs.setString('sp_watumiaji', jsonEncode(watumiaji.map((u) => u.toJson()).toList()));
      setState(() {});
    }
  }

  void bonyezaNamba(String namba) {
    if (pinIliyoingizwa.length < 4) {
      setState(() {
        pinIliyoingizwa += namba;
        ujumbeWaKosa = "";
      });
      if (pinIliyoingizwa.length == 4) {
        hakikiPin();
      }
    }
  }

  void futaNamba() {
    if (pinIliyoingizwa.isNotEmpty) {
      setState(() {
        pinIliyoingizwa = pinIliyoingizwa.substring(0, pinIliyoingizwa.length - 1);
      });
    }
  }

  void hakikiPin() {
    try {
      final mhusika = watumiaji.firstWhere((u) => u.pin == pinIliyoingizwa);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SmartPharmaDashboard(mtumiajiAliyeingia: mhusika),
        ),
      );
    } catch (e) {
      setState(() {
        ujumbeWaKosa = "PIN si sahihi! Jaribu tena.";
        pinIliyoingizwa = "";
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
              const Icon(Icons.local_pharmacy, size: 64, color: Colors.white),
              const SizedBox(height: 12),
              const Text('SmartPharma', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('Ingiza PIN yako ya tarakimu 4 kuingia', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              const Text('(PIN ya Admin ya mwanzo: 1234)', style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  bool imejazwa = index < pinIliyoingizwa.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: imejazwa ? Colors.tealAccent : Colors.white24,
                    ),
                  );
                }),
              ),
              if (ujumbeWaKosa.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(ujumbeWaKosa, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
              const SizedBox(height: 28),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((n) => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white12,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => bonyezaNamba(n),
                        child: Text(n, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      )),
                  const SizedBox(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white12,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => bonyezaNamba('0'),
                    child: const Text('0', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade900,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: futaNamba,
                    child: const Icon(Icons.backspace),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class SmartPharmaDashboard extends StatefulWidget {
  final Mtumiaji mtumiajiAliyeingia;
  const SmartPharmaDashboard({super.key, required this.mtumiajiAliyeingia});

  @override
  State<SmartPharmaDashboard> createState() => _SmartPharmaDashboardState();
}

class _SmartPharmaDashboardState extends State<SmartPharmaDashboard> {
  int kichupoKilichochaguliwa = 0;
  List<MzigoDawa> mizigoYaDawa = [];
  List<Muamala> miamalaYote = [];
  List<Mtumiaji> watumiajiWote = [];
  String utafutaji = "";

  String tareheYaLeo = "";
  String mweziWaSasa = "";
  String mwakaWaSasa = "";

  @override
  void initState() {
    super.initState();
    wekaTareheZaSasa();
    pakiaDataZote();
  }

  void wekaTareheZaSasa() {
    final sasa = DateTime.now();
    String mweziPadded = sasa.month.toString().padLeft(2, '0');
    String sikuPadded = sasa.day.toString().padLeft(2, '0');
    tareheYaLeo = "${sasa.year}-$mweziPadded-$sikuPadded";
    mweziWaSasa = "${sasa.year}-$mweziPadded";
    mwakaWaSasa = "${sasa.year}";
  }

  Future<void> pakiaDataZote() async {
    final prefs = await SharedPreferences.getInstance();

    final String? dawaJson = prefs.getString('sp_mizigo_v2');
    if (dawaJson != null) {
      mizigoYaDawa = (jsonDecode(dawaJson) as List).map((d) => MzigoDawa.fromJson(d)).toList();
    } else {
      mizigoYaDawa = [
        MzigoDawa(jina: 'Paracetamol 500mg', aina: 'Tablets', beiKununua: 100, beiKuuza: 200, idadiStoo: 50, tareheExpiry: '2027-06-30'),
        MzigoDawa(jina: 'Amoxicillin 500mg', aina: 'Capsules', beiKununua: 150, beiKuuza: 300, idadiStoo: 100, tareheExpiry: '2026-12-20'),
        MzigoDawa(jina: 'Ciprofloxacin 500mg', aina: 'Tablets', beiKununua: 200, beiKuuza: 400, idadiStoo: 30, tareheExpiry: '2026-10-01'),
      ];
    }

    final String? miamalaJson = prefs.getString('sp_miamala');
    if (miamalaJson != null) {
      miamalaYote = (jsonDecode(miamalaJson) as List).map((m) => Muamala.fromJson(m)).toList();
    }

    final String? usersJson = prefs.getString('sp_watumiaji');
    if (usersJson != null) {
      watumiajiWote = (jsonDecode(usersJson) as List).map((u) => Mtumiaji.fromJson(u)).toList();
    }

    await hifadhiDataZote();
    setState(() {});
  }

  Future<void> hifadhiDataZote() async {
    final prefs = await SharedPreferences.getInstance();
    mizigoYaDawa.sort((a, b) => a.tareheExpiry.compareTo(b.tareheExpiry));
    await prefs.setString('sp_mizigo_v2', jsonEncode(mizigoYaDawa.map((d) => d.toJson()).toList()));
    await prefs.setString('sp_miamala', jsonEncode(miamalaYote.map((m) => m.toJson()).toList()));
    await prefs.setString('sp_watumiaji', jsonEncode(watumiajiWote.map((u) => u.toJson()).toList()));
  }

  double get mauzoYaLeo => miamalaYote.where((m) => m.tarehe == tareheYaLeo).fold(0, (s, i) => s + i.jumlaMauzo);
  double get faidaYaLeo => miamalaYote.where((m) => m.tarehe == tareheYaLeo).fold(0, (s, i) => s + i.jumlaFaida);
  double get mauzoYaMweziHuu => miamalaYote.where((m) => m.mwezi == mweziWaSasa).fold(0, (s, i) => s + i.jumlaMauzo);
  double get faidaYaMweziHuu => miamalaYote.where((m) => m.mwezi == mweziWaSasa).fold(0, (s, i) => s + i.jumlaFaida);

  void dirishaLaKuuza(MzigoDawa mzigo) {
    if (mzigo.imeExpire) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IMEZUIWA: Dawa hii imesha-EXPIRE! Hairuhusiwi kuuzwa.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mzigo.idadiStoo <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dawa hii imeisha stoo!'), backgroundColor: Colors.red),
      );
      return;
    }

    final idadiCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Toa Dawa: ${mzigo.jina}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bei ya Kuuza: TZS ${mzigo.beiKuuza.toStringAsFixed(0)}'),
            Text('Zilizopo Kwenye Mzigo Huu: ${mzigo.idadiStoo}'),
            Text('Expiry: ${mzigo.tareheExpiry}', style: TextStyle(color: mzigo.inakaribiaKuExpire ? Colors.orange.shade800 : Colors.teal)),
            const SizedBox(height: 12),
            TextField(
              controller: idadiCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Idadi Anayochukua Mteja', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ghairi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C), foregroundColor: Colors.white),
            onPressed: () {
              final int idadi = int.tryParse(idadiCtrl.text) ?? 0;
              if (idadi > 0 && idadi <= mzigo.idadiStoo) {
                final sasa = DateTime.now();
                String saaKamili = "${sasa.hour.toString().padLeft(2, '0')}:${sasa.minute.toString().padLeft(2, '0')}";
                wekaTareheZaSasa();

                setState(() {
                  mzigo.idadiStoo -= idadi;
                  miamalaYote.insert(
                    0,
                    Muamala(
                      jinaDawa: "${mzigo.jina} (${mzigo.aina})",
                      idadi: idadi,
                      jumlaMauzo: mzigo.beiKuuza * idadi,
                      jumlaFaida: (mzigo.beiKuuza - mzigo.beiKununua) * idadi,
                      mhudumu: widget.mtumiajiAliyeingia.jina,
                      tarehe: tareheYaLeo,
                      mwezi: mweziWaSasa,
                      mwaka: mwakaWaSasa,
                      saa: saaKamili,
                    ),
                  );
                });
                hifadhiDataZote();
                Navigator.pop(context);
              }
            },
            child: const Text('Thibitisha Mauzo'),
          ),
        ],
      ),
    );
  }

  void sajiliAuOngezaMzigo({MzigoDawa? dawaIliyopo}) {
    final jinaCtrl = TextEditingController(text: dawaIliyopo?.jina ?? '');
    final ainaCtrl = TextEditingController(text: dawaIliyopo?.aina ?? '');
    final kununuaCtrl = TextEditingController();
    final kuuzaCtrl = TextEditingController(text: dawaIliyopo != null ? dawaIliyopo.beiKuuza.toStringAsFixed(0) : '');
    final idadiCtrl = TextEditingController();
    DateTime tareheIliyochaguliwa = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(dawaIliyopo == null ? 'Sajili Dawa Mpya' : 'Ongeza Mzigo Mpya: ${dawaIliyopo.jina}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dawaIliyopo == null) ...[
                  TextField(controller: jinaCtrl, decoration: const InputDecoration(labelText: 'Jina la Dawa')),
                  TextField(controller: ainaCtrl, decoration: const InputDecoration(labelText: 'Aina (Tabs, Syrup, Injection)')),
                ],
                TextField(
                  controller: kununuaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bei Mpya ya Kununua (TZS)'),
                ),
                TextField(
                  controller: kuuzaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Bei ya Kuuza (TZS)'),
                ),
                TextField(
                  controller: idadiCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Idadi ya Mzigo Mpya'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: Text('Expiry: ${tareheIliyochaguliwa.toIso8601String().split('T').first}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tareheIliyochaguliwa,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2035),
                    );
                    if (picked != null) {
                      setDialogState(() => tareheIliyochaguliwa = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ghairi')),
            ElevatedButton(
              onPressed: () {
                if (jinaCtrl.text.isNotEmpty) {
                  setState(() {
                    mizigoYaDawa.add(MzigoDawa(
                      jina: jinaCtrl.text,
                      aina: ainaCtrl.text.isEmpty ? 'General' : ainaCtrl.text,
                      beiKununua: double.tryParse(kununuaCtrl.text) ?? 0,
                      beiKuuza: double.tryParse(kuuzaCtrl.text) ?? 0,
                      idadiStoo: int.tryParse(idadiCtrl.text) ?? 0,
                      tareheExpiry: tareheIliyochaguliwa.toIso8601String().split('T').first,
                    ));
                  });
                  hifadhiDataZote();
                  Navigator.pop(context);
                }
              },
              child: const Text('Hifadhi Mzigo'),
            ),
          ],
        ),
      ),
    );
  }

   void simamiaWatumiaji() {
    final jinaCtrl = TextEditingController();
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Simamia Dispensers & PIN'),
          content: SizedBox(
            width: 350,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: jinaCtrl, decoration: const InputDecoration(labelText: 'Jina la Dispenser')),
                  TextField(controller: pinCtrl, keyboardType: TextInputType.number, maxLength: 4, decoration: const InputDecoration(labelText: 'PIN (tarakimu 4)')),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (jinaCtrl.text.isNotEmpty && pinCtrl.text.length == 4) {
                        if (watumiajiWote.any((u) => u.pin == pinCtrl.text)) return;
                        setState(() {
                          watumiajiWote.add(Mtumiaji(jina: jinaCtrl.text, pin: pinCtrl.text, niAdmin: false));
                        });
                        setDialogState(() {});
                        hifadhiDataZote();
                        jinaCtrl.clear();
                        pinCtrl.clear();
                      }
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Ongeza Dispenser'),
                  ),
                  const Divider(height: 20),
                  ...watumiajiWote.map((u) => ListTile(
                        dense: true,
                        title: Text(u.jina),
                        subtitle: Text('PIN: ${u.pin}'),
                        trailing: u.niAdmin
                            ? const Chip(label: Text('Admin'))
                            : IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() => watumiajiWote.remove(u));
                                  setDialogState(() {});
                                  hifadhiDataZote();
                                },
                              ),
                      )),
                ],
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Funga'))],
        ),
      ),
    );
  }

  Widget jengaUkurasaWaRipoti() {
    Map<String, double> mauzoKwaMwezi = {};
    Map<String, double> faidaKwaMwezi = {};

    for (var m in miamalaYote.where((x) => x.mwaka == mwakaWaSasa)) {
      mauzoKwaMwezi[m.mwezi] = (mauzoKwaMwezi[m.mwezi] ?? 0) + m.jumlaMauzo;
      faidaKwaMwezi[m.mwezi] = (faidaKwaMwezi[m.mwezi] ?? 0) + m.jumlaFaida;
    }

    double jumlaMauzoMwaka = mauzoKwaMwezi.values.fold(0, (a, b) => a + b);
    double jumlaFaidaMwaka = faidaKwaMwezi.values.fold(0, (a, b) => a + b);
    int idadiMiezi = mauzoKwaMwezi.keys.length;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: const Color(0xFF004D40),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HESABU YA MWAKA $mwakaWaSasa (Miezi $idadiMiezi / 12)',
                    style: const TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Jumla Mauzo Mwaka: TZS ${jumlaMauzoMwaka.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                if (widget.mtumiajiAliyeingia.niAdmin)
                  Text('Jumla Faida Mwaka: TZS ${jumlaFaidaMwaka.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Ripoti za Kila Mwezi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ...mauzoKwaMwezi.keys.map((mweziKey) {
          bool niMweziWaSasa = mweziKey == mweziWaSasa;
          return Card(
            child: ListTile(
              leading: Icon(niMweziWaSasa ? Icons.lock_open : Icons.lock, color: niMweziWaSasa ? Colors.teal : Colors.grey),
              title: Text('Mwezi: $mweziKey ${niMweziWaSasa ? "(Unaendelea)" : "(Umefungwa)"}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Mauzo: TZS ${mauzoKwaMwezi[mweziKey]!.toStringAsFixed(0)}${widget.mtumiajiAliyeingia.niAdmin ? " | Faida: TZS ${faidaKwaMwezi[mweziKey]!.toStringAsFixed(0)}" : ""}'),
            ),
          );
        }),
        const Divider(height: 24),
        const Text('Historia ya Miamala:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ...miamalaYote.take(30).map((m) => ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long, color: Colors.teal),
              title: Text('${m.jinaDawa} (x${m.idadi}) - TZS ${m.jumlaMauzo.toStringAsFixed(0)}'),
              subtitle: Text('Tarehe: ${m.tarehe} Saa ${m.saa} | Mhudumu: ${m.mhudumu}'),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dawaZilizochujwa = mizigoYaDawa
        .where((d) => d.jina.toLowerCase().contains(utafutaji.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SmartPharma', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${widget.mtumiajiAliyeingia.jina} | $tareheYaLeo', style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF00695C),
        foregroundColor: Colors.white,
        actions: [
          if (widget.mtumiajiAliyeingia.niAdmin)
            IconButton(icon: const Icon(Icons.group_add), tooltip: 'Simamia Dispensers', onPressed: simamiaWatumiaji),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Funga App (PIN)',
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PinLoginScreen())),
          ),
        ],
      ),
      body: kichupoKilichochaguliwa == 1
          ? jengaUkurasaWaRipoti()
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.teal.shade50,
                  child: Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Text('LEO ($tareheYaLeo)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text('TZS ${mauzoYaLeo.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                                if (widget.mtumiajiAliyeingia.niAdmin)
                                  Text('Faida: TZS ${faidaYaLeo.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              children: [
                                Text('MWEZI ($mweziWaSasa)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text('TZS ${mauzoYaMweziHuu.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                if (widget.mtumiajiAliyeingia.niAdmin)
                                  Text('Faida: TZS ${faidaYaMweziHuu.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    onChanged: (val) => setState(() => utafutaji = val),
                    decoration: InputDecoration(
                      hintText: 'Tafuta dawa stoo...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: dawaZilizochujwa.length,
                    itemBuilder: (context, index) {
                                         final mzigo = dawaZilizochujwa[index];
                      Color rangiKadi = Colors.white;
                      if (mzigo.imeExpire) {
                        rangiKadi = Colors.red.shade50;
                      } else if (mzigo.inakaribiaKuExpire) {
                        rangiKadi = Colors.amber.shade50;
                      }

                      return Card(
                        color: rangiKadi,
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: mzigo.imeExpire
                                ? Colors.red
                                : (mzigo.inakaribiaKuExpire ? Colors.orange : Colors.teal.shade100),
                            child: Icon(
                              mzigo.imeExpire ? Icons.warning : Icons.medication,
                              color: mzigo.imeExpire || mzigo.inakaribiaKuExpire ? Colors.white : const Color(0xFF00695C),
                            ),
                          ),
                          title: Text('${mzigo.jina} (${mzigo.aina})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bei: TZS ${mzigo.beiKuuza.toStringAsFixed(0)} | Stoo: ${mzigo.idadiStoo}'),
                              Text(
                                mzigo.imeExpire
                                    ? 'IME-EXPIRE (${mzigo.tareheExpiry}) - USIUZE!'
                                    : (mzigo.inakaribiaKuExpire
                                        ? 'TAHADHARI: Ina-expire baada ya siku ${mzigo.sikuZilizobaki} (${mzigo.tareheExpiry})'
                                        : 'Exp: ${mzigo.tareheExpiry}'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: mzigo.imeExpire ? Colors.red : (mzigo.inakaribiaKuExpire ? Colors.orange.shade900 : Colors.grey.shade700),
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.mtumiajiAliyeingia.niAdmin)
                                IconButton(
                                  icon: const Icon(Icons.add_box, color: Colors.teal),
                                  tooltip: 'Ongeza Mzigo Mpya (Bei Mpya)',
                                  onPressed: () => sajiliAuOngezaMzigo(dawaIliyopo: mzigo),
                                ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: mzigo.imeExpire
                                      ? Colors.red
                                      : (mzigo.idadiStoo > 0 ? const Color(0xFF00695C) : Colors.grey),
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => dirishaLaKuuza(mzigo),
                                child: Text(mzigo.imeExpire ? 'EXPIRED' : 'TOA'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: kichupoKilichochaguliwa == 0 && widget.mtumiajiAliyeingia.niAdmin
          ? FloatingActionButton.extended(
              onPressed: () => sajiliAuOngezaMzigo(),
              backgroundColor: const Color(0xFF00695C),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Sajili Dawa'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: kichupoKilichochaguliwa,
        selectedItemColor: const Color(0xFF00695C),
        onTap: (index) => setState(() => kichupoKilichochaguliwa = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Mauzo & Stoo'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Ripoti (Miezi/Mwaka)'),
        ],
      ),
    );
  }
}
