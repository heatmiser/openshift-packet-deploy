# OpenShift via Terraform on Packet
This collection of modules will deploy a bare metal [OpenShift](https://docs.openshift.com/container-platform/latest/installing/installing_bare_metal/installing-bare-metal.html) consisting of (1) ephemeral bootstrap node, (3) control plane nodes, and a user-configured count of worker nodes<sup>[1](#3nodedeployment)</sup> on [Packet](http://packet.com). DNS records are automatically configured using [Cloudflare](http://cloudflare.com).

## Install Terraform
Terraform is just a single binary.  Visit their [download page](https://www.terraform.io/downloads.html), and follow the link [download older versions of Terraform](https://releases.hashicorp.com/terraform/). Choose the latest 0.12.x release and then select the download link that corresponds to your operating system. Unzip the download, move the terraform binary into your path and make the binary executable.

Here is an example for **macOS**:
```bash
curl -LO https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_darwin_amd64.zip
unzip terraform_0.12.29_darwin_amd64.zip
chmod +x terraform
sudo mv terraform /usr/local/bin/
```
Example for **Linux**:
```bash
wget https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip
unzip terraform_0.12.29_linux_amd64.zip
sudo install terraform /usr/local/bin/
```
### Additional requirements

`local-exec` provisioners require the use of:
  - `curl`
  - `jq`

To install `jq` on **RHEL/CentOS**:
```bash
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
sudo install jq-linux64 /usr/local/bin/jq
```
To install `jq` on **Debian/Ubuntu**:
```bash
sudo apt-get install jq
```

## Download this project

To download this project, run the following command:
```bash
git clone https://github.com/heatmiser/openshift-packet-deploy.git
cd openshift-packet-deploy/terraform
```

## Usage

1. Follow [this](PACKET.md) to configure your Packet Public Cloud project and collect required parameters.

2. Follow [this](CLOUDFLARE.md) to configure your Cloudflare account and collect required parameters.

3. [Obtain an OpenShift Cluster Manager API Token](https://cloud.redhat.com/openshift/token) for pullSecret generation.
  
4. For variables, you have two options:
  1) export variables in the currently active shell
  2) create a tfvars file that contains all of the requisite values

  1) If you choose to export variables in the currently active shell:
    Configure TF_VARs applicable to your Packet project, Cloudflare zone, and OpenShift API Token:
     ```bash
     export TF_VAR_project_id="kajs886-l59-8488-19910kj"
     export TF_VAR_auth_token="lka6702KAmVAP8957Abny01051"
     
     export TF_VAR_cf_email="yourcfmail@domain.com"
     export TF_VAR_cf_api_key="21df29762169c002ca656"
     export TF_VAR_cf_zone_id="706767511sf7377900"

     export TF_VAR_cluster_basedomain="domain.com"
     export TF_VAR_ocp_cluster_manager_token="eyJhbGc...d8Agva"
     ```

  2) The instructions from here going forward will be using a tfvars file that will be populated with all of the requisite values.  If you do not wish to go this route, simply export all necessary variable as outline in (1) above and leave out all of the referals to the tfavrs file in the command line entries that follow.

  The base of the project directory contains a couple of example tfvars files:

    00cnvlab.tfvars.example - good configuration for OpenShift virtualization work
    00small.tfvars.example - minimal deployment, good for testing deployment automation

  Copy one of the example files to a tfvars filename, ie:
     ```bash
     cp 00cnvlab.tfvars.example 00cnvlab.tfvars
     ```
  ...and then edit 00cnvlab.tfvars with all of the correct user, authentication, project and settings

5. Initialize and validate terraform:
     ```bash
     terraform init
     terraform validate
     ```

 6. Produce a terraform deploy plan, which will create .tfplan file (file name with date/time):
     ```bash
     terraform plan -out=cnvlab-deploy-$(date +%Y-%m-%d.%H%M).tfplan -var-file="00cnvlab.tfvars"
     ```
    ...followed by applying the plan:
    ```bash
     terraform apply "cnvlab-2020-09-14.0217.tfplan"   <== tfplan file name time/date specific
     ```
    
    All resources will be created and installation launched. This process takes between 30 and 50 minutes to complete: 

 7. Once provisioning and installation process is complete, the bootstrap node can be removed by permanently (recommended) or temporarily setting `count_bootstrap=0`
     ```bash
     terraform plan -out=rm-bootstrap-$(date +%Y-%m-%d.%H%M).tfplan -var-file="00cnvlab.tfvars" -var="count_bootstrap=0"
     terraform apply "rm-bootstrap-2020-09-14.0309.tfplan"
     ```
     If you need to obtain any of the output values of the deployment at a later time, for example,your `kubeadmin` credentials:
     ```
     terraform output
     ```

---

<a name="3nodedeployment"><sup>1</sup></a> As of OpenShift Container Platform 4.5 you can [deploy three-node clusters on bare metal](https://docs.openshift.com/container-platform/4.5/installing/installing_bare_metal/installing-bare-metal.html#installation-three-node-cluster_installing-bare-metal). Setting `count_compute=0` will support deployment of a 3-node cluster. [↩](#openshift-via-terraform-on-packet)