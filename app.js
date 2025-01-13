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
        displayResults(schedule);
    } catch (error) {
        console.error('Error:', error);
        document.getElementById('results').innerHTML = `<p style="color: red;">Error: ${error.message}</p>`;
    }
}
