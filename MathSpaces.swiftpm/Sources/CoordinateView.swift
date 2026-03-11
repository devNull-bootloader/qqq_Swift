import SwiftUI

// MARK: - Coordinate Model

struct CoordFunction: Identifiable {
    let id = UUID()
    var expr: String
    var color: Color
    var visible: Bool = true
}

struct CoordPoint: Identifiable {
    let id = UUID()
    var x: Double
    var y: Double
    var name: String
}

class CoordinateModel: ObservableObject {
    @Published var functions: [CoordFunction] = []
    @Published var points: [CoordPoint] = []
    @Published var showGrid: Bool = true
    @Published var showAxes: Bool = true
    @Published var showLabels: Bool = true

    // Viewport in math coordinates (origin + scale)
    @Published var originX: Double = 0    // screen-pixels from left to math 0
    @Published var originY: Double = 0    // screen-pixels from top  to math 0
    @Published var scale: Double = 50     // pixels per unit

    let evaluator = ExpressionEvaluator()
    var canvasSize: CGSize = .zero

    let palette: [Color] = [.red, .blue, Color(red: 0, green: 0.6, blue: 0),
                             .orange, .purple, Color(red: 0, green: 0.4, blue: 0.8),
                             Color(red: 0.8, green: 0.2, blue: 0), .cyan]
    var nextColorIdx = 0

    func nextColor() -> Color {
        let c = palette[nextColorIdx % palette.count]
        nextColorIdx += 1
        return c
    }

    func resetView() {
        guard canvasSize != .zero else { return }
        originX = canvasSize.width  / 2
        originY = canvasSize.height / 2
        scale   = 50
    }

    // Math → canvas
    func toCanvas(mx: Double, my: Double) -> CGPoint {
        CGPoint(x: originX + mx * scale, y: originY - my * scale)
    }

    // Canvas → math
    func toMath(cx: CGFloat, cy: CGFloat) -> (Double, Double) {
        ((Double(cx) - originX) / scale, (originY - Double(cy)) / scale)
    }
}

// MARK: - Coordinate View

struct CoordinateView: View {
    @StateObject private var model = CoordinateModel()
    @State private var showPanel = true
    @State private var panelTab = 0            // 0=Funktionen 1=Punkte
    @State private var newFnExpr = ""
    @State private var newPtX = ""; @State private var newPtY = ""; @State private var newPtName = "A"
    @State private var fnError = ""

