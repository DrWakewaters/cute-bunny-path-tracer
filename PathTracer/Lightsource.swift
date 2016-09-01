struct Lightsource : RayIntersectable {
    var triangle: Triangle
    
    func modifyPhoton(intersectionDatum: IntersectionDatum, inout photon: Photon) -> Bool {
        photon.position = intersectionDatum.intersection
        return true
    }
    
    func isALightsource() -> Bool {
        return true
    }
}
