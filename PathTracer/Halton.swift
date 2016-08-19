import Foundation

struct Halton {
    static func generate(index: Int, _ base: Int) -> Double {
        var result: Double = 0.0
        var f: Double = 1.0
        var i: Int = index
        while i > 0 {
            f = f/Double(base)
            result = result + f*(Double(i%base))
            i = Int(Double(i)/Double(base))
        }
        return result
    }
}
