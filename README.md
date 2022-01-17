# packer-Win10

## What is packer-Win10 ?

packer-Win10 is a set of configuration files used to build automated Windows 10 virtual machine images using [Packer](https://www.packer.io/).
This Packer configuration file allows you to build images for VMware Workstation and Oracle VM VirtualBox.

## Prerequisites

* [Packer](https://www.packer.io/downloads.html)
  * <https://www.packer.io/intro/getting-started/install.html>
* A Hypervisor
  * [VMware Workstation](https://www.vmware.com/products/workstation-pro.html)
  * [Oracle VM VirtualBox](https://www.virtualbox.org/)

## How to use Packer

Commands to create an automated VM image:

To create a Windows 10 VM image using VMware Workstation use the following commands:

```sh
cd c:\packer-Win10
packer build -only=vmware-iso win10.json
```

To create a Windows 10 VM image using Oracle VM VirtualBox use the following commands:

```sh
cd c:\packer-Win10
packer build -only=virtualbox-iso win10.json
```

## Default credentials

The default credentials for this VM image are:

|Username|Password|
|--------|--------|
|administrator|packer|
