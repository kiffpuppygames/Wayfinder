
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/SceneGraph }
using { /Fortnite.com/Characters }
using { /Verse.org/Random }
using { /Verse.org/Assets }
using { /Verse.org/Colors }
using { utils }
using { array_helper }
using { seedable_random }
using { vector }
using { tile_mod }
using { room_mod }
using { grid_mod }

# Create Intial Room at orign
# Choose random point within the map
# Generate a room at that point with random width and height within the map

GeneratorSettings := struct<concrete>:
    @editable
    DistanceMultiplier: float = 0.5
    @editable
    minGridDistanceBetweenRooms: int = 9

MapSettings<public> := struct<concrete>:
    @editable
    mapDimensions<public>: Vector3Int = Vector3Int { x := 0, y := 0, z := 0 } 
    @editable
    minRoomWidth<public>: int = 1    
    @editable
    maxRoomWidth<public>: int = 2
    @editable
    minRoomBreadth<public>: int = 1    
    @editable
    maxRoomBreadth<public>: int = 2  
    @editable
    minNumRooms<public>: int = 1    
    @editable
    maxNumRooms<public>: int = 2
    @editable
    minDistancePadding<public>: int = 1

MapInfo := struct<concrete>:
    @editable
    mapDimensions: vector3 = vector3 { X := 0.0, Y := 0.0, Z := 0.0 }
    @editable
    maxVertex: vector3 = vector3 { X := 0.0, Y := 0.0, Z := 0.0 }
    @editable
    minVertex: vector3 = vector3 { X := 0.0, Y := 0.0, Z := 0.0 }

Corridor := struct:
    Tiles: []Tile

