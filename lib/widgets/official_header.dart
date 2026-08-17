import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/civic_theme.dart';

class OfficialHeader extends StatelessWidget {
  final int selectedTab; // 0: Map, 1: Grievances
  final ValueChanged<int> onTabChanged;
  final VoidCallback onOpenReport;
  final VoidCallback onOpenDrawer;

  const OfficialHeader({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onOpenReport,
    required this.onOpenDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: CivicTheme.orangeGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33E65100),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main App Header: Menu + Title + Seal
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                    onPressed: onOpenDrawer,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),

                  // Title & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nagpur Municipal Corporation',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'नागपूर महानगरपालिका • Nagpur Setu',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withAlpha(220),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Official Seal
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance,
                        color: Color(0xFFE65100),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Segmented Tab Switcher (Dual Tabs: Map & Grievances)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Tab 1: Live City Map
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTabChanged(0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: selectedTab == 0
                                ? const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 16,
                                color: selectedTab == 0 ? const Color(0xFFE65100) : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE MAP',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: selectedTab == 0 ? const Color(0xFFE65100) : Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Tab 2: Public Grievances Feed
                    Expanded(
                      child: GestureDetector(
                        onTap: () => onTabChanged(1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: selectedTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: selectedTab == 1
                                ? const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 16,
                                color: selectedTab == 1 ? const Color(0xFFE65100) : Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'GRIEVANCES',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: selectedTab == 1 ? const Color(0xFFE65100) : Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
