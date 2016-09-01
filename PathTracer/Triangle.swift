import Foundation

struct Triangle : CustomStringConvertible, RayIntersectable {
    var firstNode: Vector3D
    var secondNode: Vector3D
    var thirdNode: Vector3D
    var normal: Vector3D
    var u: Vector3D
    var v: Vector3D
    var uu: Double
    var vv: Double
    var uv: Double
    var denom: Double
    var rAbsorbance: Double
    var gAbsorbance: Double
    var bAbsorbance: Double
    var diffuseReflectionProbability: Double
    var aLightsource: Bool
    var description: String {
        return "(\(self.firstNode), \(self.secondNode), \(self.thirdNode))"
    }

    init(firstNode: Vector3D, secondNode: Vector3D, thirdNode: Vector3D, rAbsorbance: Double, gAbsorbance: Double, bAbsorbance: Double, diffuseReflectionProbability: Double, aLightsource: Bool) {
        self.firstNode = firstNode
        self.secondNode = secondNode
        self.thirdNode = thirdNode
        self.normal = normalised((secondNode-firstNode)**(thirdNode-firstNode))
        self.u = secondNode - firstNode
        self.v = thirdNode - firstNode
        self.uu = self.u*self.u
        self.vv = self.v*self.v
        self.uv = self.u*self.v
        self.denom = self.uv*self.uv - self.uu*self.vv
        self.rAbsorbance = rAbsorbance
        self.gAbsorbance = gAbsorbance
        self.bAbsorbance = bAbsorbance
        self.diffuseReflectionProbability = diffuseReflectionProbability
        self.aLightsource = aLightsource
    }
    
    func modifyPhoton(intersectionDatum: IntersectionDatum, inout photon: Photon) -> Bool {
        photon.position = intersectionDatum.intersection
        photon.rIntensity *= (1.0-self.rAbsorbance)
        photon.gIntensity *= (1.0-self.gAbsorbance)
        photon.bIntensity *= (1.0-self.bAbsorbance)
        // Russian roulette. There is a 25 % chance that a photon with very low intensity is removed. If not: increase its intensity.
        if photon.intensity < 0.02 {
            if Double(arc4random())/Double(UINT32_MAX) < 0.25 {
                return true
            } else {
                photon.rIntensity *= 4
                photon.gIntensity *= 4
                photon.bIntensity *= 4
            }
        }
        // Mirror-like reflection.
        if Double(arc4random())/Double(UINT32_MAX) < (1.0-self.diffuseReflectionProbability) {
            // FIXME store trianglenormal^2 in the triangle
            photon.direction = normalised(photon.direction - 2.0*(photon.direction*intersectionDatum.normal)*(intersectionDatum.normal))
            return false
        }
        // Diffuse reflection.
        // theta is the angle from the normal, phi the other angle needed to specify the direction
        let theta = asin(Double(arc4random())/Double(UINT32_MAX)) // [0, pi/2]
        let phi = 2.0*M_PI*Double(arc4random())/Double(UINT32_MAX) // [0, 2pi]
        // Pick a point in the triangle plane.
        let p = self.firstNode
        // Let zPlane be the normal to the and let xPlane and yPlane be two vectors in the triangle plane;
        // they form an orthonormal coordinate system.
        let zPlane = intersectionDatum.normal
        let xPlane = normalised(p - intersectionDatum.intersection)
        let yPlane = zPlane**xPlane
        let vec = Vector3D(x: sin(theta)*cos(phi), y: sin(theta)*sin(phi), z: cos(theta))
        photon.direction = normalised(vec.x*xPlane + vec.y*yPlane + vec.z*zPlane) // normalisation not needed?
        return false
    }
    
    func isALightsource() -> Bool {
        return self.aLightsource
    }
}
