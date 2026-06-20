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

        // Stats
        "stat_start":     [.en: "Start", .fr: "Début", .de: "Start", .es: "Inicio"],
        "stat_remaining": [.en: "Remaining", .fr: "Restant", .de: "Übrig", .es: "Restante"],
        "stat_next_fast": [.en: "Next fast", .fr: "Prochain jeûne", .de: "Nächstes Fasten", .es: "Próximo ayuno"],
        "stat_end":       [.en: "End", .fr: "Fin", .de: "Ende", .es: "Fin"],

        // Stage hint
        "next_stage": [.en: "Next stage", .fr: "Prochaine étape", .de: "Nächste Phase", .es: "Próxima etapa"],
        "word_in":    [.en: "in", .fr: "dans", .de: "in", .es: "en"],

        // Live tracking button
        "btn_track": [.en: "Track in Dynamic Island", .fr: "Suivre dans la Dynamic Island", .de: "In Dynamic Island verfolgen", .es: "Seguir en la Isla Dinámica"],
        "btn_stop":  [.en: "Stop live tracking", .fr: "Arrêter le suivi en direct", .de: "Live-Verfolgung stoppen", .es: "Detener el seguimiento"],

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

        // Paywall
        "pay_title":         [.en: "Fasting Pro", .fr: "Fasting Pro", .de: "Fasting Pro", .es: "Fasting Pro"],
        "pay_trial_ended":   [.en: "Your free trial has ended", .fr: "Ton essai gratuit est terminé", .de: "Deine kostenlose Testphase ist beendet", .es: "Tu prueba gratuita ha terminado"],
        "pay_subtitle":      [.en: "Keep tracking your fasts, your streaks and your widgets.", .fr: "Continue à suivre tes jeûnes, tes séries et tes widgets.", .de: "Verfolge weiter dein Fasten, deine Serien und deine Widgets.", .es: "Sigue registrando tus ayunos, tus rachas y tus widgets."],
        "pay_feature_1":     [.en: "Unlimited fasting tracking", .fr: "Suivi des jeûnes illimité", .de: "Unbegrenztes Fasten-Tracking", .es: "Seguimiento de ayunos ilimitado"],
        "pay_feature_2":     [.en: "Home-screen widgets & Dynamic Island", .fr: "Widgets écran d'accueil & Dynamic Island", .de: "Widgets & Dynamic Island", .es: "Widgets y Isla Dinámica"],
        "pay_feature_3":     [.en: "All metabolic stages", .fr: "Toutes les étapes métaboliques", .de: "Alle Stoffwechselphasen", .es: "Todas las etapas metabólicas"],
        "pay_subscribe":     [.en: "Subscribe", .fr: "S'abonner", .de: "Abonnieren", .es: "Suscribirse"],
        "pay_per_year":      [.en: "%@ / year", .fr: "%@ / an", .de: "%@ / Jahr", .es: "%@ / año"],
        "pay_restore":       [.en: "Restore purchase", .fr: "Restaurer l'achat", .de: "Kauf wiederherstellen", .es: "Restaurar compra"],
        "pay_continue":      [.en: "Continue free trial", .fr: "Continuer l'essai gratuit", .de: "Kostenlose Testphase fortsetzen", .es: "Continuar prueba gratuita"],
        "pay_days_left":     [.en: "%d days left in your free trial", .fr: "%d jours restants dans ton essai gratuit", .de: "Noch %d Tage in deiner Testphase", .es: "%d días restantes de prueba gratuita"],
        "pay_one_day_left":  [.en: "Last day of your free trial", .fr: "Dernier jour de ton essai gratuit", .de: "Letzter Tag deiner Testphase", .es: "Último día de tu prueba gratuita"],
        "pay_terms":         [.en: "Auto-renewable. Cancel anytime in the App Store.", .fr: "Renouvellement automatique. Annulable à tout moment dans l'App Store.", .de: "Automatische Verlängerung. Jederzeit im App Store kündbar.", .es: "Renovación automática. Cancela cuando quieras en la App Store."],

        // Subscription status (Settings)
        "set_plan":    [.en: "Subscription", .fr: "Abonnement", .de: "Abo", .es: "Suscripción"],
        "plan_active": [.en: "Pro subscription active", .fr: "Abonnement Pro actif", .de: "Pro-Abo aktiv", .es: "Suscripción Pro activa"],
        "plan_free":   [.en: "Free trial", .fr: "Essai gratuit", .de: "Testphase", .es: "Prueba gratuita"],
        "water_title": [.en: "Water", .fr: "Eau", .de: "Wasser", .es: "Agua"],
        "water_done":  [.en: "Goal reached!", .fr: "Objectif atteint !", .de: "Ziel erreicht!", .es: "¡Objetivo logrado!"]
    ]
}
