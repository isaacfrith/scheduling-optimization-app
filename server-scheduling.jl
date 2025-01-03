
using JuMP
import HiGHS

import HTTP
import JSON


function endpoint_solve(params::Dict{String,Any})
    if !haskey(params, "lower_bound")
        return Dict{String,Any}(
            "status" => "failure",
            "reason" => "missing lower_bound param",
        )
    elseif !(params["lower_bound"] isa Real)
        return Dict{String,Any}(
            "status" => "failure",
            "reason" => "lower_bound is not a number",
        )
    end
    model = Model(HiGHS.Optimizer)
    set_silent(model)
    @variable(model, x >= params["lower_bound"], Int)
    optimize!(model)
    ret = Dict{String,Any}(
        "status" => "okay",
        "terminaton_status" => termination_status(model),
        "primal_status" => primal_status(model),
    )
    # Only include the `x` key if it has a value.
    if primal_status(model) == FEASIBLE_POINT
        ret["x"] = value(x)
    end
    return ret
end