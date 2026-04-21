# Technical Documentation
## Wazuh SIEM Deployment & Analysis

**Author:** Muhammad Ahmad (25I-7705)  
**Course:** Advanced Network Security — MS Cybersecurity, NUCES Islamabad  
**Instructor:** Dr. Zafar Iqbal

---

## 1. Wazuh Architecture Deep Dive

### 1.1 Core Components

#### Wazuh Manager
The central component responsible for:
- Receiving log data from all connected agents over encrypted port 1514 (TCP/UDP)
- Processing events through the decoder and rule engine
- Generating alerts when rules are matched
- Storing alert data and forwarding to the indexer

**Key processes:**
- `wazuh-analysisd` — Main analysis daemon (decodes and analyzes events)
- `wazuh-remoted` — Manages remote agent connections
- `wazuh-logcollector` — Collects local log files
- `wazuh-syscheckd` — File Integrity Monitoring daemon
- `wazuh-modulesd` — Manages all Wazuh modules (SCA, Vulnerability detection, etc.)

#### Wazuh Indexer
Built on **OpenSearch** (Elasticsearch fork), responsible for:
- Indexing all Wazuh alerts and events
- Providing full-text search over security events
- Storing long-term log data for forensic analysis
- Powering dashboard visualizations

**Default port:** 9200 (HTTPS)

#### Wazuh Dashboard
Web-based UI built on **OpenSearch Dashboards**, providing:
- Real-time security event visualization
- MITRE ATT&CK framework mapping
- Compliance dashboards (PCI DSS, HIPAA, GDPR)
- Agent management and deployment
- Vulnerability assessment reports
- File Integrity Monitoring (FIM) dashboard

**Default port:** 443 (HTTPS)

### 1.2 Agent Communication Flow

```
[Agent Endpoint]
       │
       │ 1. Collects logs from OS/apps
       │ 2. Encrypts with shared key (AES-256)
       ▼
[Port 1514/TCP] ──────────────────────────► [wazuh-remoted]
                                                    │
                                                    ▼
                                           [wazuh-analysisd]
                                                    │
                                           Decodes raw log
                                                    │
                                           Matches rule engine
                                                    │
                                           Generates alert JSON
                                                    │
                                                    ▼
                                           [Filebeat/Wazuh]
                                                    │
                                                    ▼
                                           [Wazuh Indexer :9200]
                                                    │
                                                    ▼
                                           [Wazuh Dashboard :443]
```

---

## 2. MITRE ATT&CK Techniques Tested

### T1003.008 — OS Credential Dumping: /etc/passwd and /etc/shadow

**Tactic:** Credential Access  
**Platform:** Linux  
**Severity:** Critical

**Description:**  
Adversaries may attempt to dump the contents of `/etc/passwd` and `/etc/shadow` to enable offline password cracking. Modern Linux systems use a combination of both files to store user account information including password hashes.

**Attack Simulation:**
```bash
# Attacker reads /etc/shadow (requires root)
sudo cat /etc/shadow > /tmp/shadow_dump

# Combines passwd and shadow for John the Ripper
unshadow /etc/passwd /etc/shadow > /tmp/crack.password.db
```

**Wazuh Detection:**
- Rule ID: `5503` (PAM authentication failures)
- File Integrity Monitoring alert on `/etc/shadow` access
- MITRE ATT&CK mapping: `T1003.008`

**Mitigation:**
- Restrict `/etc/shadow` read permissions (mode 640, group shadow)
- Enable auditd rules monitoring access to credential files
- Implement PAM module `pam_faillock` for brute force protection

---

### T1003.007 — OS Credential Dumping: Proc Filesystem

**Tactic:** Credential Access  
**Platform:** Linux  
**Severity:** High

**Description:**  
Adversaries may gather credentials from the `/proc` filesystem. The `/proc/<PID>/mem` file can be used to dump the memory of running processes that may contain credentials.

**Attack Simulation:**
```bash
# Dump process memory via /proc
dd if=/proc/<PID>/mem of=/tmp/process_dump bs=1
grep -a 'password' /tmp/process_dump
```

**Wazuh Detection:**
- Auditd rules monitoring `/proc` filesystem access
- Process creation monitoring via `wazuh-syscheckd`

---

### T1110 — Brute Force: Password Guessing

**Tactic:** Credential Access  
**Platform:** Linux, Windows  
**Severity:** High (escalates to Critical on repeated attempts)

**Wazuh Rules Triggered:**
- Rule `5503` — PAM: User login failed (Level 5)
- Rule `100002` (custom) — Brute force: 5+ failures in 2 min (Level 10)

---

### T1548.003 — Privilege Escalation: Sudo and Sudo Caching

**Tactic:** Privilege Escalation  
**Platform:** Linux  
**Severity:** Medium-High

**Wazuh Rules Triggered:**
- Rule `5402` — Successful sudo to ROOT (Level 3)
- Rule `5406` — Unauthorized sudo command (Level 5)

---

## 3. Log Sources Monitored

### Linux Endpoints

| Log Source | Path | Events Captured |
|-----------|------|----------------|
| Authentication | `/var/log/auth.log` | Login attempts, sudo, SSH |
| System | `/var/log/syslog` | System events, service changes |
| Kernel | `/var/log/kern.log` | Kernel messages |
| Package Manager | `/var/log/dpkg.log` | Software installation |
| Journald | `systemd journal` | All systemd services |
| File System | FIM (`/etc`, `/bin`, `/sbin`) | File changes |

### Windows Endpoints

