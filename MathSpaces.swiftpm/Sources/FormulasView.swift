import SwiftUI

// MARK: - Formulas+ View

struct FormulasView: View {
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Formeln +")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.appText)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.appCard)

            // Sub-tab bar
            HStack(spacing: 0) {
                formulaTabBtn(label: "🎓 Formeln",   idx: 0)
                formulaTabBtn(label: "📐 Geometrie", idx: 1)
                formulaTabBtn(label: "⚡ Physik",    idx: 2)
                formulaTabBtn(label: "⏱️ Timer",      idx: 3)
            }
            .background(Color.appCard2)

            Group {
                switch tab {
                case 0: FormulaCollectionView()
                case 1: GeometryCalculatorView()
                case 2: PhysicsCalculatorView()
                case 3: ClassTimerView()
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBg)
    }

    private func formulaTabBtn(label: String, idx: Int) -> some View {
        Button(label) { tab = idx }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .font(.system(size: 10, weight: .semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundColor(tab == idx ? .appAccent : .appDim)
            .background(tab == idx ? Color.appAccent.opacity(0.15) : Color.clear)
            .overlay(Rectangle().frame(height: 2).foregroundColor(tab == idx ? .appAccent : .clear), alignment: .bottom)
    }
}

// MARK: - Formula Collection

struct FormulaItem: Identifiable {
    let id = UUID()
    let category: String
    let name: String
    let formula: String
    let description: String
}

let formulaCollection: [FormulaItem] = [
    // Algebra
    FormulaItem(category: "Algebra", name: "1. Binomische Formel", formula: "(a+b)² = a² + 2ab + b²", description: "Quadrat einer Summe"),
    FormulaItem(category: "Algebra", name: "2. Binomische Formel", formula: "(a-b)² = a² - 2ab + b²", description: "Quadrat einer Differenz"),
    FormulaItem(category: "Algebra", name: "3. Binomische Formel", formula: "(a+b)(a-b) = a² - b²", description: "Produkt aus Summe und Differenz"),
    FormulaItem(category: "Algebra", name: "Mitternachtsformel", formula: "x = (−b ± √(b²−4ac)) / 2a", description: "Lösungsformel der quadratischen Gleichung ax²+bx+c=0"),
    FormulaItem(category: "Algebra", name: "Lineare Funktion", formula: "y = m·x + b", description: "m = Steigung, b = y-Achsenabschnitt"),
    FormulaItem(category: "Algebra", name: "Potenzgesetz (Multiplikation)", formula: "aⁿ · aᵐ = aⁿ⁺ᵐ", description: "Gleiche Basis: Exponenten addieren"),
    FormulaItem(category: "Algebra", name: "Potenzgesetz (Division)", formula: "aⁿ / aᵐ = aⁿ⁻ᵐ", description: "Gleiche Basis: Exponenten subtrahieren"),
    // Geometry
    FormulaItem(category: "Geometrie", name: "Satz des Pythagoras", formula: "c² = a² + b²", description: "Im rechtwinkligen Dreieck: Hypotenuse c"),
    FormulaItem(category: "Geometrie", name: "Kreisfläche", formula: "A = π · r²", description: "r = Radius"),
    FormulaItem(category: "Geometrie", name: "Kreisumfang", formula: "U = 2 · π · r", description: "r = Radius"),
    FormulaItem(category: "Geometrie", name: "Dreieck Fläche", formula: "A = ½ · g · h", description: "g = Grundlinie, h = Höhe"),
    FormulaItem(category: "Geometrie", name: "Rechteck Fläche", formula: "A = a · b", description: "a, b = Seiten"),
    FormulaItem(category: "Geometrie", name: "Trapez Fläche", formula: "A = (a+c)/2 · h", description: "a, c = parallele Seiten, h = Höhe"),
    FormulaItem(category: "Geometrie", name: "Zylinder Volumen", formula: "V = π · r² · h", description: "r = Radius, h = Höhe"),
    FormulaItem(category: "Geometrie", name: "Kugel Volumen", formula: "V = (4/3) · π · r³", description: "r = Radius"),
    FormulaItem(category: "Geometrie", name: "Kegel Volumen", formula: "V = (1/3) · π · r² · h", description: "r = Radius, h = Höhe"),
    // Trigonometry
    FormulaItem(category: "Trigonometrie", name: "Sinus", formula: "sin(α) = Gegenkathete / Hypotenuse", description: "Im rechtwinkligen Dreieck"),
    FormulaItem(category: "Trigonometrie", name: "Kosinus", formula: "cos(α) = Ankathete / Hypotenuse", description: "Im rechtwinkligen Dreieck"),
    FormulaItem(category: "Trigonometrie", name: "Tangens", formula: "tan(α) = Gegenkathete / Ankathete", description: "Im rechtwinkligen Dreieck"),
    FormulaItem(category: "Trigonometrie", name: "Einheitskreis", formula: "sin²(α) + cos²(α) = 1", description: "Trigonometrischer Pythagoras"),
    // Physics
    FormulaItem(category: "Physik", name: "Ohmsches Gesetz", formula: "U = R · I", description: "U = Spannung (V), R = Widerstand (Ω), I = Strom (A)"),
    FormulaItem(category: "Physik", name: "Geschwindigkeit", formula: "v = s / t", description: "v = Geschwindigkeit, s = Strecke, t = Zeit"),
    FormulaItem(category: "Physik", name: "Kraft", formula: "F = m · a", description: "F = Kraft (N), m = Masse (kg), a = Beschleunigung (m/s²)"),
    FormulaItem(category: "Physik", name: "Kinetische Energie", formula: "Eₖ = ½ · m · v²", description: "m = Masse, v = Geschwindigkeit"),
    FormulaItem(category: "Physik", name: "Potenzielle Energie", formula: "Eₚ = m · g · h", description: "m = Masse, g = 9.81 m/s², h = Höhe"),
    FormulaItem(category: "Physik", name: "Leistung", formula: "P = W / t", description: "P = Leistung (W), W = Arbeit (J), t = Zeit (s)"),
    // Statistics
    FormulaItem(category: "Statistik", name: "Arithmetisches Mittel", formula: "x̄ = (x₁ + x₂ + … + xₙ) / n", description: "Summe aller Werte geteilt durch Anzahl"),
    FormulaItem(category: "Statistik", name: "Varianz", formula: "σ² = Σ(xᵢ - x̄)² / n", description: "Mittlere quadratische Abweichung"),
    FormulaItem(category: "Statistik", name: "Standardabweichung", formula: "σ = √(Σ(xᵢ - x̄)² / n)", description: "Wurzel der Varianz"),
]

struct FormulaCollectionView: View {
    @State private var search = ""
    @State private var expandedCategory: String? = nil

    var categories: [String] { Array(Set(formulaCollection.map(\.category))).sorted() }

    var filteredFormulas: [FormulaItem] {
        if search.isEmpty { return formulaCollection }
        return formulaCollection.filter {
            $0.name.localizedCaseInsensitiveContains(search) ||
            $0.formula.localizedCaseInsensitiveContains(search) ||
            $0.description.localizedCaseInsensitiveContains(search) ||
            $0.category.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass").foregroundColor(.appDim)
                TextField("Formel suchen…", text: $search)
                    .foregroundColor(.appText)
                    .autocorrectionDisabled()
                if !search.isEmpty {
                    Button { search = "" } label: { Image(systemName: "xmark.circle.fill").foregroundColor(.appDim) }
                }
            }
            .padding(8)
            .background(Color.appCard2)
            .cornerRadius(8)
            .padding(10)

            ScrollView {
                VStack(spacing: 8) {
                    if search.isEmpty {
                        ForEach(categories, id: \.self) { cat in
                            let items = formulaCollection.filter { $0.category == cat }
                            CategorySection(category: cat, items: items,
                                           expanded: expandedCategory == cat) {
                                withAnimation { expandedCategory = expandedCategory == cat ? nil : cat }
                            }
                        }
                    } else {
                        ForEach(filteredFormulas) { item in
                            FormulaRow(item: item)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 20)
            }
        }
    }
}

struct CategorySection: View {
    let category: String
    let items: [FormulaItem]
    let expanded: Bool
    let toggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack {
                    Text(category)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.appText)
                    Spacer()
                    Text("\(items.count)").font(.system(size: 12)).foregroundColor(.appDim)
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.appDim)
                }
                .padding(12)
                .background(Color.appCard)
                .cornerRadius(expanded ? 0 : 8)
            }

