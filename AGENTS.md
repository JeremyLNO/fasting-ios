# AGENTS.md — règles de collaboration (Claude Code ⇄ Xcode local)

Ce fichier fige comment on travaille à deux sur **Fasting** (app iOS native). Il sert aussi
de référence aux sessions Claude Code : à lire avant toute modification.

## Le projet
- App de jeûne intermittent **SwiftUI + WidgetKit + ActivityKit + AppIntents**, nom « Fasting ».
- UI **multilingue** (anglais par défaut, FR/DE/ES) via `Shared/Localization.swift` (`L.t(key, lang)`) — pas de chaînes en dur dans les vues.
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
- Runtimes simulateur **iOS 18.6 / 26.3 / 26.4 / 26.5** installés sur cette machine (Xcode → Settings
  → Components pour en ajouter d'autres). `DEVELOPMENT_TEAM` est configuré (équipe payante, nécessaire
  pour l'App Group — voir README) ; signature auto activée sur les 2 targets.
- **Bac à sable de build de Claude** : compile une copie *allégée* dans `/tmp/fasting-verify`
  (sans `Assets.xcassets`, `CODE_SIGNING_ALLOWED=NO`) pour vérifier la compilation + lancer dans
  `simctl` (device UDID à relister si le fichier `/tmp/fasting_udid.txt` a été purgé entre sessions).
  **Ne jamais éditer `/tmp`** — c'est jetable. Le vrai projet (avec icône/assets) est `~/fasting-app`.

## Architecture
- **Targets** : `Fasting` (app, bundle `company.lno.fasting`) + `FastingWidget`
  (extension, `company.lno.fasting.FastingWidget`). App Group `group.company.lno.fasting` **activé**
  (nécessite une équipe payante — sinon vider les 2 `.entitlements` en `<dict/>`, cf. README).
- **`Shared/`** compilé dans **les deux** targets : modèle (+ presets + fenêtres passées), store
  App Group (schedule + eau), historique (`HistoryStore`), palette, vues, contenu widget, Live
  Activity (attributs + vues), localisation.
- **`Fasting/`** = app uniquement (Settings, Onboarding, History, Account/Auth, notifs).
  **`FastingWidget/`** = widget uniquement (widgets, Live Activity, `WaterIntents` AppIntents).
- **App gratuite, pas de StoreKit/IAP** : aucun essai, aucun paywall — `RootView` va direct à
  `ContentView` après l'onboarding. `AppInstall.swift` (ex-`Trial`) ne sert plus qu'à ancrer
  l'historique/séries, plus à compter un essai.
- **Session manuelle** (tap sur l'anneau pour démarrer/interrompre à tout moment) : `ManualSession`
  + `FastingSchedule.effectiveState(at:override:)` dans `Shared/FastingModel.swift`, persistée via
  `SharedStore.manualOverride()` (App Group → app, widgets et Dynamic Island cohérents). Toujours
  utiliser `effectiveState(at:override:)`, jamais `state(at:)` seul, dans tout nouveau consommateur
  d'état (widget, Live Activity, etc.) sous peine d'ignorer une session manuelle en cours.
  Interrompre un jeûne (dans `FastingApp.applyOverride`) appelle aussi
  `HistoryStore.logInterruption(day:targetMinutes:actualMinutes:)` **au moment précis du tap** —
  c'est le seul instant où la durée réellement écoulée est connue, avant que la session suivante
  n'écrase l'override. `syncIfNeeded` ne réécrit jamais un jour déjà enregistré, donc ce log reste
  définitif (jour affiché en orange dans le calendrier de `HistoryView`, casse la série).
- Déploiement **iOS 17+**, Swift 5 mode.
- ⚠️ **Piège récurrent** : toute vue plein-écran doit appliquer `FastingBackground` via
  `.background(FastingBackground(phase:))` sur le contenu, **jamais** en calque frère dans un
  `ZStack` — les formes décoratives (hors-cadre) élargissent alors le layout et coupent le
  contenu à gauche (bug rencontré 2 fois : écran principal, puis onboarding).

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
- **Arguments de lancement (Debug, captures/preview)** : `-skipNotifPrompt`, `-skipOnboarding`,
  `-onboardingStep <0-3>`, `-demoNow <timestamp unix>`, `-demoLang <en|fr|de|es>`,
  `-demoWater <n>`, `-demoInstallDaysAgo <n>`, `-openSettings`, `-openHistory`, `-openAccount`,
  `-startLiveActivity`, `-widgetGallery`.

## Vérification (côté Claude)
- `xcrun simctl` sur un simulateur existant ; `-demoNow`/`-demoInstallDaysAgo` pour un état
  déterministe (historique/série inclus) ; passer l'app en arrière-plan (lancer
  `com.apple.Preferences`) pour révéler la Dynamic Island.
- **Widgets interactifs (AppIntents)** : le tap réel sur un widget d'écran d'accueil ne peut pas
  être simulé via `simctl` (pas d'automation UI) — seule la compilation de la cible widget et le
  rendu visuel (via l'aperçu in-app `-widgetGallery`, composants partagés) sont vérifiables ici.

## Git
- Commit après chaque lot ; message terminé par `Co-Authored-By: Claude Opus 4.8 …`.
- Push sur `origin main` → déclenche le build cloud **GitHub Actions** (`.github/workflows/ios.yml`).
