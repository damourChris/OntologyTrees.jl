struct OntologyTree
    graph::MetaGraphs.MetaDiGraph
    base_term::Term
    required_terms::Vector{Term}
    allow_multiple_roots::Bool
    max_parent_limit::Int
    include_UBERON::Bool
end

function OntologyTree(base_term::Term,
                      required_terms::Vector{Term}=[];
                      max_parent_limit::Int=5, allow_multiple_roots::Bool=false,
                      include_UBERON::Bool=false)
    graph = MetaDiGraph()

    # We can modify the indexing of the graph to be more efficient
    # Since every node is part of a ontology it will have an obo_id property
    # We can use this to index the nodes
    set_indexing_prop!(graph, :id)

    populate(graph, base_term, required_terms; include_UBERON, allow_multiple_roots)

    return OntologyTree(graph, base_term, required_terms, allow_multiple_roots,
                        max_parent_limit, include_UBERON)
end

# Custom display for the OntologyTree
import Base.show
function Base.show(io::IO, tree::OntologyTree)
    println(io, "OntologyTree with base term: $(tree.base_term.label)")
    println(io, "Number of required terms: $(length(tree.required_terms))")
    println(io, "Number of nodes: $(nv(tree.graph))")
    println(io, "Number of edges: $(ne(tree.graph))")
    return println(io, "Number of components: $(length(connected_components(tree.graph)))")
end

function populate(graph::MetaGraphs.MetaDiGraph, base_term::Term,
                  required_terms::Vector{Term};
                  include_UBERON::Bool=false,
                  allow_multiple_roots::Bool=false,
                  check_parent_limit::Int=5)::Nothing
    # Add the base term to the graph
    add_vertex!(graph)
    set_term_props!(graph, base_term, 1)

    for (index, term) in enumerate(required_terms)
        add_vertex!(graph)
        set_term_props!(graph, term, index + 1)
    end

    for (_, node) in enumerate(required_terms)
        populate_required_term(graph, node, base_term;
                               allow_multiple_roots=allow_multiple_roots,
                               check_parent_limit=check_parent_limit, include_UBERON)
    end
end

function get_terms_nodes_indices(graph::MetaGraphs.MetaDiGraph)::Vector{Int}
    return [v_index
            for (v_index, v_props) in graph.vprops
            if haskey(v_props, :term)]
end

function populate_required_term(graph::MetaGraphs.MetaDiGraph, term::Term, base_term::Term;
                                check_parent_limit::Int=5, allow_multiple_roots::Bool=false,
                                include_UBERON::Bool)::Nothing
    # While the parents list doesnt contain the base node, keep getting the hiercahical parents
    cur_node = term # Start with the current node

    @debug "Currently on node: $(cur_node.label)"
    return expand_graph!(graph, cur_node, base_term;
                         allow_multiple_roots=allow_multiple_roots,
                         check_parent_limit=check_parent_limit, include_UBERON)
end

function expand_graph!(graph, cur_node, base_term;
                       preferred_parents::Vector{Term}=[base_term],
                       allow_multiple_roots::Bool=false,
                       check_parent_limit::Int=5, include_UBERON::Bool)::Nothing
    if check_parent_limit == 0
        @warn "Parent limit reached. Stopping."
        return
    end
    if cur_node == base_term
        @debug "Reached base node: $(base_term.label). Stopping."
        return
    end

    cur_node_parents = get_hierarchical_parent(cur_node;
                                               return_unique_parent=!allow_multiple_roots,
                                               preferred_parent=preferred_parents,
                                               include_UBERON=include_UBERON)
    if (isa(cur_node_parents, AbstractArray) && length(cur_node_parents) == 0)
        @warn "No parents found for node: $(cur_node.label). Skipping."
        return
    end
    if (!isa(cur_node_parents, AbstractArray))
        cur_node_parents = [cur_node_parents]
    end

    cur_node_index = graph[cur_node.obo_id, :id]

    if ismissing(cur_node) || all(ismissing.(cur_node_parents))
        @warn "Error fetching parents for node: $cur_node. Skipping."
        return nothing
    end

    for parent in cur_node_parents
        if is_term_in_graph(graph, parent)
            @debug "Parent: $(parent.label) already in graph. Connecting. and stopping."
            existing_parent_index = graph[parent.obo_id, :id]

            @debug "Adding edge between $(cur_node.label) and $(parent.label)"
            add_edge!(graph, cur_node_index, existing_parent_index)
            continue
        end

        @debug "Adding parent: $(parent.label)"
        add_vertex!(graph)

        # Connect the parent to the current node
        cur_parent_index = nv(graph)
        @debug "Adding edge between $(cur_node.label) and $(parent.label)"

        add_edge!(graph, cur_node_index, cur_parent_index)

        set_term_props!(graph, parent, cur_parent_index)

        @debug "Expanding parent: $(parent.label)"
        expand_graph!(graph, parent, base_term;
                      include_UBERON=include_UBERON,
                      check_parent_limit=check_parent_limit - 1)
    end

    return nothing
end

graph(onto_tree::OntologyTree) = onto_tree.graph
limit(onto_tree::OntologyTree)::Int = onto_tree.max_parent_limit
required_terms(onto_tree::OntologyTree)::Vector{Term} = onto_tree.required_terms
base(onto_tree::OntologyTree)::Term = onto_tree.base_term