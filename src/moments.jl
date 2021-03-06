##### Weighted var & std

## var
"""
    varm(x, w::AbstractWeights, m, [dim]; corrected=false)

Compute the variance of a real-valued array `x` with a known mean `m`, optionally
over a dimension `dim`. Observations in `x` are weighted using weight vector `w`.
The uncorrected (when `corrected=false`) sample variance is defined as:
```math
\\frac{1}{\\sum{w}} \\sum_{i=1}^n {w_i\\left({x_i - m}\\right)^2 }
```
where ``n`` is the length of the input. The unbiased estimate (when `corrected=true`) of
the population variance is computed by replacing
``\\frac{1}{\\sum{w}}`` with a factor dependent on the type of weights used:
* `AnalyticWeights`: ``\\frac{1}{\\sum w - \\sum {w^2} / \\sum w}``
* `FrequencyWeights`: ``\\frac{1}{\\sum{w} - 1}``
* `ProbabilityWeights`: ``\\frac{n}{(n - 1) \\sum w}`` where ``n`` equals `count(!iszero, w)`
* `Weights`: `ArgumentError` (bias correction not supported)
"""
Base.varm(v::RealArray, w::AbstractWeights, m::Real; corrected::DepBool=nothing) =
    _moment2(v, w, m; corrected=depcheck(:varm, corrected))

"""
    var(x, w::AbstractWeights, [dim]; mean=nothing, corrected=false)

Compute the variance of a real-valued array `x`, optionally over a dimension `dim`.
Observations in `x` are weighted using weight vector `w`.
The uncorrected (when `corrected=false`) sample variance is defined as:
```math
\\frac{1}{\\sum{w}} \\sum_{i=1}^n {w_i\\left({x_i - μ}\\right)^2 }
```
where ``n`` is the length of the input and ``μ`` is the mean.
The unbiased estimate (when `corrected=true`) of the population variance is computed by
replacing ``\\frac{1}{\\sum{w}}`` with a factor dependent on the type of weights used:
* `AnalyticWeights`: ``\\frac{1}{\\sum w - \\sum {w^2} / \\sum w}``
* `FrequencyWeights`: ``\\frac{1}{\\sum{w} - 1}``
* `ProbabilityWeights`: ``\\frac{n}{(n - 1) \\sum w}`` where ``n`` equals `count(!iszero, w)`
* `Weights`: `ArgumentError` (bias correction not supported)
"""
function Base.var(v::RealArray, w::AbstractWeights; mean=nothing,
                  corrected::DepBool=nothing)
    corrected = depcheck(:var, corrected)

    if mean == nothing
        varm(v, w, Base.mean(v, w); corrected=corrected)
    else
        varm(v, w, mean; corrected=corrected)
    end
end

## var along dim

function Base.varm!(R::AbstractArray, A::RealArray, w::AbstractWeights, M::RealArray,
                    dim::Int; corrected::DepBool=nothing)
    corrected = depcheck(:varm!, corrected)
    myscale!(_wsum_centralize!(R, abs2, A, values(w), M, dim, true),
             varcorrection(w, corrected))
end

function var!(R::AbstractArray, A::RealArray, w::AbstractWeights, dim::Int;
              mean=nothing, corrected::DepBool=nothing)
    corrected = depcheck(:var!, corrected)

    if mean == 0
        Base.varm!(R, A, w, Base.reducedim_initarray(A, dim, 0, eltype(R)), dim;
                   corrected=corrected)
    elseif mean == nothing
        Base.varm!(R, A, w, Base.mean(A, w, dim), dim; corrected=corrected)
    else
        # check size of mean
        for i = 1:ndims(A)
            dA = size(A,i)
            dM = size(mean,i)
            if i == dim
                dM == 1 || throw(DimensionMismatch("Incorrect size of mean."))
            else
                dM == dA || throw(DimensionMismatch("Incorrect size of mean."))
            end
        end
        Base.varm!(R, A, w, mean, dim; corrected=corrected)
    end
end

function Base.varm(A::RealArray, w::AbstractWeights, M::RealArray, dim::Int;
                   corrected::DepBool=nothing)
    corrected = depcheck(:varm, corrected)
    Base.varm!(similar(A, Float64, Base.reduced_indices(Compat.axes(A), dim)), A, w, M,
               dim; corrected=corrected)
