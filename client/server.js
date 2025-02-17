// Declare all dependencies
import express from 'express';
import multer from 'multer';
import path from 'path';
import { promises as fs } from 'fs';
import { exec } from 'child_process';
import { promisify } from 'util';
import * as k8s from '@kubernetes/client-node';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const execPromise = promisify(exec);

// ACR login server
const ACR_LOGIN = process.env.ACR_LOGIN || 'publicacr38330'; //Using static ACR name for now
const ACR_LOGIN_SERVER = `${ACR_LOGIN}.azurecr.io`;

// K8s config
const kc = new k8s.KubeConfig();
kc.loadFromDefault();
const k8sAppsApi = kc.makeApiClient(k8s.AppsV1Api);
const k8sCoreApi = kc.makeApiClient(k8s.CoreV1Api);

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

function generateDeployTag() {
    return `${Date.now()}`;
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

// Function to create deployment
function createDeployment(imageName, deploymentName) {
    return {
        apiVersion: 'apps/v1',
        kind: 'Deployment',
        metadata: {
            name: deploymentName
        },
        spec: {
            replicas: 1,
            selector: {
                matchLabels: {
                    app: deploymentName
                }
            },
            template: {
                metadata: {
                    labels: {
                        app: deploymentName
                    }
                },
                spec: {
                    containers: [{
                        name: deploymentName,
                        image: imageName,
                        ports: [{
                            containerPort: 80
                        }]
                    }]
                }
            }
        }
    };
}

// Function to create the service
function createService(deploymentName) {
    return {
        apiVersion: 'v1',
        kind: 'Service',
        metadata: {
            name: deploymentName
        },
        spec: {
            type: 'LoadBalancer',
            ports: [{
                port: 80,
                targetPort: 80
            }],
            selector: {
                app: deploymentName
            }
        }
    };
}

async function deployToKubernetes(imageName) {
    try {
        const tag = generateDeployTag();
        const deploymentName = `mailman-${tag}`;

        console.log(`Creating deploy ${deploymentName}`);

        // create deploy
        const deployManifest = createDeployment(imageName, deploymentName);
        await k8sAppsApi.createNamespacedDeployment('default', deployManifest);

        // create service
        const serviceManifest = createService(deploymentName);
        await k8sCoreApi.createNamespacedService('default', serviceManifest);   
        
        let externalIp = null;
        for (let i = 0; i < 24; i++) {
            const service = await k8sCoreApi.readNamespacedService(deploymentName, 'default');
            if (service.body.status.loadBalancer.ingress) {
                externalIp = service.body.status.loadBalancer.ingress[0].ip;
                break;
            }
            await new Promise(resolve => setTimeout(resolve, 2400));
        }

        if (!externalIp) {
            throw new Error('External IP not found');
        }

        return {
            success: true,
            deploymentName: deploymentName,
            serviceIP: externalIp
        };
    } catch (error) {
        console.error(`K8s deployment error:`, error);
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

        if (!buildSuccess.success) {
            return res.status(500).json({
                error: "Failed to create Docker image",
                details: buildSuccess.error
            });
        }

        console.log('Deploying to Kubernetes...');
        const deployResult = await deployToKubernetes(buildSuccess.acrImageName);

        if (deployResult.success) {
            res.json({
                message: "Deploy succesful",
                imageDetails: {
                    tag: buildSuccess.tag,
                    fullImageName: buildSuccess.acrImageName
                },
                deployment: {
                    name: deployResult.deploymentName,
                    accessUrl: `http://${deployResult.serviceIP}`
                }
            });
        } else {
            res.status(500).json({
                error: "Deploy failed",
                details: deployResult.error
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
    console.log(`Server successfully started on port ${PORT}`);
});
