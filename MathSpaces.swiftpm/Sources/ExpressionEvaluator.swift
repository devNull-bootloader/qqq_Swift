import Foundation

// MARK: - Errors

enum EvalError: LocalizedError {
    case unexpectedEnd
    case unexpectedToken(String)
    case unknownFunction(String)
    case divisionByZero
    case unknownVariable(String)
    case missingClosingParen

    var errorDescription: String? {
        switch self {
        case .unexpectedEnd:              return "Unerwartetes Ende des Ausdrucks"
        case .unexpectedToken(let t):    return "Unerwartetes Zeichen: \(t)"
        case .unknownFunction(let f):    return "Unbekannte Funktion: \(f)"
        case .divisionByZero:            return "Division durch Null"
        case .unknownVariable(let v):    return "Unbekannte Variable: \(v)"
        case .missingClosingParen:       return "Fehlende schließende Klammer )"
        }
    }
}

// MARK: - Token

private enum Token: Equatable {
    case num(Double)
    case op(String)    // + - * / ^ %
    case name(String)  // function or variable name
    case lparen
    case rparen
}

// MARK: - Evaluator

class ExpressionEvaluator {

    enum AngleMode { case deg, rad }
    var angleMode: AngleMode = .deg
    var variables: [String: Double] = [:]

    // MARK: Public API

    func evaluate(_ expr: String) throws -> Double {
        let tokens = try tokenize(normalize(expr))
        var idx = 0
        let result = try parseExpr(tokens, &idx)
        if idx < tokens.count {
            throw EvalError.unexpectedToken(tokenDescription(tokens[idx]))
        }
        return result
    }

    // MARK: - Normalisation

    private func normalize(_ expr: String) -> String {
        var s = expr
        s = s.replacingOccurrences(of: "×", with: "*")
        s = s.replacingOccurrences(of: "÷", with: "/")
        s = s.replacingOccurrences(of: "²", with: "^2")
        s = s.replacingOccurrences(of: "√", with: "sqrt")
        s = s.replacingOccurrences(of: "π", with: "pi")
        s = s.replacingOccurrences(of: "−", with: "-")
        return s
    }

    // MARK: - Tokeniser

    private func tokenize(_ input: String) throws -> [Token] {
        var result: [Token] = []
        let chars = Array(input)
        var pos = 0

        while pos < chars.count {
            let c = chars[pos]

            if c.isWhitespace { pos += 1; continue }

            // Number
            if c.isNumber || c == "." {
                var num = ""
                while pos < chars.count && (chars[pos].isNumber || chars[pos] == ".") {
                    num.append(chars[pos]); pos += 1
                }
                // Scientific notation  e.g.  1e3  or  2.5e-4
                if pos < chars.count && (chars[pos] == "e" || chars[pos] == "E") {
                    num.append(chars[pos]); pos += 1
                    if pos < chars.count && (chars[pos] == "+" || chars[pos] == "-") {
                        num.append(chars[pos]); pos += 1
                    }
                    while pos < chars.count && chars[pos].isNumber {
                        num.append(chars[pos]); pos += 1
                    }
                }
                guard let val = Double(num) else {
                    throw EvalError.unexpectedToken(num)
                }
                result.append(.num(val))
                // Implicit multiply: 2x  2(
                if pos < chars.count && (chars[pos].isLetter || chars[pos] == "(") {
                    result.append(.op("*"))
                }
                continue
            }

            // Identifier / function / constant
            if c.isLetter || c == "_" {
                var name = ""
                while pos < chars.count && (chars[pos].isLetter || chars[pos].isNumber || chars[pos] == "_") {
                    name.append(chars[pos]); pos += 1
                }
                result.append(.name(name))
                // No implicit multiply after name – the name could be a function call
                continue
            }

            // Parentheses
            if c == "(" {
                // Implicit multiply: )(  or  x(
                if let last = result.last, case .rparen = last {
                    result.append(.op("*"))
                }
                result.append(.lparen); pos += 1; continue
            }
            if c == ")" { result.append(.rparen); pos += 1; continue }

            // Operators
            let ops: Set<Character> = ["+", "-", "*", "/", "^", "%"]
            if ops.contains(c) { result.append(.op(String(c))); pos += 1; continue }

            // Unknown – skip
            pos += 1
        }

        return result
    }

    // MARK: - Recursive Descent Parser
    // Grammar (↑ = higher precedence):
    //  expr   = term   (('+' | '-') term)*
    //  term   = power  (('*' | '/' | '%') power)*
    //  power  = unary  ('^' unary)*          // right-assoc via recursion
    //  unary  = '-' unary | primary
    //  primary = num | name ['(' expr ')'] | '(' expr ')'

    private func parseExpr(_ tokens: [Token], _ idx: inout Int) throws -> Double {
        var lhs = try parseTerm(tokens, &idx)
        while idx < tokens.count, case .op(let op) = tokens[idx], op == "+" || op == "-" {
            idx += 1
            let rhs = try parseTerm(tokens, &idx)
            lhs = op == "+" ? lhs + rhs : lhs - rhs
        }
        return lhs
    }

