import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'screens/map_screen.dart';
import 'screens/issue_feed_screen.dart';
import 'screens/report_screen.dart';
import 'screens/location_permission_gate_screen.dart';
import 'screens/network_gate_screen.dart';
import 'screens/citizen_login_gate_screen.dart';
import 'widgets/official_header.dart';
import 'widgets/official_drawer.dart';
import 'services/location_service.dart';
import 'services/network_service.dart';
import 'services/supabase_service.dart';
import 'services/complaints_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
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

/// Mandatory 3-Tier Security & Onboarding Gate:
/// 1. Internet Connection Gate (continuous monitoring — blocks app if connection drops mid-session)
/// 2. GPS Location Permission Gate
/// 3. One-Time Citizen Login Gate
class AppRootSecurityGate extends StatefulWidget {
  const AppRootSecurityGate({super.key});

  @override
  State<AppRootSecurityGate> createState() => _AppRootSecurityGateState();
}

class _AppRootSecurityGateState extends State<AppRootSecurityGate> {
  final ComplaintsRepository _repo = ComplaintsRepository();
  bool _isLoading = true;
  bool _hasInternet = false;
  bool _hasLocationPermission = false;
  bool _isChecking = false;

  /// Continuous connectivity stream subscription.
  /// Monitors network state in real-time and blocks the app immediately
  /// when the user loses internet mid-session (prevents security bypass).
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoStateChanged);
    _startContinuousConnectivityMonitor();
    _evaluateAppRequirements();
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoStateChanged);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _onRepoStateChanged() {
    if (mounted) setState(() {});
  }

  /// Start listening to real-time connectivity changes.
  /// When the user disconnects (WiFi off, airplane mode, etc.),
  /// this immediately sets _hasInternet = false, which forces
  /// the UI back to the NetworkGateScreen.
  void _startContinuousConnectivityMonitor() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      // ConnectivityResult.none means no active network interface
      final hasActiveInterface = results.isNotEmpty &&
          !results.every((r) => r == ConnectivityResult.none);

      if (!hasActiveInterface) {
        // Immediately block access — user lost internet
        if (mounted) {
          setState(() => _hasInternet = false);
        }
        return;
      }

      // Active interface detected, but verify with an actual HTTP check
      // (e.g., connected to WiFi but no actual internet access)
      final actuallyOnline = await NetworkService.hasInternetConnection();
      if (mounted) {
        setState(() => _hasInternet = actuallyOnline);
      }
    });
  }

  Future<void> _evaluateAppRequirements() async {
    setState(() => _isChecking = true);

    final hasNet = await NetworkService.hasInternetConnection();
    final hasLoc = await LocationService.isLocationReady();

    if (hasNet && !SupabaseConfig.isInitialized) {
      await SupabaseConfig.initialize();
    }

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

    // Tier 1: Mandatory Internet Gate (continuously enforced)
    // If the user loses internet at ANY point during the session,
    // the app blocks all features until connectivity is restored.
    if (!_hasInternet) {
      return NetworkGateScreen(
        onRetry: _evaluateAppRequirements,
        isChecking: _isChecking,
      );
    }

    // Tier 2: Mandatory Location Permission Gate
    if (!_hasLocationPermission) {
      return LocationPermissionGateScreen(
        onPermissionGranted: () {
          setState(() => _hasLocationPermission = true);
        },
      );
    }

    // Tier 3: Mandatory Citizen Mobile Login Gate
    if (!_repo.isCitizenLoggedIn) {
      return CitizenLoginGateScreen(
        onLoginSuccess: () {
          setState(() {});
        },
      );
    }

    // Tier 4: Main Civic App Experience (All gates cleared)
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
