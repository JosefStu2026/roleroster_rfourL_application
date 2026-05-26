// lib/screens/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid = context.read<AuthProvider>().user?.uid;
      if (uid != null) {
        context.read<NotificationProvider>().loadNotifications(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().user?.uid;
    final notificationProv = context.watch<NotificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primary,
      ),
      body: uid == null
          ? const Center(child: Text('Please sign in again.'))
          : notificationProv.loading
              ? const Center(child: CircularProgressIndicator())
              : notificationProv.notifications.isEmpty
                  ? const Center(
                      child: Text('No notifications yet.',
                          style: TextStyle(color: AppColors.textLight)),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          context.read<NotificationProvider>().refresh(uid),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notificationProv.notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification =
                              notificationProv.notifications[index];
                          final isInvite =
                              notification.type == 'group_invite_pending';
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: (notification.isRead || isInvite)
                                ? null
                                : () => context
                                    .read<NotificationProvider>()
                                    .markAsRead(notification.id, uid),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: notification.isRead
                                    ? AppColors.white
                                    : const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (!notification.isRead)
                                        const Icon(Icons.circle,
                                            size: 10, color: AppColors.accent),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(notification.body,
                                      style: const TextStyle(
                                          color: AppColors.textDark,
                                          height: 1.35)),
                                  const SizedBox(height: 8),
                                  Text(
                                    notification.createdAt.toLocal().toString(),
                                    style: const TextStyle(
                                      color: AppColors.textLight,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (isInvite && !notification.isRead) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () => context
                                                .read<NotificationProvider>()
                                                .respondToGroupInvite(
                                                  notification: notification,
                                                  uid: uid,
                                                  accept: false,
                                                ),
                                            child: const Text('Decline'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () => context
                                                .read<NotificationProvider>()
                                                .respondToGroupInvite(
                                                  notification: notification,
                                                  uid: uid,
                                                  accept: true,
                                                ),
                                            child: const Text('Accept'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
