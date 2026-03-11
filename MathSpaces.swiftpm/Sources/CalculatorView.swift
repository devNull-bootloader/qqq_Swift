import SwiftUI

// MARK: - Calculator Model

class CalculatorModel: ObservableObject {
    @Published var expression: String = ""
    @Published var result: String = "0"
    @Published var history: [String] = []

    var varX: Double = 0 { didSet { livePreview() } }
    var varY: Double = 0 { didSet { livePreview() } }

    enum AngleMode: String { case deg = "DEG", rad = "RAD" }
    @Published var angleMode: AngleMode = .deg
    @Published var sciMode: Bool = false

    private let evaluator = ExpressionEvaluator()

    private func syncEvaluator() {
        evaluator.angleMode = angleMode == .deg ? .deg : .rad
        evaluator.variables = ["x": varX, "y": varY]
    }

    func input(_ ch: String) {
        let ops = ["+", "-", "×", "÷", "^"]
        let last = expression.last.map(String.init) ?? ""

        switch ch {
        case "()":
            let opens  = expression.filter { $0 == "(" }.count
            let closes = expression.filter { $0 == ")" }.count
            expression += opens > closes ? ")" : "("
        case "√":
            expression += "sqrt("
        default:
            // Prevent double operators
            if ops.contains(ch) && ops.contains(last) && last != ")" {
                expression = String(expression.dropLast())
            }
            expression += ch
        }
        livePreview()
    }

    func clear() { expression = ""; result = "0" }

    func backspace() {
        let fns = ["asin(", "acos(", "atan(", "sqrt(", "sin(", "cos(", "tan(", "log(", "exp(", "ln("]
        if let fn = fns.first(where: { expression.hasSuffix($0) }) {
            expression = String(expression.dropLast(fn.count))
        } else if !expression.isEmpty {
            expression = String(expression.dropLast())
        }
        result = expression.isEmpty ? "0" : (liveCalc() ?? "...")
    }

    func evaluate() {
        guard !expression.isEmpty else { return }
        syncEvaluator()
        do {
            let val = try evaluator.evaluate(prepareForEval(expression))
            let formatted = formatNumber(val)
            let entry = "\(expression) = \(formatted)"
            history.insert(entry, at: 0)
            if history.count > 3 { history.removeLast() }
            result = formatted
            expression = ""
        } catch {
            result = "Fehler"
            expression = ""
        }
    }

    private func livePreview() {
        if let r = liveCalc() { result = r }
    }

    private func liveCalc() -> String? {
        guard !expression.isEmpty else { return "0" }
        syncEvaluator()
        return try? formatNumber(evaluator.evaluate(prepareForEval(expression)))
    }

    private func prepareForEval(_ expr: String) -> String {
        expr.replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
    }

    func formatNumber(_ n: Double) -> String {
        guard n.isFinite else { return n.isNaN ? "Kein Ergebnis" : "Unendlich" }
        if n == n.rounded() && abs(n) < 1e15 { return String(Int64(n)) }
        return String(format: "%g", n)
    }
}

// MARK: - Equation Solver Model

struct SolutionStep: Identifiable {
    let id = UUID()
    let desc: String
    let math: String
    var isResult: Bool = false
}

