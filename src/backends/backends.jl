global current_context, make_current
function default_backend()
    if is_backend_supported(:cudanative)
        CUBackend
    elseif is_backend_supported(:opencl)
        CLBackend
    else
        JLBackend
    end
end
let compute_contexts = Context[]
    function current_context()
        if isempty(compute_contexts)
            default_backend().init()
        end
        last(compute_contexts)
    end
    all_contexts() = copy(compute_contexts)
    function make_current(ctx)
        idx = findfirst(compute_contexts, ctx)
        if idx != 0
            splice!(compute_contexts, idx) # remove
        end
        push!(compute_contexts, ctx)
    end
end
#interface
function create_buffer(ctx, array) end
"""
Blocks until all operations are finished on `A`
"""
function synchronize(A::AbstractArray)
    # fallback is a noop, for backends not needing synchronization. This
    # makes it easier to write generic code that also works for AbstractArrays
end
"""
`A` must be a gpu Array and will help to dispatch to the correct GPU backend
and can supply queues and contexts.
Calls `f` on args on the GPU, falls back to a normal call if there is no backend.
"""
function gpu_call(A::AbstractArray, f, args, worksize, localsize = nothing)
    f(args...)
end

function free(x::AbstractArray)

end

# BLAS support
hasblas(x) = false
include("blas.jl")
include("supported_backends.jl")
include("shared.jl")

function init(sym::Symbol, args...; kw_args...)
    if sym == :julia
        JLBackend.init(args...; kw_args...)
    elseif sym == :cudanative
        CUBackend.init(args...; kw_args...)
    elseif sym == :opencl
        CLBackend.init(args...; kw_args...)
    elseif sym == :opengl
        GLBackend.init(args...; kw_args...)
    else
        error("$sym not a supported backend. Try one of: $(supported_backends())")
    end
end


"""
Iterates through all backends and calls `f` after initializing the current one!
"""
function perbackend(f)
    for backend in supported_backends()
        ctx = GPUArrays.init(backend)
        f(backend)
    end
end
