function set_term_props!(graph::MetaGraphs.MetaDiGraph, term::Term, vertex_id::Int)::Bool
    set_props!(graph, vertex_id,
               Dict(:term => term,
                    :id => term.obo_id,
                    :label => term.label,
                    :type => :term))

    return true
end

function set_gene_props!(graph::MetaGraphs.MetaDiGraph, gene::String,
                         vertex_id::Int)::Bool
    return set_props!(graph, vertex_id,
                      Dict(:id => gene,
                           :type => :gene,
                           :expression => missing))
end

function is_term_in_graph(graph::MetaGraphs.MetaDiGraph, term::Term)
    try
        graph[term.obo_id, :id]
        return true
    catch
        return false
    end
end

function set_gene_props!(graph::MetaGraphs.MetaDiGraph, gene::Tuple{String,Float64},
                         vertex_id::Int)::Bool
    return set_props!(graph, vertex_id,
                      Dict(:id => gene[1],
                           :type => :gene,
                           :expression => gene[2]))
end
