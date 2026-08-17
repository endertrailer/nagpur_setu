import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import '../services/complaints_repository.dart';
import '../services/vision_classifier.dart';
import '../utils/geo_utils.dart';

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
  final String _photoUrl = 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=800&auto=format&fit=crop&q=80';
  String _category = 'Pothole';
  bool _isClassifying = false;
  ClassificationResult? _aiResult;

  final TextEditingController _landmarkController = TextEditingController(text: 'Coffee House Square, West High Court Rd, Dharampeth');
  final TextEditingController _descriptionController = TextEditingController();
  double _lat = 21.1432;
  double _lng = 79.0620;

  final TextEditingController _locationSearchController = TextEditingController();
  List<NagpurLocation> _searchSuggestions = [];

  final TextEditingController _phoneController = TextEditingController(text: '9823012345');
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  bool _isPhoneVerified = false;
  String _phoneHash = '';

  Map<String, dynamic>? _duplicateAlert;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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

  void _detectLocation() {
    setState(() {
      _lat = 21.1458;
      _lng = 79.0882;
      _landmarkController.text = 'Zero Mile Stone, Civil Lines, Nagpur';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📍 Location detected within Nagpur (GPS: 21.1458, 79.0882)')),
    );
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
      _landmarkController.text = loc.name;
      _locationSearchController.text = loc.name;
      _searchSuggestions = [];
    });
    _checkDuplicates();
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
    setState(() {
      _phoneHash = hash;
      _isPhoneVerified = true;
    });
  }

  void _submitReport() {
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
      setState(() => _errorMessage = result['message']);
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
            Text('Report Submitted!', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
              if (widget.onReportSuccess != null) {
                widget.onReportSuccess!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
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
      backgroundColor: const Color(0xFFFDFAF6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: Text(
          'Report Civic Issue',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1C1C)),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Step $_currentStep/3',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[500]),
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
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 20),

                // STEP 1: Photo & Category
                if (_currentStep == 1) ...[
                  Text(
                    'Photo Proof',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1C1C)),
                  ),
                  const SizedBox(height: 8),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        Image.network(
                          _photoUrl,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        if (_isClassifying)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black54,
                              child: const Center(
                                child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (_aiResult != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFF6B00)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFFF6B00), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI Suggested: ${_aiResult!.suggestedCategory} (${(_aiResult!.confidence * 100).round()}% match)',
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFFF6B00)),
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
                  const SizedBox(height: 16),

                  Text(
                    'Select Category',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1C1C)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kCivicCategories.map((cat) {
                      final isSelected = _category.toLowerCase() == cat.id.toLowerCase();
                      return GestureDetector(
                        onTap: () {
                          setState(() => _category = cat.id);
                          _checkDuplicates();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF6B00) : Colors.grey[300]!,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(cat.icon, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                cat.id,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // STEP 2: Location (Detect GPS & Search Nagpur)
                if (_currentStep == 2) ...[
                  // Detect GPS Button
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFF6B00)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, color: Color(0xFFFF6B00), size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Detect User GPS (Nagpur)', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
                              Text('GPS: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _detectLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFFF6B00),
                            elevation: 0,
                            side: const BorderSide(color: Color(0xFFFF6B00)),
                          ),
                          child: const Text('Detect GPS', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Location
                  Text(
                    'Search Nagpur Landmark',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _locationSearchController,
                    onChanged: _searchNagpurLocation,
                    decoration: InputDecoration(
                      hintText: 'Search Sitabuldi, Dharampeth, Sadar...',
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
                      ),
                      child: Column(
                        children: _searchSuggestions.map((loc) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, color: Color(0xFFFF6B00), size: 18),
                            title: Text(loc.name, style: GoogleFonts.inter(fontSize: 12)),
                            onTap: () => _selectLocation(loc),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16),

                  Text(
                    'Street / Landmark Description',
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
                    'Issue Details',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Describe traffic impact or hazard...',
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
                      child: Text('❌ Location is outside Nagpur Municipal limits. Please select a spot inside Nagpur.', style: TextStyle(color: Colors.red[800], fontSize: 12)),
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
                            Text('Citizen Phone Verification', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Phone OTP blocks spam bots. Numbers are SHA-256 hashed for privacy.',
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
                          backgroundColor: const Color(0xFFFF6B00),
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
                      child: Text('✓ Phone Verified (SHA-256 Hashed)', style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold)),
                    ),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Text(_errorMessage!, style: TextStyle(color: Colors.red[900], fontSize: 12)),
                    ),
                ],

                const SizedBox(height: 30),

                // Step Buttons
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
                          backgroundColor: const Color(0xFFFF6B00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _submitReport,
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Verify & Submit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B00),
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
              colors: const [Color(0xFFFF6B00), Colors.green, Colors.amber, Colors.blue],
            ),
          ),
        ],
      ),
    );
  }
}