func solveEquation(_ raw: String) throws -> [SolutionStep] {
    var eq = raw.trimmingCharacters(in: .whitespaces)
        .replacingOccurrences(of: "²", with: "^2")
        .replacingOccurrences(of: "×", with: "*")
        .replacingOccurrences(of: "÷", with: "/")
        .replacingOccurrences(of: " ", with: "")

    guard let eqIdx = eq.firstIndex(of: "=") else {
        throw EvalError.unexpectedToken("Kein Gleichheitszeichen (=) gefunden")
    }

    let lhsStr = String(eq[eq.startIndex..<eqIdx])
    let rhsStr = String(eq[eq.index(after: eqIdx)...])

    let lhs = parsePoly(lhsStr)
    let rhs = parsePoly(rhsStr)

    let a = round((lhs.a - rhs.a) * 1e10) / 1e10
    let b = round((lhs.b - rhs.b) * 1e10) / 1e10
    let c = round((lhs.c - rhs.c) * 1e10) / 1e10

    var steps: [SolutionStep] = []
    steps.append(SolutionStep(desc: "Originalgleichung", math: raw))
    steps.append(SolutionStep(desc: "Alle Terme links", math: "\(polyStr(a, b, c)) = 0"))

    if a != 0 {
        steps.append(SolutionStep(desc: "Quadratische Gleichung", math: "a = \(fmt(a)),  b = \(fmt(b)),  c = \(fmt(c))"))
        let D = round((b*b - 4*a*c) * 1e10) / 1e10
        steps.append(SolutionStep(desc: "Diskriminante D = b² − 4ac", math: "D = \(fmt(b))² − 4·\(fmt(a))·\(fmt(c)) = \(fmt(D))"))

        if D < 0 {
            steps.append(SolutionStep(desc: "D < 0 → Keine reellen Lösungen", math: "Keine Lösung in ℝ", isResult: true))
        } else if D == 0 {
            let x = round(-b / (2*a) * 1e10) / 1e10
            steps.append(SolutionStep(desc: "D = 0 → Eine Lösung", math: "x = −b/(2a) = \(fmt(x))", isResult: true))
        } else {
            let sqrtD = sqrt(D)
            let x1 = round((-b + sqrtD) / (2*a) * 1e10) / 1e10
            let x2 = round((-b - sqrtD) / (2*a) * 1e10) / 1e10
            steps.append(SolutionStep(desc: "√D = \(fmt(sqrtD))", math: "x₁,₂ = (−b ± √D) / (2a)"))
            steps.append(SolutionStep(desc: "x₁", math: "= \(fmt(x1))"))
            steps.append(SolutionStep(desc: "x₂", math: "= \(fmt(x2))"))
            steps.append(SolutionStep(desc: "✅ Ergebnis", math: "x₁ = \(fmt(x1)),  x₂ = \(fmt(x2))", isResult: true))
        }
    } else if b != 0 {
        steps.append(SolutionStep(desc: "Lineare Gleichung (bx + c = 0)", math: "\(fmt(b))x + (\(fmt(c))) = 0"))
        steps.append(SolutionStep(desc: "x-Term isolieren", math: "\(fmt(b))x = \(fmt(-c))"))
        let x = round(-c / b * 1e10) / 1e10
        steps.append(SolutionStep(desc: "x = −c / b", math: "x = \(fmt(-c)) ÷ \(fmt(b)) = \(fmt(x))"))
        steps.append(SolutionStep(desc: "✅ Ergebnis", math: "x = \(fmt(x))", isResult: true))
    } else {
        let s = c == 0
            ? SolutionStep(desc: "⚠️ Unendlich viele Lösungen", math: "x ∈ ℝ", isResult: true)
            : SolutionStep(desc: "⚠️ Keine Lösung (Widerspruch)", math: "\(fmt(c)) ≠ 0", isResult: true)
        steps.append(s)
    }
    return steps
}

private func parsePoly(_ expr: String) -> (a: Double, b: Double, c: Double) {
    var e = expr.replacingOccurrences(of: "-", with: "+-")
    if e.hasPrefix("+") { e = String(e.dropFirst()) }
    let terms = e.components(separatedBy: "+").filter { !$0.isEmpty }
    var a = 0.0, b = 0.0, c = 0.0
    for t in terms {
        if t.contains("x^2") || t.contains("x²") {
            var coef = t.replacingOccurrences(of: "x^2", with: "").replacingOccurrences(of: "x²", with: "")
            if coef.isEmpty || coef == "+" { coef = "1" } else if coef == "-" { coef = "-1" }
            a += Double(coef) ?? 0
        } else if t.contains("x") {
            var coef = t.replacingOccurrences(of: "x", with: "")
            if coef.isEmpty || coef == "+" { coef = "1" } else if coef == "-" { coef = "-1" }
            b += Double(coef) ?? 0
        } else {
            c += Double(t) ?? 0
        }
    }
    return (a, b, c)
}

