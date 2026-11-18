import 'package:flutter/material.dart';

import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../buyer/buyer_home.dart';
import '../buyer/flash_market_screen.dart';
import '../buyer/market_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../common/wallet_screen.dart';
import '../logistics/agent_screens.dart';
import '../logistics/transporter_screens.dart';
import '../messages/conversations_screen.dart';
import '../orders/orders_screen.dart';
import '../producer/my_offers_screen.dart';
import '../producer/producer_home.dart';

class _Tab {
  const _Tab(this.label, this.icon, this.selectedIcon, this.page);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget page;
}

/// Coquille principale : barre de navigation adaptée au rôle.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  Role? _lastRole;

  List<_Tab> _tabsFor(Role role) => switch (role) {
        Role.producteur || Role.cooperative => const [
            _Tab('Accueil', Icons.home_outlined, Icons.home, ProducerHome()),
            _Tab('Mes offres', Icons.storefront_outlined, Icons.storefront, MyOffersScreen()),
            _Tab('Commandes', Icons.receipt_long_outlined, Icons.receipt_long, OrdersScreen()),
            _Tab('Portefeuille', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, WalletScreen()),
            _Tab('Plus', Icons.menu, Icons.menu, ProfileScreen()),
          ],
        Role.transformateur => const [
            _Tab('Accueil', Icons.home_outlined, Icons.home, BuyerHome()),
            _Tab('Marché', Icons.search, Icons.search, MarketScreen()),
            _Tab('Flash', Icons.bolt_outlined, Icons.bolt, FlashMarketScreen()),
            _Tab('Commandes', Icons.receipt_long_outlined, Icons.receipt_long, OrdersScreen()),
            _Tab('Plus', Icons.menu, Icons.menu, ProfileScreen()),
          ],
        Role.transporteur => const [
            _Tab('Missions', Icons.route_outlined, Icons.route, TransporterHome()),
            _Tab('Gains', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet, WalletScreen()),
            _Tab('Plus', Icons.menu, Icons.menu, ProfileScreen()),
          ],
        Role.agent => const [
            _Tab('Contrôles', Icons.fact_check_outlined, Icons.fact_check, AgentHome()),
            _Tab('Historique', Icons.history, Icons.history, AgentHistoryScreen()),
            _Tab('Plus', Icons.menu, Icons.menu, ProfileScreen()),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final role = state.role;
    if (_lastRole != role) {
      _lastRole = role;
      _index = 0;
    }
    final tabs = _tabsFor(role);
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: IndexedStack(
              key: ValueKey(role),
              index: _index,
              children: [for (final t in tabs) t.page],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(
              icon: t.label == 'Commandes'
                  ? CountBadge(count: state.activeOrders.where((o) => o.status == OrderStatus.payeeSequestre || o.status == OrderStatus.livree).length, child: Icon(t.icon))
                  : Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

/// Icônes « messages » et « notifications » des barres de titre.
class TopActions extends StatelessWidget {
  const TopActions({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.role != Role.agent)
          IconButton(
            tooltip: 'Messages',
            onPressed: () => go<void>(context, const ConversationsScreen()),
            icon: CountBadge(count: state.unreadMessages, child: const Icon(Icons.chat_bubble_outline)),
          ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => go<void>(context, const NotificationsScreen()),
          icon: CountBadge(count: state.unreadNotifications, child: const Icon(Icons.notifications_outlined)),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
