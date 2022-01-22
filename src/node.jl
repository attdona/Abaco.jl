function node(abaco::Context, sn, domain, parent)
    if parent !== ""
        container = abaco.element[parent]
        node(abaco, container, sn, domain)
    else
        node(abaco, sn, domain)
    end
end

function node(abaco::Context, sn, domain)
    # if domain is unknow then fallback to the default settings
    ##settings = get(abaco.cfg, domain, abaco.cfg[DEFAULT_TYPE])
    if abaco.interval == -1
        el = Element(sn, domain)
    else
        el = Element(sn, domain, abaco.ages)
    end

    if haskey(abaco.cfg, domain)
            for formula in values(abaco.cfg[domain].formula)
                for snap in values(el.snap)
                    snap.outputs[formula.output] = FormulaState(false, formula.output)
                end
            end
    end

    abaco.element[sn] = el
    el
end


function node(abaco::Context, target, sn, domain)
    elem = node(abaco, sn, domain)

    if haskey(abaco.origins, target.sn)
        push!(abaco.origins[target.sn], elem)
    else
        abaco.origins[target.sn] = Set([elem])
    end
    abaco.target[sn] = (domain, target.sn)
    return elem
end

function delete_node(abaco, sn)
    delete!(abaco.element, sn)
end
