protocol RayIntersectable {
    func modifyPhoton(intersectionDatum: IntersectionDatum, inout photon: Photon) -> Bool
    func isALightsource() -> Bool
}