            if expanded {
                VStack(spacing: 0) {
                    ForEach(items) { item in
                        FormulaRow(item: item)
                            .padding(.horizontal, 4)
                        Divider().background(Color.appBorder)
                    }
                }
                .background(Color.appCard.opacity(0.5))
                .cornerRadius(8)
            }
        }
        .cornerRadius(8)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct FormulaRow: View {
    let item: FormulaItem
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name).font(.system(size: 12, weight: .semibold)).foregroundColor(.appAccent)
            Text(item.formula)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.appText)
            Text(item.description).font(.system(size: 11)).foregroundColor(.appDim)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
    }
}

// MARK: - Geometry Calculator

struct GeometryCalculatorView: View {
    @State private var shape = 0
    let shapes = ["Kreis", "Rechteck", "Dreieck", "Zylinder", "Kugel", "Kegel", "Trapez"]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(shapes.enumerated()), id: \.0) { i, name in
                        Button(name) { shape = i }
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(shape == i ? Color.appAccent : Color.appCard2)
                            .cornerRadius(6)
                            .foregroundColor(.white)
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .padding(10)
            }
            .background(Color.appCard)

            ScrollView {
                Group {
                    switch shape {
                    case 0: CircleCalc()
                    case 1: RectangleCalc()
                    case 2: TriangleCalc()
                    case 3: CylinderCalc()
                    case 4: SphereCalc()
                    case 5: ConeCalc()
                    case 6: TrapezCalc()
                    default: EmptyView()
                    }
                }
                .padding(12)
            }
        }
    }
}

