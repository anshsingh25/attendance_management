import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _filteredNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    // Mock data - in real app, this would come from API
    _notifications = [
      {
        'id': '1',
        'title': 'New Student Enrolled',
        'message': 'John Doe has enrolled in Mathematics class',
        'type': 'enrollment',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
        'isRead': false,
        'priority': 'high',
      },
      {
        'id': '2',
        'title': 'Attendance Alert',
        'message': 'Low attendance detected in Physics class (65%)',
        'type': 'attendance',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': false,
        'priority': 'medium',
      },
      {
        'id': '3',
        'title': 'Class Reminder',
        'message': 'Chemistry class starts in 15 minutes',
        'type': 'reminder',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
        'isRead': true,
        'priority': 'low',
      },
      {
        'id': '4',
        'title': 'System Update',
        'message': 'New features added to attendance system',
        'type': 'system',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'isRead': true,
        'priority': 'low',
      },
      {
        'id': '5',
        'title': 'Report Generated',
        'message': 'Monthly attendance report is ready for download',
        'type': 'report',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'isRead': true,
        'priority': 'medium',
      },
      {
        'id': '6',
        'title': 'Student Absent',
        'message': 'Sarah Wilson is absent for 3 consecutive days',
        'type': 'attendance',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
        'isRead': false,
        'priority': 'high',
      },
    ];
    _filteredNotifications = List.from(_notifications);
  }

  void _filterNotifications() {
    setState(() {
      _filteredNotifications = _notifications.where((notification) {
        if (_selectedFilter == 'All') return true;
        if (_selectedFilter == 'Unread') return !notification['isRead'];
        return notification['type'] == _selectedFilter.toLowerCase();
      }).toList();
    });
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = _notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        _notifications[index]['isRead'] = true;
        _filterNotifications();
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification['isRead'] = true;
      }
      _filterNotifications();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      _notifications.removeWhere((n) => n['id'] == notificationId);
      _filterNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Unread', 'Enrollment', 'Attendance', 'Reminder', 'System', 'Report'].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = filter;
                        });
                        _filterNotifications();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Notifications List
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No notifications',
            style: AppTheme.headlineSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: AppTheme.bodyLarge.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'];
    final priority = notification['priority'];
    final type = notification['type'];
    
    Color priorityColor;
    IconData typeIcon;
    
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.blue;
    }
    
    switch (type) {
      case 'enrollment':
        typeIcon = Icons.person_add;
        break;
      case 'attendance':
        typeIcon = Icons.assignment;
        break;
      case 'reminder':
        typeIcon = Icons.schedule;
        break;
      case 'system':
        typeIcon = Icons.system_update;
        break;
      case 'report':
        typeIcon = Icons.assessment;
        break;
      default:
        typeIcon = Icons.notifications;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isRead ? null : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      child: InkWell(
        onTap: () => _markAsRead(notification['id']),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  typeIcon,
                  color: priorityColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: AppTheme.titleMedium.copyWith(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: priorityColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'],
                      style: AppTheme.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _formatTimestamp(notification['timestamp']),
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priority.toUpperCase(),
                            style: AppTheme.labelSmall.copyWith(
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteNotification(notification['id']);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
