import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final list = state.notifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadNotifications > 0)
            TextButton(onPressed: state.markAllNotificationsRead, child: const Text('Tout marquer lu')),
        ],
      ),
      body: list.isEmpty
          ? const EmptyState(icon: Icons.notifications_none, title: 'Rien de nouveau', message: 'Vos alertes de commandes, d’offres et de prix apparaîtront ici.')
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(indent: 72),
              itemBuilder: (_, i) {
                final n = list[i];
                return ListTile(
                  tileColor: n.read ? null : AppColors.greenLight.withValues(alpha: 0.5),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(backgroundColor: n.color.withValues(alpha: 0.12), child: Icon(n.icon, color: n.color)),
                  title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.w600 : FontWeight.w800)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(n.body),
                      const SizedBox(height: 2),
                      Text(ago(n.at), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
