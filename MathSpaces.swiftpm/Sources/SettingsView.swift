import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @State private var showAbout = false

    var body: some View {
        NavigationView {
            List {
                // Appearance
                Section("Erscheinungsbild") {
                    HStack {
                        Label("Farbschema", systemImage: "moon.fill")
                            .foregroundColor(.appText)
                        Spacer()
                        Text("Dunkel").foregroundColor(.appDim).font(.system(size: 13))
                    }
                    .listRowBackground(Color.appCard)

                    NavigationLink {
                        AccentColourPicker()
                    } label: {
                        Label("Akzentfarbe", systemImage: "paintpalette")
                            .foregroundColor(.appText)
                    }
                    .listRowBackground(Color.appCard)
                }

                // Info
                Section("App-Info") {
                    HStack {
                        Label("Version", systemImage: "info.circle")
                            .foregroundColor(.appText)
                        Spacer()
                        Text("1.0").foregroundColor(.appDim)
                    }
                    .listRowBackground(Color.appCard)

                    HStack {
                        Label("Plattform", systemImage: "ipad")
                            .foregroundColor(.appText)
                        Spacer()
                        Text("Swift Playgrounds").foregroundColor(.appDim).font(.system(size: 13))
                    }
                    .listRowBackground(Color.appCard)

                    Button {
                        showAbout = true
                    } label: {
                        Label("Über MathSpaces", systemImage: "questionmark.circle")
                            .foregroundColor(.appAccent)
                    }
                    .listRowBackground(Color.appCard)
                }

                // Features
                Section("Funktionen") {
                    FeatureRow(icon: "🧮", title: "Rechner",           desc: "Grundrechner, Gleichungen, Brüche, Einheiten")
                    FeatureRow(icon: "📐", title: "Koordinatensystem", desc: "Funktionen zeichnen, Punkte setzen")
                    FeatureRow(icon: "📝", title: "Notizen",           desc: "Schnellnotizen speichern")
                    FeatureRow(icon: "🎓", title: "Formeln+",          desc: "Formeln, Geometrie & Physikrechner")
                    FeatureRow(icon: "⏱️", title: "Klassentimer",       desc: "Countdown-Timer für Unterrichtsstunden")
                }
                .listRowBackground(Color.appCard)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color.appBg)
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("⚙️ Einstellungen")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.appText)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showAbout) { AboutView() }
    }
}

struct FeatureRow: View {
    let icon: String; let title: String; let desc: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(icon).font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.appText)
                Text(desc).font(.system(size: 12)).foregroundColor(.appDim)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Accent Colour Picker

struct AccentColourPicker: View {
    let options: [(String, Color)] = [
        ("Blau",   Color(red: 68/255,  green: 102/255, blue: 255/255)),
        ("Cyan",   Color(red: 0,       green: 180/255, blue: 255/255)),
        ("Grün",   Color(red: 0,       green: 200/255, blue: 100/255)),
        ("Lila",   Color(red: 160/255, green: 60/255,  blue: 255/255)),
        ("Orange", Color(red: 255/255, green: 140/255, blue: 0)),
        ("Rot",    Color(red: 220/255, green: 40/255,  blue: 40/255)),
    ]

    var body: some View {
        List {
            ForEach(options, id: \.0) { name, color in
                HStack {
                    Circle().fill(color).frame(width: 24, height: 24)
                    Text(name).foregroundColor(.appText)
                    Spacer()
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.appCard)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .navigationTitle("Akzentfarbe")
        .preferredColorScheme(.dark)
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [Color.appAccent, Color.blue],
                                                  startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                        Text("M")
                            .font(.system(size: 40, weight: .black))
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 6) {
                        Text("MathSpaces").font(.system(size: 24, weight: .black)).foregroundColor(.appText)
                        Text("Version 1.0").font(.system(size: 14)).foregroundColor(.appDim)
                        Text("Swift Playgrounds Edition").font(.system(size: 13)).foregroundColor(.appDim)
                    }

                    Divider().background(Color.appBorder)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Über die App")
                            .font(.system(size: 16, weight: .bold)).foregroundColor(.appText)
                        Text("MathSpaces ist eine umfassende Mathematik-App für iPad und iPhone, entwickelt mit Swift und SwiftUI.")
                            .font(.system(size: 14)).foregroundColor(.appDim).fixedSize(horizontal: false, vertical: true)
                        Text("Die App enthält einen wissenschaftlichen Taschenrechner, Gleichungslöser, Bruchrechner, Einheitenrechner, interaktives Koordinatensystem, Notizen, Formelsammlung, Geometrie- und Physikrechner sowie einen Klassen-Timer.")
                            .font(.system(size: 14)).foregroundColor(.appDim).fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(12)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Technologie")
                            .font(.system(size: 16, weight: .bold)).foregroundColor(.appText)
                        AboutTechRow(icon: "swift",        label: "Swift 5.9")
                        AboutTechRow(icon: "rectangle.3.group", label: "SwiftUI")
                        AboutTechRow(icon: "ipad",         label: "iOS 16+")
                        AboutTechRow(icon: "play.rectangle", label: "Swift Playgrounds 4")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.appCard)
                    .cornerRadius(12)

                    Text("100% Swift – Kein HTML, kein JavaScript")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appAccent)
                        .padding(10)
                        .background(Color.appAccent.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(20)
            }
            .background(Color.appBg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") { dismiss() }.foregroundColor(.appAccent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct AboutTechRow: View {
    let icon: String; let label: String
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundColor(.appAccent).frame(width: 20)
            Text(label).font(.system(size: 14)).foregroundColor(.appText)
        }
    }
}
