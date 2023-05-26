# Deployment of a FortiGate-VM on Microsoft Azure using a FortiFlex license

## Introduction

A Terraform script to deploy a FortiGate-VM BYOL FortiFlex on Azure

## Requirements

* [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html) >= 0.12.0
* Terraform Provider AzureRM >= 2.38.0
* Terraform Provider FortiFlex >= 1.0.0

## Deployment overview

Terraform deploys the following components:

* Azure Virtual Network with 2 subnets
* One FortiGate-VM instances with 2 NICs
* Two firewall rules: one for external, one for internal.

## Deployment

To deploy the FortiGate-VM to Azure:

1. Clone the repository.
2. Customize variables in the `terraform.tfvars.example` and `variables.tf` file as needed.  And rename `terraform.tfvars.example` to `terraform.tfvars`.
3. Initialize the providers and modules:

   ```sh
   terraform init
    ```

4. Submit the Terraform plan:

   ```sh
   terraform plan
   ```

5. Verify output.
6. Confirm and apply the plan:

   ```sh
   terraform apply
   ```

7. If output is satisfactory, type `yes`.

Output will include the information necessary to log in to the FortiGate-VM instances:

```sh
##############################################################################################################
#
# FortiGate a standalone FortiGate VM
# Terraform deployment template for Microsoft Azure
#
# The FortiGate VMs are reachable via the public IP address of the load balancer.
#
# BEWARE: The state files contain sensitive data like passwords and others. After the demo clean up your
#         clouddrive directory.
#
# Deployment location: <FGT region>
# Username: <FGT username>
#
# Management FortiGate: https://<FGT Public IP>/
#
##############################################################################################################

fgt_ipaddress = <FGT Public IP>
fgt_private_ip_address_ext = <FGT Private IP port 1>
fgt_private_ip_address_int = <FGT Private IP port 2>

##############################################################################################################
```

## Destroy the instance

To destroy the instance, use the command:

```sh
terraform destroy
```

## Support

Fortinet-provided scripts in this and other GitHub projects do not fall under the regular Fortinet technical support scope and are not supported by FortiCare Support Services.
For direct issues, please refer to the [Issues](https://github.com/fortinet/fortigate-terraform-deploy/issues) tab of this GitHub project.
For other questions related to this project, contact [github@fortinet.com](mailto:github@fortinet.com).

## License

[License](https://github.com/fortinet/fortigate-terraform-deploy/blob/master/LICENSE) © Fortinet Technologies. All rights reserved.
