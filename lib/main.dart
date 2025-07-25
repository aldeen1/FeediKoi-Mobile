import 'package:feedikoi/data/repositories/FirebaseRepository.dart';
import 'package:feedikoi/firebase_options.dart';
import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:feedikoi/services/logger_feedikoi_service.dart';
import 'package:feedikoi/data/datasource/mock_feedikoi_service.dart';
import 'package:feedikoi/shared/widgets/app_bar.dart';
import 'package:feedikoi/shared/widgets/navbar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'features/dashboard/dashboard_page.dart';
import 'features/info_kolam/info_kolam_page.dart';
import 'features/jadwal_pakan/jadwal_pakan_page.dart';
import 'features/profile/profile_page.dart';
import 'features/splash/splash_screen_page.dart';
import 'features/statistic_pakan/statistic_pakan_page.dart';

Future<void> requestInitialPermissions() async {
  await Future.wait([
    Permission.photos.request(),
  ]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  await requestInitialPermissions();

  FlutterNativeSplash.remove();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FeediKoi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.instrumentSansTextTheme()
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreenPage(),
        '/home': (context) => const MyHomePage(title: 'Feedikoi'),
      },
      color: Colors.grey[50],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FeedikoiService feedService = LoggingFeedikoiService(FirebaseRepository());
  int selectedIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _requestAllPermissions();
  }

  Future<bool> _requestAllPermissions() async {
    final permissions = [
      Permission.storage,
      Permission.phone,
    ];

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    return allGranted;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DashboardPage(service: feedService),
      JadwalPakanPage(service: feedService),
      StatisticPakanPage(service: feedService),
      InfoKolamPage(service: feedService),
      ProfilePage()
    ];

    return Scaffold(
      appBar: CustomAppBar(
        service: feedService,
      ),
      body: _pages[selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: CustomNavBar(
            currentIndex: selectedIndex,
            onTap: (index) => setState(() {
              selectedIndex = index;
            })
        )
      ),
      backgroundColor: Colors.grey[300],
    );
  }
}
