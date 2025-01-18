let chartInstance; // Global variable to store the chart instance

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

        const result = await response.json();

        // Check if the response contains an error
        if (result.error) {
            document.getElementById('results').innerHTML = `<p style="color: red;">Problem is not solvable: ${result.error}</p>`;
        } else {
            // Display results if no error
            displayResults(result, parseInt(numMidwives), parseInt(numDays));
        }

    } catch (error) {
        console.error('Error:', error);
        document.getElementById('results').innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
    }
}



function displayResults(schedule, numMidwives, numDays) {
    // I want to create a heatmap that can be used by the chartInstance below
    





    // Render the heatmap using Chart.js
    const ctx = document.getElementById('heatmap').getContext('2d');

    chartInstance = new Chart(ctx, {
        type: 'matrix',
        data: {
            datasets: [{
                label: 'Midwife Shifts',
                data: heatmapData.flatMap((row, nurseIndex) =>
                    row.map((value, dayIndex) => ({ x: dayIndex + 1, y: nurseIndex + 1, v: value }))
                ),               
                backgroundColor: function (context) {
                    const value = context.raw.v;
                    if (value === 3) return 'rgba(255, 0, 0, 0.7)'; // Night: red
                    if (value === 2) return 'rgba(0, 0, 255, 0.7)'; // PM: blue
                    if (value === 1) return 'rgba(0, 255, 0, 0.7)'; // AM: green
                    return 'rgba(200, 200, 200, 0.7)'; // No shift: gray
                },
                borderWidth: 1,
                borderColor: 'rgba(0,0,0,0.1)',
                width: ({ chart }) => chart.chartArea ? chart.chartArea.width / Math.max(numDays, 1) : 10,
                height: ({ chart }) => chart.chartArea ? chart.chartArea.height / Math.max(numMidwives, 1) : 10,

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
                    title: { display: true, text: 'Midwife ID' },
                    ticks: {
                        stepSize: 1,
                        padding: 10,
                        font: { size: 12 }
                    }
                }
            },
            plugins: {
                legend: {
                    display: true,
                    position: 'bottom',
                    labels: {
                        generateLabels: () => [
                            { text: 'Night Shift', fillStyle: 'rgba(255, 0, 0, 0.7)' },
                            { text: 'PM Shift', fillStyle: 'rgba(0, 0, 255, 0.7)' },
                            { text: 'AM Shift', fillStyle: 'rgba(0, 255, 0, 0.7)' },
                            { text: 'No Shift', fillStyle: 'rgba(220, 220, 220, 0.3)' }
                        ]
                    }
                }
            }
        }
    });
    

}
