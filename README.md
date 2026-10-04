## Azure Virtual Machines 

### 1. VM Creation — Portal + CLI

**Portal flow:**

Azure Portal → Virtual Machines → Create → Azure Virtual Machine

Configure:

| Setting | Example |
|---|---|
| Resource Group | `vm-rg` |
| VM Name | `myvm` |
| Region | `Central India` |
| Image | Ubuntu Server 24.04 LTS |
| Size | `Standard_B2s` |
| Authentication | SSH Key |
| Username | `azureuser` |
| Public IP | Enable for practice |

**Azure CLI:**

```bash
# Create Resource Group
az group create \
  --name vm-rg \
  --location centralindia

# Create Linux VM
az vm create \
  --resource-group vm-rg \
  --name myvm \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys

# List VMs
az vm list -o table

# Get VM public IP
az vm show \
  -d \
  -g vm-rg \
  -n myvm \
  --query publicIps \
  -o tsv

# Start / Stop
az vm start -g vm-rg -n myvm
az vm stop -g vm-rg -n myvm

# Deallocate — stops compute billing
az vm deallocate -g vm-rg -n myvm

# Delete
az vm delete -g vm-rg -n myvm --yes
```

**Remember:** `stop` and `deallocate` are different. For cost control, **deallocate** the VM when it isn't needed.

---

### 2. Disk Types & Performance

Azure VM storage mainly consists of:

```text
Azure VM
   |
   +-- OS Disk
   |
   +-- Data Disk
   |
   +-- Temporary Disk
```

| Disk Type | Performance | Typical Use |
|---|---|---|
| Standard HDD | Low | Backup / infrequent workloads |
| Standard SSD | Moderate | Dev/Test |
| Premium SSD | High | Production |
| Premium SSD v2 | Higher/configurable | Performance workloads |
| Ultra Disk | Very High | Databases / I/O-intensive workloads |

Important performance terms:

```text
IOPS       = Input/Output operations per second
Throughput = Amount of data transferred per second
Latency    = Time required for an I/O operation
```

**Practice:** VM → Disks → Create and attach new disk → initialize/mount inside the operating system.

---

### 3. Images & Snapshots

**Image**

A reusable template for creating VMs.

```text
Image
  |
  +---- VM1
  +---- VM2
  +---- VM3
```

Can contain OS, applications and configuration.

**Snapshot**

Point-in-time copy of a managed disk.

```text
VM
 |
OS Disk
 |
Snapshot
 |
New Disk
```

Typical snapshot CLI:

```bash
az snapshot create \
  --resource-group vm-rg \
  --name mySnapshot \
  --source myDisk
```

**Remember:**

```text
Image    → Create/reproduce VMs
Snapshot → Backup/copy a disk at a point in time
```

For production image management at scale, learn **Azure Compute Gallery**.

---

### 4. Availability Sets vs Availability Zones

| Feature | Availability Set | Availability Zone |
|---|---|---|
| Protection | Hardware/rack failures | Datacenter failure |
| Concept | Fault + Update Domains | Separate physical zones |
| Scope | Datacenter | Region |
| Best for | Legacy/compatible architectures | Modern HA architectures |

For Azure, the number of VM “copies” differs between **Availability Sets, Availability Zones, and VM Scale Sets**.

### Availability Sets vs Zones vs VM Scale Sets

| Feature | VM Copies | Placement | Main Purpose |
|---|---:|---|---|
| **Availability Set** | **Minimum 2 VMs recommended** | Same Azure region/datacenter grouping, spread across fault/update domains | Protect from hardware/maintenance failures |
| **Availability Zones** | **Usually 2–3 VMs** | Separate physical zones/datacenters in one region | Protect from datacenter/zone failure |
| **VM Scale Set (VMSS)** | **0 to 1000+ VMs**, depending on configuration/limits | Automatically creates/manages many identical VM instances | Scaling + high availability |

### 1. Availability Set — 2 VM copies

```text
             Availability Set
                    |
          +---------+---------+
          |                   |
     Fault Domain 1       Fault Domain 2
          |                   |
        VM-1                  VM-2
      Copy 1                Copy 2
```

You manually create **VM-1 and VM-2** and place both in the same Availability Set.

**Remember:**

```text
Availability Set
      |
      +-- VM1
      |
      +-- VM2

Recommended = 2 or more VMs
Automatic VM copies = NO
Automatic scaling   = NO
```

### 2. Availability Zones — typically 3 VM copies

```text
               Azure Region
                    |
        +-----------+-----------+
        |           |           |
      Zone 1      Zone 2      Zone 3
        |           |           |
       VM-1        VM-2        VM-3
      Copy 1      Copy 2      Copy 3
```

Each zone is a **physically separate location** within an Azure region.

```text
Zone 1 → VM1
Zone 2 → VM2
Zone 3 → VM3
```

Using **3 copies across 3 zones** gives strong zone-level resiliency, although you don't always need exactly three VMs.

### 3. VM Scale Set — many identical VM copies

```text
                    Users
                      |
                Load Balancer
                      |
               VM Scale Set
                      |
          +-----------+-----------+
          |           |           |
        VM-1        VM-2        VM-3
          |           |           |
        Copy        Copy        Copy

              High CPU / Load
                     ↓
             + VM-4 + VM-5

              Low CPU / Load
                     ↓
             - VM-4 - VM-5
```

VMSS can automatically increase or decrease the number of instances:

```text
Normal Load
VM1  VM2

High Load
VM1  VM2  VM3  VM4  VM5
          ↑
       Scale Out

Low Load
VM1  VM2
          ↓
        Scale In
```

### Easy way to remember

```text
Availability Set
VM1 + VM2
   ↓
Hardware/Maintenance Protection


Availability Zones
Zone-1      Zone-2      Zone-3
  VM1         VM2         VM3
   ↓
Datacenter/Zone Protection


VM Scale Set
VM1 VM2 → VM1 VM2 VM3 VM4 VM5
              ↑
          Auto Scaling
```

