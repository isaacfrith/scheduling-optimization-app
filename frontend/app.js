let chartInstance; // Global variable to store the chart instance
let nameDictionary = {
    1: 'Riley',
    2: 'Avery',
    3: 'Leah',
    4: 'Abigail',
    5: 'Zoey',
    6: 'Zoey',
    7: 'Mia',
    8: 'Scarlett',
    9: 'Ava',
    10: 'Harper',
    11: 'Natalie',
    12: 'Ella',
    13: 'Amelia',
    14: 'Ella',
    15: 'Mia',
    16: 'Lucy',
    17: 'Scarlett',
    18: 'Leah',
    19: 'Lucy',
    20: 'Addison',
    21: 'Bella',
    22: 'Abigail',
    23: 'Evelyn',
    24: 'Savannah',
    25: 'Olivia',
    26: 'Mia',
    27: 'Hannah',
    28: 'Charlotte',
    29: 'Ava',
    30: 'Hannah',
    31: 'Victoria',
    32: 'Natalie',
    33: 'Ava',
    34: 'Nora',
    35: 'Emma',
    36: 'Zoey',
    37: 'Aria',
    38: 'Chloe',
    39: 'Lucy',
    40: 'Violet'
}

async function sendRequest() {
    // Collect input values
    const numMidwives = document.getElementById('num_midwives').value;
    const numDays = document.getElementById('num_days').value;
    const minMidwivesPerShift = document.getElementById('min_midwives_per_shift').value;
    const minSupervisorsPerShift = document.getElementById('min_supervisors_per_shift').value;
    const supervisors = document.getElementById('supervisors').value.split(',').map(Number);

    // Prepare request payload
    const data = {
        num_midwives: parseInt(numMidwives),
        num_days: parseInt(numDays),
        min_midwives_per_shift: parseInt(minMidwivesPerShift),
        min_supervisors_per_shift: parseInt(minSupervisorsPerShift),
        supervisors: supervisors
    };

    // Send POST request to the server
    try {
        const response = await fetch('http://127.0.0.1:8080/api/solve', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data),
        });

       
        if (!response.ok) throw new Error(`Server error: ${response.statusText}`);

        const resp = await response.json();
        const result = JSON.parse(resp)

        // Check if the response contains an error
        if (result.error) {
            document.getElementById('results').innerHTML = `<p style="color: red;">Problem is not solvable: ${result.error}</p>`;
        } else {
            // Display results if no error
            document.getElementById('results').innerHTML = "";

            displayResults(result.shifts, parseInt(numMidwives), parseInt(numDays), result.fte);
            
        }

    } catch (error) {
        console.error('Error:', error);
        document.getElementById('results').innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
    }
}


function displayResults(schedule, numMidwives, numDays, fte) {
    // Get the container for the heatmap
    const heatmapContainer = document.getElementById('heatmap');
    heatmapContainer.innerHTML = ''; // Clear any existing content



    // Create the grid container
    const grid = document.createElement('div');
    grid.style.display = 'grid';
    grid.style.gridTemplateColumns = `repeat(${numDays + 1}, 1fr)`; // +1 for header column
    grid.style.gap = '2px'; // Gap between grid items
    grid.style.border = '1px solid #ccc';
    grid.style.padding = '5px';

    // Add headers for the days
    const emptyHeader = document.createElement('div'); // Empty corner cell
    emptyHeader.textContent = '';
    emptyHeader.style.fontWeight = 'bold';
    grid.appendChild(emptyHeader);

    for (let day = 1; day <= numDays; day++) {
        const dayHeader = document.createElement('div');
        dayHeader.style.width = '20px';
        dayHeader.textContent = `${day}`;
        dayHeader.style.fontWeight = 'light';
        dayHeader.style.textAlign = 'center';
        grid.appendChild(dayHeader);
    }

    // Populate the grid with midwife shifts
    for (let midwife = 1; midwife <= numMidwives; midwife++) {
        // Add the midwife header
        const midwifeHeader = document.createElement('div');
        midwifeHeader.textContent = `${nameDictionary[midwife]} (${fte[midwife.toString()]})`; // Convert midwife to string
        midwifeHeader.style.width = '100px';
        midwifeHeader.style.fontWeight = 'light';
        midwifeHeader.style.textAlign = 'center';
        grid.appendChild(midwifeHeader);

        // Add shift data for each day
        for (let day = 1; day <= numDays; day++) {
            const cell = document.createElement('div');
            cell.style.width = '30px';
            cell.style.height = '30px';
            cell.style.display = 'flex';
            cell.style.alignItems = 'center';
            cell.style.justifyContent = 'center';
            cell.style.border = '1px solid #ccc';
            cell.style.textAlign = 'center';
            cell.style.fontSize = '12px';

            // Determine the shift type for this midwife and day
            let shiftType = 0; // Default: No shift
            Object.entries(schedule).forEach(([dayKey, shifts]) => {
                if (parseInt(dayKey) === day) {
                    Object.entries(shifts).forEach(([type, midwives]) => {
                        if (midwives.includes(midwife)) {
                            shiftType = type === 'Night' ? 3 : type === 'PM' ? 2 : 1;
                        }
                    });
                }
            });

            // Apply background color based on the shift type
            if (shiftType === 3) {
                cell.style.backgroundColor = 'rgba(255, 0, 0, 0.7)'; // Night: red
                cell.textContent = 'N';
            } else if (shiftType === 2) {
                cell.style.backgroundColor = 'rgba(0, 0, 255, 0.7)'; // PM: blue
                cell.textContent = 'P';
            } else if (shiftType === 1) {
                cell.style.backgroundColor = 'rgba(0, 255, 0, 0.7)'; // AM: green
                cell.textContent = 'A';
            } else {
                cell.style.backgroundColor = 'rgba(200, 200, 200, 0.7)'; // No shift: gray
                cell.textContent = '';
            }

            grid.appendChild(cell);
        }
    }

    // Append the grid to the heatmap container
    heatmapContainer.appendChild(grid);
}
