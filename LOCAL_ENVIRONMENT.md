# Project Context: High-Availability SDR Cluster on Turing Pi 2

## 1. Infrastructure Overview
* **Hardware:** Raspberry Pi 4 Cluster (Turing Pi 2 boards).
* **Orchestrator:** K3s (Lightweight Kubernetes).
* **Architecture:** HA Control Plane (3 Masters) + 5 Worker Nodes.
* **OS:** Raspberry Pi OS (Bookworm) 64-bit.

## 2. Network Configuration
* **Control Plane VIP:** `10.9.0.90` (Managed by Kube-VIP).
* **Load Balancer:** MetalLB (Layer 2 Mode).
    * **CIDR Range:** `10.9.0.20 - 10.9.0.30`
    * **Constraint:** All external-facing services (Web UIs, API Gateways) must use `type: LoadBalancer`. Do not use NodePort.
* **Local Access:** Developer Mac is on the same L2 subnet (`10.9.0.x`), allowing direct IP access to LoadBalancer IPs.

## 3. Storage Strategy & Persistence
* **Storage Backend:** Longhorn (Distributed Block Storage).
* **Hardware Tiering:**
    * **SSD Nodes:** `k3s-node3`, `k3s-node7` (SATA SSDs).
    * **eMMC Nodes:** Others.
* **Node Labels:** Nodes with SSDs are labeled `disktype=ssd`.
* **Constraint:** Stateful workloads (Databases, Recorders, .. etc) **must** use PersistentVolumeClaims (PVC) and include `nodeSelector` targeting `disktype: ssd` to ensure performance.

## 4. Hardware Dependencies (SDR)
* **Device:** RTL-SDR Blog V4 (USB).
    * **Vendor/Product ID:** `0bda:2838`.
    * **Serial:** `00000001`.
* **Location:** Physically attached to **Node 8** ONLY.
* **Node Label:** `hardware=sdr` (Applied to Node 8).
* **Deployment Constraints:**
    * **Affinity:** Pods accessing the SDR **must** use `nodeSelector: {hardware: sdr}`.
    * **Replicas:** **Exactly 1** (Single hardware resource constraint).
    * **Privileges:** Container requires `securityContext: {privileged: true}`.
    * **Mounts:** Must mount `/dev/bus/usb` from host to container to access the device.
* **Driver Handling:** The host (Node 8) has blacklisted `dvb_usb_rtl28xxu` to allow container passthrough.

## 5. Scheduling & Resilience
* **Master Protection:** Master nodes (`.91`, `.92`, `.95`) are Tainted (`NoSchedule`). Workloads must be scheduled on Workers.
* **Resilience Strategy:**
    * The cluster environment is prone to node power cycles (single board failure affects 4 nodes).
    * **Constraint:** Stateless Deployments must have `replicas: >=2` and define `podAntiAffinity` to spread pods across different physical nodes.

## 6. Developer Environment
* **Tooling:** `kubectl` is configured locally on MacOS pointing to the VIP.
* **Monitoring:** `k9s` and Longhorn UI are available for debugging.