end

function Base.var(A::RealArray, w::AbstractWeights, dim::Int; mean=nothing,
                  corrected::DepBool=nothing)
    corrected = depcheck(:var, corrected)
    var!(similar(A, Float64, Base.reduced_indices(Compat.axes(A), dim)), A, w, dim;
         mean=mean, corrected=corrected)
end

## std
"""
    stdm(v, w::AbstractWeights, m, [dim]; corrected=false)

Compute the standard deviation of a real-valued array `x` with a known mean `m`,
optionally over a dimension `dim`. Observations in `x` are weighted using weight vector `w`.
The uncorrected (when `corrected=false`) sample standard deviation is defined as:
```math
\\sqrt{\\frac{1}{\\sum{w}} \\sum_{i=1}^n {w_i\\left({x_i - m}\\right)^2 }}
```
where ``n`` is the length of the input. The unbiased estimate (when `corrected=true`) of the
population standard deviation is computed by replacing ``\\frac{1}{\\sum{w}}`` with a factor
dependent on the type of weights used:
* `AnalyticWeights`: ``\\frac{1}{\\sum w - \\sum {w^2} / \\sum w}``
* `FrequencyWeights`: ``\\frac{1}{\\sum{w} - 1}``
* `ProbabilityWeights`: ``\\frac{n}{(n - 1) \\sum w}`` where ``n`` equals `count(!iszero, w)`
* `Weights`: `ArgumentError` (bias correction not supported)
"""
Base.stdm(v::RealArray, w::AbstractWeights, m::Real; corrected::DepBool=nothing) =
    sqrt(varm(v, w, m, corrected=depcheck(:stdm, corrected)))

"""
    std(v, w::AbstractWeights, [dim]; mean=nothing, corrected=false)

Compute the standard deviation of a real-valued array `x`,
optionally over a dimension `dim`. Observations in `x` are weighted using weight vector `w`.
The uncorrected (when `corrected=false`) sample standard deviation is defined as:
```math
\\sqrt{\\frac{1}{\\sum{w}} \\sum_{i=1}^n {w_i\\left({x_i - μ}\\right)^2 }}
```
where ``n`` is the length of the input and ``μ`` is the mean.
The unbiased estimate (when `corrected=true`) of the population standard deviation is
computed by replacing ``\\frac{1}{\\sum{w}}`` with a factor dependent on the type of
weights used:
* `AnalyticWeights`: ``\\frac{1}{\\sum w - \\sum {w^2} / \\sum w}``
* `FrequencyWeights`: ``\\frac{1}{\\sum{w} - 1}``
* `ProbabilityWeights`: ``\\frac{n}{(n - 1) \\sum w}`` where ``n`` equals `count(!iszero, w)`
* `Weights`: `ArgumentError` (bias correction not supported)
"""
Base.std(v::RealArray, w::AbstractWeights; mean=nothing, corrected::DepBool=nothing) =
    sqrt.(var(v, w; mean=mean, corrected=depcheck(:std, corrected)))

Base.stdm(v::RealArray, m::RealArray, dim::Int; corrected::DepBool=nothing) =
    Base.sqrt!(Compat.varm(v, m, dims=dim, corrected=depcheck(:stdm, corrected)))

Base.stdm(v::RealArray, w::AbstractWeights, m::RealArray, dim::Int;
          corrected::DepBool=nothing) =
    sqrt.(varm(v, w, m, dim; corrected=depcheck(:stdm, corrected)))

Base.std(v::RealArray, w::AbstractWeights, dim::Int; mean=nothing,
         corrected::DepBool=nothing) =
    sqrt.(var(v, w, dim; mean=mean, corrected=depcheck(:std, corrected)))

##### Fused statistics
"""
    mean_and_var(x, [w::AbstractWeights], [dim]; corrected=false) -> (mean, var)

Return the mean and variance of a real-valued array `x`, optionally over a dimension
`dim`, as a tuple. Observations in `x` can be weighted using weight vector `w`.
Finally, bias correction is be applied to the variance calculation if `corrected=true`.
See [`var`](@ref) documentation for more details.
"""
function mean_and_var(A::RealArray; corrected::Bool=true)
    m = mean(A)
    v = varm(A, m; corrected=corrected)
    m, v
