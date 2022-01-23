function node(abaco::Context, sn, tag, parent)
    if parent !== ""
        container = abaco.node[parent]
        node(abaco, container, sn, tag)
    else
        node(abaco, sn, tag)
    end
end

function node(abaco::Context, sn, tag)
    # if tag is unknow then fallback to the default settings
    ##settings = get(abaco.cfg, tag, abaco.cfg[DEFAULT_TYPE])
    if abaco.interval == -1
        el = Node(sn, tag)
    else
        el = Node(sn, tag, abaco.ages)
    end

    if haskey(abaco.cfg, tag)
            for formula in values(abaco.cfg[tag].formula)
                for snap in values(el.snap)
                    snap.outputs[formula.output] = FormulaState(false, formula.output)
                end
            end
    end

    abaco.node[sn] = el
    el
end


function node(abaco::Context, target, sn, tag)
    elem = node(abaco, sn, tag)

    if haskey(abaco.origins, target.sn)
        push!(abaco.origins[target.sn], elem)
    else
        abaco.origins[target.sn] = Set([elem])
    end
    abaco.target[sn] = (tag, target.sn)
    return elem
end

function delete_node(abaco, sn)
    delete!(abaco.node, sn)
end
