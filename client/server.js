// Declare all dependencies
const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs').promises;
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

// ACR login server
const ACR_LOGIN = process.env.ACR_LOGIN || 'publicacr38330'; //Using static ACR name for now
const ACR_LOGIN_SERVER = `${ACR_LOGIN}.azurecr.io`;

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

// Generating unique tag/timestamp
function generateImageTag() {
    return `v${Date.now()}`;
}

// Build and push Docker image to ACR
async function buildAndPushImage(uploadDir) {
    try {
        const tag = generateImageTag();
        const imageName = 'mailman';
        const acrImageName = `${ACR_LOGIN_SERVER}/${imageName}:${tag}`;

        console.log('Building Docker image...');
        await execPromise(`docker build -t ${imageName}:${tag} ${uploadDir}`);
        console.log(`${imageName}:${tag}`);
        console.log(`${acrImageName}`);
        console.log('Docker image built successfully!');

        console.log('Creating ACR tag...');
        await execPromise(`docker tag ${imageName}:${tag} ${acrImageName}`);
        console.log('ACR tag created successfully!');

        console.log('Pushing Docker image to ACR...');
        await execPromise(`docker push ${acrImageName}`);
        console.log('Push succesful!');

        return {
            success: true,
            tag: tag,
            acrImageName: acrImageName
        };
    } catch (error) {
        console.error("Error building and pushing Docker image to ACR");
        return {
            success: false,
            error: error.message
        };
    }
}


// File upload route
app.post('/upload', upload.single('htmlFile'), async (req, res) => {
    if (!req.file) {
        return res.status(400).send('Please select and upload a file.');
    }
    try {
        const uploadDir = "uploads";
        await createDockerfile(uploadDir);

        const buildSuccess = await buildAndPushImage(uploadDir);

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
    console.log(`Server successfully started on port ${PORT}`); // Finally managed to get this working!
});