end

"""
    mean_and_std(x, [w::AbstractWeights], [dim]; corrected=false) -> (mean, std)

Return the mean and standard deviation of a real-valued array `x`, optionally
over a dimension `dim`, as a tuple. A weighting vector `w` can be specified
to weight the estimates. Finally, bias correction is applied to the
standard deviation calculation if `corrected=true`.
See [`std`](@ref) documentation for more details.
"""
function mean_and_std(A::RealArray; corrected::Bool=true)
    m = mean(A)
    s = stdm(A, m; corrected=corrected)
    m, s
end

function mean_and_var(A::RealArray, w::AbstractWeights; corrected::DepBool=nothing)
    m = mean(A, w)
    v = varm(A, w, m; corrected=depcheck(:mean_and_var, corrected))
    m, v
end
function mean_and_std(A::RealArray, w::AbstractWeights; corrected::DepBool=nothing)
    m = mean(A, w)
    s = stdm(A, w, m; corrected=depcheck(:mean_and_std, corrected))
    m, s
end


function mean_and_var(A::RealArray, dim::Int; corrected::Bool=true)
    m = Compat.mean(A, dims = dim)
    v = Compat.varm(A, m, dims = dim, corrected=corrected)
    m, v
end
function mean_and_std(A::RealArray, dim::Int; corrected::Bool=true)
    m = Compat.mean(A, dims = dim)
    s = stdm(A, m, dim; corrected=corrected)
    m, s
end


function mean_and_var(A::RealArray, w::AbstractWeights, dim::Int;
                      corrected::DepBool=nothing)
    m = mean(A, w, dim)
    v = varm(A, w, m, dim; corrected=depcheck(:mean_and_var, corrected))
    m, v
end
function mean_and_std(A::RealArray, w::AbstractWeights, dim::Int;
                      corrected::DepBool=nothing)
    m = mean(A, w, dim)
    s = stdm(A, w, m, dim; corrected=depcheck(:mean_and_std, corrected))
    m, s
end



##### General central moment
function _moment2(v::RealArray, m::Real; corrected=false)
    n = length(v)
    s = 0.0
    for i = 1:n
        @inbounds z = v[i] - m
        s += z * z
    end
    varcorrection(n, corrected) * s
end

function _moment2(v::RealArray, wv::AbstractWeights, m::Real; corrected=false)
    n = length(v)
    s = 0.0
    w = values(wv)
    for i = 1:n
        @inbounds z = v[i] - m
        @inbounds s += (z * z) * w[i]
    end

    varcorrection(wv, corrected) * s
end

function _moment3(v::RealArray, m::Real)
    n = length(v)
    s = 0.0
    for i = 1:n
        @inbounds z = v[i] - m
        s += z * z * z
    end
    s / n
end

function _moment3(v::RealArray, wv::AbstractWeights, m::Real)
    n = length(v)
    s = 0.0
    w = values(wv)
    for i = 1:n
        @inbounds z = v[i] - m
        @inbounds s += (z * z * z) * w[i]
    end
    s / sum(wv)
end

function _moment4(v::RealArray, m::Real)
    n = length(v)
    s = 0.0
    for i = 1:n
        @inbounds z = v[i] - m
        s += abs2(z * z)
    end
    s / n
end

function _moment4(v::RealArray, wv::AbstractWeights, m::Real)
    n = length(v)
    s = 0.0
    w = values(wv)
    for i = 1:n
        @inbounds z = v[i] - m
        @inbounds s += abs2(z * z) * w[i]
    end
    s / sum(wv)
end

function _momentk(v::RealArray, k::Int, m::Real)
    n = length(v)
    s = 0.0
    for i = 1:n
        @inbounds z = v[i] - m
        s += (z ^ k)
    end
    s / n
end

function _momentk(v::RealArray, k::Int, wv::AbstractWeights, m::Real)
    n = length(v)
    s = 0.0
    w = values(wv)
    for i = 1:n
        @inbounds z = v[i] - m
        @inbounds s += (z ^ k) * w[i]
    end
    s / sum(wv)
end


