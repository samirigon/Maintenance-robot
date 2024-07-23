--Requiere de unos valores globales para:
    --Facing = "east"
    --Relative_position = {x,y,z}

local robot = require("robot")
local fs = require("filesystem")
require("missing_functions")
PriorityQueue = require("PriorityQueue")


function Refill_robot()
    --si el robot tiene menos de x combustible
    --(calculado con la distancia a la base)
    --vuelve a la base
end

function TurnDirection(direction)
    if Directions_dictionary[direction] == nil and type(direction) ~= "number" then
        --la direccion que se ha metido es right o left
        --si no es ninguna de las dos manda un mensaje de error.
        if direction == "left" then
            if Facing ~= "east" then
                direction = Directions_dictionary[Facing]-1
            else
                direction = 4
            end
        elseif direction == "right" then
            if Facing ~= "north" then
                direction = Directions_dictionary[Facing]+1
            else
                direction = 1
            end
        else
            error("Must be right or left, any of the cardinal directions or a number from 1 to 4 representing them.")
        end
    end

    if type(direction) == "number" then
        direction = Directions[direction]
    end

    local actual_direction = Directions_dictionary[Facing]
    local final_direction= Directions_dictionary[direction]
    local number_of_turns = final_direction - actual_direction


    if number_of_turns == 3 then
        robot.turnLeft() --este --> norte
    elseif number_of_turns > 0 then
        while number_of_turns ~= 0 do
            robot.turnRight()
            number_of_turns = number_of_turns -1
        end
    else
        while number_of_turns ~= 0 do
            robot.turnLeft()
            number_of_turns = number_of_turns + 1
        end
    end

    Facing = Directions[final_direction]
end

function Move_forward(number_of_blocks)
    for i = 1,number_of_blocks do
        robot.forward()
        if Facing == "east" then
            Relative_position[1] = Relative_position[1] + 1
        elseif Facing == "west" then
            Relative_position[1] = Relative_position[1] - 1
        elseif Facing == "south " then
            Relative_position[3] = Relative_position[3] + 1
        elseif Facing == "north" then
            Relative_position[3] = Relative_position[3] - 1
        end
    end
end

function Calculate_closest_block(blocks)
    --given a list of blocks returns the closest one
    --to Relative_position
    local moduli = {}
    for i,block in pairs(blocks) do
        local modulus = Modulus(Vector_difference(block,Relative_position))
        table.insert(moduli,modulus)
    end

    local min = Min(moduli)
    local index = Index(min,moduli)

    return blocks[index]
end

function Travel_to(block)
    --travels to given block in a straight line

    local function go_to_relative_position(start_position,final_position)
        local previously_facing = Facing
        local x_difference = final_position[1] - start_position[1]
        if x_difference < 0 then
            TurnDirection("west")
            Move_forward(math.abs(x_difference))
        else
            TurnDirection("east")
            Move_forward(x_difference)
        end

        local y_difference = final_position[2] - start_position[2]
        if y_difference < 0 then
            while y_difference ~= 0 do
                y_difference = y_difference+1
            end
        else
            while y_difference ~= 0 do
                y_difference = y_difference - 1
            end
        end

        local z_difference = final_position[3] - start_position[3]
        if z_difference < 0 then
            TurnDirection("north")
            Move_forward(math.abs(z_difference))
        else
            TurnDirection("south") --para el eje z positivo
            Move_forward(z_difference)
        end
        TurnDirection(previously_facing)
    end

    go_to_relative_position(Relative_position,block)
end


function Calculate_path(pos,positions,walls)
    --given a mapped area calculates several points
    --to go from Relative_position to pos
    --and moves the robot.
    --uses A* Algorithm
    local path = {}
    local turn_cost = 1
    local move_cost = 1
    local frontier = PriorityQueue.new()
    frontier:enqueue(Relative_position, 0)
    local came_from = {}
    local cost_so_far = {}
    came_from[Relative_position] = nil
    cost_so_far[Relative_position] = 0

    local function heuristic(a, b)
        -- Manhattan distance on a square grid
        assert(type(a) == "table" or type(b) == "table", "Must be coordinates tables!")
        return math.abs(a[1] - b[1]) + math.abs(a[3] - b[3])
    end


    local function neighbours(valid_positions,pos)
        --returns the blocks that are neighbours

        local neighbors = {{pos[1]+1,pos[2],pos[3]},
        {pos[1]-1,pos[2],pos[3]},
        {pos[1],pos[2],pos[3]+1},
        {pos[1],pos[2],pos[3]-1}}

        for i,neighbour in pairs(neighbors) do
            if not In(neighbour,valid_positions) then
                local index = Index(neighbour,neighbors)
                table.remove(neighbors,index)
            end
        end

        return neighbors
    end

    local function cost(valid_positions,current,next)
        --returns the cost of the next movement
        local pointing
        if next == {current[1],current[2],current[3]-1} then
            --norte
            pointing = 4
        elseif next == {current[1],current[2],current[3]+1} then
            --sur
            pointing =2
        elseif next == {current[1]-1,current[2],current[3]} then
            --oeste
            pointing = 3
        elseif next == {current[1]+1,current[2],current[3]} then
            --este
            pointing = 1
        end
        if Directions_dictionary[Facing] == pointing then
            return move_cost
        else return move_cost+turn_cost
        end
    end

    local current
    local dummy
    while frontier:len() ~= 0 do
        current,dummy = frontier:dequeue()
        if current == pos then
             break
        end
    end

    for dummy,next in pairs(neighbours(positions,pos)) do
        local new_cost = cost_so_far[current] + cost(positions,current, next)
        if not In(next,cost_so_far) or new_cost < cost_so_far[next] then
            cost_so_far[next] = new_cost
            local priority = new_cost + heuristic(pos, next)
            frontier:enqueue(next, priority)
            came_from[next] = current
        end
    end

    path = Reverse(came_from)

    return path
