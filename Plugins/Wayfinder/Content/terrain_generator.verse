
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/SceneGraph }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { Utils }
using { SeedableRandom }
using { ArrayHelper }

# Create Intial Room at orign
# Choose random point within the map
# Generate a room at that point with random width and height within the map

GeneratorSettings := struct<concrete>:
    @editable
    DistanceMultiplier: float = 0.5
    # @editable
    # MinGridDistanceBetweenRooms: float = 9.0

MapSettingsData := struct<concrete>:
    @editable
    MapWidth: int = 10
    @editable
    MapBreadth: int = 10
    @editable
    MinRoomWidth: int = 1    
    @editable
    MaxRoomWidth: int = 2    
    @editable
    MinRoomBreadth: int = 1    
    @editable
    MaxRoomBreadth: int = 2  
    @editable
    MinNumRooms: int = 1    
    @editable
    MaxNumRooms: int = 2

Room := struct:
    grid_position: vector3    
    Width: int    
    Breadth: int    
    tiles: []Tile

Corridor := struct:
    Tiles: []Tile

Tile := struct:    
    relative_grid_position: vector3   
    tile_data: TileData
    tile_object: ?creative_prop

TileData := struct<concrete>:
    @editable
    Width: int = 1
    @editable
    Breadth: int = 1
    @editable
    model: mesh = Meshes.FloorTile

