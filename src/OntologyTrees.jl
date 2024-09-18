module OntologyTrees

using Graphs
using MetaGraphs
using OntologyLookup
using STRINGdb
using TestItems

include("tree.jl")
export OntologyTree, graph, limit, required_terms, base

include("utils.jl")
export add_genes!, connect_term_genes!, connect_genes!, connect_term_gene!,
       connect_term_genes!

include("populate.jl")
export add_genes!, connect_term_genes!

end