// MARK: Geometry sub-calculators

struct CircleCalc: View {
    @State private var r = ""
    private var radius: Double? { Double(r) }
    var area:  String { radius.map { String(format: "%g", Double.pi * $0 * $0) } ?? "—" }
    var circ:  String { radius.map { String(format: "%g", 2 * Double.pi * $0) } ?? "—" }
    var body: some View {
        GeomCard(title: "Kreis", icon: "⭕") {
            GeomInput(label: "Radius r", value: $r)
            GeomResult(label: "Fläche A = π·r²", value: area)
            GeomResult(label: "Umfang U = 2·π·r", value: circ)
        }
    }
}

struct RectangleCalc: View {
    @State private var a = ""; @State private var b = ""
    private var av: Double? { Double(a) }; private var bv: Double? { Double(b) }
    var area: String { (av != nil && bv != nil) ? String(format: "%g", av! * bv!) : "—" }
    var peri: String { (av != nil && bv != nil) ? String(format: "%g", 2*(av!+bv!)) : "—" }
    var body: some View {
        GeomCard(title: "Rechteck", icon: "▭") {
            GeomInput(label: "Seite a", value: $a)
            GeomInput(label: "Seite b", value: $b)
            GeomResult(label: "Fläche A = a·b", value: area)
            GeomResult(label: "Umfang U = 2·(a+b)", value: peri)
        }
    }
}

