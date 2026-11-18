# MARCHE.CM — Application mobile (Flutter)

Plateforme de mise en relation entre **producteurs agricoles** et **transformateurs agroalimentaires** au Cameroun.
Projet DUT — IUT de Douala (Victor, James, Lucresse).

Cette branche contient le **front end complet** de l'application, branché sur des **données de démonstration**
(`lib/data/mock_data.dart`). Chaque action de `lib/data/app_state.dart` correspond à un point de l'API prévue
(NestJS + PostgreSQL) : il suffira d'y remplacer le code de démo par des appels HTTP.

## Lancer l'application

```bash
flutter create . --org cm.marche --project-name marche_cm --platforms=android,ios,web   # une seule fois : génère android/, ios/, web/
flutter pub get
flutter run            # sur un téléphone Android ou un émulateur
flutter run -d chrome  # dans le navigateur
```

Connexion de démo : n'importe quel numéro `6XXXXXXXX`, puis n'importe quel code à 6 chiffres.
Dans l'onglet **Plus**, la section *Démonstration* permet de passer d'un espace à l'autre sans se déconnecter.

## Ce que contient le front end

| Espace | Écrans |
|---|---|
| Accès | Démarrage, présentation, connexion par SMS (code à 6 chiffres), choix du profil, création du profil (RCCM/NIU pour les transformateurs) |
| Producteur / coopérative | Accueil (ventes, séquestre, tâches, demandes, prix, météo), mes offres, publication d'offre, Vente Flash à prix dégressif, demandes des transformateurs, contrats pré-récolte, préfinancement, portefeuille et retraits |
| Transformateur | Accueil (suivi, Ventes Flash, recommandations), marché avec recherche et filtres, fiche offre, commande et paiement Mobile Money en séquestre, Ventes Flash avec réservation 30 min, besoins publiés, abonnement Pro |
| Commandes | Liste, suivi en frise (12 états), contrôle qualité et QR code, confirmation de réception, notation, litige |
| Transporteur | Missions proposées / en cours / terminées, démarrage par scan, livraison, gains |
| Agent terrain | Réception des lots, pesée, grade, points de contrôle, conformité, QR code de traçabilité, historique |
| Commun | Messagerie avec masquage des numéros (anti-contournement), notifications, bourse des prix, météo, mode hors ligne simulé, charte de confiance |

## Organisation du code

```
lib/
  main.dart, app.dart        point d'entrée, thème, localisation française
  core/                      thème, mise en forme (FCFA, dates), widgets et cartes réutilisables
  data/                      modèles, données de démo, état de l'application (AppState)
  features/
    auth/                    démarrage, présentation, téléphone + code, rôle, profil
    shell/                   barre de navigation adaptée au rôle
    producer/                espace producteur
    buyer/                   espace transformateur
    orders/                  suivi de commande, litige
    messages/                messagerie
    common/                  profil, portefeuille, prix, contrats, notifications
    logistics/               transporteur et agent terrain
test/                        tests unitaires (prix Flash, séquestre, mise en relation, masquage) et tests d'écrans
```

Aucune dépendance externe en dehors du SDK Flutter : l'état est géré avec `ChangeNotifier` + `InheritedNotifier`.

## Intégration continue

À chaque push, GitHub Actions analyse le code, lance les tests et construit la version web et l'APK Android
(onglet **Actions** du dépôt, section *Artifacts*).
