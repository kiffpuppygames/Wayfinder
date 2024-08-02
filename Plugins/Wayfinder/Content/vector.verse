using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { utils }


vector<public> := module
{
    Vector3Int<public> := class<concrete>()
    {
        @editable
        var x<public>: int = 0
        @editable
        var y<public>: int = 0
        @editable
        var z<public>: int = 0

        length<public>(): float =
        {
            return Sqrt(toFloat(x * x + y * y + z * z))
        }

        equals<public>(other: Vector3Int)<transacts>: int =
        {
            if ( x = other.x and y = other.y and z = other.z) { return 1 } else { return -1 }
        }

        normalize<public>(): Vector3Int =
        {
            len := length()
            vec := vector3 { X := toFloat(x) / len , Y := toFloat(y) / len, Z := toFloat(z) / len }
            if (res := vector3Int( Int[vec.X], Int[vec.Y], Int[vec.Z] ) )
            {
                return res
            }
            
            Print("Error: Vector3Int.normalize() failed to convert float to int")
            return vector3Int(0, 0, 0)
        }

        distanceTo<public>(other: Vector3Int)<transacts>: float =
        {
            return Sqrt(toFloat((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y) + (z - other.z) * (z - other.z)))
        }

        inverse<public>()<transacts>: Vector3Int =
        {
            return vector3Int(-x, -y, -z)
        }

        add<public>( other: Vector3Int): Vector3Int =
        {
            return vector3Int(x + other.x, y + other.y, z + other.z)
        }

        sub<public>( other: Vector3Int): Vector3Int =
        {
            return vector3Int(x - other.x, y - other.y, z - z)
        }

        mul<public>( other: Vector3Int): Vector3Int =
        {
            return vector3Int(x * other.x, y * other.y, z * z)
        }

        mul<public>( scalar: int): Vector3Int =
        {
            return vector3Int(x * scalar, y * scalar, z * scalar)
        }

        halfRoundUp<public>()<transacts>: Vector3Int =
        {
            half_x :int = if ( Mod[x, 2] > 0 )
            {
                if (res := Int[toFloat(x) / 2.0]) { res + 1 } else { -1 }
            }
            else
            {
                if (res := Int[toFloat(x) / 2.0]) { res } else { -1 }
            }
            
            half_y : int =  if ( Mod[y, 2] > 0 )
            {
                if (res := Int[toFloat(y) / 2.0]) { res + 1 } else { -1 }
            }
            else
            {
                if (res := Int[toFloat(y) / 2.0]) { res } else { -1 }
            }

            return vector3Int(half_x, half_y, 0)
        }

        toString<public>(): string =
        {
            return "Vector3Int({x}, {y}, {z})"
        }

        toVector3<public>()<transacts>: vector3 =
        {
            return vector3 { X := toFloat(x), Y := toFloat(y), Z := toFloat(z) }
        }
    }

    vector3Int<public>(x:int, y:int, z:int)<transacts>: Vector3Int =
    {
        return Vector3Int {  x := x, y := y, z := z }
    }

    vector3IntZero<public>()<transacts>: Vector3Int =
    {
        return Vector3Int {  x := 0, y := 0, z := 0 }
    }

    vector3IntMin<public>(a: Vector3Int, b: Vector3Int): Vector3Int =
    {
        return vector3Int( Min(a.x, b.x), Min(a.y, b.y), Min(a.z, b.z) )
    }

    vector3IntMax<public>(a: Vector3Int, b: Vector3Int): Vector3Int =
    {
        return vector3Int( Max(a.x, b.x), Max(a.y, b.y), Max(a.z, b.z) )
    }

    vector3zero<public>(): vector3 =
    {
        return vector3 { X := 0.0, Y := 0.0, Z := 0.0 }
    }

    vector3IntfromVector3<public>(vec: vector3): Vector3Int =
    {
        if ( grid_pos := vector3Int( Int[vec.X], Int[vec.Y], Int[vec.Z] ) )
        {
            return grid_pos
        }

        Print("Error: fromVector3 failed to convert float to int")
        return vector3IntZero()
    }
}