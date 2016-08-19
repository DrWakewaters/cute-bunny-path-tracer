import Foundation

struct Triangle : CustomStringConvertible {
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
    var description: String {
        return "(\(self.firstNode), \(self.secondNode), \(self.thirdNode))"
    }

    init(firstNode: Vector3D, secondNode: Vector3D, thirdNode: Vector3D, rAbsorbance: Double, gAbsorbance: Double, bAbsorbance: Double, diffuseReflectionProbability: Double) {
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
    }
}
