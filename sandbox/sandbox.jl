using Pkg
Pkg.activate(@__DIR__)

using OntologyLookup
using Graphs
using MetaGraphs

include("../src/OntologyTrees.jl")

base_term = onto_term("cl", "http://purl.obolibrary.org/obo/CL_0000000")
cell_types_terms_iris = ["http://purl.obolibrary.org/obo/CL_0009051"]

cell_types_terms = onto_term.("cl", cell_types_terms_iris)

new_tree = OntologyTrees.OntologyTree(base_term, cell_types_terms; max_parent_limit=50,
                                      include_UBERON=false)

new_tree.graph.graph