import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/complaint.dart';
import '../services/complaints_repository.dart';
import '../widgets/civic_category_tiles.dart';
import 'issue_detail_screen.dart';

class IssueFeedScreen extends StatefulWidget {
  const IssueFeedScreen({super.key});

  @override
  State<IssueFeedScreen> createState() => _IssueFeedScreenState();
}

class _IssueFeedScreenState extends State<IssueFeedScreen> {
  final ComplaintsRepository _repo = ComplaintsRepository();
  String _selectedCategory = 'all';
  String _searchQuery = '';

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

  @override
  Widget build(BuildContext context) {
    final filtered = _repo.complaints.where((c) {
      final matchesCategory = _selectedCategory == 'all' ||
          c.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.trim().isEmpty ||
          c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.landmark.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.id.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'NMC Civic Grievance Categories',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1C1C),
            ),
          ),
          const SizedBox(height: 10),

          // 1. Pastel Category Tiles Grid (Exact Style from Screenshot)
          CivicCategoryTilesGrid(
            selectedCategoryId: _selectedCategory,
            onSelectCategory: (catId) {
              setState(() => _selectedCategory = catId);
            },
          ),
          const SizedBox(height: 18),

          // 2. Search Box
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search grievances by landmark, street, #ID...',
              prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grievance Feed List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Public Complaints (${filtered.length})',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1C),
                ),
              ),
              if (_selectedCategory != 'all')
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = 'all'),
                  child: Text(
                    'Clear Filter',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE65100),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Complaints Feed List
          ...filtered.map((c) {
            final isResolved = c.status == ComplaintStatus.resolved;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => IssueDetailScreen(complaintId: c.id),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          child: Image.network(
                            c.photoUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: Text(
                              c.category,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? Colors.green[700]
                                  : c.status == ComplaintStatus.inProgress
                                      ? const Color(0xFFE65100)
                                      : Colors.red[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              c.status.displayName,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  '${c.reportCount} Citizens Reported',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${c.id}',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c.title,
                            style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1C)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Color(0xFFE65100)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  c.landmark,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
