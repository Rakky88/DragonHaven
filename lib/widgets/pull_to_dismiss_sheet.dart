import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A bottom-sheet body with a pinned handle and deliberate pull-down dismissal.
class PullToDismissSheet extends StatefulWidget {
  const PullToDismissSheet({
    required this.child,
    this.heightFactor = .9,
    this.dragHandleKey,
    this.backgroundColor = AppColors.cream,
    this.dismissPullThreshold = 72,
    super.key,
  });

  final Widget child;
  final double heightFactor;
  final Key? dragHandleKey;
  final Color backgroundColor;
  final double dismissPullThreshold;

  @override
  State<PullToDismissSheet> createState() => _PullToDismissSheetState();
}

class _PullToDismissSheetState extends State<PullToDismissSheet> {
  bool _isDismissing = false;
  double _dismissPullDistance = 0;

  void _addDismissPull(double distance) {
    if (_isDismissing) return;
    if (distance <= 0) {
      _resetDismissPull();
      return;
    }
    _dismissPullDistance += distance;
    if (_dismissPullDistance < widget.dismissPullThreshold) return;
    _isDismissing = true;
    Navigator.of(context).pop();
  }

  void _resetDismissPull() => _dismissPullDistance = 0;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is OverscrollNotification &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent &&
        notification.overscroll < 0) {
      _addDismissPull(-notification.overscroll);
    } else if (notification is ScrollEndNotification ||
        (notification is ScrollUpdateNotification &&
            notification.metrics.pixels >
                notification.metrics.minScrollExtent)) {
      _resetDismissPull();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height *
              widget.heightFactor.clamp(.25, 1),
          child: Material(
            color: widget.backgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                GestureDetector(
                  key: widget.dragHandleKey,
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: (_) => _resetDismissPull(),
                  onVerticalDragUpdate: (details) =>
                      _addDismissPull(details.delta.dy),
                  onVerticalDragEnd: (_) => _resetDismissPull(),
                  onVerticalDragCancel: _resetDismissPull,
                  child: SizedBox(
                    height: 34,
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.mist,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