struct TriangleCalc: View {
    @State private var g = ""; @State private var h = ""; @State private var a = ""; @State private var b = ""; @State private var c = ""
    var area: String { (Double(g) != nil && Double(h) != nil) ? String(format: "%g", 0.5 * Double(g)! * Double(h)!) : "—" }
    var hyp:  String {
        guard let av = Double(a), let bv = Double(b) else { return "—" }
        return String(format: "%g", sqrt(av*av + bv*bv))
    }
    var body: some View {
        GeomCard(title: "Dreieck", icon: "△") {
            GeomInput(label: "Grundlinie g", value: $g)
            GeomInput(label: "Höhe h", value: $h)
            GeomResult(label: "Fläche A = ½·g·h", value: area)
            Divider().background(Color.appBorder)
            Text("Pythagoras (rechtwinkliges Dreieck)").font(.system(size: 11)).foregroundColor(.appDim)
            GeomInput(label: "Kathete a", value: $a)
            GeomInput(label: "Kathete b", value: $b)
            GeomResult(label: "Hypotenuse c = √(a²+b²)", value: hyp)
        }
    }
}

struct CylinderCalc: View {
    @State private var r = ""; @State private var h = ""
    private var rv: Double? { Double(r) }; private var hv: Double? { Double(h) }
    var vol:  String { (rv != nil && hv != nil) ? String(format: "%g", Double.pi*rv!*rv!*hv!) : "—" }
    var mant: String { (rv != nil && hv != nil) ? String(format: "%g", 2*Double.pi*rv!*hv!) : "—" }
    var body: some View {
        GeomCard(title: "Zylinder", icon: "⌀") {
            GeomInput(label: "Radius r", value: $r)
            GeomInput(label: "Höhe h", value: $h)
            GeomResult(label: "Volumen V = π·r²·h", value: vol)
            GeomResult(label: "Mantelfläche M = 2·π·r·h", value: mant)
        }
    }
}

struct SphereCalc: View {
    @State private var r = ""
    private var rv: Double? { Double(r) }
    var vol:  String { rv.map { String(format: "%g", (4.0/3.0)*Double.pi*$0*$0*$0) } ?? "—" }
    var surf: String { rv.map { String(format: "%g", 4*Double.pi*$0*$0) } ?? "—" }
    var body: some View {
        GeomCard(title: "Kugel", icon: "◉") {
            GeomInput(label: "Radius r", value: $r)
            GeomResult(label: "Volumen V = (4/3)·π·r³", value: vol)
            GeomResult(label: "Oberfläche O = 4·π·r²", value: surf)
        }
    }
}

struct ConeCalc: View {
    @State private var r = ""; @State private var h = ""
    private var rv: Double? { Double(r) }; private var hv: Double? { Double(h) }
    var vol: String { (rv != nil && hv != nil) ? String(format: "%g", (1.0/3.0)*Double.pi*rv!*rv!*hv!) : "—" }
    var sl:  String { (rv != nil && hv != nil) ? String(format: "%g", sqrt(rv!*rv!+hv!*hv!)) : "—" }
    var body: some View {
        GeomCard(title: "Kegel", icon: "△") {
            GeomInput(label: "Radius r", value: $r)
            GeomInput(label: "Höhe h", value: $h)
            GeomResult(label: "Volumen V = (1/3)·π·r²·h", value: vol)
            GeomResult(label: "Slant l = √(r²+h²)", value: sl)
        }
    }
}

struct TrapezCalc: View {
    @State private var a = ""; @State private var c = ""; @State private var h = ""
    private var av: Double? { Double(a) }; private var cv: Double? { Double(c) }; private var hv: Double? { Double(h) }
    var area: String { (av != nil && cv != nil && hv != nil) ? String(format: "%g", (av!+cv!)/2*hv!) : "—" }
    var body: some View {
        GeomCard(title: "Trapez", icon: "⌂") {
            GeomInput(label: "Seite a (oben)", value: $a)
            GeomInput(label: "Seite c (unten)", value: $c)
            GeomInput(label: "Höhe h", value: $h)
            GeomResult(label: "Fläche A = (a+c)/2 · h", value: area)
        }
    }
}

// MARK: Geometry helpers

struct GeomCard<Content: View>: View {
    let title: String; let icon: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Text(icon); Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(.appText) }
            content
        }
        .padding(14)
        .background(Color.appCard)
        .cornerRadius(10)
    }
}

