using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Colors }
using { utils }
using { vector }
using { tile_mod}
using { room_mod }

grid_mod<public> := module
{
    DEBUG :int = -1

    Grid<public> := class<concrete>
    {
        var values<public>: []Tile = array {}
        var dimensions<public>: Vector3Int = Vector3Int { x := 0, y := 0, z :=0 }

        init<public>(size: Vector3Int) : void =
        {
            set dimensions = size
            tile := tileEmpty()
            var data: []Tile = array {}
            for (i: int = 0..size.x * size.y - 1)
            {
                set data = data + array { tile }
            }
            set values = values + data
        }

        populate<public>(rooms: []Room, floorTileInfo: TileInfo): void =
        {
            var new_tiles: []Tile = values  
            for (grid_index :int = 0..new_tiles.Length - 1)
            {
                if ( blank_tile := values[grid_index] )
                {

                }
            }
             
            if (DEBUG = 1) { Print("Populating Grid", ?Duration := 6.0) }
            var current_grid_coord :Vector3Int = vector3IntZero()
    
            if (DEBUG = 1) { Print("Number of Rooms {rooms.Length}", ?Duration := 6.0) }
            for (r_index: int = 0..rooms.Length - 1)
            {
                for (t_index: int = 0..rooms[r_index].tiles.Length - 1)
                {                    
                    if ( room := rooms[r_index] )
                    {                        
                        for (i :int = 0..rooms[r_index].tiles.Length - 1)
                        {
                            if ( tile := rooms[r_index].tiles[i] )
                            {
                                t_grid_index :int = getIndex(tile.gridPosition.add(room.gridPosition))
                                #Print("Grid Pos {tile.gridPosition.toString()}", ?Duration := 6.0)
                                tile_pos := room.gridPosition.add(tile.gridPosition)
                                #Print("Tile Pos {tile_pos.toString()}", ?Duration := 6.0)

                                new_tile := newTile(tile_pos, TileInfo { size := vector3 { X := 100.0, Y := 100.0, Z := 1.0}, tileType := TileType.FLOOR }, tile.tileObject)      
                                    
                                if ( new_tiles.ReplaceElement[t_grid_index, new_tile] ) {} else 
                                { 
                                    if (DEBUG = 1) { Print("Error Populating Grid", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 }) }
                                }
                            }
                        }
                    }
                }
            }

            set values = new_tiles
        }
        
        getIndex(coord: Vector3Int)<transacts>: int =
        {
            return coord.x + coord.y * dimensions.x
        }
        
        getCoordinate(index: int)<transacts>: Vector3Int =
        {
            f_index := toFloat(index)
            f_grid_width := toFloat(dimensions.x)

            half_dimensions := dimensions.halfRoundUp().inverse()
    
            if ( x := Mod[index, dimensions.x] )
            {
                if ( y :int = Int[f_index / f_grid_width] )
                {
                    return vector3Int(half_dimensions.x + x, half_dimensions.y + y, 0)
                }
            }
            
            if (DEBUG = 1) { Print("Error Getting Grid Coordinates for {index}", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 }) }
            return vector3Int(0, 0, 0)
        }

        selectRandomCoord<public>(room_dimensions: Vector3Int): Vector3Int = 
        {
            half_room_dimensions := room_dimensions.halfRoundUp()
            half_map_dimensions := room_dimensions.halfRoundUp()
    
            min_bounds := half_map_dimensions.inverse().add(half_room_dimensions)
            max_bounds := half_map_dimensions.add(half_room_dimensions)
    
            return vector3Int(GetRandomInt(min_bounds.x, max_bounds.x), GetRandomInt(min_bounds.y, max_bounds.y), 0)
        }
    }
    
    getClosestGridCoord(position: vector3): Vector3Int =
    {
        if ( res := vector3Int(Int[position.X], Int[position.Y], 0) )
        {
            return res
        }
        
        if (DEBUG = 1) {  Print("Error Getting Closest Grid Coordinate for {position}", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 }) }
        return vector3Int(0, 0, 0)
    }

    directionToGridDirection<public>(direction: vector3): Vector3Int =
    {
        right := if ( direction.X > 0.0 ) { vector3Int(1, 0, 0) } else { vector3IntZero() }
        left := if ( direction.X < 0.0 ) { vector3Int(-1, 0, 0) } else { vector3IntZero() }
        up := if ( direction.Y > 0.0 ) { vector3Int(0, 1, 0) } else { vector3IntZero() }
        down :=if ( direction.Y < 0.0 ) {  vector3Int(0, -1, 0) } else { vector3IntZero() }
        return right.add(left).add(up).add(down)
    }
}