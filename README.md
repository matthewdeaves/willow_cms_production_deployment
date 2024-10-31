# Willow CMS Production-Ready Container for AWS AppRunner

This repo provides a rock-solid, secure, and production-ready container setup for deployment of [Willow CMS](https://github.com/matthewdeaves/willow) on AWS AppRunner.

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Docker Compose Files](#docker-compose-files)
   - [Production (`docker-compose.yml`)](#production-docker-composeyml)
   - [Testing (`docker-compose-test.yml`)](#testing-docker-compose-testyml)
5. [Nginx Configuration](#nginx-configuration)
6. [Supervisord Configuration](#supervisord-configuration)
7. [Security Considerations](#security-considerations)
8. [Willow CMS Version](#willow-cms-version)
9. [Useful Commands](#useful-commands)
10. [Thanks To](#thanks-to)

## Overview

This repository provides a containerized setup for Willow CMS, optimized for deployment on AWS AppRunner. The setup for production includes:

### 1 Willow CMS Container
- **Nginx**: A high-performance web server and reverse proxy.
- **PHP-FPM**: FastCGI Process Manager for PHP, ensuring efficient handling of PHP requests.
- **Redis**: An in-memory data structure store used as the back end for CakePHP Queues
- **Supervisor**: A process control system for managing long-running processes, including CakePHP queue runners, PHP-FPM and nginx.

## Installation

To get started, clone this repository and ensure you have Docker installed on your system. Follow the instructions below to set up the environment.

## Configuration

The container uses environment variables for configuration, allowing seamless integration with AWS AppRunner. You should set up [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html) and use the example docker-compose file for the bare minimum set of environment variables you need to setup values for.

## Docker Compose Files

The docker compose files are examples. You'll see they set environment variables used through the DockerFile and also the config/shell/setup.sh script. You should create a `docker-compose.yml` locally and use that to build your Willow CMS docker images for production. The `.gitignore` file is set to ignore that file to reduce the risk of comiting to the repo.

### Production (`docker-compose-prod-example.yml`)

This is used to build production images. It will not run on your host machine on docker as it is configured to connecto to a MySQL Server via an environment variable and the docker file has no other containers than `willowcms`.

- **WillowCMS**: The main application container, running Nginx, PHP-FPM, Redis and Supervisord. It is configured to serve the application on port 8080.

[docker-compose-prod-example.yml](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/main/docker-compose-prod-example.yml)

### Testing (`docker-compose-test.yml`)

The testing setup includes additional services for testing the production environment container locally:

- **WillowCMS**: Similar to the production container but configured for testing locally with MySQL.
- **MySQL**: A MySQL 5.7 database instance for testing purposes.

[docker-compose-test.yml](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/main/docker-compose-test.yml)

## Nginx Configuration

The Nginx configuration for Willow CMS is split into two main files: `nginx-cms.conf` and `nginx.conf`. These files are crucial for setting up the web server and ensuring optimal performance and security.

### `nginx-cms.conf`

This configuration file is specifically tailored for the Willow CMS application. It includes directives that handle the routing of requests to the appropriate application endpoints and ensures that static assets are served efficiently. This file is designed to optimize the performance of the CMS by configuring caching and compression settings.

- **Purpose**: To manage application-specific routing and performance optimizations.
- **Location**: [nginx-cms.conf](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/main/config/nginx/nginx-cms.conf)

### `nginx.conf`

The `nginx.conf` file contains the global configuration settings for the Nginx server. It includes security settings such as disabling server tokens to prevent information leakage, setting up security headers, and configuring logging. This file ensures that the server is secure and operates efficiently under various loads.

- **Purpose**: To define global server settings, including security and logging.
- **Location**: [nginx.conf](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/main/config/nginx/nginx.conf)

### `Nginx Logging`

If you want to delve deeper into Nginx logging best practices for the cloud, read this:

[Detailed Logging ReadMe](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/main/LOGGINGCONFIG.md)

## Supervisord Configuration

The `supervisord.conf` file manages the processes within the container, including:

- **Nginx**: The web server.
- **PHP-FPM**: The PHP FastCGI Process Manager.
- **Redis**: The in-memory data structure store.
- **CakePHP Queue Runners**: Ensures background tasks are processed from CakePHP Queue. See these [jobs](https://github.com/matthewdeaves/willow/tree/main/src/Job).

[supervisord.conf](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/main/config/supervisord/supervisord.conf)

This configuration ensures that all necessary services are running and monitored, providing a stable environment for the application.

## Security Considerations

- **Non-Root User**: The container runs processes as a non-root user (`nobody`), enhancing security by minimizing permissions. [Dockerfile](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/main/Dockerfile)
- **Environment Variables**: Sensitive information is managed through environment variables, which should be secured and not exposed in production.
- **Nginx Configuration**: The Nginx setup includes security headers and disables server tokens to prevent information leakage. [nginx.conf](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/main/config/nginx/nginx.conf)

## Willow CMS Version
The Dockerfile for this container setup specifies the version of Willow CMS that is downloaded and installed. This is achieved through the following Docker configuration and will be configurable via the `WILLOW_VERSION` argument:

[DockerFile](https://github.com/matthewdeaves/willow_cms_production_deployment/blob/bcdc433cfda64d9dfac713502d608990ca3a28f5/Dockerfile#L64)

## Useful Commands

Here are some useful Docker Compose commands for working with the containers:

### View the Logs

```bash
sudo docker-compose logs willowcms
docker-compose -f docker-compose-test.yml logs willowcmstest
```

### Rebuild an Image

```bash
sudo docker-compose build willowcms --progress=plain --no-cache

docker-compose -f docker-compose-test.yml build willowcms --progress=plain --no-cache
```

### Build

```bash
docker-compose up -d

docker-compose -f docker-compose-test.yml up -d
```

### Down

```bash
docker-compose down -v

docker-compose -f docker-compose-test.yml down -v
```

## Thanks To

Many hours of head banging putting this together where were spared thanks to the fantasic work of Tim de Pater and his [Docker image with PHP-FPM 8.3 & Nginx 1.26 on Alpine Linux](https://hub.docker.com/r/trafex/php-nginx). You should [check him out](https://timdepater.com)