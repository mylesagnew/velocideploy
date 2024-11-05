<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#introduction">Introduction</a></li>
        <li><a href="#prerequisites">Prerequisites</a></li>
    </ul>
          <a href="#velociraptor">Velociraptor</a>
          <ul>
            <li><a href="#installation">Installation</a></li>
            <li><a href="#usage">Usage</a></li>
            <li><a href="#agent-deploy">Agent Deployment</a></li>
            <li><a href="#server-teardown">Teardown</a></li>
      </ul>
      <a href="#roadmap">Roadmap</a><p>
      <a href="#contributing">Contributing</a>
  </ol>
</details>
<!-- CREDITS -->
This deployment script is an enhanced version of @Seeps https://github.com/Seeps/VRAutomate/
<!-- GETTING-STARTED -->

<!-- INTRODUCTION -->
### Introduction


<!-- PREREQUISITES -->
### Prerequisites

Follow the guides to install requirements for Terraform, Ansible, and AWS:
1. Install Terraform for your environment: https://learn.hashicorp.com/tutorials/terraform/install-cli?in=terraform/aws-get-started#install-terraform
2. Once Terraform is setup, install AWSCLI for your environment: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
3. Install Ansible for your environment: https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-specific-operating-systems 

    > <b>For Mac:</b>
      1. Open Terminal and install Brew: 
      ```sh 
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      ```
      3. Install Ansible using Brew: 
      ```sh
      brew install ansible
      ```

5. Sign into AWS and create an access key. You will need the key and secret handy: https://console.aws.amazon.com/iam/home?#/security_credentials

6. Configure AWSCLI with your key and secret (ignore the other prompts):
   ```sh
   aws configure
   ```
   The configuration process stores your credentials in a file at ```~/.aws/credentials``` on MacOS and Linux, or ```%UserProfile%\.aws\credentials``` on Windows.

<!-- VELOCIRAPTOR -->
## Velociraptor

<!-- INSTALLATION -->
### Installation

1. Clone the repo
   ```sh
   git clone https://github.com/mylesagnew/velocideploy.git
   ```

2. Give execute permissions to the Velociraptor script:
   ```sh
   chmod +x ./velocideploy/velocideploy.sh

3. Execute the script:
   ```sh
   ./velocideploy/velocideploy.sh
   ```

<!-- USAGE -->
## Usage
1. Enter a Value: ie 'Raptor' (Without Quotes will deploy all the Infrastructure using this tag) 

2.Do you want to perform these actions?
Enter a Value: 'yes'  (If you are happy with the itemised list from Terraform)

3. Take note of IP's
aws_private_ip= ""
aws_public_ip= "" <- This address you will use for DNS A record ie raptor.mylesagnew.com

4. 
<!-- AGENT-DEPLOY -->
## Agent Deployment


<!-- SERVER-TEARDOWN -->
## Teardown


<!-- ROADMAP -->
## Roadmap
1. Get 100% Working in AWS
2. Azure Build 
3. GCP
4. Homelab K8/Docker Build

<!-- CONTRIBUTING -->
## Contributing
