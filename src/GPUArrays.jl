__precompile__(true)
module GPUArrays

using IterTools, Sugar

abstract type Context end

include("abstractarray.jl")
export GPUArray, mapidx, linear_index, gpu_call
include("vectors.jl")


include(joinpath("backends", "backends.jl"))
export is_backend_supported, supported_backends


end # module