**Key distinction:** Availability Sets and Zones are primarily about **where separate VM instances are placed for availability**. VM Scale Sets are about **managing and scaling a fleet of VM instances**.


**Availability Set:**

```text
Datacenter
 ├── Fault Domain 1 → VM1
 └── Fault Domain 2 → VM2
```

**Availability Zones:**

```text
Azure Region
 ├── Zone 1 → VM1
 ├── Zone 2 → VM2
 └── Zone 3 → VM3
```

For new highly available architectures, **Availability Zones are generally preferred when the region/service supports them**.

---

### 5. VM Scale Sets

**VM Scale Sets (VMSS)** allow multiple identical VM instances to be deployed and scaled.

```text
               Load Balancer
                     |
          +----------+----------+
          |          |          |
         VM1        VM2        VM3
                     |
               Autoscaling
```

Useful for:

- Web applications
- Stateless applications
- High availability
- Horizontal scaling
- Variable traffic

Example:

```bash
az vmss create \
  --resource-group vm-rg \
  --name myvmss \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --instance-count 2
```

Concept:

```text
Traffic increases
      ↓
Autoscale rule
      ↓
2 VMs → 4 VMs → 6 VMs

Traffic decreases
      ↓
Scale in
      ↓
6 VMs → 3 VMs → 2 VMs
```

---

### 6. Azure Bastion Access

Azure Bastion provides secure browser-based **SSH/RDP access** to VMs.

Traditional:

```text
Internet
   |
Public IP
   |
SSH / RDP
   |
VM
```

With Bastion:

```text
User Browser
     |
Azure Bastion
     |
Private IP
     |
    VM
```

Major benefit: the VM does **not need its own public IP** for normal Bastion access.

**Portal practice:**

VM → Connect → Bastion → Deploy Bastion → Enter credentials → Connect

Good security practice:

```text
Avoid exposing:
22   SSH
3389 RDP

directly to the Internet.
```

---

### 7. VM Monitoring Basics

Main Azure monitoring service:

**Azure Monitor**

```text
Azure VM
   |
   +-- Metrics
   +-- Logs
   +-- Alerts
   +-- VM Insights
          |
     Azure Monitor
```

Useful metrics include:

- CPU percentage
- Disk IOPS
- Disk throughput
- Network In/Out
- Availability
- VM health

**Practice:**

VM → Monitoring → Metrics

Select:

```text
Metric Namespace: Virtual Machine Host
Metric: Percentage CPU
Aggregation: Average
```

Then create an alert such as:

```text
CPU > 80%
      ↓
Azure Monitor Alert
      ↓
Action Group
      ↓
Email / Notification
```

---

### 8. Auto Shutdown / Cost Control

For Dev/Test VMs, configure automatic shutdown.

Portal:

```text
VM
 ↓
Operations
 ↓
Auto-shutdown
 ↓
Enable
 ↓
Select shutdown time
```

Example:

```text
Start VM → 9:00 AM
     |
Training / Lab
     |
Auto Shutdown → 7:00 PM
```

Other important cost controls:

- Choose the correct VM size.
- Deallocate unused VMs.
- Delete unused managed disks and public IPs.
- Use Azure Advisor recommendations.
- Configure Azure Budget alerts.
- Consider Reservations/Savings Plans for predictable workloads.
- Use Spot VMs only for interruption-tolerant workloads.

### Quick Revision

```text
VM               → Compute server
Managed Disk     → Persistent VM storage
Image            → Template for creating VMs
Snapshot         → Point-in-time disk copy
Availability Set → Hardware/rack-level resiliency
Availability Zone→ Datacenter-level resiliency
VMSS             → Multiple scalable VM instances
Bastion          → Secure SSH/RDP without VM public IP
Azure Monitor    → Metrics, logs and alerts
Auto Shutdown    → Reduce unnecessary VM cost
```

**Best hands-on sequence:** Create VM → attach data disk → take snapshot → create image → test Availability Zone → create VMSS → connect using Bastion → configure CPU alert → enable auto-shutdown.

<div align="center">

