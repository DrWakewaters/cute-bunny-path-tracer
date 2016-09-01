import Foundation
import CoreImage

class Renderer {
    var room: Room
    var pixelData: [[PixelDatum]]
    var renderingQueue: dispatch_queue_t
    var renderingGroup: dispatch_group_t
    var writeToSelfQueue: dispatch_queue_t
    var writeToSelfGroup: dispatch_group_t
    var passesPerPixel: Int = 2
    var rowsRendered: Int = 0
    var renderedPercent: Int = 0
    var pixelsPerPoint = 2
    var xRandom = [Double]()
    var yRandom = [Double]()
    
    init() {
        let (viewXMin, viewXMax, viewYMin, viewYMax) = (200, 800, 200, 800)
        let xRetina = (viewXMin + viewXMax)/2
        let yRetina = (viewYMin + viewYMax)/2
        var room = Room(retina: Vector3D(x: Double(xRetina), y: Double(yRetina), z: 1400.0), viewDirection: Vector3D(x: 0.0, y: 0.0, z: -1.0), viewXMin: viewXMin, viewXMax: viewXMax, viewYMin: viewYMin, viewYMax: viewYMax)
        let cornerNodes = [Vector3D(x: 0, y: 0, z: 0), Vector3D(x: 1000, y: 0, z: 0), Vector3D(x: 1000, y: 1000, z: 0), Vector3D(x: 0, y: 1000, z: 0), Vector3D(x: 0, y: 0, z: 1000), Vector3D(x: 1000, y: 0, z: 1000), Vector3D(x: 1000, y: 1000, z: 1000), Vector3D(x: 0, y: 1000, z: 1000)]
        let lightNodes = [Vector3D(x: 350, y: 1000, z: 350), Vector3D(x: 350, y: 1000, z: 650), Vector3D(x: 650, y: 1000, z: 650), Vector3D(x: 650, y: 1000, z: 350), Vector3D(x: 350, y: 1500, z: 350), Vector3D(x: 350, y: 1500, z: 650), Vector3D(x: 650, y: 1500, z: 650), Vector3D(x: 650, y: 1500, z: 350)]
        let extraNodes = [Vector3D(x: 350, y: 1000, z: 0), Vector3D(x: 350, y: 1000, z: 1000), Vector3D(x: 650, y: 1000, z: 1000), Vector3D(x: 650, y: 1000, z: 0)]
        let diffuseReflectionProbability = 0.92
        // the lightsource
        room.lightsources.append(Triangle(firstNode: lightNodes[4], secondNode: lightNodes[7], thirdNode: lightNodes[6], rAbsorbance: 0.0, gAbsorbance: 0.0, bAbsorbance: 0.0, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: true))
        room.lightsources.append(Triangle(firstNode: lightNodes[4], secondNode: lightNodes[6], thirdNode: lightNodes[5], rAbsorbance: 0.0, gAbsorbance: 0.0, bAbsorbance: 0.0, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: true))
        // xy-plane
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[1], thirdNode: cornerNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[2], thirdNode: cornerNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // xz-plane
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[4], thirdNode: cornerNodes[5], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[5], thirdNode: cornerNodes[1], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // yz-plane
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[3], thirdNode: cornerNodes[7], rAbsorbance: 0.05, gAbsorbance: 0.5, bAbsorbance: 0.5, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: cornerNodes[0], secondNode: cornerNodes[7], thirdNode: cornerNodes[4], rAbsorbance: 0.05, gAbsorbance: 0.5, bAbsorbance: 0.5, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // yz-plane with x=1000
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[2], thirdNode: cornerNodes[1], rAbsorbance: 0.5, gAbsorbance: 0.5, bAbsorbance: 0.05, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[1], thirdNode: cornerNodes[5], rAbsorbance: 0.5, gAbsorbance: 0.5, bAbsorbance: 0.05, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // xz-plane with y=1000; x > 650
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: extraNodes[2], thirdNode: extraNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: extraNodes[3], thirdNode: cornerNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // xz-plane with y=1000, x < 350
        room.surfaces.append(Triangle(firstNode: cornerNodes[7], secondNode: cornerNodes[3], thirdNode: extraNodes[0], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: cornerNodes[7], secondNode: extraNodes[0], thirdNode: extraNodes[1], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // xz-plane with y=1000, 350<x<650, 650<z<1000
        room.surfaces.append(Triangle(firstNode: extraNodes[1], secondNode: lightNodes[1], thirdNode: lightNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: extraNodes[1], secondNode: lightNodes[2], thirdNode: extraNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // xz-plane with y=1000, 350<x<650, 0<z<350
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: extraNodes[0], thirdNode: extraNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: extraNodes[3], thirdNode: lightNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // xy-plane with z=350, 350<x<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: lightNodes[3], thirdNode: lightNodes[7], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: lightNodes[0], secondNode: lightNodes[7], thirdNode: lightNodes[4], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // yz-plane with x=350, 350<z<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[1], thirdNode: lightNodes[0], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[0], thirdNode: lightNodes[4], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // xy-plane with z=650, 350<x<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[6], thirdNode: lightNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: lightNodes[5], secondNode: lightNodes[2], thirdNode: lightNodes[1], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // yz-plane with x=650, 350<z<650, 1000<y<1500
        room.surfaces.append(Triangle(firstNode: lightNodes[6], secondNode: lightNodes[7], thirdNode: lightNodes[3], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: lightNodes[6], secondNode: lightNodes[3], thirdNode: lightNodes[2], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // xy-plane with z=1000
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[5], thirdNode: cornerNodes[4], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        room.surfaces.append(Triangle(firstNode: cornerNodes[6], secondNode: cornerNodes[4], thirdNode: cornerNodes[7], rAbsorbance: 0.25, gAbsorbance: 0.25, bAbsorbance: 0.25, diffuseReflectionProbability: diffuseReflectionProbability, aLightsource: false))
        // a shpere made of glass
        room.spheres.append(Sphere(refractiveIndex: 2.0, radius: 200.0, position: Vector3D(x: 300.0, y: 400.0, z: 400.0), rAbsorbanceDuringReflection: 0.06, gAbsorbanceDuringReflection: 0.01, bAbsorbanceDuringReflection: 0.06, rAbsorbanceDuringTransmittancePerPoint: 0.00015, gAbsorbanceDuringTransmittancePerPoint: 0.000025, bAbsorbanceDuringTransmittancePerPoint: 0.00015, diffuseReflectionProbability: 0.01, isOpaque: false, aLightsource: false))
        // a small sphere made of glass
        room.spheres.append(Sphere(refractiveIndex: 4.0, radius: 50.0, position: Vector3D(x: 250.0, y: 150.0, z: 450.0), rAbsorbanceDuringReflection: 0.0, gAbsorbanceDuringReflection: 0.0, bAbsorbanceDuringReflection: 0.0, rAbsorbanceDuringTransmittancePerPoint: 0.0, gAbsorbanceDuringTransmittancePerPoint: 0.0, bAbsorbanceDuringTransmittancePerPoint: 0.0, diffuseReflectionProbability: 0.0, isOpaque: false, aLightsource: false))
        // a sphere made of gold
        room.spheres.append(Sphere(refractiveIndex: 1.0, radius: 200.0, position: Vector3D(x: 750.0, y: 300.0, z: 400.0), rAbsorbanceDuringReflection: 0.1, gAbsorbanceDuringReflection: 0.1, bAbsorbanceDuringReflection: 0.7, rAbsorbanceDuringTransmittancePerPoint: 0.0, gAbsorbanceDuringTransmittancePerPoint: 0.0, bAbsorbanceDuringTransmittancePerPoint: 0.0, diffuseReflectionProbability: 0.0, isOpaque: true, aLightsource: false))
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
    
    func findClosestIntersectedSphere(room: Room, photon: Photon) -> (intersectionDatum: IntersectionDatum, rayIntersectable: RayIntersectable)? {
        var closestDistance = Double.infinity
        var intersectionDatum: IntersectionDatum?
        var intersectionSphere: Sphere?
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
                intersectionDatum = IntersectionDatum(distance: closestDistance, intersection: d2*photon.direction + photon.position, normal: normalised(d2*photon.direction + photon.position - sphere.position))
                intersectionSphere = sphere
            } else if d1 > 1e-7 && d1 < closestDistance {
                closestDistance = d1
                intersectionDatum = IntersectionDatum(distance: closestDistance, intersection: d1*photon.direction + photon.position, normal: normalised(d1*photon.direction + photon.position - sphere.position))
                intersectionSphere = sphere
            }
        }
        if let intersectionDatum = intersectionDatum, let intersectionSphere = intersectionSphere  {
            return (intersectionDatum, intersectionSphere)
        }
        return nil
    }
 
    func findClosestIntersectedTriangle(room: Room, photon: Photon, triangles: [Triangle]) -> (intersectionDatum: IntersectionDatum, rayIntersectable: RayIntersectable)? {
        var closestDistance = Double.infinity
        var intersectionDatum: IntersectionDatum?
        var intersectionTriangle: Triangle?
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
                    intersectionDatum = IntersectionDatum(distance: closestDistance, intersection: d*photon.direction + photon.position, normal: triangle.normal)
                    intersectionTriangle = triangle
                }
            }
        }
        if let intersectionDatum = intersectionDatum, let intersectionTriangle = intersectionTriangle  {
            return (intersectionDatum, intersectionTriangle)
        }
        return nil
    }
    
    func findClosestIntersectedObject(room: Room, photon: Photon) -> (intersectionDatum: IntersectionDatum, rayIntersectable: RayIntersectable)? {
        var intersectionInformations = [(intersectionDatum: IntersectionDatum, rayIntersectable: RayIntersectable)]()
        let triangleInformation = self.findClosestIntersectedTriangle(room, photon: photon, triangles: room.surfaces)
        if let triangleInformation = triangleInformation {
            intersectionInformations.append(triangleInformation)
        }
        let sphereInformation = self.findClosestIntersectedSphere(room, photon: photon)
        if let sphereInformation = sphereInformation {
            intersectionInformations.append(sphereInformation)
        }
        let lightsourceInformation = self.findClosestIntersectedTriangle(room, photon: photon, triangles: room.lightsources)
        if let lightsourceInformation = lightsourceInformation {
            intersectionInformations.append(lightsourceInformation)
        }
        if intersectionInformations.count == 0 {
            return nil
        }
        var closestIntersectionInformation = intersectionInformations[0]
        for intersectionInformation in intersectionInformations {
            if intersectionInformation.intersectionDatum.distance < closestIntersectionInformation.intersectionDatum.distance {
                closestIntersectionInformation = intersectionInformation
            }
        }
        return closestIntersectionInformation
    }
    
    func trace(room: Room, inout photon: Photon?) {
        while photon != nil {
            let intersectionInformation = self.findClosestIntersectedObject(room, photon: photon!)
            if let intersectionInformation = intersectionInformation {
                if intersectionInformation.rayIntersectable.isALightsource() {
                    return
                }
                let photonAbsorbed = intersectionInformation.rayIntersectable.modifyPhoton(intersectionInformation.intersectionDatum, photon: &photon!)
                if photonAbsorbed {
                    photon = nil
                }
            } else {
                print("The photon escaped.")
                photon = nil
                return
            }
        }
    }

    func render() {
        print("Starting rendering.")
        self.renderAll()
        print("Finished rendering.")
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
            var photon: Photon? = Photon(position: Vector3D(x: x, y: y, z: 800.0), direction: normalised(Vector3D(x: x+xRandom, y: y+yRandom, z: 800.0) - self.room.retina))
            self.trace(self.room, photon: &photon)
            if let photon = photon {
                r += photon.rIntensity
                g += photon.gIntensity
                b += photon.bIntensity
            }
        }
        r = r/Double(self.passesPerPixel)
        g = g/Double(self.passesPerPixel)
        b = b/Double(self.passesPerPixel)
        r = sqrt(2.0/(1.0+exp(-1.0*r/0.04))-1)
        g = sqrt(2.0/(1.0+exp(-1.0*g/0.04))-1)
        b = sqrt(2.0/(1.0+exp(-1.0*b/0.04))-1)
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