DungeonGenerator := class(creative_device):

    @editable
    DungeonGeneratorSettings<public>: GeneratorSettings = GeneratorSettings { DistanceMultiplier := 2.0 }

    @editable
    MapSettings<public>: MapSettingsData = MapSettingsData { MapWidth := 10, MapBreadth := 10, MinRoomWidth := 1, MaxRoomWidth := 2, MinNumRooms := 1, MaxNumRooms := 2 }

    @editable
    CorridorTileData<public> : TileData = TileData { Width := 1, Breadth := 1, model := Meshes.CorridorTile }

    @editable
    FloorTileData<public> : TileData = TileData { Width := 1, Breadth := 1 }

    var _rooms<private>: []Room = array {}
    var _corridors<private>: []Corridor = array {}

    RandomGenerator<private> :SeedableRandom.Murmur3Hash := SeedableRandom.Murmur3Hash {}

    OnBegin<override>()<suspends>:void= 
    {
        set _rooms = generateDungeon()          
        resolveOverlaps()
        set _corridors = generateCorridors()

        spawnDungeon()
    }

    OnEnd<override>() :void= 
    {
        for (r: int = 0.._rooms.Length)
        {
            if (room := _rooms[r])
            {
                set _rooms = array{}
            }
        }
    }

    generateCorridors(): []Corridor =
    {
        # Sort rooms by their X coordinate
        #sorted_rooms := _rooms.sort((a, b) => a.grid_position.X < b.grid_position.X)

        sorted_rooms := MergeSort(_rooms, CompareRoomPositions)
        Print("Rooms Sorted", ?Duration := 10.0, ?Color := color { R := 0.0, G := 1.0, B := 0.0 })
            
        corridors: []Corridor = for (i: int = 0..sorted_rooms.Length - 2)
        {
            if (room1 := sorted_rooms[i])
            {
                if (room2 := sorted_rooms[i + 1])
                {
                    createCorridor(room1, room2)
                }
                else
                {
                    Corridor{ Tiles := array {} }
                }
            }
            else
            {
                Corridor{ Tiles := array {} }
            }
        }

        corridors
    }

    createCorridor(room1: Room, room2: Room): Corridor =
    {
        var corridorTiles : []Tile = array {} 
        var end_x :float = 0.0

        # Create horizontal corridor
        if (room1.grid_position.X = room2.grid_position.X) {} else
        {
            var start_x :float = 0.0

            if (room1.grid_position.X < room2.grid_position.X)
            {
                set start_x = room1.grid_position.X
                set end_x = room2.grid_position.X

                for (x: int = Int[start_x]..Int[end_x])
                {
                    var tile_pos :vector3 = (vector3{X := toFloat(x), Y := room1.grid_position.Y - 2.0, Z := 0.0 })
                    tile : Tile = Tile{ relative_grid_position := tile_pos, tile_data := CorridorTileData, tile_object := false }
                    set corridorTiles = corridorTiles + array { tile }
                }
            }
            else if (room1.grid_position.X > room2.grid_position.X)
            {
                set start_x = room2.grid_position.X
                set end_x = room1.grid_position.X

                for (x: int = Int[start_x]..Int[end_x])
                {
                    var tile_pos :vector3 = (vector3{X := toFloat(x), Y := room2.grid_position.Y - 2.0, Z := 0.0 })
                    tile : Tile = Tile{ relative_grid_position := tile_pos, tile_data := CorridorTileData, tile_object := false }
                    set corridorTiles = corridorTiles + array { tile }
                }
            }
        }
    
        # Create vertical corridor
        if (room1.grid_position.Y = room2.grid_position.Y) {} else
        {
            var start_y :float = Min(room1.grid_position.Y, room2.grid_position.Y)
            var end_y :float = Max(room1.grid_position.Y, room2.grid_position.Y)

            if (room1.grid_position.Y < room2.grid_position.Y)
            {
                set start_y = room1.grid_position.Y + (toFloat(room1.Breadth) / 2.0)
                set end_y = room2.grid_position.Y - (toFloat(room2.Breadth) / 2.0)

                for (y: int = Int[start_y]..Int[end_y])
                {
                    var tile_pos :vector3 = (vector3{X := room1.grid_position.Y, Y := toFloat(y) , Z := 0.0 })
                    tile : Tile = Tile{ relative_grid_position := tile_pos, tile_data := CorridorTileData, tile_object := false }
                    set corridorTiles = corridorTiles + array { tile }
                }
            }
            else if (room1.grid_position.Y > room2.grid_position.Y)
            {
                set start_y = room2.grid_position.Y + (toFloat(room2.Breadth) / 2.0)
                set end_y = room1.grid_position.Y - (toFloat(room1.Breadth) / 2.0)

                for (y: int = Int[start_y]..Int[end_y])
                {
                    var tile_pos :vector3 = (vector3{X := room2.grid_position.Y, Y := toFloat(y) , Z := 0.0 })
                    tile : Tile = Tile{ relative_grid_position := tile_pos, tile_data := CorridorTileData, tile_object := false }
                    set corridorTiles = corridorTiles + array { tile }
                }
            }

            
        }

        Corridor{ Tiles := corridorTiles }
    }

    CompareRoomPositions(r1: Room, r2: Room)<transacts><decides>: Room =
    {
        var selected :Room = r1
        if (r1.grid_position.X <= r2.grid_position.X):
            set selected = r2
        else:
            Print("Error Comparing Room Positions", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 })
            set selected = Room { grid_position := vector3 { X := 0.0, Y := 0.0, Z := 0.0 }, Width := 0, Breadth := 0, tiles := array {} }

        return selected
    }
    
    resolveOverlaps(): void =
    {
        var hasOverlap :int= 1
        var loopCount :int= 0
        loopLimit :int = 1000
        loop
        {
            #set hasOverlap = -1
            for (i: int = 0.._rooms.Length - 1)
            {
                if (room1 := _rooms[i])
                {
                    for (j: int = i + 1.._rooms.Length - 1)
                    {                        
                        if (room2 := _rooms[j])
                        {
                            res := rectanglesIntersect(room1.grid_position, toFloat(room1.Width), toFloat(room1.Breadth), room2.grid_position, toFloat(room2.Width), toFloat(room2.Breadth));
                            if (res = 1):
                                new_room := resolveOverlap(room1, room2)
                                if ( set _rooms[j] = new_room ) {}
                                #set hasOverlap = 1
                        }
                    }
                }
            }

            set loopCount = loopCount + 1

            if (loopCount >= loopLimit):
                Print("Loop Limit Reached", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 })
                break

            # if (hasOverlap = -1):
            #     break
        }
        
        #Print("Overlapping Rooms Resolved", ?Duration := 10.0, ?Color := color { R := 0.0, G := 1.0, B := 0.0 })
    }

    resolveOverlap(room1: Room, room2: Room): Room =
    {
        room1_x := room1.grid_position.X
        room2_x := room2.grid_position.X

        room1_y := room1.grid_position.Y
        room2_y := room2.grid_position.Y

        var overlap_x: float = 0.0
        var overlap_y: float = 0.0

        half_width1 := toFloat(room1.Width) / 2.0
        half_width2 := toFloat(room2.Width) / 2.0
        half_breadth1 := toFloat(room1.Breadth) / 2.0
        half_breadth2 := toFloat(room2.Breadth) / 2.0

        var r1_to_r2 :vector3 = room2.grid_position - room1.grid_position
        var length :float = r1_to_r2.Length()

        if (length <= 0.0001)
        {            
            set r1_to_r2 = vector3 { X := GetRandomFloat(-1.0, 1.0), Y := GetRandomFloat(-1.0, 1.0), Z := GetRandomFloat(-1.0, 1.0) }
            Print("Generated Dir {r1_to_r2}", ?Duration:=6.0)
            set length = r1_to_r2.Length()
        }

        if ( min_dist :int = Int[(Sqrt(Pow(half_width1, 2.0) + Pow(half_breadth1, 2.0)) + Sqrt(Pow(half_width2, 2.0) + Pow(half_breadth2, 2.0))) * 1] + 8 )
        {
            f_min_dist := toFloat(min_dist)
            if (length < f_min_dist)
            {   
                if ( dir_to_r2 := r1_to_r2.MakeUnitVector[] )
                {
                    # if ( i_x := Int[dir_to_r2.X]) 
                    # {
                    #     if ( i_y := Int[dir_to_r2.Y] )
                    #     {
                            #int_translation := vector3 { X:= toFloat(i_x), Y:= toFloat(i_y), Z:= 0.0 }
                            #var new_grid_pos :vector3 = room1.grid_position + (dir_to_r2 * DungeonGeneratorSettings.MinGridDistanceBetweenRooms)
                            var new_grid_pos :vector3 = dir_to_r2 * 1.0

                            if ( i_x := Int[new_grid_pos.X] )
                            {
                                if ( i_y := Int[new_grid_pos.Y] )
                                {
                                    set new_grid_pos = vector3 { X:= toFloat(i_x), Y:= toFloat(i_y), Z:= 0.0 }
                                }

                                Print("New Room Pos {new_grid_pos}", ?Duration:=6.0)
                                var new_room: Room = room2

                                set new_room = Room { 
                                        grid_position := new_grid_pos, 
                                        Width := new_room.Width, 
                                        Breadth := new_room.Breadth,
                                        tiles := new_room.tiles }

                                return new_room
                            }
                    #     }
                    # }
                }
            }
            else
            {
                Print("Rooms are too far apart", ?Duration:=6.0)
            }
        }
        
        return Room { grid_position := vector3 { X := 0.0, Y := 0.0, Z := 0.0 }, Width := 0, Breadth := 0, tiles := array {} }
    }

    rectanglesIntersect( rect1_pos: vector3, rect1_width: float, rect1_breadth: float, rect2_pos: vector3, rect2_width: float, rect2_breadth: float): int =
    {
        rect1_left := rect1_pos.X
        rect1_right := rect1_pos.X + rect1_width
        rect1_top := rect1_pos.Y
        rect1_bottom := rect1_pos.Y + rect1_breadth

        rect2_left := rect2_pos.X
        rect2_right := rect2_pos.X + rect2_width
        rect2_top := rect2_pos.Y
        rect2_bottom := rect2_pos.Y + rect2_breadth

        if (rect1_left >= rect2_right or rect2_left >= rect1_right):
            return -1
        if (rect1_top >= rect2_bottom or rect2_top >= rect1_bottom):
            return -1

        return 1
    }

    generateDungeon(): []Room=
    {
        num_rooms := GetRandomInt(MapSettings.MinNumRooms, MapSettings.MaxNumRooms)

        rooms: []Room = for (i: int = 0..num_rooms - 1)
        {
            generateRoom()
        }
        rooms
    }

    generateRoom(): Room =
    {
        tiles_x :int = GetRandomInt(MapSettings.MinRoomWidth, MapSettings.MaxRoomWidth)
        tiles_x_f := toFloat(tiles_x)
        var room_min_pos_x: int = if ( res := Int[tiles_x_f / 2.0] ) { res } else { 0 } 

        tiles_y :int = GetRandomInt(MapSettings.MinRoomBreadth, MapSettings.MaxRoomBreadth)
        tiles_y_f := toFloat(tiles_y)
        var room_min_pos_y: int = if ( res := Int[tiles_y_f / 2.0] ) { res } else { 0 } 

        f_map_width := toFloat(MapSettings.MapWidth)
        f_map_breadth := toFloat(MapSettings.MapBreadth)
        room_position := selectRandomPointInRect(-f_map_width / 2.0 , f_map_width / 2.0, -f_map_breadth / 2.0, f_map_breadth / 2.0)
        Print("Initial Room Pos {room_position}", ?Duration:=6.0)

        var x_offset: int = 0
        if ( Mod[tiles_x, 2] = 0 ):
            # even number of tiles x
            set x_offset = if ( res:int = Int[tiles_x_f / 2.0] ) { res } else { 0 }
        else:
            # odd number of tiles x
            set x_offset = if ( res:int = Int[tiles_x_f / 2.0] ) { res + 1 } else { 0 }

        var y_offset: int = 0
        if ( Mod[tiles_y, 2] = 0 ):
            # even number of tiles y
            set y_offset = if ( res:= Int[tiles_y_f / 2.0] ) { res } else { 0 }
        else:
            # odd number of tiles y
            set y_offset = if ( res:= Int[tiles_y_f / 2.0] ) { res } else { 0 }

        intial_offset := vector3{X := toFloat(x_offset), Y := toFloat(y_offset), Z := 0.0}
        initial_tile_pos := room_position - intial_offset

        # 1D arrays are more performant as they are contiguous in memory
        total_tiles := tiles_x * tiles_y

        var tiles: []Tile = array {}

        var index_count :int= 0
        for (y: int = 0..tiles_y - 1)
        {
            for (x: int = 0..tiles_x - 1)
            {                      
                var tile_pos :vector3 = (vector3{X := toFloat(x), Y := toFloat(y), Z := 0.0})
                tile : Tile = Tile{ relative_grid_position := tile_pos, tile_data := FloorTileData, tile_object := false }
                set tiles = tiles + array { tile }
            }
        }

        Room{ grid_position := room_position, Width := tiles_x, Breadth := tiles_y, tiles := tiles }
    }

    selectRandomPointInRect(width_min: float, width_max: float, breadth_min: float, breadth_max: float): vector3 = 
    {
        if ( i_width_min := Int[width_min]) 
        {
            if ( i_width_max := Int[width_max]) 
            {
                if ( i_breadth_min := Int[breadth_min]) 
                {
                    if ( i_breadth_max := Int[breadth_max]) 
                    {
                        x := GetRandomInt(i_width_min, i_width_max)
                        y := GetRandomInt(i_breadth_min, i_breadth_max)
                        return vector3{X := toFloat(x), Y := toFloat(y), Z := 0.0}
                    }
                }
            }
        }
        
        return vector3{X := 0.0, Y := 0.0, Z := 0.0}
    }

    spawnDungeon(): void=
    {
        # Getting an infinite loop error(false-positive). I suspect its happening here as a result if unreals infinite loop detection. Usally avoidable in 
        # C++ code but not in Vertse Apparently. Code works as expected though.
        for (r: int = 0.._rooms.Length)
        {
            if (room := _rooms[r])
            {
                spawn_location := room.grid_position * vector3 { X:= toFloat(FloorTileData.Width), Y:= toFloat(FloorTileData.Breadth), Z := 0.0 };
                Print("Room {r} Spawn Location {spawn_location}", ?Duration:=6.0)
                for (t: int = 0..room.tiles.Length)
                {
                    if (tile := room.tiles[t])
                    {
                        tile_spawn_location := (room.grid_position + tile.relative_grid_position) * vector3 { X:= toFloat(FloorTileData.Width), Y:= toFloat(FloorTileData.Breadth), Z := 0.0 }
                        Print("Tile {t} Spawn Location {tile_spawn_location}", ?Duration:=6.0)
                        SpawnLocation := transform:
                            Translation := tile_spawn_location
                            Rotation := IdentityRotation()
                            Scale := vector3{X := 1.0, Y := 1.0, Z := 1.0}
                    
                        SpawnPropResult := SpawnProp(DefaultCreativePropAsset, SpawnLocation)
                    
                        if (SpawnedProp := SpawnPropResult(0)?):
                            SpawnedProp.SetMesh(tile.tile_data.model)

                        # Data Member instance access is not implemeted yet so we need to create a new tile struct
                        n_tile : Tile = Tile{ relative_grid_position := tile.relative_grid_position, tile_data := tile.tile_data, tile_object := SpawnPropResult(0) }

                        if ( room.tiles.ReplaceElement[t, n_tile] ) {}
                    }
                }

                if ( _rooms.ReplaceElement[r, room] ) {}
            }
        }

        for (c: int = 0.._corridors.Length - 1)
        {
            if (corridor := _corridors[c])
            {
                for (t: int = 0..corridor.Tiles.Length - 1)
                {
                    if (tile := corridor.Tiles[t])
                    {
                        tile_spawn_location := tile.relative_grid_position * vector3 { X:= toFloat(FloorTileData.Width), Y:= toFloat(FloorTileData.Breadth), Z := 0.0 }
                        Print("Corridor Tile {t} Spawn Location {tile_spawn_location}", ?Duration:=6.0)
                        SpawnLocation := transform:
                            Translation := tile_spawn_location
                            Rotation := IdentityRotation()
                            Scale := vector3{X := 1.0, Y := 1.0, Z := 1.0}
                    
                        SpawnPropResult := SpawnProp(DefaultCreativePropAsset, SpawnLocation)
                    
                        if (SpawnedProp := SpawnPropResult(0)?):
                            SpawnedProp.SetMesh(tile.tile_data.model)

                        # Data Member instance access is not implemeted yet so we need to create a new tile struct
                        n_tile : Tile = Tile{ relative_grid_position := tile.relative_grid_position, tile_data := tile.tile_data, tile_object := SpawnPropResult(0) }

                        if ( corridor.Tiles.ReplaceElement[t, n_tile] ) {}
                    }
                }

                if ( _corridors.ReplaceElement[c, corridor] ) {}
            }
        }
    }

    



    