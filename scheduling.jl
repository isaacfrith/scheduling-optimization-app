"""
- Can only work 1 shift in a working day
- must have at least 1 supervisor on each shift
- must have at least M number of midwifes per shift
- Aim to satisfy preferences as much as possible
- Can't work consecutive shifts
- No more than 5 consecutive days without a day off (not night shift)

- no more than 38hrs per week 
- at least 2 rest days per week
- No more than 4 consective night shifts without a day off
- "Fair" distribution of weekend shifts

- some midwifes can only work 0.4, 0.6 FTE 

- Number of days = 31 days

- Number of midwifes = 20

- AM shifts: 07:00 - 15:30
- PM shifts: 15:00 - 23:30
- Night shifts: 23:00 - 07:30

- must have 1 in charge midwife each shift

"""

using JuMP, Cbc  # Cbc is the solver used here; you can replace it with another solver if desired

# Parameters
num_midwives = 20
num_days = 31
shifts = ["AM", "PM", "Night"]
shift_hours = Dict("AM" => 8.5, "PM" => 8.5, "Night" => 8.5)  # Shift durations in hours

# Minimum number of midwives per shift (M)
M = 3

# Supervisor requirement: At least 1 supervisor (in-charge) per shift
supervisors = [1, 5, 10]  # Example midwives who can act as in-charge

shift_index = Dict("AM" => 1, "PM" => 2, "Night" => 3)


# Preferences: 1 if midwife i prefers to work shift s on day d, 0 otherwise (example random data)
preferences = rand(Bool, num_midwives, num_days, length(shifts))

# Full-Time Equivalents (FTE) for each midwife (example data)
FTE = [1.0, 0.6, 0.4, 1.0, 0.6, 1.0, 1.0, 0.4, 0.6, 1.0, 1.0, 0.6, 0.4, 1.0, 1.0, 0.4, 1.0, 0.6, 1.0, 1.0]

# Model
model = Model(Cbc.Optimizer)

# Decision Variables
@variable(model, x[1:num_midwives, 1:num_days, shifts], Bin)  # x[i, d, s] = 1 if midwife i works shift s on day d

# Constraints

# 1. Only one shift per working day
@constraint(model, [i=1:num_midwives, d=1:num_days], sum(x[i, d, s] for s in shifts) <= 1)

# 2. Minimum number of midwives per shift (M)
@constraint(model, [d=1:num_days, s in shifts], sum(x[i, d, s] for i=1:num_midwives) >= M)

# 3. At least one supervisor per shift
@constraint(model, [d=1:num_days, s in shifts], sum(x[i, d, s] for i in supervisors) >= 1)

# 4. No consecutive shifts
@constraint(model, [i=1:num_midwives, d=1:num_days-1], sum(x[i, d, s] + x[i, d+1, s] for s in shifts) <= 1)

# 5. No more than 5 consecutive days without a day off
@constraint(model, [i=1:num_midwives, d=1:num_days-5], sum(sum(x[i, d+k, s] for s in shifts) for k=0:5) <= 5)

# 6. No more than 4 consecutive night shifts
@constraint(model, [i=1:num_midwives, d=1:num_days-4], sum(x[i, d+k, "Night"] for k=0:4) <= 4)

# 7. Maximum 38 hours per week (for full-time midwives)
for i in 1:num_midwives
    for week_start in 1:7:num_days-6
        @constraint(model, sum(x[i, d, s] * shift_hours[s] for d=week_start:week_start+6, s in shifts) <= FTE[i] * 38)
    end
end

# 8. At least 2 st days per week
for i in 1:num_midwives
    for week_start in 1:7:num_days-6
        @constraint(model, sum(sum(x[i, d, s] for s in shifts) for d=week_start:week_start+6) <= 5)
    end
end

# Objective: Maximize preference satisfaction
@objective(model, Max, sum(preferences[i, d, shift_index[s]] * x[i, d, s] for i=1:num_midwives, d=1:num_days, s in shifts))

# Solve the model
optimize!(model)

# Display results
println("Optimization Status: ", termination_status(model))

for i in 1:num_midwives
    println("\nMidwife $i:")
    for d in 1:num_days
        for s in shifts
            if value(x[i, d, s]) > 0.5
                println("  Day $d: $s Shift")
            end
        end
    end
end
