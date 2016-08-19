import Foundation

// FIXME: change from per pixel to per unit length (add info about pixels per unit length)
struct Sphere {
    var refractiveIndex: Double
    var radius: Double
    var position: Vector3D
    var rAbsorbanceReflection: Double
    var gAbsorbanceReflection: Double
    var bAbsorbanceReflection: Double
    var rAbsorbanceTransmittancePerPixel: Double
    var gAbsorbanceTransmittancePerPixel: Double
    var bAbsorbanceTransmittancePerPixel: Double
    var diffuseReflectionProbability: Double
    var isOpaque: Bool
}
