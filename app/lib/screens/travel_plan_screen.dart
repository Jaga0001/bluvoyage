import 'package:app/models/travel_model.dart';
import 'package:app/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

class TravelPlanScreen extends StatefulWidget {
  final TravelPlan travelPlan;

  const TravelPlanScreen({super.key, required this.travelPlan});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _backgroundAnimation;

  int selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _backgroundAnimation =
        ColorTween(
          begin: const Color(0xFFF8FAFC),
          end: const Color(0xFFEFF6FF),
        ).animate(
          CurvedAnimation(
            parent: _backgroundController,
            curve: Curves.easeInOutSine,
          ),
        );

    _fadeController.forward();
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
    final isDesktop = screenWidth > 1024;
    final isMobile = screenWidth <= 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _backgroundAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(color: _backgroundAnimation.value),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(
                  8,
                  (index) => AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      final progress =
                          (_particleController.value + index * 0.15) % 1.0;
                      final size = 3.0 + (index % 3) * 1.5;
                      final opacity = (0.015 + (index % 4) * 0.01);

                      return Positioned(
                        left:
                            (screenWidth * (0.1 + (index % 6) * 0.15)) +
                            math.sin(progress * 2 * math.pi + index) * 50,
                        top: MediaQuery.of(context).size.height * progress,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: opacity),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // Responsive Top App Bar
                        _buildTopAppBar(isMobile),

                        // Mobile/Tablet Horizontal Day Selector
                        if (!isDesktop &&
                            widget.travelPlan.itinerary.days.isNotEmpty)
                          _buildHorizontalDaySelector(),

                        // Main Content Area
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Sidebar for desktop only
                              if (isDesktop) _buildDaySidebar(),

                              // Main activity content
                              Expanded(
                                child: _buildMainContent(isDesktop, isMobile),
                              ),
                            ],
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