private func polyStr(_ a: Double, _ b: Double, _ c: Double) -> String {
    var parts: [String] = []
    if a != 0 { parts.append("\(fmt(a))x²") }
    if b != 0 { parts.append("\(b > 0 && !parts.isEmpty ? "+" : "")\(fmt(b))x") }
    if c != 0 { parts.append("\(c > 0 && !parts.isEmpty ? "+" : "")\(fmt(c))") }
    return parts.isEmpty ? "0" : parts.joined()
}

private func fmt(_ n: Double) -> String {
    if n == n.rounded() && abs(n) < 1e10 { return String(Int(n)) }
    return String(format: "%g", n)
}

// MARK: - Unit Converter Data

struct UnitCategory {
    let name: String
    let units: [(String, Double)]  // (label, factor to base)
    let isTemperature: Bool

    init(_ name: String, _ units: [(String, Double)], temp: Bool = false) {
        self.name = name; self.units = units; self.isTemperature = temp
    }
}

let unitCategories: [UnitCategory] = [
    UnitCategory("Länge", [
        ("Kilometer (km)", 1000), ("Meter (m)", 1), ("Dezimeter (dm)", 0.1),
        ("Zentimeter (cm)", 0.01), ("Millimeter (mm)", 0.001),
        ("Meile (mi)", 1609.344), ("Yard (yd)", 0.9144),
        ("Fuß (ft)", 0.3048), ("Zoll (in)", 0.0254)
    ]),
    UnitCategory("Gewicht", [
        ("Tonne (t)", 1000), ("Kilogramm (kg)", 1), ("Gramm (g)", 0.001),
        ("Milligramm (mg)", 0.000001), ("Pfund (lb)", 0.453592), ("Unze (oz)", 0.0283495)
    ]),
    UnitCategory("Temperatur", [
        ("Celsius (°C)", 0), ("Fahrenheit (°F)", 0), ("Kelvin (K)", 0)
    ], temp: true),
    UnitCategory("Fläche", [
        ("km²", 1e6), ("Hektar (ha)", 1e4), ("m²", 1), ("dm²", 0.01),
        ("cm²", 0.0001), ("mm²", 1e-6), ("Meile² (mi²)", 2589988.11),
        ("Fuß² (ft²)", 0.0929)
    ]),
    UnitCategory("Geschwindigkeit", [
        ("km/h", 1/3.6), ("m/s", 1), ("mph", 0.44704), ("Knoten (kn)", 0.514444)
    ]),
    UnitCategory("Zeit", [
        ("Stunden (h)", 3600), ("Minuten (min)", 60), ("Sekunden (s)", 1),
        ("Tage (d)", 86400), ("Wochen (w)", 604800)
    ]),
    UnitCategory("Volumen", [
        ("Liter (L)", 1), ("Deziliter (dL)", 0.1), ("Zentiliter (cL)", 0.01),
        ("Milliliter (mL)", 0.001), ("m³", 1000), ("Gallone (gal)", 3.78541),
        ("Pint (pt)", 0.473176)
    ])
]

// MARK: - CalculatorView

