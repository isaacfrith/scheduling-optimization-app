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

using JuMP
using SCIP

# -------------------------
# Variables
# -------------------------

# Number of midwives
num_midwives = 20

# Number of days in the period
num_days = 3

# Shifts
shifts = ["AM", "PM", "Night"]

# FTE for each midwife (example: random values for demonstration)
fte = Dict(1 => 1.0, 2 => 0.6, 3 => 0.4, 4 => 1.0, 5 => 1.0, 6 => 0.6, 7 => 1.0, 8 => 1.0,
           9 => 1.0, 10 => 0.6, 11 => 1.0, 12 => 0.4, 13 => 1.0, 14 => 1.0, 15 => 1.0,
           16 => 1.0, 17 => 0.4, 18 => 1.0, 19 => 0.6, 20 => 1.0)

# Hours per shift
shift_hours = Dict("AM" => 8.5, "PM" => 8.5, "Night" => 8.5)

# Minimum midwives and supervisors per shift
min_midwives_per_shift = 3
min_supervisors_per_shift = 1
supervisors = [1, 5, 10, 15, 16, 19, 20]  # Example supervisor indices

# Preference scores (example: random preferences for demonstration)
preferences = Dict((i, d, s) => rand(1:10) for i in 1:num_midwives, d in 1:num_days, s in shifts)

# -------------------------
# Model
# -------------------------

model = Model(SCIP.Optimizer)

# Decision variable: X[i, d, s] = 1 if midwife i works on day d and shift s, 0 otherwise
@variable(model, X[i = 1:num_midwives, d = 1:num_days, s in shifts], Bin)

# -------------------------
# Constraints
# -------------------------

# 1. One shift per day per midwife
@constraint(model, [i = 1:num_midwives, d = 1:num_days], sum(X[i, d, s] for s in shifts) <= 1)

# 2. At least one supervisor per shift
@constraint(model, [d = 1:num_days, s in shifts], sum(X[i, d, s] for i in supervisors) >= min_supervisors_per_shift)

# 3. At least M midwives per shift
# certain number of midwifes on shift
@constraint(model, [d = 1:num_days, s in shifts], sum(X[i, d, s] for i in 1:num_midwives) >= min_midwives_per_shift)

# 4. No consecutive shifts
@constraint(model, [i = 1:num_midwives, d = 1:num_days], sum(X[i, d, s] for s in shifts) <= 1)


# 5. No more than 5 consecutive working days
# total number of shifts consectively should be less than 5
@constraint(model, [i = 1:num_midwives, d = 1:num_days-4],
    sum(sum(X[i, d+k, s] for s in shifts) for k = 0:4) <= 5)

# 6. No more than 4 consecutive night shifts
# Sum of nights must be less or equal to 4
@constraint(model, [i = 1:num_midwives, d = 1:num_days-3],
    sum(X[i, d+k, "Night"] for k = 0:3) <= 4)

# 7. Weekly working hours limit based on FTE
# Hours <= 38 hours (convert to FTE)
@constraint(model, [i = 1:num_midwives],
    sum(shift_hours[s] * X[i, d, s] for d = 1:num_days, s in shifts) <= 38 * (num_days / 7) * fte[i])

# -------------------------
# Objective Function
# -------------------------

# Maximize preference satisfaction
# Objective function: P(i, d, s) * X(i, d, s)
@objective(model, Max, sum(preferences[i, d, s] * X[i, d, s] for i in 1:num_midwives, d in 1:num_days, s in shifts))

# -------------------------
# Solve the Model
# -------------------------

optimize!(model)

# -------------------------
# Results
# -------------------------

for d in 1:num_days
    println("\nDay $d:")
    for s in shifts
        assigned_midwives = [i for i in 1:num_midwives if value(X[i, d, s]) > 0.5]
        if !isempty(assigned_midwives)
            println("  Shift $s: Midwives $(assigned_midwives)")
        end
    end
end
else
    println("No optimal solution found.")
end
