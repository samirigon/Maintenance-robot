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

function Vector_difference(v1,v2)
    --given two vectors, returns the difference
    if v1.size ~= v2.size then
        error("Vectors must have the same size!")
    end
    local vector = table()
    for i=1,v1.size do
        table.insert(vector,i,v1[i]-v2[i])
    end

    return vector
end


function Reverse(tab)
    for i = 1, #tab//2, 1 do
        tab[i], tab[#tab-i+1] = tab[#tab-i+1], tab[i]
    end
    return tab
end