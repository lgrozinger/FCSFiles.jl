struct FlowSample{T<:Number, I<:AbstractVector{Int}}
    data::AxisArray{T, 2, Matrix{T}, Tuple{Axis{:param, Vector{String}}, Axis{:event, I}}}
    params::Dict{String, String}
end

const opt_params = [
("Machine", "\$CYT"),
("Begin Time", "\$BTIM"),
("End Time", "\$ETIM"),
("Date", "\$DATE"),
("File", "\$FIL"),
("Volume run", "\$VOL")
]


function Base.show(io::IO, f::FlowSample)
    spacing = " "^4
    print(io, typeof(f))

    for pair in opt_params
        if haskey(f.params, pair[2])
            print(io, "\n", spacing, "$(pair[1]): $(f.params[pair[2]])")
        end
    end
    print(io, "\n", spacing, "Axes:")
    n_params = parse(Int, f.params["\$PAR"])
    for i in 1:n_params
        print(io, "\n", spacing, spacing, "$(f.params["\$P$(i)N"])")
        if haskey(f.params, "\$P$(i)S")
            print(io, " ($(f.params["\$P$(i)N"]))")
        end
    end
end

function Base.getproperty(f::FlowSample, s::Symbol)
    if s == :params
        Base.depwarn("`flowrun.params` is deprecated and will be removed in a future release. Parameters can be accessed like any other member variable. E.g. `flowrun.par` or `flowrun.PAR`.", "flowrun.params")
    elseif s == :data
        Base.depwarn("`flowrun.data` is deprecated and will be removed in a future release. The data can be indexed, e.g. `flowrun[\"SSC-A\"]` or can be obtained as a matrix with `Array(flowrun)`.", "flowrun.data")
    end
    getfield(f, s)
end

Base.size(f::FlowSample) = size(getfield(f, :data))
Base.size(f::FlowSample, dim::Int) = size(f)[dim]
Base.length(f::FlowSample) = size(f, 1)

Base.keys(f::FlowSample) = getfield(f, :data).axes[1]
Base.haskey(f::FlowSample, x) = x in keys(f)
Base.values(f::FlowSample) = [getfield(f, :data)[key] for key in keys(f)]

Base.getindex(f::FlowSample, args...) = getindex(getfield(f, :data), args...)
Base.axes(f::FlowSample) = Base.axes(getfield(f, :data))
Base.axes(f::FlowSample, i::Int) = Base.axes(getfield(f, :data), i)

Base.iterate(iter::FlowSample) = iterate(getfield(iter, :data))
Base.iterate(iter::FlowSample, state) = iterate(getfield(iter, :data), state)
Base.Array(f::FlowSample) = Array(getfield(f, :data))
