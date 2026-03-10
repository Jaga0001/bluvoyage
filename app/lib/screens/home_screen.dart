import 'package:app/auth/google_auth.dart';
import 'package:app/models/travel_model.dart';
import 'package:app/screens/login_screen.dart';
import 'package:app/screens/travel_plan_screen.dart';
import 'package:app/screens/prompt_screen.dart';
import 'package:app/db/db_func.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _backgroundAnimation;

  // Remove sample travel plan and use empty list
  List<TravelPlan> travelPlans = [];
  final DbFunc _dbFunc = DbFunc();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat(reverse: true);
    _particleController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

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

    _fadeController.forward();
    _loadTravelPlans();
  }

  // Load travel plans from Firestore
  Future<void> _loadTravelPlans() async {
    try {
      final plans = await _dbFunc.getTravelPlans();
      if (mounted) {
        setState(() {
          travelPlans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading travel plans: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800 && screenWidth <= 1200;
    final showPermanentDrawer = screenWidth > 1000;

    return Scaffold(
      body: Row(
        children: [
          // Permanent Sidebar for larger screens
          if (showPermanentDrawer) _buildPermanentSidebar(),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                _buildTopAppBar(showPermanentDrawer),

                // Main Content
                Expanded(
                  child: AnimatedBuilder(
                    animation: _backgroundAnimation,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          color: _backgroundAnimation.value,
                        ),
                        child: Stack(
                          children: [
                            // Animated background particles
                            ...List.generate(
                              8,
                              (index) => AnimatedBuilder(
                                animation: _particleController,
                                builder: (context, child) {
                                  final progress =
                                      (_particleController.value +
                                          index * 0.15) %
                                      1.0;
                                  final size = 3.0 + (index % 2) * 1.5;
                                  final opacity = (0.03 + (index % 3) * 0.02);

                                  return Positioned(
                                    left:
                                        (screenWidth *
                                            (0.1 + (index % 6) * 0.15)) +
                                        math.sin(
                                              progress * 2 * math.pi + index,
                                            ) *
                                            30,
                                    top:
                                        MediaQuery.of(context).size.height *
                                        progress,
                                    child: Container(
                                      width: size,
                                      height: size,
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFF3B82F6,
                                        ).withOpacity(opacity),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Padding(
                                padding: EdgeInsets.all(
                                  isLargeScreen ? 32 : 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Welcome Section
                                    _buildWelcomeSection(isLargeScreen),
                                    SizedBox(height: 32),

                                    // Travel Plans Section
                                    Expanded(
                                      child: _isLoading
                                          ? _buildLoadingState()
                                          : travelPlans.isEmpty
                                          ? _buildEmptyState(isLargeScreen)
                                          : _buildTravelPlansGrid(
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
                ),
              ],
            ),
          ),
        ],
      ),
      // Mobile drawer for smaller screens
      drawer: !showPermanentDrawer ? _buildMobileDrawer(context) : null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToPromptPage,
        backgroundColor: Color(0xFF3B82F6),
        icon: Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Plan',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildTopAppBar(bool showPermanentDrawer) {
    return Container(
      height: 70,
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
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            if (!showPermanentDrawer) ...[
              Builder(
                builder: (context) => IconButton(
                  icon: Icon(Icons.menu, color: Color(0xFF1E40AF)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              SizedBox(width: 16),
            ],
            Text(
              showPermanentDrawer ? 'Dashboard' : 'BluVoyage',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E40AF),
              ),
            ),
            Spacer(),
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Color(0xFF1E40AF),
              ),
              onPressed: () {},
            ),
            SizedBox(width: 16),
            CircleAvatar(
              backgroundColor: Color(0xFF3B82F6),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermanentSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Sidebar Header
            Container(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.sailing,
                      size: 40,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'BluVoyage',
                    style: GoogleFonts.montserrat(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'AI Travel Planner',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: Colors.white.withOpacity(0.3), thickness: 1),

            // Navigation Menu
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                children: [
                  _buildSidebarItem(
                    Icons.dashboard_outlined,
                    'Dashboard',
                    true,
                    () {},
                  ),

                  _buildSidebarItem(Icons.logout, 'Sign Out', true, () {
                    signOutGoogle();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(
    IconData icon,
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Drawer Header
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sailing,
                        size: 40,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'BluVoyage',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Travel Planner',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white.withOpacity(0.3)),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  children: [
                    _buildDrawerItem(
                      Icons.home_outlined,
                      'Home',
                      true,
                      () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      Icons.map_outlined,
                      'My Plans',
                      false,
                      () {},
                    ),
                    _buildDrawerItem(
                      Icons.favorite_outline,
                      'Favorites',
                      false,
                      () {},
                    ),
                    _buildDrawerItem(Icons.history, 'History', false, () {}),
                    _buildDrawerItem(
                      Icons.settings_outlined,
                      'Settings',
                      false,
                      () {},
                    ),
                    SizedBox(height: 32),
                    _buildDrawerItem(
                      Icons.help_outline,
                      'Help & Support',
                      false,
                      () {},
                    ),
                    _buildDrawerItem(Icons.logout, 'Sign Out', false, () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isLargeScreen) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: GoogleFonts.inter(
                    fontSize: isLargeScreen ? 32 : 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ready to plan your next adventure?',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.explore, size: 40, color: Color(0xFF3B82F6)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF3B82F6)),
            SizedBox(height: 24),
            Text(
              'Loading your travel plans...',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isLargeScreen) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.map_outlined,
                size: 60,
                color: Color(0xFF3B82F6),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No travel plans yet',
              style: GoogleFonts.inter(
                fontSize: isLargeScreen ? 24 : 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E40AF),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Start planning your dream vacation with AI assistance',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _navigateToPromptPage,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'Create Your First Plan',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B82F6),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelPlansGrid(bool isLargeScreen, bool isMediumScreen) {
    int crossAxisCount = isLargeScreen ? 3 : (isMediumScreen ? 2 : 1);
    double spacing = isLargeScreen ? 24 : 16;
    double childAspectRatio = isLargeScreen ? 1.15 : 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Travel Plans',
          style: GoogleFonts.inter(
            fontSize: isLargeScreen ? 28 : 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E40AF),
          ),
        ),
        SizedBox(height: isLargeScreen ? 24 : 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: travelPlans.length,
            itemBuilder: (context, index) {
              return _buildTravelPlanCard(travelPlans[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTravelPlanCard(TravelPlan plan) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TravelPlanScreen(travelPlan: plan),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  child: _buildPlanImage(plan.travel_image),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E40AF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      plan.destination,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      plan.duration,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Color(0xFF3B82F6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanImage(String imageUrl) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'Travel Plan',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToPromptPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PromptScreen()),
    );

    if (result != null && result is TravelPlan) {
      // Refresh the travel plans list
      _loadTravelPlans();
    }
  }
}
