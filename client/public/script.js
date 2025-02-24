// Enhanced script.js content will go here
const fileInput = document.getElementById('fileInput');
const uploadBtn = document.getElementById('uploadBtn');
const dropZone = document.getElementById('dropZone');
const progressContainer = document.getElementById('progressContainer');
const progressFill = document.getElementById('progressFill');
const statusMessage = document.getElementById('statusMessage');
const resultSection = document.getElementById('resultSection');
const deploymentUrl = document.getElementById('deploymentUrl');

        // Event listeners for drag and drop
dropZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropZone.classList.add('dragging');
});

dropZone.addEventListener('dragleave', () => {
    dropZone.classList.remove('dragging');
});

dropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    dropZone.classList.remove('dragging');
    const files = e.dataTransfer.files;
    if (files.length > 0) {
        fileInput.files = files;
        handleFileSelection();
    }
});

        // Click to upload
uploadBtn.addEventListener('click', () => {
    fileInput.click();
});

fileInput.addEventListener('change', handleFileSelection);

function handleFileSelection() {
    if (fileInput.files.length > 0) {
        uploadFile(fileInput.files[0]);
    }
}

function updateProgress(percentage, message) {
    progressFill.style.width = `${percentage}%`;
    statusMessage.textContent = message;
}

function showProgress() {
    progressContainer.style.display = 'block';
    resultSection.style.display = 'none';
}

function simulateProgress(duration, steps, callback) {
    let progress = 0;
    const increment = 125 / steps;
    const stepDuration = duration / steps;

    const interval = setInterval(() => {
        progress += increment;
        if (progress >= 125) {
            clearInterval(interval);
            progress = 125;
            if (callback) callback();
        }
        updateProgress(progress, getProgressMessage(progress));
    }, stepDuration);
}

function getProgressMessage(progress) {
    if (progress < 20) return "Preparing deployment...";
    if (progress < 45) return "Building container...";
    if (progress < 75) return "Pushing to registry...";
    if (progress < 90) return "Deploying to Kubernetes...";
    return "Finalizing deployment...";
}

async function uploadFile(file) {
    const formData = new FormData();
    formData.append('htmlFile', file);

    showProgress();
    updateProgress(0, "Starting deployment...");

    try {
        // Start progress animation
        simulateProgress(21000, 300);

        const response = await fetch('/upload', {
            method: 'POST',
            body: formData
        });

        const result = await response.json();

        if (response.ok) {
             // Show success state
            updateProgress(100, "Deployment successful!");
            setTimeout(() => {
                progressContainer.style.display = 'none';
                resultSection.style.display = 'block';
                deploymentUrl.href = result.deployment.accessUrl;
                deploymentUrl.textContent = result.deployment.accessUrl;
                document.querySelector('.envelope-icon').classList.add('success-animation');
            }, 1000);
        } else {
            throw new Error(result.error || 'Deployment failed');
        }
    } catch (error) {
        updateProgress(100, `Error: ${error.message}`);
        progressFill.style.backgroundColor = '#dc3545';
    }
}
