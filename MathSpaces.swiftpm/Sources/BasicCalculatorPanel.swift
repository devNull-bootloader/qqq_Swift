import SwiftUI

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
                HStack(alignment: .top, spacing: sp) {
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
