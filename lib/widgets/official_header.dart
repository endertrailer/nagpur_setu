import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OfficialHeader extends StatelessWidget {
  final int selectedTab; // 0: Map, 1: Grievances, 2: Admin
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
        gradient: LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF6B00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33E65100),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Menu + Title + Seal + Notification
              Row(
                children: [
                  // Hamburger Menu
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                    onPressed: onOpenDrawer,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),

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

                  // Official Emblem / Seal
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: const Center(
                      child: Text('🏛️', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Notification Bell
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No new municipal emergency alerts in Nagpur.')),
                          );
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.yellowAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Segmented Tab Switcher
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _buildSegmentTab(0, 'LIVE MAP', Icons.map_outlined),
                    _buildSegmentTab(1, 'GRIEVANCES', Icons.assignment_outlined),
                    _buildSegmentTab(2, 'NMC ADMIN', Icons.admin_panel_settings_outlined),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Sub-header Tagline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Know your city services in one touch',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withAlpha(235),
                    ),
                  ),
                  GestureDetector(
                    onTap: onOpenReport,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_circle, color: Color(0xFFE65100), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Report Issue',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFE65100),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentTab(int index, String label, IconData icon) {
    final isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTabChanged(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isSelected
                ? const [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? const Color(0xFFE65100) : Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? const Color(0xFFE65100) : Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
