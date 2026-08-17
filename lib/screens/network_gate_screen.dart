import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NetworkGateScreen extends StatelessWidget {
  final VoidCallback onRetry;
  final bool isChecking;

  const NetworkGateScreen({
    super.key,
    required this.onRetry,
    this.isChecking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Warning / Offline Icon Box
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE65100), width: 2),
                ),
                child: const Center(
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 48,
                    color: Color(0xFFE65100),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Internet Connection Required',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1C),
                ),
              ),
              const SizedBox(height: 12),

              // Explanation
              Text(
                'Nagpur Setu requires an active internet connection to synchronize live municipal GPS maps, prevent duplicate civic reports, and process photo verification.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Instructions Checklist
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    _buildCheckRow(Icons.wifi, 'Turn on Wi-Fi or Mobile Data'),
                    const SizedBox(height: 10),
                    _buildCheckRow(Icons.signal_cellular_alt, 'Ensure mobile network signal is stable'),
                    const SizedBox(height: 10),
                    _buildCheckRow(Icons.sync, 'Tap Retry to enter Nagpur Setu'),
                  ],
                ),
              ),

              const Spacer(),

              // Retry Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isChecking ? null : onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: isChecking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Retry Connection',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE65100), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }
}