  Widget _buildTopAppBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF1E40AF),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          SizedBox(width: isMobile ? 12 : 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.travelPlan.title,
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 16 : 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.travelPlan.destination} • ${widget.travelPlan.duration}',
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 12 : 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? 8 : 16),
          _buildDownloadButton(isMobile),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
          onTap: () => _downloadPdf(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 8 : 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                  size: isMobile ? 16 : 18,
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Export PDF',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _downloadPdf() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
                const SizedBox(height: 16),
                Text(
                  'Generating PDF...',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await PdfService.generateAndDownloadTravelPlan(widget.travelPlan);

      if (!mounted) return;
      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF downloaded successfully!',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Close loading dialog if still open
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error generating PDF: ${e.toString()}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _openMapsLocation(String mapsLink) async {
    if (mapsLink.isNotEmpty) {
      final Uri url = Uri.parse(mapsLink);
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Could not open maps location',
                  style: GoogleFonts.inter(color: Colors.white),
                ),
                backgroundColor: Colors.red.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error opening maps: ${e.toString()}',
                style: GoogleFonts.inter(color: Colors.white),
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  Widget _buildHorizontalDaySelector() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: widget.travelPlan.itinerary.days.length,
        itemBuilder: (context, index) {
          final isSelected = selectedDay == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ChoiceChip(
              label: Text(
                'Day ${widget.travelPlan.itinerary.days[index].day_number}',
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => selectedDay = index);
              },
              selectedColor: const Color(0xFF3B82F6),
              backgroundColor: Colors.grey.shade100,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDaySidebar() {
    if (widget.travelPlan.itinerary.days.isEmpty) {
      return Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Center(
          child: Text(
            'No itinerary data',
            style: GoogleFonts.inter(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Itinerary',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.travelPlan.itinerary.duration_days} days in ${widget.travelPlan.destination}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: widget.travelPlan.itinerary.days.length,
              itemBuilder: (context, index) {
                final day = widget.travelPlan.itinerary.days[index];
                final isSelected = selectedDay == index;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                        ? const Color(0xFFEFF6FF)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFBFDBFE)
                          : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF3B82F6)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day_number}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'Day ${day.day_number}',
                      style: GoogleFonts.inter(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1E3A8A)
                            : const Color(0xFF334155),
                      ),
                    ),
                    subtitle: Text(
                      day.theme,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => setState(() => selectedDay = index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDesktop, bool isMobile) {
    if (widget.travelPlan.itinerary.days.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No activities planned',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    if (selectedDay >= widget.travelPlan.itinerary.days.length) {
      selectedDay = 0;
    }
    final currentDay = widget.travelPlan.itinerary.days[selectedDay];

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : (isDesktop ? 40 : 24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayHeader(currentDay, isMobile),
          SizedBox(height: isMobile ? 24 : 40),
          _buildActivitiesList(currentDay.activities, isMobile),
        ],
      ),
    );
  }

  Widget _buildDayHeader(TravelDay day, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1488085061387-422e29b40080?q=80&w=2000&auto=format&fit=crop',
          ), // Optional abstract subtle background
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Color(0xFF1E3A8A), BlendMode.multiply),
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isMobile ? 50 : 64,
            height: isMobile ? 50 : 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '${day.day_number}',
                style: GoogleFonts.montserrat(
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 16 : 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${day.day_number}',
                  style: GoogleFonts.montserrat(
                    fontSize: isMobile ? 22 : 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  day.theme,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList(List<Activity> activities, bool isMobile) {
    return Column(
      children: activities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        final isLast = index == activities.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline Column
              SizedBox(
                width: isMobile ? 40 : 60,
                child: Column(
                  children: [
                    Container(
                      width: isMobile ? 36 : 48,
                      height: isMobile ? 36 : 48,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(activity.category),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(
                              activity.category,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(activity.category),
                        color: Colors.white,
                        size: isMobile ? 16 : 20,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey.shade200,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? 12 : 24),
              // Activity Card
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast ? 0 : (isMobile ? 24.0 : 32.0),
                  ),
                  child: Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header: Time & Category
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildChip(
                              activity.time,
                              const Color(0xFF3B82F6),
                              Icons.access_time,
                            ),
                            _buildChip(
                              activity.category.toUpperCase(),
                              _getCategoryColor(activity.category),
                              _getCategoryIcon(activity.category),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),

                        // Title & Location
                        Text(
                          activity.location.name,
                          style: GoogleFonts.montserrat(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        if (activity.location.address.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  activity.location.address,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: isMobile ? 12 : 16),

                        // Description
                        Text(
                          activity.description,
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 14 : 15,
                            color: const Color(0xFF475569),
                            height: 1.6,
                          ),
                        ),

                        // Action Buttons / Cultural Connection
                        if (activity.culturalConnection.isNotEmpty ||
                            activity.location.maps_link.isNotEmpty)
                          SizedBox(height: isMobile ? 16 : 20),

                        if (activity.culturalConnection.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFFF59E0B),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activity.culturalConnection,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: const Color(0xFF64748B),
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (activity.location.maps_link.isNotEmpty) ...[
                          if (activity.culturalConnection.isNotEmpty)
                            const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _openMapsLocation(
                                activity.location.maps_link,
                              ),
                              icon: const Icon(Icons.map_outlined, size: 16),
                              label: Text(
                                'Open Map',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF2563EB),
                                backgroundColor: const Color(0xFFEFF6FF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'music':
        return const Color(0xFF8B5CF6);
      case 'film':
        return const Color(0xFFF59E0B);
      case 'fashion':
        return const Color(0xFFEC4899);
      case 'dining':
        return const Color(0xFF10B981);
      case 'hidden_gem':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'music':
        return Icons.headphones;
      case 'film':
        return Icons.movie_creation;
      case 'fashion':
        return Icons.checkroom;
      case 'dining':
        return Icons.restaurant;
      case 'hidden_gem':
        return Icons.diamond;
      default:
        return Icons.place;
    }
  }
}