struct GeomInput: View {
    let label: String
    @Binding var value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(.appDim)
            Spacer()
            TextField("0", text: $value)
                .keyboardType(.decimalPad)
                .font(.system(size: 15, design: .monospaced))
                .foregroundColor(.appText)
                .multilineTextAlignment(.trailing)
                .frame(width: 100)
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Color.appCard2)
                .cornerRadius(4)
        }
    }
}

struct GeomResult: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(.appDim)
            Spacer()
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .monospaced))
                .foregroundColor(.appAccent)
        }
        .padding(8)
        .background(Color.appAccent.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Physics Calculator

struct PhysicsCalculatorView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                OhmCalcCard()
                BMICalcCard()
                VelocityCalcCard()
                PECalcCard()
                KECalcCard()
                TempConvCard()
            }
            .padding(12)
        }
        .background(Color.appBg)
    }
}

struct OhmCalcCard: View {
    @State private var U = ""; @State private var R = ""; @State private var I = ""
    @State private var result = ""
    var body: some View {
        PhysCard(title: "⚡ Ohmsches Gesetz  U = R · I") {
            GeomInput(label: "Spannung U (V)", value: $U)
            GeomInput(label: "Widerstand R (Ω)", value: $R)
            GeomInput(label: "Strom I (A)", value: $I)
            Button("Berechnen") { calc() }
                .frame(maxWidth: .infinity).padding(8)
                .background(Color.appAccent).cornerRadius(6).foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            if !result.isEmpty {
                Text(result).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(.appAccent)
            }
        }
    }
    private func calc() {
        let uv = Double(U), rv = Double(R), iv = Double(I)
        if let r = rv, let i = iv { result = "U = \(String(format: "%g", r*i)) V" }
        else if let u = uv, let r = rv { result = "I = \(String(format: "%g", u/r)) A" }
        else if let u = uv, let i = iv { result = "R = \(String(format: "%g", u/i)) Ω" }
        else { result = "Zwei Werte eingeben" }
    }
}

struct BMICalcCard: View {
    @State private var weight = ""; @State private var height = ""
    @State private var result = ""; @State private var category = ""
    var body: some View {
        PhysCard(title: "🏃 BMI-Rechner") {
            GeomInput(label: "Gewicht (kg)", value: $weight)
            GeomInput(label: "Größe (m)",   value: $height)
            Button("Berechnen") { calc() }
                .frame(maxWidth: .infinity).padding(8)
                .background(Color.appAccent).cornerRadius(6).foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            if !result.isEmpty {
                VStack(spacing: 2) {
                    Text("BMI = \(result)").font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(.appAccent)
                    Text(category).font(.system(size: 13)).foregroundColor(.appText)
                }
            }
        }
    }
    private func calc() {
        guard let wv = Double(weight), let hv = Double(height), hv > 0 else { result = "Ungültige Eingabe"; category = ""; return }
        let bmi = wv / (hv * hv)
        result = String(format: "%.1f", bmi)
        category = bmi < 18.5 ? "Untergewicht" : bmi < 25 ? "Normalgewicht ✅" : bmi < 30 ? "Übergewicht" : "Starkes Übergewicht"
    }
}

struct VelocityCalcCard: View {
    @State private var s = ""; @State private var t = ""; @State private var v = ""
    @State private var result = ""
    var body: some View {
        PhysCard(title: "🚀 Geschwindigkeit  v = s / t") {
            GeomInput(label: "Strecke s (m)", value: $s)
            GeomInput(label: "Zeit t (s)", value: $t)
            GeomInput(label: "Geschwindigkeit v (m/s)", value: $v)
            Button("Berechnen") { calc() }
                .frame(maxWidth: .infinity).padding(8)
                .background(Color.appAccent).cornerRadius(6).foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            if !result.isEmpty { Text(result).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(.appAccent) }
        }
    }
    private func calc() {
        let sv = Double(s), tv = Double(t), vv = Double(v)
        if let sv2 = sv, let tv2 = tv, tv2 > 0 { result = "v = \(String(format: "%g", sv2/tv2)) m/s" }
        else if let vv2 = vv, let tv2 = tv { result = "s = \(String(format: "%g", vv2*tv2)) m" }
        else if let sv2 = sv, let vv2 = vv, vv2 > 0 { result = "t = \(String(format: "%g", sv2/vv2)) s" }
        else { result = "Zwei Werte eingeben" }
    }
}