end

function Map_area()
    --maps an area and saves it in memory in order to find the best path
    --to go from one point to another
    --uses extensive search
    local valid_positions = {}
    local missing_positions = {}
    local walls = {}
    local y = Relative_position[2]

    local function pos_in_front()
        local relative_position = table.shallow_copy(Relative_position)
        if Facing == "east" then
            relative_position[1] = relative_position[1] + 1
        elseif Facing == "west" then
            relative_position[1] = relative_position[1] - 1
        elseif Facing == "south" then
            relative_position[3] = relative_position[3] + 1
        elseif Facing == "north" then
            relative_position[3] = relative_position[3] - 1
        end
        return relative_position
    end


    local function add_wall()
        local relative_position = pos_in_front()
        if not In(relative_position,walls) then
            table.insert(walls,relative_position)
        end
    end

    local function add_safe()
        local relative_position = table.shallow_copy(Relative_position)
        if not In(relative_position,valid_positions) then
            table.insert(valid_positions,relative_position)
        end
        if In(relative_position,missing_positions) then
            local index = Index(relative_position,missing_positions)
            table.remove(missing_positions,index)
        end
    end

    local function add_missing()
        local relative_position = pos_in_front()
        if not In(relative_position,missing_positions) and not In(relative_position,valid_positions) then
            table.insert(missing_positions,relative_position)
        end
    end

    local function advance_till_wall()
        while not robot.detect() do
            for i=1,4 do
                TurnDirection("left")
                if robot.detect() then
                    add_wall()
                else
                    add_missing()
                end
            end
            Move_forward(1)
            add_safe()
        end
    end

    add_safe()
    advance_till_wall()
    print("no more going forward!")

    while Size(missing_positions) ~= 0 do
        local facing = Facing --registramos la dirección en la que mira.


        local maxomin
        local axis

        if facing == "east" then
            maxomin = Max
            axis = 1
        elseif facing == "west" then
            axis = 1
            maxomin = Min
        elseif facing == "north" then
            axis = 3
            maxomin = Min
        elseif facing == "south" then
            axis = 3
            maxomin = Max
        end

        Refill_robot()
        --queremos que el robot recorra todo el espacio de la base
        --desplazándose en un eje, x o z.
        --el eje va a ser hacia el que esté mirando cuando está en la base.


        local next_row = {} --aquí almacenaremos las casillas de la siguiente fila.

        --queremos añadir las posiciones de la siguiente fila a next_row
        local axis_values = {}
        --primero metemos todos los valores del eje
        for i,j in pairs(missing_positions) do
            table.insert(axis_values,j[axis])
        end
        --calculamos el valor del extremo
        local row_value = maxomin(axis_values)
        --y metemos todos los bloques que ha de recorrer en la lista.
        for i,j in pairs(missing_positions) do
            if j[axis] == row_value then
                table.insert(next_row,j)
            end
        end
        --ya tenemos los valores de los bloques en la fila que queremos recorrer.
        --ahora tenemos que decirle que vaya al extremo más cercano
        --y que se la recorra entera.
        --los extremos van a ser las posiciones que tengan mayor y menor
        --valor del otro eje.

        local otheraxis

        if axis == 1 then
            otheraxis = 3
        elseif axis == 3 then
            otheraxis = 1
        end

        local otheraxis_values = {}
        for i,j in pairs(next_row) do
            table.insert(otheraxis_values,j[otheraxis])
        end
        local column_values =  {}
        table.insert(column_values,Max(otheraxis_values))
        table.insert(column_values,Min(otheraxis_values))
        --calculo los extremos para ver cuál está más cerca
        local extremes = {}
        for i=1,2 do
            local extreme = {0,y,0}
            extreme[axis] = row_value
            extreme[otheraxis] = column_values[i]
            table.insert(extremes,extreme)
        end

        local position = Calculate_closest_block(extremes)
        local positions = TableConcat(valid_positions,missing_positions)
        local path = Calculate_path(position,positions,walls) --devuelve todas las
        --posiciones a las que hemos de ir para llegar al objetivo
        for dummy,block in pairs(path) do
            print(block[1],block[2],block[3])
            assert(In(block,positions),"Unknown block!")
            Travel_to(block)
        end
        
        Travel_to(position)
        --ya hemos viajado al primer bloque de la siguiente fila.
        --ya puede empezar el bucle de nuevo.

        print(position[1],position[2],position[3])
    end
end


Directions_dictionary = {["east"] = 1,["south"] = 2,["west"] = 3,["north"] = 4}
Directions = {"east", "south", "west", "north"}
Facing = "west"
Relative_position = {-8,69,-499}

Map_area()
