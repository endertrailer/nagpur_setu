import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../services/complaints_repository.dart';
import '../services/vision_classifier.dart';
import '../services/location_service.dart';
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
  late ConfettiController _confettiController;

  int _currentStep = 1;

  // Form State
  String _photoUrl = kSampleCivicPhotos[0]['url']!;
  String _category = 'Pothole';
  bool _isClassifying = false;
  ClassificationResult? _aiResult;

  final TextEditingController _landmarkController = TextEditingController(text: 'Coffee House Square, West High Court Road, Dharampeth');
  final TextEditingController _descriptionController = TextEditingController();
  double _lat = 21.1432;
  double _lng = 79.0620;
  bool _isDetectingLocation = false;

  final TextEditingController _locationSearchController = TextEditingController();
  List<NagpurLocation> _searchSuggestions = [];

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isPhoneVerified = false;
  String _phoneHash = '';

  Map<String, dynamic>? _duplicateAlert;
  String? _rateLimitError;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    if (_repo.isCitizenLoggedIn) {
      _phoneController.text = _repo.currentCitizenPhone ?? '';
      _phoneHash = _repo.currentCitizenPhoneHash ?? '';
      _isPhoneVerified = true;
    } else {
      _phoneController.text = '9823012345';
    }

    _runAiClassification();
    _checkDuplicates();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _landmarkController.dispose();
    _descriptionController.dispose();
    _locationSearchController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _runAiClassification() async {
    setState(() => _isClassifying = true);
    final result = await VisionClassifierService.classifyCivicImage(
      fileName: 'pothole_crater.jpg',
      hintText: _landmarkController.text,
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

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);

    final pos = await LocationService.getCurrentDeviceLocation(context);

    setState(() => _isDetectingLocation = false);

    if (pos == null) return;

    final lat = pos.latitude;
    final lng = pos.longitude;

    if (!GeoUtils.isInsideNagpur(lat, lng)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Detected GPS (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}) is outside Nagpur limits. Please pick a location within Nagpur.',
            ),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    setState(() {
      _lat = lat;
      _lng = lng;
      _landmarkController.text = 'Verified GPS Location, Nagpur (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📍 Live GPS: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)} (Nagpur)'),
          backgroundColor: Colors.green[700],
        ),
      );
    }

    _checkDuplicates();
  }

  void _searchNagpurLocation(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchSuggestions = []);
    } else {
      setState(() {
        _searchSuggestions = GeoUtils.searchLocations(query);
      });
    }
  }

  void _selectLocation(NagpurLocation loc) {
    setState(() {
      _lat = loc.lat;
      _lng = loc.lng;
      _landmarkController.text = '${loc.name} (${loc.area})';
      _locationSearchController.text = loc.name;
      _searchSuggestions = [];
    });
    _checkDuplicates();
  }

  void _showPhotoProofPicker() {
    final customUrlController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select or Upload Photo Proof',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),

            // Sample Civic Photos Grid
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: kSampleCivicPhotos.length,
                itemBuilder: (context, idx) {
                  final item = kSampleCivicPhotos[idx];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _photoUrl = item['url']!;
                        _category = item['category']!;
                      });
                      Navigator.pop(ctx);
                      _checkDuplicates();
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _photoUrl == item['url'] ? const Color(0xFFE65100) : Colors.grey[300]!,
                          width: _photoUrl == item['url'] ? 2.5 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(item['url']!, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            Text('Or Enter Custom Photo URL / Cloud Image:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: customUrlController,
                    style: GoogleFonts.inter(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'https://images.unsplash.com/...',
                      filled: true,
                      fillColor: const Color(0xFFF8F9FA),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (customUrlController.text.trim().isNotEmpty) {
                      setState(() => _photoUrl = customUrlController.text.trim());
                      Navigator.pop(ctx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE65100),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Use Photo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendOtp() {
    final clean = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit mobile number')),
      );
      return;
    }
    setState(() {
      _otpSent = true;
      _otpController.text = '849201';
    });
  }

  void _verifyOtp() {
    if (_otpController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }
    final hash = GeoUtils.hashPhoneNumber(_phoneController.text);
    _repo.setCitizenSession(_phoneController.text);

    setState(() {
      _phoneHash = hash;
      _isPhoneVerified = true;
    });
  }

  void _submitReport() {
    setState(() => _rateLimitError = null);

    if (!GeoUtils.isInsideNagpur(_lat, _lng)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rejected: Location is outside Nagpur city limits.')),
      );
      return;
    }

    if (!_isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify your phone via OTP first.')),
      );
      return;
    }

    // Rate-limit check & submission
    final result = _repo.submitOrMergeReport(
      category: _category,
      description: _descriptionController.text.trim().isEmpty
          ? '$_category issue reported near ${_landmarkController.text}'
          : _descriptionController.text.trim(),
      photoUrl: _photoUrl,
      lat: _lat,
      lng: _lng,
      landmark: _landmarkController.text.trim(),
      phoneHash: _phoneHash,
    );

    if (!result['success']) {
      setState(() => _rateLimitError = result['message']);
      return;
    }

    _confettiController.play();

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
            child: const Text('View on Map'),
          ),
        ],
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
                // Step Progress Bar
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
                      TextButton.icon(
                        onPressed: _showPhotoProofPicker,
                        icon: const Icon(Icons.photo_library, size: 16, color: Color(0xFFE65100)),
                        label: const Text('Change Photo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  GestureDetector(
                    onTap: _showPhotoProofPicker,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        children: [
                          Image.network(
                            _photoUrl,
                            height: 190,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Tap to Change', style: TextStyle(color: Colors.white, fontSize: 11)),
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
                                  'AI Category Match: ${_aiResult!.suggestedCategory} (${(_aiResult!.confidence * 100).round()}% confidence)',
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

                  // Government Category Selection Tiles
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

                // STEP 2: Location (Detect GPS & 60+ Nagpur Locations Search)
                if (_currentStep == 2) ...[
                  // Detect GPS Button
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE65100)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: Color(0xFFE65100), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Detect Citizen GPS (Nagpur)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('GPS: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _isDetectingLocation ? null : _detectLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFE65100),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFFE65100)),
                          ),
                          child: _isDetectingLocation
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE65100)),
                                )
                              : const Text('Detect GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Location Autocomplete (60+ Nagpur Locations)
                  Text(
                    'Search Precise Nagpur Landmark & Area',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _locationSearchController,
                    onChanged: _searchNagpurLocation,
                    decoration: InputDecoration(
                      hintText: 'Type Dharampeth, Sitabuldi, Sadar, Wardha Rd...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                  if (_searchSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                      ),
                      child: Column(
                        children: _searchSuggestions.map((loc) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, color: Color(0xFFE65100), size: 18),
                            title: Text(loc.name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                            subtitle: Text(loc.area, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                            onTap: () => _selectLocation(loc),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Text(
                    'Exact Street Address / Landmark',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _landmarkController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Near Coffee House Square, WHC Road',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Grievance Description',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Describe severity, road hazard or water leakage...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (!isNagpurValid)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                      child: Text('❌ Location is outside Nagpur municipal limits. Please pick a location inside Nagpur.', style: TextStyle(color: Colors.red[800], fontSize: 12)),
                    ),

                  if (_duplicateAlert != null && isNagpurValid)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber[300]!),
                      ),
                      child: Text(
                        '⚠️ Similar issue found nearby. Submitting will boost priority and attach your photo proof.',
                        style: TextStyle(color: Colors.amber[900], fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],

                // STEP 3: Phone OTP Verification
                if (_currentStep == 3) ...[
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
                            Text('Citizen Authentication', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Blocks bot spam. Phone numbers are SHA-256 encrypted for citizen privacy.',
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
                          decoration: InputDecoration(
                            hintText: '9876543210',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Send OTP'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_otpSent) ...[
                    Text('Enter 6-Digit OTP', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 18, letterSpacing: 8, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _verifyOtp,
                          icon: const Icon(Icons.check, size: 16),
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

                  if (_isPhoneVerified)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Text('✓ Verified Citizen (SHA-256 Encrypted)', style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
                    ),

                  // 7-Day 50m Rate Limit Error Banner
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
                          const Icon(Icons.error_outline, color: Colors.red, size: 22),
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

                // Step Navigation Buttons
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
                        onPressed: () {
                          if (_currentStep == 2 && !isNagpurValid) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please choose a location inside Nagpur.')),
                            );
                            return;
                          }
                          setState(() => _currentStep++);
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Continue'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _submitReport,
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Register Grievance'),
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
