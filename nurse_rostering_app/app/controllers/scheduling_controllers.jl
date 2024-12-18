using Genie.Router
include("/models/scheduling.jl")

route("/generate_schedule", method=POST) do
    # Retrieve form inputs
    num_midwives = parse(Int, @params(:num_midwives))
    num_days = parse(Int, @params(:num_days))
    min_midwives_per_shift = parse(Int, @params(:min_midwives))

    # Run the scheduling function
    results = generate_schedule(num_midwives, num_days, min_midwives_per_shift)

    # Format the results for display
    result_html = "<h2>Generated Schedule</h2><pre>$(results)</pre>"
    return result_html
end
