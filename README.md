# Microservices Task

This `README.md` outlines the steps taken to separate the code into backend and frontend and build the Docker images with Docker Compose.


## Task Objective

This project demonstrates the separation of a codebase into backend and frontend services, containerization using Docker, and orchestration using Docker Compose.

## Table of Contents
- [Overview](#overview)
- [Project Structure](#project-structure)
- [Setup](#setup)
- [Backend Service](#backend-service)
- [Frontend Service](#frontend-service)
- [Docker Compose](#docker-compose)
- [Build and Run](#build-and-run)
- [Contributing](#contributing)
- [License](#license)


## Overview

The **Microservices Task** project is designed to demonstrate:
- The separation of backend and frontend components.
- Building and deploying both services as Docker containers.
- Using Docker Compose for service orchestration.

This repository contains:
- A **backend** service (e.g., a REST API built with Spring Boot).
- A **frontend** service (e.g., a React-based UI).
- Docker and Docker Compose configurations to simplify containerization and deployment.


## Project Structure

The repository is structured as follows:

```
microservices-task/
├── backend/
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml (or package.json for Node.js backend)
├── frontend/
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── docker-compose.yml
└── README.md
```

### Backend
The backend directory contains the server-side application, responsible for business logic and API endpoints.

### Frontend
The frontend directory contains the client-side application that interacts with the backend API and provides the user interface.

---

## Setup

Before running the application, ensure you have the following installed:
- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/)

---

## Backend Service

### Steps for Setting Up the Backend
1. Navigate to the `backend` directory:
   ```bash
   cd backend
   ```
2. Build the backend application:
   - If using Maven:
     ```bash
     mvn clean package
     ```
   - If using Node.js:
     ```bash
     npm install
     ```

### Dockerize the Backend
1. Create a `Dockerfile` in the `backend` directory:
   ```dockerfile
   FROM openjdk:11-jdk-slim
   WORKDIR /app
   COPY target/*.jar app.jar
   ENTRYPOINT ["java", "-jar", "app.jar"]
   ```
2. Build the backend Docker image:
   ```bash
   docker build -t backend-service .
   ```

---

## Frontend Service

### Steps for Setting Up the Frontend
1. Navigate to the `frontend` directory:
   ```bash
   cd frontend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```

### Dockerize the Frontend
1. Create a `Dockerfile` in the `frontend` directory:
   ```dockerfile
   FROM node:14
   WORKDIR /app
   COPY . .
   RUN npm install
   RUN npm run build
   CMD ["npx", "serve", "-s", "build", "-l", "3000"]
   ```
2. Build the frontend Docker image:
   ```bash
   docker build -t frontend-service .
   ```

---

## Docker Compose

The `docker-compose.yml` file is used to define and orchestrate the backend and frontend services.

### Example `docker-compose.yml`
```yaml
version: "3.8"
services:
  backend:
    build:
      context: ./backend
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
    depends_on:
      - db

  frontend:
    build:
      context: ./frontend
    ports:
      - "3000:3000"

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: microservices
      MYSQL_USER: user
      MYSQL_PASSWORD: password
    ports:
      - "3306:3306"
```


## Build and Run

### Step 1: Build the Images
Run the following command to build Docker images for both the backend and frontend:
```bash
docker-compose build
```

### Step 2: Start the Services
Start all services using Docker Compose:
```bash
docker-compose up
```

### Step 3: Access the Application
- **Frontend**: Navigate to `http://localhost:3000` in your browser.
- **Backend**: Access the API at `http://localhost:8080`.


## Contributing

Feel free to fork this repository and make your own contributions. Pull requests are welcome.


This `README.md` provides clear instructions on setting up, building, and running your backend and frontend services with Docker Compose. Let me know if you'd like to customize any section further!



## Infrastructure Configuration using Terraform for EC2, RDS, Auto Scaling, and Monitoring

### Overview

This Terraform configuration provisions the following AWS resources:
- **EC2 Instance**: A `t2.micro` EC2 instance with SSH and MySQL access configured.
- **RDS Instance**: A MySQL-based database instance for DevOps workloads.
- **Auto Scaling Group**: An auto scaling group with EC2 instances that adjusts capacity based on CPU utilization.
- **CloudWatch Monitoring**: CloudWatch Alarms and Dashboards to monitor CPU utilization for both EC2 and RDS instances.
- **Security Group**: A security group allowing SSH and MySQL access.

## Prerequisites

- **Terraform**: Ensure Terraform is installed on your machine. You can download it from [here](https://www.terraform.io/downloads.html).
- **AWS CLI**: Ensure AWS CLI is configured on your machine to authenticate with your AWS account. You can configure it using `aws configure`.
- **AWS Account**: You need to have an AWS account with the necessary permissions to create resources (EC2, RDS, Auto Scaling, CloudWatch, etc.).

## Setup Instructions

1. **Clone the repository** or create a new Terraform configuration directory.
   
2. **Download the required providers**:
   Run the following Terraform command to initialize the provider configuration:
   ```bash
   terraform init
   ```

3. **Configure your AWS credentials**:
   Ensure your AWS credentials are set up either through environment variables or using the AWS CLI configuration.

4. **Review the variables**:
   Ensure that the security group, VPC, and subnet IDs are correct and correspond to the existing infrastructure. Adjust the subnet IDs in the Auto Scaling Group block if necessary.

5. **AWS Secrets Manager**:
   The `AWS Secrets Manager` is used to store sensitive information like database credentials. Replace the reference in the `aws_db_instance` resource with your specific Secrets Manager secret containing the username and password.

6. **Apply the Terraform configuration**:
   Once you have reviewed and set up your configuration, you can apply the configuration by running:
   ```bash
   terraform apply
   ```

7. **Review the resources**:
   Terraform will show you the execution plan. Type `yes` when prompted to approve the changes.

## Resources Created

This configuration will create the following AWS resources:

### EC2 Instance

- **Instance Type**: `t2.micro`
- **AMI**: `ami-0c55b159cbfafe1f0` (Amazon Linux 2)
- **Security Group**: SSH and MySQL (ports 22 and 3306)
- **Auto Scaling**: Part of an Auto Scaling group with scaling policies.

### RDS Instance

- **DB Engine**: MySQL 5.7
- **Instance Type**: `db.t2.micro`
- **Storage**: 20 GB
- **Security Group**: Associated with the EC2 security group.

### Auto Scaling Group

- **Launch Configuration**: Creates an EC2 instance template for auto scaling.
- **Desired Capacity**: 2 instances initially.
- **Min/Max Size**: 1-5 instances.
- **Scaling Policies**: Scale out and scale in policies based on CPU utilization.

### CloudWatch Alarms & Dashboards

- **EC2 Monitoring**: Alarms to scale EC2 instances based on CPU utilization (CPU > 80%).
- **RDS Monitoring**: CloudWatch alarm for RDS CPU usage.
- **CloudWatch Dashboard**: A dashboard to visualize EC2 and RDS CPU utilization and disk operations.

## Key Terraform Resources

- **aws_security_group**: Configures security rules for EC2 and RDS instances.
- **aws_instance**: Provisions an EC2 instance.
- **aws_db_instance**: Provisions a MySQL RDS instance with integration for Secrets Manager credentials.
- **aws_launch_configuration**: Defines the template for EC2 instances in the Auto Scaling group.
- **aws_autoscaling_group**: Auto scaling group with capacity management and CloudWatch alarm integration.
- **aws_cloudwatch_metric_alarm**: Alarms for monitoring EC2 and RDS metrics.
- **aws_cloudwatch_dashboard**: Custom CloudWatch dashboard to visualize the performance of EC2 and RDS instances.

## Important Notes

- **Sensitive Data**: Database credentials (username and password) are pulled from AWS Secrets Manager. Ensure that your secret in Secrets Manager is properly configured before applying this configuration.
- **Security Group**: The security group allows inbound SSH (port 22) and MySQL (port 3306) access from any IP (`0.0.0.0/0`). You should restrict this in a production environment to a specific IP or VPC.
- **Auto Scaling Policies**: This setup creates policies to scale in and out based on EC2 CPU utilization. The threshold is set to 80%, but you can modify this based on your needs.
- **CloudWatch Dashboards**: The dashboard shows metrics for CPU utilization and disk operations for both EC2 and RDS instances.

## Cleanup

To delete the resources created by this Terraform configuration, you can run:
```bash
terraform destroy
```
This will remove all the resources in your AWS account as defined in the Terraform configuration.

---

This README provides an overview of the Infrastructure setup, usage, and resources created by the `main.tf` Terraform configuration. It also includes instructions for applying and cleaning up the resources.
