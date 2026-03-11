import SwiftUI

// MARK: - Equation Solver Model

struct SolutionStep: Identifiable {
    let id = UUID()
    let desc: String
    let math: String
    var isResult: Bool = false
}

func solveEquation(_ raw: String) throws -> [SolutionStep] {
    let eq = raw.trimmingCharacters(in: .whitespaces)
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
                        .onAppear { focused = true }
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
