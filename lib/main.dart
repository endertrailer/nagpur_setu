import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/map_screen.dart';
import 'screens/issue_feed_screen.dart';
import 'screens/report_screen.dart';
import 'screens/location_permission_gate_screen.dart';
import 'screens/network_gate_screen.dart';
import 'widgets/official_header.dart';
import 'widgets/official_drawer.dart';
import 'services/location_service.dart';
import 'services/network_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NagpurSetuApp());
}

class NagpurSetuApp extends StatelessWidget {
  const NagpurSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nagpur Municipal Corporation | Nagpur Setu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE65100),
          primary: const Color(0xFFE65100),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
          headlineLarge: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: const Color(0xFF1A1C1C)),
          headlineMedium: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1A1C1C)),
          titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: const Color(0xFF1A1C1C)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE65100),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AppRootSecurityGate(),
    );
  }
}

/// Dual Mandatory Gate: 1. Internet Connection Check -> 2. GPS Location Permission Check
class AppRootSecurityGate extends StatefulWidget {
  const AppRootSecurityGate({super.key});

  @override
  State<AppRootSecurityGate> createState() => _AppRootSecurityGateState();
}

class _AppRootSecurityGateState extends State<AppRootSecurityGate> {
  bool _isLoading = true;
  bool _hasInternet = false;
  bool _hasLocationPermission = false;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _evaluateAppRequirements();
  }

  Future<void> _evaluateAppRequirements() async {
    setState(() => _isChecking = true);

    final hasNet = await NetworkService.hasInternetConnection();
    final hasLoc = await LocationService.isLocationReady();

    if (mounted) {
      setState(() {
        _hasInternet = hasNet;
        _hasLocationPermission = hasLoc;
        _isLoading = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDFAF6),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE65100)),
        ),
      );
    }

    // 1. Mandatory Internet Gate
    if (!_hasInternet) {
      return NetworkGateScreen(
        onRetry: _evaluateAppRequirements,
        isChecking: _isChecking,
      );
    }

    // 2. Mandatory Location Gate
    if (!_hasLocationPermission) {
      return const LocationPermissionGateScreen();
    }

    // 3. Main App Experience
    return const MainNavigationScreen();
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentTab = 0; // 0: Live Map, 1: Grievances

  void _openReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          onReportSuccess: () {
            setState(() => _currentTab = 1); // Switch to grievances so user immediately sees their report!
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: OfficialDrawer(
        onSelectTab: (idx) => setState(() => _currentTab = idx),
        onOpenReport: _openReportScreen,
      ),
      body: Column(
        children: [
          // 1. Official Government Header with Dual Tabs (Map & Grievances)
          OfficialHeader(
            selectedTab: _currentTab,
            onTabChanged: (idx) => setState(() => _currentTab = idx),
            onOpenReport: _openReportScreen,
            onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
          ),

          // 2. Active Citizen Screen View
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                MapScreen(onOpenReport: _openReportScreen),
                const IssueFeedScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
