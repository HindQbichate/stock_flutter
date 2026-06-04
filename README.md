# 📦 StockFlutter — Application SAAS de Gestion de Stock

Application mobile Flutter de gestion de stock multi-tenant, guidée par la **Domain-Driven Design Architecture (DDDA)**.

---

## 🏗️ Architecture — DDDA (Domain-Driven Design Architecture)

```
lib/
├── core/                          # Infrastructure transversale
│   ├── constants/                 # Constantes globales
│   ├── errors/                    # Gestion des erreurs (Failures, Exceptions)
│   ├── network/                   # Configuration Dio, intercepteurs
│   ├── router/                    # GoRouter — navigation
│   ├── theme/                     # Thème global (couleurs, typographie)
│   └── utils/                     # Utilitaires partagés
│
├── features/                      # Domaines métier isolés
│   ├── auth/                      # Authentification Firebase
│   │   ├── data/                  # Sources de données, modèles, repos impl.
│   │   ├── domain/                # Entités, interfaces repos, use cases
│   │   └── presentation/          # Pages, providers Riverpod, widgets
│   │
│   ├── products/                  # Gestion des produits
│   ├── categories/                # Gestion des catégories
│   ├── movements/                 # Entrées/sorties de stock
│   └── dashboard/                 # Tableaux de bord & statistiques
│
└── shared/                        # Composants UI réutilisables
```

---

## 🛠️ Stack Technologique

| Technologie | Usage |
|---|---|
| **Flutter 3.x** | Framework mobile cross-platform |
| **GoRouter** | Navigation déclarative avec deep links |
| **Riverpod** | Gestion d'état réactive et testable |
| **Dio** | Client HTTP avec intercepteurs |
| **Firebase Auth** | Authentification email/password |
| **Cloud Firestore** | Base de données NoSQL multi-tenant |
| **FL Chart** | Graphiques interactifs dashboard |

---

## 🗄️ Modèle de données Firestore (Multi-Tenant)

```
firestore/
└── tenants/
    └── {tenantId}/                  ← Isolement par client
        ├── categories/
        │   └── {categoryId}/
        │       ├── name: string
        │       ├── description: string
        │       └── createdAt: timestamp
        │
        ├── products/
        │   └── {productId}/
        │       ├── name: string
        │       ├── categoryId: string
        │       ├── sku: string
        │       ├── quantity: number
        │       ├── threshold: number       ← Seuil d'alerte
        │       ├── price: number
        │       └── createdAt: timestamp
        │
        └── movements/
            └── {movementId}/
                ├── productId: string
                ├── type: "in" | "out"     ← Entrée ou vente
                ├── quantity: number
                ├── note: string
                └── createdAt: timestamp
```

---

## 🚀 Fonctionnalités

- ✅ **Authentification** — Email/password via Firebase Auth
- ✅ **Gestion des produits** — CRUD avec catégorie (création inline si inexistante)
- ✅ **Entrées de stock** — Réception de marchandises
- ✅ **Ventes (sorties)** — Déduction du stock en temps réel
- ✅ **Dashboard** — KPIs, graphiques fl_chart
- ✅ **État de stock** — Par plage de dates
- ✅ **Top produits vendus** — Par plage de dates
- ✅ **Ventes par catégorie** — Analyse par segment
- ✅ **Alertes seuil** — Notifications produits sous seuil d'approvisionnement

---

## ⚙️ Installation

```bash
# 1. Cloner le projet
git clone https://github.com/VOTRE_USERNAME/stock_flutter.git
cd stock_flutter

# 2. Installer les dépendances
flutter pub get

# 3. Configurer Firebase
# - Créer un projet Firebase
# - Activer Authentication (Email/Password)
# - Activer Firestore Database
# - Télécharger google-services.json → android/app/
# - Télécharger GoogleService-Info.plist → ios/Runner/

# 4. Générer les fichiers Riverpod
dart run build_runner build --delete-conflicting-outputs

# 5. Lancer l'application
flutter run
```

---

## 🧪 Tests

```bash
# Tests unitaires
flutter test test/unit/

# Tests widgets
flutter test test/widget/

# Tous les tests
flutter test --coverage
```

---

## 📱 Screenshots

| Login | Dashboard | Produits | Mouvements |
|---|---|---|---|
| *(à venir)* | *(à venir)* | *(à venir)* | *(à venir)* |

---

## 👨‍💻 Développement

Projet développé avec **Android Studio** + plugin Flutter.

**Conventions de commit :**
```
feat: nouvelle fonctionnalité
fix: correction de bug  
refactor: refactorisation
test: ajout/modification tests
docs: documentation
chore: configuration, dépendances
```
