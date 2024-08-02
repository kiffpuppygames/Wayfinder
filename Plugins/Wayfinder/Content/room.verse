using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Colors }
using { /Verse.org/Random }
using { utils }
using { vector }
using { tile_mod }
using { grid_mod }

room_mod<public> := module
{
    Room<public> := class()
    {
        gridPosition<public>: Vector3Int    
        dimensions<public>: Vector3Int
        tiles<public>: []Tile

        getMinTilePosition(): Vector3Int =
            {
                var min_tile_pos : Vector3Int = vector3IntZero()
                for (i: int = 0..tiles.Length - 1)
                {
                    if (tile := tiles[i])
                    {
                        set min_tile_pos = vector3IntMin(min_tile_pos, tile.gridPosition)
                    }
                }
        
                return min_tile_pos
            }
        
        getMaxTilePosition(): Vector3Int =
        {
            var max_tile_pos : Vector3Int = vector3IntZero()
            for (i: int = 0..tiles.Length - 1)
            {
                if (tile := tiles[i])
                {
                    set max_tile_pos = vector3IntMax(max_tile_pos, tile.gridPosition)
                }
            }
    
            return max_tile_pos
        }

        resolveOverlap<public>(other: Room, minDistancePadding: int, minGridDistanceBetweenRooms: int): Room =
        {
            Print("Current Room Pos {gridPosition.toString()}", ?Duration:=6.0)  
            Print("Current Room Dimensions {dimensions.toString()}", ?Duration:=6.0)
            
            Print("Other Room Pos {other.gridPosition.toString()}", ?Duration:=6.0)
            Print("Other Room Dimensions {dimensions.toString()}", ?Duration:=6.0)

            var overlap_x: float = 0.0
            var overlap_y: float = 0.0
    
            half_width1 := toFloat(dimensions.x) / 2.0
            half_width2 := toFloat(other.dimensions.x) / 2.0
            half_breadth1 := toFloat(dimensions.y) / 2.0
            half_breadth2 := toFloat(other.dimensions.y) / 2.0
    
            var r1_to_r2 :Vector3Int= other.gridPosition.sub(gridPosition)
            Print("Vector to Other Room {r1_to_r2.toString()}", ?Duration:=6.0)
            if ( Print("Direction to Other Room {r1_to_r2.toVector3().MakeUnitVector[]}", ?Duration:=6.0) ) {}
            var distance :float = gridPosition.distanceTo(other.gridPosition)
            Print("Distance to Other Room {distance}", ?Duration:=6.0) 
    
            if (distance <= 0.0001)
            {            
                set r1_to_r2 = vector3Int(GetRandomInt(-1, 1), GetRandomInt(-1, 1), GetRandomInt(-1, 1))
                Print("Generated Dir {r1_to_r2.toString()}", ?Duration:=6.0)
                set distance = r1_to_r2.length()
            }
    
            # Get the minimum required distance from center of room 1
            if ( min_dist :int = Int[Sqrt(Pow(half_width1 + half_width2, 2.0) + Pow(half_breadth1 + half_breadth2, 2.0))] + minDistancePadding )
            {
                Print("Min Distance {min_dist}", ?Duration:=6.0)
                f_min_dist := toFloat(min_dist)
                if (distance < f_min_dist)
                {   
                    if ( dir_to_r2 : vector3 = r1_to_r2.toVector3().MakeUnitVector[] )
                    {                        
                        direction := directionToGridDirection(dir_to_r2)
                        Print("Dir to Other Room {direction.toString()}", ?Duration:=6.0)

                        new_pos := direction.mul(min_dist)
                        Print("New Room Pos {new_pos.toString()}", ?Duration:=6.0)

                        var new_room: Room = other
        
                        set new_room = Room { 
                                gridPosition := new_pos, 
                                dimensions := new_room.dimensions, 
                                tiles := new_room.tiles }
        
                        return new_room
                    }
                }
            }
            
            return Room { gridPosition := vector3IntZero(), dimensions := vector3IntZero(), tiles := array {} }
        }
    }

    roomsIntersect<public>( room1: Room, room2: Room): int =
    {
        room1_min_tile_pos := room1.getMinTilePosition()
        room1_max_tile_pos := room1.getMaxTilePosition()

        room2_min_tile_pos := room2.getMinTilePosition()
        room2_max_tile_pos := room2.getMaxTilePosition()

        x_overlap :int = if ( room1_min_tile_pos.x <= room2_max_tile_pos.x and room1_max_tile_pos.x >= room2_min_tile_pos.x ) { 1 } else { -1 }
        y_overlap :int = if (room1_min_tile_pos.y <= room2_max_tile_pos.y and room1_max_tile_pos.y >= room2_min_tile_pos.y) { 1 } else { -1 }
        
        if (x_overlap = 1 and y_overlap = 1)
        {
            return 1
        }

        return -1
    }

    compareRoomPositions<public>(r1: Room, r2: Room)<transacts><decides>: Room =
    {
        var selected :Room = r1
        if (r1.gridPosition.x <= r2.gridPosition.x and r1.gridPosition.y <= r2.gridPosition.y)
        {
            set selected = r2
        }            
        else
        {
            Print("Error Comparing Room Positions", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 })
            set selected = Room { gridPosition := vector3IntZero(), dimensions := vector3IntZero(), tiles := array {} }
        }

        return selected
    }

    generateRoom<public>(map_settings : MapSettings, grid: Grid, tile_info: TileInfo): Room =
    {
        room_dimensions := vector3Int(
            GetRandomInt(map_settings.minRoomWidth, map_settings.maxRoomWidth), 
            GetRandomInt(map_settings.minRoomBreadth, map_settings.maxRoomBreadth),
            0)        

        grid_position := grid.selectRandomCoord(room_dimensions)

        initial_tile_pos := room_dimensions.halfRoundUp().inverse()

        # 1D arrays are more performant as they are contiguous in memory
        total_tiles := room_dimensions.x * room_dimensions.y

        var tiles: []Tile = array {}

        var index_count :int= 0
        for (y: int = 0..room_dimensions.y - 1)
        {
            for (x: int = 0..room_dimensions.x - 1)
            {                      
                tile_pos := initial_tile_pos.add(vector3Int(x, y, 0))
                tile : Tile = Tile{ gridPosition := tile_pos, tileInfo := tile_info, tileObject := false }
                set tiles = tiles + array { tile }
            }
        }

        Room{ gridPosition := grid_position, dimensions := room_dimensions, tiles := tiles }
    }
}