struct CalculatorView: View {
    @StateObject private var model = CalculatorModel()
    @State private var subTab: Int = 0
    @State private var varXStr = "0"
    @State private var varYStr = "0"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MathSpaces")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.appText)
                Spacer()
                Text("🧮 Rechner")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appDim)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.appCard)

            // Sub-tab selector
            HStack(spacing: 0) {
                SubTabBtn(label: "Rechner",  icon: "🧮",  idx: 0, current: $subTab)
                SubTabBtn(label: "Gleichung",icon: "⚖️",  idx: 1, current: $subTab)
                SubTabBtn(label: "Brüche",   icon: "½",   idx: 2, current: $subTab)
                SubTabBtn(label: "Einheiten",icon: "📏",  idx: 3, current: $subTab)
            }
            .background(Color.appCard2)

            Group {
                switch subTab {
                case 0: BasicCalculatorPanel(model: model, varXStr: $varXStr, varYStr: $varYStr)
                case 1: EquationSolverPanel()
                case 2: FractionPanel()
                case 3: UnitConverterPanel()
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBg)
    }
}

// MARK: - Sub-tab Button

struct SubTabBtn: View {
    let label: String; let icon: String; let idx: Int
    @Binding var current: Int
    var body: some View {
        Button {
            current = idx
        } label: {
            VStack(spacing: 2) {
                Text(icon).font(.system(size: 14))
                Text(label).font(.system(size: 10, weight: .semibold))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(current == idx ? Color.appAccent.opacity(0.25) : Color.clear)
            .foregroundColor(current == idx ? .appAccent : .appDim)
            .overlay(
                Rectangle().frame(height: 2).foregroundColor(current == idx ? .appAccent : .clear),
                alignment: .bottom
            )
        }
    }
}

// MARK: - Basic Calculator Panel

struct BasicCalculatorPanel: View {
    @ObservedObject var model: CalculatorModel
    @Binding var varXStr: String
    @Binding var varYStr: String

    var body: some View {
        VStack(spacing: 0) {
            // Variable row
            HStack(spacing: 8) {
                Text("x =").font(.system(size: 12)).foregroundColor(.appDim)
                TextField("0", text: $varXStr)
                    .keyboardType(.decimalPad)
                    .frame(width: 64)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color.appCard2)
                    .cornerRadius(4)
                    .foregroundColor(.appText)
                    .font(.system(size: 13, design: .monospaced))
                    .onChange(of: varXStr) { v in model.varX = Double(v) ?? 0 }

                Text("y =").font(.system(size: 12)).foregroundColor(.appDim)
                TextField("0", text: $varYStr)
                    .keyboardType(.decimalPad)
                    .frame(width: 64)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Color.appCard2)
                    .cornerRadius(4)
                    .foregroundColor(.appText)
                    .font(.system(size: 13, design: .monospaced))
                    .onChange(of: varYStr) { v in model.varY = Double(v) ?? 0 }

                Spacer()

                Button("x") { model.input("x") }
                    .calcKeyStyle(bg: .secBtn)
                Button("y") { model.input("y") }
                    .calcKeyStyle(bg: .secBtn)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.appCard)

            // Display
            VStack(alignment: .trailing, spacing: 4) {
                // History
                VStack(alignment: .trailing, spacing: 2) {
                    ForEach(model.history, id: \.self) { entry in
                        Text(entry)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.appDim)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)

                // Expression
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(model.expression.isEmpty ? " " : model.expression)
                        .font(.system(size: 20, design: .monospaced))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // Result
                Text(model.result)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .foregroundColor(model.expression.isEmpty ? .appText : .appDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 110)
            .background(Color.appCard)

            // SCI/DEG toggle row
            HStack(spacing: 8) {
                Toggle("SCI", isOn: $model.sciMode)
                    .labelsHidden()
                    .tint(.appAccent)
                Text("SCI").font(.system(size: 12, weight: .semibold)).foregroundColor(model.sciMode ? .appAccent : .appDim)

                Spacer()

                if model.sciMode {
                    Button(model.angleMode.rawValue) {
                        model.angleMode = model.angleMode == .deg ? .rad : .deg
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(model.angleMode == .deg ? .appAccent : Color.orange)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.appCard2)
                    .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.appBg)

            Spacer(minLength: 0)

            // Science rows
            if model.sciMode {
                CalcSciRow(model: model)
                    .background(Color.appCard2)
            }

            // Main keypad
            CalcKeypad(model: model)
                .padding(6)
                .background(Color.appBg)
        }
    }
}

// MARK: - Scientific row

struct CalcSciRow: View {
    @ObservedObject var model: CalculatorModel
    let sciKeys: [(String, String)] = [
        ("sin", "sin("), ("cos", "cos("), ("tan", "tan("), ("sin⁻¹", "asin("),
        ("log", "log("), ("ln", "ln("), ("π", "π"), ("eˣ", "exp(")
    ]
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 4), spacing: 4) {
            ForEach(sciKeys, id: \.0) { (label, val) in
                Button(label) { model.input(val) }
                    .calcKeyStyle(bg: .sciBtn, font: 13)
            }
        }
        .padding(6)
    }
}

