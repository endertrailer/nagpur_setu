import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/complaints_repository.dart';

class OfficialDrawer extends StatelessWidget {
  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenReport;

  const OfficialDrawer({
    super.key,
    required this.onSelectTab,
    required this.onOpenReport,
  });

  @override
  Widget build(BuildContext context) {
    final repo = ComplaintsRepository();

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Official Header in Drawer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE65100), Color(0xFFFF6B00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🏛️', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NMC Nagpur',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'नागपूर महानगरपालिका',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.white.withAlpha(220),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    repo.isCitizenLoggedIn
                        ? 'Citizen: +91 ${repo.currentCitizenPhone}'
                        : 'Nagpur Setu • Public Citizen Portal',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Drawer Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildDrawerTile(
                  icon: Icons.map_outlined,
                  title: 'Nagpur Live Map',
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(0);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.assignment_outlined,
                  title: 'Public Civic Grievances',
                  onTap: () {
                    Navigator.pop(context);
                    onSelectTab(1);
                  },
                ),
                _buildDrawerTile(
                  icon: Icons.add_circle_outline,
                  title: 'Report Civic Issue (Geo-tagged)',
                  onTap: () {
                    Navigator.pop(context);
                    onOpenReport();
                  },
                ),
                const Divider(),

                // Emergency Contacts section
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'NMC EMERGENCY HELPLINES',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[500]),
                  ),
                ),
                _buildHelplineTile('NMC Control Room', '0712-2567035'),
                _buildHelplineTile('OCW Water Emergency', '1800-233-1191'),
                _buildHelplineTile('Fire Brigade', '101'),
                _buildHelplineTile('Ambulance / GMC', '108'),

                const Divider(),
                _buildDrawerTile(
                  icon: Icons.refresh,
                  title: 'Reset Demo Complaints Seed',
                  onTap: () {
                    repo.resetToDefaultSeed();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Database reset to fresh demo complaints!')),
                    );
                  },
                ),
              ],
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Govt of Maharashtra • Nagpur Municipal Corporation\nPublic Citizen Grievance Network',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400], height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFE65100), size: 22),
      title: Text(
        title,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1C1C)),
      ),
      onTap: onTap,
    );
  }

  Widget _buildHelplineTile(String label, String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700])),
          Text(
            number,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
          ),
        ],
      ),
    );
  }
}