struct PECalcCard: View {
    @State private var m = ""; @State private var h = ""
    @State private var result = ""
    let g = 9.81
    var body: some View {
        PhysCard(title: "🌍 Potenzielle Energie  Eₚ = m·g·h") {
            GeomInput(label: "Masse m (kg)", value: $m)
            GeomInput(label: "Höhe h (m)", value: $h)
            Button("Berechnen") { calc() }
                .frame(maxWidth: .infinity).padding(8)
                .background(Color.appAccent).cornerRadius(6).foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            if !result.isEmpty { Text(result).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(.appAccent) }
        }
    }
    private func calc() {
        guard let mv = Double(m), let hv = Double(h) else { return }
        result = "Eₚ = \(String(format: "%g", mv*g*hv)) J"
    }
}

struct KECalcCard: View {
    @State private var m = ""; @State private var v = ""
    @State private var result = ""
    var body: some View {
        PhysCard(title: "⚡ Kinetische Energie  Eₖ = ½·m·v²") {
            GeomInput(label: "Masse m (kg)", value: $m)
            GeomInput(label: "Geschwindigkeit v (m/s)", value: $v)
            Button("Berechnen") { calc() }
                .frame(maxWidth: .infinity).padding(8)
                .background(Color.appAccent).cornerRadius(6).foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            if !result.isEmpty { Text(result).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(.appAccent) }
        }
    }
    private func calc() {
        guard let mv = Double(m), let vv = Double(v) else { return }
        result = "Eₖ = \(String(format: "%g", 0.5*mv*vv*vv)) J"
    }
}

struct TempConvCard: View {
    @State private var input = ""
    @State private var fromUnit = 0
    let units = ["°C", "°F", "K"]
    @State private var results: [String] = []
    var body: some View {
        PhysCard(title: "🌡️ Temperatur-Umrechnung") {
            HStack {
                TextField("Wert", text: $input).keyboardType(.decimalPad)
                    .font(.system(size: 15, design: .monospaced)).foregroundColor(.appText)
                    .padding(8).background(Color.appCard2).cornerRadius(6)
                Picker("Von", selection: $fromUnit) {
                    ForEach(0..<units.count, id: \.self) { Text(units[$0]).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            Button("Umrechnen") { calc() }
                .frame(maxWidth: .infinity).padding(8)
                .background(Color.appAccent).cornerRadius(6).foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            ForEach(results, id: \.self) { r in
                Text(r).font(.system(size: 14, design: .monospaced)).foregroundColor(.appText)
            }
        }
    }
    private func calc() {
        guard let val = Double(input) else { return }
        var celsius: Double
        switch fromUnit {
        case 0: celsius = val
        case 1: celsius = (val - 32) * 5/9
        case 2: celsius = val - 273.15
        default: return
        }
        results = [
            "°C: \(String(format: "%.2f", celsius))",
            "°F: \(String(format: "%.2f", celsius * 9/5 + 32))",
            "K: \(String(format: "%.2f", celsius + 273.15))"
        ]
    }
}

struct PhysCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(.appText)
            content
        }
        .padding(14)
        .background(Color.appCard)
        .cornerRadius(10)
    }
}

// MARK: - Class Timer

class TimerModel: ObservableObject {
    @Published var timeRemaining: Int = 300  // seconds
    @Published var totalTime: Int = 300
    @Published var isRunning = false
    @Published var label: String = "Bereit"

    private var timer: Timer? = nil
    var customMin: String = "5"
    var customSec: String = "0"