// MARK: - Main Keypad

struct CalcKeypad: View {
    @ObservedObject var model: CalculatorModel
    private let sp: CGFloat = 4
    private let btnH: CGFloat = 44

    private var numBg: Color { Color(red: 38/255, green: 38/255, blue: 38/255) }

    var body: some View {
        GeometryReader { geo in
            let colW = (geo.size.width - sp * 3) / 4

            VStack(spacing: sp) {
                row4(colW: colW, [
                    ("AC",  Color.clBtn,  { model.clear() }),
                    ("⌫",   Color.secBtn, { model.backspace() }),
                    ("( )", Color.secBtn, { model.input("()") }),
                    ("÷",   Color.opBtn,  { model.input("÷") }),
                ])
                row4(colW: colW, [
                    ("√",   Color.secBtn, { model.input("√") }),
                    ("%",   Color.secBtn, { model.input("%") }),
                    ("xʸ", Color.secBtn, { model.input("^") }),
                    ("×",   Color.opBtn,  { model.input("×") }),
                ])
                row4(colW: colW, [
                    ("7", numBg, { model.input("7") }),
                    ("8", numBg, { model.input("8") }),
                    ("9", numBg, { model.input("9") }),
                    ("−", Color.opBtn, { model.input("-") }),
                ])
                row4(colW: colW, [
                    ("4", numBg, { model.input("4") }),
                    ("5", numBg, { model.input("5") }),
                    ("6", numBg, { model.input("6") }),
                    ("+", Color.opBtn, { model.input("+") }),
                ])
                // Bottom 2 rows: [1][2][3] / [0(wide)][.] with = spanning both on right
                ZStack(alignment: .topLeading) {
                    VStack(spacing: sp) {
                        HStack(spacing: sp) {
                            btn("1", w: colW, h: btnH, bg: numBg)  { model.input("1") }
                            btn("2", w: colW, h: btnH, bg: numBg)  { model.input("2") }
                            btn("3", w: colW, h: btnH, bg: numBg)  { model.input("3") }
                        }
                        HStack(spacing: sp) {
                            btn("0", w: colW * 2 + sp, h: btnH, bg: numBg) { model.input("0") }
                            btn(".", w: colW, h: btnH, bg: numBg)           { model.input(".") }
                        }
                    }
                    btn("=", w: colW, h: btnH * 2 + sp, bg: Color.eqBtn, fs: 28)
                        { model.evaluate() }
                        .offset(x: colW * 3 + sp * 3)
                }
                .frame(height: btnH * 2 + sp)
            }
        }
        .frame(height: btnH * 6 + sp * 5)
    }

    @ViewBuilder
    private func row4(colW: CGFloat, _ items: [(String, Color, () -> Void)]) -> some View {
        HStack(spacing: sp) {
            ForEach(Array(items.enumerated()), id: \.0) { _, item in
                btn(item.0, w: colW, h: btnH, bg: item.1, action: item.2)
            }
        }
    }

