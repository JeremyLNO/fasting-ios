import Foundation

/// Supported in-app languages. English is the default; the user can switch in Settings.
enum AppLanguage: String, CaseIterable, Identifiable {
    case en, fr, de, es
    var id: String { rawValue }

    var flag: String {
        switch self {
        case .en: return "🇬🇧"
        case .fr: return "🇫🇷"
        case .de: return "🇩🇪"
        case .es: return "🇪🇸"
        }
    }

    /// Endonym (name of the language in that language).
    var name: String {
        switch self {
        case .en: return "English"
        case .fr: return "Français"
        case .de: return "Deutsch"
        case .es: return "Español"
        }
    }

    static let storageKey = "app.language"

    /// The currently selected language (defaults to English). Read from standard defaults
    /// so the app, its notifications and the Live Activity stay in sync.
    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: storageKey) ?? "en") ?? .en
    }
}

/// Tiny in-app localization table (key → per-language string).
enum L {
    static func t(_ key: String, _ lang: AppLanguage = .current) -> String {
        table[key]?[lang] ?? table[key]?[.en] ?? key
    }

    static let table: [String: [AppLanguage: String]] = [
        // Phases
        "phase_fasting": [.en: "Fasting", .fr: "Jeûne en cours", .de: "Fasten läuft", .es: "Ayuno en curso"],
        "phase_eating":  [.en: "Eating window", .fr: "Fenêtre alimentaire", .de: "Essensfenster", .es: "Ventana de comida"],
        "phase_ready":   [.en: "Ready to fast", .fr: "Prêt à jeûner", .de: "Bereit zu fasten", .es: "Listo para ayunar"],

        // Stats
        "stat_start":     [.en: "Start", .fr: "Début", .de: "Start", .es: "Inicio"],
        "stat_remaining": [.en: "Remaining", .fr: "Restant", .de: "Übrig", .es: "Restante"],
        "stat_next_fast": [.en: "Next fast", .fr: "Prochain jeûne", .de: "Nächstes Fasten", .es: "Próximo ayuno"],
        "stat_end":       [.en: "End", .fr: "Fin", .de: "Ende", .es: "Fin"],
        "stat_late":      [.en: "Late by", .fr: "Retard", .de: "Verspätet", .es: "Retraso"],

        // Ring labels
        "ring_elapsed":   [.en: "elapsed", .fr: "écoulé", .de: "vergangen", .es: "transcurrido"],

        // Last 7 days strip
        "week_title":   [.en: "Last 7 days", .fr: "7 derniers jours", .de: "Letzte 7 Tage", .es: "Últimos 7 días"],
        "week_full":    [.en: "Full success", .fr: "Réussite complète", .de: "Voller Erfolg", .es: "Éxito completo"],
        "week_partial": [.en: "Partial", .fr: "Partiel", .de: "Teilweise", .es: "Parcial"],
        "week_today":   [.en: "TODAY", .fr: "AUJ.", .de: "HEUTE", .es: "HOY"],

        // Day editor (tap a day in the strip)
        "edit_day_title":     [.en: "Edit this day", .fr: "Modifier ce jour", .de: "Diesen Tag bearbeiten", .es: "Editar este día"],
        "edit_day_start":     [.en: "Fast started", .fr: "Jeûne commencé", .de: "Fasten begann", .es: "Ayuno empezó"],
        "edit_day_end":       [.en: "Fast ended", .fr: "Jeûne terminé", .de: "Fasten endete", .es: "Ayuno terminó"],
        "edit_day_duration":  [.en: "Duration", .fr: "Durée", .de: "Dauer", .es: "Duración"],
        "edit_day_invalid":   [.en: "The end must be after the start.", .fr: "La fin doit être après le début.", .de: "Das Ende muss nach dem Beginn liegen.", .es: "El final debe ser posterior al inicio."],
        "edit_day_clear":     [.en: "Mark as no fast", .fr: "Marquer comme sans jeûne", .de: "Als kein Fasten markieren", .es: "Marcar como sin ayuno"],
        "edit_day_goal":      [.en: "Goal %@", .fr: "Objectif %@", .de: "Ziel %@", .es: "Objetivo %@"],

        // Start-time editor (tap the START card)
        "edit_start_title":   [.en: "Adjust the start", .fr: "Ajuster le début", .de: "Beginn anpassen", .es: "Ajustar el inicio"],
        "edit_start_fasting": [.en: "When did this fast actually start?", .fr: "Quand ce jeûne a-t-il vraiment commencé ?", .de: "Wann hat dieses Fasten wirklich begonnen?", .es: "¿Cuándo empezó realmente este ayuno?"],
        "edit_start_eating":  [.en: "When did this eating window actually start?", .fr: "Quand cette fenêtre alimentaire a-t-elle vraiment commencé ?", .de: "Wann hat dieses Essensfenster wirklich begonnen?", .es: "¿Cuándo empezó realmente esta ventana de comida?"],
        "edit_start_future":  [.en: "The start can't be in the future.", .fr: "Le début ne peut pas être dans le futur.", .de: "Der Beginn kann nicht in der Zukunft liegen.", .es: "El inicio no puede estar en el futuro."],
        "edit_ends_at":       [.en: "Ends at %@", .fr: "Se termine à %@", .de: "Endet um %@", .es: "Termina a las %@"],

        // Stage hint
        "next_stage": [.en: "Next stage", .fr: "Prochaine étape", .de: "Nächste Phase", .es: "Próxima etapa"],
        "word_in":    [.en: "in", .fr: "dans", .de: "in", .es: "en"],

        // Live tracking button
        "btn_track": [.en: "Track in Dynamic Island", .fr: "Suivre dans la Dynamic Island", .de: "In Dynamic Island verfolgen", .es: "Seguir en la Isla Dinámica"],
        "btn_stop":  [.en: "Stop live tracking", .fr: "Arrêter le suivi en direct", .de: "Live-Verfolgung stoppen", .es: "Detener el seguimiento"],

        // Manual start/interrupt (tap the ring)
        "tap_to_end":   [.en: "Tap the ring to end your fast now", .fr: "Touche l'anneau pour arrêter ton jeûne maintenant", .de: "Tippe auf den Ring, um dein Fasten jetzt zu beenden", .es: "Toca el anillo para terminar tu ayuno ahora"],
        "tap_to_start": [.en: "Tap the ring to start fasting now", .fr: "Touche l'anneau pour démarrer ton jeûne maintenant", .de: "Tippe auf den Ring, um jetzt mit dem Fasten zu beginnen", .es: "Toca el anillo para empezar a ayunar ahora"],
        "tap_to_start_overdue": [.en: "Your fast hasn't started — tap the ring to start it", .fr: "Ton jeûne n'a pas démarré — touche l'anneau pour le lancer", .de: "Dein Fasten läuft nicht — tippe auf den Ring, um es zu starten", .es: "Tu ayuno no ha empezado — toca el anillo para iniciarlo"],
        "end_fast_confirm_title":  [.en: "End your fast now?", .fr: "Arrêter ton jeûne maintenant ?", .de: "Fasten jetzt beenden?", .es: "¿Terminar tu ayuno ahora?"],
        "end_fast_confirm_body":   [.en: "Your eating window starts now. The next fast won't start on its own — we'll remind you at your usual hour.", .fr: "Ta fenêtre alimentaire commence maintenant. Le prochain jeûne ne démarrera pas tout seul : on te le rappellera à ton heure habituelle.", .de: "Dein Essensfenster beginnt jetzt. Das nächste Fasten startet nicht von allein — wir erinnern dich zur gewohnten Zeit.", .es: "Tu ventana de comida empieza ahora. El próximo ayuno no empezará solo: te lo recordaremos a tu hora habitual."],
        "end_fast_confirm_action": [.en: "End fast now", .fr: "Arrêter le jeûne", .de: "Fasten beenden", .es: "Terminar ayuno"],

        // Settings
        "set_title":      [.en: "Settings", .fr: "Réglages", .de: "Einstellungen", .es: "Ajustes"],
        "set_fast_start": [.en: "Fast start", .fr: "Début du jeûne", .de: "Fastenbeginn", .es: "Inicio del ayuno"],
        "set_fast_end":   [.en: "Fast end", .fr: "Fin du jeûne", .de: "Fastenende", .es: "Fin del ayuno"],
        "set_save":       [.en: "Save", .fr: "Enregistrer", .de: "Speichern", .es: "Guardar"],
        "set_close":      [.en: "Close", .fr: "Fermer", .de: "Schließen", .es: "Cerrar"],
        "set_language":   [.en: "Language", .fr: "Langue", .de: "Sprache", .es: "Idioma"],
        "set_word_fasting": [.en: "fasting", .fr: "de jeûne", .de: "Fasten", .es: "de ayuno"],
        "set_word_eating":  [.en: "eating", .fr: "pour manger", .de: "Essen", .es: "para comer"],

        // Notifications
        "notif_start_title": [.en: "Fast started 🌙", .fr: "Jeûne démarré 🌙", .de: "Fasten gestartet 🌙", .es: "Ayuno iniciado 🌙"],
        "notif_start_body":  [.en: "Your %@ fast begins now. You've got this!", .fr: "Ton jeûne de %@ commence maintenant. Courage !", .de: "Dein %@-Fasten beginnt jetzt. Du schaffst das!", .es: "Tu ayuno de %@ comienza ahora. ¡Tú puedes!"],
        "notif_end_title":   [.en: "Fast complete ✅", .fr: "Jeûne terminé ✅", .de: "Fasten abgeschlossen ✅", .es: "Ayuno completado ✅"],
        "notif_end_body":    [.en: "Well done! You can open your eating window.", .fr: "Bravo ! Tu peux ouvrir ta fenêtre alimentaire.", .de: "Gut gemacht! Du kannst dein Essensfenster öffnen.", .es: "¡Bien hecho! Puedes abrir tu ventana de comida."],

        // Nudges after a fast was stopped early — the next one doesn't start on its own.
        "notif_restart1_title": [.en: "Ready to fast? 🌙", .fr: "Prêt à jeûner ? 🌙", .de: "Bereit zu fasten? 🌙", .es: "¿Listo para ayunar? 🌙"],
        "notif_restart1_body":  [.en: "It's your usual time. Open the app to start your fast.", .fr: "C'est ton heure habituelle. Ouvre l'app pour lancer ton jeûne.", .de: "Es ist deine übliche Zeit. Öffne die App, um dein Fasten zu starten.", .es: "Es tu hora habitual. Abre la app para iniciar tu ayuno."],
        "notif_restart2_title": [.en: "Your fast hasn't started", .fr: "Ton jeûne n'a pas démarré", .de: "Dein Fasten hat nicht begonnen", .es: "Tu ayuno no ha empezado"],
        "notif_restart2_body":  [.en: "Start it now and it will still finish at your usual hour.", .fr: "Lance-le maintenant, il se terminera quand même à ton heure habituelle.", .de: "Starte es jetzt, es endet trotzdem zur gewohnten Zeit.", .es: "Inícialo ahora y terminará igualmente a tu hora habitual."],

        // Live Activity
        "la_end":       [.en: "End", .fr: "Fin", .de: "Ende", .es: "Fin"],
        "la_ends_at":   [.en: "ends at", .fr: "fin à", .de: "endet um", .es: "termina a las"],

        // Metabolic stages (name + detail)
        "stage_digestion":        [.en: "Digestion", .fr: "Digestion", .de: "Verdauung", .es: "Digestión"],
        "stage_digestion_detail": [.en: "Your body is digesting the last meal", .fr: "Le corps digère le dernier repas", .de: "Der Körper verdaut die letzte Mahlzeit", .es: "El cuerpo digiere la última comida"],
        "stage_glycemia":         [.en: "Blood sugar dropping", .fr: "Glycémie en baisse", .de: "Blutzucker sinkt", .es: "Glucemia bajando"],
        "stage_glycemia_detail":  [.en: "Blood sugar is coming down", .fr: "La glycémie redescend", .de: "Der Blutzucker sinkt", .es: "La glucemia baja"],
        "stage_glycogen":         [.en: "Glycogen stores", .fr: "Réserves de glycogène", .de: "Glykogenspeicher", .es: "Reservas de glucógeno"],
        "stage_glycogen_detail":  [.en: "Burning through glycogen", .fr: "Le corps puise dans le glycogène", .de: "Der Körper nutzt Glykogen", .es: "El cuerpo usa el glucógeno"],
        "stage_fatburn":          [.en: "Fat burning", .fr: "Combustion des graisses", .de: "Fettverbrennung", .es: "Quema de grasa"],
        "stage_fatburn_detail":   [.en: "Switching to fat burning", .fr: "Passage en mode lipolyse", .de: "Umstellung auf Fettverbrennung", .es: "Cambio a quema de grasa"],
        "stage_ketosis":          [.en: "Ketosis", .fr: "Cétose", .de: "Ketose", .es: "Cetosis"],
        "stage_ketosis_detail":   [.en: "Producing ketones", .fr: "Production de corps cétoniques", .de: "Ketone werden gebildet", .es: "Producción de cetonas"],
        "stage_autophagy":        [.en: "Autophagy", .fr: "Autophagie", .de: "Autophagie", .es: "Autofagia"],
        "stage_autophagy_detail": [.en: "Cellular cleanup underway", .fr: "Nettoyage cellulaire enclenché", .de: "Zellreinigung beginnt", .es: "Limpieza celular en marcha"],
        "stage_extended":         [.en: "Extended fast", .fr: "Jeûne prolongé", .de: "Verlängertes Fasten", .es: "Ayuno prolongado"],
        "stage_extended_detail":  [.en: "Deeper benefits", .fr: "Bénéfices renforcés", .de: "Verstärkte Vorteile", .es: "Beneficios reforzados"],

        // Free app (Crazy Bee Labs commitment)
        "free_badge_title":    [.en: "Free app", .fr: "Application gratuite", .de: "Kostenlose App", .es: "Aplicación gratuita"],
        "free_badge_subtitle": [.en: "Fasting made easy is free, part of Crazy Bee Labs' commitment.", .fr: "Fasting made easy est gratuite, dans le cadre de l'engagement Crazy Bee Labs.", .de: "Fasting made easy ist kostenlos, Teil des Engagements von Crazy Bee Labs.", .es: "Fasting made easy es gratis, parte del compromiso de Crazy Bee Labs."],

        "water_title": [.en: "Water", .fr: "Eau", .de: "Wasser", .es: "Agua"],
        "water_done":  [.en: "Goal reached!", .fr: "Objectif atteint !", .de: "Ziel erreicht!", .es: "¡Objetivo logrado!"],
        "support":     [.en: "Support & ideas", .fr: "Support et idées", .de: "Support & Ideen", .es: "Soporte e ideas"],

        // History
        "history_title":  [.en: "History", .fr: "Historique", .de: "Verlauf", .es: "Historial"],
        "history_streak": [.en: "Current streak", .fr: "Série actuelle", .de: "Aktuelle Serie", .es: "Racha actual"],
        "history_best":   [.en: "Best streak", .fr: "Meilleure série", .de: "Beste Serie", .es: "Mejor racha"],
        "history_total":  [.en: "Fasts completed", .fr: "Jeûnes complétés", .de: "Abgeschlossene Fastenperioden", .es: "Ayunos completados"],
        "history_avg":    [.en: "Average duration", .fr: "Durée moyenne", .de: "Durchschnittliche Dauer", .es: "Duración media"],
        "history_last":   [.en: "Last 4 weeks", .fr: "4 dernières semaines", .de: "Letzte 4 Wochen", .es: "Últimas 4 semanas"],
        "history_days":   [.en: "days", .fr: "jours", .de: "Tage", .es: "días"],
        "history_empty":  [.en: "Your streak starts with your first completed fast.", .fr: "Ta série commence avec ton premier jeûne complété.", .de: "Deine Serie beginnt mit deinem ersten abgeschlossenen Fasten.", .es: "Tu racha empieza con tu primer ayuno completado."],
        "history_legend_completed":   [.en: "Completed", .fr: "Complété", .de: "Abgeschlossen", .es: "Completado"],
        "history_legend_interrupted": [.en: "Interrupted", .fr: "Interrompu", .de: "Unterbrochen", .es: "Interrumpido"],
        "history_legend_none":        [.en: "No data", .fr: "Aucune donnée", .de: "Keine Daten", .es: "Sin datos"],

        // Presets
        "set_presets": [.en: "Quick presets", .fr: "Préréglages rapides", .de: "Schnellauswahl", .es: "Preajustes rápidos"],

        // Water goal & reminders
        "water_goal_label":      [.en: "Daily goal", .fr: "Objectif quotidien", .de: "Tagesziel", .es: "Objetivo diario"],
        "water_goal_glasses":    [.en: "%d glasses", .fr: "%d verres", .de: "%d Gläser", .es: "%d vasos"],
        "water_reminders_label": [.en: "Water reminders", .fr: "Rappels pour boire", .de: "Trinkerinnerungen", .es: "Recordatorios de agua"],
        "water_reminder_title":  [.en: "Time to hydrate 💧", .fr: "C'est l'heure de boire 💧", .de: "Zeit zu trinken 💧", .es: "Hora de hidratarse 💧"],
        "water_reminder_body":   [.en: "Don't forget to drink some water.", .fr: "N'oublie pas de boire de l'eau.", .de: "Vergiss nicht, Wasser zu trinken.", .es: "No olvides beber agua."],

        // Onboarding
        "onb_welcome_title":    [.en: "Welcome to Fasting made easy", .fr: "Bienvenue sur Fasting made easy", .de: "Willkommen bei Fasting made easy", .es: "Bienvenido a Fasting made easy"],
        "onb_welcome_subtitle": [.en: "A simple way to track your intermittent fasting, right from your home screen.", .fr: "Un moyen simple de suivre ton jeûne intermittent, depuis ton écran d'accueil.", .de: "Eine einfache Art, dein intermittierendes Fasten zu verfolgen — direkt vom Homescreen.", .es: "Una forma sencilla de seguir tu ayuno intermitente, desde tu pantalla de inicio."],
        "onb_language_title":   [.en: "Choose your language", .fr: "Choisis ta langue", .de: "Wähle deine Sprache", .es: "Elige tu idioma"],
        "onb_schedule_title":   [.en: "Pick your fasting schedule", .fr: "Choisis ton programme de jeûne", .de: "Wähle deinen Fastenplan", .es: "Elige tu horario de ayuno"],
        "onb_schedule_subtitle":[.en: "You can fine-tune the exact times anytime in Settings.", .fr: "Tu pourras affiner les horaires exacts à tout moment dans les réglages.", .de: "Du kannst die genauen Zeiten jederzeit in den Einstellungen anpassen.", .es: "Puedes ajustar las horas exactas cuando quieras en Ajustes."],
        "onb_notif_title":      [.en: "Stay on track", .fr: "Reste sur la bonne voie", .de: "Bleib dran", .es: "Mantente en el camino"],
        "onb_notif_subtitle":   [.en: "We'll send you a notification when your fast starts and ends.", .fr: "Tu recevras une notification au début et à la fin de ton jeûne.", .de: "Wir benachrichtigen dich, wenn dein Fasten beginnt und endet.", .es: "Te avisaremos cuando tu ayuno empiece y termine."],
        "onb_free_title":       [.en: "Free, thanks to Crazy Bee Labs", .fr: "Gratuite, grâce à Crazy Bee Labs", .de: "Kostenlos, dank Crazy Bee Labs", .es: "Gratis, gracias a Crazy Bee Labs"],
        "onb_free_subtitle":    [.en: "Fasting made easy is part of Crazy Bee Labs' commitment to simple, honest apps — free, with no trial and no subscription.", .fr: "Fasting made easy fait partie de l'engagement de Crazy Bee Labs pour des applications simples et honnêtes — gratuite, sans essai ni abonnement.", .de: "Fasting made easy ist Teil von Crazy Bee Labs' Engagement für einfache, ehrliche Apps — kostenlos, ohne Testphase und ohne Abo.", .es: "Fasting made easy forma parte del compromiso de Crazy Bee Labs con aplicaciones simples y honestas — gratis, sin prueba ni suscripción."],
        "onb_free_feature":     [.en: "No trial. No subscription. Ever.", .fr: "Aucun essai. Aucun abonnement. Jamais.", .de: "Keine Testphase. Kein Abo. Nie.", .es: "Sin prueba. Sin suscripción. Nunca."],
        "onb_continue":         [.en: "Continue", .fr: "Continuer", .de: "Weiter", .es: "Continuar"],
        "onb_get_started":      [.en: "Get started", .fr: "C'est parti", .de: "Los geht's", .es: "Empezar"],

        // Commitment screen (one-time, before onboarding — same pattern as the other free
        // Crazy Bee Labs apps, cf. Respire's CommitmentView)
        "commit_title":     [.en: "Fasting made easy is free, for real", .fr: "Fasting made easy est gratuite, pour de vrai", .de: "Fasting made easy ist kostenlos, wirklich", .es: "Fasting made easy es gratis, de verdad"],
        "commit_why_title": [.en: "Why it's free", .fr: "Pourquoi c'est gratuit", .de: "Warum sie kostenlos ist", .es: "Por qué es gratis"],
        "commit_why_body":  [.en: "Taking care of your health should never depend on what's in your bank account. So here: no subscription, no in-app purchase, no feature locked behind a paywall.", .fr: "Prendre soin de sa santé ne devrait jamais dépendre de ce qu'il y a sur ton compte. Alors ici : pas d'abonnement, pas d'achat intégré, pas de fonctionnalité verrouillée derrière un paywall.", .de: "Auf deine Gesundheit zu achten sollte nie davon abhängen, was auf deinem Konto ist. Deshalb hier: kein Abo, kein In-App-Kauf, keine Funktion hinter einer Paywall.", .es: "Cuidar tu salud nunca debería depender de lo que haya en tu cuenta. Así que aquí: sin suscripción, sin compras integradas, sin funciones bloqueadas tras un muro de pago."],
        "commit_why_body2": [.en: "Your schedule, your history, the widgets and the Live Activity: everything stays available, from day one to the last.", .fr: "Ton planning, ton historique, les widgets et la Live Activity : tout reste accessible, du premier jour au dernier.", .de: "Dein Plan, dein Verlauf, die Widgets und die Live Activity: alles bleibt verfügbar, vom ersten bis zum letzten Tag.", .es: "Tu horario, tu historial, los widgets y la Live Activity: todo sigue disponible, del primer día al último."],
        "commit_cbl_title": [.en: "The Crazy Bee Labs commitment", .fr: "L'engagement Crazy Bee Labs", .de: "Das Crazy Bee Labs Versprechen", .es: "El compromiso de Crazy Bee Labs"],
        "commit_cbl_body":  [.en: "Fasting made easy is part of a small family of health apps created by Crazy Bee Labs. Our rule is simple: honest tools, with no dark patterns and no needless data collection, that genuinely support you rather than sell you something.", .fr: "Fasting made easy fait partie d'une petite famille d'applications santé créées par Crazy Bee Labs. Notre règle est simple : des outils sincères, sans dark patterns ni collecte de données superflue, qui accompagnent vraiment plutôt que de vendre quelque chose.", .de: "Fasting made easy gehört zu einer kleinen Familie von Gesundheits-Apps von Crazy Bee Labs. Unsere Regel ist einfach: ehrliche Werkzeuge, ohne Dark Patterns und ohne unnötige Datensammlung, die dich wirklich begleiten, statt dir etwas zu verkaufen.", .es: "Fasting made easy forma parte de una pequeña familia de apps de salud creadas por Crazy Bee Labs. Nuestra regla es simple: herramientas sinceras, sin patrones oscuros ni recopilación de datos innecesaria, que de verdad te acompañan en lugar de venderte algo."],
        "commit_link":      [.en: "Our commitment", .fr: "Notre engagement", .de: "Unser Versprechen", .es: "Nuestro compromiso"],
        "commit_other_apps": [.en: "Discover our other apps", .fr: "Découvrir nos autres apps", .de: "Unsere anderen Apps entdecken", .es: "Descubre nuestras otras apps"],

        // Legal / compliance links
        "privacy_policy":       [.en: "Privacy Policy", .fr: "Politique de confidentialité", .de: "Datenschutzrichtlinie", .es: "Política de privacidad"],

        // Account
        "account_title":           [.en: "Account", .fr: "Compte", .de: "Konto", .es: "Cuenta"],
        "account_signin_title":    [.en: "Sign in", .fr: "Se connecter", .de: "Anmelden", .es: "Iniciar sesión"],
        "account_signin_subtitle": [.en: "Optional — sign in to have a linked account. Fasting works fully offline either way.", .fr: "Optionnel — connecte-toi pour associer un compte. Fasting fonctionne hors-ligne dans tous les cas.", .de: "Optional — melde dich an, um ein verknüpftes Konto zu haben. Fasting funktioniert in jedem Fall komplett offline.", .es: "Opcional — inicia sesión para tener una cuenta vinculada. Fasting funciona totalmente sin conexión de todas formas."],
        "account_signed_in_as":   [.en: "Signed in with Apple", .fr: "Connecté avec Apple", .de: "Angemeldet mit Apple", .es: "Sesión iniciada con Apple"],
        "account_manage_apple_id": [.en: "Manage Apple ID (password & security)", .fr: "Gérer l'identifiant Apple (mot de passe et sécurité)", .de: "Apple-ID verwalten (Passwort & Sicherheit)", .es: "Gestionar el ID de Apple (contraseña y seguridad)"],
        "account_sign_out":       [.en: "Sign out", .fr: "Se déconnecter", .de: "Abmelden", .es: "Cerrar sesión"],
        "account_delete":         [.en: "Delete account & data", .fr: "Supprimer le compte et les données", .de: "Konto & Daten löschen", .es: "Eliminar cuenta y datos"],
        "account_delete_confirm_title": [.en: "Delete account & data?", .fr: "Supprimer le compte et les données ?", .de: "Konto & Daten löschen?", .es: "¿Eliminar cuenta y datos?"],
        "account_delete_confirm_body":  [.en: "This permanently erases your schedule, water history, fasting history and preferences from this device. This can't be undone.", .fr: "Ceci efface définitivement ton planning, ton historique d'eau, ton historique de jeûne et tes préférences sur cet appareil. Action irréversible.", .de: "Dies löscht deinen Zeitplan, deinen Wasserverlauf, deinen Fastenverlauf und deine Einstellungen auf diesem Gerät dauerhaft. Kann nicht rückgängig gemacht werden.", .es: "Esto borra permanentemente tu horario, historial de agua, historial de ayuno y preferencias de este dispositivo. No se puede deshacer."],
        "account_delete_confirm_action": [.en: "Delete everything", .fr: "Tout supprimer", .de: "Alles löschen", .es: "Eliminar todo"]
    ]
}
