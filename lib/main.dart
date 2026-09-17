import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Read the app's display name from the platform itself (the same
  // value set in AndroidManifest.xml / Info.plist) instead of hardcoding
  // it as a separate string in the Dart source.
  final packageInfo = await PackageInfo.fromPlatform();

  runApp(DateDiffApp(appName: packageInfo.appName));

  // Remove the plain native splash almost immediately; our own
  // SplashScreen widget (with the rounded-corner logo) takes over
  // and controls the full 2s display time itself.
  FlutterNativeSplash.remove();
}

/// App color palette
class AppColors {
  static const primary = Color(0xFF4F8EF7);
  static const primaryDark = Color(0xFF2E6FE0);
  static const accent = Color(0xFF00D9C0);
  static const bg = Color(0xFFEAF1FC);
  static const cardShadow = Color(0x1A1D5FC4);
  static const textDark = Color(0xFF1B233A);
  static const textMuted = Color(0xFF8B93A6);
}

class DateDiffApp extends StatelessWidget {
  const DateDiffApp({super.key, required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme();
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.accent,
        ),
        textTheme: baseTextTheme.apply(
          bodyColor: AppColors.textDark,
          displayColor: AppColors.textDark,
        ),
      ),
      home: SplashScreen(appName: appName),
    );
  }
}

/// Shows the app logo with rounded corners (clipped in code, not baked
/// into the PNG) on the app's sky-blue background, zooming it in with a
/// slight bounce, with the app name closely following right underneath
/// it so the two read as one unit. Shown for exactly 2 seconds, then
/// hands off to the main calculator page.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.appName});

  final String appName;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();

    // Zoom the logo in with a slight overshoot ("grows a bit then settles
    // back") over the full 2s the splash screen is shown for.
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // The app name fades and slides in early, close behind the logo, so
    // the icon and the name read as one unit rather than two separate
    // beats.
    _textFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_textFade);

    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DateDiffHomePage(appName: widget.appName)),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _logoScale,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(
                  'assets/icon.png',
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeTransition(
              opacity: _textFade,
              child: SlideTransition(
                position: _textSlide,
                child: Text(
                  widget.appName,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateDiffHomePage extends StatefulWidget {
  const DateDiffHomePage({super.key, required this.appName});

  final String appName;

  @override
  State<DateDiffHomePage> createState() => _DateDiffHomePageState();
}

class _DateDiffHomePageState extends State<DateDiffHomePage>
    with SingleTickerProviderStateMixin {
  DateTime? _startDate;
  DateTime? _endDate;

  int _years = 0;
  int _months = 0;
  int _days = 0;
  int _totalDays = 0;
  bool _hasResult = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      if (_startDate != null && _endDate != null) {
        _calculate();
      }
    }
  }

  void _calculate() {
    DateTime from = _startDate!;
    DateTime to = _endDate!;
    if (from.isAfter(to)) {
      final tmp = from;
      from = to;
      to = tmp;
    }

    int years = to.year - from.year;
    int months = to.month - from.month;
    int days = to.day - from.day;

    if (days < 0) {
      months -= 1;
      final prevMonth = DateTime(to.year, to.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    setState(() {
      _years = years;
      _months = months;
      _days = days;
      _totalDays = to.difference(from).inDays;
      _hasResult = true;
    });
    _animController.forward(from: 0);
  }

  void _reset() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _hasResult = false;
    });
    _animController.reset();
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select a date';
    return DateFormat('d MMMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: _buildHeader(),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.bg,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDateCard(
                        label: 'From date',
                        icon: Icons.flight_takeoff_rounded,
                        date: _startDate,
                        onTap: () => _pickDate(isStart: true),
                      ),
                      const SizedBox(height: 14),
                      _buildDateCard(
                        label: 'To date',
                        icon: Icons.flight_land_rounded,
                        date: _endDate,
                        onTap: () => _pickDate(isStart: false),
                      ),
                      const SizedBox(height: 22),
                      if (_hasResult)
                        _buildResultSection()
                      else
                        _buildEmptyHint(),
                      const SizedBox(height: 20),
                      if (_hasResult)
                        TextButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.refresh_rounded,
                              color: AppColors.primary),
                          label: Text(
                            'New calculation',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/icon.png',
            width: 54,
            height: 54,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.appName,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Find the exact gap in years, months & days',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: Colors.white.withOpacity(0.75),
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDateCard({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _fmt(date),
                      style: GoogleFonts.poppins(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_right_rounded,
                  color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Icon(Icons.date_range_rounded,
              color: AppColors.textMuted.withOpacity(0.7), size: 46),
          const SizedBox(height: 10),
          Text(
            'Pick both dates to see the result',
            style: GoogleFonts.poppins(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.94, end: 1).animate(_fadeAnim),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 22,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Difference between the dates',
                style: GoogleFonts.poppins(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUnit(_years, 'Years'),
                  _buildDivider(),
                  _buildUnit(_months, 'Months'),
                  _buildDivider(),
                  _buildUnit(_days, 'Days'),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timelapse_rounded,
                        color: AppColors.primaryDark, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Total days: ${NumberFormat.decimalPattern('en').format(_totalDays)}',
                      style: GoogleFonts.poppins(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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

  Widget _buildUnit(int value, String label) {
    return Column(
      children: [
        Container(
          width: 78,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$value',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: AppColors.textMuted.withOpacity(0.15),
    );
  }
}
