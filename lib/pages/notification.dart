import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/mqtt-service.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  static String id = 'notification_screen';
  final PageController controller;

  const NotificationPage({super.key, required this.controller});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationService _notificationService = NotificationService();
  late MqttService _mqttService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  // Store the function reference to properly remove it in dispose
  Function(String)? _mqttNotificationCallback;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_scrollListener);

    // Subscribe to mqtt notifications to refresh the list when new one arrives
    _mqttService = MqttService();

    // Store the reference to the callback function
    _mqttNotificationCallback = (message) => _handleMqttNotification(message);

    // Set the callback
    _mqttService.onNewNotification = _mqttNotificationCallback;
  }

  @override
  void dispose() {
    // Remove the MQTT notification callback to prevent setState after dispose
    if (_mqttNotificationCallback != null) {
      // Only remove our specific callback to avoid affecting other subscribers
      if (_mqttService.onNewNotification == _mqttNotificationCallback) {
        _mqttService.onNewNotification = null;
      }
    }

    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleMqttNotification(String message) {
    // When receiving an MQTT notification, refresh the notification list
    // Check if widget is still mounted before refreshing
    if (mounted) {
      _refreshNotifications();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_currentPage < _totalPages && !_isLoadingMore) {
        _loadMoreNotifications();
      }
    }
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await _notificationService.getNotifications(
        pageIndex: 1,
        pageSize: 10,
      );

      if (!mounted) return;

      setState(() {
        _notifications = response.response.data;
        _currentPage = response.response.currentPage;
        _totalPages = response.response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');

      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _notificationService.getNotifications(
        pageIndex: _currentPage + 1,
        pageSize: 10,
      );

      if (!mounted) return;

      setState(() {
        _notifications.addAll(response.response.data);
        _currentPage = response.response.currentPage;
        _totalPages = response.response.totalPages;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    if (!mounted) return;

    try {
      final success = await _notificationService.markAsRead(notificationId);
      if (success && mounted) {
        setState(() {
          final index = _notifications.indexWhere(
            (notification) => notification.id == notificationId,
          );
          if (index != -1) {
            // Create a copy of notification with isRead = true
            final updatedNotification = NotificationModel(
              id: _notifications[index].id,
              title: _notifications[index].title,
              message: _notifications[index].message,
              isRead: true,
              type: _notifications[index].type,
              senderName: _notifications[index].senderName,
              receiverName: _notifications[index].receiverName,
              referenceId: _notifications[index].referenceId,
              createdAt: _notifications[index].createdAt,
            );

            // Update the list
            _notifications[index] = updatedNotification;
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not mark as read: ${e.toString()}')),
      );
    }
  }

  Future<void> _refreshNotifications() async {
    if (!mounted) return;
    await _loadNotifications();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshNotifications,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Đã xảy ra lỗi: $_errorMessage'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadNotifications,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
              : _notifications.isEmpty
              ? const Center(child: Text('Không có thông báo nào'))
              : RefreshIndicator(
                onRefresh: _refreshNotifications,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      _notifications.length +
                      (_currentPage < _totalPages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _notifications.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final notification = _notifications[index];
                    return InkWell(
                      onTap: () {
                        if (!notification.isRead) {
                          _markAsRead(notification.id);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              notification.isRead
                                  ? Colors.white
                                  : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(notification.message),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Loại: ${notification.type}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _formatDate(notification.createdAt),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
