import 'package:flutter/material.dart';
import 'dart:async';

class PopupNotification extends StatefulWidget {
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const PopupNotification({
    super.key,
    required this.title,
    required this.body,
    this.data,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<PopupNotification> createState() => _PopupNotificationState();
}

class _PopupNotificationState extends State<PopupNotification>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Timer _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Start animations
    _fadeController.forward();
    _slideController.forward();

    // Auto-dismiss after 5 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      _dismiss();
    });
  }

  void _dismiss() {
    _slideController.reverse();
    _fadeController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _autoDismissTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _autoDismissTimer.cancel();
                widget.onTap?.call();
                _dismiss();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Notification Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.body,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Dismiss Button
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3A3C) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Global overlay entry manager
class PopupNotificationManager {
  static final PopupNotificationManager _instance = PopupNotificationManager._internal();
  factory PopupNotificationManager() => _instance;
  PopupNotificationManager._internal();

  OverlayEntry? _currentNotification;
  final List<Map<String, dynamic>> _notificationQueue = [];

  void showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
    VoidCallback? onTap,
  }) {
    // Add to queue
    _notificationQueue.add({
      'title': title,
      'body': body,
      'data': data,
      'onTap': onTap,
    });

    // Show next notification if none is currently displayed
    if (_currentNotification == null) {
      _showNextNotification();
    }
  }

  void _showNextNotification() {
    if (_notificationQueue.isEmpty) return;

    final notificationData = _notificationQueue.removeAt(0);
    
    _currentNotification = OverlayEntry(
      builder: (context) => PopupNotification(
        title: notificationData['title'],
        body: notificationData['body'],
        data: notificationData['data'],
        onTap: notificationData['onTap'],
        onDismiss: () {
          _dismissCurrent();
          // Show next notification after a short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            _showNextNotification();
          });
        },
      ),
    );

    // Find the overlay and insert - handle null context gracefully
    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        final overlay = Overlay.of(context);
        overlay.insert(_currentNotification!);
      } else {
        print('⚠️ Navigator context not available for popup notification');
        // Fallback: try to show after a delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _showNextNotification();
        });
      }
    } catch (e) {
      print('❌ Error showing popup notification: $e');
      // Fallback: try to show after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _showNextNotification();
      });
    }
  }

  void _dismissCurrent() {
    _currentNotification?.remove();
    _currentNotification = null;
  }

  void clearAll() {
    _notificationQueue.clear();
    _dismissCurrent();
  }
}

// Global navigator key for overlay access
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