DungeonGenerator := class(creative_device):

    DEBUG :int = -1

    @editable
    generatorSettings<public>: GeneratorSettings = GeneratorSettings { DistanceMultiplier := 2.0 }

    @editable
    mapSettings<public>: MapSettings = MapSettings { 
        mapDimensions := Vector3Int { x := 10, y := 10, z := 0 },
        minRoomWidth := 1, 
        maxRoomWidth := 2, 
        minNumRooms := 1, 
        maxNumRooms := 2 
    }

    @editable
    corridorTileInfo<public> : TileInfo = TileInfo { size := vector3 { X:= 0.0, Y := 0.0, Z := 0.0 } }

    @editable
    floorTileInfo<public> : TileInfo = TileInfo { size := vector3 { X:= 0.0, Y := 0.0, Z := 0.0 } }
    
    var _grid<private>: Grid = Grid{ dimensions := Vector3Int { x := 0, y := 0, z := 0 }, values := array {} }    
    var _rooms<private>: []Room = array {}
    var _corridors<private>: []Corridor = array {}

    OnBegin<override>()<suspends>:void= 
    {
        if (DEBUG = 1) { Print("Generating Dungeon", ?Duration := 6.0) }

        _grid.init(vector3Int(mapSettings.mapDimensions.x, mapSettings.mapDimensions.y, 0))
        set _rooms = generateDungeon(mapSettings, _grid, floorTileInfo)          
        set _rooms = resolveOverlaps(_rooms, mapSettings.minDistancePadding)
        #set _corridors = generateCorridors()
        _grid.populate(_rooms, floorTileInfo)
        spawnDungeon(_grid, floorTileInfo)
    }

    OnEnd<override>() :void= 
    {
        set _rooms = array{}
    }

    # generateCorridors(): []Corridor =
    # {
    #     # Sort rooms by their X coordinate
    #     #sorted_rooms := _rooms.sort((a, b) => a.grid_position.X < b.grid_position.X)

    #     sorted_rooms := MergeSort(_rooms, compareRoomPositions)
    #     if (DEBUG = 1) { Print("Rooms Sorted", ?Duration := 10.0, ?Color := color { R := 0.0, G := 1.0, B := 0.0 }) }
            
    #     corridors: []Corridor = for (i: int = 0..sorted_rooms.Length - 2)
    #     {
    #         if (room1 := sorted_rooms[i])
    #         {
    #             if (room2 := sorted_rooms[i + 1])
    #             {
    #                 createCorridor(room1, room2)
    #             }
    #             else
    #             {
    #                 Corridor{ Tiles := array {} }
    #             }
    #         }
    #         else
    #         {
    #             Corridor{ Tiles := array {} }
    #         }
    #     }

    #     corridors
    # }

    createCorridor(room1: Room, room2: Room): Corridor =
    {
        var corridorTiles : []Tile = array {} 
        var end_x :int = 0

        # Create horizontal corridor
        if (room1.gridPosition.x = room2.gridPosition.x) {} else
        {
            var start_x :int = 0

            if (room1.gridPosition.x < room2.gridPosition.x)
            {
                set start_x = room1.gridPosition.x
                set end_x = room2.gridPosition.x

                for (x: int = start_x..end_x)
                {
                    var tile_pos : Vector3Int = vector3Int(x, room1.gridPosition.x - 2, 0)
                    t : Tile = Tile{ gridPosition := tile_pos, tileInfo := corridorTileInfo, tileObject := false }
                    set corridorTiles = corridorTiles + array { t }
                }
            }
            else if (room1.gridPosition.x > room2.gridPosition.x)
            {
                set start_x = room2.gridPosition.x
                set end_x = room1.gridPosition.x

                for (x: int = start_x..end_x)
                {
                    var tile_pos :Vector3Int = vector3Int(x, room2.gridPosition.y - 2, 0)
                    t : Tile = Tile{ gridPosition := tile_pos, tileInfo := corridorTileInfo, tileObject := false }
                    set corridorTiles = corridorTiles + array { t }
                }
            }
        }
    
        # Create vertical corridor
        if (room1.gridPosition.y = room2.gridPosition.y) {} else
        {
            r1_half_dimensions : Vector3Int = room1.dimensions.halfRoundUp()
            r2_half_dimensions : Vector3Int = room2.dimensions.halfRoundUp()

            var start_y :int = Min(room1.gridPosition.y, room2.gridPosition.y)
            var end_y :int = Max(room1.gridPosition.y, room2.gridPosition.y)
            var t: Tile = Tile { gridPosition := vector3Int(0, 0, 0), tileInfo := corridorTileInfo, tileObject := false }

            if (room1.gridPosition.y < room2.gridPosition.y)
            {
                set start_y = room1.gridPosition.y + r1_half_dimensions.y
                set end_y = room2.gridPosition.y - r1_half_dimensions.y

                for (y: int = start_y..end_y)
                {
                    set t = Tile{ gridPosition := vector3Int(room1.gridPosition.x, y, 0), tileInfo := corridorTileInfo, tileObject := false }
                    set corridorTiles = corridorTiles + array { t }
                }
            }
            else if (room1.gridPosition.y > room2.gridPosition.y)
            {
                set start_y = room2.gridPosition.y + r2_half_dimensions.y
                set end_y = room1.gridPosition.y - r2_half_dimensions.y

                for (y: int = start_y..end_y)
                {
                    set t = Tile{ gridPosition := vector3Int(room2.gridPosition.x, y, 0), tileInfo := corridorTileInfo, tileObject := false }
                    set corridorTiles = corridorTiles + array { t }
                }
            }
        }

        Corridor{ Tiles := corridorTiles }
    }
    
    resolveOverlaps(rooms: []Room, minDistancePadding: int): []Room =
    {
        var new_rooms: []Room = rooms
        if ( res := array { rooms[0] }) { set new_rooms = new_rooms + res }
        var loopCount :int= 0
        loopLimit :int = 1
        loop
        {
            if (DEBUG = 1) { Print("Evaluating Rooms {0} to {rooms.Length - 2}", ?Duration := 6.0) }
            for (i: int = 0..rooms.Length - 2)
            {
                if (room1 := rooms[i])
                {
                    if (DEBUG = 1) { Print("Evaluating Rooms {1} to {rooms.Length - 1}", ?Duration := 6.0) }
                    for (j: int = 1.._rooms.Length - 1)
                    {                        
                        if (room2 := rooms[j])
                        {
                            res := roomsIntersect(room1, room2);
                            if (res = 1)
                            {
                                var new_room :Room = room1.resolveOverlap(room2, minDistancePadding, generatorSettings.minGridDistanceBetweenRooms)
                                if ( new_rooms.ReplaceElement[j, new_room] ) {} else { if (DEBUG = 1) { Print("Failed to update room", ?Duration := 6.0) } }
                            }
                        }
                    }
                }
            }

            set loopCount = loopCount + 1

            if (loopCount >= loopLimit):
                if (DEBUG = 1) { Print("Loop Limit Reached", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 }) }
                break
        }

        return new_rooms
    }

    generateDungeon(map_settings : MapSettings, grid: Grid, tile_info: TileInfo): []Room=
    {
        num_rooms := GetRandomInt(map_settings.minNumRooms, map_settings.maxNumRooms)
        if (DEBUG = 1) { Print("Num Rooms {num_rooms}", ?Duration:=6.0) }

        rooms: []Room = for (i: int = 0..num_rooms - 1)
        {
            generateRoom(map_settings, _grid, tile_info)
        }
        rooms
    }

    spawnDungeon(grid: Grid, floor_tile_info: TileInfo): void=
    {
        # Getting an infinite loop error(false-positive). I suspect its happening here as a result if unreals infinite loop detection. Usally avoidable in 
        # C++ code but not in Verse Apparently. Code works as expected though. Will need to break up the loop into smaller parts
        Print("Grid Size {grid.values.Length}", ?Duration:=6.0)
        for (i: int = 0..grid.values.Length - 1)
        {
            if (tile := grid.values[i])
            {
                if (tile.tileInfo.tileType = TileType.NONE) 
                {
                    #Print("Tile Type is NONE", ?Duration := 6.0)
                } 
                else
                {
                    spawn_pos := tile.gridPosition.toVector3() * tile.tileInfo.size
                    Print("Spawning Tile at {spawn_pos}", ?Duration:=6.0)

                    SpawnLocation := transform:
                        Translation := spawn_pos
                        Rotation := IdentityRotation()
                        Scale := vector3{X := 1.0, Y := 1.0, Z := 1.0}
    
                    SpawnPropResult := SpawnProp(DefaultCreativePropAsset, SpawnLocation)
    
                    if (SpawnedProp := SpawnPropResult(0)?)
                    {
                        if (tile.tileInfo.tileType = TileType.FLOOR) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.WALL_EAST) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.WALL_WEST) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.WALL_NORTH) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.WALL_SOUTH) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.CORNER_WALL_NORTH_EAST) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.CORNER_WALL_NORTH_WEST) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.CORNER_WALL_SOUTH_EAST) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.CORNER_WALL_SOUTH_WEST) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.DOOR) { SpawnedProp.SetMesh(Meshes.FloorTile) }
                        else if (tile.tileInfo.tileType = TileType.WINDOW) { SpawnedProp.SetMesh(Meshes.FloorTile) }
    
                        # Data Member instance access is not implemeted yet so we need to create a new tile struct
                        var new_tile :Tile = Tile { gridPosition := tile.gridPosition, tileInfo := tile.tileInfo, tileObject := SpawnPropResult(0) }
    
                        if ( grid.values.ReplaceElement[i, new_tile] ) {}
                    }
                    else
                    {
                        Print("Error Spawning Tile", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 })
                    }
                }
            }
            else
            {
                if (DEBUG = 1) { Print("Error Getting tile at index {i}", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 }) }          
            }
        }

        if (DEBUG = 1) { Print("Dungeon Spawned", ?Duration:=6.0) }
    }

    getPlayerPosition<public>(grid : Grid): vector3=
    {
        if ( player_position := GetPlayspace().GetPlayers()[0].GetFortCharacter[].GetTransform().Translation )
        {
            return player_position
        }

        if (DEBUG = 1) { Print("Player Position Not Found", ?Duration := 10.0, ?Color := color { R := 1.0, G := 0.0, B := 0.0 }) }
        return vector3 { X := 0.0, Y := 0.0, Z := 0.0 }
    }