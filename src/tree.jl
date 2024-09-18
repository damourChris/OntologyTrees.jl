struct OntologyTree
    graph::MetaGraphs.MetaDiGraph
    base_term::Term
    required_terms::Vector{Term}
    max_parent_limit::Int
end

graph(onto_tree::OntologyTree) = onto_tree.graph
limit(onto_tree::OntologyTree)::Int = onto_tree.max_parent_limit
required_terms(onto_tree::OntologyTree)::Vector{Term} = onto_tree.required_terms
base(onto_tree::OntologyTree)::Term = onto_tree.root