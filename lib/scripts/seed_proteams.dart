/// Script to seed Israeli professional teams to Firestore
/// Run with: dart run lib/scripts/seed_proteams.dart
///
/// This script populates the proteams collection with Israeli Premier League
/// and National League teams with their logos

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';

/// Israeli Professional Teams Data
/// Logos are from official team websites or Wikipedia
final proteamsData = [
  // ===== ליגת העל (Premier League) =====
  {
    'teamId': 'maccabi-tel-aviv',
    'name': 'מכבי תל אביב',
    'nameEn': 'Maccabi Tel Aviv',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/c/c0/Maccabi_Tel_Aviv_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'maccabi-haifa',
    'name': 'מכבי חיפה',
    'nameEn': 'Maccabi Haifa',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/9/9b/Maccabi_Haifa_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-beer-sheva',
    'name': 'הפועל באר שבע',
    'nameEn': 'Hapoel Be\'er Sheva',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/1/1c/Hapoel_Be%27er_Sheva_FC_Logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'maccabi-petah-tikva',
    'name': 'מכבי פתח תקווה',
    'nameEn': 'Maccabi Petah Tikva',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/a/ab/Maccabi_Petah_Tikva_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'beitar-jerusalem',
    'name': 'בית״ר ירושלים',
    'nameEn': 'Beitar Jerusalem',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/f/f9/Beitar_Jerusalem_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-haifa',
    'name': 'הפועל חיפה',
    'nameEn': 'Hapoel Haifa',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/2/2f/Hapoel_Haifa_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'bnei-sakhnin',
    'name': 'בני סכנין',
    'nameEn': 'Bnei Sakhnin',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/5/57/Bnei_Sakhnin_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'maccabi-bnei-reineh',
    'name': 'מכבי בני ריינה',
    'nameEn': 'Maccabi Bnei Reineh',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/e/e7/Maccabi_Bnei_Reineh_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-jerusalem',
    'name': 'הפועל ירושלים',
    'nameEn': 'Hapoel Jerusalem',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/7/73/Hapoel_Jerusalem_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-tel-aviv',
    'name': 'הפועל תל אביב',
    'nameEn': 'Hapoel Tel Aviv',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/b/b7/Hapoel_Tel_Aviv_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'ashdod',
    'name': 'אשדוד',
    'nameEn': 'Ashdod SC',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/5/5d/Ashdod_SC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'maccabi-netanya',
    'name': 'מכבי נתניה',
    'nameEn': 'Maccabi Netanya',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/c/c6/Maccabi_Netanya_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'ironi-kiryat-shmona',
    'name': 'עירוני קריית שמונה',
    'nameEn': 'Ironi Kiryat Shmona',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/d/dc/Ironi_Kiryat_Shmona_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'sektzia-ness-ziona',
    'name': 'סקציה נס ציונה',
    'nameEn': 'Sektzia Ness Ziona',
    'league': 'premier',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/e/e4/Sektzia_Ness_Ziona_FC_logo.svg',
    'isActive': true,
  },

  // ===== ליגה לאומית (National League) =====
  {
    'teamId': 'hapoel-hadera',
    'name': 'הפועל חדרה',
    'nameEn': 'Hapoel Hadera',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/7/73/Hapoel_Hadera_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-acre',
    'name': 'הפועל עכו',
    'nameEn': 'Hapoel Acre',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/a/ab/Hapoel_Acre_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-raanana',
    'name': 'הפועל רעננה',
    'nameEn': 'Hapoel Ra\'anana',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/f/f4/Hapoel_Ra%27anana_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-kfar-saba',
    'name': 'הפועל כפר סבא',
    'nameEn': 'Hapoel Kfar Saba',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/c/c6/Hapoel_Kfar_Saba_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-petah-tikva',
    'name': 'הפועל פתח תקווה',
    'nameEn': 'Hapoel Petah Tikva',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/8/85/Hapoel_Petah_Tikva_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-nof-hagalil',
    'name': 'הפועל נוף הגליל',
    'nameEn': 'Hapoel Nof HaGalil',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/1/16/Hapoel_Nof_HaGalil_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'beitar-tel-aviv',
    'name': 'בית״ר תל אביב רמת גן',
    'nameEn': 'Beitar Tel Aviv Ramla',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/0/0c/Beitar_Tel_Aviv_Bat_Yam_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'maccabi-kabilio-jaffa',
    'name': 'מכבי קביליו יפו',
    'nameEn': 'Maccabi Kabilio Jaffa',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/a/a8/Maccabi_Jaffa_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-afula',
    'name': 'הפועל עפולה',
    'nameEn': 'Hapoel Afula',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/5/54/Hapoel_Afula_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'maccabi-herzliya',
    'name': 'מכבי הרצליה',
    'nameEn': 'Maccabi Herzliya',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/2/27/Maccabi_Herzliya_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-umm-al-fahm',
    'name': 'הפועל אום אל-פחם',
    'nameEn': 'Hapoel Umm al-Fahm',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/3/3e/Hapoel_Umm_al-Fahm_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'ms-kafr-qasim',
    'name': 'מ.ס. כפר קאסם',
    'nameEn': 'MS Kafr Qasim',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/9/91/MS_Kafr_Qasim_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'ironi-tiberias',
    'name': 'עירוני טבריה',
    'nameEn': 'Ironi Tiberias',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/6/6d/Ironi_Tiberias_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-rishon-lezion',
    'name': 'הפועל ראשון לציון',
    'nameEn': 'Hapoel Rishon LeZion',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/f/fe/Hapoel_Rishon_LeZion_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'maccabi-yavne',
    'name': 'מכבי יבנה',
    'nameEn': 'Maccabi Yavne',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/4/49/Maccabi_Yavne_FC_logo.svg',
    'isActive': true,
  },
  {
    'teamId': 'hapoel-nazareth-illit',
    'name': 'הפועל נצרת עילית',
    'nameEn': 'Hapoel Nazareth Illit',
    'league': 'national',
    'logoUrl':
        'https://upload.wikimedia.org/wikipedia/en/7/75/Hapoel_Nazareth_Illit_FC_logo.svg',
    'isActive': true,
  },
];

Future<void> main() async {
  print('🚀 Starting ProTeams seeding script...');

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    final firestore = FirebaseFirestore.instance;
    final proteamsRef = firestore.collection('proteams');

    print('📊 Found ${proteamsData.length} teams to seed');
    print('   - Premier League: ${proteamsData.where((t) => t['league'] == 'premier').length} teams');
    print('   - National League: ${proteamsData.where((t) => t['league'] == 'national').length} teams');

    int count = 0;
    for (final teamData in proteamsData) {
      final teamId = teamData['teamId'] as String;
      await proteamsRef.doc(teamId).set(teamData);
      count++;
      print('  [$count/${proteamsData.length}] ✓ ${teamData['name']} (${teamData['league']})');
    }

    print('\n✅ Successfully seeded $count teams to Firestore!');
    print('📍 Collection: proteams');
    print('🎯 Ready to use in the app!');
  } catch (e, stackTrace) {
    print('❌ Error seeding teams: $e');
    print('Stack trace: $stackTrace');
  }
}
