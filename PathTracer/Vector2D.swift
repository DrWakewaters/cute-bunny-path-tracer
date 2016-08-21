struct Vector2D : CustomStringConvertible {
    var x: Double
    var y: Double
    var description: String {
        return "(\(self.x), \(self.y))"
    }
}