    func setPreset(_ minutes: Int) {
        stop(); reset(to: minutes * 60)
    }

    func reset(to seconds: Int = -1) {
        stop()
        if seconds >= 0 {
            totalTime = seconds; timeRemaining = seconds
        } else {
            timeRemaining = totalTime
        }
        label = "Bereit"
    }

    func toggle() {
        if isRunning { stop() }
        else { start() }
    }

    func start() {
        guard timeRemaining > 0 else { return }
        isRunning = true
        label = "Läuft"
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.stop()
                self.label = "Zeit abgelaufen! ⏰"
            }
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
        isRunning = false
        if timeRemaining > 0 { label = "Pausiert" }
    }

    var progress: Double { totalTime > 0 ? Double(timeRemaining) / Double(totalTime) : 1 }
    var displayTime: String {
        let m = timeRemaining / 60, s = timeRemaining % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct ClassTimerView: View {
    @StateObject private var model = TimerModel()
    let presets = [5, 10, 15, 20, 25, 45, 90]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Timer display
                VStack(spacing: 8) {
                    Text(model.displayTime)
                        .font(.system(size: 64, weight: .bold, design: .monospaced))
                        .foregroundColor(model.timeRemaining < 60 && model.isRunning ? .red : .appText)
                    Text(model.label)
                        .font(.system(size: 14))
                        .foregroundColor(.appDim)

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color.appCard2).frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(model.progress < 0.2 ? Color.red : Color.appAccent)
                                .frame(width: geo.size.width * model.progress, height: 8)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(20)
                .background(Color.appCard)
                .cornerRadius(12)

                // Controls
                HStack(spacing: 12) {
                    Button {
                        model.toggle()
                    } label: {
                        Label(model.isRunning ? "Pause" : "▶ Start",
                              systemImage: model.isRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(model.isRunning ? Color.orange : Color.appAccent)
                            .cornerRadius(8)
                            .foregroundColor(.white)
                    }
                    Button {
                        model.reset()
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Color.appCard2)
                            .cornerRadius(8)
                            .foregroundColor(.appText)
                    }
                }

                // Presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Voreinstellungen").font(.system(size: 12, weight: .bold)).foregroundColor(.appDim)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(presets, id: \.self) { min in
                            Button("\(min) Min") {
                                model.setPreset(min)
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.appCard2)
                            .cornerRadius(6)
                            .foregroundColor(.appText)
                        }
                    }
                }
                .padding(12)
                .background(Color.appCard)
                .cornerRadius(10)

                // Custom time
                VStack(alignment: .leading, spacing: 8) {
                    Text("Eigene Zeit").font(.system(size: 12, weight: .bold)).foregroundColor(.appDim)
                    HStack(spacing: 10) {
                        TextField("Min", text: $model.customMin).keyboardType(.numberPad)
                            .font(.system(size: 18, design: .monospaced)).foregroundColor(.appText)
                            .multilineTextAlignment(.center)
                            .frame(width: 70).padding(8).background(Color.appCard2).cornerRadius(6)
                        Text("Min").foregroundColor(.appDim)
                        TextField("Sek", text: $model.customSec).keyboardType(.numberPad)
                            .font(.system(size: 18, design: .monospaced)).foregroundColor(.appText)
                            .multilineTextAlignment(.center)
                            .frame(width: 70).padding(8).background(Color.appCard2).cornerRadius(6)
                        Text("Sek").foregroundColor(.appDim)
                        Spacer()
                        Button("Setzen") {
                            let m = Int(model.customMin) ?? 0
                            let s = Int(model.customSec) ?? 0
                            model.reset(to: m * 60 + s)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color.appAccent).cornerRadius(6).foregroundColor(.white)
                        .font(.system(size: 13, weight: .semibold))
                    }
                }
                .padding(12)
                .background(Color.appCard)
                .cornerRadius(10)
            }
            .padding(12)
        }
        .background(Color.appBg)
    }
}
