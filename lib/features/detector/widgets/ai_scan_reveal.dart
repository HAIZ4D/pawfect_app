import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../models/diagnosis_model.dart';

/// Cinematic AI-detection reveal that plays once on the result screen.
///
/// Sequence (≈ 6s — paced to feel earned, not padded):
///   0.00s  fade-in dark backdrop + photo
///   0.40s  corner brackets snap onto photo (elasticOut)
///   1.10s  vertical scan line sweeps top → bottom with glow
///   1.90s  detection dots pulse in sequentially with labels
///   3.70s  confidence ring sweeps around the photo
///   5.20s  "DIAGNOSIS LOCKED" badge + condition name reveal
///   6.00s  exit fade → onComplete fires
class AIScanReveal extends StatefulWidget {
  final File image;
  final DiagnosisModel diagnosis;
  final VoidCallback onComplete;

  const AIScanReveal({
    super.key,
    required this.image,
    required this.diagnosis,
    required this.onComplete,
  });

  @override
  State<AIScanReveal> createState() => _AIScanRevealState();
}

class _AIScanRevealState extends State<AIScanReveal>
    with TickerProviderStateMixin {
  static const Color _ink = Color(0xFF2D3142);
  static const Color _inkDark = Color(0xFF1F232E);

  late final AnimationController _master;
  late final AnimationController _exit;

  late final Animation<double> _backdropFade;
  late final Animation<double> _photoScale;
  late final Animation<double> _bracketsProgress;
  late final Animation<double> _scanLineProgress;
  late final Animation<double> _ringProgress;
  late final Animation<double> _badgeProgress;

  // Three detection regions positioned over a typical cat-face area.
  // (Alignment is in the photo-frame coordinate space, -1 → 1.)
  late final List<_Detection> _detections;

  int _statusIndex = 0;
  static const _statusMessages = [
    'Locking onto subject…',
    'Examining coat, skin & posture…',
    'Detecting visual markers…',
    'Cross-referencing symptoms…',
    'Computing final diagnosis…',
  ];

  @override
  void initState() {
    super.initState();

    _detections = _buildDetections();

    _master = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    );

    _exit = AnimationController(
      duration: const Duration(milliseconds: 480),
      vsync: this,
    );

    _backdropFade = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.0, 0.08, curve: Curves.easeOut),
    );

    _photoScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.0, 0.18, curve: Curves.easeOutCubic),
      ),
    );

    _bracketsProgress = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.06, 0.22, curve: Curves.easeOutBack),
    );

    _scanLineProgress = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.18, 0.58, curve: Curves.easeInOutCubic),
    );

    _ringProgress = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.62, 0.88, curve: Curves.easeOutCubic),
    );

    _badgeProgress = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.86, 1.0, curve: Curves.easeOutCubic),
    );

    _master.addListener(_advanceStatus);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _master.forward();
    if (!mounted) return;
    await _exit.forward();
    if (!mounted) return;
    widget.onComplete();
  }

  void _advanceStatus() {
    final v = _master.value;
    int next = 0;
    if (v > 0.85) {
      next = 4;
    } else if (v > 0.65) {
      next = 3;
    } else if (v > 0.45) {
      next = 2;
    } else if (v > 0.22) {
      next = 1;
    }
    if (next != _statusIndex) {
      setState(() => _statusIndex = next);
    }
  }

  List<_Detection> _buildDetections() {
    // Try to use Gemini's vision detections; fall back to generic regions.
    final ml = widget.diagnosis.mlDetections;
    final labels = ml.isNotEmpty
        ? ml.take(3).map(_shortLabel).toList()
        : const ['Skin region', 'Eye area', 'Coat surface'];

    // Triangle pattern centred on a typical cat-face position.
    const positions = <Alignment>[
      Alignment(-0.32, -0.18),
      Alignment(0.36, -0.10),
      Alignment(0.02, 0.34),
    ];

    return List.generate(labels.length, (i) {
      return _Detection(
        position: positions[i % positions.length],
        label: labels[i],
        delay: 0.32 + i * 0.12,
      );
    });
  }

  String _shortLabel(String raw) {
    if (raw.length <= 22) return raw;
    return '${raw.substring(0, 20)}…';
  }

  @override
  void dispose() {
    _master.removeListener(_advanceStatus);
    _master.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_master, _exit]),
      builder: (context, _) {
        final exitFade = 1.0 - _exit.value;
        return Opacity(
          opacity: exitFade,
          child: GestureDetector(
            onTap: _skip,
            behavior: HitTestBehavior.opaque,
            child: _buildSurface(),
          ),
        );
      },
    );
  }

  void _skip() {
    if (_master.isAnimating) {
      _master.value = 1.0;
    }
    if (!_exit.isAnimating && _exit.value == 0.0) {
      _exit.forward();
    }
  }

  Widget _buildSurface() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackdrop(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 22),
                Expanded(child: _buildScanFrame()),
                const SizedBox(height: 18),
                _buildStatusTicker(),
                const SizedBox(height: 16),
                _buildVerdict(),
                const SizedBox(height: 8),
                _buildSkipHint(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Backdrop ───────────────────────────
  Widget _buildBackdrop() {
    return Opacity(
      opacity: _backdropFade.value,
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [_ink, _inkDark, Color(0xFF15181F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(progress: _backdropFade.value),
        ),
      ),
    );
  }

  // ─────────────────────────── Top bar ───────────────────────────
  Widget _buildTopBar() {
    final pulse = 0.5 + 0.5 * math.sin(_master.value * math.pi * 6);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: PawfectColors.pawfectOrange.withOpacity(0.4 + 0.6 * pulse),
            boxShadow: [
              BoxShadow(
                color: PawfectColors.pawfectOrange.withOpacity(0.5 * pulse),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'GEMINI VISION • LIVE SCAN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Text(
            '${(_master.value * 100).clamp(0, 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────── Scan frame ───────────────────────────
  Widget _buildScanFrame() {
    return Center(
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Transform.scale(
          scale: _photoScale.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(widget.image, fit: BoxFit.cover),
                        // Subtle dim so brackets/dots stay legible.
                        Container(color: Colors.black.withOpacity(0.18)),
                      ],
                    ),
                  ),
                  // Scan line band
                  _buildScanBand(constraints),
                  // Corner brackets
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _BracketsPainter(
                        progress: _bracketsProgress.value,
                        color: PawfectColors.pawfectOrange,
                      ),
                    ),
                  ),
                  // Confidence ring
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: _ringProgress.value,
                        color: PawfectColors.pawfectOrange,
                      ),
                    ),
                  ),
                  // Detection dots
                  ..._detections.map(
                    (d) => _buildDetectionDot(d, constraints),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScanBand(BoxConstraints c) {
    final t = _scanLineProgress.value;
    if (t == 0) return const SizedBox.shrink();
    final y = t * c.maxHeight;
    return Positioned(
      top: y - 30,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                PawfectColors.pawfectOrange.withOpacity(0.0),
                PawfectColors.pawfectOrange.withOpacity(0.55),
                PawfectColors.pawfectOrange.withOpacity(0.0),
                Colors.transparent,
              ],
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
            ),
          ),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              height: 1.4,
              decoration: BoxDecoration(
                color: PawfectColors.pawfectOrange,
                boxShadow: [
                  BoxShadow(
                    color: PawfectColors.pawfectOrange.withOpacity(0.85),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetectionDot(_Detection d, BoxConstraints c) {
    final m = _master.value;
    final localT = ((m - d.delay) / 0.10).clamp(0.0, 1.0);
    if (localT == 0) return const SizedBox.shrink();

    final pulse = 0.6 + 0.4 * math.sin((m - d.delay) * math.pi * 6);
    final dx = (d.position.x + 1) / 2 * c.maxWidth;
    final dy = (d.position.y + 1) / 2 * c.maxHeight;
    final settled = m > d.delay + 0.10;

    return Positioned(
      left: dx - 90,
      top: dy - 16,
      width: 180,
      child: Opacity(
        opacity: localT,
        child: Transform.scale(
          scale: 0.85 + 0.15 * localT,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 28 * (settled ? pulse : 1.0),
                      height: 28 * (settled ? pulse : 1.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PawfectColors.pawfectOrange.withOpacity(0.18),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PawfectColors.pawfectOrange,
                        boxShadow: [
                          BoxShadow(
                            color: PawfectColors.pawfectOrange.withOpacity(0.6),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: PawfectColors.pawfectOrange.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    d.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Status ticker ───────────────────────────
  Widget _buildStatusTicker() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Row(
        key: ValueKey(_statusIndex),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 1.6,
              valueColor: AlwaysStoppedAnimation(
                PawfectColors.pawfectOrange,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _statusMessages[_statusIndex],
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Verdict ───────────────────────────
  Widget _buildVerdict() {
    final t = _badgeProgress.value;
    if (t == 0) {
      return const SizedBox(height: 88);
    }
    return Opacity(
      opacity: t,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - t)),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: PawfectColors.pawfectOrange,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: PawfectColors.pawfectOrange.withOpacity(0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'DIAGNOSIS LOCKED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.diagnosis.condition,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkipHint() {
    final t = (_master.value - 0.15).clamp(0.0, 1.0);
    return Opacity(
      opacity: 0.5 * t,
      child: const Text(
        'Tap to skip',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _Detection {
  final Alignment position;
  final String label;
  final double delay;

  const _Detection({
    required this.position,
    required this.label,
    required this.delay,
  });
}

class _GridPainter extends CustomPainter {
  final double progress;
  _GridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025 * progress)
      ..strokeWidth = 0.6;
    const step = 36.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) =>
      old.progress != progress;
}

class _BracketsPainter extends CustomPainter {
  final double progress;
  final Color color;
  _BracketsPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final inset = 16.0;
    final maxArm = 40.0;
    final arm = maxArm * progress.clamp(0.0, 1.0);
    final w = size.width;
    final h = size.height;

    void drawCorner(Offset origin, Offset hDir, Offset vDir) {
      canvas.drawLine(origin, origin + hDir * arm, glowPaint);
      canvas.drawLine(origin, origin + vDir * arm, glowPaint);
      canvas.drawLine(origin, origin + hDir * arm, paint);
      canvas.drawLine(origin, origin + vDir * arm, paint);
    }

    drawCorner(
      Offset(inset, inset),
      const Offset(1, 0),
      const Offset(0, 1),
    );
    drawCorner(
      Offset(w - inset, inset),
      const Offset(-1, 0),
      const Offset(0, 1),
    );
    drawCorner(
      Offset(inset, h - inset),
      const Offset(1, 0),
      const Offset(0, -1),
    );
    drawCorner(
      Offset(w - inset, h - inset),
      const Offset(-1, 0),
      const Offset(0, -1),
    );
  }

  @override
  bool shouldRepaint(covariant _BracketsPainter old) =>
      old.progress != progress;
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _RingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final rect = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(26));
    final path = Path()..addRRect(rrect);

    final pathMetrics = path.computeMetrics().toList();
    final extracted = Path();
    for (final pm in pathMetrics) {
      extracted.addPath(
        pm.extractPath(0, pm.length * progress),
        Offset.zero,
      );
    }

    final glow = Paint()
      ..color = color.withOpacity(0.45)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extracted, glow);
    canvas.drawPath(extracted, stroke);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress;
}
