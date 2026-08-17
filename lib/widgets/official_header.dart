import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        color: Color(0xFF0F294A),
        border: Border(
          bottom: BorderSide(color: Color(0xFFD9531E), width: 2.5),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Statutory Strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GOVT. OF MAHARASHTRA • URBAN DEVELOPMENT',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD9531E),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'NMC CITIZEN SETU',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Main App Header: Menu + Title + Seal
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 24),
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
                          'नागपूर महानगरपालिका • Grievance Redressal',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Official Municipal Emblem Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withAlpha(50)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.account_balance,
                        color: Colors.white,
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
                  color: const Color(0xFF0A1D36),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withAlpha(20)),
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 16,
                                color: selectedTab == 0 ? const Color(0xFF0F294A) : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'LIVE MAP',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: selectedTab == 0 ? const Color(0xFF0F294A) : Colors.white70,
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
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 16,
                                color: selectedTab == 1 ? const Color(0xFF0F294A) : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'GRIEVANCES',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: selectedTab == 1 ? const Color(0xFF0F294A) : Colors.white70,
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
