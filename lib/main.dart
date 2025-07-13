import 'package:feedikoi/services/feedikoi_service.dart';
import 'package:feedikoi/services/logger_feedikoi_service.dart';
import 'package:feedikoi/shared/widgets/app_bar.dart';
import 'package:feedikoi/shared/widgets/navbar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/dashboard/dashboard_page.dart';
import 'features/info_kolam/info_kolam_page.dart';
import 'features/jadwal_pakan/jadwal_pakan_page.dart';
import 'features/profile/profile_page.dart';
import 'features/statistic_pakan/statistic_pakan_page.dart';

void main() {
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
      home: const MyHomePage(title: 'Feedikoi'),
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
  final FeedikoiService feedService = LoggingFeedikoiService(MockFeedikoiService());
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      DashboardPage(),
      JadwalPakanPage(),
      StatisticPakanPage(service: feedService,),
      InfoKolamPage(),
      ProfilePage()
    ];

    return Scaffold(
      appBar: const CustomAppBar(
        activityText: "Pemberian Makan Berhasil",
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
