import 'package:flutter/material.dart';

// ── Design Tokens ────────────────────────────────────────────────────────────

const Color kPrimary = Color(0xFF0F172A);
const Color kBackground = Color(0xFF020617);
const Color kSurface = Color(0xFF1E293B);
const Color kAccent = Color(0xFF22C55E);
const Color kMuted = Color(0xFF334155);
const Color kForeground = Color(0xFFF8FAFC);
const double kRadius = 12.0;
const double kPadding = 20.0;

// ── Shared UI Components ─────────────────────────────────────────────────────

class TechnicalGridBackground extends StatelessWidget {
  const TechnicalGridBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(color: kBackground),
          Opacity(
            opacity: 0.03,
            child: CustomPaint(
              painter: _GridPainter(),
              child: Container(),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: _GlowBlob(color: kAccent.withValues(alpha: 0.05)),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: _GlowBlob(color: const Color(0xFF6366F1).withValues(alpha: 0.03)),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GlowBlob extends StatelessWidget {
  final Color color;
  const _GlowBlob({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class TechnicalSectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final double topPadding;

  const TechnicalSectionHeader({
    super.key,
    required this.label,
    required this.color,
    this.topPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(kPadding, topPadding, kPadding, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 2, height: 14, color: color),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Container(
            height: 1,
            width: double.infinity,
            color: Colors.white.withValues(alpha: 0.05),
          ),
        ],
      ),
    );
  }
}

class TechnicalCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool showBorder;

  const TechnicalCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(kRadius),
        border: showBorder ? Border.all(color: Colors.white.withValues(alpha: 0.05)) : null,
      ),
      child: child,
    );
  }
}

class TechnicalButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final bool isLoading;

  const TechnicalButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = kAccent,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<TechnicalButton> createState() => _TechnicalButtonState();
}

class _TechnicalButtonState extends State<TechnicalButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isLoading ? null : widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _pressed ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(kRadius),
            border: Border.all(color: widget.color.withValues(alpha: 0.3)),
          ),
          child: widget.isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: widget.color),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.color, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label.toUpperCase(),
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
