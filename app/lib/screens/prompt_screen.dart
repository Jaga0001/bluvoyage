import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/apis/api_func.dart';
import 'package:app/db/db_func.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class PromptScreen extends StatefulWidget {
  const PromptScreen({super.key});

  @override
  State<PromptScreen> createState() => _PromptScreenState();
}

class _PromptScreenState extends State<PromptScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late AnimationController _formController;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _backgroundAnimation;
  late Animation<double> _formAnimation;

  // Single form controller for the prompt
  final TextEditingController _promptController = TextEditingController();
  final ApiFunc _apiFunc = ApiFunc();
  final DbFunc _dbFunc = DbFunc();
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);
    _particleController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _backgroundAnimation =
        ColorTween(begin: Color(0xFFF8FAFC), end: Color(0xFFF1F5F9)).animate(
          CurvedAnimation(
            parent: _backgroundController,
            curve: Curves.easeInOut,
          ),
        );

    _formAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _formController, curve: Curves.easeOutBack),
    );

    _fadeController.forward();
    _formController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    _formController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800 && screenWidth <= 1200;
    final isSmallScreen = screenWidth <= 800;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(color: _backgroundAnimation.value),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(
                  10,
                  (index) => AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      final progress =
                          (_particleController.value + index * 0.1) % 1.0;
                      final size = 2.0 + (index % 3) * 1.5;
                      final opacity = (0.02 + (index % 4) * 0.01);

                      return Positioned(
                        left:
                            (screenWidth * (0.1 + (index % 7) * 0.12)) +
                            math.sin(progress * 2 * math.pi + index) * 50,
                        top: MediaQuery.of(context).size.height * progress,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: Color(0xFF3B82F6).withOpacity(opacity),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // Top App Bar
                        _buildTopAppBar(isMediumScreen),

                        // Main Content
                        Expanded(
                          child: isMediumScreen
                              ? Row(
                                  children: [
                                    // Sidebar for medium screens
                                    if (!isSmallScreen)
                                      Container(
                                        width: 280,
                                        color: Colors.white.withOpacity(0.95),
                                        child: _buildSidebar(),
                                      ),
                                    // Main form area
                                    Expanded(
                                      child: _buildMainContent(
                                        isLargeScreen,
                                        isMediumScreen,
                                      ),
                                    ),
                                  ],
                                )
                              : _buildMainContent(
                                  isLargeScreen,
                                  isMediumScreen,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(bool isMediumScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Container(
      height: isLargeScreen ? 90 : 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 32 : 24),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Color(0xFF1E40AF),
                size: isLargeScreen ? 28 : 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            SizedBox(width: isLargeScreen ? 24 : 16),
            Expanded(
              child: Text(
                'Plan Your Journey',
                style: GoogleFonts.montserrat(
                  fontSize: isLargeScreen ? 28 : 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(bool isLargeScreen, bool isMediumScreen) {
    return Center(
      child: Container(
        width: isLargeScreen
            ? 800
            : (isMediumScreen ? double.infinity : double.infinity),
        margin: EdgeInsets.all(isLargeScreen ? 32 : 24),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.3),
            end: Offset.zero,
          ).animate(_formAnimation),
          child: FadeTransition(
            opacity: _formAnimation,
            child: _buildMainCard(isLargeScreen),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.travel_explore, color: Colors.white, size: 32),
          ),
          SizedBox(height: 24),
          Text(
            'BluVoyage',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E40AF),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'AI-Powered Journey Planning',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
          ),
          SizedBox(height: 32),
          _buildSidebarInfo('Travel Preferences', 'Tell us what interests you'),
          SizedBox(height: 24),
          _buildSidebarInfo('AI Analysis', 'We personalize your itinerary'),
          SizedBox(height: 24),
          _buildSidebarInfo('Get Exploring', 'Download your perfect plan'),
        ],
      ),
    );
  }

  Widget _buildSidebarInfo(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E40AF),
          ),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildMainCard(bool isLargeScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMediumScreen = screenWidth > 800 && screenWidth <= 1200;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isLargeScreen ? 28 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // Form Content
          Expanded(
            child: _buildPromptPage(
              isLargeScreen,
              isMediumScreen: isMediumScreen,
            ),
          ),

          // Generate Button
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildPromptPage(bool isLargeScreen, {bool isMediumScreen = false}) {
    final padding = isLargeScreen ? 40 : (isMediumScreen ? 32 : 28);

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding.toDouble()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildPageHeader(
            "Tell us about your perfect trip",
            "Describe your travel desires in one sentence",
            Icons.edit_outlined,
            isLargeScreen: isLargeScreen,
          ),

          SizedBox(height: isLargeScreen ? 40 : 32),

          // Prompt Field - moved up to be first
          _buildPromptField(isLargeScreen),

          SizedBox(height: isLargeScreen ? 40 : 32),

          // Example sentences as clickable buttons
          _buildExampleButtonsSection(isLargeScreen),
        ],
      ),
    );
  }

  Widget _buildPromptField(bool isLargeScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _promptController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'I want to go to...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(isLargeScreen ? 24 : 20),
          hintStyle: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: isLargeScreen ? 17 : 16,
            height: 1.5,
          ),
        ),
        style: GoogleFonts.inter(
          fontSize: isLargeScreen ? 17 : 16,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildExampleButtonsSection(bool isLargeScreen) {
    final examples = [
      "I want to go to Chennai for 3 days I love Frank Ocean, Studio Ghibli films, and Japanese streetwear.",
      "My vibe is Taylor Swift, classic romantic films, and matcha desserts.",
      "I want a relaxing beach vacation with seafood and water activities.",
      "Plan a cultural tour in Kyoto with traditional experiences.",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try these examples:',
          style: GoogleFonts.inter(
            fontSize: isLargeScreen ? 17 : 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B82F6),
          ),
        ),
        SizedBox(height: isLargeScreen ? 20 : 16),
        ...examples
            .map(
              (example) => GestureDetector(
                onTap: () {
                  setState(() {
                    _promptController.text = example;
                  });
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: isLargeScreen ? 16 : 12),
                  padding: EdgeInsets.all(isLargeScreen ? 20 : 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF3B82F6).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          example,
                          style: GoogleFonts.inter(
                            fontSize: isLargeScreen ? 15 : 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildPageHeader(
    String title,
    String subtitle,
    IconData icon, {
    bool isLargeScreen = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isLargeScreen ? 100 : 80,
          height: isLargeScreen ? 100 : 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
            ),
            borderRadius: BorderRadius.circular(isLargeScreen ? 24 : 20),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, size: isLargeScreen ? 50 : 40, color: Colors.white),
        ),
        SizedBox(height: isLargeScreen ? 32 : 24),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: isLargeScreen ? 32 : 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E40AF),
          ),
        ),
        SizedBox(height: isLargeScreen ? 16 : 12),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: isLargeScreen ? 17 : 16,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Container(
      padding: EdgeInsets.all(isLargeScreen ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: isLargeScreen ? 56 : 48,
        child: ElevatedButton(
          onPressed: _isGenerating ? null : _generateTravelPlan,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isGenerating ? Colors.grey : Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
          ),
          child: _isGenerating
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Generating...',
                      style: GoogleFonts.inter(
                        fontSize: isLargeScreen ? 17 : 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Generate My Travel Plan',
                  style: GoogleFonts.inter(
                    fontSize: isLargeScreen ? 17 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  void _generateTravelPlan() async {
    // Validate prompt field
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please describe your travel plans'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    // Show beautiful loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildBeautifulLoadingDialog(),
    );

    try {
      // Retry logic with exponential backoff
      dynamic travelPlan;
      int maxRetries = 3;
      int retryDelay = 1; // seconds

      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          print('API call attempt $attempt/$maxRetries');

          travelPlan = await _apiFunc
              .generateItinerary(_promptController.text.trim())
              .timeout(
                Duration(seconds: 30), // 30 second timeout
                onTimeout: () {
                  throw Exception('Request timed out. Please try again.');
                },
              );

          // If we get here, the call was successful
          break;
        } catch (e) {
          print('Attempt $attempt failed: $e');

          if (attempt == maxRetries) {
            // Last attempt failed, rethrow the error
            rethrow;
          }

          // Wait before retrying (exponential backoff)
          await Future.delayed(Duration(seconds: retryDelay));
          retryDelay *= 2; // Double the delay for next attempt
        }
      }

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (travelPlan != null) {
          // Save to Firestore
          bool saved = await _dbFunc.saveTravelPlan(travelPlan);

          if (saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Travel plan generated successfully! Reloading...',
                ),
                backgroundColor: Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: Duration(seconds: 2),
              ),
            );

            // Wait a moment for the snackbar to show, then restart the app
            await Future.delayed(Duration(seconds: 2));
            _restartApp();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Travel plan generated but failed to save. Please try again.',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Unable to generate travel plan. Please try again.',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _generateTravelPlan: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        String errorMessage;
        if (e.toString().contains('timed out')) {
          errorMessage =
              'Request timed out. Please check your connection and try again.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else {
          errorMessage = 'Something went wrong. Please try again in a moment.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _restartApp() {
    // For Flutter apps, we can restart by exiting and letting the system restart
    // or by navigating to root and clearing the stack
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/', // Assuming your home route is '/'
      (route) => false,
    );
  }

  Widget _buildBeautifulLoadingDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: _BeautifulLoadingWidget(),
    );
  }
}

