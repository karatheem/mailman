// Declare all dependencies
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

// Create express app
const app = express();

// Multer config for file upload

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'uploads/'); //dir where files will be uploaded
    },
    filename: function (req, file, cb) {
        cb(null, 'index.html') //for now always save files as index.html, though this should be changed later
    }
});

const upload = multer({ storage: storage });

// Serve static content
app.use(express.static('public'));



// Function to create Dockerfile

async function createDockerfile(uploadDir) {
    const dockerfileContent = `
    FROM nginx:alpine
    COPY index.html /usr/share/nginx/html
    EXPOSE 80
`;
    await fs.writeFile(path.join(uploadDir, 'Dockerfile'), dockerfileContent);
}

// Function to build Docker image

async function buildDockerImage(uploadDir, imageName) {
    try {
        console.log("Creating docker image...");

        // Execute docker build
        await execPromise('docker build -t mailman:latest uploads/'); // Absolute path for now to get it working 
        console.log("Docker image created successfully!");
        return true;
    } catch (error) {
        console.error("Error building Docker image");
        return false;
    }
}

// File upload route
app.post('/upload', upload.single('htmlFile'), async (req, res) => {
    if (!req.file) {
        return res.status(400).send('Please select and upload a file.');
    }
    try {
        const uploadDir = "uploads";
        const imageName = "mailman:latest" // Again, this needs to be changed later to make it unique

        await createDockerfile(uploadDir);

        const buildSuccess = await buildDockerImage(uploadDir, imageName);

        if (buildSuccess) {
            res.json({
                message: "Successfully uploaded file and built Docker image"
            });
        } else {
            res.status(500).json({
                error: "Failed to create Docker image"
            });
        }
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({
            error: "Server error detected"
        });
    }
});


// Server initialization

const PORT = 8080;
app.listen(PORT, () => {
    console.log('Server successfully started on port ${PORT}');
});
