import Foundation

struct Vector3D : CustomStringConvertible {
    var x: Double
    var y: Double
    var z: Double
    var description: String {
        return "(\(self.x), \(self.y), \(self.z))"
    }
}

func ==(left: Vector3D, right: Vector3D) -> Bool {
    return left.x == right.x && left.y == right.y && left.z == right.z
}

func +(left: Vector3D, right: Vector3D) -> Vector3D {
    return Vector3D(x: left.x+right.x, y: left.y+right.y, z: left.z+right.z)
}

func -(left: Vector3D, right: Vector3D) -> Vector3D {
    return Vector3D(x: left.x-right.x, y: left.y-right.y, z: left.z-right.z)
}

func *(left: Vector3D, right: Vector3D) -> Double {
    return left.x*right.x + left.y*right.y + left.z*right.z
}

func *(scalar: Double, vector: Vector3D) -> Vector3D {
    return Vector3D(x: scalar*vector.x, y: scalar*vector.y, z: scalar*vector.z)
}

func *(vector: Vector3D, scalar: Double) -> Vector3D {
    return Vector3D(x: scalar*vector.x, y: scalar*vector.y, z: scalar*vector.z)
}

infix operator** {
    associativity left
    precedence 150
}

func **(left: Vector3D, right: Vector3D) -> Vector3D {
    let x = left.y*right.z - left.z*right.y
    let y = left.z*right.x - left.x*right.z
    let z = left.x*right.y - left.y*right.x
    return Vector3D(x: x, y: y, z: z)
}

func /(vector: Vector3D, scalar: Double) -> Vector3D {
    return Vector3D(x: vector.x/scalar, y: vector.y/scalar, z: vector.z/scalar)
}

func square(vector: Vector3D) -> Double {
    return vector.x*vector.x + vector.y*vector.y + vector.z*vector.z
}

func norm(vector: Vector3D) -> Double {
    return sqrt(vector.x*vector.x + vector.y*vector.y + vector.z*vector.z)
}

func normalised(vector: Vector3D) -> Vector3D {
    return vector/norm(vector)
}

// the vectors must be normalised!
func angle(left: Vector3D, _ right: Vector3D) -> Double {
    return acos(left.x*right.x + left.y*right.y + left.z*right.z)
}