class _BeautifulLoadingWidget extends StatefulWidget {
  @override
  _BeautifulLoadingWidgetState createState() => _BeautifulLoadingWidgetState();
}

class _BeautifulLoadingWidgetState extends State<_BeautifulLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _particleController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: Duration(seconds: 6),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 280, maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF3B82F6).withOpacity(0.15),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Floating particles (limit to 5 for better performance)
                ...List.generate(5, (index) => _buildFloatingParticle(index)),

                // Main content
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 10),

                      // Main loading ring with icon
                      _buildMainLoadingRing(),

                      SizedBox(height: 24),

                      // Loading text with animation
                      _buildLoadingText(),

                      SizedBox(height: 8),

                      // Subtitle
                      _buildSubtitle(),

                      SizedBox(height: 16),

                      // Progress dots
                      _buildProgressDots(),

                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + index * 0.125) % 1.0;
        final size = 4.0 + (index % 3) * 2.0;
        final opacity = 0.3 + (index % 4) * 0.1;
        final radius = 80.0 + (index % 3) * 20.0;
        final angle = (index * math.pi / 4) + (progress * 2 * math.pi);

        return Positioned(
          left: 140 + math.cos(angle) * radius,
          top: 160 + math.sin(angle) * radius,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Color(0xFF3B82F6).withOpacity(opacity),
                  Color(0xFF8B5CF6).withOpacity(opacity * 0.5),
                ],
              ),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainLoadingRing() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer rotating ring
        AnimatedBuilder(
          animation: _rotationAnimation,
          builder: (context, child) => Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.transparent,
                    Color(0xFF3B82F6).withOpacity(0.8),
                    Color(0xFF8B5CF6).withOpacity(0.9),
                    Color(0xFFEC4899).withOpacity(0.8),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ),

        // Inner pulsing circle with icon
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) => Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF3B82F6).withOpacity(0.25),
                    blurRadius: 25,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.flight_takeoff,
                size: 36,
                color: Color(0xFF3B82F6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingText() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) => Transform.scale(
        scale: 0.98 + (_pulseAnimation.value - 1) * 0.02,
        child: Text(
          'Crafting Your Dream Journey',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Our AI is curating the perfect\nexperiences just for you',
      style: GoogleFonts.inter(
        fontSize: 14,
        color: Color(0xFF64748B),
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildProgressDots() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            final progress =
                (_rotationController.value * 2 + index * 0.25) % 1.0;
            final opacity = (math.sin(progress * math.pi) * 0.5 + 0.5);
            final scale = 0.6 + (opacity * 0.4);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