"""
    moment(v, k, [wv::AbstractWeights], m=mean(v))

Return the `k`th order central moment of a real-valued array `v`, optionally
specifying a weighting vector `wv` and a center `m`.
"""
function moment(v::RealArray, k::Int, m::Real)
    k == 2 ? _moment2(v, m) :
    k == 3 ? _moment3(v, m) :
    k == 4 ? _moment4(v, m) :
    _momentk(v, k, m)
end

function moment(v::RealArray, k::Int, wv::AbstractWeights, m::Real)
    k == 2 ? _moment2(v, wv, m) :
    k == 3 ? _moment3(v, wv, m) :
    k == 4 ? _moment4(v, wv, m) :
    _momentk(v, k, wv, m)
end

moment(v::RealArray, k::Int) = moment(v, k, mean(v))
function moment(v::RealArray, k::Int, wv::AbstractWeights)
    moment(v, k, wv, mean(v, wv))
end


##### Skewness and Kurtosis

# Skewness
# This is Type 1 definition according to Joanes and Gill (1998)
"""
    skewness(v, [wv::AbstractWeights], m=mean(v))

Compute the standardized skewness of a real-valued array `v`, optionally
specifying a weighting vector `wv` and a center `m`.
"""
function skewness(v::RealArray, m::Real)
    n = length(v)
    cm2 = 0.0   # empirical 2nd centered moment (variance)
    cm3 = 0.0   # empirical 3rd centered moment
    for i = 1:n
        @inbounds z = v[i] - m
        z2 = z * z

        cm2 += z2
        cm3 += z2 * z
    end
    cm3 /= n
    cm2 /= n
    return cm3 / sqrt(cm2 * cm2 * cm2)  # this is much faster than cm2^1.5
end

function skewness(v::RealArray, wv::AbstractWeights, m::Real)
    n = length(v)
    length(wv) == n || throw(DimensionMismatch("Inconsistent array lengths."))
    cm2 = 0.0   # empirical 2nd centered moment (variance)
    cm3 = 0.0   # empirical 3rd centered moment
    w = values(wv)

    @inbounds for i = 1:n
        x_i = v[i]
        w_i = w[i]
        z = x_i - m
        z2w = z * z * w_i
        cm2 += z2w
        cm3 += z2w * z
    end
    sw = sum(wv)
    cm3 /= sw
    cm2 /= sw
    return cm3 / sqrt(cm2 * cm2 * cm2)  # this is much faster than cm2^1.5
end

skewness(v::RealArray) = skewness(v, mean(v))
skewness(v::RealArray, wv::AbstractWeights) = skewness(v, wv, mean(v, wv))

# (excessive) Kurtosis
# This is Type 1 definition according to Joanes and Gill (1998)
"""
    kurtosis(v, [wv::AbstractWeights], m=mean(v))

Compute the excess kurtosis of a real-valued array `v`, optionally
specifying a weighting vector `wv` and a center `m`.
"""
function kurtosis(v::RealArray, m::Real)
    n = length(v)
    cm2 = 0.0  # empirical 2nd centered moment (variance)
    cm4 = 0.0  # empirical 4th centered moment
    for i = 1:n
        @inbounds z = v[i] - m
        z2 = z * z
        cm2 += z2
        cm4 += z2 * z2
    end
    cm4 /= n
    cm2 /= n
    return (cm4 / (cm2 * cm2)) - 3.0
end

function kurtosis(v::RealArray, wv::AbstractWeights, m::Real)
    n = length(v)
    length(wv) == n || throw(DimensionMismatch("Inconsistent array lengths."))
    cm2 = 0.0  # empirical 2nd centered moment (variance)
    cm4 = 0.0  # empirical 4th centered moment
    w = values(wv)

    @inbounds for i = 1 : n
        x_i = v[i]
        w_i = w[i]
        z = x_i - m
        z2 = z * z
        z2w = z2 * w_i
        cm2 += z2w
        cm4 += z2w * z2
    end
    sw = sum(wv)
    cm4 /= sw
    cm2 /= sw
    return (cm4 / (cm2 * cm2)) - 3.0
end

kurtosis(v::RealArray) = kurtosis(v, mean(v))
kurtosis(v::RealArray, wv::AbstractWeights) = kurtosis(v, wv, mean(v, wv))
