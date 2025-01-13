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
        
        const schedule = await response.json();
        displayResults(schedule);
    } catch (error) {
        console.error('Error:', error);
        document.getElementById('results').innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
    }
}

// function displayResults(schedule) {
//     const resultsDiv = document.getElementById('results');
//     resultsDiv.innerHTML = ''; // Clear previous results
    
//     for (const [day, shifts] of Object.entries(schedule)) {
//         const dayDiv = document.createElement('div');
//         dayDiv.className = 'day';
//         dayDiv.innerHTML = `<strong>Day ${day}</strong><br>`;
        
//         for (const [shift, midwives] of Object.entries(shifts)) {
//             dayDiv.innerHTML += `${shift}: ${midwives.join(', ')}<br>`;
//         }
        
//         resultsDiv.appendChild(dayDiv);
//     }
// }
