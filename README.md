# REMLA 25 Team 5 - Sentiment Analysis App

## **Assignment 1: Versions, Releases, and Containerization.** 

For a quick start, you can run the app using [Docker Compose](#docker-compose).

The whole project contains two docker images, the architecture is taken from the assignment:

![Architecture](docs/architecture.png)


- The app image (left) is the web app developed with Flask and Vue. It is responsible for the user interface and the interaction with the user. The app image is built using a Dockerfile located in the `app` directory.
- The model image (right) contains the sentiment analysis model. It is built using a Dockerfile located in the `model` directory. The model image is responsible for loading the model and serving it to the app image via a REST API.
- The images are combined using Docker Compose, using the `docker-compose.yml` file.

The two images are detailed in the next two sections.

### App-service

The Vue frontend can be found in [app-frontend](https://github.com/remla25-team5/app/tree/main/app-frontend) 
and the Flask backend is in [app-backend](https://github.com/remla25-team5/app/tree/main/app-backend).
The API is documented with the OpenAPI standard, and can be found in the docstrings. 

The app image is built using the Dockerfile in root. The environment variables are configured in the .env file, in line with the variables used in the model image.

It uses a multi-stage build to first build the frontend, then it copies the HTML files to the app image. 
It then installs the requirements for the backend, including a tagged release for the lib-version library from github. 

The app image can be built using the following command:

```bash
docker build -t app-service .
```
The app image is run with:

```bash
docker run -p 8080:8080 --env-file=.env app-service 
```

### Model-service

The model service relies on the lib-ml library to encapsulate preprocessing, which is used
both for training and inference. 
Training is done in a [separate repository](https://github.com/remla25-team5/model-training) in a jupyter notebook, and the model is released on github.
The model service downloads the model and the CountVectorizer from the release on github, and caches them in a local directory.

The API is documented with the OpenAPI standard, and can be found in separate YAML files. The default environment variables are in the .env file.

To run the model service, the following command can be used:

```bash
docker build -t model-service .
```

The model service is run with:

```bash
docker run -p 5000:5000 model-service
```

### Docker Compose

The two images are combined using Docker Compose, using the `docker-compose.yml` file in this repository.
The environment variables from the env files are passed to the app and model images.
By default the app image is run on port 8080, and the model image is run on port 5000.

Run with:

```bash
docker-compose up --pull always
```
The app can then be accessed at [http://localhost:8080](http://localhost:8080).

## **Assignment 2: Provisioning a Kubernetes Cluster**

The Kubernetes cluster is provisioned using Vagrant and Ansible. The infrastructure consists of one controller node and two worker nodes, all running Ubuntu 24.04.

### Vagrant Configuration

The `Vagrantfile` located in the `operation` directory defines:
- 1 control plane node (`ctrl`)
- 2 worker nodes (`node-1` and `node-2`)
- A private network with fixed IPs for all nodes (192.168.56.100 for controller)
- Provisioning using Ansible playbooks

### Ansible Provisioning

The Ansible playbooks are located in the `operation/ansible-provisioning` directory:

- **general.yaml**: Applied to all nodes, handles common setup tasks, such as:
  - SSH key authorization for team members
  - Disabling swap (required for Kubernetes)
  - Common system configuration
  - Etc.

- **ctrl.yaml**: Specific to the controller node:
  - Initializes the Kubernetes control plane with `kubeadm`
  - Sets up kubeconfig for the vagrant user
  - Configures the Pod network with Flannel
  - Etc.

- **node.yaml**: Applied to worker nodes:
  - Configures worker-specific settings
  - Joins nodes to the Kubernetes cluster
  - Etc.

### Usage Instructions

First, upload your public SSH key to the `ssh_keys/` directory. This key will be used to access the VMs.

To provision the Kubernetes cluster:

```bash
# Navigate to the operation directory
cd operation

# Start the VMs and provision with Ansible
vagrant up

# To SSH into the controller node:
vagrant ssh ctrl

# To SSH into a worker node (replace n with node number):
vagrant ssh node-n

# To destroy the VMs when done:
vagrant destroy -f
```

Once provisioned, the Kubernetes cluster will be ready to deploy the sentiment analysis application.

If you only want to provision after running `vagrant up`, you can run the following command:

```bash
vagrant provision
```

To setup the dashboard once the kubernetes cluster is provisoned:
```bash
# Navigate to the operation directory
cd operation

# Run the finalization playbook
ansible-playbook -u vagrant -i 192.168.56.100, \
                 ansible-provisioning/finalization.yaml

# Get a token to access the dashboard
kubectl -n kubernetes-dashboard create token admin-user 
```
Remember to add 
```bash
192.168.56.90 dashboard.local
192.168.56.90 sentiment-app.local
192.168.56.90 sentiment-app-test.local
192.168.56.90 grafana.local
```
to your host's DNS file (sudo nano /etc/hosts on Mac)
Once this is done you can access https://dashboard.local in your browser to access the dashboard.

## **Assignment 3: Operate and Monitor Kubernetes**

### Using Helm for Deployment

The sentiment analysis application can be deployed to Kubernetes using Helm. The Helm chart `sentiment-app-chart` is included in this repository and contains all the necessary configuration to deploy both the sentiment analysis app and the model service together.

#### Prerequisites

- A running Kubernetes cluster (either the Vagrant setup described above or minikube)
- Helm installed (version 3.x)

#### Deploying with Helm on Vagrant Kubernetes Cluster

To deploy the application on the Vagrant Kubernetes cluster after having provisioned `finalization.yaml`:

```bash
# SSH into the controller node
vagrant ssh ctrl

# Navigate to the shared operation folder
cd /vagrant

# Install the Helm chart
helm install sentiment-app ./sentiment-app-chart

# Verify the deployment
kubectl get pods
kubectl get services
```

#### Deploying with Helm on Minikube

If you're using minikube instead of the Vagrant setup:

```bash
# Start minikube if not already running
minikube start
minikube addons enable ingress


# Prometheus is added as a dependency which should be fetched is you want monitoring
cd ./sentiment-app-chart
helm dependency build
cd ..

# Install the Helm chart (optionally, Gmail inbox and App password https://support.google.com/accounts/answer/185833?hl=en are needed for receiving alerts)
helm install sentiment-app ./sentiment-app-chart --set monitoring.enabled=true --set istioEnabled=false --set gmailEmail=<value>@gmail.com --set emailPassword=<value>

# Verify the deployment
kubectl get pods
kubectl get services

# Copy the IngressController IP address to etc/hosts
echo "$(minikube ip) sentiment-app.local" | sudo tee -a /etc/hosts

# If you enabled monitoring also copy the grafana url to etc/hosts
echo "$(minikube ip) grafana.local" | sudo tee -a /etc/hosts
```

Then, you can access the app at <release_name>.local so for this installation it will be [http://sentiment-app.local](http://sentiment-app.local).
It is to note that when you deploy the same helm chart multiple times with monitoring enabled, prometheus and grafana will not pick up both, so when testing installation multiple times in a single cluster do `--set monitoring.enabled=false`

If monitoring is enabled you can run the following command to open the port-forwarding to the Prometheus UI:
```bash
kubectl port-forward -n kube-prometheus-stack svc/kube-prometheus-stack-prometheus 9090:9090
```
or alternatively
`minikube service sentiment-app-kube-prometh-prometheus --url`
This can then be accessed at [http://127.0.0.1:9090](http://localhost:9090)


The grafana UI can be accessed at [http://grafana.local](http://grafana.local) with username: admin, password: prom-operator

In order to see alert manager dashboard, call `minikube service sentiment-app-kube-prometh-alertmanager --url`.
Submissions can be simulated easily with the command:
```bash
minikube tunnel
for i in `seq 1 120`; do curl 'http://localhost/api/submit' -H 'Content-Type: application/json' -H 'Host: sentiment-app.local' --data-raw '{"text":"review"}'; sleep 2; done
```
or with VM setup
```bash
for i in `seq 1 120`; do curl 'http://192.168.56.90/api/submit' -H 'Content-Type: application/json' -H 'Host: sentiment-app.local' --data-raw '{"text":"review"}'; sleep 2; done
```

### Grafana Dashboard
The Helm chart includes a Grafana dashboard for monitoring the sentiment analysis application. The dashboard provides insights into:
- Total number of submissions received
- Number of active submissions not yet verified
- Rate of total number of submissions received
- Average number of active submissions not yet verified
- Count sentiment and verified combinations over time

The dashboard is automatically configured when the Helm chart is deployed with monitoring enabled. You can access it at [http://grafana.local](http://grafana.local) after adding the entry to your `/etc/hosts` file.

A visualization of the Grafana dashboard can be seen below:

![Grafana Dashboard Screenshot](docs/grafana-sentiment-experiment.jpg)

##### Uninstalling the Chart

To remove the deployment:

```bash
helm uninstall sentiment-app
```

## Assignment 4

### Automated tests

The testing framework calculates an ML Test Score based on test results across different categories:
- Features
- Monitoring
- ML Infrastructure
- Model Development

These tests are found under `tests/` in the `model-training` repo. The scores are displayed in the terminal output and contribute to the ML Score badge in the `model-training` README.

#### Mutamorphic Testing with Automatic Repair

The `model-training` repo includes mutamorphic tests that automatically detect and repair inconsistencies in model behavior. These tests check if model predictions remain consistent across different mutations of the same test input data, such as replacing words with synonyms.

Mutamorphic testing works by:
1. Generating the test input data.
2. Testing if replacing words with synonyms leads to the same model predictions.
3. If predictions differ, the test fails and the code attempts to repair the issue by trying other synonyms to automatically repair consistencies.

## Assignment 5

### Running the Helm Chart with Istio
Uncomment lines in `finalization.yaml` after the comment `Step 23: Install Istio` to add Istio to VM cluster by re-provisioning (`ansible-playbook -u vagrant -i 192.168.56.100, ansible-provisioning/finalization.yaml`).
After deploying with Helm (either on Minikube or the Vagrant-based Kubernetes cluster), Istio’s IngressGateway handles traffic routing.

Ensure you have Istio installed in your cluster. If not, download the [latest release](https://github.com/istio/istio/releases/) (1.26.0) that corresponds with your system architecture and OS and unpack it.
We will need several Istio addons. You can find the install files in the unpacked Istio folder in `samples/addons/` . 

```bash
minikube delete
minikube start --memory=16384 --cpus=4 --driver=docker
minikube addons enable ingress
istioctl install
kubectl apply -f istio-1.26.0/samples/addons/jaeger.yaml
kubectl apply -f istio-1.26.0/samples/addons/kiali.yaml
kubectl label ns default istio-injection=enabled

cd ./sentiment-app-chart
helm dependency build
cd ..

# Install the Helm chart (optionally, Gmail inbox and App password https://support.google.com/accounts/answer/185833?hl=en are needed for receiving alerts)
# Default enabled Istio
helm install sentiment-app ./sentiment-app-chart --set monitoring.enabled=true --set gmailEmail=<value>@gmail.com --set emailPassword=<value>
```
If running the cluster on VM, don't forget to execute the following commands for convenience (192.168.56.91 is Istio load balancer IP):
```bash
echo "192.168.56.91 sentiment-app.local" | sudo tee -a /etc/hosts
echo "192.168.56.91 grafana.local" | sudo tee -a /etc/hosts
```
Make sure these DNS mappings for `sentiment-app.local` and `grafana.local` overwrite previous records and clear cache. If you want to measure prometheus scraping from the service mesh, you should also install the prometheus addon and enable the dashboard of kiali:
```bash
kubectl apply -f istio-1.26.0/samples/addons/prometheus.yaml
istioctl dashboard kiali
```
This will run next to the prometheus installation outside the cluster. This setup was decided so the custom dashboard can be automatically injected and seen. 

#### Checking the Istio Ingress Gateway IP on Minikube

Istio routes traffic through its IngressGateway. To check the **Ingress Gateway’s IP address**, run:

```bash
minikube service list
```

This will expose the IP of the `istio-ingressgateway` service, which is what you’ll use to access your app. Open the second URL (the URL with the `http2/80` target port) under the `istio-ingressgateway` service in your browser.

#### Testing with Postman or Curl

✅ **Access the app normally (no experiment header):**

* Open your browser and navigate to `http://<GATEWAY_IP>`.
* Or use curl:

  ```bash
  curl http://<GATEWAY_IP>
  ```

✅ **Test experiment traffic (header-based sticky sessions):**
If you want to force a user into the **new version** (`v2`) of the app, use the header `x-experiment: true`.
For example, using curl:

```bash
curl -H "x-experiment: true" http://<GATEWAY_IP>
```

You can also test with **Postman**:

* Set the URL: `http://<GATEWAY_IP>`
* In the Headers tab, add:

  ```
  Key: x-experiment
  Value: true
  ```
* Send the request to see responses from **v2**.

#### 90/10 Canary Split Testing

If no header is present (`x-experiment` not sent), Istio **dynamically splits traffic 90/10**:

* **90%** of users will be routed to `v1`.
* **10%** will see `v2`.

The version is set using a cookie on first entrance on the web, so repeatedly refreshing will not work. This makes it hard to see the feature version (v2), so to see this we recommend setting the `x-experiment: true` header. 
This can be done in a browser using an extension such as ModHeader for google chrome: https://chromewebstore.google.com/detail/modheader-modify-http-hea/idgpnmonknjnojddfkpgkljpfnnfcklj?pli=1

To test rate limiting, call 
```bash
minikube tunnel
for i in {1..11}; do curl -s "http://localhost/api/submit" -H 'Content-Type: application/json' -H 'Host: sentiment-app.local' -H 'x-user: ricky' --data '{"text":"review"}' -o /dev/null -w "%{http_code}\n"; sleep 1; done
```
or with VM setup
```bash
for i in {1..11}; do curl -s "http://192.168.56.91/api/submit" -H 'Content-Type: application/json' -H 'Host: sentiment-app.local' -H 'x-user: ricky' --data '{"text":"review"}' -o /dev/null -w "%{http_code}\n"; sleep 1; done
```
You can vary `x-user` header parameter to notice that limit is being applied per user header for a specific service API (users that send more than 10 requests per minute get temporarily blocked). Without the x-user header this will not work, so you need to set the header when testing this.

## Repositories

Links to the repositories used in this project:

- [model-service](https://github.com/remla25-team5/model-service)
- [lib-ml](https://github.com/remla25-team5/lib-ml)
- [operation](https://github.com/remla25-team5/operation)
- [app](https://github.com/remla25-team5/app)
- [model-training](https://github.com/remla25-team5/model-training)
- [lib-version](https://github.com/remla25-team5/lib-version)

### Use of Generative AI

We used generative AI in the following ways:

- **model-training**: For model-training, Gemini was used to avoid doing repetitive tasks, such as duplicating code with small variations for the training of the classifiers. Also in the custom plugin for pylint, the possible random state cases (TARGETS_RANDOMNESS) where generated to obtain as much coverage as possible. ChatGPT was used to help with implementing some tests, such as finding out how to measure non-functional requirements like memory usage. Copilot was used to help with writing the README.md file.
- **model-service**: For model-service, ChatGPT was used to understand what Dockerfiles and release.yml files are, and what they should contain. Copilot was used to help with making environment variables that are used in the model_utils.py and service.py files. It was also used to speed up repetitive tasks, like downloading the CountVectorizer model the same way that the trained model is downloaded. It was also used to help with writing the README.md file.
- **lib-ml**: In lib-ml, Gemini was used to help determine the needed dependencies for the pyproject.toml file.
- **app**: For the frontend, ChatGPT was only used for trivial and repetitive tasks. Examples include: adding try/catch blocks to code, adding console.log statements to code and defining datatypes in TypeScript as specified by me etc.
- **operation**: For operation, GitHub Copilot was used to help with writing the README.md file. It was also used to help with understanding how `Vagrantfile` works, especially in combination with Ansible. For steps 1 - 5, it was used to help with understanding the setup of the Ansible `general.yaml` playbook. For steps 11-15 we used ChatGPT to enhance our personal understanding of how to specify things in the .yaml file, we read the documentation and then challenged our belief with ChatGPT to make sure we didn't miss any subtleties. For the Helm chart, we used ChatGPT to help understand the structure of the chart and how to use it. We also used it to help with writing the `README.md` file. For Assignment 5, ChatGPT was used to help with adding a section to the `README.md` file about how to use Istio with the Helm chart. ChatGPT was also used to help with rewriting the content of `deployment.md` to make it more readable and understandable.