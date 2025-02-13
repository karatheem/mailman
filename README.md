# mailman

**Mailman** is a web application to which you can POST your code and receive a public IP address where it is already running.

### Run as client

All you have to worry about is your `index.html` file with your website. In the `mailman` app you submit your `index.html` file, and we take care of the rest. In a couple of minutes, the backend will be ready and you will receive a public IP address from which your website will be accessible. You app will be live at the designated IP address for a predefined default period of 48hrs.

### Run as server

To run the `mailman` as a server, grab the repository package. You will need an active Azure subscription. By running the `srv` scripts you will create an Azure VNET in which you should have an Azure VM with Ubuntu VM, an Azure Container Registry (ACR), and Azure Kubernetes Cluster (AKS).

The Ubuntu VM will receive all the necessary configuration via the `run-command` script directly to the guest OS. The ACR will store the pushed container images and make them available for the AKS cluster which in turn will run the workloads publicly.

The server deployment is fully provisioned by running `/srv/spin-srv.sh`.

### Application environment

The high-level diagram below shows the infrastructure required of the application:

<img width="1128" alt="image" src="https://github.com/user-attachments/assets/efd0ec12-4e32-480c-8f3c-4119d6b48fc6" />

Proof of concept:
- The client user acccess the web application running in the Ubuntu 2204 VM being prompted to a web session in which they can upload their web script file.
- The server VM takes care of building a container image based on the provided web file via Dockerfile.
- The resulting container image is then being pushed to Azure Container Registry (ACR).
- The VM composes the application deployment and LoadBalancer service *.yaml files using the container image path available in the ACR.
- Next,the VM applies the application *.yaml files to the Azure Kubernetes Services (AKS) cluster, which in turn runs the application and makes it publicly available.
- Lastly, the VM interogates the AKS cluster for the LoadBalancer service external IP address and prints it on the client-facing application before ending the session.

### Service-Level Agreement

This application and deployment are provided free of charge for both client and server sides.
At the same time, support is as-is via GitHub issues.
