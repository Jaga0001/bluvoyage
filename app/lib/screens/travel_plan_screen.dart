import 'package:app/models/travel_model.dart';
import 'package:app/services/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

// ─── Color Palette ────────────────────────────────────────────────────────────
class _Palette {
  static const ink = Color(0xFF0A0E1A);
  static const inkLight = Color(0xFF1C2436);
  static const slate = Color(0xFF3D4A6B);
  static const muted = Color(0xFF8896B3);
  static const surface = Color(0xFFF4F6FB);
  static const accent = Color(0xFF4F7FFF);
  static const accentDeep = Color(0xFF2952CC);
  static const gold = Color(0xFFE8A838);
  static const emerald = Color(0xFF2EC87A);
  static const rose = Color(0xFFFF5C87);
  static const violet = Color(0xFF9B5DE5);
  static const sky = Color(0xFF00C2FF);
  static const divider = Color(0xFFE8EDF6);
}

// ─── Category Config ──────────────────────────────────────────────────────────
class _CategoryStyle {
  final Color color;
  final IconData icon;
  final String label;
  const _CategoryStyle(this.color, this.icon, this.label);
}

const _categoryMap = {
  'music': _CategoryStyle(_Palette.violet, Icons.headphones_rounded, 'MUSIC'),
  'film': _CategoryStyle(_Palette.gold, Icons.movie_creation_rounded, 'FILM'),
  'fashion': _CategoryStyle(_Palette.rose, Icons.checkroom_rounded, 'FASHION'),
  'dining': _CategoryStyle(_Palette.emerald, Icons.restaurant_rounded, 'DINING'),
  'hidden_gem': _CategoryStyle(_Palette.sky, Icons.diamond_rounded, 'GEM'),
};

_CategoryStyle _cat(String c) =>
    _categoryMap[c.toLowerCase()] ??
    const _CategoryStyle(_Palette.slate, Icons.place_rounded, 'PLACE');

