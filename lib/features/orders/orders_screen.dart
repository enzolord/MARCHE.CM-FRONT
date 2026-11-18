import 'package:material_ui/material_ui.dart';

import '../../core/cards.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final all = state.myOrders;
    final active = all.where((o) => !o.status.isFinal).toList();
    final done = all.where((o) => o.status.isFinal).toList();
    final asBuyer = state.role == Role.transformateur;

    Widget list(List<Order> orders, String empty) => orders.isEmpty
        ? EmptyState(icon: Icons.receipt_long, title: empty, message: asBuyer ? 'Vos achats apparaîtront ici, avec leur suivi.' : 'Vos ventes apparaîtront ici, avec leur suivi.')
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => OrderTile(
              order: orders[i],
              asBuyer: asBuyer,
              onTap: () => go<void>(context, OrderDetailScreen(order: orders[i])),
            ),
          );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(asBuyer ? 'Mes achats' : 'Mes ventes'),
          actions: const [TopActions()],
          bottom: TabBar(tabs: [Tab(text: 'En cours (${active.length})'), Tab(text: 'Terminées (${done.length})')]),
        ),
        body: TabBarView(children: [list(active, 'Aucune commande en cours'), list(done, 'Aucune commande terminée')]),
      ),
    );
  }
}
