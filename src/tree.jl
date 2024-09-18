struct OntologyTree
    graph::MetaGraphs.MetaDiGraph
    base_term::Term
    required_terms::Vector{Term}
    max_parent_limit::Int
end

