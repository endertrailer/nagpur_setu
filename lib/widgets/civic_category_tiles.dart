import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CivicServiceTileData {
  final String id;
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;

  const CivicServiceTileData({
    required this.id,
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
  });
}

const List<CivicServiceTileData> kGovCivicTiles = [
  CivicServiceTileData(
    id: 'Pothole',
    title: 'Roads & Potholes',
    icon: Icons.add_road_outlined,
    bgColor: Color(0xFFFFE4E6),
    borderColor: Color(0xFFFDA4AF),
    iconColor: Color(0xFFE11D48),
  ),
  CivicServiceTileData(
    id: 'Garbage',
    title: 'Garbage & Waste',
    icon: Icons.delete_outline,
    bgColor: Color(0xFFDCFCE7),
    borderColor: Color(0xFF86EFAC),
    iconColor: Color(0xFF16A34A),
  ),
  CivicServiceTileData(
    id: 'Water Leak',
    title: 'Water & Drainage',
    icon: Icons.water_drop_outlined,
    bgColor: Color(0xFFE0F2FE),
    borderColor: Color(0xFF7DD3FC),
    iconColor: Color(0xFF0284C7),
  ),
  CivicServiceTileData(
    id: 'Streetlight',
    title: 'Streetlights',
    icon: Icons.lightbulb_outline,
    bgColor: Color(0xFFFEF9C3),
    borderColor: Color(0xFFFDE047),
    iconColor: Color(0xFFCA8A04),
  ),
  CivicServiceTileData(
    id: 'Other',
    title: 'Public Hazards',
    icon: Icons.warning_amber_outlined,
    bgColor: Color(0xFFF3E8FF),
    borderColor: Color(0xFFD8B4FE),
    iconColor: Color(0xFF9333EA),
  ),
  CivicServiceTileData(
    id: 'all',
    title: 'All Grievances',
    icon: Icons.grid_view_outlined,
    bgColor: Color(0xFFF1F5F9),
    borderColor: Color(0xFFCBD5E1),
    iconColor: Color(0xFF475569),
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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemCount: kGovCivicTiles.length,
      itemBuilder: (context, index) {
        final tile = kGovCivicTiles[index];
        final isSelected = selectedCategoryId.toLowerCase() == tile.id.toLowerCase();

        return GestureDetector(
          onTap: () => onSelectCategory(tile.id),
          child: Column(
            children: [
              // Pastel Box Tile
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: tile.bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE65100) : tile.borderColor,
                      width: isSelected ? 2.5 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFE65100).withAlpha(50),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      tile.icon,
                      size: 34,
                      color: isSelected ? const Color(0xFFE65100) : tile.iconColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Title Below Box
              Text(
                tile.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFFE65100) : const Color(0xFF1A1C1C),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
