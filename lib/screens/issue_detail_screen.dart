import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/complaint.dart';
import '../services/complaints_repository.dart';
import '../utils/geo_utils.dart';

class IssueDetailScreen extends StatefulWidget {
  final String complaintId;

  const IssueDetailScreen({super.key, required this.complaintId});

  @override
  State<IssueDetailScreen> createState() => _IssueDetailScreenState();
}

class _IssueDetailScreenState extends State<IssueDetailScreen> {
  final ComplaintsRepository _repo = ComplaintsRepository();
  bool _hasUpvoted = false;

  @override
  Widget build(BuildContext context) {
    final complaint = _repo.complaints.firstWhere(
      (c) => c.id == widget.complaintId,
      orElse: () => _repo.complaints.first,
    );

    final isResolved = complaint.status == ComplaintStatus.resolved;
    final catObj = kCivicCategories.firstWhere(
      (cat) => cat.id.toLowerCase() == complaint.category.toLowerCase(),
      orElse: () => kCivicCategories.last,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Grievance #${complaint.id}',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Grievance link copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Image Section
            Stack(
              children: [
                Image.network(
                  complaint.photoUrl,
                  width: double.infinity,
                  height: 240,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 240,
                    color: Colors.grey[300],
                    child: const Center(child: Icon(Icons.broken_image, size: 48)),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Row(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'share_hero',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Grievance link copied!')),
                          );
                        },
                        backgroundColor: Colors.white,
                        child: const Icon(Icons.share, color: Color(0xFFE65100), size: 18),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'upvote_hero',
                        onPressed: () {
                          if (!_hasUpvoted) {
                            setState(() {
                              _hasUpvoted = true;
                            });
                            _repo.upvoteComplaint(complaint.id, 'h_flutter_citizen');
                          }
                        },
                        backgroundColor: _hasUpvoted ? Colors.green[700] : const Color(0xFFE65100),
                        child: const Icon(Icons.thumb_up, color: Colors.white, size: 18),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Badges & Category
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          '${catObj.icon} ${complaint.category}',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isResolved
                              ? Colors.green[50]
                              : complaint.status == ComplaintStatus.inProgress
                                  ? const Color(0xFFFFF0E5)
                                  : Colors.red[50],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isResolved
                                ? Colors.green[300]!
                                : complaint.status == ComplaintStatus.inProgress
                                    ? const Color(0xFFE65100)
                                    : Colors.red[300]!,
                          ),
                        ),
                        child: Text(
                          complaint.status.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isResolved
                                ? Colors.green[700]
                                : complaint.status == ComplaintStatus.inProgress
                                    ? const Color(0xFFE65100)
                                    : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Title & Description
                  Text(
                    complaint.title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1C1C),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint.description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. Social Proof
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department, color: Color(0xFFE65100), size: 20),
                        const SizedBox(width: 6),
                        Text(
                          '${complaint.reportCount} citizens corroborated this issue in Nagpur',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Location Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 18, color: Color(0xFFE65100)),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Location (Nagpur)',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          complaint.landmark,
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1C)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nagpur, Maharashtra (GPS: ${complaint.lat.toStringAsFixed(4)}, ${complaint.lng.toStringAsFixed(4)})',
                          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 6. Status History Timeline
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history, size: 18, color: Color(0xFFE65100)),
                            const SizedBox(width: 6),
                            Text(
                              'Status History & Audit',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTimelineNode(
                          title: 'Reported by Citizen',
                          subtitle: 'Submitted with photo proof & OTP authentication.',
                          time: DateFormat('MMM d, hh:mm a').format(complaint.createdAt),
                          isActive: true,
                          isLast: false,
                        ),
                        _buildTimelineNode(
                          title: 'Assigned to Municipal Wing',
                          subtitle: complaint.assignedTo ?? 'NMC Rapid Response Wing',
                          time: 'Squad Dispatched',
                          isActive: complaint.status == ComplaintStatus.inProgress || isResolved,
                          isLast: false,
                        ),
                        _buildTimelineNode(
                          title: isResolved ? 'Resolved & Audited' : 'Resolution in Progress',
                          subtitle: isResolved
                              ? (complaint.resolutionNotes ?? 'Field work completed.')
                              : 'Awaiting repair completion and After-Photo audit.',
                          time: complaint.resolvedAt != null
                              ? DateFormat('MMM d, hh:mm a').format(complaint.resolvedAt!)
                              : 'Ongoing',
                          isActive: isResolved,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 7. Before & After Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.compare, size: 18, color: Color(0xFFE65100)),
                            const SizedBox(width: 6),
                            Text(
                              'Before & After Public Audit',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            // Before
                            Expanded(
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      complaint.photoUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Before (Reported)',
                                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // After
                            Expanded(
                              child: Column(
                                children: [
                                  if (isResolved && complaint.resolvedPhotoUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        complaint.resolvedPhotoUrl!,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  else
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0E5),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFE65100)),
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.build, color: Color(0xFFE65100), size: 28),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Pending Repair',
                                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isResolved ? 'After (Repaired)' : 'Pending Resolution',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isResolved ? Colors.green[700] : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),

      // 8. Fixed Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Grievance link shared!')),
                  );
                },
                icon: const Icon(Icons.share, size: 16, color: Color(0xFF1A1C1C)),
                label: Text('Share', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1C))),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (!_hasUpvoted) {
                    setState(() => _hasUpvoted = true);
                    _repo.upvoteComplaint(complaint.id, 'h_flutter_citizen');
                  }
                },
                icon: const Icon(Icons.exposure_plus_1, size: 18),
                label: Text(
                  _hasUpvoted ? 'Corroborated!' : '+1 Me Too (Affects Me)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasUpvoted ? Colors.green[600] : const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineNode({
    required String title,
    required String subtitle,
    required String time,
    required bool isActive,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFE65100) : Colors.grey[300],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: const Color(0xFFE65100),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1C)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400]),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
