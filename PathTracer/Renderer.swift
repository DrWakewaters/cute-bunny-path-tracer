import Foundation
import CoreImage

class Renderer {
    var room: Room
    var pixelData: [[PixelDatum]]
    var renderingQueue: dispatch_queue_t
    var renderingGroup: dispatch_group_t
    var writeToSelfQueue: dispatch_queue_t
    var writeToSelfGroup: dispatch_group_t
    var passesPerPixel: Int = 8
    var rowsRendered: Int = 0
    var renderedPercent: Int = 0
    var pixelsPerPoint = 2
    var xRandom = [Double]()
    var yRandom = [Double]()
    
    init() {
        let (viewXMin, viewXMax, viewYMin, viewYMax) = (100, 900, 200, 800)
        let xRetina = (viewXMin + viewXMax)/2
        let yRetina = (viewYMin + viewYMax)/2
        var room = Room(retina: Vector3D(x: Double(xRetina), y: Double(yRetina), z: 1400.0), viewDirection: Vector3D(x: 0.0, y: 0.0, z: -1.0), viewXMin: viewXMin, viewXMax: viewXMax, viewYMin: viewYMin, viewYMax: viewYMax)
        let cornerNodes = [Vector3D(x: 0, y: 0, z: 0), Vector3D(x: 1000, y: 0, z: 0), Vector3D(x: 1000, y: 1000, z: 0), Vector3D(x: 0, y: 1000, z: 0), Vector3D(x: 0, y: 0, z: 1000), Vector3D(x: 1000, y: 0, z: 1000), Vector3D(x: 1000, y: 1000, z: 1000), Vector3D(x: 0, y: 1000, z: 1000)]
        let lightNodes = [Vector3D(x: 350, y: 1000, z: 350), Vector3D(x: 350, y: 1000, z: 650), Vector3D(x: 650, y: 1000, z: 650), Vector3D(x: 650, y: 1000, z: 350), Vector3D(x: 350, y: 1500, z: 350), Vector3D(x: 350, y: 1500, z: 650), Vector3D(x: 650, y: 1500, z: 650), Vector3D(x: 650, y: 1500, z: 350)]
        let extraNodes = [Vector3D(x: 350, y: 1000, z: 0), Vector3D(x: 350, y: 1000, z: 1000), Vector3D(x: 650, y: 1000, z: 1000), Vector3D(x: 650, y: 1000, z: 0)]
        let diffuseReflectionProbability = 0.92
        // the lightsource
        room.lightsources.append(Triangle(firstNode: lightNodes[4], secondNode: lightNodes[7], thirdNode: lightNodes[6], rAbsorbance: 0.0, gAbsorbance: 0.0, bAbsorbance: 0.0, diffuseReflectionProbability: diffuseReflectionProbability))
        room.lightsources.append(Triangle(firstNode: lightNodes[4], secondNode: lightNodes[6], thirdNode: lightNodes[5], rAbsorbance: 0.0, gAbsorbance: 0.0, bAbsorbance: 0.0, diffuseReflectionProbability: diffuseReflectionProbability))
        // xy-plane
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[1], thirdNode: cornerNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[2], thirdNode: cornerNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // xz-plane
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[4], thirdNode: cornerNodes[5], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[5], thirdNode: cornerNodes[1], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // yz-plane
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[3], thirdNode: cornerNodes[7], rAbsorbance: 0.05, gAbsorbance: 0.6, bAbsorbance: 0.6, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[7], thirdNode: cornerNodes[4], rAbsorbance: 0.05, gAbsorbance: 0.6, bAbsorbance: 0.6, diffuseReflectionProbability: diffuseReflectionProbability))
        // yz-plane with x=1000
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[2], thirdNode: cornerNodes[1], rAbsorbance: 0.6, gAbsorbance: 0.6, bAbsorbance: 0.05, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[1], thirdNode: cornerNodes[5], rAbsorbance: 0.6, gAbsorbance: 0.6, bAbsorbance: 0.05, diffuseReflectionProbability: diffuseReflectionProbability))
        // xz-plane with y=1000; x > 650
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: extraNodes[2], thirdNode: extraNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: extraNodes[3], thirdNode: cornerNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // xz-plane with y=1000, x < 350
        room.surfaces.append(Triangle(firstNode: cornerNodes[7], secondNode: cornerNodes[3], thirdNode: extraNodes[0], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: cornerNodes[7], secondNode: extraNodes[0], thirdNode: extraNodes[1], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // xz-plane with y=1000, 350<x<650, 650<z<1000
        room.surfaces.append(Triangle(firstNode: extraNodes[1], secondNode: lightNodes[1], thirdNode: lightNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: extraNodes[1], secondNode: lightNodes[2], thirdNode: extraNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // xz-plane with y=1000, 350<x<650, 0<z<350
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: extraNodes[0], thirdNode: extraNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: extraNodes[3], thirdNode: lightNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // xy-plane with z=350, 350<x<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: lightNodes[3], thirdNode: lightNodes[7], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: lightNodes[7], thirdNode: lightNodes[4], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // yz-plane with x=350, 350<z<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[1], thirdNode: lightNodes[0], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[0], thirdNode: lightNodes[4], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // xy-plane with z=650, 350<x<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[6], thirdNode: lightNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[2], thirdNode: lightNodes[1], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // yz-plane with x=650, 350<z<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[6], secondNode: lightNodes[7], thirdNode: lightNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: lightNodes[6], secondNode: lightNodes[3], thirdNode: lightNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // xy-plane with z=1000
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[5], thirdNode: cornerNodes[4], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[4], thirdNode: cornerNodes[7], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability))
        // a sphere
        room.spheres.append(Sphere(refractiveIndex: 2.0, radius: 200, position: Vector3D(x: 300.0, y: 400.0, z: 400.0), rAbsorbanceReflection: 0.3, gAbsorbanceReflection: 0.05, bAbsorbanceReflection: 0.3, rAbsorbanceTransmittancePerPixel: 0.0003, gAbsorbanceTransmittancePerPixel: 0.00005, bAbsorbanceTransmittancePerPixel: 0.0003, diffuseReflectionProbability: 0.02, isOpaque: false))
        room.spheres.append(Sphere(refractiveIndex: 1.0, radius: 200, position: Vector3D(x: 750.0, y: 300.0, z: 400.0), rAbsorbanceReflection: 0.1, gAbsorbanceReflection: 0.1, bAbsorbanceReflection: 0.7, rAbsorbanceTransmittancePerPixel: 0.0, gAbsorbanceTransmittancePerPixel: 0.0, bAbsorbanceTransmittancePerPixel: 0.0, diffuseReflectionProbability: 0.0, isOpaque: true))
        self.room = room
        let viewWidth = viewXMax - viewXMin
        let viewHeight = viewYMax - viewYMin
        let numberOfPixelsInARow = self.pixelsPerPoint*viewWidth
        let numberOfPixelsInAColumn = self.pixelsPerPoint*viewHeight
        self.pixelData = [[PixelDatum]](count: numberOfPixelsInARow, repeatedValue: [PixelDatum](count: numberOfPixelsInAColumn, repeatedValue: PixelDatum(a: 255, r: 0, g: 0, b: 0)))
        self.renderingQueue = dispatch_queue_create("renderingQueue", DISPATCH_QUEUE_CONCURRENT)
        self.renderingGroup = dispatch_group_create()
        self.writeToSelfQueue = dispatch_queue_create("writeToSelfQueue", DISPATCH_QUEUE_SERIAL)
        self.writeToSelfGroup = dispatch_group_create()
        for i in 1...self.passesPerPixel {
            self.xRandom.append(Halton.generate(i, 2))
            self.yRandom.append(Halton.generate(i, 3))
        }
    }
    
    // A photon interacts at a sphere. There will be reflection, transmission or absorption.
    // See http://graphics.stanford.edu/courses/cs148-10-summer/docs/2006--degreve--reflection_refraction.pdf
    func photonIntersectionAtSphere(room: Room, inout photon: Photon, sphereIntersection: Vector3D, sphereNormal: Vector3D, sphere: Sphere) -> Bool {
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
        let distance = norm(photon.position-sphereIntersection)
        photon.position = sphereIntersection
        let isInsideSphere: Bool
        var eta1: Double
        var eta2: Double
        if photon.direction*sphereNormal > 0 {
            isInsideSphere = true
        } else {
            isInsideSphere = false
        }
        if isInsideSphere {
            eta1 = sphere.refractiveIndex
            eta2 = 1.0
        } else {
            eta1 = 1.0
            eta2 = sphere.refractiveIndex
        }
        let etaQuotient = (eta1/eta2)
        var cosThetaI = photon.direction*sphereNormal
        if cosThetaI < 0.0 {
            cosThetaI *= -1
        }
        let sinThetaTSquared = etaQuotient*etaQuotient*(1-cosThetaI*cosThetaI)
        // Diffuse reflection.
        if Double(arc4random())/Double(UINT32_MAX) < sphere.diffuseReflectionProbability {
            // theta is the angle from the normal, phi the other angle needed to specify the direction
            let theta = asin(Double(arc4random())/Double(UINT32_MAX)) // [0, pi/2]
            let phi = 2.0*M_PI*Double(arc4random())/Double(UINT32_MAX) // [0, 2pi]
            // Pick a point in the tangent plane. FIXME: make sure an x and y is picked that is in the plane.
            let x = Double(arc4random())/Double(UINT32_MAX)
            let y = Double(arc4random())/Double(UINT32_MAX)
            let z = sphereIntersection*sphereNormal - x*sphereNormal.x - y*sphereNormal.y
            let p = Vector3D(x: x, y: y, z: z)
            // Let zPlane be the normal to the and let xPlane and yPlane be two vectors in the tangent plane;
            // they form an orthonormal coordinate system.
            let zPlane = sphereNormal
            let xPlane = normalised(p - sphereIntersection)
            let yPlane = zPlane**xPlane
            let vec = Vector3D(x: sin(theta)*cos(phi), y: sin(theta)*sin(phi), z: cos(theta))
            photon.direction = normalised(vec.x*xPlane + vec.y*yPlane + vec.z*zPlane) // normalisation not needed?
            photon.rIntensity *= (1-sphere.rAbsorbanceReflection)
            photon.gIntensity *= (1-sphere.gAbsorbanceReflection)
            photon.bIntensity *= (1-sphere.bAbsorbanceReflection)
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
            if Double(arc4random())/Double(UINT32_MAX) <= R || sphere.isOpaque {
                photon.direction = normalised(photon.direction - 2.0*(photon.direction*sphereNormal)*sphereNormal)
                photon.rIntensity *= (1.0-sphere.rAbsorbanceReflection)
                photon.gIntensity *= (1.0-sphere.gAbsorbanceReflection)
                photon.bIntensity *= (1.0-sphere.bAbsorbanceReflection)
            // Transmission
            } else {
                photon.direction = (etaQuotient*photon.direction) + (etaQuotient*cosThetaI-sqrt(1-sinThetaTSquared))*sphereNormal
                if isInsideSphere {
                    photon.rIntensity *= pow(1.0-sphere.rAbsorbanceTransmittancePerPixel, distance)
                    photon.gIntensity *= pow(1.0-sphere.gAbsorbanceTransmittancePerPixel, distance)
                    photon.bIntensity *= pow(1.0-sphere.bAbsorbanceTransmittancePerPixel, distance)
                }
            }
        // Total internal reflection.
        } else {
            photon.direction = photon.direction - 2.0*(photon.direction*sphereNormal)*sphereNormal
            photon.rIntensity *= pow(1.0-sphere.rAbsorbanceTransmittancePerPixel, distance)
            photon.gIntensity *= pow(1.0-sphere.gAbsorbanceTransmittancePerPixel, distance)
            photon.bIntensity *= pow(1.0-sphere.bAbsorbanceTransmittancePerPixel, distance)

        }
        photon.direction = normalised(photon.direction)
        return false
    }
    
    func findClosestIntersectedSphere(room: Room, inout photon: Photon) -> (Double, Vector3D?, Vector3D?, Sphere?) {
        var closestDistance = Double.infinity
        var intersection: Vector3D?
        var normal: Vector3D?
        var closestSphere: Sphere?
        for sphere in room.spheres {
            let p = photon.direction*(photon.position-sphere.position)
            let a = p*p - square(photon.position - sphere.position) + sphere.radius*sphere.radius
            if a <= 0 {
                continue
            }
            let b = -1.0*(photon.direction*(photon.position-sphere.position))
            let (d1, d2) = (b + sqrt(a), b - sqrt(a))
            // 1e-7 rather than 0 to avoid intersecting twice; consider finding a better method.
            // (The distance might not be negative - that would be in the wrong direction.)
            if d2 > 1e-7 && d2 < closestDistance {
                closestDistance = d2
                closestSphere = sphere
                intersection = d2*photon.direction + photon.position
                normal = normalised(intersection! - sphere.position)
            } else if d1 > 1e-7 && d1 < closestDistance {
                closestDistance = d1
                closestSphere = sphere
                intersection = d1*photon.direction + photon.position
                normal = normalised(intersection! - sphere.position)
            }
        }
        return (closestDistance, intersection, normal, closestSphere)
    }
 
    func findClosestIntersectedTriangle(room: Room, inout photon: Photon, triangles: [Triangle]) -> (Double, Vector3D?, Vector3D?, Triangle?) {
        var closestDistance = Double.infinity
        var intersection: Vector3D?
        var normal: Vector3D?
        var closestTriangle: Triangle?
        for triangle in triangles {
            let d = ((triangle.firstNode - photon.position)*triangle.normal)/(photon.direction*triangle.normal)
            // 1e-7 rather than 0 to avoid intersecting twice; consider finding a better method.
            // (The distance might not be negative - that would be in the wrong direction.)
            if d > 1e-7 && d < closestDistance {
                // See http://geomalgorithms.com/a06-_intersect-2.html
                let w = (d*photon.direction + photon.position) - triangle.firstNode
                let wv = w*triangle.v
                let wu = w*triangle.u
                let s = (triangle.uv*wv - triangle.vv*wu)/triangle.denom
                let t = (triangle.uv*wu - triangle.uu*wv)/triangle.denom
                if s >= 0 && t >= 0 && s+t <= 1 {
                    closestDistance = d
                    intersection = d*photon.direction + photon.position
                    normal = triangle.normal
                    closestTriangle = triangle
                }
            }
        }
        return (closestDistance, intersection, normal, closestTriangle)
    }
    
    func photonIntersectionAtTriangle(room: Room, inout photon: Photon, triangleIntersection: Vector3D, triangleNormal: Vector3D, triangle: Triangle) -> Bool {
        photon.position = triangleIntersection
        photon.rIntensity *= (1.0-triangle.rAbsorbance)
        photon.gIntensity *= (1.0-triangle.gAbsorbance)
        photon.bIntensity *= (1.0-triangle.bAbsorbance)
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
        if Double(arc4random())/Double(UINT32_MAX) < (1.0-triangle.diffuseReflectionProbability) {
            // FIXME store trianglenormal^2 in the triangle
            photon.direction = normalised(photon.direction - 2.0*(photon.direction*triangleNormal)*(triangleNormal))
            return true
        }
        // Diffuse reflection.
        // theta is the angle from the normal, phi the other angle needed to specify the direction
        let theta = asin(Double(arc4random())/Double(UINT32_MAX)) // [0, pi/2]
        let phi = 2.0*M_PI*Double(arc4random())/Double(UINT32_MAX) // [0, 2pi]
        // Pick a point in the triangle plane.
        let p = triangle.firstNode
        // Let zPlane be the normal to the and let xPlane and yPlane be two vectors in the triangle plane;
        // they form an orthonormal coordinate system.
        let zPlane = triangleNormal
        let xPlane = normalised(p - triangleIntersection)
        let yPlane = zPlane**xPlane
        let vec = Vector3D(x: sin(theta)*cos(phi), y: sin(theta)*sin(phi), z: cos(theta))
        photon.direction = normalised(vec.x*xPlane + vec.y*yPlane + vec.z*zPlane) // normalisation not needed?
        return false
    }
    
    func trace(room: Room, inout photon: Photon) -> Bool {
        while true {
            let (surfaceDistance, surfaceIntersection, surfaceNormal, surfaceTriangle) = self.findClosestIntersectedTriangle(room, photon: &photon, triangles: room.surfaces)
            let (lightsourceDistance, _, _, _) = self.findClosestIntersectedTriangle(room, photon: &photon, triangles: room.lightsources)
            let (sphereDistance, sphereIntersection, sphereNormal, sphere) = self.findClosestIntersectedSphere(room, photon: &photon)
            // I think this happens if a photon hits close to an edge.
            if surfaceDistance == Double.infinity && lightsourceDistance == Double.infinity && sphereDistance == Double.infinity {
                print("The photon escaped.")
                return false
            }
            if lightsourceDistance <= surfaceDistance && lightsourceDistance <= sphereDistance {
                return true
            } else if sphereDistance < surfaceDistance && sphereDistance < lightsourceDistance {
                let absorbed = self.photonIntersectionAtSphere(room, photon: &photon, sphereIntersection: sphereIntersection!, sphereNormal: sphereNormal!, sphere: sphere!)
                if absorbed {
                    return false
                }
            } else if surfaceDistance < sphereDistance && surfaceDistance < lightsourceDistance {
                let absorbed = self.photonIntersectionAtTriangle(room, photon: &photon, triangleIntersection: surfaceIntersection!, triangleNormal: surfaceNormal!, triangle: surfaceTriangle!)
                if absorbed {
                    return false
                }
            } else {
                fatalError()
            }
        }
    }
    
    func render() {
        self.renderAll()
        self.writeToFile()
        self.writeToPPMFile()
    }

    func renderAll() {
        let heightPoints = self.room.viewHeight*self.pixelsPerPoint
        let widthPoints = self.room.viewWidth*self.pixelsPerPoint
        for yIndex in 0..<heightPoints {
            dispatch_group_async(self.renderingGroup, self.renderingQueue) {
                for xIndex in 0..<widthPoints {
                    let x = Double(self.room.viewXMin) + Double(xIndex)/Double(self.pixelsPerPoint)
                    let y = Double(self.room.viewYMin) + Double(yIndex)/Double(self.pixelsPerPoint)
                    self.renderPixel(x: x, y: y, xIndex: xIndex, yIndex: yIndex)
                }
            }
        }
        dispatch_group_wait(self.renderingGroup, DISPATCH_TIME_FOREVER)
        dispatch_group_wait(self.writeToSelfGroup, DISPATCH_TIME_FOREVER)
    }
    
    func renderPixel(x x: Double, y: Double, xIndex: Int, yIndex: Int) {
        var r: Double = 0.0
        var g: Double = 0.0
        var b: Double = 0.0
        for _ in 0..<self.passesPerPixel {
            let yRandom = (Double(arc4random())/Double(UINT32_MAX) - 0.5)/Double(self.passesPerPixel)
            let xRandom = (Double(arc4random())/Double(UINT32_MAX) - 0.5)/Double(self.passesPerPixel)
            //let xRandom = self.xRandom[i] - 0.5
            //let yRandom = self.yRandom[i] - 0.5
            var photon = Photon(position: Vector3D(x: x, y: y, z: 800.0), direction: normalised(Vector3D(x: x+xRandom, y: y+yRandom, z: 800.0) - self.room.retina))
            let detected = self.trace(self.room, photon: &photon)
            if detected {
                r += photon.rIntensity
                g += photon.gIntensity
                b += photon.bIntensity
            }
        }
        r = r/Double(self.passesPerPixel)
        g = g/Double(self.passesPerPixel)
        b = b/Double(self.passesPerPixel)
        r = sqrt(2.0/(1.0+exp(-1.0*r/0.05))-1)
        g = sqrt(2.0/(1.0+exp(-1.0*g/0.05))-1)
        b = sqrt(2.0/(1.0+exp(-1.0*b/0.05))-1)
        self.pixelData[xIndex][yIndex].r = UInt8(255.0*r)
        self.pixelData[xIndex][yIndex].g = UInt8(255.0*g)
        self.pixelData[xIndex][yIndex].b = UInt8(255.0*b)
        // Don't add to many blocks to the serial queue; that'll eat memory.
        // Count the number of rendered rows instead of pixels.
        if xIndex == 0 {
            dispatch_group_async(self.writeToSelfGroup, self.writeToSelfQueue) {
                self.rowsRendered += 1
                let renderedPercent = (100*self.rowsRendered)/(self.room.viewHeight*self.pixelsPerPoint)
                if renderedPercent > self.renderedPercent {
                    self.renderedPercent = renderedPercent
                    print("Rendered \(self.renderedPercent) %.")
                }
            }
        }
    }
    
    func writeToPPMFile() {
        if let directory = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last {
            if directory.path != nil {
                let fileURL = directory.URLByAppendingPathComponent("image.ppm")
                if let filePath = fileURL.path {
                    NSFileManager.defaultManager().createFileAtPath(filePath, contents: nil, attributes: nil)
                    var string = "P3 \(self.room.viewWidth*self.pixelsPerPoint) \(self.room.viewHeight*self.pixelsPerPoint) 255\n"
                    for yIndex in 0..<self.room.viewHeight*self.pixelsPerPoint {
                        for xIndex in 0..<self.room.viewWidth*self.pixelsPerPoint {
                            let pixelDatum = self.pixelData[xIndex][self.room.viewHeight*self.pixelsPerPoint-1-yIndex]
                            string += "\(pixelDatum.r) \(pixelDatum.g) \(pixelDatum.b) "
                        }
                        string += "\n"
                    }
                    do {
                        try string.writeToFile(filePath, atomically: true, encoding: NSUTF8StringEncoding)
                    } catch {
                        
                    }
                }
            }
        }
    }
    
    func writeToFile() {
        var pixelDataOneDimensional = [PixelDatum]()
        for y in 0..<self.room.viewHeight*self.pixelsPerPoint {
            for x in 0..<self.room.viewWidth*self.pixelsPerPoint {
                pixelDataOneDimensional.append(self.pixelData[x][self.room.viewHeight*self.pixelsPerPoint-1-y])
            }
        }
        if let directory = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last {
            if directory.path != nil {
                let file = directory.URLByAppendingPathComponent("image.bmp")
                if let filePath = file.path {
                    NSFileManager.defaultManager().createFileAtPath(filePath, contents: nil, attributes: nil)
                    if let cgImageDestination = CGImageDestinationCreateWithURL(file, kUTTypeBMP, 1, nil) {
                        let providerRef = CGDataProviderCreateWithCFData(NSData(bytes: &pixelDataOneDimensional, length: pixelDataOneDimensional.count * sizeof(PixelDatum)))
                        if let cgImage = CGImageCreate(self.room.viewWidth*self.pixelsPerPoint, self.room.viewHeight*self.pixelsPerPoint, 8, 32, self.room.viewWidth*self.pixelsPerPoint*sizeof(PixelDatum), CGColorSpaceCreateDeviceRGB(), CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue), providerRef, nil, true, CGColorRenderingIntent.RenderingIntentDefault) {
                            CGImageDestinationAddImage(cgImageDestination, cgImage, nil)
                            CGImageDestinationFinalize(cgImageDestination)
                        }
                    }
                }
            }
        }
    }
}
