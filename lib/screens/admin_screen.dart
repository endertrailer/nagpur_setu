import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/complaint.dart';
import '../services/complaints_repository.dart';
import 'issue_detail_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ComplaintsRepository _repo = ComplaintsRepository();
  String _selectedStatus = 'all';
  String _searchQuery = '';
  String _sortBy = 'urgency'; // 'urgency' | 'newest'

  @override
  void initState() {
    super.initState();
    _repo.addListener(_onRepoChange);
  }

  @override
  void dispose() {
    _repo.removeListener(_onRepoChange);
    super.dispose();
  }

  void _onRepoChange() {
    if (mounted) setState(() {});
  }

  void _showResolveDialog(Complaint complaint) {
    final photoController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1541888946425-d0fbb18086f6?w=800&auto=format&fit=crop&q=80',
    );
    final notesController = TextEditingController(
      text: 'Hot bituminous patch completed over road section by NMC squad. Site cleared and traffic resumed.',
    );
    final squadController = TextEditingController(
      text: 'NMC Rapid Response Wing #2',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 24),
            const SizedBox(width: 8),
            Text(
              'Audit & Resolve Proof',
              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MANDATORY CONSTRAINT: A verified After-Photo is required to close #${complaint.id}.',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[700]),
              ),
              const SizedBox(height: 14),

              Text('After-Photo Proof URL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: photoController,
                style: GoogleFonts.inter(fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              Text('Resolution Notes / Work Performed', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: notesController,
                maxLines: 2,
                style: GoogleFonts.inter(fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              Text('Field Squad / Contractor Assigned', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextField(
                controller: squadController,
                style: GoogleFonts.inter(fontSize: 12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (photoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('After-photo proof is required!')),
                );
                return;
              }
              final res = _repo.resolveComplaint(
                id: complaint.id,
                resolvedPhotoUrl: photoController.text.trim(),
                resolutionNotes: notesController.text.trim(),
                assignedTo: squadController.text.trim(),
              );

              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(res['message'])),
              );
            },
            icon: const Icon(Icons.check_circle, size: 16),
            label: const Text('Sign Off Resolution'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final all = _repo.complaints;
    final total = all.length;
    final openCount = all.where((c) => c.status == ComplaintStatus.open).length;
    final inProgCount = all.where((c) => c.status == ComplaintStatus.inProgress).length;
    final resCount = all.where((c) => c.status == ComplaintStatus.resolved).length;

    final filtered = all.where((c) {
      final matchesStatus = _selectedStatus == 'all' ||
          (_selectedStatus == 'open' && c.status == ComplaintStatus.open) ||
          (_selectedStatus == 'in_progress' && c.status == ComplaintStatus.inProgress) ||
          (_selectedStatus == 'resolved' && c.status == ComplaintStatus.resolved);

      final matchesSearch = _searchQuery.trim().isEmpty ||
          c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.landmark.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.id.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesSearch;
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'urgency') {
        return b.reportCount.compareTo(a.reportCount);
      }
      return b.createdAt.compareTo(a.createdAt);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          'NMC Admin Grievance Desk',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1C)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Summary Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: [
                _buildKpiCard('Total Complaints', '$total', Colors.blueGrey),
                _buildKpiCard('Needs Action (Open)', '$openCount', Colors.red[700]!),
                _buildKpiCard('In Progress', '$inProgCount', const Color(0xFFFF6B00)),
                _buildKpiCard('Resolved & Audited', '$resCount', Colors.green[700]!),
              ],
            ),
            const SizedBox(height: 16),

            // Search and Controls
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search complaints, landmark, #ID...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      isDense: true,
                      contentPadding: const EdgeInsets.all(10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          isDense: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Status', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'open', child: Text('Open', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'in_progress', child: Text('In Progress', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'resolved', child: Text('Resolved', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) => setState(() => _selectedStatus = val ?? 'all'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _sortBy,
                          isDense: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'urgency', child: Text('By Urgency', style: TextStyle(fontSize: 12))),
                            DropdownMenuItem(value: 'newest', child: Text('Newest First', style: TextStyle(fontSize: 12))),
                          ],
                          onChanged: (val) => setState(() => _sortBy = val ?? 'urgency'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Urgency Priority Action Queue Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Priority Action Queue (${filtered.length})',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1C)),
                ),
                Text(
                  'Sorted by Reports',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Queue List
            ...filtered.map((c) {
              final isResolved = c.status == ComplaintStatus.resolved;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            c.photoUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('#${c.id}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B00))),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isResolved ? Colors.green[50] : Colors.red[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c.status.displayName,
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isResolved ? Colors.green[800] : Colors.red[800]),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${c.reportCount} Reports',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[700]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.landmark,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IssueDetailScreen(complaintId: c.id),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Inspect', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        if (!isResolved && c.status == ComplaintStatus.open)
                          ElevatedButton(
                            onPressed: () {
                              _repo.updateStatus(c.id, ComplaintStatus.inProgress, assignedTo: 'NMC Rapid Response Wing');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Issue #${c.id} marked In Progress!')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Start Work', style: TextStyle(fontSize: 12)),
                          ),
                        if (!isResolved)
                          ElevatedButton.icon(
                            onPressed: () => _showResolveDialog(c),
                            icon: const Icon(Icons.camera_alt, size: 14),
                            label: const Text('Resolve', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(80)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