[![Open in Codespaces](https://img.shields.io/badge/Open%20in-Codespaces-24292e?logo=github&style=for-the-badge)](https://codespaces.new/atulkamble/template.git)
[![Open with VS Code](https://img.shields.io/badge/Open%20with-VS%20Code-007ACC?logo=visualstudiocode&style=for-the-badge)](https://vscode.dev/github/atulkamble/template)
[![Open with GitHub Desktop](https://img.shields.io/badge/Open%20with-GitHub%20Desktop-purple?logo=github&style=for-the-badge)](https://desktop.github.com/)

**🚀 MyApp** | Built with ❤️ by [Atul Kamble](https://github.com/atulkamble)

[![GitHub](https://img.shields.io/badge/GitHub-atulkamble-181717?logo=github)](https://github.com/atulkamble)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-atuljkamble-0A66C2?logo=linkedin)](https://www.linkedin.com/in/atuljkamble/)
[![X](https://img.shields.io/badge/X-atul_kamble-000000?logo=x)](https://x.com/atul_kamble)

**Version 1.0.0** | Last Updated: December 2025

</div>

Below is an **step-by-step Azure CLI guide** for **launching both Linux (Ubuntu Server) and Windows Server Azure VMs**, including **Azure VM Extensions (Custom Script)**.

This is **production-ready** and suitable for **labs, demos, CI/CD pipelines, and real projects**.

---

## 🔐 1️⃣ Login & Set Subscription

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

---

## 📦 2️⃣ Create Resource Group

```bash
az group create \
  --name myRG \
  --location eastus
```

---

# 🐧 Launch Azure VM – **Linux (Ubuntu Server)**

![Image](https://k21academy.com/wp-content/uploads/2020/07/Azure-portal.png)

![Image](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/n-tier/images/single-vm-diagram.svg)

![Image](https://res.cloudinary.com/canonical/image/fetch/f_auto%2Cq_auto%2Cfl_sanitize%2Cc_fill%2Cw_720/https%3A%2F%2Flh5.googleusercontent.com%2FM8fI_OhgDjiEawxsoUmMLDFw5QltILoGHjXczOI-H6nY9j3P_Oml9Ub8KkML7veDUaSTJmhU9T8Qf9uiTZxcJNesSGtdnZQdo5g_FN_roe9T_f_w1aPvcOPuIUmb5sS8x-MJic13)

## 3️⃣ Create Ubuntu Server VM

```bash
az vm create \
  --resource-group myRG \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username atul \
  --admin-password 'Password@123' \
  --authentication-type password \
  --public-ip-sku Standard
  --os-disk-size-gb 30
```

### ✅ What this does

* Creates **Ubuntu Server 22.04 LTS**
* Generates SSH keys automatically
* Attaches a public IP
* Uses **Standard_B2s** VM size

---

## 4️⃣ Open SSH & HTTP Ports (Linux)

```bash
az vm open-port \
  --resource-group myRG \
  --name myVM \
  --port 22
```

```bash
az vm open-port \
  --resource-group myRG \
  --name myVM \
  --port 80
```

---

## 5️⃣ Linux VM – Custom Script Extension (Install NGINX)

```bash
az vm extension set \
  --resource-group myRG \
  --vm-name myVM \
  --name CustomScript \
  --publisher Microsoft.Azure.Extensions \
  --settings '{
    "commandToExecute": "sudo apt update && sudo apt install -y nginx"
  }'
```

---

# 🪟 Launch Azure VM – **Windows Server**

![Image](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/n-tier/images/single-vm-diagram.svg)

![Image](https://www.thomasmaurer.ch/wp-content/uploads/2021/11/Windows-Server-2022-Azure-Edition-scaled.jpg)

![Image](https://learn.microsoft.com/en-us/azure-stack/user/media/iaas-architecture-vm-windows/image1.png?view=azs-2506)

## 6️⃣ Create Windows Server VM

```bash
az vm create \
  --resource-group myRG \
  --name myVM \
  --image Win2022Datacenter \
  --size Standard_B2s \
  --admin-username azureadmin \
  --admin-password 'StrongPassword@123' \
  --public-ip-sku Standard \
  --os-disk-size-gb 64
```

⚠️ **Password requirements**

* Min 12 chars
* Uppercase + lowercase
* Number + special char

---

## 7️⃣ Open RDP & HTTP Ports (Windows)

```bash
az vm open-port \
  --resource-group myRG \
  --name myVM \
  --port 3389
```

```bash
az vm open-port \
  --resource-group rg-azure-vm-lab \
  --name vm-windows-01 \
  --port 80
```

---

## 8️⃣ Windows VM – Custom Script Extension (Install IIS)

```bash
az vm extension set \
  --resource-group rg-azure-vm-lab \
  --vm-name vm-windows-01 \
  --name CustomScriptExtension \
  --publisher Microsoft.Compute \
  --settings '{
    "commandToExecute": "powershell Install-WindowsFeature -Name Web-Server"
  }'
```

---

## 📋 9️⃣ List VM Extensions

```bash
az vm extension list \
  --resource-group rg-azure-vm-lab \
  --vm-name vm-ubuntu-01 \
  --output table
```

```bash
az vm extension list \
  --resource-group rg-azure-vm-lab \
  --vm-name vm-windows-01 \
  --output table
```

---

## 🔍 🔟 Get Public IP Addresses

```bash
az vm list-ip-addresses \
  --resource-group rg-azure-vm-lab \
  --output table
```

---

## 🧹 1️⃣1️⃣ Clean-up Resources

```bash
az group delete \
  --name rg-azure-vm-lab \
  --yes --no-wait
```

---

## 🎯 Best Practices (Production)

* Use **cloud-init** for Linux bootstrapping
* Store scripts in **GitHub / Azure Storage**
* Use **Azure Key Vault** for secrets
* Use **Bicep / Terraform** instead of raw CLI
* Enable **Azure Monitor Agent**
* Restrict NSG ports (avoid `0.0.0.0/0`)

---
## 🔹 Azure VM Initialization Options – Big Picture

![Image](https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/n-tier/images/single-vm-diagram.svg)

![Image](https://labresources.whizlabs.com/391a18a3eebf32fc6e566ec5de369a58/cse.png)

Azure provides **two primary mechanisms** to configure VMs at boot or post-deployment:

| Method            | Runs When       | Best For                                 |
| ----------------- | --------------- | ---------------------------------------- |
| **Cloud-Init**    | First boot only | OS-level initialization (Linux)          |
| **VM Extensions** | Anytime         | Post-deploy automation (Linux + Windows) |

---

# 1️⃣ Azure Cloud-Init (Linux Only)

### 🔹 What is Cloud-Init?

**Cloud-Init** is a **native Linux initialization system** that runs **once on first boot**.

✔ Runs **before SSH login**
✔ Faster than extensions
✔ Ideal for **immutable infrastructure**

---

## 🔹 Typical Cloud-Init Use Cases

* Create users & SSH keys
* Install packages
* Configure hostname
* Write config files
* Run bootstrap scripts

---

## 🔹 Cloud-Init YAML Example

```yaml
#cloud-config
package_update: true
package_upgrade: true

packages:
  - nginx
  - git
  - docker.io

users:
  - name: devops
    groups: sudo
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1...

runcmd:
  - systemctl enable nginx
  - systemctl start nginx
  - echo "Cloud-init completed" > /var/log/cloud-init-done.log
```

---

## 🔹 Deploy VM with Cloud-Init (Azure CLI)

```bash
az vm create \
  --resource-group rg-demo \
  --name linux-vm-cloudinit \
  --image Ubuntu2204 \
  --admin-username azureuser \
  --generate-ssh-keys \
  --custom-data cloud-init.yaml
```

📌 **Note**:

* `--custom-data` = cloud-init YAML
* Runs **only once** (on first boot)

---

## 🔹 Verify Cloud-Init Execution

```bash
cloud-init status
cloud-init analyze
cat /var/log/cloud-init-output.log
```

---

# 2️⃣ Azure VM Script Extensions (Advanced)

### 🔹 What are VM Extensions?

VM Extensions are **agents installed on the VM** that allow you to:

✔ Run scripts anytime
✔ Re-run scripts
✔ Integrate with CI/CD
✔ Configure post-deployment

---

## 🔹 Common Azure Script Extensions

| Extension                   | OS              |
| --------------------------- | --------------- |
| **Custom Script Extension** | Linux / Windows |
| **DSC Extension**           | Windows         |
| **Chef / Puppet / Ansible** | Linux / Windows |
| **Azure Monitor Agent**     | Both            |

---

# 3️⃣ Custom Script Extension – Linux

![Image](https://ochzhen.com/assets/img/azure-custom-script-extension-linux/assigned-identity-to-vmss.png)

![Image](https://media.licdn.com/dms/image/v2/C5612AQEHKEJUPWuV2A/article-cover_image-shrink_720_1280/article-cover_image-shrink_720_1280/0/1584082178681?e=2147483647\&t=SBo0aofLnNj49QPrPJH6em-bhmHZ30M_dr8rxPg5NyU\&v=beta)

![Image](https://learn.microsoft.com/en-us/azure/architecture/virtual-machines/media/baseline-network-egress.svg)

### 🔹 Use Cases

* Install applications
* Pull GitHub scripts
* Apply patches
* Reconfigure VM after creation

---

## 🔹 Linux Custom Script Extension (Inline)

```bash
az vm extension set \
  --resource-group rg-demo \
  --vm-name linux-vm \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --settings '{
    "commandToExecute": "apt update && apt install -y nginx"
  }'
```

---

## 🔹 Linux Script from GitHub / Storage

```bash
az vm extension set \
  --resource-group rg-demo \
  --vm-name linux-vm \
  --name customScript \
  --publisher Microsoft.Azure.Extensions \
  --settings '{
    "fileUris": ["https://raw.githubusercontent.com/org/repo/main/setup.sh"],
    "commandToExecute": "bash setup.sh"
  }'
```

---

# 4️⃣ Custom Script Extension – Windows

### 🔹 PowerShell Example

```bash
az vm extension set \
  --resource-group rg-demo \
  --vm-name win-vm \
  --name CustomScriptExtension \
  --publisher Microsoft.Compute \
  --settings '{
    "commandToExecute": "powershell Install-WindowsFeature -Name Web-Server"
  }'
```

---

# 5️⃣ Cloud-Init vs Extensions – Architect View

| Feature        | Cloud-Init  | Script Extension |
| -------------- | ----------- | ---------------- |
| OS Support     | Linux only  | Linux + Windows  |
| Execution      | First boot  | Anytime          |
| Speed          | Very fast   | Moderate         |
| Re-run         | ❌ No        | ✅ Yes            |
| CI/CD friendly | ⚠️ Limited  | ✅ Yes            |
| Best For       | Base config | App config       |

---

# 6️⃣ Best-Practice Architecture (Real World)

✅ **Cloud-Init**

* Users
* SSH
* OS hardening
* Docker installation

✅ **Extensions**

* App deployment
* Monitoring agent
* Security tools
* CI/CD triggered updates

---

## 🧠 Interview Tip (Important)

> **Cloud-Init = OS bootstrap**
> **Extensions = Configuration management**

This distinction is **frequently asked** in **Azure interviews**.

---
**complete list of methods to create an Azure VM**

---

## ✅ All Possible Ways to Create an Azure VM:

| Method                                     | Tool / Interface                  | Code / Command |
| :----------------------------------------- | :-------------------------------- | :------------- |
| **1. Azure Portal (GUI)**                  | Web browser                       | Manual         |
| **2. Azure CLI**                           | Command line / Bash / PowerShell  | ✅              |
| **3. Azure PowerShell**                    | PowerShell console                | ✅              |
| **4. Azure ARM Templates**                 | JSON-based IaC                    | ✅              |
| **5. Bicep**                               | Bicep DSL (IaC)                   | ✅              |
| **6. Terraform**                           | Terraform (HCL IaC tool)          | ✅              |
| **7. Ansible**                             | YAML Playbooks with Azure modules | ✅              |
| **8. Azure SDK (Python, .NET, Java, etc)** | Programmatic SDK-based            | ✅              |

---

## ✅ Now — Codes & Commands for Each:

---

## 📌 1️⃣ Azure CLI

```bash
az group create --name MyResourceGroup --location eastus

az vm create \
  --resource-group MyResourceGroup \
  --name MyVM \
  --image UbuntuLTS \
  --admin-username azureuser \
  --generate-ssh-keys
```
```
az vm create \
  --resource-group LAMP-ResourceGroup \
  --name LampVM \
  --image Ubuntu2404 \
  --admin-username atul \
  --generate-ssh-keys \
  --size Standard_B1s
```

---

## 📌 2️⃣ Azure PowerShell

```powershell
New-AzResourceGroup -Name "MyResourceGroup" -Location "EastUS"

New-AzVM `
  -ResourceGroupName "MyResourceGroup" `
  -Name "MyVM" `
  -Location "EastUS" `
  -VirtualNetworkName "MyVNet" `
  -SubnetName "MySubnet" `
  -SecurityGroupName "MyNSG" `
  -PublicIpAddressName "MyPublicIP" `
  -OpenPorts 80,3389
```

---

## 📌 3️⃣ ARM Template (JSON)

**azuredeploy.json**

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "vmName": { "type": "string" },
    "adminUsername": { "type": "string" },
    "adminPassword": { "type": "securestring" }
  },
  "resources": [
    {
      "type": "Microsoft.Compute/virtualMachines",
      "apiVersion": "2022-03-01",
      "name": "[parameters('vmName')]",
      "location": "[resourceGroup().location]",
      "properties": {
        "hardwareProfile": { "vmSize": "Standard_DS1_v2" },
        "storageProfile": {
          "imageReference": {
            "publisher": "Canonical",
            "offer": "UbuntuServer",
            "sku": "18.04-LTS",
            "version": "latest"
          },
          "osDisk": { "createOption": "FromImage" }
        },
        "osProfile": {
          "computerName": "[parameters('vmName')]",
          "adminUsername": "[parameters('adminUsername')]",
          "adminPassword": "[parameters('adminPassword')]"
        },
        "networkProfile": {
          "networkInterfaces": [
            {
              "id": "[resourceId('Microsoft.Network/networkInterfaces', concat(parameters('vmName'),'-nic'))]"
            }
          ]
        }
      }
    }
  ]
}
```

Deploy it:

```bash
az deployment group create --resource-group MyResourceGroup --template-file azuredeploy.json --parameters vmName=MyVM adminUsername=azureuser adminPassword=YourPassword123!
```

---

## 📌 4️⃣ Bicep (IaC DSL for ARM)

**vm.bicep**

```bicep
resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'myVM'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'myVM'
      adminUsername: 'azureuser'
      adminPassword: 'Password123!'
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'myNic')
        }
      ]
    }
  }
}
```

Deploy it:

```bash
az deployment group create --resource-group MyResourceGroup --template-file vm.bicep
```

---

## 📌 5️⃣ Terraform

**main.tf**

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "myResourceGroup"
  location = "East US"
}

resource "azurerm_virtual_network" "example" {
  name                = "myVNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "example" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "example" {
  name                = "myNIC"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "example" {
  name                  = "myVM"
  location              = azurerm_resource_group.example.location
  resource_group_name   = azurerm_resource_group.example.name
  network_interface_ids = [azurerm_network_interface.example.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "myOsDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "myVM"
    admin_username = "azureuser"
    admin_password = "Password123!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
```

Deploy:

```bash
terraform init
terraform apply
```

---

## 📌 6️⃣ Ansible

**azure\_vm\_playbook.yml**

```yaml
- hosts: localhost
  tasks:
    - name: Create Azure VM
      azure_rm_virtualmachine:
        resource_group: "MyResourceGroup"
        name: "myVM"
        vm_size: "Standard_DS1_v2"
        admin_username: "azureuser"
        admin_password: "Password123!"
        image:
          offer: UbuntuServer
          publisher: Canonical
          sku: '18.04-LTS'
          version: latest
```

Run it:

```bash
ansible-playbook azure_vm_playbook.yml
```

---

## 📌 7️⃣ Azure SDK (Python Example)

```python
from azure.identity import DefaultAzureCredential
from azure.mgmt.compute import ComputeManagementClient

subscription_id = 'your-subscription-id'
credential = DefaultAzureCredential()
compute_client = ComputeManagementClient(credential, subscription_id)

vm = compute_client.virtual_machines.begin_create_or_update(
    "MyResourceGroup",
    "myVM",
    {
        "location": "eastus",
        "storage_profile": {
            "image_reference": {
                "publisher": "Canonical",
                "offer": "UbuntuServer",
                "sku": "18.04-LTS",
                "version": "latest"
            }
        },
        "hardware_profile": {
            "vm_size": "Standard_DS1_v2"
        },
        "os_profile": {
            "computer_name": "myVM",
            "admin_username": "azureuser",
            "admin_password": "Password123!"
        },
        "network_profile": {
            "network_interfaces": [{
                "id": "/subscriptions/xxxx-xxxx/resourceGroups/MyResourceGroup/providers/Microsoft.Network/networkInterfaces/myNic"
            }]
        }
    }
)
```

---

## 📌 8️⃣ Azure Portal (Manual)

* Go to Azure Portal
* Navigate to **Virtual Machines**
* Click **+ Create**
* Follow the wizard UI for all options
  (No code — GUI driven)

---

## 📊 Summary

| Method       | Code Available |
| :----------- | :------------- |
| Azure CLI    | ✅              |
| PowerShell   | ✅              |
| ARM Template | ✅              |
| Bicep        | ✅              |
| Terraform    | ✅              |
| Ansible      | ✅              |
| SDK (Python) | ✅              |
| Azure Portal | GUI            |

---

## ✅ Conclusion

Awesome brief, Atul! Here’s a clean, ready-to-reuse “all the common ways” toolkit to launch Azure VMs — Linux & Windows — using **Azure CLI**, **Azure PowerShell (Az)**, **Bicep**, **ARM JSON**, **Terraform**, and common **provisioning hooks** (cloud-init, Custom Script Extension). I’ve organized it with reusable variables, then variations (Spot, Availability Set, Zones, Accelerated Networking, Ephemeral OS, SIG image, VMSS, data disks, WinRM/RDP NSG, etc.).

If you want, I can drop this into a GitHub-friendly repo layout next.

---

# 0) Reusable naming & variables (copy/paste once)

### Azure CLI (bash/zsh)

```bash
# ---------- BASICS ----------
export LOC="eastus"
export RG="rg-vm-lab"
export VNET="vnet-lab"
export SUBNET="snet-app"
export NSG="nsg-app"
export PUBIP="pip-app"
export NIC="nic-app-01"
export TAGS="env=lab project=vm-lab owner=atul"

# ---------- LINUX ----------
export LINUX_VM="vm-ubuntu-01"
export LINUX_IMAGE="Ubuntu2204"   # az vm image list --publisher Canonical --offer 0001-com-ubuntu-server-jammy ...
export LINUX_SIZE="Standard_B2s"
export SSH_KEY="$HOME/.ssh/azure_vm_lab_id_rsa.pub"  # create via: ssh-keygen -t ed25519 -f ~/.ssh/azure_vm_lab_id_rsa -N ''

# ---------- WINDOWS ----------
export WIN_VM="vm-win-01"
export WIN_IMAGE="Win2022Datacenter"   # lookup with 'az vm image list --publisher MicrosoftWindowsServer --all -o table'
export WIN_SIZE="Standard_B2ms"
export ADMIN_USER="azureuser"
export ADMIN_PASS='P@ssw0rd-Your-Strong-Password-123!'  # demo; prefer Key Vault + secrets in real use
```

### Azure PowerShell (pwsh)

```powershell
$Loc      = "eastus"
$Rg       = "rg-vm-lab"
$Vnet     = "vnet-lab"
$Subnet   = "snet-app"
$Nsg      = "nsg-app"
$Pip      = "pip-app"
$Nic      = "nic-app-01"
$Tags     = @{ env="lab"; project="vm-lab"; owner="atul" }

$LinuxVm  = "vm-ubuntu-01"
$LinuxSz  = "Standard_B2s"
$LinuxImg = "Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest"
$SshKey   = Get-Content "$HOME/.ssh/azure_vm_lab_id_rsa.pub"

$WinVm    = "vm-win-01"
$WinSz    = "Standard_B2ms"
$WinImg   = "MicrosoftWindowsServer:WindowsServer:2022-datacenter:latest"
$Admin    = "azureuser"
$Pass     = ConvertTo-SecureString "P@ssw0rd-Your-Strong-Password-123!" -AsPlainText -Force
$Cred     = New-Object System.Management.Automation.PSCredential ($Admin, $Pass)
```

---

# 1) Network & RG bootstrap (shared)

### Azure CLI

```bash
az group create -n $RG -l $LOC

az network vnet create -g $RG -n $VNET --address-prefixes 10.10.0.0/16 \
  --subnet-name $SUBNET --subnet-prefixes 10.10.1.0/24

az network nsg create -g $RG -n $NSG
# Linux SSH + Web demo
az network nsg rule create -g $RG --nsg-name $NSG -n allow-ssh --priority 1001 \
  --access Allow --protocol Tcp --direction Inbound --source-address-prefixes '*' \
  --source-port-ranges '*' --destination-port-ranges 22
az network nsg rule create -g $RG --nsg-name $NSG -n allow-http --priority 1002 \
  --access Allow --protocol Tcp --direction Inbound --destination-port-ranges 80

az network public-ip create -g $RG -n $PUBIP --sku Standard --version IPv4

az network nic create -g $RG -n $NIC --vnet-name $VNET --subnet $SUBNET \
  --network-security-group $NSG --public-ip-address $PUBIP
```

### PowerShell

```powershell
New-AzResourceGroup -Name $Rg -Location $Loc

$vnet = New-AzVirtualNetwork -Name $Vnet -ResourceGroupName $Rg -Location $Loc -AddressPrefix "10.10.0.0/16"
Add-AzVirtualNetworkSubnetConfig -Name $Subnet -AddressPrefix "10.10.1.0/24" -VirtualNetwork $vnet | Set-AzVirtualNetwork

$nsg = New-AzNetworkSecurityGroup -Name $Nsg -ResourceGroupName $Rg -Location $Loc
New-AzNetworkSecurityRuleConfig -Name "allow-ssh" -NetworkSecurityGroup $nsg `
  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationPortRange 22 -Access Allow | Out-Null
New-AzNetworkSecurityRuleConfig -Name "allow-http" -NetworkSecurityGroup $nsg `
  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationPortRange 80 -Access Allow | Out-Null
$nsg | Set-AzNetworkSecurityGroup

$pip = New-AzPublicIpAddress -Name $Pip -ResourceGroupName $Rg -Location $Loc -AllocationMethod Static -Sku Standard
$subnetRef = (Get-AzVirtualNetwork -Name $Vnet -ResourceGroupName $Rg).Subnets | Where-Object {$_.Name -eq $Subnet}
$nic = New-AzNetworkInterface -Name $Nic -ResourceGroupName $Rg -Location $Loc -SubnetId $subnetRef.Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id
```

---

# 2) Create a **Linux VM** (Ubuntu) — multiple ways

### 2.1 Azure CLI (SSH key, cloud-init, tags)

`cloud-init.yaml` (install Docker + NGINX demo)

```yaml
#cloud-config
package_update: true
packages:
  - docker.io
  - nginx
runcmd:
  - systemctl enable --now docker
  - bash -lc "echo 'hello from cloud-init' > /var/www/html/index.nginx-debian.html"
```

```bash
az vm create -g $RG -n $LINUX_VM \
  --image "Canonical:0001-com-ubuntu-server-jammy:22_04-lts:latest" \
  --size $LINUX_SIZE \
  --admin-username azureuser \
  --ssh-key-values "$SSH_KEY" \
  --nics $NIC \
  --custom-data cloud-init.yaml \
  --tags $TAGS
```

### 2.2 PowerShell

```powershell
$vmCfg = New-AzVMConfig -VMName $LinuxVm -VMSize $LinuxSz |
  Set-AzVMOperatingSystem -Linux -ComputerName $LinuxVm -Credential (New-Object PSCredential("azureuser",(ConvertTo-SecureString "ignored" -AsPlainText -Force))) -DisablePasswordAuthentication |
  Set-AzVMSourceImage -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" -Skus "22_04-lts" -Version "latest" |
  Add-AzVMNetworkInterface -Id $nic.Id

# SSH public key
Add-AzVMSshPublicKey -VM $vmCfg -KeyData $SshKey -Path "/home/azureuser/.ssh/authorized_keys"

# Cloud-init
$ci = Get-Content "./cloud-init.yaml" -Raw
Set-AzVMCustomData -VM $vmCfg -CustomData $ci

New-AzVM -ResourceGroupName $Rg -Location $Loc -VM $vmCfg -Tag $Tags
```

### 2.3 Bicep (`main.bicep`)

```bicep
param location string = resourceGroup().location
param vmName string = 'vm-ubuntu-01'
param adminUser string = 'azureuser'
@secure()
param sshPubKey string
param vnetName string
param subnetName string
param nsgName string

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' existing = {
  name: 'nic-app-01' // or create inside template
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  tags: { env: 'lab', project: 'vm-lab', owner: 'atul' }
  properties: {
    hardwareProfile: { vmSize: 'Standard_B2s' }
    osProfile: {
      computerName: vmName
      adminUsername: adminUser
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUser}/.ssh/authorized_keys'
              keyData: sshPubKey
            }
          ]
        }
      }
      customData: base64(loadTextContent('cloud-init.yaml'))
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Premium_LRS' }
        diskSizeGB: 64
      }
    }
    networkProfile: {
      networkInterfaces: [
        { id: nic.id }
      ]
    }
  }
}
```

### 2.4 ARM JSON (minimal Linux)

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "adminUsername": { "type": "string" },
    "sshPubKey": { "type": "string" }
  },
  "resources": [
    {
      "type": "Microsoft.Compute/virtualMachines",
      "apiVersion": "2023-09-01",
      "name": "vm-ubuntu-01",
      "location": "[resourceGroup().location]",
      "properties": {
        "hardwareProfile": { "vmSize": "Standard_B2s" },
        "osProfile": {
          "computerName": "vm-ubuntu-01",
          "adminUsername": "[parameters('adminUsername')]",
          "linuxConfiguration": {
            "disablePasswordAuthentication": true,
            "ssh": {
              "publicKeys": [
                {
                  "path": "[format('/home/{0}/.ssh/authorized_keys', parameters('adminUsername'))]",
                  "keyData": "[parameters('sshPubKey')]"
                }
              ]
            }
          },
          "customData": "[base64(loadTextContent('cloud-init.yaml'))]"
        },
        "storageProfile": {
          "imageReference": {
            "publisher": "Canonical",
            "offer": "0001-com-ubuntu-server-jammy",
            "sku": "22_04-lts",
            "version": "latest"
          },
          "osDisk": {
            "createOption": "FromImage",
            "managedDisk": { "storageAccountType": "Premium_LRS" },
            "diskSizeGB": 64
          }
        },
        "networkProfile": {
          "networkInterfaces": [
            { "id": "[resourceId('Microsoft.Network/networkInterfaces','nic-app-01')]" }
          ]
        }
      }
    }
  ]
}
```

### 2.5 Terraform (Linux + cloud-init)

`main.tf`

```hcl
terraform {
  required_version = ">= 1.6"
  required_providers { azurerm = { source = "hashicorp/azurerm" version = "~> 3.114" } }
}
provider "azurerm" { features {} }

variable "location" { default = "eastus" }
variable "rg"       { default = "rg-vm-lab" }

data "template_file" "cloud_init" {
  template = file("${path.module}/cloud-init.yaml")
}

resource "azurerm_resource_group" "rg" {
  name     = var.rg
  location = var.location
  tags     = { env = "lab", project = "vm-lab", owner = "atul" }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-lab"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "http"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-app-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-ubuntu-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/azure_vm_lab_id_rsa.pub")
  }

  custom_data = base64encode(data.template_file.cloud_init.rendered)

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-ubuntu01"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  tags = { env = "lab", project = "vm-lab", owner = "atul" }
}
```

---

# 3) Create a **Windows VM** — multiple ways

### 3.1 Azure CLI (RDP NSG rule + Custom Script to install IIS)

`win-init.ps1`

```powershell
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value "<h1>Hello from Windows IIS</h1>"
```

```bash
# RDP rule
az network nsg rule create -g $RG --nsg-name $NSG -n allow-rdp --priority 1003 \
  --access Allow --protocol Tcp --direction Inbound --destination-port-ranges 3389

# Create Windows VM
az vm create -g $RG -n $WIN_VM \
  --image MicrosoftWindowsServer:WindowsServer:2022-datacenter:latest \
  --size $WIN_SIZE \
  --admin-username $ADMIN_USER \
  --admin-password "$ADMIN_PASS" \
  --nics $NIC \
  --tags $TAGS

# Custom Script Extension to install IIS
az vm extension set -g $RG --vm-name $WIN_VM --name CustomScriptExtension \
  --publisher Microsoft.Compute --version 1.10 \
  --settings "{\"commandToExecute\":\"powershell -ExecutionPolicy Bypass -File win-init.ps1\"}" \
  --protected-settings "{}"
```

### 3.2 PowerShell (Windows + IIS)

```powershell
$vmCfg = New-AzVMConfig -VMName $WinVm -VMSize $WinSz |
  Set-AzVMOperatingSystem -Windows -ComputerName $WinVm -Credential $Cred |
  Set-AzVMSourceImage -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2022-datacenter" -Version "latest" |
  Add-AzVMNetworkInterface -Id $nic.Id

New-AzVM -ResourceGroupName $Rg -Location $Loc -VM $vmCfg -Tag $Tags

Set-AzVMExtension -ResourceGroupName $Rg -VMName $WinVm -Name "CustomScriptExtension" `
  -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion "1.10" `
  -SettingString '{"commandToExecute":"powershell -ExecutionPolicy Bypass -File win-init.ps1"}'
```

### 3.3 Terraform (Windows + WinRM optional)

```hcl
resource "azurerm_windows_virtual_machine" "win" {
  name                = "vm-win-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2ms"
  admin_username      = "azureuser"
  admin_password      = "P@ssw0rd-Your-Strong-Password-123!"
  network_interface_ids = [azurerm_network_interface.nic.id]

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter"
    version   = "latest"
  }

  os_disk {
    name                 = "osdisk-win01"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 128
  }

  tags = { env = "lab", project = "vm-lab", owner = "atul" }
}

# Custom Script Extension
resource "azurerm_virtual_machine_extension" "iiscfg" {
  name                 = "customscript"
  virtual_machine_id   = azurerm_windows_virtual_machine.win.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  settings             = jsonencode({ commandToExecute = "powershell -ExecutionPolicy Bypass -File win-init.ps1" })
}
```

---

# 4) Useful VM **variants & options** (CLI snippets)

### 4.1 Spot VM (Linux)

```bash
az vm create -g $RG -n vm-spot-ubuntu \
  --image Ubuntu2204 --size Standard_B2s --priority Spot \
  --max-price -1 --eviction-policy Deallocate \
  --admin-username azureuser --ssh-key-values "$SSH_KEY"
```

### 4.2 Availability Set

```bash
az vm availability-set create -g $RG -n avset-app --platform-fault-domain-count 2
az vm create -g $RG -n vm-avs-01 --image Ubuntu2204 --size Standard_B2s \
  --availability-set avset-app --admin-username azureuser --ssh-key-values "$SSH_KEY"
```

### 4.3 Zone-pinned VM

```bash
az vm create -g $RG -n vm-zone-1 --image Ubuntu2204 --size Standard_B2s \
  --zone 1 --admin-username azureuser --ssh-key-values "$SSH_KEY"
```

### 4.4 Ephemeral OS disk (fast boot, stateless)

```bash
az vm create -g $RG -n vm-ephemeral --image Ubuntu2204 --size Standard_D2s_v4 \
  --ephemeral-os-disk true \
  --admin-username azureuser --ssh-key-values "$SSH_KEY"
```

### 4.5 Accelerated Networking

```bash
az network nic update -g $RG -n $NIC --accelerated-networking true
```

### 4.6 Attach Data Disks

```bash
az vm disk attach -g $RG --vm-name $LINUX_VM --new --name data1 --size-gb 64
```

### 4.7 VM from **Shared Image Gallery** (SIG)

```bash
az vm create -g $RG -n vm-sig-01 \
  --image "/subscriptions/<subid>/resourceGroups/<sigRG>/providers/Microsoft.Compute/galleries/<gallery>/images/<imageDef>/versions/1.0.0" \
  --admin-username azureuser --ssh-key-values "$SSH_KEY"
```

### 4.8 Marketplace image requiring plan (example: Windows 11 Pro)

```bash
az vm image terms accept --publisher MicrosoftWindowsDesktop --offer windows-11 --plan win11-22h2-pro
az vm create -g $RG -n vm-win11 \
  --image MicrosoftWindowsDesktop:windows-11:win11-22h2-pro:latest \
  --admin-username $ADMIN_USER --admin-password "$ADMIN_PASS"
```

### 4.9 System-assigned Managed Identity

```bash
az vm identity assign -g $RG -n $LINUX_VM
```

---

# 5) **VM Scale Sets** (VMSS) quickstarts

### 5.1 Linux VMSS with cloud-init

`vmss-cloud-init.yaml`

```yaml
#cloud-config
package_update: true
packages: [nginx]
runcmd:
  - systemctl enable --now nginx
```

```bash
az vmss create -g $RG -n vmss-nginx \
  --image Ubuntu2204 --orchestration-mode Uniform \
  --admin-username azureuser --ssh-key-values "$SSH_KEY" \
  --instance-count 2 --upgrade-policy-mode Automatic \
  --custom-data vmss-cloud-init.yaml
```

### 5.2 Windows VMSS with IIS

```bash
az vmss create -g $RG -n vmss-win-iis \
  --image MicrosoftWindowsServer:WindowsServer:2022-datacenter:latest \
  --admin-username $ADMIN_USER --admin-password "$ADMIN_PASS" \
  --instance-count 2 --upgrade-policy-mode Automatic
az vmss extension set -g $RG --vmss-name vmss-win-iis --name CustomScriptExtension \
  --publisher Microsoft.Compute --version 1.10 \
  --settings "{\"commandToExecute\":\"powershell -ExecutionPolicy Bypass Install-WindowsFeature Web-Server -IncludeManagementTools\"}"
```

---

# 6) **Custom Script Extension** (Linux examples)

### 6.1 Install Docker/Compose on Ubuntu

`install-docker.sh`

```bash
#!/usr/bin/env bash
set -e
apt-get update -y
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker azureuser
systemctl enable --now docker
```

```bash
az vm extension set -g $RG --vm-name $LINUX_VM --name CustomScript \
  --publisher Microsoft.Azure.Extensions --version 2.1 \
  --settings "{\"fileUris\":[\"https://<your-storage>/scripts/install-docker.sh\"],\"commandToExecute\":\"bash install-docker.sh\"}"
```

*(Tip: host `install-docker.sh` on Azure Storage with SAS; for quick test you can inline `commandToExecute` with a one-liner.)*

---

# 7) **Windows provisioning** helpers

### 7.1 Enable WinRM over HTTPS (for configuration tools)

```powershell
# winrm-https.ps1
winrm quickconfig -q
New-SelfSignedCertificate -DnsName localhost -CertStoreLocation Cert:\LocalMachine\My | Out-Null
Enable-PSRemoting -Force
```

### 7.2 Add local firewall rule (RDP already covered by NSG)

```powershell
New-NetFirewallRule -DisplayName "Allow HTTP 80" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 80
```

Apply via **CustomScriptExtension** just like the IIS sample.

---

# 8) **Security & best practices** (quick checklist)

* Prefer **SSH keys** for Linux; store secrets in **Key Vault** (use `--admin-password` only for demos).
* Lock down NSG source IPs (not `*`) for SSH/RDP in real environments.
* Use **Managed Identities** + **Azure RBAC** for resource access (no embedded credentials).
* For prod, consider **Azure Policy** to enforce approved SKUs/images, and **Defender for Cloud**.
* Use **Availability Zones** or **VMSS** for HA; **Proximity Placement Groups** for low latency.
* Consider **Ephemeral OS** for short-lived stateless workloads; **Ultra Disk** for high IOPS data disk.

---

# 9) Quick “destroy lab” commands (cleanup)

### Azure CLI

```bash
az group delete -n $RG --yes --no-wait
```

### PowerShell

```powershell
Remove-AzResourceGroup -Name $Rg -Force
```

---

## Want this as a ready-to-push repo?

Say “create repo” and I’ll generate:

* `/cli/` (Linux/Windows/VMSS scripts + cloud-init + PowerShell)
* `/powershell/` (Az scripts)
* `/bicep/` (main.bicep + param files)
* `/arm/` (template.json + parameters.json)
* `/terraform/` (main.tf + variables.tf + outputs.tf + README)
* `/extensions/` (install-docker.sh, win-init.ps1, winrm-https.ps1)

…and a README with step-by-step commands and screenshots checklists.


That’s the **complete, production-grade list with working examples** for creating Azure VMs across all supported ways.