// ─── Screen ───────────────────────────────────────────────────────────────────
class TravelPlanScreen extends StatefulWidget {
  final TravelPlan travelPlan;
  const TravelPlanScreen({super.key, required this.travelPlan});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen>
    with TickerProviderStateMixin {
  // Controllers
  late final AnimationController _enterCtrl;
  late final AnimationController _orbCtrl;
  late final AnimationController _dayTransCtrl;
  late final ScrollController _scrollCtrl;

  late final Animation<double> _enterFade;
  late final Animation<Offset> _enterSlide;
  late final Animation<double> _dayTransFade;

  int _selectedDay = 0;
  bool _appBarElevated = false;

  @override
  void initState() {
    super.initState();

    _scrollCtrl = ScrollController()
      ..addListener(() {
        final elevated = _scrollCtrl.offset > 8;
        if (elevated != _appBarElevated) setState(() => _appBarElevated = elevated);
      });

    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
    _dayTransCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));

    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterSlide = Tween(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _dayTransFade = CurvedAnimation(parent: _dayTransCtrl, curve: Curves.easeInOut);

    _enterCtrl.forward();
    _dayTransCtrl.value = 1.0;
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _orbCtrl.dispose();
    _dayTransCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _selectDay(int index) {
    if (index == _selectedDay) return;
    _dayTransCtrl.reverse().then((_) {
      setState(() => _selectedDay = index);
      _dayTransCtrl.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isDesktop = w > 1100;
    final isTablet = w > 680 && w <= 1100;

    return Scaffold(
      backgroundColor: _Palette.surface,
      body: FadeTransition(
        opacity: _enterFade,
        child: SlideTransition(
          position: _enterSlide,
          child: Stack(
            children: [
              // ── Ambient orb background ──
              _AmbientOrbs(controller: _orbCtrl),

              // ── Main layout ──
              SafeArea(
                child: Column(
                  children: [
                    _TopBar(
                      plan: widget.travelPlan,
                      elevated: _appBarElevated,
                      onBack: () => Navigator.pop(context),
                      onExport: _downloadPdf,
                    ),
                    Expanded(
                      child: isDesktop
                          ? _DesktopLayout(
                              plan: widget.travelPlan,
                              selectedDay: _selectedDay,
                              onDaySelect: _selectDay,
                              fadeAnim: _dayTransFade,
                              scrollCtrl: _scrollCtrl,
                            )
                          : _MobileTabletLayout(
                              plan: widget.travelPlan,
                              selectedDay: _selectedDay,
                              onDaySelect: _selectDay,
                              fadeAnim: _dayTransFade,
                              scrollCtrl: _scrollCtrl,
                              isTablet: isTablet,
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

  Future<void> _downloadPdf() async {
    final overlay = OverlayEntry(
      builder: (_) => const _LoadingOverlay(),
    );
    Overlay.of(context).insert(overlay);
    try {
      await PdfService.generateAndDownloadTravelPlan(widget.travelPlan);
      overlay.remove();
      if (!mounted) return;
      _showSnack('PDF exported successfully ✓', _Palette.emerald);
    } catch (e) {
      overlay.remove();
      if (!mounted) return;
      _showSnack('Export failed: ${e.toString()}', _Palette.rose);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }
}

// ─── Ambient Orb Background ───────────────────────────────────────────────────
class _AmbientOrbs extends StatelessWidget {
  final AnimationController controller;
  const _AmbientOrbs({required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value * 2 * math.pi;
        return Stack(children: [
          _orb(
            left: size.width * 0.65 + math.sin(t * 0.7) * 40,
            top: -60 + math.cos(t * 0.5) * 30,
            diameter: 340,
            color: _Palette.accent.withOpacity(0.07),
          ),
          _orb(
            left: -80 + math.cos(t * 0.4) * 25,
            top: size.height * 0.35 + math.sin(t * 0.6) * 40,
            diameter: 280,
            color: _Palette.violet.withOpacity(0.05),
          ),
          _orb(
            left: size.width * 0.3 + math.sin(t * 0.3) * 30,
            top: size.height * 0.72 + math.cos(t * 0.5) * 20,
            diameter: 200,
            color: _Palette.sky.withOpacity(0.06),
          ),
        ]);
      },
    );
  }

  Widget _orb({
    required double left,
    required double top,
    required double diameter,
    required Color color,
  }) =>
      Positioned(
        left: left,
        top: top,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      );
}

// ─── Top Bar ─────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final TravelPlan plan;
  final bool elevated;
  final VoidCallback onBack;
  final VoidCallback onExport;
  const _TopBar({
    required this.plan,
    required this.elevated,
    required this.onBack,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w <= 600;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 28, vertical: compact ? 12 : 16),
      decoration: BoxDecoration(
        color: elevated
            ? Colors.white.withOpacity(0.92)
            : Colors.transparent,
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: _Palette.ink.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: elevated
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: _barContent(compact),
              ),
            )
          : _barContent(compact),
    );
  }

  Widget _barContent(bool compact) => Row(
        children: [
          // Back button
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          SizedBox(width: compact ? 12 : 20),

          // Title block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: compact ? 17 : 22,
                    fontWeight: FontWeight.w700,
                    color: _Palette.ink,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_rounded, size: 12, color: _Palette.muted),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${plan.destination}  ·  ${plan.duration}',
                        style: GoogleFonts.poppins(
                          fontSize: compact ? 11 : 13,
                          color: _Palette.muted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 16),

          // Export button
          _ExportButton(compact: compact, onTap: onExport),
        ],
      );
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _Palette.ink.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _Palette.ink, size: 18),
        ),
      );
}

class _ExportButton extends StatelessWidget {
  final bool compact;
  final VoidCallback onTap;
  const _ExportButton({required this.compact, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 18, vertical: compact ? 9 : 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_Palette.accent, _Palette.accentDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: _Palette.accent.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 16),
              if (!compact) ...[
                const SizedBox(width: 8),
                Text(
                  'Export PDF',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2),
                ),
              ],
            ],
          ),
        ),
      );
}

// ─── Desktop Layout ───────────────────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final TravelPlan plan;
  final int selectedDay;
  final void Function(int) onDaySelect;
  final Animation<double> fadeAnim;
  final ScrollController scrollCtrl;
  const _DesktopLayout({
    required this.plan,
    required this.selectedDay,
    required this.onDaySelect,
    required this.fadeAnim,
    required this.scrollCtrl,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          SizedBox(
            width: 280,
            child: _DaySidebar(
              plan: plan,
              selectedDay: selectedDay,
              onDaySelect: onDaySelect,
            ),
          ),
          // Content
          Expanded(
            child: _DayContent(
              plan: plan,
              selectedDay: selectedDay,
              fadeAnim: fadeAnim,
              scrollCtrl: scrollCtrl,
              isDesktop: true,
            ),
          ),
        ],
      );
}

// ─── Mobile / Tablet Layout ───────────────────────────────────────────────────
class _MobileTabletLayout extends StatelessWidget {
  final TravelPlan plan;
  final int selectedDay;
  final void Function(int) onDaySelect;
  final Animation<double> fadeAnim;
  final ScrollController scrollCtrl;
  final bool isTablet;
  const _MobileTabletLayout({
    required this.plan,
    required this.selectedDay,
    required this.onDaySelect,
    required this.fadeAnim,
    required this.scrollCtrl,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _HorizontalDayRail(
              plan: plan, selectedDay: selectedDay, onDaySelect: onDaySelect),
          Expanded(
            child: _DayContent(
              plan: plan,
              selectedDay: selectedDay,
              fadeAnim: fadeAnim,
              scrollCtrl: scrollCtrl,
              isDesktop: false,
            ),
          ),
        ],
      );
}

// ─── Day Sidebar (Desktop) ────────────────────────────────────────────────────
class _DaySidebar extends StatelessWidget {
  final TravelPlan plan;
  final int selectedDay;
  final void Function(int) onDaySelect;
  const _DaySidebar(
      {required this.plan, required this.selectedDay, required this.onDaySelect});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: _Palette.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('YOUR JOURNEY',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: _Palette.accent,
                      )),
                  const SizedBox(height: 8),
                  Text(
                    '${plan.itinerary.duration_days} Days',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: _Palette.ink,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(plan.destination,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _Palette.muted,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const Divider(height: 1, color: _Palette.divider),
            const SizedBox(height: 12),
            // Day list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: plan.itinerary.days.length,
                itemBuilder: (_, i) => _SidebarDayTile(
                  day: plan.itinerary.days[i],
                  index: i,
                  isSelected: selectedDay == i,
                  onTap: () => onDaySelect(i),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
}

class _SidebarDayTile extends StatelessWidget {
  final TravelDay day;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  const _SidebarDayTile(
      {required this.day,
      required this.index,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _Palette.accent.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _Palette.accent.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Day number pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? _Palette.accent : _Palette.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${day.day_number}',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isSelected ? Colors.white : _Palette.slate,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${day.day_number}',
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 13,
                      color: isSelected ? _Palette.accent : _Palette.inkLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    day.theme,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _Palette.muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                    color: _Palette.accent, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Horizontal Day Rail (Mobile/Tablet) ──────────────────────────────────────
class _HorizontalDayRail extends StatefulWidget {
  final TravelPlan plan;
  final int selectedDay;
  final void Function(int) onDaySelect;
  const _HorizontalDayRail(
      {required this.plan, required this.selectedDay, required this.onDaySelect});

  @override
  State<_HorizontalDayRail> createState() => _HorizontalDayRailState();
}

class _HorizontalDayRailState extends State<_HorizontalDayRail> {
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(_HorizontalDayRail old) {
    super.didUpdateWidget(old);
    if (old.selectedDay != widget.selectedDay) {
      final target = widget.selectedDay * 88.0;
      _scroll.animateTo(target.clamp(0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        height: 76,
        color: Colors.white,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                itemCount: widget.plan.itinerary.days.length,
                itemBuilder: (_, i) {
                  final day = widget.plan.itinerary.days[i];
                  final sel = widget.selectedDay == i;
                  return GestureDetector(
                    onTap: () => widget.onDaySelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? _Palette.accent : _Palette.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                  color: _Palette.accent.withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('DAY ${day.day_number}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sel ? Colors.white : _Palette.muted,
                                letterSpacing: 0.8,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(height: 1, color: _Palette.divider),
          ],
        ),
      );
}

// ─── Day Content ─────────────────────────────────────────────────────────────
class _DayContent extends StatelessWidget {
  final TravelPlan plan;
  final int selectedDay;
  final Animation<double> fadeAnim;
  final ScrollController scrollCtrl;
  final bool isDesktop;
  const _DayContent({
    required this.plan,
    required this.selectedDay,
    required this.fadeAnim,
    required this.scrollCtrl,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.itinerary.days.isEmpty) return _EmptyState();
    final safeDay = selectedDay.clamp(0, plan.itinerary.days.length - 1);
    final day = plan.itinerary.days[safeDay];
    final px = isDesktop ? 40.0 : 20.0;

    return FadeTransition(
      opacity: fadeAnim,
      child: SingleChildScrollView(
        controller: scrollCtrl,
        padding: EdgeInsets.fromLTRB(px, 28, px, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CinematicDayHeader(day: day, isDesktop: isDesktop),
            const SizedBox(height: 36),
            _ActivityTimeline(activities: day.activities, isDesktop: isDesktop),
          ],
        ),
      ),
    );
  }
}

// ─── Cinematic Day Header ─────────────────────────────────────────────────────
class _CinematicDayHeader extends StatelessWidget {
  final TravelDay day;
  final bool isDesktop;
  const _CinematicDayHeader({required this.day, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: isDesktop ? 220 : 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=2000&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              _Palette.ink.withOpacity(0.55),
              _Palette.ink.withOpacity(0.92),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Day badge
            Positioned(
              top: 20,
              left: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      'DAY ${day.day_number}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Activity count badge
            Positioned(
              top: 20,
              right: 24,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _Palette.accent.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _Palette.accent.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.route_rounded, color: Colors.white, size: 13),
                        const SizedBox(width: 6),
                        Text(
                          '${day.activities.length} Stops',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Bottom title
            Positioned(
              bottom: 22,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.theme,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: isDesktop ? 30 : 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Category pills from first 3 activities
                  Wrap(
                    spacing: 6,
                    children: day.activities
                        .take(3)
                        .map((a) => _cat(a.category))
                        .toSet()
                        .map((cs) => _MiniPill(style: cs))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final _CategoryStyle style;
  const _MiniPill({required this.style});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: style.color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: style.color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: 10, color: Colors.white),
            const SizedBox(width: 4),
            Text(style.label,
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8)),
          ],
        ),
      );
}

// ─── Activity Timeline ────────────────────────────────────────────────────────
class _ActivityTimeline extends StatelessWidget {
  final List<Activity> activities;
  final bool isDesktop;
  const _ActivityTimeline({required this.activities, required this.isDesktop});

  @override
  Widget build(BuildContext context) => Column(
        children: activities.asMap().entries.map((e) {
          return _TimelineItem(
            activity: e.value,
            index: e.key,
            isLast: e.key == activities.length - 1,
            isDesktop: isDesktop,
          );
        }).toList(),
      );
}

class _TimelineItem extends StatelessWidget {
  final Activity activity;
  final int index;
  final bool isLast;
  final bool isDesktop;
  const _TimelineItem({
    required this.activity,
    required this.index,
    required this.isLast,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final cs = _cat(activity.category);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline column
          SizedBox(
            width: 52,
            child: Column(
              children: [
                // Icon node
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.color, cs.color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: cs.color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(cs.icon, color: Colors.white, size: 18),
                ),
                // Connector
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            cs.color.withOpacity(0.4),
                            _Palette.divider,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: _ActivityCard(
                  activity: activity, cs: cs, isDesktop: isDesktop),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Activity Card ────────────────────────────────────────────────────────────
class _ActivityCard extends StatefulWidget {
  final Activity activity;
  final _CategoryStyle cs;
  final bool isDesktop;
  const _ActivityCard(
      {required this.activity, required this.cs, required this.isDesktop});

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    final cs = widget.cs;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered ? cs.color.withOpacity(0.3) : _Palette.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? cs.color.withOpacity(0.12)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _hovered ? 24 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Colored top accent bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [cs.color, cs.color.withOpacity(0.3)]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(widget.isDesktop ? 22 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta row
                  Row(
                    children: [
                      _Chip(label: a.time, icon: Icons.access_time_rounded, color: _Palette.accent),
                      const SizedBox(width: 8),
                      _Chip(label: cs.label, icon: cs.icon, color: cs.color),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name
                  Text(
                    a.location.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: widget.isDesktop ? 20 : 18,
                      fontWeight: FontWeight.w700,
                      color: _Palette.ink,
                      height: 1.2,
                    ),
                  ),

                  // Address
                  if (a.location.address.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 13, color: _Palette.muted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            a.location.address,
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: _Palette.muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    a.description,
                    style: GoogleFonts.poppins(
                      fontSize: widget.isDesktop ? 14 : 13,
                      color: _Palette.slate,
                      height: 1.65,
                    ),
                  ),

                  // Cultural note
                  if (a.culturalConnection.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _Palette.gold.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _Palette.gold.withOpacity(0.25)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: _Palette.gold, size: 14),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              a.culturalConnection,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF8A6A00),
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Map button
                  if (a.location.maps_link.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => _openMap(context, a.location.maps_link),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: _Palette.accent.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: _Palette.accent.withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.map_outlined,
                                  size: 14, color: _Palette.accent),
                              const SizedBox(width: 8),
                              Text(
                                'Open in Maps',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _Palette.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(BuildContext ctx, String link) async {
    final url = Uri.parse(link);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _Chip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 0.3)),
          ],
        ),
      );
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off_rounded,
                size: 56, color: _Palette.muted.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No activities yet',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    color: _Palette.muted,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ─── Loading Overlay ──────────────────────────────────────────────────────────
class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black54,
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_Palette.accent),
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Generating PDF…',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _Palette.ink)),
                    const SizedBox(height: 4),
                    Text('This won\'t take long',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: _Palette.muted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}