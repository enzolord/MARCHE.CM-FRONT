import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../shell/home_shell.dart';

class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  Role? _role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, automaticallyImplyLeading: false),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const Text('Vous êtes…', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Choisissez votre profil. Il adapte l’application à votre activité.', style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 20),
                  for (final r in Role.values)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RoleTile(role: r, selected: _role == r, onTap: () => setState(() => _role = r)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: FilledButton(
                onPressed: _role == null
                    ? null
                    : () {
                        AppScope.read(context).chooseRole(_role!);
                        go<void>(context, const ProfileSetupScreen());
                      },
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({required this.role, required this.selected, required this.onTap});

  final Role role;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenLight : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.green : AppColors.line, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: selected ? AppColors.green : AppColors.page,
              child: Icon(role.icon, color: selected ? Colors.white : AppColors.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  Text(role.tagline, style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? AppColors.green : AppColors.line),
          ],
        ),
      ),
    );
  }
}

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _company;
  late final TextEditingController _city;
  final _rccm = TextEditingController();
  final _niu = TextEditingController();
  late String _region;
  final Set<String> _products = {};

  @override
  void initState() {
    super.initState();
    final me = AppScope.read(context).me!;
    _name = TextEditingController(text: me.name);
    _company = TextEditingController(text: me.company ?? '');
    _city = TextEditingController(text: me.city);
    _region = me.region;
    if (me.role.sells) _products.addAll(['tomate', 'plantain', 'piment']);
  }

  @override
  void dispose() {
    for (final c in [_name, _company, _city, _rccm, _niu]) {
      c.dispose();
    }
    super.dispose();
  }

  void _finish() {
    if (!_form.currentState!.validate()) return;
    final state = AppScope.read(context);
    state.updateProfile(name: _name.text.trim(), city: _city.text.trim(), region: _region, company: _company.text);
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const HomeShell()), (_) => false);
    if (state.role == Role.transformateur && _rccm.text.isNotEmpty) {
      toast(context, 'Documents envoyés : vérification sous 24 h');
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = AppScope.of(context).role;
    final business = role == Role.transformateur || role == Role.cooperative || role == Role.transporteur;
    return Scaffold(
      appBar: AppBar(title: const Text('Votre profil')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Pill(role.label, color: AppColors.green, icon: role.icon),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nom et prénom'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Nom requis' : null,
            ),
            if (business) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _company,
                decoration: InputDecoration(labelText: role == Role.cooperative ? 'Nom de la coopérative / du GIC' : 'Raison sociale'),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(labelText: 'Ville ou village', prefixIcon: Icon(Icons.place_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Localité requise' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _region,
              decoration: const InputDecoration(labelText: 'Région'),
              items: [for (final r in Catalog.regions) DropdownMenuItem(value: r, child: Text(r))],
              onChanged: (v) => setState(() => _region = v ?? _region),
            ),
            if (role.sells) ...[
              const SectionTitle('Ce que vous produisez', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in Catalog.all)
                    FilterChip(
                      label: Text('${p.emoji} ${p.name}'),
                      selected: _products.contains(p.id),
                      onSelected: (v) => setState(() => v ? _products.add(p.id) : _products.remove(p.id)),
                    ),
                ],
              ),
            ],
            if (role == Role.transformateur) ...[
              const SectionTitle('Vérification de l’entreprise', padding: EdgeInsets.fromLTRB(0, 20, 0, 8)),
              TextFormField(controller: _rccm, decoration: const InputDecoration(labelText: 'Numéro RCCM')),
              const SizedBox(height: 12),
              TextFormField(controller: _niu, decoration: const InputDecoration(labelText: 'NIU (numéro d’identifiant unique)')),
              const SizedBox(height: 12),
              const InfoBanner(
                icon: Icons.verified_user_outlined,
                text: 'Un administrateur vérifie ces informations avant votre premier achat. Les producteurs voient le badge « vérifié ».',
              ),
            ],
            const SizedBox(height: 28),
            FilledButton(onPressed: _finish, child: const Text('Accéder à mon espace')),
          ],
        ),
      ),
    );
  }
}
