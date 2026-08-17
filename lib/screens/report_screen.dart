import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:image_picker/image_picker.dart';
import '../services/complaints_repository.dart';
import '../services/vision_classifier.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/civic_category_tiles.dart';

const List<Map<String, String>> kSampleCivicPhotos = [
  {
    'name': 'Pothole Crater (WHC Rd)',
    'url': 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=800&auto=format&fit=crop&q=80',
    'category': 'Pothole',
  },
  {
    'name': 'Garbage Dump (Variety Sq)',
    'url': 'https://images.unsplash.com/photo-1530587191325-3db32d826c18?w=800&auto=format&fit=crop&q=80',
    'category': 'Garbage',
  },
  {
    'name': 'Pipeline Burst (Central Bazaar)',
    'url': 'https://images.unsplash.com/photo-1584467735815-f778f274e296?w=800&auto=format&fit=crop&q=80',
    'category': 'Water Leak',
  },
  {
    'name': 'Broken Lamppost (Mount Rd)',
    'url': 'https://images.unsplash.com/photo-1509114397022-ed747cca3f65?w=800&auto=format&fit=crop&q=80',
    'category': 'Streetlight',
  },
  {
    'name': 'Broken Drain Slab (VNIT)',
    'url': 'https://images.unsplash.com/photo-1589939705384-5185137a7f0f?w=800&auto=format&fit=crop&q=80',
    'category': 'Other',
  },
];

class ReportScreen extends StatefulWidget {
  final VoidCallback? onReportSuccess;

  const ReportScreen({super.key, this.onReportSuccess});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ComplaintsRepository _repo = ComplaintsRepository();
  final ImagePicker _picker = ImagePicker();
  late ConfettiController _confettiController;

  int _currentStep = 1;

  // Photo state
  XFile? _pickedFile;
  String _photoUrl = kSampleCivicPhotos[0]['url']!;
  String _category = 'Pothole';
  bool _isClassifying = false;
  ClassificationResult? _aiResult;

  // 100% Automatic GPS State
  double _lat = 21.1432;
  double _lng = 79.0620;
  String _autoDetectedLandmark = 'Near Coffee House Square, West High Court Road, Dharampeth';
  bool _isDetectingLocation = false;
  bool _hasAttemptedGps = false;

  final TextEditingController _descriptionController = TextEditingController();

  // Phone OTP State
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  bool _isPhoneVerified = false;
  String _phoneHash = '';
  int _resendTimerSeconds = 0;
  Timer? _resendTimer;

  Map<String, dynamic>? _duplicateAlert;
  String? _rateLimitError;
  String? _otpErrorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    if (_repo.isCitizenLoggedIn) {
      _phoneController.text = _repo.currentCitizenPhone ?? '';
      _phoneHash = _repo.currentCitizenPhoneHash ?? '';
      _isPhoneVerified = true;
    }

