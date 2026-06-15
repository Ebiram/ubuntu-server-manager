# Ubuntu Ultimate Server Automation & Hardening Suite

A modular, highly secure, and production-ready Bash automation suite tailored for **Ubuntu 24.04 LTS and higher**. This toolkit streamlines initial server provisioning, advanced kernel network optimizations, service deployment, and multi-server tunneling with a zero-trust approach.

### ⚡ Quick One-Line Installation

Run the following command on your fresh Ubuntu server to download, extract, and execute the management suite automatically:

```bash
mkdir -p /tmp/server-tools && \
curl -sL https://github.com/Ebiram/ubuntu-aio-server-manager/archive/refs/heads/main.tar.gz | \
tar -xz -C /tmp/server-tools --strip-components=1 && \
cd /tmp/server-tools && \
chmod +x main.sh && \
./main.sh
```

## 🚀 Key Features & Architecture

The project is entirely modular, separating core logical domains into dedicated sub-modules. This makes it highly scalable and clean for version control via GitHub.

* **1) Core Security & Hardening (`security.sh`)**
    * Zero-trust SSH daemon configuration (disables root login, enforces key-only authentication).
    * Secure non-interactive user provisioning with automatic SSH key mirroring.
    * Strict automated UFW firewall policies.
* **2) Performance Optimization (`optimization.sh`)**
    * Bridges core constraints by expanding system file descriptors (`ulimit`) up to 1,000,000.
    * Enables **Google BBR Congestion Control** to minimize packet loss over volatile networks.
    * Optimizes TCP buffers and kernel parameters tailored for Reverse Proxies and Load Balancers.
* **3) Production Service Provisioning (`provision.sh`)**
    * Interactive wizard to deploy optimized **Nginx Virtual Hosts** (ideal for Laravel & WordPress).
    * Installs production-grade PHP runtimes, Node.js LTS, Python environments, MariaDB, PostgreSQL, Redis, and Postfix Outbound Mail.
* **4) Custom App Deployment (`deploy.sh`)**
    * One-click integrations for structural proxy controllers like **3x-ui** and **OpenVPN (Angristan)**.
* **5) Multi-Server Tunneling (`tunnel.sh`)**
    * Automates secure reverse proxy architecture using **GOST (gRPC Multiplexing)** and **Xray Core**.
    * Includes on-demand raw network capacity benchmarking via `iperf3`.
* **6) System Environment Localization (`system_env.sh`)**
    * Enforces global persistence for Google Public DNS using modern `systemd-resolved` schemas.
    * Deploys **ZRAM (Compressed RAM Drive)** to protect low-tier virtual machines from Out-Of-Memory (OOM) crashes.

---

## 📂 Repository Structure

```text
.
├── main.sh               # Core Orchestrator & CLI Menu System
└── modules/
    ├── security.sh       # Module 1: Infrastructure Security
    ├── optimization.sh   # Module 2: Network & Kernel Performance Tuning
    ├── provision.sh      # Module 3: Modern Web Stack & Database Provisioning
    ├── deploy.sh         # Module 4: Auxiliary Application Installation
    ├── tunnel.sh         # Module 5: Multi-Server Secure Bridging
    └── system_env.sh     # Module 6: System Localization, DNS & Memory Tweaks
```
