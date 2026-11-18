import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final list = [...state.conversations]..sort((a, b) => b.lastAt.compareTo(a.lastAt));
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: list.isEmpty
          ? const EmptyState(icon: Icons.chat_bubble_outline, title: 'Aucune conversation', message: 'Négociez depuis une offre ou une demande.')
          : ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(indent: 76),
              itemBuilder: (_, i) {
                final c = list[i];
                final last = c.messages.isEmpty ? null : c.messages.last;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: UserAvatar(c.other, radius: 24),
                  title: Row(
                    children: [
                      Expanded(child: Text(c.other.displayName, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: c.unread > 0 ? FontWeight.w800 : FontWeight.w600))),
                      Text(last == null ? '' : ago(last.at), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.subject, style: const TextStyle(fontSize: 12.5, color: AppColors.green, fontWeight: FontWeight.w600)),
                      Text(last == null ? '' : '${last.fromMe ? 'Vous : ' : ''}${last.text}', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                  trailing: c.unread > 0 ? CircleAvatar(radius: 11, backgroundColor: AppColors.flash, child: Text('${c.unread}', style: const TextStyle(fontSize: 12, color: Colors.white))) : null,
                  onTap: () => go<void>(context, ChatScreen(conversation: c)),
                );
              },
            ),
    );
  }
}