    // Gesture state
    @State private var dragStartOriginX: Double = 0
    @State private var dragStartOriginY: Double = 0
    @State private var isDragging = false
    @State private var zoomStartScale: Double = 50
    @State private var isZooming = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                // Canvas
                Canvas { ctx, size in
                    drawCoordCanvas(ctx: ctx, size: size)
                }
                .ignoresSafeArea(edges: .bottom)
                .background(Color.white)
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            if !isDragging {
                                isDragging = true
                                dragStartOriginX = model.originX
                                dragStartOriginY = model.originY
                            }
                            model.originX = dragStartOriginX + Double(value.translation.width)
                            model.originY = dragStartOriginY + Double(value.translation.height)
                        }
                        .onEnded { _ in isDragging = false }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            if !isZooming {
                                isZooming = true
                                zoomStartScale = model.scale
                            }
                            model.scale = min(max(zoomStartScale * Double(value), 5), 500)
                        }
                        .onEnded { _ in isZooming = false }
                )
                .onAppear {
                    model.canvasSize = geo.size
                    model.resetView()
                }
                .onChange(of: geo.size) { size in
                    model.canvasSize = size
                }

                // Side panel
                if showPanel {
                    panelView
                        .frame(width: min(geo.size.width * 0.42, 300))
                        .frame(maxHeight: .infinity)
                        .background(Color.appBg.opacity(0.96))
                        .shadow(color: .black.opacity(0.4), radius: 8)
                        .transition(.move(edge: .trailing))
                }

                // Toggle panel button
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showPanel.toggle() }
                } label: {
                    Image(systemName: showPanel ? "sidebar.right" : "sidebar.right")
                        .font(.system(size: 18))
                        .padding(10)
                        .background(Color.appBg.opacity(0.9))
                        .cornerRadius(8)
                        .foregroundColor(.appAccent)
                }
                .padding(8)
                .offset(x: showPanel ? -(min(geo.size.width * 0.42, 300) + 4) : 0)

                // Reset view button
                Button {
                    withAnimation { model.resetView() }
                } label: {
                    Image(systemName: "arrow.counterclockwise.circle")
                        .font(.system(size: 22))
                        .padding(8)
                        .background(Color.appBg.opacity(0.9))
                        .cornerRadius(8)
                        .foregroundColor(.appDim)
                }
                .padding(.bottom, 48)
                .padding(.trailing, showPanel ? (min(geo.size.width * 0.42, 300) + 12) : 12)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: Panel

    var panelView: some View {
        VStack(spacing: 0) {
            // Panel tabs
            HStack(spacing: 0) {
                panelTabBtn(label: "Funktionen", idx: 0)
                panelTabBtn(label: "Punkte",     idx: 1)
                panelTabBtn(label: "Ansicht",    idx: 2)
            }
            .background(Color.appCard)

            ScrollView {
                Group {
                    switch panelTab {
                    case 0: fnPanel
                    case 1: ptPanel
                    case 2: viewPanel
                    default: EmptyView()
                    }
                }
                .padding(10)
            }
        }
    }

    private func panelTabBtn(label: String, idx: Int) -> some View {
        Button(label) { panelTab = idx }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(panelTab == idx ? .appAccent : .appDim)
            .background(panelTab == idx ? Color.appAccent.opacity(0.15) : Color.clear)
            .overlay(Rectangle().frame(height: 2).foregroundColor(panelTab == idx ? .appAccent : .clear), alignment: .bottom)
    }

    // MARK: Function panel

    var fnPanel: some View {
        VStack(spacing: 8) {
            Text("Funktionen").font(.system(size: 12, weight: .bold)).foregroundColor(.appDim)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Add function row
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("f(x) =").font(.system(size: 13, design: .monospaced)).foregroundColor(.appDim)
                    TextField("z.B.  x^2  oder  sin(x)", text: $newFnExpr)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.appText)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .onSubmit { addFunction() }
                }
                .padding(8)
                .background(Color.appCard2)
                .cornerRadius(6)

                if !fnError.isEmpty {
                    Text(fnError).font(.system(size: 11)).foregroundColor(.red)
                }

                Button(action: addFunction) {
                    Label("Hinzufügen", systemImage: "plus.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.appAccent)
                        .cornerRadius(6)
                        .foregroundColor(.white)
                }
            }

            Divider().background(Color.appBorder)

            // Function list
            ForEach(model.functions) { fn in
                FnRow(fn: fn, model: model)
            }
        }
    }

    private func addFunction() {
        let expr = newFnExpr.trimmingCharacters(in: .whitespaces)
        guard !expr.isEmpty else { return }
        // Validate
        do {
            _ = try model.evaluator.evaluate(expr, x: 0)
            fnError = ""
        } catch {
            fnError = "⚠️ Ausdruck ungültig"
            return
        }
        model.functions.append(CoordFunction(expr: expr, color: model.nextColor()))
        newFnExpr = ""
    }

    // MARK: Points panel

    var ptPanel: some View {
        VStack(spacing: 8) {
            Text("Punkte").font(.system(size: 12, weight: .bold)).foregroundColor(.appDim)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Add point
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Text("Name").font(.system(size: 11)).foregroundColor(.appDim)
                    TextField("A", text: $newPtName)
                        .font(.system(size: 13)).foregroundColor(.appText)
                        .frame(width: 36)
                        .padding(6).background(Color.appCard2).cornerRadius(4)
                }
                HStack(spacing: 4) {
                    Text("x =").font(.system(size: 12, design: .monospaced)).foregroundColor(.appDim)
                    TextField("0", text: $newPtX).keyboardType(.decimalPad)
                        .font(.system(size: 13, design: .monospaced)).foregroundColor(.appText)
                        .padding(6).background(Color.appCard2).cornerRadius(4)
                    Text("y =").font(.system(size: 12, design: .monospaced)).foregroundColor(.appDim)
                    TextField("0", text: $newPtY).keyboardType(.decimalPad)
                        .font(.system(size: 13, design: .monospaced)).foregroundColor(.appText)
                        .padding(6).background(Color.appCard2).cornerRadius(4)
                }
                Button(action: addPoint) {
                    Label("Punkt hinzufügen", systemImage: "plus.circle")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.appAccent)
                        .cornerRadius(6)
                        .foregroundColor(.white)
                }
            }

            Divider().background(Color.appBorder)

            ForEach(model.points) { pt in
                HStack {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("\(pt.name)(\(String(format: "%g", pt.x)), \(String(format: "%g", pt.y)))")
                        .font(.system(size: 12, design: .monospaced)).foregroundColor(.appText)
                    Spacer()
                    Button { model.points.removeAll { $0.id == pt.id } } label: {
                        Image(systemName: "trash").foregroundColor(.red).font(.system(size: 12))
                    }
                }
                .padding(.vertical, 3)
            }
        }
    }

    private func addPoint() {
        let x = Double(newPtX) ?? 0
        let y = Double(newPtY) ?? 0
        let name = newPtName.isEmpty ? "P" : newPtName
        model.points.append(CoordPoint(x: x, y: y, name: name))
        newPtName = nextPointName()
        newPtX = ""; newPtY = ""
    }

    private func nextPointName() -> String {
        let used = Set(model.points.map(\.name))
        for c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ" {
            let n = String(c)
            if !used.contains(n) { return n }
        }
        return "P\(model.points.count + 1)"
    }

    // MARK: View panel

    var viewPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Gitternetz", isOn: $model.showGrid).tint(.appAccent)
                .font(.system(size: 13)).foregroundColor(.appText)
            Toggle("Achsen",     isOn: $model.showAxes).tint(.appAccent)
                .font(.system(size: 13)).foregroundColor(.appText)
            Toggle("Beschriftungen", isOn: $model.showLabels).tint(.appAccent)
                .font(.system(size: 13)).foregroundColor(.appText)

            Divider().background(Color.appBorder)

            Button {
                model.functions.removeAll()
            } label: {
                Label("Alle Funktionen löschen", systemImage: "trash")
                    .font(.system(size: 12)).foregroundColor(.red)
            }
            Button {
                model.points.removeAll()
            } label: {
                Label("Alle Punkte löschen", systemImage: "trash")
                    .font(.system(size: 12)).foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Canvas Drawing

    private func drawCoordCanvas(ctx: GraphicsContext, size: CGSize) {
        let W = Double(size.width), H = Double(size.height)
        let ox = model.originX, oy = model.originY
        let s = model.scale

        // Grid step – aim for ~5 grid lines across the visible range
        let targetStep = (W / s) / 10
        let rawStep = pow(10, floor(log10(targetStep)))
        let gs: Double = targetStep / rawStep >= 5 ? rawStep * 5 :
                         targetStep / rawStep >= 2 ? rawStep * 2 : rawStep

        // Background
        ctx.fill(Path(CGRect(x: 0, y: 0, width: W, height: H)), with: .color(.white))

        // Grid
        if model.showGrid {
            var gridPath = Path()
            let xStart = floor((0 - ox) / s / gs) * gs
            let xEnd   = ceil((W - ox) / s / gs) * gs
            var mx = xStart
            while mx <= xEnd { let cx = ox + mx * s; gridPath.move(to: CGPoint(x: cx, y: 0)); gridPath.addLine(to: CGPoint(x: cx, y: H)); mx += gs }
            let yStart = floor((oy - H) / s / gs) * gs
            let yEnd   = ceil(oy / s / gs) * gs
            var my = yStart
            while my <= yEnd { let cy = oy - my * s; gridPath.move(to: CGPoint(x: 0, y: cy)); gridPath.addLine(to: CGPoint(x: W, y: cy)); my += gs }
            ctx.stroke(gridPath, with: .color(Color.black.opacity(0.1)), lineWidth: 0.75)
        }

        // Axes
        if model.showAxes {
            var axisPath = Path()
            axisPath.move(to: CGPoint(x: 0, y: oy)); axisPath.addLine(to: CGPoint(x: W, y: oy))
            axisPath.move(to: CGPoint(x: ox, y: 0)); axisPath.addLine(to: CGPoint(x: ox, y: H))
            ctx.stroke(axisPath, with: .color(Color.black.opacity(0.5)), lineWidth: 1.5)

            // Arrows
            let arrowSize = 8.0, arrowHW = 3.5
            var arrowPaths = [Path]()
            var arrowRight = Path()
            arrowRight.move(to: CGPoint(x: W - 4, y: oy))
            arrowRight.addLine(to: CGPoint(x: W - 4 - arrowSize, y: oy - arrowHW))
            arrowRight.addLine(to: CGPoint(x: W - 4 - arrowSize, y: oy + arrowHW))
            arrowRight.closeSubpath()
            arrowPaths.append(arrowRight)

            var arrowUp = Path()
            arrowUp.move(to: CGPoint(x: ox, y: 4))
            arrowUp.addLine(to: CGPoint(x: ox - arrowHW, y: 4 + arrowSize))
            arrowUp.addLine(to: CGPoint(x: ox + arrowHW, y: 4 + arrowSize))
            arrowUp.closeSubpath()
            arrowPaths.append(arrowUp)

            for p in arrowPaths { ctx.fill(p, with: .color(Color.black.opacity(0.5))) }

            if model.showLabels {
                ctx.draw(Text("x").font(.system(size: 12)).foregroundColor(Color.black.opacity(0.6)),
                         at: CGPoint(x: W - 16, y: oy - 14))
                ctx.draw(Text("y").font(.system(size: 12)).foregroundColor(Color.black.opacity(0.6)),
                         at: CGPoint(x: ox + 12, y: 12))
            }
        }

        // Axis tick labels
        if model.showLabels && model.showAxes {
            let xStart = floor((0 - ox) / s / gs) * gs
            let xEnd   = ceil((W - ox) / s / gs) * gs
            var mx = xStart
            while mx <= xEnd {
                if abs(mx) > gs * 0.01 {
                    let cx = ox + mx * s
                    let label = formatTickLabel(mx)
                    let cy = min(max(oy + 14, 14.0), H - 4)
                    ctx.draw(Text(label).font(.system(size: 9)).foregroundColor(Color.black.opacity(0.6)),
                             at: CGPoint(x: cx, y: cy))
                }
                mx += gs
            }
            let yStart = floor((oy - H) / s / gs) * gs
            let yEnd   = ceil(oy / s / gs) * gs
            var my = yStart
            while my <= yEnd {
                if abs(my) > gs * 0.01 {
                    let cy = oy - my * s
                    let label = formatTickLabel(my)
                    let cx = max(ox - 6, 16.0)
                    ctx.draw(Text(label).font(.system(size: 9)).foregroundColor(Color.black.opacity(0.6)),
                             at: CGPoint(x: cx, y: cy))
                }
                my += gs
            }
        }

        // Functions
        for fn in model.functions where fn.visible {
            plotFunction(ctx: ctx, fn: fn, size: size)
        }

        // Points
        for pt in model.points {
            let cp = model.toCanvas(mx: pt.x, my: pt.y)
            var circle = Path()
            circle.addEllipse(in: CGRect(x: cp.x - 5, y: cp.y - 5, width: 10, height: 10))
            ctx.fill(circle, with: .color(.red))
            var ring = Path()
            ring.addEllipse(in: CGRect(x: cp.x - 5, y: cp.y - 5, width: 10, height: 10))
            ctx.stroke(ring, with: .color(.white), lineWidth: 1.5)

            if model.showLabels {
                let lbl = "\(pt.name)(\(String(format: "%g", pt.x)), \(String(format: "%g", pt.y)))"
                ctx.draw(Text(lbl).font(.system(size: 11, weight: .semibold)).foregroundColor(.red),
                         at: CGPoint(x: cp.x + 10, y: cp.y - 8))
            }
        }
    }

    private func plotFunction(ctx: GraphicsContext, fn: CoordFunction, size: CGSize) {
        let W = Double(size.width)
        let steps = Int(W * 2)
        let xLeft  = (0      - model.originX) / model.scale
        let xRight = (W      - model.originX) / model.scale
        let dx = (xRight - xLeft) / Double(steps)
        let verticalRange = Double(size.height) / model.scale * 2  // discontinuity guard

        var path = Path()
        var started = false
        var prevY: Double? = nil

        for i in 0...steps {
            let mx = xLeft + Double(i) * dx
            guard let my = try? model.evaluator.evaluate(fn.expr, x: mx), my.isFinite else {
                started = false; prevY = nil; continue
            }
            if let py = prevY, abs(my - py) > verticalRange {
                started = false
            }
            let cp = model.toCanvas(mx: mx, my: my)
            if !started { path.move(to: cp); started = true }
            else        { path.addLine(to: cp) }
            prevY = my
        }

        ctx.stroke(path, with: .color(fn.color), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
    }

    private func formatTickLabel(_ n: Double) -> String {
        if n == 0 { return "0" }
        let abs = Swift.abs(n)
        if abs >= 1000 || (abs < 0.01 && abs > 0) { return String(format: "%g", n) }
        if n == n.rounded() { return String(Int(n)) }
        return String(format: "%g", n)
    }
}

// MARK: - Function List Row

struct FnRow: View {
    let fn: CoordFunction
    @ObservedObject var model: CoordinateModel

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(fn.color).frame(width: 10, height: 10)
            Text("f(x) = \(fn.expr)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.appText)
                .lineLimit(1)
            Spacer()
            Button { model.functions.removeAll { $0.id == fn.id } } label: {
                Image(systemName: "trash").foregroundColor(.red).font(.system(size: 12))
            }
        }
        .padding(6)
        .background(Color.appCard2)
        .cornerRadius(6)
    }
}
