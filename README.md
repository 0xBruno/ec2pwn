# ec2pwn


## What is it? 

ec2pwn is a series of bash wrapper functions around the AWS CLI & Terraform. 
It's main purpose is to simplify creating, starting, stopping, and other normal operations of an AWS EC2 instance using the Kali AMI for offensive security purposes.
It is heavily inspired by Axiom from pry0cc. But its only goal is simplifying workflows.

ec2pwn's default configuration uses the Kali AMI and a security group with ingress on port 80 from 0.0.0.0/0 and port 22 from provided /24 CIDR block.

## Usage
![image](https://user-images.githubusercontent.com/59654121/190963523-df6fad37-14fd-4f51-add9-25776e554489.png)

Setting up: 
1. Download the AWS CLI and Terraform 
2. Setup your AWS credentials 
3. Change region in terraform/main.tf if needed (Default: us-east-1)
4. Accept terms and usage for Kali AMI ami-07bd857436e5e514f and/or change if needed. 
5. Change the "CHANGEME" value in terraform/security.tf cidr_blocks to your /24 address. (Your public IP address but last octet is 0. e.g public IP 1.2.3.4 -> 1.2.3.0/24)
6. `source funcs.sh`. 

Now all the functions are built into your current shell. 

Usage: 
1. `ec2pwn-init pwnbox` will create and start a Kali AMI EC2 instance named "pwnbox". 
2. That's it. Start and stop it, use the instance as a SOCKS proxy, or whatever with the functions defined below. 


## Functions Definitions

`ec2pwn-init <instance name>` creates an AWS EC2 instance resource, a security group defined in security.tf, and an ssh keypair for use.

`ec2pwn-socks <instance name>` creates a socks proxy with ssh on port 1337 (Useful for tunneling local tools through the instance with proxychains). 

`ec2pwn-id <instance name>` retrieves the instance ID from a name.

`ec2pwn-ip <instance name>` retrieves the public IP address of the instance. 

`ec2pwn-ssh <instance name>` ssh's into the instance with the created keypair from `ec2pwn-init()`.

`ec2pwn-stop <instance name>` stops the instance.

`ec2pwn-start <instance name>` starts the instance.

`ec2pwn-rm <instance name>` terminates the instance and removes associated files created by ec2pwn.

`ec2pwn-ls` describes the instances (Useful for checking if running or not). 


