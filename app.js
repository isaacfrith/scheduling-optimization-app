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
            method: 'POST', // Change to POST for sending the data
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data), // Send the JSON-encoded data
        });

        if (!response.ok) throw new Error(`Server error: ${response.statusText}`);
        
        const schedule = await response.json();
        window.displayResults(schedule);
    } catch (error) {
        console.error('Error:', error);
        document.getElementById('results').innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
    }
}

function displayResults(schedule) {
    const numNurses = 30; // Total number of nurses
    const numDays = 30; // Total number of days

    // Create a 2D array with default value 0 (no shift)
    const heatmapData = Array.from({ length: numNurses }, () => Array(numDays).fill(0));

    // Populate the heatmapData based on the schedule
    for (const nurseId in schedule) {
        const shifts = schedule[nurseId];
        const nurseIndex = parseInt(nurseId) - 1; // Convert nurse ID to array index

        for (const shiftType in shifts) {
            const days = shifts[shiftType];
            days.forEach(day => {
                const dayIndex = day - 1; // Convert day to array index
                if (shiftType === 'Night') heatmapData[nurseIndex][dayIndex] = 3;
                if (shiftType === 'PM') heatmapData[nurseIndex][dayIndex] = 2;
                if (shiftType === 'AM') heatmapData[nurseIndex][dayIndex] = 1;
            });
        }
    }

    // Render the heatmap using Chart.js
    const ctx = document.getElementById('heatmap').getContext('2d');
    new Chart(ctx, {
        type: 'matrix',
        data: {
            datasets: [{
                label: 'Midwife Shifts',
                data: heatmapData.flatMap((row, nurseIndex) =>
                    row.map((value, dayIndex) => ({ x: dayIndex + 1, y: nurseIndex + 1, v: value }))
                ),
                backgroundColor: function(context) {
                    const value = context.raw.v;
                    if (value === 3) return 'rgba(255, 0, 0, 0.7)'; // Night: red
                    if (value === 2) return 'rgba(0, 0, 255, 0.7)'; // PM: blue
                    if (value === 1) return 'rgba(0, 255, 0, 0.7)'; // AM: green
                    return 'rgba(200, 200, 200, 0.7)'; // No shift: gray
                },
                borderWidth: 1,
                borderColor: 'rgba(0,0,0,0.1)',
                width: ({ chart }) => {
                    // Ensure chartArea is defined
                    return chart.chartArea ? chart.chartArea.width / numDays : 10;
                },
                height: ({ chart }) => {
                    // Ensure chartArea is defined
                    return chart.chartArea ? chart.chartArea.height / numNurses : 10;
                }
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: true,
            scales: {
                x: {
                    type: 'linear',
                    title: { display: true, text: 'Day of Month' },
                    ticks: { stepSize: 1 }
                },
                y: {
                    type: 'linear',
                    offset: true, // Adds separation between rows
                    title: { display: true, text: 'Nurse ID' },
                    ticks: {
                        stepSize: 1, // Ensure each Nurse ID is displayed
                        padding: 10, // Add padding between labels and axis
                        font: {
                            size: 12 // Adjust font size for better readability
                        }
                    }
                }
            },
            plugins: {
                legend: { display: false }
            }
        }
    }); // Corrected closing bracket here
}
