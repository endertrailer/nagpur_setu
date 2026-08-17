import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/civic_theme.dart';

class CivicServiceTileData {
  final String id;
  final String title;
  final String department;
  final IconData icon;

  const CivicServiceTileData({
    required this.id,
    required this.title,
    required this.department,
    required this.icon,
  });
}

const List<CivicServiceTileData> kGovCivicTiles = [
  CivicServiceTileData(
    id: 'Pothole',
    title: 'Roads & Potholes',
    department: 'NMC PWD Division',
    icon: Icons.construction_outlined,
  ),
  CivicServiceTileData(
    id: 'Garbage',
    title: 'Solid Waste & Garbage',
    department: 'Sanitation Wing',
    icon: Icons.delete_outline,
  ),
  CivicServiceTileData(
    id: 'Water Leak',
    title: 'Water & Drainage',
    department: 'OCW Water Supply',
    icon: Icons.water_drop_outlined,
  ),
  CivicServiceTileData(
    id: 'Streetlight',
    title: 'Street Lighting',
    department: 'Electrical Grid',
    icon: Icons.lightbulb_outline,
  ),
  CivicServiceTileData(
    id: 'Other',
    title: 'Public Hazards',
    department: 'Emergency Response',
    icon: Icons.warning_amber_outlined,
  ),
  CivicServiceTileData(
    id: 'all',
    title: 'All Grievances',
    department: 'Nagpur Municipal Corp',
    icon: Icons.grid_view_outlined,
  ),
];

class CivicCategoryTilesGrid extends StatelessWidget {
  final String selectedCategoryId;
  final ValueChanged<String> onSelectCategory;

  const CivicCategoryTilesGrid({
    super.key,
    required this.selectedCategoryId,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
      ),
      itemCount: kGovCivicTiles.length,
      itemBuilder: (context, index) {
        final tile = kGovCivicTiles[index];
        final isSelected = selectedCategoryId.toLowerCase() == tile.id.toLowerCase();

        return GestureDetector(
          onTap: () => onSelectCategory(tile.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? CivicTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? CivicTheme.primary : CivicTheme.border,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white.withAlpha(25) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    tile.icon,
                    size: 20,
                    color: isSelected ? Colors.white : CivicTheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tile.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : CivicTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tile.department,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : CivicTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