    @ViewBuilder
    private func btn(_ label: String, w: CGFloat, h: CGFloat, bg: Color, fs: CGFloat = 18, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: fs, weight: label == "=" ? .bold : .semibold))
                .frame(width: w, height: h)
                .background(bg)
                .cornerRadius(6)
                .foregroundColor(.white)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Equation Solver Panel

struct EquationSolverPanel: View {
    @State private var input: String = ""
    @State private var steps: [SolutionStep] = []
    @State private var error: String? = nil
    @State private var solved = false
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Gleichung eingeben", systemImage: "function")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.appDim)

                    Text("Lineare oder quadratische Gleichung\n(z.B.  2x+3=7  oder  x^2+5x+6=0)")
                        .font(.system(size: 12))
                        .foregroundColor(.appDim)

                    TextField("z.B.  2x + 3 = 7", text: $input)
                        .font(.system(size: 17, design: .monospaced))
                        .padding(10)
                        .background(Color.appCard2)
                        .cornerRadius(6)
                        .foregroundColor(.appText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit { solve() }
                }
                .padding()
                .background(Color.appCard)
                .cornerRadius(8)

                Button(action: solve) {
                    Label("Gleichung lösen", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.appAccent)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }

                if let err = error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                        Text(err)
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                if solved && error == nil {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lösungsweg")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.appDim)
                            .padding(.horizontal, 12)
                            .padding(.top, 8)

                        ForEach(steps.filter { !$0.isResult }) { step in
                            StepRow(step: step)
                        }
                        ForEach(steps.filter { $0.isResult }) { step in
                            ResultRow(step: step)
                        }
                    }
                    .background(Color.appCard)
                    .cornerRadius(8)
                }
            }
            .padding(12)
        }
        .background(Color.appBg)
    }

    private func solve() {
        focused = false
        error = nil
        solved = false
        guard !input.isEmpty else { return }
        do {
            steps = try solveEquation(input)
            solved = true
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct StepRow: View {
    let step: SolutionStep
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("→").font(.system(size: 13)).foregroundColor(.appAccent)
            VStack(alignment: .leading, spacing: 2) {
                if !step.desc.isEmpty {
                    Text(step.desc).font(.system(size: 12)).foregroundColor(.appDim)
                }
                Text(step.math).font(.system(size: 15, design: .monospaced)).foregroundColor(.appText)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct ResultRow: View {
    let step: SolutionStep
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(step.desc).font(.system(size: 12, weight: .semibold)).foregroundColor(.appAccent)
            Text(step.math)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.appText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.appAccent.opacity(0.15))
        .cornerRadius(8)
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Fraction Panel

struct FractionPanel: View {
    @State private var n1 = "1"; @State private var d1 = "2"
    @State private var n2 = "1"; @State private var d2 = "3"
    @State private var op: String = "+"
    @State private var steps: [SolutionStep] = []
    @State private var error: String? = nil
    @State private var solved = false

    let ops = [("+", "+"), ("−", "-"), ("×", "*"), ("÷", "/")]

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Fraction input
                VStack(spacing: 12) {
                    Label("Bruchrechnung", systemImage: "divide")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.appDim)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 16) {
                        FractionInput(numerator: $n1, denominator: $d1)

                        // Operator selector
                        VStack(spacing: 4) {
                            ForEach(ops, id: \.0) { (label, val) in
                                Button(label) { op = val }
                                    .frame(width: 36, height: 28)
                                    .background(op == val ? Color.appAccent : Color.appCard2)
                                    .cornerRadius(4)
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }

                        FractionInput(numerator: $n2, denominator: $d2)
                    }
                }
                .padding()
                .background(Color.appCard)
                .cornerRadius(8)

                Button(action: calculate) {
                    Label("Berechnen", systemImage: "equal.square")
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.appAccent)
                        .cornerRadius(8)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }

                if let err = error {
                    Text(err).foregroundColor(.red).padding().background(Color.red.opacity(0.1)).cornerRadius(8)
                }

                if solved && error == nil {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Lösungsweg").font(.system(size: 13, weight: .bold)).foregroundColor(.appDim).padding(12)
                        ForEach(steps.filter { !$0.isResult }) { s in StepRow(step: s) }
                        ForEach(steps.filter { $0.isResult })  { s in ResultRow(step: s) }
                    }
                    .background(Color.appCard)
                    .cornerRadius(8)
                }
            }
            .padding(12)
        }
        .background(Color.appBg)
    }

    private func calculate() {
        error = nil; solved = false
        guard let n1v = Int(n1), let d1v = Int(d1), let n2v = Int(n2), let d2v = Int(d2) else {
            error = "Bitte gültige ganze Zahlen eingeben"; return
        }
        guard d1v != 0 && d2v != 0 else { error = "Nenner darf nicht 0 sein"; return }
        steps = solveFraction(n1v, d1v, n2v, d2v, op: op)
        solved = true
    }
}