    _runAiClassification();
    _checkDuplicates();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendTimerSeconds = 30);
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimerSeconds > 0) {
        setState(() => _resendTimerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _runAiClassification() async {
    setState(() => _isClassifying = true);
    final result = await VisionClassifierService.classifyCivicImage(
      fileName: _pickedFile?.name ?? 'civic_photo.jpg',
      hintText: _autoDetectedLandmark,
    );
    setState(() {
      _isClassifying = false;
      _aiResult = result;
      _category = result.suggestedCategory;
    });
    _checkDuplicates();
  }

  void _checkDuplicates() {
    final dupResult = GeoUtils.findDuplicateComplaint(
      _lat,
      _lng,
      _category,
      _repo.complaints,
      thresholdMeters: 50.0,
    );
    if (dupResult['duplicate'] != null) {
      setState(() => _duplicateAlert = dupResult);
    } else {
      setState(() => _duplicateAlert = null);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file != null) {
        setState(() {
          _pickedFile = file;
          _photoUrl = file.path;
        });
        _runAiClassification();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access image: $e')),
        );
      }
    }
  }

  void _showPhotoOptionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upload Civic Photo Proof',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.photo_library, color: Color(0xFFE65100)),
              ),
              title: Text('Choose from Gallery', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Select evidence photo from your device storage', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.camera_alt, color: Colors.blue[800]),
              ),
              title: Text('Take Live Photo with Camera', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text('Capture the pothole, garbage, or leak on-site', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),

            const Divider(),
            Text('Or Select Sample Civic Proof:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700])),
            const SizedBox(height: 8),

            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: kSampleCivicPhotos.length,
                itemBuilder: (context, idx) {
                  final item = kSampleCivicPhotos[idx];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _pickedFile = null;
                        _photoUrl = item['url']!;
                        _category = item['category']!;
                      });
                      Navigator.pop(ctx);
                      _runAiClassification();
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(item['url']!, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _hasAttemptedGps = true;
    });

    final pos = await LocationService.getCurrentDeviceLocation(context);

    setState(() => _isDetectingLocation = false);

    if (pos == null) return;

    final lat = pos.latitude;
    final lng = pos.longitude;

    final isNagpur = GeoUtils.isInsideNagpur(lat, lng);

    if (!isNagpur) {
      setState(() {
        _lat = lat;
        _lng = lng;
        _autoDetectedLandmark = 'Outside Nagpur Limits';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}) is OUTSIDE Nagpur city. Pin cannot be placed outside Nagpur.',
            ),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final closest = GeoUtils.findClosestNagpurLandmark(lat, lng);

    setState(() {
      _lat = lat;
      _lng = lng;
      _autoDetectedLandmark = '${closest.name} (${closest.area})';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Live GPS Locked: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} (${closest.name})'),
          backgroundColor: Colors.green[700],
        ),
      );
    }

    _checkDuplicates();
  }

  // Real Supabase Phone OTP Request (Field starts empty)
  void _handleSendOtp() async {
    final clean = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _otpErrorMessage = null;
    });

    final res = await SupabaseConfig.sendPhoneOtp(clean);

    setState(() {
      _isSendingOtp = false;
      _otpSent = true;
      _otpController.clear(); // Starts completely empty for user to type!
    });

    _startResendCountdown();

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

  // Real Supabase OTP Verification
  void _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _otpErrorMessage = 'Please enter the verification code.');
      return;
    }

    setState(() {
      _isVerifyingOtp = true;
      _otpErrorMessage = null;
    });

    final res = await SupabaseConfig.verifyPhoneOtp(_phoneController.text, code);

    setState(() => _isVerifyingOtp = false);

    if (res['success']) {
      final hash = GeoUtils.hashPhoneNumber(_phoneController.text);
      _repo.setCitizenSession(_phoneController.text);

      setState(() {
        _phoneHash = hash;
        _isPhoneVerified = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']),
            backgroundColor: Colors.green[700],
          ),
        );
      }
    } else {
      setState(() => _otpErrorMessage = res['message']);
    }
  }

  void _submitReport() async {
    setState(() {
      _rateLimitError = null;
      _isSubmitting = true;
    });

    if (!GeoUtils.isInsideNagpur(_lat, _lng)) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rejected: GPS is outside Nagpur city limits. Cannot add pin.')),
      );
      return;
    }

    if (!_isPhoneVerified) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your mobile number via OTP first.')),
      );
      return;
    }

    final result = await _repo.submitOrMergeReport(
      category: _category,
      description: _descriptionController.text.trim().isEmpty
          ? '$_category issue verified by citizen at $_autoDetectedLandmark'
          : _descriptionController.text.trim(),
      photoUrl: _photoUrl,
      lat: _lat,
      lng: _lng,
      landmark: _autoDetectedLandmark,
      phoneHash: _phoneHash,
    );

    setState(() => _isSubmitting = false);

    if (!result['success']) {
      setState(() => _rateLimitError = result['message']);
      return;
    }

    _confettiController.play();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text('Grievance Registered!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            result['message'],
            style: GoogleFonts.inter(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
                if (widget.onReportSuccess != null) {
                  widget.onReportSuccess!();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('View in Grievances'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPhotoPreview() {
    if (_pickedFile != null && !kIsWeb) {
      return Image.file(
        File(_pickedFile!.path),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.network(
      _photoUrl,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.broken_image, size: 40)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNagpurValid = GeoUtils.isInsideNagpur(_lat, _lng);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'File Civic Grievance (NMC)',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Step $_currentStep/3',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _currentStep / 3,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE65100)),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 20),

                // STEP 1: Photo & Category
                if (_currentStep == 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1. Upload Photo Proof',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1A1C1C)),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showPhotoOptionsDialog,
                        icon: const Icon(Icons.add_photo_alternate, size: 16),
                        label: const Text('Upload Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: _showPhotoOptionsDialog,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          _buildPhotoPreview(),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.photo_camera, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Gallery / Camera', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                          if (_isClassifying)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: CircularProgressIndicator(color: Color(0xFFE65100)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_aiResult != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE65100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFE65100), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Detected Category: ${_aiResult!.suggestedCategory} (${(_aiResult!.confidence * 100).round()}% confidence)',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                                ),
                                Text(
                                  _aiResult!.explanation,
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),

                  Text(
                    '2. Select Grievance Department',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF1A1C1C)),
                  ),
                  const SizedBox(height: 10),

                  CivicCategoryTilesGrid(
                    selectedCategoryId: _category,
                    onSelectCategory: (catId) {
                      if (catId != 'all') {
                        setState(() => _category = catId);
                        _checkDuplicates();
                      }
                    },
                  ),
                ],

                // STEP 2: Automatic GPS
                if (_currentStep == 2) ...[
                  Text(
                    'Automatic GPS Geo-tagging',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF1A1C1C)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nagpur Setu strictly uses live device GPS hardware to prevent fraudulent pins outside Nagpur city limits.',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isNagpurValid ? Colors.white : Colors.red[50],
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isNagpurValid ? const Color(0xFFE65100) : Colors.red[300]!,
                        width: isNagpurValid ? 1.5 : 2,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isNagpurValid ? Icons.my_location : Icons.location_off,
                              color: isNagpurValid ? const Color(0xFFE65100) : Colors.red[800],
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isNagpurValid ? 'Live Hardware GPS Locked' : 'Outside Nagpur City Limit',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isNagpurValid ? const Color(0xFF1A1C1C) : Colors.red[900],
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isDetectingLocation ? null : _detectLocation,
                              icon: _isDetectingLocation
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.refresh, size: 14),
                              label: const Text('Capture GPS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE65100),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        Text('GPS Coordinates:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        const SizedBox(height: 2),
                        Text(
                          '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFFE65100)),
                        ),
                        const SizedBox(height: 12),

                        Text('Nearest Nagpur Locality:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                        const SizedBox(height: 2),
                        Text(
                          _autoDetectedLandmark,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1A1C1C)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isNagpurValid)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.red[400]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.red, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '🚫 GPS position is outside Nagpur Municipal bounds. You CANNOT place a pin or submit a report here.',
                              style: TextStyle(color: Colors.red[900], fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_duplicateAlert != null && isNagpurValid)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: Text(
                        '⚠️ Similar issue found nearby. Submitting will boost priority and attach your photo proof.',
                        style: TextStyle(color: Colors.amber[900], fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Text(
                    'Optional Citizen Note',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Additional details (e.g., deep trench, heavy traffic hazard)...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                ],

                // STEP 3: Real Supabase Phone OTP Authentication
                if (_currentStep == 3) ...[
                  if (_isPhoneVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified_user, color: Colors.green, size: 28),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '✓ Authenticated Citizen (+91 ${_phoneController.text})',
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[900]),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'One-Time Citizen Login Active. You do NOT need to enter your phone number or OTP again.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.green[900], height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await _repo.logoutCitizen();
                              setState(() {
                                _isPhoneVerified = false;
                                _phoneController.clear();
                                _otpController.clear();
                                _otpSent = false;
                              });
                            },
                            icon: const Icon(Icons.switch_account, size: 14, color: Color(0xFFE65100)),
                            label: const Text('Switch / Change Phone Number', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE65100)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Container(
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
                              const Icon(Icons.security, color: Colors.green, size: 22),
                              const SizedBox(width: 8),
                              Text('1-Time Citizen Authentication', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Authenticate once. Your verified session is securely remembered so you never have to re-enter your number.',
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Mobile Number (India)',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
                          child: Text('+91', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            decoration: InputDecoration(
                              hintText: 'Enter 10-digit number',
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: (_isSendingOtp || _resendTimerSeconds > 0) ? null : _handleSendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE65100),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSendingOtp
                              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(_resendTimerSeconds > 0 ? '${_resendTimerSeconds}s' : 'Send OTP'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_otpSent && !_isPhoneVerified) ...[
                      Text('Enter 6-Digit OTP Code', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 6,
                              style: GoogleFonts.inter(fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                hintText: '• • • • • •',
                                hintStyle: const TextStyle(letterSpacing: 4, color: Colors.grey),
                                counterText: '',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _isVerifyingOtp ? null : _handleVerifyOtp,
                            icon: _isVerifyingOtp
                                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check, size: 16),
                            label: const Text('Verify'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  if (_otpErrorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(10)),
                      child: Text(_otpErrorMessage!, style: TextStyle(color: Colors.red[800], fontSize: 12, fontWeight: FontWeight.w600)),
                    ),

                  if (_isPhoneVerified)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Text('✓ Verified Citizen (+91 ${_phoneController.text})', style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
                    ),

                  if (_rateLimitError != null)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_off_outlined, color: Colors.red, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _rateLimitError!,
                              style: TextStyle(color: Colors.red[900], fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 30),

                // Navigation Buttons
                Row(
                  children: [
                    if (_currentStep > 1)
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _currentStep--),
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    const Spacer(),
                    if (_currentStep < 3)
                      ElevatedButton.icon(
                        onPressed: (_currentStep == 2 && !isNagpurValid)
                            ? null
                            : () {
                                if (_currentStep == 1 && !_hasAttemptedGps) {
                                  _detectLocation();
                                }
                                setState(() => _currentStep++);
                              },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: Text(
                          (_currentStep == 2 && !isNagpurValid)
                              ? 'GPS Outside Nagpur (Blocked)'
                              : 'Continue',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitReport,
                        icon: _isSubmitting
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send, size: 16),
                        label: Text(_isSubmitting ? 'Registering...' : 'Register Grievance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFFE65100), Colors.green, Colors.amber, Colors.blue],
            ),
          ),
        ],
      ),
    );
  }
}
