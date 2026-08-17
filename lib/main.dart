import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/map_screen.dart';
import 'screens/issue_feed_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/report_screen.dart';
import 'screens/location_permission_gate_screen.dart';
import 'services/complaints_repository.dart';
import 'services/location_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NagpurSetuApp());
}

class NagpurSetuApp extends StatelessWidget {
  const NagpurSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nagpur Setu | Public Civic Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDFAF6),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF6B00),
          primary: const Color(0xFFFF6B00),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1A1C1C)),
          headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1A1C1C)),
          titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1A1C1C)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0.5,
        ),
      ),
      home: const AppRootPermissionGate(),
    );
  }
}

/// Gate widget that mandates location permission before entering the app
class AppRootPermissionGate extends StatefulWidget {
  const AppRootPermissionGate({super.key});

  @override
  State<AppRootPermissionGate> createState() => _AppRootPermissionGateState();
}

class _AppRootPermissionGateState extends State<AppRootPermissionGate> {
  bool _isLoading = true;
  bool _hasLocationPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionState();
  }

  Future<void> _checkPermissionState() async {
    final ready = await LocationService.isLocationReady();
    setState(() {
      _hasLocationPermission = ready;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDFAF6),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
        ),
      );
    }

    if (_hasLocationPermission) {
      return const MainNavigationScreen();
    }

    return const LocationPermissionGateScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final ComplaintsRepository _repo = ComplaintsRepository();

  void _openReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          onReportSuccess: () {
            setState(() => _currentIndex = 0); // Switch to map
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MapScreen(onOpenReport: _openReportScreen),
      const IssueFeedScreen(),
      const AdminScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('🍊', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Text(
              'Nagpur Setu',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1C1C),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reset Demo Data',
            icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
            onPressed: () {
              _repo.resetToDefaultSeed();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Database reset to fresh demo complaints!')),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: _openReportScreen,
              icon: const Icon(Icons.add_circle, size: 16),
              label: const Text('Report Issue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: Colors.white,
        elevation: 2,
        indicatorColor: const Color(0xFFFFF0E5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFFFF6B00)),
            label: 'Nagpur Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.feed_outlined),
            selectedIcon: Icon(Icons.feed, color: Color(0xFFFF6B00)),
            label: 'Issues',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings, color: Color(0xFFFF6B00)),
            label: 'NMC Admin',
          ),
        ],
      ),
    );
  }
}
