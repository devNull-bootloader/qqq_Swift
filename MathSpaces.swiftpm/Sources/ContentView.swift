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
    @AppStorage("ms_accent") var accentColorName: String = "Blau"

    var resolvedAccent: Color {
        switch accentColorName {
        case "Cyan":   return Color(red: 0,       green: 180/255, blue: 255/255)
        case "Grün":   return Color(red: 0,       green: 200/255, blue: 100/255)
        case "Lila":   return Color(red: 160/255, green: 60/255,  blue: 255/255)
        case "Orange": return Color(red: 255/255, green: 140/255, blue: 0)
        case "Rot":    return Color(red: 220/255, green: 40/255,  blue: 40/255)
        default:       return Color(red: 68/255,  green: 102/255, blue: 255/255)  // Blau
        }
    }
}

// MARK: - ContentView

struct ContentView: View {
    @StateObject private var settings = AppSettings()
    @StateObject private var calcModel = CalculatorModel()

    @State private var selectedTab: Int = 0
    @State private var calcSubTab: Int = 0

    @FocusState private var captureKeyboard: Bool

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                CalculatorView(model: calcModel, subTab: $calcSubTab)
                    .environmentObject(settings)
                    .tabItem { Label("Rechner",       systemImage: "function") }
                    .tag(0)
                CoordinateView()
                    .environmentObject(settings)
                    .tabItem { Label("Koord.",         systemImage: "chart.line.uptrend.xyaxis") }
                    .tag(1)
                NotesView()
                    .environmentObject(settings)
                    .tabItem { Label("Notizen",        systemImage: "note.text") }
                    .tag(2)
                FormulasView()
                    .environmentObject(settings)
                    .tabItem { Label("Formeln+",       systemImage: "graduationcap.fill") }
                    .tag(3)
                SettingsView()
                    .environmentObject(settings)
                    .tabItem { Label("Einstellungen",  systemImage: "gearshape") }
                    .tag(4)
            }

            // Global hidden TextField: captures hardware keyboard input
            // for Calculator's Rechner subtab (custom keypad – no native TextField to focus).
            TextField("", text: Binding(
                get: { calcModel.expression },
                set: { newValue in routeKey(newValue) }
            ))
            .focused($captureKeyboard)
            .frame(width: 0, height: 0)
            .opacity(0)
            .allowsHitTesting(false)
        }
        .preferredColorScheme(settings.colorSchemeOverride)
        .tint(settings.resolvedAccent)
        .onChange(of: selectedTab)  { _ in updateCapture() }
        .onChange(of: calcSubTab)   { _ in updateCapture() }
        .onAppear                   { updateCapture() }
    }

    /// Focus the global capture only when the basic-calculator (custom keypad) is visible.
    /// All other tab/subtab views use native TextFields / TextEditors which handle
    /// hardware keyboard input through normal SwiftUI focus themselves.
    private func updateCapture() {
        captureKeyboard = (selectedTab == 0 && calcSubTab == 0)
    }

    /// Route a hardware key event (delivered via the hidden TextField binding) to the
    /// basic-calculator model.  Called only when captureKeyboard is true.
    private func routeKey(_ newValue: String) {
        let old = calcModel.expression
        if newValue.count > old.count {
            let typed = String(newValue.dropFirst(old.count))
            for ch in typed {
                switch ch {
                case "0"..."9", ".", "+", "-", "^":
                    calcModel.input(String(ch))
                case "*":
                    calcModel.input("×")
                case "/":
                    calcModel.input("÷")
                case "(", ")":
                    calcModel.input("()")
                case "\n", "\r":
                    calcModel.evaluate()
                default:
                    let s = String(ch)
                    if "xyπ".contains(s) {
                        calcModel.input(s)
                    }
                }
            }
        } else if newValue.count < old.count {
            // Handle single or bulk deletion (e.g. select-all + delete).
            let deleteCount = old.count - newValue.count
            for _ in 0..<deleteCount { calcModel.backspace() }
        }
    }
}
