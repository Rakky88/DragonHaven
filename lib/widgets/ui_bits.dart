import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

bool usesLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1) > 1.2;

void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(
      {super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!, style: const TextStyle(color: AppColors.muted)),
        ],
      ],
    );
    final largeText = usesLargeText(context);
    if (largeText && trailing != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          text,
          const SizedBox(height: 5),
          Align(alignment: Alignment.centerRight, child: trailing!),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A compact horizontal rail that makes off-screen choices discoverable.
///
/// Mobile users can still swipe the rail normally. The edge fades only appear
/// while more choices exist in that direction, so a clipped chip never looks
/// like an accidental layout error.
class HorizontalChoiceRail extends StatefulWidget {
  const HorizontalChoiceRail({
    super.key,
    required this.children,
    this.height = 40,
  });

  final List<Widget> children;
  final double height;

  @override
  State<HorizontalChoiceRail> createState() => _HorizontalChoiceRailState();
}

class _HorizontalChoiceRailState extends State<HorizontalChoiceRail> {
  final _controller = ScrollController();
  bool _hasChoicesBefore = false;
  bool _hasChoicesAfter = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncEdges);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEdges());
  }

  @override
  void didUpdateWidget(covariant HorizontalChoiceRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncEdges());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_syncEdges)
      ..dispose();
    super.dispose();
  }

  void _syncEdges() {
    if (!mounted || !_controller.hasClients) return;
    final position = _controller.position;
    final before = position.pixels > 2;
    final after = position.maxScrollExtent - position.pixels > 2;
    if (before == _hasChoicesBefore && after == _hasChoicesAfter) return;
    setState(() {
      _hasChoicesBefore = before;
      _hasChoicesAfter = after;
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            ListView(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 28),
              children: widget.children,
            ),
            _RailEdgeIndicator(
              alignment: Alignment.centerLeft,
              icon: Icons.chevron_left_rounded,
              visible: _hasChoicesBefore,
            ),
            _RailEdgeIndicator(
              alignment: Alignment.centerRight,
              icon: Icons.chevron_right_rounded,
              visible: _hasChoicesAfter,
            ),
          ],
        ),
      );
}

class _RailEdgeIndicator extends StatelessWidget {
  const _RailEdgeIndicator({
    required this.alignment,
    required this.icon,
    required this.visible,
  });

  final Alignment alignment;
  final IconData icon;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final fromLeft = alignment == Alignment.centerLeft;
    return Positioned(
      top: 0,
      bottom: 0,
      left: fromLeft ? 0 : null,
      right: fromLeft ? null : 0,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 160),
          child: ExcludeSemantics(
            child: Container(
              width: 72,
              alignment: alignment,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin:
                      fromLeft ? Alignment.centerLeft : Alignment.centerRight,
                  end: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
                  colors: [
                    AppColors.cream,
                    AppColors.cream.withValues(alpha: .92),
                    AppColors.cream.withValues(alpha: 0),
                  ],
                ),
              ),
              child: Container(
                width: 30,
                height: 30,
                margin: EdgeInsets.only(
                  left: fromLeft ? 3 : 0,
                  right: fromLeft ? 0 : 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.mist),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x165B4B8A),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: AppColors.twilight),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MetricPill extends StatelessWidget {
  const MetricPill(
      {super.key,
      required this.leading,
      required this.value,
      required this.label,
      required this.color});
  final Widget leading;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(15)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            leading,
            const SizedBox(width: 7),
            Text(value,
                style: TextStyle(fontWeight: FontWeight.w900, color: color)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.82))),
          ],
        ),
      );
}
