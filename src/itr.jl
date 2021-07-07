struct BranchItr{T, J}
    f::ROOTFile
    b::Union{TBranch, TBranchElement}
    current::Int64
    total_entry::Int64

    function BranchItr(f::ROOTFile, b::Union{TBranch, TBranchElement})
        T = eltype(b)
        J = JaggType(only(b.fLeaves.elements))
        # we don't know how to deal with multiple leaves yet
        new{T, J}(f, b, 0, sum(b.fBasketEntry))
    end
end

function Base.show(io::IO, itr::BranchItr)
    summary(io, itr)
    println()
    println(io, "Branch: $(itr.b.fName)")
    print(io, "Total entry: $(itr.total_entry)")
end
Base.length(itr::BranchItr) = itr.total_entry
Base.eltype(itr::BranchItr{T,J}) where {T,J} = T


function Base.iterate(itr::BranchItr{T, J}, state=(itr.current, 1, T[], 0)) where {T,J}
    current, ithbasket, entries, remaining = state

    if current >= itr.total_entry
        return nothing
    end

    if iszero(remaining)
        rawdata, rawoffsets = readbasket(itr.f, itr.b, ithbasket)
        entries = interped_data(rawdata, rawoffsets, itr.b, J, T)
        remaining = length(entries)
        ithbasket += 1
    end
    return (pop!(entries), (current+1, ithbasket, entries, remaining-1))
end
