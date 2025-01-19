# Scheduling Optimization App

An application to optimize scheduling for healthcare using advanced mathematical modeling and intuitive user interfaces.

## Features

- **Backend**: Built with [JuMP](https://jump.dev/), a domain-specific modeling language for mathematical optimization in Julia.
- **Frontend**: Developed using JavaScript for an interactive and responsive user experience.
- **Optimization**: Utilizes solvers and constraint programming to generate efficient schedules tailored to healthcare needs.
- **Customizability**: Allows configuration of constraints such as minimum staff per shift, supervisory requirements, and specific roles.

## How It Works

1. **User Input**: Users input parameters such as the number of staff, number of days, and shift requirements through a simple web form.
2. **Constraint Programming**: The backend processes these inputs using JuMP to define and solve the scheduling problem.
3. **Optimization Solvers**: Solvers like Gurobi or Cbc are employed to find optimal solutions efficiently.
4. **Results Visualization**: Outputs are displayed in a user-friendly format, such as heatmaps, to help users understand the scheduling results.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/scheduling-optimization-app.git
   cd scheduling-optimization-app
   ```

2. Install dependencies for the backend (Julia):
   ```bash
   julia --project=@.
   using Pkg
   Pkg.instantiate()
   ```

3. Install dependencies for the frontend:
   ```bash
   cd frontend
   npm install
   ```

4. Start the backend server:
   ```bash
   julia backend/server.jl
   ```

5. Start the frontend:
   ```bash
   cd frontend
   npm start
   ```

## Usage

1. Open the app in your browser (default: `http://localhost:3000`).
2. Input scheduling parameters, such as the number of midwives and shift requirements.
3. Click "Get Schedule" to generate optimized results.
4. Review the heatmap and other visual outputs to understand the schedule.

## Technologies Used

- **Backend**:
  - [JuMP](https://jump.dev/)
  - Solvers: [Gurobi](https://www.gurobi.com/), [Cbc](https://github.com/coin-or/Cbc), or other compatible solvers
- **Frontend**:
  - JavaScript
  - HTML/CSS

## Contributing

1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add feature"
   ```
4. Push to the branch:
   ```bash
   git push origin feature-name
   ```
5. Create a pull request.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

- [JuMP Development Team](https://jump.dev/)
- Open-source solver communities

## Contact

For any questions or suggestions, please open an issue or contact the repository owner.