| Log Source | Channel | Events Captured |
|-----------|---------|----------------|
| Security Events | `Security` | Logon/logoff, account changes |
| System Events | `System` | Service start/stop, crashes |
| Application | `Application` | App errors, warnings |
| PowerShell | `Microsoft-Windows-PowerShell/Operational` | PS command execution |
| Sysmon | `Microsoft-Windows-Sysmon/Operational` | Process creation, network |

---

## 4. Compliance Mapping

### PCI DSS Controls

| Requirement | Description | Wazuh Capability |
|-------------|-------------|-----------------|
| 10.2.1 | All individual user access | Log collection & alerting |
| 10.2.2 | All root/admin actions | Privilege escalation detection |
| 10.2.4 | Invalid logical access attempts | Failed auth detection |
| 10.2.5 | Use of authentication mechanisms | PAM monitoring |
| 10.2.6 | Initialization/stopping of audit logs | Service monitoring |
| 10.2.7 | Creation/deletion of system objects | FIM |
| 10.3 | Protect audit trails | Secure log forwarding |
| 11.5 | Deploy file integrity monitoring | Wazuh FIM |

### GDPR Controls

| Article | Description | Wazuh Capability |
|---------|-------------|-----------------|
| Art. 32 | Security of processing | Encryption, access control monitoring |
| Art. 35.7.d | Risk assessment | Vulnerability detection |
| Art. 33 | Breach notification | Real-time alerting |

---

## 5. CIS Benchmark Results

**Benchmark:** CIS Ubuntu Linux 22.04 LTS v2.0.0  
**Score:** 42% (76 passed, 101 failed, 30 not applicable)

### Failed Check Categories (Top)

| Category | Failed Count | Priority |
|----------|-------------|---------|
| Partition configuration (`/tmp`, `/var`) | 6 | Medium |
| Filesystem integrity | 4 | High |
| PAM authentication policies | 8 | High |
| Network configuration | 12 | Medium |
| Logging configuration | 9 | High |

### Remediation Plan

1. **Partition separation** — Separate `/tmp`, `/var`, `/home` partitions for noexec/nosuid
2. **PAM hardening** — Implement `pam_pwquality` and `pam_faillock`
3. **Auditd rules** — Deploy CIS-recommended auditd configuration
4. **Kernel hardening** — Apply sysctl hardening parameters

---

## 6. Security Events Analysis

### Alert Distribution (24-hour window)

| MITRE Tactic | Alert Count | Top Rule |
|-------------|------------|---------|
| Defense Evasion | 19 | Kernel module loaded |
| Privilege Escalation | 19 | Sudo to ROOT |
| Initial Access | 11 | PAM login |
| Persistence | 11 | New service started |
| Credential Access | 2 | Shadow file access |

### Top Rules Triggered

| Rule ID | Description | Count | Severity |
|---------|-------------|-------|---------|
| 5503 | PAM: User login failed | 45 | 5 |
| 5402 | Successful sudo to ROOT | 32 | 3 |
| 5501 | PAM: Login session opened | 28 | 3 |
| 5502 | PAM: Login session closed | 26 | 3 |
| 533 | Port status change | 8 | 7 |
| 5406 | Command not allowed | 3 | 5 |

---

## 7. Wazuh Manager Service Management

### Service Control Commands

```bash
# Start all services
sudo systemctl start wazuh-manager wazuh-indexer wazuh-dashboard

# Stop all services
sudo systemctl stop wazuh-manager wazuh-indexer wazuh-dashboard

# Check status
sudo systemctl status wazuh-manager
sudo systemctl status wazuh-indexer
sudo systemctl status wazuh-dashboard

# Enable auto-start on boot
sudo systemctl enable wazuh-manager wazuh-indexer wazuh-dashboard

# View logs
sudo tail -f /var/ossec/logs/ossec.log
sudo tail -f /var/ossec/logs/alerts/alerts.json
```

### Useful File Locations

| File | Purpose |
|------|---------|
| `/var/ossec/etc/ossec.conf` | Main Wazuh Manager configuration |
| `/var/ossec/etc/rules/local_rules.xml` | Custom detection rules |
| `/var/ossec/etc/decoders/local_decoder.xml` | Custom log decoders |
| `/var/ossec/logs/alerts/alerts.json` | Generated alerts (JSON) |
| `/var/ossec/logs/ossec.log` | Wazuh Manager process log |
| `/var/ossec/queue/agents-info/` | Agent connection info |

---

## 8. Troubleshooting

### Agent Not Connecting

```bash
# On Manager — check agent key registration
sudo /var/ossec/bin/manage_agents -l

# On Agent — check service status
sudo systemctl status wazuh-agent
sudo tail -f /var/ossec/logs/ossec.log

# Verify firewall allows port 1514
sudo ufw allow 1514/tcp
sudo ufw allow 1514/udp
```

### Dashboard Not Loading

```bash
# Restart dashboard
sudo systemctl restart wazuh-dashboard

# Check indexer health
curl -k -u admin:PASSWORD https://localhost:9200/_cluster/health?pretty

# Check dashboard logs
sudo journalctl -u wazuh-dashboard --no-pager | tail -50
```

### Reset Admin Password

```bash
# Generate new password hash
/usr/share/wazuh-indexer/plugins/opensearch-security/tools/hash.sh

# Update internal users
sudo /usr/share/wazuh-indexer/plugins/opensearch-security/tools/securityadmin.sh \
  -cd /etc/wazuh-indexer/opensearch-security/ \
  -icl -nhnv \
  -cacert /etc/wazuh-indexer/certs/root-ca.pem \
  -cert /etc/wazuh-indexer/certs/admin.pem \
  -key /etc/wazuh-indexer/certs/admin-key.pem
```

---

*Document generated for Assignment No. 3 — Advanced Network Security*  
*NUCES Islamabad — MS Cybersecurity Program*
