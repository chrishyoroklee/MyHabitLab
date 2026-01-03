import Foundation

struct HabitUnit: Hashable, Codable {
    let displayName: String
    let baseName: String
    let baseScale: Int
    let displayPrecision: Int

    init(
        displayName: String,
        baseName: String,
        baseScale: Int,
        displayPrecision: Int
    ) {
        self.displayName = displayName
        self.baseName = baseName
        self.baseScale = max(1, baseScale)
        self.displayPrecision = max(0, displayPrecision)
    }
}

enum HabitProgress {
    static func baseValue(fromDisplay displayValue: Double, unit: HabitUnit) -> Int {
        let scaled = displayValue * Double(unit.baseScale)
        let rounded = scaled.rounded(.toNearestOrAwayFromZero)
        return max(0, Int(rounded))
    }

    static func displayValue(fromBase baseValue: Int, unit: HabitUnit) -> Double {
        Double(baseValue) / Double(unit.baseScale)
    }

    static func formattedDisplay(
        baseValue: Int,
        unit: HabitUnit,
        locale: Locale = .current
    ) -> String {
        let value = displayValue(fromBase: baseValue, unit: unit)
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = unit.displayPrecision
        formatter.maximumFractionDigits = unit.displayPrecision
        let valueString = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(valueString) \(unit.displayName)"
    }

    static func formattedProgress(
        currentBase: Int,
        goalBase: Int,
        unit: HabitUnit,
        locale: Locale = .current
    ) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = unit.displayPrecision
        formatter.maximumFractionDigits = unit.displayPrecision

        let currentDisplay = displayValue(fromBase: currentBase, unit: unit)
        let goalDisplay = displayValue(fromBase: goalBase, unit: unit)
        let currentString = formatter.string(from: NSNumber(value: currentDisplay)) ?? "\(currentDisplay)"
        let goalString = formatter.string(from: NSNumber(value: goalDisplay)) ?? "\(goalDisplay)"
        return "\(currentString)/\(goalString) \(unit.displayName)"
    }

    static func progress(currentBase: Int, goalBase: Int) -> Double {
        guard goalBase > 0 else { return 0 }
        let clamped = max(0, currentBase)
        return min(Double(clamped) / Double(goalBase), 1.0)
    }

    static func isComplete(currentBase: Int, goalBase: Int) -> Bool {
        guard goalBase > 0 else { return false }
        return currentBase >= goalBase
    }
}

extension Habit {
    var unitConfiguration: HabitUnit? {
        guard let displayName = unitDisplayName else { return nil }
        let baseName = unitBaseName ?? displayName
        return HabitUnit(
            displayName: displayName,
            baseName: baseName,
            baseScale: unitBaseScale,
            displayPrecision: unitDisplayPrecision
        )
    }
}
