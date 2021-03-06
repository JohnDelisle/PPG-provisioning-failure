# Mixed-Series VMs in a PPG fail to provision reliably

Due what I understand to be PPG/ PPG API design decisions, the Terraform AzureRM Provider is unable to reliably provision two or more mixed-series VMs into a single PPG, and you are likely to encounter errors like this:

```
Error: waiting for creation of Windows Virtual Machine "data-vm10" (Resource Group "jmd-test-new"): Code="AllocationFailed" Message="Allocation failed. We do not have sufficient capacity for the requested VM size in this region. Read more about improving likelihood of allocation success at http://aka.ms/allocation-guidance"
```

This repo includes a complete example that generates the above error when provisioing a new PPG and several mixed-series VMs. 

I've raised this issue with **MS Premier Support case #2102170040000017** who brougt it to the attention of the PPG Product Team for guidance. They have acknowledged that first-party tools including the Powershell Az Module and the Az CLI, and any third-party tools (like Terraform) that are not implmenting the workaround below will fail to provision multiple mixed-series VMs into a PPG.


# Microsoft-advised workaround
 
I was provided the following workaround (my summary):

- You must use an ARM Template
- The tempalte must include the new PPG and at least one VM of each VM series that wish to use with this PPG
- You can now provision subsequent VMs into the PPG, as long as they're of the same series as the initial VMs

# Why is an ARM template required?

A support rep explained that Azure VMs are provisioned to what he called "clusters". These clusters can host a variety of VM series, but there's no guarantee that a given cluster has capacity to host VMs of every series.  Here's how I understood his explanation:  

- When you provision with a single ARM template containing the PPG and the mixed-series VMs, they're able to provision the PPG on a cluster compatible all the VM series included in the teamplate. 
- When you provision with any other mechanism, like Powershell Az or AZ CLI, the PPG is not assigned to a cluster until the first VM gets created. The Azure back-end picks a cluster with capacity and creates the PPG and VM there.  When you add your next VM, there's no way Azure could have anticipated the VM series you'd now add, meaning Azure may have created the PPG and first VM on a cluster that cannot accommodate the second VM. 

I welcome corrections from those more familiar with Azure's inner workings.


# Examples that DO NOT trigger this issue

## Bicep (ARM)

See the [./bicep](./bicep) directory for a Bicep example (pod.bicep) that successfully provisions the PPG and mixed-series VMs. This approach was recommended by MS, so I expected a successful outcome. 

# Examples that trigger this issue

## Terraform 

The [./terraform](./terraform) directory contains a Terraform example that triggers this issue.

## Powershell Az Module

The [./powershell-az](./powershell-az) directory contains a Powershell example that triggers this issue.

Here's an abbreviated example of PPG and mixed-series VM provisioning, using Powershell Az module:

```
# Works - PPG created, but not assigned to a "cluster" yet
$ppg = New-AzProximityPlacementGroup

# Works - VM created, and PPG assigned to a cluster
$vm1 = New-AzVm -ProximityPlacementGroup $ppg.id -Size Standard_B2MS

# No assurance this will work – the PPG may not be compatible with this VM series
$vm2 = New-AzVm -ProximityPlacementGroup $ppg.id -Size Standard_D8ds_v4
```


## Az CLI

The [./az-cli](./az-cli) directory contains a working example that triggers this issue. --- WORK IN PROGRESS, COMING SOON

Here's an abbreviated example of PPG and mixed-series VM provisioning, using Az CLI:

```
# Works - PPG created, but not assigned to a "cluster" yet
az ppg create

# Works - VM created, and PPG assigned to a cluster
az vm create --ppg myPPG --size Standard_B2MS

# No assurance this will work – the PPG may not be compatible with this VM series
az vm create --ppg myPPG --size Standard_D8ds_v4
```

# Issues with the MS workaround

I find the workaround problematic for several reasons:

- This workaround requires customers to abandon their chosen automation tooling.  They must use a single ARM template for critical resources central to their Azure workloads.  The VMs in PPGs are often the heart of our applications, and are the very thing we're seeking to automate using non-ARM Template approaches.
- As a result of this issue and workaround, PPGs with mixed-series VMs are not compatible with first-party MS tools like Powershell Az and Az CLI (without resorting to using these tootls to push an ARM Temaplate). 
- This has knock-on effects, in that other resources are very likely to get pulled into that ARM template due to resource interdependencies, encumbering, blocking, or preventing automation using other tools.

This should be reason enough for MS to re-think their design and implementation of PPGs.

# Proposed fix

Add an optional "VM Series list" parameter to the PPG resource.

This would inform the MS back-end to create the PPG and the VMs on a cluster compatible with all specified VM series. 

# Interesting notes
I have been able to successfully provision PPGs with mixed-series VMs using Terraform, but not reliably. Maybe I'm getting lucky, but I've had a few very simple examples work, sometimes. I've never been able to do this at-scale, where I provision more than a handful of VMs, or where I provision additional resources like data disks that drive-up the complexity and resource count.  I feel like I get "luckier" when I provision just one VM of each series into a PPG via Terraform.