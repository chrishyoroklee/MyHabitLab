import Foundation
import Testing
@testable import MyHabitLab

struct HabitProgressTests {
    @Test func baseConversionFromDisplayUsesScale() {
        let unit = HabitUnit(displayName: "L", baseName: "ml", baseScale: 1000, displayPrecision: 1)
        let base = HabitProgress.baseValue(fromDisplay: 2.5, unit: unit)
        #expect(base == 2500)
    }

    @Test func displayConversionUsesScale() {
        let unit = HabitUnit(displayName: "L", baseName: "ml", baseScale: 1000, displayPrecision: 1)
        let display = HabitProgress.displayValue(fromBase: 1500, unit: unit)
        #expect(abs(display - 1.5) < 0.0001)
    }

    @Test func hoursToMinutesConversion() {
        let unit = HabitUnit(displayName: "hours", baseName: "minutes", baseScale: 60, displayPrecision: 1)
        let base = HabitProgress.baseValue(fromDisplay: 1.5, unit: unit)
        #expect(base == 90)
    }

    @Test func customDecimalScaleConversion() {
        let unit = HabitUnit(displayName: "miles", baseName: "miles", baseScale: 10, displayPrecision: 1)
        let base = HabitProgress.baseValue(fromDisplay: 1.2, unit: unit)
        #expect(base == 12)
    }

    @Test func progressAndCompletion() {
        let progress = HabitProgress.progress(currentBase: 750, goalBase: 1000)
        #expect(abs(progress - 0.75) < 0.0001)
        #expect(HabitProgress.isComplete(currentBase: 1000, goalBase: 1000))
        #expect(!HabitProgress.isComplete(currentBase: 999, goalBase: 1000))
    }

    @Test func formattedProgressUsesPrecision() {
        let unit = HabitUnit(displayName: "L", baseName: "ml", baseScale: 1000, displayPrecision: 1)
        let text = HabitProgress.formattedProgress(currentBase: 1500, goalBase: 2000, unit: unit, locale: Locale(identifier: "en_US_POSIX"))
        #expect(text == "1.5/2.0 L")
    }
}
