struct Room {
    var spheres: [Sphere] = []
    var lightsources: [Triangle] = []
    var surfaces: [Triangle] = []
    var retina: Vector3D
    var viewDirection: Vector3D
    var viewXMin: Int
    var viewXMax: Int
    var viewYMin: Int
    var viewYMax: Int
    var viewWidth: Int {
        return self.viewXMax - self.viewXMin
    }
    var viewHeight: Int {
        return self.viewYMax - self.viewYMin
    }
    init(retina: Vector3D, viewDirection: Vector3D, viewXMin: Int, viewXMax: Int, viewYMin: Int, viewYMax: Int) {
        self.retina = retina
        self.viewDirection = viewDirection
        self.viewXMin = viewXMin
        self.viewXMax = viewXMax
        self.viewYMin = viewYMin
        self.viewYMax = viewYMax
    }
}
