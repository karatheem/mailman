document.getElementById('uploadForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const statusDiv = document.getElementById('status');
    const formData = new FormData();
    const fileInput = document.getElementById('htmlFile');
    
    if (!fileInput.files[0]) {
        statusDiv.textContent = 'Please select a file';
        statusDiv.className = 'error';
        statusDiv.style.display = 'block';
        return;
    }

    formData.append('htmlFile', fileInput.files[0]);

    try {
        const response = await fetch('/upload', {
            method: 'POST',
            body: formData
        });

        if (response.ok) {
            statusDiv.textContent = `File uploaded successfully! Here is your website IP: ${result.deployment.accessUrl}`;
            statusDiv.className = 'success';
        } else {
            statusDiv.textContent = 'Upload failed. Please try again.';
            statusDiv.className = 'error';
        }
    } catch (error) {
        statusDiv.textContent = 'An error occurred. Please try again.';
        statusDiv.className = 'error';
    }
    
    statusDiv.style.display = 'block';
});
