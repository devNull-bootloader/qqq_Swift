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

// MARK: - CalculatorView

struct CalculatorView: View {
    @ObservedObject var model: CalculatorModel
    @Binding var subTab: Int
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
