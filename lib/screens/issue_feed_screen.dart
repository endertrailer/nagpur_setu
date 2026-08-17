import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/complaint.dart';
import '../services/complaints_repository.dart';
import '../utils/civic_theme.dart';
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
            'Municipal Department Classifications',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: CivicTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // 1. Department Category Tiles
          CivicCategoryTilesGrid(
            selectedCategoryId: _selectedCategory,
            onSelectCategory: (catId) {
              setState(() => _selectedCategory = catId);
            },
          ),
          const SizedBox(height: 16),

          // 2. Search Box
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: GoogleFonts.inter(fontSize: 13, color: CivicTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search grievances by landmark, street, #ID...',
              prefixIcon: const Icon(Icons.search, size: 20, color: CivicTheme.textSecondary),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CivicTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CivicTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: CivicTheme.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grievance Feed List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Public Grievance Feed (${filtered.length})',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: CivicTheme.textPrimary,
                ),
              ),
              if (_selectedCategory != 'all' || _searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'all';
                      _searchQuery = '';
                    });
                  },
                  child: const Text('Clear Filters', style: TextStyle(color: CivicTheme.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Grievance Card List
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CivicTheme.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.folder_open_outlined, size: 40, color: CivicTheme.textSecondary),
                  const SizedBox(height: 8),
                  Text('No Grievances Found', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: CivicTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text('No complaints matching the selected filter criteria.', style: GoogleFonts.inter(fontSize: 12, color: CivicTheme.textSecondary)),
                ],
              ),
            ),

          ...filtered.map((c) {
            final isResolved = c.status == ComplaintStatus.resolved;

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CivicTheme.border),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      buildCivicPhoto(
                        c.photoUrl,
                        height: 160,
                        width: double.infinity,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: CivicTheme.primary.withAlpha(220),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.white.withAlpha(50)),
                          ),
                          child: Text(
                            c.category,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? CivicTheme.statusResolved
                                : c.status == ComplaintStatus.inProgress
                                    ? CivicTheme.statusInProgress
                                    : CivicTheme.statusOpen,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c.status.displayName.toUpperCase(),
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
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
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people_outline, color: Colors.white, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                '${c.reportCount} Citizens Corroborated',
                                style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${c.id}',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: CivicTheme.accent),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          c.title,
                          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: CivicTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: CivicTheme.accent),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                c.landmark,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 12, color: CivicTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 12, color: CivicTheme.textSecondary, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => IssueDetailScreen(complaintId: c.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined, size: 16),
                            label: const Text('View Inspection Details'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: CivicTheme.primary,
                              side: const BorderSide(color: CivicTheme.border),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
