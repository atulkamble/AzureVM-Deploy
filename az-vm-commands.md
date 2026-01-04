```
az commands 

az cli 

az --version 

az login 

az login --tenant tenant-id 

bash - bourne again shell - 

// check tenant id from azure portal >> tenant properties 

az group create \
  --name myResourceGroup \
  --location eastus

az group create --name myResourceGroup --location eastus

az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --image Ubuntu2204 \
  --size Standard_B1s \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --os-disk-size-gb 30

az vm open-port \
  --resource-group myResourceGroup \
  --name myVM \
  --port 80

az vm open-port --resource-group myResourceGroup --name myVM --port 80

az vm extension set \
  --resource-group myResourceGroup \
  --vm-name myVM \
  --name CustomScript \
  --publisher Microsoft.Azure.Extensions \
  --settings '{
    "commandToExecute": "sudo apt update && sudo apt install -y nginx"
  }'

OR 

 1️⃣ Create settings.json 
 { 
   "commandToExecute": "sudo apt update && sudo apt install -y nginx" 
 } 
  
 2️⃣ Run command 
 az vm extension set ` 
   --resource-group myRG ` 
   --vm-name vm-ubuntu-01 ` 
   --name CustomScript ` 
   --publisher Microsoft.Azure.Extensions ` 
   --settings settings.json


http://vm-ip

az vm list 

az vm delete \
  --resource-group myResourceGroup \
  --name myVM 

az vm create \
  --resource-group myResourceGroup \
  --name MyVM \
  --image Win2022Datacenter \
  --size Standard_B2s \
  --admin-username azureadmin \
  --admin-password 'StrongPassword@123' \
  --public-ip-sku Standard \
  --os-disk-size-gb 127


az vm delete \
  --resource-group myResourceGroup \
  --name MyVM 

az group delete \
  --name myResourceGroup 


// VS Code >> azure terraform, hashicorp terraform 

powershell >> run as admin >> choco install terraform 

```


**Azure VM management commands** using **Azure CLI** and **Azure PowerShell**, as these are the two most common interfaces for Azure VM operations.

---

## 📦 Azure VM Commands

---

## ✅ Azure CLI Commands (`az`)

### 🔹 Create a Resource Group

```bash
az group create --name myResourceGroup --location eastus
```

### 🔹 Create a Virtual Machine

```bash
az vm create \
  --resource-group myResourceGroup \
  --name myVM \
  --image UbuntuLTS \
  --admin-username azureuser \
  --generate-ssh-keys
```

### 🔹 List All VMs

```bash
az vm list -o table
```

### 🔹 Start a VM

```bash
az vm start --resource-group myResourceGroup --name myVM
```

### 🔹 Stop (Deallocate) a VM

```bash
az vm stop --resource-group myResourceGroup --name myVM
```

### 🔹 Restart a VM

```bash
az vm restart --resource-group myResourceGroup --name myVM
```

### 🔹 Delete a VM

```bash
az vm delete --resource-group myResourceGroup --name myVM --yes
```

### 🔹 Open a Port (NSG Rule for VM)

```bash
az vm open-port --resource-group myResourceGroup --name myVM --port 80
```

### 🔹 Get Public IP of VM

```bash
az vm list-ip-addresses --resource-group myResourceGroup --name myVM -o table
```

---

## ✅ Azure PowerShell Commands (`Az` Module)

### 🔹 Connect to Azure

```powershell
Connect-AzAccount
```

### 🔹 Create a Resource Group

```powershell
New-AzResourceGroup -Name myResourceGroup -Location "East US"
```

### 🔹 Create a Virtual Machine

```powershell
New-AzVm `
  -ResourceGroupName "myResourceGroup" `
  -Name "myVM" `
  -Location "East US" `
  -ImageName "Win2019Datacenter"
```

### 🔹 List All VMs

```powershell
Get-AzVM
```

### 🔹 Start a VM

```powershell
Start-AzVM -ResourceGroupName "myResourceGroup" -Name "myVM"
```

### 🔹 Stop a VM

```powershell
Stop-AzVM -ResourceGroupName "myResourceGroup" -Name "myVM" -Force
```

### 🔹 Restart a VM

```powershell
Restart-AzVM -ResourceGroupName "myResourceGroup" -Name "myVM"
```

### 🔹 Delete a VM

```powershell
Remove-AzVM -ResourceGroupName "myResourceGroup" -Name "myVM"
```

### 🔹 Get Public IP of VM

```powershell
Get-AzPublicIpAddress -ResourceGroupName "myResourceGroup" | Select Name, IpAddress
```

---
