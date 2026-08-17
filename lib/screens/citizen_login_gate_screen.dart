import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/complaints_repository.dart';
import '../services/supabase_service.dart';

class CitizenLoginGateScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const CitizenLoginGateScreen({super.key, required this.onLoginSuccess});

  @override
  State<CitizenLoginGateScreen> createState() => _CitizenLoginGateScreenState();
}

class _CitizenLoginGateScreenState extends State<CitizenLoginGateScreen> {
  final ComplaintsRepository _repo = ComplaintsRepository();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _resendCountdown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        t.cancel();
      }
    });
  }

  Future<void> _sendOtp() async {
    final clean = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) {
      setState(
        () => _errorMessage =
            'Please enter a valid 10-digit Indian mobile number.',
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
    });

    final res = await SupabaseConfig.sendPhoneOtp(clean);

    setState(() {
      _isSendingOtp = false;
      _otpSent = true;
      _otpController.clear();
    });

    _startTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message']),
          backgroundColor: const Color(0xFFE65100),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _errorMessage = 'Please enter the 6-digit OTP code.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
    });

    final res = await SupabaseConfig.verifyPhoneOtp(
      _phoneController.text,
      code,
    );

    setState(() => _isVerifyingOtp = false);

    if (res['success']) {
      await _repo.setCitizenSession(_phoneController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Verified Citizen (+91 ${_phoneController.text})'),
            backgroundColor: Colors.green[700],
          ),
        );
      }
      widget.onLoginSuccess();
    } else {
      setState(() => _errorMessage = res['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFAF6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Official Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F294A),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: Color(0xFFD9531E), width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withAlpha(40)),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.account_balance,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NMC NAGPUR',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'नागपूर महानगरपालिका • Citizen Portal',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'GOVERNMENT OF MAHARASHTRA • URBAN DEVELOPMENT',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFD9531E),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Title Section
              Text(
                'Citizen Mobile Login or Register',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1C1C),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in once to report civic grievances, track repairs, and corroborate municipal issues in Nagpur.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Mobile Input
              Text(
                'Mobile Number (India)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1C1C),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      '+91',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1C1C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter 10-digit number',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.normal,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFFE65100),
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!_otpSent)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSendingOtp ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSendingOtp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(
                            'Send Verification OTP',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),

              // OTP Input Section
              if (_otpSent) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enter 6-Digit OTP Code',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1C1C),
                      ),
                    ),
                    TextButton(
                      onPressed: (_resendCountdown > 0 || _isSendingOtp)
                          ? null
                          : _sendOtp,
                      child: Text(
                        _resendCountdown > 0
                            ? 'Resend in ${_resendCountdown}s'
                            : 'Resend Code',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _resendCountdown > 0
                              ? Colors.grey
                              : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    letterSpacing: 10,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A1C1C),
                  ),
                  decoration: InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: const TextStyle(
                      letterSpacing: 6,
                      color: Colors.grey,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFFE65100),
                        width: 1.8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isVerifyingOtp ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isVerifyingOtp
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.2,
                            ),
                          )
                        : Text(
                            'Verify & Enter Nagpur Setu',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],

              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[900],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              // Privacy Notice
              Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your mobile number is SHA-256 encrypted for privacy.\nNagpur Municipal Corporation Citizen Security Gate',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
