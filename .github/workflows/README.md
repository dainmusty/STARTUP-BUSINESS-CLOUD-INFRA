🔹 Scenario 1: Startup on Budget (No EKS)
Use case: For startups that cannot afford managed Kubernetes (EKS), we use EC2 instances, Terraform for provisioning, and Ansible to configure Prometheus and Grafana.

🔧 Stack Overview
Infrastructure: AWS EC2 (via Terraform)
Configuration Management: Ansible (with dynamic AWS inventory)
Monitoring: Prometheus + Grafana (installed on EC2)
📂 Project Structure
├── ansible/
│   ├── inventory/
│   │   └── aws_ec2.yml       # Dynamic EC2 inventory
│   ├── playbooks/
│   │   └── setup-prometheus.yml
│   └── roles/                # Optional: Reusable Ansible roles
├── terraform-infra/
│   └── environments/
│       └── dev/
│           └── main.tf
└── .github/workflows/
    └── terraform-ansible.yml  # Workflow definition
🛠️ terraform-ansible.yml
name: Terraform + Ansible Deploy

on:
  push:
    branches:
      - dev

jobs:
  terraform:
    name: Deploy Infra with Terraform
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.6

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Terraform Init & Apply
        working-directory: env/dev
        run: |
          terraform init -input=false
          terraform apply -auto-approve -input=false

  ansible:
    name: Configure Prometheus with Ansible
    needs: terraform
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y ansible python3-boto3 python3-botocore

      - name: Set up SSH private key
        run: |
          mkdir -p ~/.ssh
          echo "${{ secrets.ANSIBLE_SSH_KEY }}" > ~/.ssh/id_rsa
          chmod 600 ~/.ssh/id_rsa

      - name: Create Ansible config
        run: |
          echo '[defaults]' > ansible.cfg
          echo 'inventory = ansible/inventory/aws_ec2.yml' >> ansible.cfg
          echo 'host_key_checking = False' >> ansible.cfg
          echo 'remote_user = ubuntu' >> ansible.cfg

      - name: Run Ansible Playbook
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          ansible-playbook ansible/playbooks/setup-prometheus.yml