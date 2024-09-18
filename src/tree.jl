struct OntologyTree
    graph::MetaGraphs.MetaDiGraph
    base_term::Term
    required_terms::Vector{Term}
    max_parent_limit::Int
end

function OntologyTree(base_term::Term,
                      required_terms::Vector{Term}=[];
                      max_parent_limit::Int=5)
    graph = MetaDiGraph()

    # We can modify the indexing of the graph to be more efficient
    # Since every node is part of a ontology it will have an obo_id property
    # We can use this to index the nodes
    set_indexing_prop!(graph, :id)

    populate(graph, base_term, required_terms)

    return OntologyTree(graph, base_term, required_terms, max_parent_limit)
end

function populate(graph::MetaGraphs.MetaDiGraph, base_term::Term,
                  required_terms::Vector{Term},
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
                               check_parent_limit=check_parent_limit)
    end
end

function get_terms_nodes_indices(graph::MetaGraphs.MetaDiGraph)::Vector{Int}
    return [v_index
            for (v_index, v_props) in graph.vprops
            if haskey(v_props, :term)]
end

function populate_required_term(graph::MetaGraphs.MetaDiGraph, term::Term, base_term::Term;
                                check_parent_limit::Int=5)::Nothing
    # While the parents list doesnt contain the base node, keep getting the hiercahical parents
    cur_node = term # Start with the current node

    @debug "Currently on node: $(cur_node.label)"
    while check_parent_limit > 0
        if cur_node == base_term
            @info "Reached base node: $(base_term.label). Stopping."
            break
        end

        # We want to have a unified tree so the "preferred_parents" are all the terms
        # already present in the graph
        # Note that we might want to define an hierachy at some point to simplify this part
        vertice_with_term = get_terms_nodes_indices(graph)
        preferred_parents = [get_prop(graph, vertex, :term)
                             for vertex in vertice_with_term]

        cur_node_parent = get_hierarchical_parent(cur_node;
                                                  preferred_parent=preferred_parents,
                                                  include_UBERON=false)
        cur_node_index = graph[cur_node.obo_id, :id]

        if ismissing(cur_node) || ismissing(cur_node_parent)
            @warn "Error fetching parents for node: $cur_node. Skipping."
            break
        end

        # Check if the parent is already in the graph 
        if is_term_in_graph(graph, cur_node_parent)
            @debug "Parent: $(cur_node_parent.label) already in graph. Connecting. and stopping."
            existing_parent_index = graph[cur_node_parent.obo_id, :id]
            add_edge!(graph, cur_node_index, existing_parent_index)
            break
        end

        @debug "Adding parent: $(cur_node_parent.label)"
        add_vertex!(graph)

        # Connect the parent to the current node
        cur_parent_index = nv(graph)
        add_edge!(graph, cur_node_index, cur_parent_index)
        set_term_props!(graph, cur_node_parent, cur_parent_index)

        check_parent_limit -= 1
        cur_node = cur_node_parent
    end
end

graph(onto_tree::OntologyTree) = onto_tree.graph
limit(onto_tree::OntologyTree)::Int = onto_tree.max_parent_limit
required_terms(onto_tree::OntologyTree)::Vector{Term} = onto_tree.required_terms
base(onto_tree::OntologyTree)::Term = onto_tree.base_term