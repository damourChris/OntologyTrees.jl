"""
    add_genes!(onto_tree::OntologyTree, genes::Vector{String})::Nothing

Add genes to the ontology tree graph.
"""
function add_genes!(onto_tree::OntologyTree, genes::Vector{String})::Nothing
    g = graph(onto_tree)
    cur_v_num = nv(onto_tree.graph)
    for (index, gene) in enumerate(genes)
        add_vertex!(g)
        set_gene_props!(onto_tree.graph, gene, cur_v_num + index)
    end

    return nothing
end

function add_genes!(onto_tree::OntologyTree, genes::Vector{Tuple{String,Float64}})::Nothing
    cur_v_num = nv(onto_tree.graph)
    for (index, gene) in enumerate(genes)
        add_vertex!(onto_tree.graph)
        set_gene_props!(onto_tree.graph, gene, cur_v_num + index)
    end

    return nothing
end

function connect_term_genes!(onto_tree::OntologyTree,
                             pairings::Dict{Term,Vector{String}})::Nothing
    for (term, genes) in pairings
        @info "Connecting genes to term: $(term.label)"

        for gene in genes
            term_gene_edge_added = connect_term_gene!(onto_tree.graph, term, gene)
            if !term_gene_edge_added
                @warn "Error connecting gene: $gene to term: $(term.label). Skipping."
            end
        end
    end
end

function connect_genes!(graph::MetaGraphs.MetaDiGraph, threshold::Float64=0.4)
    # Here we query the STRING db for the interactions between the genes
    # and add the edges to the graph
    genes_in_graph::Vector{String} = [get_prop(graph, v, :gene_id)
                                      for (v, d) in graph.vprops
                                      if haskey(d, :gene_id)]

    # Get the interactions between the genes
    interactions = get_interactions(genes_in_graph)

    # Add the interactions to the graph
    for (gene1, gene2, score) in interactions
        gene1_index = try
            graph[gene1, :id]
        catch
            missing
        end

        gene2_index = try
            graph[gene2, :id]
        catch
            missing
        end

        if ismissing(gene1_index) || ismissing(gene2_index)
            @warn "Error fetching gene indices for: $gene1 and $gene2. Skipping."
            continue
        end

        if score >= threshold
            add_edge!(graph, gene1_index, gene2_index)
        end
    end

    return interactions
end

function connect_term_gene!(graph::MetaGraphs.MetaDiGraph, term::Term, gene::String)::Bool
    term_index = try
        graph[term.obo_id, :id]
    catch
        missing
    end
    gene_index = try
        graph[gene, :id]
    catch
        missing
    end

    if ismissing(term_index) || ismissing(gene_index)
        @debug "Node: $(ismissing(term_index) ? term.label : gene) not found in graph. Skipping."
        return false
    end

    return add_edge!(graph, gene_index, term_index)
end
