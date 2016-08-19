import Foundation

struct Room {
    var spheres: [Sphere] = []
    var lightsources: [Triangle] = []
    var surfaces: [Triangle] = []
    var retina: Vector3D
    var viewDirection: Vector3D
    var viewWidth: Int
    var viewHeight: Int
    init(retina: Vector3D, viewDirection: Vector3D, viewWidth: Int, viewHeight: Int) {
        self.retina = retina
        self.viewDirection = viewDirection
        self.viewWidth = viewWidth
        self.viewHeight = viewHeight
    }
}
