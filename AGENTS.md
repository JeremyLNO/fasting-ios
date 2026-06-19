# AGENTS.md — règles de collaboration (Claude Code ⇄ Xcode local)

Ce fichier fige comment on travaille à deux sur **Jeûne** (app iOS native). Il sert aussi
de référence aux sessions Claude Code : à lire avant toute modification.

## Le projet
- App de jeûne intermittent **SwiftUI + WidgetKit + ActivityKit**, UI en français.
- Dossier local : `~/fasting-app/` · Repo : `github.com/JeremyLNO/fasting-ios`.
- Le dossier local **est** le projet ouvert dans Xcode — pas de copie séparée.

## Travailler ensemble
- **Même dossier, deux éditeurs.** Claude écrit dans `~/fasting-app/` ; Xcode ouvre le même
  dossier. Les `.swift` modifiés sont rechargés automatiquement par Xcode.
- **Un seul côté à la fois sur un fichier donné** (dernier qui écrit gagne). Se prévenir avant
  de toucher un fichier que l'autre édite.
- **Changements de structure** (ajout de fichier, capabilities, build settings) = **un seul
  côté à la fois**. Ils réécrivent `project.pbxproj` :
  - Si Xcode les fait → Claude **relit** `project.pbxproj` avant de le ré-éditer.
  - Si Claude les fait à la main → Xcode rechargera le projet (accepter la fenêtre).
- **git = filet de sécurité.** Claude commit après chaque lot ; revoir les diffs dans Xcode
  via **Source Control** (⌥⌘2). Même machine ⇒ pas de `pull` nécessaire.

## Compiler & lancer
- Ouvrir `Fasting.xcodeproj`, scheme **Fasting**, **⌘R**.
- Nécessite un **runtime simulateur** (Xcode → Settings → **Components** → iOS) **ou** un
  iPhone branché (+ support plateforme iOS). ⚠️ Ce Mac n'a pas le runtime simulateur assorti
  au SDK → en ligne de commande `actool` échoue sur le catalogue d'assets ; via Xcode GUI avec
  un runtime présent, c'est OK.
- **Bac à sable de build de Claude** : compile une copie *allégée* dans `/tmp/fasting-verify`
  (sans `Assets.xcassets`) uniquement pour vérifier la compilation + lancer dans `simctl`.
  **Ne jamais éditer `/tmp`** — c'est jetable. Le vrai projet (avec icône/assets) est `~/fasting-app`.

## Architecture
- **Targets** : `Fasting` (app, bundle `company.lno.fasting`) + `FastingWidget`
  (extension, `company.lno.fasting.FastingWidget`). App Group `group.company.lno.fasting`.
- **`Shared/`** compilé dans **les deux** targets : modèle, store App Group, palette, vues,
  contenu widget, Live Activity (attributs + vues).
- **`Fasting/`** = app uniquement · **`FastingWidget/`** = widget uniquement.
- Déploiement **iOS 17+**, Swift 5 mode.

## Conventions
- `project.pbxproj` est **écrit à la main** avec un schéma d'UUID lisible :
  `AA…` groupes/projet · `BB…` targets · `CC…` produits · `DD…` config lists ·
  `EE…` build configs · `FF…` build phases · `AB…` file refs de `Shared/` ·
  `AC…` file refs app · `AD…` file refs widget · `BA…` build files app · `BD…` build files widget.
- **Ajouter un fichier partagé** = 1 `PBXFileReference` + entrée groupe `Shared` +
  **2** `PBXBuildFile` (app + widget) + entrées dans **les deux** `PBXSourcesBuildPhase`.
  (Plus simple : l'ajouter via Xcode et le laisser réécrire le pbxproj.)
- **Design system** dans `Shared/Palette.swift` + `Shared/FastingViews.swift`
  (`GlowRing`, `StatCard`, `FastingBackground`, `StageChip`, `SparkleDivider`, `PhaseBadge`).
  Style pastel / verre dépoli, teinté par phase (violet = jeûne, vert = repas).
- **Arguments de lancement (Debug, captures/preview)** :
  `-skipNotifPrompt`, `-demoNow <timestamp unix>`, `-startLiveActivity`, `-widgetGallery`.

## Vérification (côté Claude)
- `xcrun simctl` sur un simulateur existant ; `-demoNow` pour un état déterministe ;
  passer l'app en arrière-plan (lancer `com.apple.Preferences`) pour révéler la Dynamic Island.

## Git
- Commit après chaque lot ; message terminé par `Co-Authored-By: Claude Opus 4.8 …`.
- Push sur `origin main` → déclenche le build cloud **GitHub Actions** (`.github/workflows/ios.yml`).
