struct PixelDatum : CustomStringConvertible {
    var a: UInt8
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var description: String {
        return "(\(self.r), \(self.g), \(self.b))"
    }
}
