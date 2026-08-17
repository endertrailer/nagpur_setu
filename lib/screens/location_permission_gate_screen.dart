import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/location_service.dart';
import '../main.dart';

class LocationPermissionGateScreen extends StatefulWidget {
  const LocationPermissionGateScreen({super.key});

  @override
  State<LocationPermissionGateScreen> createState() => _LocationPermissionGateScreenState();
}

class _LocationPermissionGateScreenState extends State<LocationPermissionGateScreen> {
  bool _isChecking = false;
  String? _errorMessage;

  Future<void> _handleGrantPermission() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final result = await LocationService.requestLocationPermission(context);

    setState(() => _isChecking = false);

    if (result['granted']) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('🍊', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Nagpur Setu',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1C1C),
                    ),
                  ),
                ],
              ),

              // Center Visual & Mandatory Notice
              Column(
                children: [
                  // Animated Radar Pin Icon
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E5),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFF6B00), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B00).withAlpha(40),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.location_on,
                        size: 54,
                        color: Color(0xFFFF6B00),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Location Access Mandatory',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1C1C),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Nagpur Setu is a verified municipal grievance platform for Nagpur city. Live GPS access is mandatory to:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feature bullets
                  _buildRequirementItem(
                    icon: Icons.pin_drop_outlined,
                    title: 'Accurate Municipal Geo-tagging',
                    desc: 'Pins potholes and broken infrastructure to exact street coordinates.',
                  ),
                  const SizedBox(height: 12),
                  _buildRequirementItem(
                    icon: Icons.shield_outlined,
                    title: 'Anti-Spam & Geofence Verification',
                    desc: 'Strictly verifies that reports originate within Nagpur city limits.',
                  ),
                  const SizedBox(height: 12),
                  _buildRequirementItem(
                    icon: Icons.merge_type,
                    title: '50-Meter Proximity Deduplication',
                    desc: 'Merges duplicate reports to boost urgency without flooding tickets.',
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.red[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // Bottom CTA
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isChecking ? null : _handleGrantPermission,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Icon(Icons.near_me, size: 20),
                      label: Text(
                        _isChecking ? 'Verifying GPS...' : 'Enable GPS & Continue',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: const Color(0xFFFF6B00).withAlpha(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '🔒 Your location is only queried when using map & reporting tools.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFFF6B00), size: 18),
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
                  desc,
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
