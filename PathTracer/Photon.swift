import Foundation

struct Photon : CustomStringConvertible {
    var rIntensity: Double = 1.0
    var gIntensity: Double = 1.0
    var bIntensity: Double = 1.0
    var intensity: Double {
        return (self.rIntensity + self.gIntensity + self.bIntensity)/3.0
    }
    var position: Vector3D
    var direction: Vector3D
    var description: String {
        return "A photon: \n(r, g, b ) = (\(self.rIntensity), \(self.gIntensity), \(self.bIntensity)),\nposition \(self.position),\ndirection \(self.direction)."
    }
    
    init(position: Vector3D, direction: Vector3D) {
        self.position = position
        self.direction = direction
    }
}
