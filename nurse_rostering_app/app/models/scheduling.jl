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

using JuMP, Plots
using SCIP, HiGHS

# -------------------------
# Variables
# -------------------------

# Number of midwives
num_midwives = 30

# Number of days in the period
num_days = 30

# Shifts
shifts = ["AM", "PM", "Night"]

# FTE for each midwife (example: random values for demonstration)
fte = Dict(
    1 => 0.4, 2 => 0.6, 3 => 0.6, 4 => 0.4, 5 => 0.4, 6 => 0.4, 7 => 0.4, 8 => 0.4, 9 => 1.0, 10 => 1.0,
    11 => 0.6, 12 => 0.4, 13 => 1.0, 14 => 0.8, 15 => 0.8, 16 => 0.8, 17 => 1.0, 18 => 1.0, 19 => 0.4, 20 => 1.0,
    21 => 0.6, 22 => 0.4, 23 => 0.8, 24 => 0.4, 25 => 0.6, 26 => 0.8, 27 => 1.0, 28 => 0.8, 29 => 0.4, 30 => 1.0)
    # 31 => 0.6, 32 => 1.0, 33 => 0.4, 34 => 0.6, 35 => 0.4, 36 => 0.6, 37 => 0.4, 38 => 0.8, 39 => 0.4, 40 => 0.6,
    # 41 => 1.0, 42 => 1.0, 43 => 0.8, 44 => 1.0, 45 => 1.0, 46 => 0.4, 47 => 0.6, 48 => 0.8, 49 => 1.0, 50 => 0.4)
#     51 => 1.0, 52 => 1.0, 53 => 0.4, 54 => 0.8, 55 => 1.0, 56 => 1.0, 57 => 1.0, 58 => 1.0, 59 => 0.6, 60 => 0.6,
#     61 => 0.4, 62 => 0.6, 63 => 0.6, 64 => 1.0, 65 => 0.4, 66 => 0.8, 67 => 0.6, 68 => 1.0, 69 => 0.4, 70 => 0.4,
#     71 => 0.6, 72 => 0.4, 73 => 1.0, 74 => 0.8, 75 => 1.0, 76 => 0.6, 77 => 1.0, 78 => 0.6, 79 => 0.6, 80 => 0.8,
#     81 => 1.0, 82 => 0.6, 83 => 0.4, 84 => 1.0, 85 => 1.0, 86 => 0.8, 87 => 0.8, 88 => 0.8, 89 => 0.6, 90 => 0.4,
#     91 => 0.6, 92 => 0.4, 93 => 0.8, 94 => 0.4, 95 => 0.8, 96 => 0.6, 97 => 0.8, 98 => 0.6, 99 => 0.6, 100 => 1.0
# )


# Hours per shift
shift_hours = Dict("AM" => 8.5, "PM" => 8.5, "Night" => 8.5)

# Minimum midwives and supervisors per shift
min_midwives_per_shift = 3
min_supervisors_per_shift = 1
supervisors = [1, 5, 10, 15, 16, 19, 20, 25, 30]  # Example supervisor indices

# Preference scores (example: random preferences for demonstration)
preferences = Dict((i, d, s) => rand(1:10) for i in 1:num_midwives, d in 1:num_days, s in shifts)

"""
permutation of the total number of nureses
so from 1-90 for each nurese to have a preference
"""

# 

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
@constraint(model, [d = 1:num_days, s in shifts], sum(X[i, d, s] for i in 1:num_midwives) == min_midwives_per_shift)

# define adjacency of the shifts - 
# rather indexing 
# two sets of decisions variables a day and a shift - and have the shift tired to the day 
# also have a constraint to tire the shifts and days together
# 
# 4. No consecutive shifts
#@constraint(model, [i = 1:num_midwives, d = 1:num_days], sum(X[i, d, s] for s in shifts) <= 1)
# No AM and PM shift on the same day for the same midwife
@constraint(model, [i = 1:num_midwives, d = 1:num_days], X[i, d, "AM"] + X[i, d, "PM"] <= 1)