struct FractionInput: View {
    @Binding var numerator: String
    @Binding var denominator: String
    var body: some View {
        VStack(spacing: 0) {
            TextField("Zähler", text: $numerator)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .font(.system(size: 20, design: .monospaced))
                .foregroundColor(.appText)
                .frame(width: 70, height: 38)
            Rectangle().fill(Color.appText).frame(height: 2).frame(width: 70)
            TextField("Nenner", text: $denominator)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .font(.system(size: 20, design: .monospaced))
                .foregroundColor(.appText)
                .frame(width: 70, height: 38)
        }
    }
}

private func solveFraction(_ n1: Int, _ d1: Int, _ n2: Int, _ d2: Int, op: String) -> [SolutionStep] {
    let ops = ["+": "+", "-": "−", "*": "×", "/": "÷"]
    let opSym = ops[op] ?? op
    var steps: [SolutionStep] = []
    steps.append(SolutionStep(desc: "Aufgabe", math: "\(n1)/\(d1)  \(opSym)  \(n2)/\(d2)"))

    var rn: Int; var rd: Int

    if op == "+" || op == "-" {
        let lcm = lcmOf(abs(d1), abs(d2))
        let f1 = lcm / d1, f2 = lcm / d2
        let en1 = n1 * f1, en2 = n2 * f2
        steps.append(SolutionStep(desc: "Gemeinsamer Nenner (kgV)", math: "kgV(\(abs(d1)), \(abs(d2))) = \(lcm)"))
        steps.append(SolutionStep(desc: "Brüche erweitern", math: "\(en1)/\(lcm)  \(opSym)  \(en2)/\(lcm)"))
        rn = op == "+" ? en1 + en2 : en1 - en2
        rd = lcm
        steps.append(SolutionStep(desc: "Zähler verrechnen", math: "\(rn)/\(rd)"))
    } else if op == "*" {
        rn = n1 * n2; rd = d1 * d2
        steps.append(SolutionStep(desc: "Zähler × Zähler, Nenner × Nenner", math: "(\(n1)×\(n2)) / (\(d1)×\(d2)) = \(rn)/\(rd)"))
    } else {
        rn = n1 * d2; rd = d1 * n2
        steps.append(SolutionStep(desc: "Mit Kehrwert multiplizieren", math: "\(n1)/\(d1) × \(d2)/\(n2) = (\(n1)×\(d2)) / (\(d1)×\(n2)) = \(rn)/\(rd)"))
    }

    let g = gcdOf(abs(rn), abs(rd))
    let sn = rn / g, sd = rd / g
    if g != 1 { steps.append(SolutionStep(desc: "Kürzen mit ggT(\(abs(rn)),\(abs(rd))) = \(g)", math: "\(sn)/\(sd)")) }
    let dec = Double(sn) / Double(sd)
    steps.append(SolutionStep(desc: "✅ Ergebnis", math: "\(sn)/\(sd)  =  \(String(format: "%g", dec))", isResult: true))
    return steps
}

