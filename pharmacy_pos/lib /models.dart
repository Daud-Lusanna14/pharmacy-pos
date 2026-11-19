import 'dart:convert';
import 'package:crypto/crypto.dart';

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
