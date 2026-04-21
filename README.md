<div align="center">

![Wazuh SIEM Banner](./assets/banner.svg)

# 🛡️ Wazuh SIEM Deployment & Analysis

[![MS Cybersecurity](https://img.shields.io/badge/Program-MS%20Cybersecurity-0d1117?style=for-the-badge&logo=shield&logoColor=00d4ff)](https://github.com)
[![Wazuh](https://img.shields.io/badge/SIEM-Wazuh%20v4.14.4-00d4ff?style=for-the-badge&logo=security&logoColor=white)](https://wazuh.com)
[![MITRE ATT&CK](https://img.shields.io/badge/Framework-MITRE%20ATT%26CK-ff6b35?style=for-the-badge)](https://attack.mitre.org)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-239120?style=for-the-badge&logo=linux&logoColor=white)](https://github.com)

> **A complete, production-grade SIEM deployment using Wazuh — covering multi-platform agent deployment, real-time log collection, MITRE ATT&CK threat simulation, and security event analysis.**

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Architecture](#-architecture)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Environment Setup](#-environment-setup)
- [Log Collection](#-log-collection)
- [Threat Simulation](#-threat-simulation)
- [Event Monitoring & Analysis](#-event-monitoring--analysis)
- [Results Summary](#-results-summary)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Author](#-author)

---

## 🔍 Overview

This project demonstrates a **full-lifecycle SIEM (Security Information and Event Management)** deployment using **Wazuh** — a free, open-source security platform. The lab environment simulates real-world threat scenarios using the **Atomic Red Team** framework mapped to **MITRE ATT&CK** techniques.

### 🎯 Key Objectives

| Objective | Status |
|-----------|--------|
| Deploy Wazuh SIEM (All-in-One) | ✅ Complete |
| Multi-Platform Agent Deployment (Linux + Windows) | ✅ Complete |
| Real-Time Log Collection | ✅ Complete |
| MITRE ATT&CK Threat Simulation | ✅ Complete |
| Security Event Monitoring & Analysis | ✅ Complete |
| Compliance Mapping (PCI DSS, GDPR) | ✅ Complete |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    WAZUH SIEM ARCHITECTURE                   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   ┌──────────────────────────────────────┐                 │
│   │         WAZUH MANAGER SERVER         │                 │
│   │         192.168.134.129              │                 │
│   │                                      │                 │
│   │  ┌──────────┐  ┌──────────────────┐  │                 │
│   │  │  Wazuh   │  │  Wazuh Indexer   │  │                 │
│   │  │ Manager  │  │  (OpenSearch)    │  │                 │
│   │  └──────────┘  └──────────────────┘  │                 │
│   │         ┌──────────────────┐          │                 │
│   │         │ Wazuh Dashboard  │          │                 │
│   │         │   (Web UI)       │          │                 │
│   │         └──────────────────┘          │                 │
│   └──────────────────────────────────────┘                 │
│              ↑ Port 1514 (Encrypted)                        │
│    ┌──────────────────┬──────────────────┐                  │
│    │                  │                  │                  │
│    ▼                  ▼                  ▼                  │
│ ┌────────┐      ┌────────────┐    ┌─────────────┐          │
│ │ Ubuntu │      │  Ubuntu    │    │  Windows 10 │          │
│ │ Server │      │   Clone    │    │  (FlareVM)  │          │
│ │ Agent  │      │  (linux)   │    │   Agent     │          │
│ └────────┘      └────────────┘    └─────────────┘          │
│  192.168.x.x    192.168.134.163   192.168.134.159          │
└─────────────────────────────────────────────────────────────┘
```

---

## ⚙️ Prerequisites

| Requirement | Details |
|-------------|---------|
| **Hypervisor** | VMware Workstation / VirtualBox |
| **OS (Manager)** | Ubuntu 22.04 LTS (64-bit) |
| **RAM** | Minimum 8 GB (16 GB recommended) |
| **Storage** | Minimum 50 GB free |
| **Network** | NAT or Host-Only adapter |
| **Internet** | Required for package downloads |

---

## 🚀 Installation

### Step 1 — Launch Ubuntu VM

Boot your Ubuntu 22.04 VM in VirtualBox or VMware.

### Step 2 — Run Wazuh Quickstart Installation

Open a terminal and execute the following command:

```bash
curl -sO https://packages.wazuh.com/4.14/wazuh-install.sh && \
sudo bash ./wazuh-install.sh --a
```

> **Note:** The `--a` flag triggers an **all-in-one** installation, deploying:
> - `wazuh-manager` — Core threat analysis engine
> - `wazuh-indexer` — Elasticsearch-compatible search & storage
> - `wazuh-dashboard` — Web-based visualization interface

### Step 3 — Find Server IP Address

```bash
ip a
```

Note the IP (e.g., `192.168.134.129`) — you'll use this to access the dashboard.

### Step 4 — Access the Dashboard

Navigate to `https://<YOUR_IP>` in your browser. Accept the self-signed SSL warning and log in with the auto-generated credentials printed in the terminal output.

---

## 🌐 Environment Setup

### Restart Wazuh Services

```bash
sudo systemctl start wazuh-manager
sudo systemctl start wazuh-indexer
sudo systemctl start wazuh-dashboard
```

### Deploy Linux Agent (Cloned Ubuntu VM)

On the cloned Ubuntu machine, run:

```bash
wget https://packages.wazuh.com/4.x/apt/pool/main/w/wazuh-agent/wazuh-agent_4.14.4-1_amd64.deb && \
sudo WAZUH_MANAGER='192.168.134.129' \
     WAZUH_AGENT_NAME='linux' \
     dpkg -i ./wazuh-agent_4.14.4-1_amd64.deb
```

Then start the agent:

```bash
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

### Deploy Windows Agent (FlareVM)

Open **PowerShell as Administrator** on the Windows machine:

```powershell
Invoke-WebRequest -Uri https://packages.wazuh.com/4.x/windows/wazuh-agent-4.14.4-1.msi `
  -OutFile $env:tmp\wazuh-agent

msiexec.exe /i $env:tmp\wazuh-agent /q WAZUH_MANAGER='192.168.134.129'

NET START Wazuh
```

---

## 📊 Log Collection

### How It Works

```
[Endpoint Agent] ──(encrypted, port 1514)──► [Wazuh Manager]
                                                     │
                                                     ▼
                                           [Wazuh Indexer]
                                                     │
                                                     ▼
                                          [Dashboard / Alerts]
```

Log sources monitored by default:
- **Linux:** `/var/log/auth.log`, `/var/log/syslog`, journald
- **Windows:** Windows Event Log (System, Security, Application)

### Configure Custom Log Sources

Edit `/var/ossec/etc/ossec.conf` on the manager:

```xml
<localfile>
  <log_format>syslog</log_format>
  <location>/var/log/custom-app.log</location>
</localfile>
```

Restart Wazuh Manager after changes:

```bash
sudo systemctl restart wazuh-manager
```

---

## ⚔️ Threat Simulation

### Install Invoke-AtomicRedTeam on Linux

```bash
# Install PowerShell Core
sudo snap install powershell --classic

# Launch PowerShell
pwsh
```

Inside PowerShell:

```powershell
# Install the Atomic Red Team framework
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing)
Install-AtomicRedTeam -getAtomics
```

### Execute MITRE ATT&CK Technique T1003.008

```powershell
# OS Credential Dumping — /etc/passwd & /etc/shadow
Invoke-AtomicTest T1003.008
```

### Additional Tests Executed

```powershell
# T1003.007 — Proc filesystem memory dump
Invoke-AtomicTest T1003.007

# T1003.006 — Additional credential tests
Invoke-AtomicTest T1003.006
```

---

## 📈 Event Monitoring & Analysis

### MITRE ATT&CK Tactics Detected

| Tactic | Alert Count |
|--------|------------|
| Defense Evasion | 19 |
| Privilege Escalation | 19 |
| Initial Access | 11 |
| Persistence | 11 |
| Credential Access | 2 |

### Compliance Mapping

| Standard | Controls Mapped |
|----------|----------------|
| PCI DSS 2.2 | 209 events |
| PCI DSS 10.2.5 | 30 events |
| PCI DSS 10.2.2 | 7 events |
| GDPR IV_35.7.d | Mapped |
| GDPR IV_32.2 | Mapped |

---

## 📊 Results Summary

| Capability | Result |
|-----------|--------|
| **Log Collection** | ✅ Successfully collected from Linux & Windows agents |
| **Agent Deployment** | ✅ Ubuntu Clone + Windows 10 (FlareVM) |
| **Threat Detection** | ✅ MITRE ATT&CK T1003.008, T1003.007 detected |
| **Alert Generation** | ✅ 280+ alerts generated & visible in dashboard |
| **Failed Login Detection** | ✅ Multiple failed auth attempts captured |
| **MITRE ATT&CK Mapping** | ✅ Events mapped to ATT&CK techniques |
| **File Integrity Monitoring** | ✅ FIM events captured on Linux endpoint |
| **Vulnerability Assessment** | ✅ CVE detection active |
| **Compliance (PCI DSS)** | ✅ 42% score on CIS Ubuntu 22.04 Benchmark |

---

## 📸 Screenshots

All screenshots are organized in the [`/screenshots`](./screenshots/) directory.

| # | Description |
|---|-------------|
| 01 | Ubuntu VM launched in VirtualBox |
| 02 | Wazuh website accessed |
| 03 | Installation documentation |
| 04 | Quickstart method selected |
| 05 | Installation command executed |
| 06 | Installation in progress |
| 07 | IP address retrieval |
| 08 | Dashboard login page |
| 09 | Installation credentials |
| 10 | IP address terminal output |
| 11 | VM cloning wizard |
| 12 | Wazuh services restarted |
| 13 | Linux agent installation |
| 14 | Clone of Ubuntu 64-bit created |
| 15 | Linux agent active in dashboard |
| 16 | Windows PowerShell agent install |
| 17 | Windows agent service started |
| 18 | Multi-platform agents confirmed |
| 19 | Activity generation on clone |
| 20 | Security events in dashboard |
| 21 | ossec.conf file location |
| 22 | Rules section in dashboard |
| 23 | Atomic Red Team website |
| 24 | PowerShell installed on Linux |
| 25 | Invoke-AtomicRedTeam installed |
| 26 | MITRE ATT&CK technique search |
| 27 | T1003.008 test prepared |
| 28 | T1003.008 test executed |
| 29 | Additional atomic tests run |
| 30 | MITRE ATT&CK alert count increase |
| 31 | Security events — new alerts |
| 32 | Authentication failure events |
| 33 | Event analysis summary |
| 34 | Detailed alert view |
| 35 | Compliance section (PCI DSS/GDPR) |
| 36 | Windows agent security events |
| 37 | Windows agent active status |
| 38 | MITRE ATT&CK heatmap |
| 39 | Vulnerability assessment module |
| 40 | File Integrity Monitoring (FIM) |
| 41 | Dashboard summary panel |
| 42 | Wazuh Manager logs |
| 43 | JSON event payload expanded |
| 44 | Discover view — event filtering |
| 45 | Final agents status — all active |
| 46 | Reporting section accessed |
| 47 | Security report preview |
| 48 | Final SIEM operational state |
| 49 | Concluding dashboard view |

---

## 🛠️ Tech Stack

<div align="center">

![Wazuh](https://img.shields.io/badge/Wazuh-4.14.4-00d4ff?style=flat-square&logo=elastic&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04_LTS-E95420?style=flat-square&logo=ubuntu&logoColor=white)
![Windows](https://img.shields.io/badge/Windows_10-FlareVM-0078D6?style=flat-square&logo=windows&logoColor=white)
![VMware](https://img.shields.io/badge/VMware-Workstation-607078?style=flat-square&logo=vmware&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-7.6.0-5391FE?style=flat-square&logo=powershell&logoColor=white)
![MITRE](https://img.shields.io/badge/MITRE-ATT%26CK-FF0000?style=flat-square)
![OpenSearch](https://img.shields.io/badge/OpenSearch-Indexer-003BDE?style=flat-square&logo=opensearch&logoColor=white)

</div>

---

## 👤 Author

<div align="center">

**Muhammad Ahmad**
MS Cybersecurity — NUCES Islamabad

*Advanced Network Security — Assignment No. 3*
*Submitted to: Dr. Zafar Iqbal*
*Student ID: 25I-7705*

[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?style=for-the-badge&logo=github)](https://github.com)

</div>

---

<div align="center">

⭐ **If this project helped you, give it a star!** ⭐

*Made with 🔒 for the cybersecurity community*

</div>
