import SwiftUI

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
                        FractionInput(numerator: $n1, denominator: $d1, autoFocus: true)

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
    var autoFocus: Bool = false
    @FocusState private var numFocused: Bool
    var body: some View {
        VStack(spacing: 0) {
            TextField("Zähler", text: $numerator)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .font(.system(size: 20, design: .monospaced))
                .foregroundColor(.appText)
                .frame(width: 70, height: 38)
                .focused($numFocused)
            Rectangle().fill(Color.appText).frame(height: 2).frame(width: 70)
            TextField("Nenner", text: $denominator)
                .keyboardType(.numbersAndPunctuation)
                .multilineTextAlignment(.center)
                .font(.system(size: 20, design: .monospaced))
                .foregroundColor(.appText)
                .frame(width: 70, height: 38)
        }
        .onAppear { if autoFocus { numFocused = true } }
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