# No Night shift followed by an AM shift the next day
@constraint(model, [i = 1:num_midwives, d = 1:num_days-1], X[i, d, "Night"] + X[i, d + 1, "AM"] <= 1)

# No AM shift after a Night shift the previous day
@constraint(model, [i = 1:num_midwives, d = 2:num_days], X[i, d, "AM"] + X[i, d - 1, "Night"] <= 1)


# 5. No more than 5 consecutive working days
# total number of shifts consectively should be less than 5
@constraint(model, [i = 1:num_midwives, d = 1:num_days-6],
    sum(sum(X[i, d+k, s] for s in shifts) for k = 1:6) <= 5) # check that it goes from 0 -> 4

# 6. No more than 4 consecutive night shifts
# Sum of nights must be less or equal to 4
@constraint(model, [i = 1:num_midwives, d = 1:num_days-4],
    sum(X[i, d+k, "Night"] for k = 1:4) <= 4)

# 7. Weekly working hours limit based on FTE
# Hours <= 38 hours (convert to FTE)
# assuming FTE is measured per week 
# nested sum to sum over the course of 7 days
# then convert that to a decimal and it should
# be less than the FTE value
# @constraint(model, [i = 1:num_midwives],
#     sum(shift_hours[s] * X[i, d, s] for d = 1:num_days, s in shifts) <= fte[i])

@constraint(model, [i = 1:num_midwives, d = 1:num_days-7],
    sum(sum(shift_hours[s] * X[i, d+k, s] for s in shifts) for k = 1:7) <= 38 * fte[i])


# 8. At least 2 rest days per 7 days window
@constraint(model, [i = 1:num_midwives, d = 1:num_days-7],
    sum(sum(X[i, d+k, s] for s in shifts) for k = 1:7) <= 5)

#try fixs for if a nurse was sick on a day for a shift 
#fix(X [7, d, s] == 0 )

#get Jess to give a real schedule


# -------------------------
# Objective Function
# -------------------------

# Maximize preference satisfaction
# Objective function: P(i, d, s) * X(i, d, s)
@objective(model, Max, sum(preferences[i, d, s] * X[i, d, s] for i in 1:num_midwives, d in 1:num_days, s in shifts))


# different objective function is two subtract actual - preferred and minimise the difference

# -------------------------
# Solve the Model
# -------------------------

optimize!(model)

# -------------------------
# Results
# -------------------------

# for d in 1:num_days
#     println("\nDay $d:")
#     for s in shifts
#         assigned_midwives = [i for i in 1:num_midwives if value(X[i, d, s]) > 0.5]
#         if !isempty(assigned_midwives)
#             println("  Shift $s: Midwives $(assigned_midwives)")
#         end
#     end
# end

#out put to have it as a heat map


# Define the shift codes
shift_codes = Dict("AM" => 1, "PM" => 2, "Night" => 3, "None" => 0)

# Create a matrix to store the assignments
assignment_matrix = fill(0, num_midwives, num_days)

# Populate the matrix with the results from the optimization
for i in 1:num_midwives
    for d in 1:num_days
        shift_assigned = "None"
        for s in shifts
            if value(X[i, d, s]) > 0.5
                shift_assigned = s
                break
            end
        end
        assignment_matrix[i, d] = shift_codes[shift_assigned]
    end
end


# Plot the heatmap
heatmap(
    assignment_matrix,
    xlabel="Days",
    ylabel="Midwives",
    title="Midwife Shift Assignments",
    xticks=1:num_days,
    yticks=1:num_midwives,
    colorbar_title="Shift",
    color=:viridis,
    clim=(0, 3)
)

# Add a custom color legend
annotate!(num_days + 1, num_midwives // 2, text("0: None\n1: AM\n2: PM\n3: Night", 10, :left))