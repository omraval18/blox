/// Parses the small TOML subset Blox needs: `[tables]`, `key = value` (string, int, float, bool),
/// quoted keys, and `#` comments. Arrays, inline tables and dates are intentionally unsupported.
enum TOMLParser {
    /// Returns entries grouped by table name; top-level keys live under the empty name.
    static func parse(_ text: String) throws -> [String: [TOMLEntry]] {
        var tables: [String: [TOMLEntry]] = ["": []]
        var current = ""
        for (offset, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated() {
            let number = offset + 1
            let line = stripComment(String(raw)).trimmed
            if line.isEmpty {
                continue
            }
            if line.hasPrefix("[") {
                guard line.hasSuffix("]"), line.count > 2 else { throw ConfigError(
                    line: number,
                    message: "malformed table header",
                ) }
                current = String(line.dropFirst().dropLast()).trimmed
                tables[current, default: []] += []
            } else {
                try tables[current, default: []].append(entry(from: line, number: number))
            }
        }
        return tables
    }

    private static func entry(from line: String, number: Int) throws -> TOMLEntry {
        let (key, rest) = try splitKey(line, number: number)
        guard rest.hasPrefix("=") else { throw ConfigError(line: number, message: "expected '=' after key") }
        let value = try parseValue(String(rest.dropFirst()).trimmed, number: number)
        return TOMLEntry(key: key, value: value, line: number)
    }

    private static func splitKey(_ line: String, number: Int) throws -> (String, String) {
        if line.hasPrefix("\"") {
            let (key, rest) = try quoted(line, number: number)
            return (key, rest.trimmed)
        }
        guard let equals = line.firstIndex(of: "=") else { throw ConfigError(
            line: number,
            message: "expected 'key = value'",
        ) }
        return (String(line[..<equals]).trimmed, String(line[equals...]))
    }

    private static func parseValue(_ text: String, number: Int) throws -> TOMLValue {
        if text.hasPrefix("\"") {
            let (value, rest) = try quoted(text, number: number)
            guard rest.trimmed.isEmpty else { throw ConfigError(
                line: number,
                message: "unexpected text after string",
            ) }
            return .string(value)
        }
        if text == "true" || text == "false" {
            return .bool(text == "true")
        }
        if let int = Int(text) {
            return .int(int)
        }
        if let double = Double(text) {
            return .double(double)
        }
        throw ConfigError(line: number, message: "invalid value '\(text)'")
    }

    /// Reads a leading `"..."` string (supporting `\"` and `\\`), returning it and the remainder.
    private static func quoted(_ text: String, number: Int) throws -> (String, String) {
        var result = ""
        var escaped = false
        var index = text.index(after: text.startIndex)
        while index < text.endIndex {
            let char = text[index]
            index = text.index(after: index)
            if escaped {
                result.append(char)
                escaped = false
            } else if char == "\\" {
                escaped = true
            } else if char == "\"" {
                return (result, String(text[index...]))
            } else {
                result.append(char)
            }
        }
        throw ConfigError(line: number, message: "unterminated string")
    }

    private static func stripComment(_ line: String) -> String {
        var inString = false
        var escaped = false
        for index in line.indices {
            let char = line[index]
            if inString, char == "\\", !escaped {
                escaped = true; continue
            }
            if char == "\"", !escaped {
                inString.toggle()
            }
            if char == "#", !inString {
                return String(line[..<index])
            }
            escaped = false
        }
        return line
    }
}

extension String {
    var trimmed: String {
        var slice = Substring(self)
        while slice.first?.isWhitespace == true {
            slice.removeFirst()
        }
        while slice.last?.isWhitespace == true {
            slice.removeLast()
        }
        return String(slice)
    }
}
