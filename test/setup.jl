using StaticArrayInterface, Static, LinearAlgebra, Test

struct MArray{T,N,R} <: DenseArray{T,N}
    parent::Array{T,N}
    indices::LinearIndices{N,R}
end

MArray(A::Array) = MArray(A, LinearIndices(map(s -> static(1):static(s), size(A))))
Base.parent(x::MArray) = x.parent
Base.IndexStyle(::Type{<:MArray}) = IndexLinear()
StaticArrayInterface.static_axes(x::MArray) = StaticArrayInterface.static_axes(x.indices)
Base.axes(x::MArray) = StaticArrayInterface.static_axes(x)
StaticArrayInterface.axes_types(T::Type{<:MArray}) = T.parameters[3]
StaticArrayInterface.static_axes(x::MArray) = StaticArrayInterface.static_axes(x.indices)
StaticArrayInterface.defines_strides(::Type{<:MArray}) = true
Base.strides(x::MArray) = strides(parent(x))
function Base.getindex(x::MArray, inds...)
    @boundscheck checkbounds(x, inds...)
    @inbounds parent(x)[inds...]
end

Base.size(x::MArray) = map(Int, StaticArrayInterface.static_size(x))
struct NamedDimsWrapper{D,T,N,P<:AbstractArray{T,N}} <: StaticArrayInterface.AbstractArray2{T,N}
    dimnames::D
    parent::P
    NamedDimsWrapper(d::D, p::P) where {D,P} = new{D,eltype(P),ndims(p),P}(d, p)
end
StaticArrayInterface.is_forwarding_wrapper(::Type{<:NamedDimsWrapper}) = true
Base.parent(x::NamedDimsWrapper) = getfield(x, :parent)
StaticArrayInterface.parent_type(::Type{T}) where {P,T<:NamedDimsWrapper{<:Any,<:Any,<:Any,P}} = P
StaticArrayInterface.dimnames(x::NamedDimsWrapper) = getfield(x, :dimnames)
function StaticArrayInterface.known_dimnames(::Type{T}) where {L,T<:NamedDimsWrapper{L}}
    Static.known(L)
end

Base.parent(x::NamedDimsWrapper) = x.parent

# Dummy array type with undetermined contiguity properties
struct DummyZeros{T,N} <: AbstractArray{T,N}
    dims :: Dims{N}
    DummyZeros{T}(dims...) where {T} = new{T,length(dims)}(dims)
end
DummyZeros(dims...) = DummyZeros{Float64}(dims...)
Base.size(x::DummyZeros) = x.dims
Base.getindex(::DummyZeros{T}, inds...) where {T} = zero(T)

struct Wrapper{T,N,P<:AbstractArray{T,N}} <: StaticArrayInterface.AbstractArray2{T,N}
    parent::P
end
StaticArrayInterface.parent_type(::Type{<:Wrapper{T,N,P}}) where {T,N,P} = P
Base.parent(x::Wrapper) = x.parent
StaticArrayInterface.is_forwarding_wrapper(::Type{<:Wrapper}) = true

struct DenseWrapper{T,N,P<:AbstractArray{T,N}} <: DenseArray{T,N} end
StaticArrayInterface.parent_type(::Type{DenseWrapper{T,N,P}}) where {T,N,P} = P
