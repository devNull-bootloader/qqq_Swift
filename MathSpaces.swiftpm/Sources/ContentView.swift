import SwiftUI

// MARK: - App Colour Palette

extension Color {
    static let appBg      = Color(red: 17/255,  green: 17/255,  blue: 17/255)
    static let appCard    = Color(red: 26/255,  green: 26/255,  blue: 26/255)
    static let appCard2   = Color(red: 34/255,  green: 34/255,  blue: 34/255)
    static let appBorder  = Color(red: 51/255,  green: 51/255,  blue: 51/255)
    static let appText    = Color(red: 232/255, green: 232/255, blue: 232/255)
    static let appDim     = Color(red: 136/255, green: 136/255, blue: 136/255)
    static let appAccent  = Color(red: 68/255,  green: 102/255, blue: 255/255)
    static let opBtn      = Color(red: 40/255,  green: 40/255,  blue: 80/255)
    static let eqBtn      = Color(red: 0,       green: 85/255,  blue: 204/255)
    static let clBtn      = Color(red: 153/255, green: 0,       blue: 0)
    static let secBtn     = Color(red: 42/255,  green: 42/255,  blue: 42/255)
    static let sciBtn     = Color(red: 30/255,  green: 30/255,  blue: 60/255)
}

// MARK: - App Settings (shared observable state)

class AppSettings: ObservableObject {
    @Published var colorSchemeOverride: ColorScheme? = .dark
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var settings = AppSettings()

    var body: some View {
        TabView {
            CalculatorView()
                .tabItem { Label("Rechner",       systemImage: "function") }
            CoordinateView()
                .tabItem { Label("Koord.",         systemImage: "chart.line.uptrend.xyaxis") }
            NotesView()
                .tabItem { Label("Notizen",        systemImage: "note.text") }
            FormulasView()
                .tabItem { Label("Formeln+",       systemImage: "graduationcap.fill") }
            SettingsView()
                .environmentObject(settings)
                .tabItem { Label("Einstellungen",  systemImage: "gearshape") }
        }
        .preferredColorScheme(.dark)
        .tint(.appAccent)
    }
}
