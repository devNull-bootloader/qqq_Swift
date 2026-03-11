import SwiftUI

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