    private func parseTerm(_ tokens: [Token], _ idx: inout Int) throws -> Double {
        var lhs = try parsePower(tokens, &idx)
        while idx < tokens.count, case .op(let op) = tokens[idx], op == "*" || op == "/" || op == "%" {
            idx += 1
            let rhs = try parsePower(tokens, &idx)
            if op == "/" {
                if rhs == 0 { throw EvalError.divisionByZero }
                lhs /= rhs
            } else if op == "%" {
                lhs = lhs.truncatingRemainder(dividingBy: rhs)
            } else {
                lhs *= rhs
            }
        }
        return lhs
    }

    private func parsePower(_ tokens: [Token], _ idx: inout Int) throws -> Double {
        let base = try parseUnary(tokens, &idx)
        if idx < tokens.count, case .op("^") = tokens[idx] {
            idx += 1
            let exp = try parseUnary(tokens, &idx) // right-associative
            return pow(base, exp)
        }
        return base
    }

    private func parseUnary(_ tokens: [Token], _ idx: inout Int) throws -> Double {
        if idx < tokens.count, case .op("-") = tokens[idx] {
            idx += 1
            return try -parsePrimary(tokens, &idx)
        }
        if idx < tokens.count, case .op("+") = tokens[idx] {
            idx += 1
        }
        return try parsePrimary(tokens, &idx)
    }

    private func parsePrimary(_ tokens: [Token], _ idx: inout Int) throws -> Double {
        guard idx < tokens.count else { throw EvalError.unexpectedEnd }

        switch tokens[idx] {
        case .num(let v):
            idx += 1
            return v

        case .lparen:
            idx += 1 // consume '('
            let val = try parseExpr(tokens, &idx)
            guard idx < tokens.count, case .rparen = tokens[idx] else {
                throw EvalError.missingClosingParen
            }
            idx += 1 // consume ')'
            return val

        case .name(let name):
            idx += 1
            // Check for function call
            if idx < tokens.count, case .lparen = tokens[idx] {
                idx += 1 // consume '('
                let arg = try parseExpr(tokens, &idx)
                guard idx < tokens.count, case .rparen = tokens[idx] else {
                    throw EvalError.missingClosingParen
                }
                idx += 1 // consume ')'
                return try applyFunction(name, arg)
            }
            // Constant or variable
            return try resolveIdent(name)

        case .rparen:
            throw EvalError.unexpectedToken(")")

        case .op(let op):
            throw EvalError.unexpectedToken(op)
        }
    }

    // MARK: - Helpers

    private func resolveIdent(_ name: String) throws -> Double {
        switch name.lowercased() {
        case "pi", "π": return Double.pi
        case "e":        return M_E
        case "inf":      return Double.infinity
        default:
            if let v = variables[name]            { return v }
            if let v = variables[name.lowercased()] { return v }
            throw EvalError.unknownVariable(name)
        }
    }

    private func applyFunction(_ name: String, _ arg: Double) throws -> Double {
        // Convert arg to radians if needed (for trig)
        let toRad = angleMode == .deg ? arg * .pi / 180.0 : arg
        let fromRad: (Double) -> Double = { r in
            self.angleMode == .deg ? r * 180.0 / .pi : r
        }

        switch name.lowercased() {
        case "sin":             return sin(toRad)
        case "cos":             return cos(toRad)
        case "tan":             return tan(toRad)
        case "asin", "arcsin":  return fromRad(asin(arg))
        case "acos", "arccos":  return fromRad(acos(arg))
        case "atan", "arctan":  return fromRad(atan(arg))
        case "sqrt":            return sqrt(arg)
        case "cbrt":            return cbrt(arg)
        case "abs":             return abs(arg)
        case "log", "log10":    return log10(arg)
        case "ln":              return log(arg)
        case "log2":            return log2(arg)
        case "exp":             return exp(arg)
        case "ceil":            return ceil(arg)
        case "floor":           return floor(arg)
        case "round":           return arg.rounded()
        case "sign", "sgn":     return arg > 0 ? 1 : (arg < 0 ? -1 : 0)
        default:
            throw EvalError.unknownFunction(name)
        }
    }

    private func tokenDescription(_ token: Token) -> String {
        switch token {
        case .num(let v):  return "\(v)"
        case .op(let s):   return s
        case .name(let s): return s
        case .lparen:      return "("
        case .rparen:      return ")"
        }
    }
}

// MARK: - Convenience

extension ExpressionEvaluator {
    /// Evaluate with a given x value (useful for plotting)
    func evaluate(_ expr: String, x: Double) throws -> Double {
        let saved = variables["x"]
        variables["x"] = x
        defer { variables["x"] = saved }
        return try evaluate(expr)
    }
}
