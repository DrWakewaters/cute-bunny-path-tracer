import Foundation

struct Sphere : RayIntersectable {
    var refractiveIndex: Double
    var radius: Double
    var position: Vector3D
    var rAbsorbanceDuringReflection: Double
    var gAbsorbanceDuringReflection: Double
    var bAbsorbanceDuringReflection: Double
    var rAbsorbanceDuringTransmittancePerPoint: Double
    var gAbsorbanceDuringTransmittancePerPoint: Double
    var bAbsorbanceDuringTransmittancePerPoint: Double
    var diffuseReflectionProbability: Double
    var isOpaque: Bool
    var aLightsource: Bool
    
    // A photon interacts at a sphere. There will be reflection, transmission or absorption.
    // See http://graphics.stanford.edu/courses/cs148-10-summer/docs/2006--degreve--reflection_refraction.pdf
    func modifyPhoton(intersectionDatum: IntersectionDatum, inout photon: Photon) -> Bool {
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
            let distance = norm(photon.position-intersectionDatum.intersection)
            photon.position = intersectionDatum.intersection
            let isInsideSphere: Bool
            var eta1: Double
            var eta2: Double
            if photon.direction*intersectionDatum.normal > 0 {
                isInsideSphere = true
            } else {
                isInsideSphere = false
            }
            if isInsideSphere {
                eta1 = self.refractiveIndex
                eta2 = 1.0
            } else {
                eta1 = 1.0
                eta2 = self.refractiveIndex
            }
            let etaQuotient = (eta1/eta2)
            var cosThetaI = photon.direction*intersectionDatum.normal
            if cosThetaI < 0.0 {
                cosThetaI *= -1
            }
            let sinThetaTSquared = etaQuotient*etaQuotient*(1-cosThetaI*cosThetaI)
            // Diffuse reflection.
            if Double(arc4random())/Double(UINT32_MAX) < self.diffuseReflectionProbability {
                // theta is the angle from the normal, phi the other angle needed to specify the direction
                let theta = asin(Double(arc4random())/Double(UINT32_MAX)) // [0, pi/2]
                let phi = 2.0*M_PI*Double(arc4random())/Double(UINT32_MAX) // [0, 2pi]
                // Pick a point in the tangent plane. FIXME: make sure an x and y is picked that is in the plane.
                let x = Double(arc4random())/Double(UINT32_MAX)
                let y = Double(arc4random())/Double(UINT32_MAX)
                let z = intersectionDatum.intersection*intersectionDatum.normal - x*intersectionDatum.normal.x - y*intersectionDatum.normal.y
                let p = Vector3D(x: x, y: y, z: z)
                // Let zPlane be the normal to the and let xPlane and yPlane be two vectors in the tangent plane;
                // they form an orthonormal coordinate system.
                let zPlane = intersectionDatum.normal
                let xPlane = normalised(p - intersectionDatum.intersection)
                let yPlane = zPlane**xPlane
                let vec = Vector3D(x: sin(theta)*cos(phi), y: sin(theta)*sin(phi), z: cos(theta))
                photon.direction = normalised(vec.x*xPlane + vec.y*yPlane + vec.z*zPlane) // normalisation not needed?
                photon.rIntensity *= (1-self.rAbsorbanceDuringReflection)
                photon.gIntensity *= (1-self.gAbsorbanceDuringReflection)
                photon.bIntensity *= (1-self.bAbsorbanceDuringReflection)
                return false
            }
            // Mirror-like reflection or transmission. Not total internal reflection.
            if sinThetaTSquared <= 1 {
                let cosThetaT = sqrt(1.0 - sinThetaTSquared*sinThetaTSquared)
                let rVerticalSqrt = (eta1*cosThetaI - eta2*cosThetaT)/(eta1*cosThetaI + eta2*cosThetaT)
                let rVertical = rVerticalSqrt*rVerticalSqrt
                let rHorizontalSqrt = (eta2*cosThetaI - eta1*cosThetaT)/(eta2*cosThetaI + eta1*cosThetaT)
                let rHorizontal = rHorizontalSqrt*rHorizontalSqrt
                let R = (rVertical + rHorizontal)/2.0
                // Reflection
                if Double(arc4random())/Double(UINT32_MAX) <= R || self.isOpaque {
                    photon.direction = normalised(photon.direction - 2.0*(photon.direction*intersectionDatum.normal)*intersectionDatum.normal)
                    photon.rIntensity *= (1.0-self.rAbsorbanceDuringReflection)
                    photon.gIntensity *= (1.0-self.gAbsorbanceDuringReflection)
                    photon.bIntensity *= (1.0-self.bAbsorbanceDuringReflection)
                    // Transmission
                } else {
                    photon.direction = (etaQuotient*photon.direction) + (etaQuotient*cosThetaI-sqrt(1-sinThetaTSquared))*intersectionDatum.normal
                    if isInsideSphere {
                        photon.rIntensity *= pow(1.0-self.rAbsorbanceDuringTransmittancePerPoint, distance)
                        photon.gIntensity *= pow(1.0-self.gAbsorbanceDuringTransmittancePerPoint, distance)
                        photon.bIntensity *= pow(1.0-self.bAbsorbanceDuringTransmittancePerPoint, distance)
                    }
                }
                // Total internal reflection.
            } else {
                photon.direction = photon.direction - 2.0*(photon.direction*intersectionDatum.normal)*intersectionDatum.normal
                photon.rIntensity *= pow(1.0-self.rAbsorbanceDuringTransmittancePerPoint, distance)
                photon.gIntensity *= pow(1.0-self.gAbsorbanceDuringTransmittancePerPoint, distance)
                photon.bIntensity *= pow(1.0-self.bAbsorbanceDuringTransmittancePerPoint, distance)
                
            }
            photon.direction = normalised(photon.direction)
            return false
    }
    
    func isALightsource() -> Bool {
        return self.aLightsource
    }
}
