using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Assets }
using { vector }

tile_mod<public> := module
{
    TileType<public> := enum
    {
        NONE,
        FLOOR,
        WALL_EAST,
        WALL_WEST,        
        WALL_NORTH,
        WALL_SOUTH,
        CORNER_WALL_NORTH_EAST,
        CORNER_WALL_NORTH_WEST,
        CORNER_WALL_SOUTH_EAST,
        CORNER_WALL_SOUTH_WEST,
        DOOR,
        WINDOW
    }

    TileInfo<public> := struct<concrete>
    {
        @editable
        size<public>: vector3 = vector3 { X := 1.0, Y := 1.0, Z := 1.0 }
        @editable
        tileType<public>: TileType = TileType.NONE
    }

    Tile<public> := class()
    {   
        gridPosition<public>: Vector3Int   
        tileInfo<public>: TileInfo
        tileObject<public>: ?creative_prop
    }

    newTile<public>(gridPosition: Vector3Int, tileInfo: TileInfo, tileObject: ?creative_prop): Tile =
    {
        return Tile {
            gridPosition := gridPosition,
            tileInfo := tileInfo,
            tileObject := tileObject
        }
    }
    
    tileEmpty<public>()<transacts> :Tile =  
    {
        return Tile {
            gridPosition := Vector3Int { z := 0, y := 0, x := 0}, 
            tileInfo := TileInfo { size := vector3 { X := 1.0, Y := 1.0, Z := 1.0 }, tileType := TileType.NONE },
            tileObject := false
        }
    }
}