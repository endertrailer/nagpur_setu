import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/complaint.dart';
import '../utils/geo_utils.dart';
import '../services/complaints_repository.dart';
import '../services/location_service.dart';
import 'issue_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final VoidCallback onOpenReport;

  const MapScreen({super.key, required this.onOpenReport});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final ComplaintsRepository _repo = ComplaintsRepository();

  String _selectedCategory = 'all';
  String _searchQuery = '';
  List<NagpurLocation> _locationSuggestions = [];
  bool _isSearching = false;
  bool _isDetecting = false;

  final LatLng _nagpurCenter = GeoUtils.nagpurCenter;
  final double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChanged);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChanged);
    super.dispose();
  }

  void _onRepoChanged() {
    if (mounted) setState(() {});
  }

  void _handleLocationSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _locationSuggestions = [];
        _isSearching = false;
      } else {
        _locationSuggestions = GeoUtils.searchLocations(query);
        _isSearching = true;
      }
    });
  }

  void _selectNagpurLocation(NagpurLocation loc) {
    setState(() {
      _searchQuery = loc.name;
      _locationSuggestions = [];
      _isSearching = false;
    });
    _mapController.move(LatLng(loc.lat, loc.lng), 15.5);
  }

  Future<void> _detectUserLocation() async {
    setState(() => _isDetecting = true);

    final position = await LocationService.getCurrentDeviceLocation(context);

    setState(() => _isDetecting = false);

    if (position == null) return;

    final lat = position.latitude;
    final lng = position.longitude;

    if (!GeoUtils.isInsideNagpur(lat, lng)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Your GPS location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}) is outside Nagpur city limits. Centering at Zero Mile Stone, Nagpur.',
            ),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 4),
          ),
        );
        _mapController.move(_nagpurCenter, 14.0);
      }
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Live GPS Detected: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} (Nagpur)'),
          backgroundColor: Colors.green[700],
        ),
      );
      _mapController.move(LatLng(lat, lng), 16.0);
    }
  }

  void _showComplaintPreview(Complaint complaint) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isResolved = complaint.status == ComplaintStatus.resolved;

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      complaint.photoUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF0E5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFF6B00)),
                              ),
                              child: Text(
                                complaint.category,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFF6B00),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isResolved
                                    ? Colors.green[50]
                                    : complaint.status == ComplaintStatus.inProgress
                                        ? Colors.orange[50]
                                        : Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                complaint.status.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isResolved
                                      ? Colors.green[700]
                                      : complaint.status == ComplaintStatus.inProgress
                                          ? Colors.orange[800]
                                          : Colors.red[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          complaint.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1C1C),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Color(0xFFFF6B00)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                complaint.landmark,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, size: 16, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${complaint.reportCount} Reported',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[800]),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IssueDetailScreen(complaintId: complaint.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Inspect Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _repo.complaints.where((c) {
      final isNagpur = GeoUtils.isInsideNagpur(c.lat, c.lng);
      final matchesCategory = _selectedCategory == 'all' ||
          c.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.trim().isEmpty ||
          c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.landmark.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.id.toLowerCase().contains(_searchQuery.toLowerCase());

      return isNagpur && matchesCategory && matchesSearch;
    }).toList();

    return Stack(
      children: [
        // 1. FlutterMap Engine Strictly Constrained to Nagpur
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _nagpurCenter,
            initialZoom: _currentZoom,
            minZoom: 12.0,
            maxZoom: 18.0,
            cameraConstraint: CameraConstraint.contain(
              bounds: LatLngBounds(
                const LatLng(GeoUtils.minLat, GeoUtils.minLng),
                const LatLng(GeoUtils.maxLat, GeoUtils.maxLng),
              ),
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.nagpursetu.app',
            ),
            MarkerLayer(
              markers: filtered.map((c) {
                Color pinColor = Colors.red;
                if (c.status == ComplaintStatus.inProgress) {
                  pinColor = const Color(0xFFFF6B00);
                } else if (c.status == ComplaintStatus.resolved) {
                  pinColor = const Color(0xFF10B981);
                }

                final cat = kCivicCategories.firstWhere(
                  (cat) => cat.id.toLowerCase() == c.category.toLowerCase(),
                  orElse: () => kCivicCategories.last,
                );

                return Marker(
                  point: LatLng(c.lat, c.lng),
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showComplaintPreview(c),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: pinColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              cat.icon,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        if (c.reportCount >= 20 && c.status != ComplaintStatus.resolved)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red[700],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Text(
                                '${c.reportCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // 2. Floating Search Bar + Perfectly Spaced Category Options Below
        Positioned(
          top: 14,
          left: 12,
          right: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    const Icon(Icons.search, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: _handleLocationSearch,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1C1C)),
                        decoration: InputDecoration(
                          hintText: 'Search Nagpur location (Sitabuldi, Sadar...)',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey[400]),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Detect My Location',
                      icon: _isDetecting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Color(0xFFFF6B00), strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location, color: Color(0xFFFF6B00), size: 22),
                      onPressed: _isDetecting ? null : _detectUserLocation,
                    ),
                  ],
                ),
              ),

              // Search Suggestions Dropdown
              if (_isSearching && _locationSuggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: Column(
                    children: _locationSuggestions.map((loc) {
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on, size: 18, color: Color(0xFFFF6B00)),
                        title: Text(loc.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                        onTap: () => _selectNagpurLocation(loc),
                      );
                    }).toList(),
                  ),
                ),

              // Consistent Clean Gap (12px)
              const SizedBox(height: 12),

              // Category Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All', 'all', _selectedCategory == 'all', () {
                      setState(() => _selectedCategory = 'all');
                    }),
                    ...kCivicCategories.map((cat) {
                      return _buildFilterChip(
                        '${cat.icon} ${cat.id}',
                        cat.id,
                        _selectedCategory.toLowerCase() == cat.id.toLowerCase(),
                        () => setState(() => _selectedCategory = cat.id),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 3. Map Legend (Bottom Left)
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLegendDot(Colors.red, 'Open'),
                const SizedBox(width: 8),
                _buildLegendDot(const Color(0xFFFF6B00), 'In Progress'),
                const SizedBox(width: 8),
                _buildLegendDot(const Color(0xFF10B981), 'Resolved'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      ],
    );
  }
}