private func gcdOf(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcdOf(b, a % b) }
private func lcmOf(_ a: Int, _ b: Int) -> Int { a / gcdOf(a, b) * b }

// MARK: - Unit Converter Panel

struct UnitConverterPanel: View {
    @State private var catIdx: Int = 0
    @State private var fromIdx: Int = 0
    @State private var toIdx: Int = 1
    @State private var valueStr: String = ""
    @State private var result: String = "—"

    var cat: UnitCategory { unitCategories[catIdx] }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Category buttons
                VStack(alignment: .leading, spacing: 6) {
                    Text("Kategorie").font(.system(size: 12, weight: .bold)).foregroundColor(.appDim)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(unitCategories.enumerated()), id: \.0) { i, c in
                                Button(c.name) {
                                    catIdx = i; fromIdx = 0; toIdx = min(1, c.units.count - 1); result = "—"
                                }
                                .padding(.horizontal, 10).padding(.vertical, 6)
                                .background(catIdx == i ? Color.appAccent : Color.appCard2)
                                .cornerRadius(6)
                                .foregroundColor(.white)
                                .font(.system(size: 13, weight: .semibold))
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
                .background(Color.appCard)
                .cornerRadius(8)

                // Conversion area
                VStack(spacing: 10) {
                    Text("Umrechnen").font(.system(size: 12, weight: .bold)).foregroundColor(.appDim)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("Von:").font(.system(size: 12)).foregroundColor(.appDim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("Von", selection: $fromIdx) {
                        ForEach(0..<cat.units.count, id: \.self) { i in
                            Text(cat.units[i].0).tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8).background(Color.appCard2).cornerRadius(6)
                    .onChange(of: fromIdx) { _ in convert() }

                    TextField("Wert eingeben", text: $valueStr)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 20, design: .monospaced))
                        .padding(10).background(Color.appCard2).cornerRadius(6)
                        .foregroundColor(.appText)
                        .onChange(of: valueStr) { _ in convert() }

                    Image(systemName: "arrow.down").foregroundColor(.appDim)

                    Text("Nach:").font(.system(size: 12)).foregroundColor(.appDim)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Picker("Nach", selection: $toIdx) {
                        ForEach(0..<cat.units.count, id: \.self) { i in
                            Text(cat.units[i].0).tag(i)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8).background(Color.appCard2).cornerRadius(6)
                    .onChange(of: toIdx) { _ in convert() }

                    // Result box
                    VStack(spacing: 4) {
                        Text("Ergebnis").font(.system(size: 11, weight: .bold)).foregroundColor(.appDim)
                        Text(result)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.appText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.appAccent.opacity(0.15))
                    .cornerRadius(8)
                }
                .padding()
                .background(Color.appCard)
                .cornerRadius(8)
            }
            .padding(12)
        }
        .background(Color.appBg)
    }

    private func convert() {
        guard let val = Double(valueStr) else { result = "—"; return }
        let c = cat
        if c.isTemperature {
            result = convertTemp(val, from: c.units[fromIdx].0, to: c.units[toIdx].0)
        } else {
            let base  = val * c.units[fromIdx].1
            let out   = base / c.units[toIdx].1
            result    = String(format: "%g", out)
        }
    }

    private func convertTemp(_ val: Double, from: String, to: String) -> String {
        // Convert to Celsius first
        var celsius: Double
        if from.contains("°F")     { celsius = (val - 32) * 5 / 9 }
        else if from.contains("K") { celsius = val - 273.15 }
        else                        { celsius = val }

        var out: Double
        if to.contains("°F")     { out = celsius * 9 / 5 + 32 }
        else if to.contains("K") { out = celsius + 273.15 }
        else                      { out = celsius }

        return String(format: "%g", out)
    }
}

// MARK: - Helper view modifier

extension View {
    func calcKeyStyle(bg: Color, font: CGFloat = 16) -> some View {
        self
            .font(.system(size: font, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(bg)
            .cornerRadius(4)
    }
}
