
function node(abaco::Context, ne, tag)
    # if tag is unknow then fallback to the default settings
    ##settings = get(abaco.cfg, tag, abaco.cfg[DEFAULT_TYPE])
    if abaco.interval == -1
        el = Node(ne, tag)
    else
        el = Node(ne, tag, abaco.ages)
    end

    if haskey(abaco.cfg, tag)
            for formula in values(abaco.cfg[tag].formula)
                for snap in values(el.snap)
                    snap.outputs[formula.output] = FormulaState(false, formula.output)
                end
            end
    end

    abaco.node[ne] = el
    el
end

function node(abaco::Context, ne::String, tag::String, parent::String)
    if parent !== ""
        container = abaco.node[parent]
        node(abaco, container, ne, tag)
    else
        node(abaco, ne, tag)
    end
end

function node(abaco::Context, target::Node, ne::String, tag::String)
    elem = node(abaco, ne, tag)

    if haskey(abaco.origins, target.ne)
        push!(abaco.origins[target.ne], elem)
    else
        abaco.origins[target.ne] = Set([elem])
    end
    abaco.target[ne] = (tag, target.ne)
    return elem
end

function delete_node(abaco, ne)
    delete!(abaco.node, ne)
end
