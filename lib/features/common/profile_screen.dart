import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import '../auth/phone_screen.dart';
import '../buyer/my_demands_screen.dart';
import '../buyer/pro_screen.dart';
import '../messages/conversations_screen.dart';
import '../producer/opportunities_screen.dart';
import '../producer/prefinancing_screen.dart';
import 'contracts_screen.dart';
import 'notifications_screen.dart';
import 'prices_screen.dart';

/// Onglet « Plus » : profil, raccourcis, réglages et mode démo.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final me = state.me!;
    final role = me.role;

    return Scaffold(
      appBar: AppBar(title: const Text('Plus')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    UserAvatar(me, radius: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Flexible(child: Text(me.displayName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                            if (me.verified) ...[const SizedBox(width: 4), const VerifiedBadge()],
                          ]),
                          Text('${role.label} · ${me.city}', style: const TextStyle(color: AppColors.muted)),
                          Text(prettyPhone(me.phone), style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                          if (me.reviews > 0) ...[const SizedBox(height: 4), Stars(me.rating, reviews: me.reviews)],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (role.sells || role == Role.transformateur)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _TrustCard(score: me.trustScore),
            ),
          const SectionTitle('Mon activité'),
          _Group(children: [
            if (role.sells) _Item(Icons.campaign_outlined, 'Demandes des transformateurs', () => go<void>(context, const OpportunitiesScreen())),
            if (role == Role.transformateur) _Item(Icons.campaign_outlined, 'Mes besoins publiés', () => go<void>(context, const MyDemandsScreen())),
            if (role.sells || role == Role.transformateur) _Item(Icons.handshake_outlined, 'Contrats pré-récolte', () => go<void>(context, const ContractsScreen())),
            if (role.sells) _Item(Icons.account_balance_outlined, 'Préfinancement', () => go<void>(context, const PrefinancingScreen())),
            _Item(Icons.query_stats, 'Bourse des prix et météo', () => go<void>(context, const PricesScreen())),
            if (role != Role.agent) _Item(Icons.chat_bubble_outline, 'Messages', () => go<void>(context, const ConversationsScreen()), badge: state.unreadMessages),
            _Item(Icons.notifications_outlined, 'Notifications', () => go<void>(context, const NotificationsScreen()), badge: state.unreadNotifications),
            if (role == Role.transformateur)
              _Item(Icons.workspace_premium_outlined, state.proSubscriber ? 'Abonnement Pro (actif)' : 'Passer à Pro', () => go<void>(context, const ProScreen())),
          ]),
          const SectionTitle('Réglages'),
          _Group(children: [
            SwitchListTile(
              secondary: const Icon(Icons.cloud_off_outlined),
              title: const Text('Simuler le mode hors ligne'),
              subtitle: const Text('Les actions sont mises en file d’attente'),
              value: state.offline,
              onChanged: state.setOffline,
            ),
            _Item(Icons.language, 'Langue : français', () => toast(context, 'Anglais, pidgin et fulfuldé prévus en version 2')),
            _Item(Icons.sms_outlined, 'Utiliser MARCHE.CM par SMS / USSD', () => showSuccess(context, icon: Icons.dialpad, title: '*237*7#', message: 'Depuis n’importe quel téléphone : publiez une offre, consultez les prix et confirmez vos commandes.')),
            _Item(Icons.shield_outlined, 'Charte de confiance', () => _charter(context)),
            _Item(Icons.help_outline, 'Aide et assistance', () => toast(context, 'Assistance : 6 99 00 00 00 (démo)')),
          ]),
          const SectionTitle('Démonstration'),
          _Group(children: [
            for (final r in Role.values)
              if (r != role)
                _Item(r.icon, 'Passer à l’espace ${r.label}', () {
                  state.switchRole(r);
                  toast(context, 'Espace ${r.label}');
                }),
          ]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.red),
              onPressed: () {
                state.logout();
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const PhoneScreen()), (_) => false);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('MARCHE.CM v0.1.0 · démo', style: TextStyle(color: AppColors.muted, fontSize: 12))),
        ],
      ),
    );
  }

  void _charter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Charte de confiance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 12),
              Text('1. Toutes les transactions passent par MARCHE.CM : c’est ce qui garantit le paiement et l’arbitrage.'),
              SizedBox(height: 6),
              Text('2. Le producteur ne paie aucune commission ; le transformateur paie 3 % (5 % en Vente Flash).'),
              SizedBox(height: 6),
              Text('3. Chaque lot est pesé et contrôlé au point de collecte. Un lot non conforme est remboursé.'),
              SizedBox(height: 6),
              Text('4. Les coordonnées sont masquées dans la messagerie.'),
              SizedBox(height: 6),
              Text('5. Contourner la plateforme fait perdre le badge, la note et l’accès aux Ventes Flash.'),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustCard extends StatelessWidget {
  const _TrustCard({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, color: AppColors.green),
                const SizedBox(width: 8),
                const Expanded(child: Text('Score de confiance', style: TextStyle(fontWeight: FontWeight.w700))),
                Text('${(score * 100).round()} %', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.green, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: score, minHeight: 8, backgroundColor: AppColors.greenLight, color: AppColors.green),
            ),
            const SizedBox(height: 8),
            const Text('Calculé sur vos notes, vos délais, les contrôles qualité et l’absence de litiges. Un bon score vous met en avant.', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1) const Divider(indent: 56),
            ],
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item(this.icon, this.label, this.onTap, {this.badge = 0});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge > 0) CircleAvatar(radius: 11, backgroundColor: AppColors.flash, child: Text('$badge', style: const TextStyle(fontSize: 12, color: Colors.white))),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }
}
