import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/models.dart';
import 'payment_dialog.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  MobileMoney _payment = MobileMoney.mtn;

  static const _benefits = [
    (Icons.percent, 'Commission réduite à 2 %', 'Au lieu de 3 % sur chaque commande.'),
    (Icons.notifications_active, 'Alertes prioritaires', 'Vous êtes prévenu avant les autres des offres et Ventes Flash.'),
    (Icons.handshake, 'Contrats pré-récolte', 'Sécurisez vos volumes et vos prix avant la saison.'),
    (Icons.insights, 'Tableau de bord achats', 'Suivi des volumes, des prix et des fournisseurs.'),
    (Icons.support_agent, 'Assistance dédiée', 'Un conseiller pour vos litiges et vos approvisionnements.'),
  ];

  Future<void> _subscribe() async {
    final state = AppScope.read(context);
    final ok = await payWithMobileMoney(context, amount: 15000, operator: _payment, phone: state.me!.phone);
    if (!ok || !mounted) return;
    state.subscribePro(_payment);
    toast(context, 'Bienvenue dans MARCHE.CM Pro');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final pro = AppScope.of(context).proSubscriber;
    return Scaffold(
      appBar: AppBar(title: const Text('MARCHE.CM Pro')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(20)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium, color: AppColors.gold, size: 40),
                SizedBox(height: 10),
                Text('15 000 FCFA / mois', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Sans engagement. Rentabilisé dès 1,5 million FCFA d’achats par mois.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final (icon, title, text) in _benefits)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: AppColors.greenLight, child: Icon(icon, color: AppColors.green)),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(text),
            ),
          const SizedBox(height: 16),
          if (pro)
            const InfoBanner(icon: Icons.check_circle, color: AppColors.green, text: 'Votre abonnement Pro est actif.')
          else ...[
            PaymentPicker(value: _payment, onChanged: (m) => setState(() => _payment = m)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _subscribe, child: const Text('Activer Pro — 15 000 FCFA')),
          ],
        ],
      ),
    );
  }
}
