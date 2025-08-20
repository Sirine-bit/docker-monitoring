🚀 Docker Infrastructure Monitoring – Automation with Ansible

📌 Project Context

Containerization with Docker has become the standard for deploying modern applications. However, this flexibility comes with a major challenge:
How can we effectively monitor dozens (or even hundreds) of containers across multiple distributed hosts?

This project addresses the challenge by building a complete monitoring and alerting system, evolving from a manual setup to a multi-VM federated and fully automated infrastructure powered by Ansible.

🎯 Goals

Deploy a complete monitoring stack for Docker environments.

Set up Prometheus federation to aggregate metrics from multiple VMs.

Integrate Alertmanager for proactive anomaly detection.

Automate deployment and configuration with Ansible & Vagrant.

Provide a scalable, reproducible, and reliable monitoring solution.

🏗️ Architecture
flowchart LR
    subgraph VM1 [VM Ubuntu Server]
    A1[Node Exporter] --> P1[Prometheus Local]
    A2[cAdvisor] --> P1
    end

    subgraph VM2 [VM Ubuntu Server]
    B1[Node Exporter] --> P2[Prometheus Local]
    B2[cAdvisor] --> P2
    end

    subgraph VM Central [VM Ubuntu Desktop]
    P1 --> PF[Prometheus Federator]
    P2 --> PF
    PF --> G[Grafana]
    PF --> AM[Alertmanager]
    end

🧩 Methodology

The project was developed in three main phases:

1️⃣ Manual Implementation

Deploying the monitoring stack (Prometheus, Grafana, Node Exporter, cAdvisor).

Configuring Alertmanager with initial alerting rules.

2️⃣ Distributed Extension

Setting up Prometheus federation across multiple VMs.

Building custom dynamic Grafana dashboards.

3️⃣ Automation

Using Ansible to automate deployments (roles, playbooks, Jinja2 templates).

Provisioning VMs with Vagrant to simulate a distributed environment.

Securing secrets with Ansible Vault.

⚙️ Tools & Technologies

Docker & Docker Compose – container orchestration

Prometheus – metrics collection & federation

cAdvisor & Node Exporter – system & container metrics

Alertmanager – alerts & notifications (email, Slack, etc.)

Grafana – visualization & dynamic dashboards

Ansible – automation (roles & playbooks)

Vagrant / VirtualBox – multi-VM provisioning

Bash scripts – container generation & cleanup automation

📂 Project Structure
docker-monitoring-automation/
├── ansible/
│   ├── inventory.ini
│   ├── ansible.cfg
│   ├── roles/
│   │   ├── common/
│   │   ├── monitoring_stack/
│   │   ├── prometheus_local/
│   │   └── prometheus_federator/
│   └── group_vars/
│       └── all.yml
├── prometheus/
│   ├── prometheus.yml
│   ├── federation_alert_rules.yml
│   └── templates/
│       ├── prometheus.yml.j2
│       └── docker-compose.yml.j2
├── grafana/
│   └── dashboards/
├── scripts/
│   ├── random.sh
│   ├── start_random.sh
│   └── myapp.sh
└── vagrant/
    └── Vagrantfile

🚀 Deployment
1️⃣ Clone the repository
git clone https://github.com/Sirine-bit/docker-monitoring.git
cd docker-monitoring

2️⃣ Start VMs with Vagrant
vagrant up

3️⃣ Deploy the monitoring stack with Ansible
cd ansible
ansible-playbook -i inventory/production/hosts.yml playbooks/deploy_infrastructure.yml
ansible-playbook -i inventory/production/hosts.yml playbooks/deploy_monitoring.yml

4️⃣ Access services

Grafana → http://localhost:3000 (default: admin / admin)

Prometheus → http://localhost:9090

Alertmanager → http://localhost:9093

📊 Grafana Dashboards

Example dynamic dashboard:

Monitor CPU, memory, and network usage

Track running Docker containers

Visualize active alerts

✅ Results

Fully functional centralized monitoring stack.

Automated multi-VM deployment with Ansible & Vagrant.

Dynamic Grafana dashboards for Docker containers.

Working Prometheus federation with alerting rules.

⚠️ Challenges

YAML configuration errors in Prometheus & Ansible.

Network and port conflicts between VMs.

Docker Compose v1/v2 compatibility issues.

Docker socket permissions for Prometheus access.

📌 Roadmap & Future Work

 Integrate Kubernetes (K8s) monitoring at scale

 Add Slack / Teams notifications in Alertmanager

 Implement CI/CD pipelines (GitHub Actions) for deployment testing

 Add automated Ansible tests (Molecule, Testinfra)


👤 Author

👨‍💻 Sirine Makni – Engineering Student at SUP’COM, Tunis

🔗 https://www.linkedin.com/in/sirine-makni-9367752a3/

📧 Email: sirine.makni@supcom.tn
