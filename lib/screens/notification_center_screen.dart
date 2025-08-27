import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  String _userType = 'user';
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadUserType();
    _loadNotifications();
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserType() async {
    try {
      final userType = await _authService.getUserType();
      setState(() {
        _userType = userType ?? 'user';
      });
    } catch (error) {
      print('Error loading user type: $error');
    }
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // For now, we'll create mock notifications
      // In a real app, you'd fetch these from your backend
      await Future.delayed(const Duration(seconds: 1));
      
      final mockNotifications = _generateMockNotifications();
      setState(() {
        _notifications = mockNotifications;
      });
    } catch (error) {
      print('Error loading notifications: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _generateMockNotifications() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> notifications = [];

    // Add notifications based on user type
    if (_userType == 'user') {
      notifications.addAll([
        {
          'id': '1',
          'type': 'booking',
          'title': 'Booking Confirmed',
          'body': 'Your cleaning service booking has been confirmed for tomorrow at 2:00 PM',
          'timestamp': now.subtract(const Duration(minutes: 30)),
          'isRead': false,
          'data': {'bookingId': '123', 'action': 'view_booking'},
        },
        {
          'id': '2',
          'type': 'chat',
          'title': 'New Message',
          'body': 'You have a new message from your service provider',
          'timestamp': now.subtract(const Duration(hours: 2)),
          'isRead': false,
          'data': {'chatId': '456', 'action': 'open_chat'},
        },
        {
          'id': '3',
          'type': 'rating',
          'title': 'Rate Your Experience',
          'body': 'How was your recent cleaning service? Please rate and review',
          'timestamp': now.subtract(const Duration(days: 1)),
          'isRead': true,
          'data': {'bookingId': '123', 'action': 'rate_service'},
        },
      ]);
    } else if (_userType == 'provider') {
      notifications.addAll([
        {
          'id': '1',
          'type': 'booking',
          'title': 'New Booking Request',
          'body': 'You have a new cleaning service booking request',
          'timestamp': now.subtract(const Duration(minutes: 15)),
          'isRead': false,
          'data': {'bookingId': '789', 'action': 'view_booking'},
        },
        {
          'id': '2',
          'type': 'chat',
          'title': 'New Message',
          'body': 'You have a new message from a customer',
          'timestamp': now.subtract(const Duration(hours: 1)),
          'isRead': false,
          'data': {'chatId': '456', 'action': 'open_chat'},
        },
        {
          'id': '3',
          'type': 'rating',
          'title': 'New Review',
          'body': 'You received a 5-star review from a customer',
          'timestamp': now.subtract(const Duration(days: 1)),
          'isRead': true,
          'data': {'reviewId': '101', 'action': 'view_review'},
        },
      ]);
    } else if (_userType == 'admin') {
      notifications.addAll([
        {
          'id': '1',
          'type': 'admin',
          'title': 'New Provider Registration',
          'body': 'A new service provider has registered and needs approval',
          'timestamp': now.subtract(const Duration(minutes: 45)),
          'isRead': false,
          'data': {'providerId': '202', 'action': 'review_provider'},
        },
        {
          'id': '2',
          'type': 'admin',
          'title': 'System Alert',
          'body': 'High server load detected. Consider scaling resources',
          'timestamp': now.subtract(const Duration(hours: 3)),
          'isRead': false,
          'data': {'alertType': 'server_load', 'action': 'view_metrics'},
        },
        {
          'id': '3',
          'type': 'admin',
          'title': 'Daily Report',
          'body': 'Daily activity report is ready for review',
          'timestamp': now.subtract(const Duration(days: 1)),
          'isRead': true,
          'data': {'reportType': 'daily', 'action': 'view_report'},
        },
      ]);
    }

    return notifications;
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
      }
    });
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    _markAsRead(notification['id']);
    
    // Handle navigation based on notification type and action
    final data = notification['data'];
    if (data != null) {
      // This would be handled by your navigation system
      // Navigate based on action type
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'booking':
        return const Icon(Icons.calendar_today, color: Colors.blue);
      case 'chat':
        return const Icon(Icons.chat_bubble, color: Colors.green);
      case 'rating':
        return const Icon(Icons.star, color: Colors.orange);
      case 'admin':
        return const Icon(Icons.admin_panel_settings, color: Colors.purple);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'booking':
        return Colors.blue.shade50;
      case 'chat':
        return Colors.green.shade50;
      case 'rating':
        return Colors.orange.shade50;
      case 'admin':
        return Colors.purple.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2E) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                          ? Colors.black.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          l10n.notifications,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color: isDark ? Colors.white : const Color(0xFF1D1D1F),
                          size: 20,
                        ),
                        onPressed: _loadNotifications,
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF007AFF),
                          ),
                        )
                      : _notifications.isEmpty
                          ? _buildEmptyState(l10n, isDark)
                          : _buildNotificationsList(l10n, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDark ? Colors.white54 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noNotifications,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white54 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(AppLocalizations l10n, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification, isDark);
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, bool isDark) {
    final isRead = notification['isRead'] ?? false;
    final type = notification['type'] ?? 'general';
    final title = notification['title'] ?? '';
    final body = notification['body'] ?? '';
    final timestamp = notification['timestamp'] as DateTime? ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getNotificationColor(type),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _getNotificationIcon(type),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1D1D1F),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getTimeAgo(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: !isRead ? Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(4),
          ),
        ) : null,
        onTap: () => _handleNotificationTap(notification),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
