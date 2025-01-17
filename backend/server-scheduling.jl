
using JuMP
import HiGHS
using Random
import HTTP
import JSON
using SCIP, HiGHS



# params = Dict(
#     "num_midwives" => 30,
#     "num_days" => 30,
#     "min_midwives_per_shift" => 3,
#     "min_supervisors_per_shift" => 1,
#     "supervisors" => [1, 5, 10, 15, 16, 19, 20, 25, 30]
# )

function endpoint_solve(params::Dict{String,Any})
    shifts = ["AM", "PM", "Night"]
    num_midwives = params["num_midwives"]
    num_days = params["num_days"]
    preferences = Dict((i, d, s) => rand(1:10) for i in 1:num_midwives, d in 1:num_days, s in shifts)
    min_midwives_per_shift = params["min_midwives_per_shift"]
    min_supervisors_per_shift = params["min_supervisors_per_shift"]
    supervisors = params["supervisors"] 
    shift_hours = Dict("AM" => 8.5, "PM" => 8.5, "Night" => 8.5)
    # fte = Dict(
    # 1 => 0.4, 2 => 0.6, 3 => 0.6, 4 => 0.4, 5 => 0.4, 6 => 0.4, 7 => 0.4, 8 => 0.4, 9 => 1.0, 10 => 1.0,
    # 11 => 0.6, 12 => 0.4, 13 => 1.0, 14 => 0.8, 15 => 0.8, 16 => 0.8, 17 => 1.0, 18 => 1.0, 19 => 0.4, 20 => 1.0,
    # 21 => 0.6, 22 => 0.4, 23 => 0.8, 24 => 0.4, 25 => 0.6, 26 => 0.8, 27 => 1.0, 28 => 0.8, 29 => 0.4, 30 => 1.0)

    function generate_fte(num_midwives::Int)
        fte = Dict()
        for i in 1:num_midwives
            fte[i] = round(rand(0.2:0.1:1.0), digits=1) # Random FTE value rounded to 1 decimal place
        end
        return fte
    end
    fte = generate_fte(num_midwives)

    model = Model(SCIP.Optimizer)
    set_silent(model)

    @variable(model, X[i = 1:num_midwives, d = 1:num_days, s in shifts], Bin)

    @constraint(model, [i = 1:num_midwives, d = 1:num_days], sum(X[i, d, s] for s in shifts) <= 1)
    @constraint(model, [d = 1:num_days, s in shifts], sum(X[i, d, s] for i in supervisors) >= min_supervisors_per_shift)
    @constraint(model, [d = 1:num_days, s in shifts], sum(X[i, d, s] for i in 1:num_midwives) == min_midwives_per_shift)
    @constraint(model, [i = 1:num_midwives, d = 1:num_days], X[i, d, "AM"] + X[i, d, "PM"] <= 1)
    @constraint(model, [i = 1:num_midwives, d = 1:num_days-1], X[i, d, "Night"] + X[i, d + 1, "AM"] <= 1)
    @constraint(model, [i = 1:num_midwives, d = 1:num_days-1], X[i, d, "Night"] + X[i, d + 1, "PM"] <= 1)
    @constraint(model, [i = 1:num_midwives, d = 2:num_days], X[i, d, "AM"] + X[i, d - 1, "Night"] <= 1)
    @constraint(model, [i = 1:num_midwives, d = 2:num_days], X[i, d, "PM"] + X[i, d - 1, "Night"] <= 1)
    @constraint(model, [i = 1:num_midwives, d = 1:num_days-6], sum(sum(X[i, d+k, s] for s in shifts) for k = 1:6) <= 5) 
    @constraint(model, [i = 1:num_midwives, d = 1:num_days-4], sum(X[i, d+k, "Night"] for k = 1:4) <= 4)
    @constraint(model, [i = 1:num_midwives, d = 1:num_days-7], sum(sum(shift_hours[s] * X[i, d+k, s] for s in shifts) for k = 1:7) <= 38 * fte[i])
    @constraint(model, [i = 1:num_midwives, d = 1:num_days-7], sum(sum(X[i, d+k, s] for s in shifts) for k = 1:7) <= 5)

    @objective(model, Max, sum(preferences[i, d, s] * X[i, d, s] for i in 1:num_midwives, d in 1:num_days, s in shifts))
    optimize!(model)

    # Check optimization status
    status = termination_status(model)
    if status != MOI.OPTIMAL
        return Dict("error" => "Problem is not solvable")
    end

   # Prepare results as a dictionary
    ret = Dict{Int, Dict{String, Any}}()  # Dictionary with day as key, and another dictionary as value
    fte_ret = fte
   for d in 1:num_days
       day_data = Dict{String, Any}()  # Dictionary for shifts on a specific day
       for s in shifts
           assigned_midwives = [i for i in 1:num_midwives if value(X[i, d, s]) > 0.5]
           if !isempty(assigned_midwives)
               day_data[s] = assigned_midwives  # Store shift and assigned midwives
           end
       end
       ret[d] = day_data  # Store day data in main dictionary
   end
   
#    return Dict("shifts" => ret, "fte" => fte)
   return json_response = JSON.json(Dict("shifts" => ret, "fte" => fte))

end



function serve_solve(request::HTTP.Request)
    data = JSON.parse(String(request.body))
    solution = endpoint_solve(data)
    @info solution
    return HTTP.Response(200, Dict(
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
        "Access-Control-Allow-Headers" => "*"
    ), solution)
end




function setup_server(host, port)
    server = HTTP.Sockets.listen(host, port)
    @info server
    HTTP.serve!(host, port; server = server) do request
        try
            if request.method == "OPTIONS"
                return HTTP.Response(200, Dict(
                    "Access-Control-Allow-Origin" => "*",
                    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
                    "Access-Control-Allow-Headers" => "*"
                ), "")
            end
            if request.target == "/api/solve"
                return serve_solve(request)
            else
                return HTTP.Response(404, Dict("Access-Control-Allow-Origin" => "*",
                "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
                "Access-Control-Allow-Headers" => "*"), "Not Found")
            end
        catch err
            return HTTP.Response(500, Dict(
                "Access-Control-Allow-Origin" => "*",
                "Access-Control-Allow-Methods" => "POST, GET, OPTIONS",
                "Access-Control-Allow-Headers" => "*"
            ), "Internal Server Error")
        end
        return Response
    end
end