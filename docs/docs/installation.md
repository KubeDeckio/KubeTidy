---
title: Installation
parent: Documentation
nav_order: 1
layout: default
---

# ⚡ Installing KubeTidy

KubeTidy can be installed on **Windows, Linux, and macOS** via the **PowerShell Gallery** or **Krew** for `kubectl` users.

---

## 🖥️ Installing via PowerShell Gallery

For PowerShell users, install **KubeTidy** directly from the PowerShell Gallery:

```powershell
Install-Module -Name KubeTidy -Repository PSGallery -Scope CurrentUser
```

### 🔄 Updating KubeTidy

To update **KubeTidy** to the latest version:

```powershell
Update-Module -Name KubeTidy
```

---

## 🌍 Installing via Krew (Linux/macOS)

For Kubernetes users on **Linux and macOS**, install KubeTidy as a `kubectl` plugin using **Krew**:

### 1️⃣ Install Krew
Follow the official Krew installation guide [here](https://krew.sigs.k8s.io/docs/user-guide/setup/install/).

### 2️⃣ Install KubeTidy via Krew

```bash
kubectl krew install kubetidy
```

### 🔄 Updating KubeTidy via Krew

```bash
kubectl krew upgrade kubetidy
```

---

## 🔧 Requirements

✅ **PowerShell Version**: PowerShell 7 or higher is required.  
✅ **Additional Dependencies**: The `powershell-yaml` module is needed for YAML parsing and will be installed automatically.  
✅ **Krew for Plugin Users**: If using Krew, ensure `kubectl` and Krew are properly configured.  

---

✅ **Next Steps:** Now that KubeTidy is installed, check out the [Usage Guide](/docs/usage) to start cleaning up your Kubernetes configurations! 🚀

