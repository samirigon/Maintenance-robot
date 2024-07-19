function In(element,table)
    --returns true if element in table
    --returns false if otherwise

    for i,j in pairs(table) do
        if j == element then
            return true
        else
            return false
        end
    end
end

function Index(element,table)
    --returns the index of the element.
    if not In(element,table) then
        return nil
    end

    for i,j in pairs(table) do
        if j == element then
            return i
        end
    end
end

function Modulus(v)
    --given a vector, v, calculate its modulus
    local modulus = 0
    for i,j in pairs(v) do
        modulus = modulus + j*j
    end
    return modulus
end

function Size(t)
    --returns the size of the table t
    local count = 0
    for i,j in pairs(t) do
        count = count + 1
    end
    return count
end

function Vector_difference(v1,v2)
    --given two vectors, returns the difference
    if Size(v1) ~= Size(v2) then
        print(Size(v1),Size(v2))
        for i,j in v1 do
            print(i,j)
        end
        print(v2,":")
        for i,j in v2 do
            print(i,j)
        end
        error("Vectors must have the same size!")
    end
    local vector = {}
    for i=1,Size(v1) do
        table.insert(vector,i,v1[i]-v2[i])
    end

    return vector
end


function Reverse(t)
    for i = 1, Size(t)//2, 1 do
        t[i], t[Size(t)-i+1] = t[Size(t)-i+1], t[i]
    end
    return t
end

function Max(t)
    local max = t[1]
    for index,item in pairs(t) do
        if item > max then
            max = item
        end
    end
    return max
end

function Min(t)
    local min = t[1]
    for index,item in pairs(t) do
        if item > min then
            min = item
        end
    end
    return min
end