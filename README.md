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

## Configuring Input/User Locale & Timezone

To set the input/user locale and timezone according to your preferences edit the following file:

* ".\packer-Win2019\scripts\autounattend.xml"

```xml
<settings pass="specialize">
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
        <InputLocale>fr-FR</InputLocale>
        <UserLocale>fr-FR</UserLocale>
    </component>
    <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
        <TimeZone>Romance Standard Time</TimeZone>
    </component>
</settings>
```

## Default credentials

The default credentials for this VM image are:

|Username|Password|
|--------|--------|
|administrator|packer|
