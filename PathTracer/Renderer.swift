import Foundation
import CoreImage

class Renderer {
    var room: Room
    var pixelData: [PixelData]
    var detectedPhotons: [[Photon]]
    var renderingQueue: dispatch_queue_t
    var renderingGroup: dispatch_group_t
    var writeToSelfQueue: dispatch_queue_t
    var writeToSelfGroup: dispatch_group_t
    var passesPerPixel: Int
    var pixelsRendered: Int = 0
    var renderedPercent: Int = 0
    
    init() {
        var room = Room(retina: Vector3D(x: 500.0, y: 500.0, z: 1400.0), viewDirection: Vector3D(x: 0.0, y: 0.0, z: -1.0), viewWidth: 600, viewHeight: 600)
        let cornerNodes = [Vector3D(x: 0, y: 0, z: 0), Vector3D(x: 1000, y: 0, z: 0), Vector3D(x: 1000, y: 1000, z: 0), Vector3D(x: 0, y: 1000, z: 0), Vector3D(x: 0, y: 0, z: 1000), Vector3D(x: 1000, y: 0, z: 1000), Vector3D(x: 1000, y: 1000, z: 1000), Vector3D(x: 0, y: 1000, z: 1000)]
        let lightNodes = [Vector3D(x: 350, y: 1000, z: 350), Vector3D(x: 350, y: 1000, z: 650), Vector3D(x: 650, y: 1000, z: 650), Vector3D(x: 650, y: 1000, z: 350), Vector3D(x: 350, y: 1500, z: 350), Vector3D(x: 350, y: 1500, z: 650), Vector3D(x: 650, y: 1500, z: 650), Vector3D(x: 650, y: 1500, z: 350)]
        let extraNodes = [Vector3D(x: 350, y: 1000, z: 0), Vector3D(x: 350, y: 1000, z: 1000), Vector3D(x: 650, y: 1000, z: 1000), Vector3D(x: 650, y: 1000, z: 0)]
        // the lightsource
        room.lightsources.append(Triangle(firstNode: lightNodes[4], secondNode: lightNodes[7], thirdNode: lightNodes[6], rAbsorbance: 0.0, gAbsorbance: 0.0, bAbsorbance: 0.0))
        room.lightsources.append(Triangle(firstNode: lightNodes[4], secondNode: lightNodes[6], thirdNode: lightNodes[5], rAbsorbance: 0.0, gAbsorbance: 0.0, bAbsorbance: 0.0))
        // xy-plane
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[1], thirdNode: cornerNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[2], thirdNode: cornerNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // xz-plane
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[4], thirdNode: cornerNodes[5], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[5], thirdNode: cornerNodes[1], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // yz-plane
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[3], thirdNode: cornerNodes[7], rAbsorbance: 0.05, gAbsorbance: 0.6, bAbsorbance: 0.6))
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[7], thirdNode: cornerNodes[4], rAbsorbance: 0.05, gAbsorbance: 0.6, bAbsorbance: 0.6))
        // yz-plane with x=1000
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[2], thirdNode: cornerNodes[1], rAbsorbance: 0.6, gAbsorbance: 0.6, bAbsorbance: 0.05))
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[1], thirdNode: cornerNodes[5], rAbsorbance: 0.6, gAbsorbance: 0.6, bAbsorbance: 0.05))
        // xz-plane with y=1000; x > 650
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: extraNodes[2], thirdNode: extraNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: extraNodes[3], thirdNode: cornerNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // xz-plane with y=1000, x < 350
        room.surfaces.append(Triangle(firstNode: cornerNodes[7], secondNode: cornerNodes[3], thirdNode: extraNodes[0], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: cornerNodes[7], secondNode: extraNodes[0], thirdNode: extraNodes[1], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // xz-plane with y=1000, 350<x<650, 650<z<1000
        room.surfaces.append(Triangle(firstNode: extraNodes[1], secondNode: lightNodes[1], thirdNode: lightNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: extraNodes[1], secondNode: lightNodes[2], thirdNode: extraNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // xz-plane with y=1000, 350<x<650, 0<z<350
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: extraNodes[0], thirdNode: extraNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: extraNodes[3], thirdNode: lightNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // xy-plane with z=350, 350<x<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: lightNodes[3], thirdNode: lightNodes[7], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: lightNodes[7], thirdNode: lightNodes[4], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // yz-plane with x=350, 350<z<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[1], thirdNode: lightNodes[0], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[0], thirdNode: lightNodes[4], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // xy-plane with z=650, 350<x<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[6], thirdNode: lightNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[2], thirdNode: lightNodes[1], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // yz-plane with x=650, 350<z<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[6], secondNode: lightNodes[7], thirdNode: lightNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: lightNodes[6], secondNode: lightNodes[3], thirdNode: lightNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // xy-plane with z=1000
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[5], thirdNode: cornerNodes[4], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[4], thirdNode: cornerNodes[7], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25))
        // a sphere
        room.spheres.append(Sphere(refractiveIndex: 2.0, radius: 200, position: Vector3D(x: 300.0, y: 400.0, z: 400.0), rAbsorbanceReflection: 0.3, gAbsorbanceReflection: 0.05, bAbsorbanceReflection: 0.3, rAbsorbanceTransmittancePerPixel: 0.0003, gAbsorbanceTransmittancePerPixel: 0.00005, bAbsorbanceTransmittancePerPixel: 0.0003, isOpaque: false))
        room.spheres.append(Sphere(refractiveIndex: 1.0, radius: 200, position: Vector3D(x: 750.0, y: 300.0, z: 400.0), rAbsorbanceReflection: 0.1, gAbsorbanceReflection: 0.1, bAbsorbanceReflection: 0.7, rAbsorbanceTransmittancePerPixel: 0.0, gAbsorbanceTransmittancePerPixel: 0.0, bAbsorbanceTransmittancePerPixel: 0.0, isOpaque: true))
        self.room = room
        self.pixelData = [PixelData](count: 600 * 600, repeatedValue: PixelData(a: 255, r: 0, g: 0, b: 0))
        self.detectedPhotons = [[Photon]](count: 600 * 600, repeatedValue: [Photon]())
        self.renderingQueue = dispatch_queue_create("renderingQueue", DISPATCH_QUEUE_CONCURRENT)
        self.renderingGroup = dispatch_group_create()
        self.writeToSelfQueue = dispatch_queue_create("writeToSelfQueue", DISPATCH_QUEUE_SERIAL)
        self.writeToSelfGroup = dispatch_group_create()
        self.passesPerPixel = 20000
    }
    
    // See http://graphics.stanford.edu/courses/cs148-10-summer/docs/2006--degreve--reflection_refraction.pdf
    func photonIntersectionAtSphere(room: Room, inout photon: Photon, sphereIntersection: Vector3D, sphereNormal: Vector3D, sphere: Sphere) -> Bool {
        // Russian roulette. There is a 50 % chance that a photon with very low intensity is removed. If not: increase its intensity.
        if photon.intensity < 0.02 {
            if Double(arc4random())/Double(UINT32_MAX) < 0.5 {
                return true
            } else {
                photon.rIntensity *= 2
                photon.gIntensity *= 2
                photon.bIntensity *= 2
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
        // 5 % chance of diffuse reflection if not opaque.
        let random = Double(arc4random())/Double(UINT32_MAX)
        if random < 0.05 && !sphere.isOpaque {
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
        // Mirror-like reflection.
        if sinThetaTSquared <= 1 {
            let cosThetaT = sqrt(1.0 - sinThetaTSquared*sinThetaTSquared)
            let rVerticalSqrt = (eta1*cosThetaI - eta2*cosThetaT)/(eta1*cosThetaI + eta2*cosThetaT)
            let rVertical = rVerticalSqrt*rVerticalSqrt
            let rHorizontalSqrt = (eta2*cosThetaI - eta1*cosThetaT)/(eta2*cosThetaI + eta1*cosThetaT)
            let rHorizontal = rHorizontalSqrt*rHorizontalSqrt
            let R = (rVertical + rHorizontal)/2.0
            let random = Double(arc4random())/Double(UINT32_MAX)
            if random <= R || sphere.isOpaque {
                //print("Reflection at sphere.")
                photon.direction = normalised(photon.direction - 2.0*(photon.direction*sphereNormal)*sphereNormal)
                photon.rIntensity *= (1.0-sphere.rAbsorbanceReflection)
                photon.gIntensity *= (1.0-sphere.gAbsorbanceReflection)
                photon.bIntensity *= (1.0-sphere.bAbsorbanceReflection)
            } else {
                //print("Transmission at sphere.")
                photon.direction = (etaQuotient*photon.direction) + (etaQuotient*cosThetaI-sqrt(1-sinThetaTSquared))*sphereNormal
                if isInsideSphere {
                    photon.rIntensity *= pow(1.0-sphere.rAbsorbanceTransmittancePerPixel, distance)
                    photon.gIntensity *= pow(1.0-sphere.gAbsorbanceTransmittancePerPixel, distance)
                    photon.bIntensity *= pow(1.0-sphere.bAbsorbanceTransmittancePerPixel, distance)
                }
            }
        } else {
            //print("Total internal reflection at sphere.")
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
            // 1e-6 rather than 0 to avoid intersecting twice; consider finding a better method
            if d2 > 1e-6 && d2 < closestDistance {
                closestDistance = d2
                closestSphere = sphere
                intersection = d2*photon.direction + photon.position
                normal = normalised(intersection! - sphere.position)
            } else if d1 > 1e-6 && d1 < closestDistance {
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
            if d > 1e-9 && d < closestDistance {
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
        // Russian roulette. There is a 50 % chance that a photon with very low intensity is removed. If not: increase its intensity.
        if photon.intensity < 0.02 {
            if Double(arc4random())/Double(UINT32_MAX) < 0.5 {
                return true
            } else {
                photon.rIntensity *= 2
                photon.gIntensity *= 2
                photon.bIntensity *= 2
            }
        }
        // 5 % chance of mirror-like reflection
        if Double(arc4random())/Double(UINT32_MAX) < 0.05 {
            // FIXME store trianglenormal^2 in the triangle
            photon.direction = normalised(photon.direction - 2.0*(photon.direction*triangleNormal)*(triangleNormal))
            return true
        }
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
            let (lightsourceDistance, lightsourceIntersection, lightsourceNormal, lightsourceTriangle) = self.findClosestIntersectedTriangle(room, photon: &photon, triangles: room.lightsources)
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
        //self.writePixelData(self.passesPerPixel)
        self.writeToFile()
    }
    
    func renderAll() {
        for i in 10..<40 {
            dispatch_group_async(self.renderingGroup, self.renderingQueue) {
                for y in 20*i..<20*(i+1) {
                    for x in 200..<800 {
                        self.renderPixel(x, y)
                    }
                }
            }
        }
        dispatch_group_wait(self.renderingGroup, DISPATCH_TIME_FOREVER)
        dispatch_group_wait(self.writeToSelfGroup, DISPATCH_TIME_FOREVER)
    }
    
    func renderPixel(x: Int, _ y: Int) {
        var photons = [Photon]()
        var detectedPhotons = [Photon]()
        var positions = [Position]()
        for _ in 0..<self.passesPerPixel {
            let yRandom = Double(arc4random())/Double(UINT32_MAX) - 0.5
            let xRandom = Double(arc4random())/Double(UINT32_MAX) - 0.5
            let photon = Photon(position: Vector3D(x: Double(x), y: Double(y), z: 800.0), direction: normalised(Vector3D(x: Double(x)+xRandom, y: Double(y)+yRandom, z: 800.0) - self.room.retina))
            photons.append(photon)
        }
        for i in 0..<self.passesPerPixel {
            var photon = photons[i]
            let detected = self.trace(self.room, photon: &photon)
            let (pixelX, pixelY) = (x-200, 599-(y-200)) // [0, 599], [0, 599]
            if detected {
                detectedPhotons.append(photon)
                positions.append(Position(x: pixelX, y: pixelY))
            }
        }
        dispatch_group_async(self.writeToSelfGroup, self.writeToSelfQueue) {
            /*for i in 0..<detectedPhotons.count {
                let (pixelX, pixelY) = (positions[i].x, positions[i].y)
                let photon = detectedPhotons[i]
                self.detectedPhotons[pixelY*600 + pixelX].append(photon)
            }*/
            let (pixelX, pixelY) = (x-200, 599-(y-200)) // test
            self.writeSingelPixelData(detectedPhotons, index: pixelY*600 + pixelX) // test
            self.pixelsRendered += 1
            let renderedPercent = (100*self.pixelsRendered)/(self.room.viewHeight*self.room.viewWidth)
            if renderedPercent > self.renderedPercent {
                self.renderedPercent = renderedPercent
                print("Rendered \(self.renderedPercent) %.")
            }
        }
    }
    
    func writeSingelPixelData(detectedPhotons: [Photon], index: Int) {
        var r: Double = 0.0
        var g: Double = 0.0
        var b: Double = 0.0
        for photon in detectedPhotons {
            r += photon.rIntensity
            g += photon.gIntensity
            b += photon.bIntensity
        }
        r = r/Double(passesPerPixel)
        g = g/Double(passesPerPixel)
        b = b/Double(passesPerPixel)
        r = sqrt(2.0/(1.0+exp(-1.0*r/0.05))-1)
        g = sqrt(2.0/(1.0+exp(-1.0*g/0.05))-1)
        b = sqrt(2.0/(1.0+exp(-1.0*b/0.05))-1)
        if r > 1.0 {
            r = 1.0
        }
        if g > 1.0 {
            g = 1.0
        }
        if b > 1.0 {
            b = 1.0
        }
        self.pixelData[index].r = UInt8(255.0*r)
        self.pixelData[index].g = UInt8(255.0*g)
        self.pixelData[index].b = UInt8(255.0*b)
    }
    
    func writePixelData(passesPerPixel: Int) {
        for i in 0..<self.pixelData.count {
            var r: Double = 0.0
            var g: Double = 0.0
            var b: Double = 0.0
            for photon in self.detectedPhotons[i] {
                r += photon.rIntensity
                g += photon.gIntensity
                b += photon.bIntensity
            }
            r = r/Double(passesPerPixel)
            g = g/Double(passesPerPixel)
            b = b/Double(passesPerPixel)
            r = sqrt(2.0/(1.0+exp(-1.0*r/0.05))-1)
            g = sqrt(2.0/(1.0+exp(-1.0*g/0.05))-1)
            b = sqrt(2.0/(1.0+exp(-1.0*b/0.05))-1)
            if r > 1.0 {
                r = 1.0
            }
            if g > 1.0 {
                g = 1.0
            }
            if b > 1.0 {
                b = 1.0
            }
            self.pixelData[i].r = UInt8(255.0*r)
            self.pixelData[i].g = UInt8(255.0*g)
            self.pixelData[i].b = UInt8(255.0*b)
        }
    }
    
    func writeToFile() {
        if let directory = NSFileManager.defaultManager().URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last {
            if directory.path != nil {
                let file = directory.URLByAppendingPathComponent("image.bmp")
                if let filePath = file.path {
                    NSFileManager.defaultManager().createFileAtPath(filePath, contents: nil, attributes: nil)
                    if let cgImageDestination = CGImageDestinationCreateWithURL(file, kUTTypeBMP, 1, nil) {
                        let providerRef = CGDataProviderCreateWithCFData(NSData(bytes: &pixelData, length: pixelData.count * sizeof(PixelData)))
                        if let cgImage = CGImageCreate(600, 600, 8, 32, 600 * sizeof(PixelData), CGColorSpaceCreateDeviceRGB(), CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue), providerRef, nil, true, CGColorRenderingIntent.RenderingIntentDefault) {
                            CGImageDestinationAddImage(cgImageDestination, cgImage, nil)
                            CGImageDestinationFinalize(cgImageDestination)
                        }
                    }
                }
            }
        }
    }
    
    func renderOLD() {
        for y in 200..<800 {
            print(y)
            for x in 200..<800 {
                for _ in 0..<self.passesPerPixel {
                    let yRandom = Double(arc4random())/Double(UINT32_MAX) - 0.5
                    let xRandom = Double(arc4random())/Double(UINT32_MAX) - 0.5
                    var photon = Photon(position: Vector3D(x: Double(x), y: Double(y), z: 800.0), direction: normalised(Vector3D(x: Double(x)+xRandom, y: Double(y)+yRandom, z: 800.0) - room.retina))
                    let detected = self.trace(room, photon: &photon)
                    let (pixelX, pixelY) = (x-200, 599-(y-200)) // [0, 599], [0, 599]
                    if detected {
                        self.detectedPhotons[pixelY*600 + pixelX].append(photon)
                    }
                }
            }
        }
        self.writePixelData(self.passesPerPixel)
        self.writeToFile()
    }
}
