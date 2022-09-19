#!/bin/bash

ec2pwn-init(){
    # ASCII art
    echo """
    
    ███████╗ ██████╗██████╗ ██████╗ ██╗    ██╗███╗   ██╗
    ██╔════╝██╔════╝╚════██╗██╔══██╗██║    ██║████╗  ██║
    █████╗  ██║      █████╔╝██████╔╝██║ █╗ ██║██╔██╗ ██║
    ██╔══╝  ██║     ██╔═══╝ ██╔═══╝ ██║███╗██║██║╚██╗██║
    ███████╗╚██████╗███████╗██║     ╚███╔███╔╝██║ ╚████║
    ╚══════╝ ╚═════╝╚══════╝╚═╝      ╚══╝╚══╝ ╚═╝  ╚═══╝
                                                        

    """    

    EC2PWN_INSTANCE_NAME=$1
    EC2PWN_INSTANCE_SSHKEYS_NAME=ec2pwn_$EC2PWN_INSTANCE_NAME-sshkeys
    EC2PWN_INSTANCE_TFVARS="ec2pwn-$EC2PWN_INSTANCE_NAME-variables.tfvars"

    # Following this logic, terraform code and other crucial config data will be stored in ~/.ec2pwn
    if [ ! -d ~/.ec2pwn ] 
    then
        # initializing config dir if not exists
        echo "[*] EC2pwn initialization..."
        
        mkdir -p ~/.ec2pwn/
        

        if [ ! -d "./terraform" ]
        then 
            echo "[!] ERROR: First time initialization needs to be run in source repo."
            return 0
        fi

        # copying over terraform code for centralization
        cp -r ./terraform ~/.ec2pwn/terraform 

    fi
     

    # Create SSH key pair for EC2 instance
    echo "[*] Creating SSH keypair for $EC2PWN_INSTANCE_NAME..."
    ssh-keygen -q -b 4096 -t rsa -N "" -f ~/.ssh/$EC2PWN_INSTANCE_SSHKEYS_NAME

    # Set variables for Terraform variables.tfvars
    echo "[*] Setting EC2 variables..."
    
    cd ~/.ec2pwn/terraform 
    
    cp base_vars.tfvars $EC2PWN_INSTANCE_TFVARS
    echo "ami_name = \"$EC2PWN_INSTANCE_NAME\""                            >> $EC2PWN_INSTANCE_TFVARS
    echo "ami_key_pair_name = \"$EC2PWN_INSTANCE_SSHKEYS_NAME\""           >> $EC2PWN_INSTANCE_TFVARS
    echo "ami_pub_key = \"$(cat ~/.ssh/$EC2PWN_INSTANCE_SSHKEYS_NAME.pub)\""   >> $EC2PWN_INSTANCE_TFVARS
    
    echo "[*] Terraform applying... "
    terraform apply -var-file="$EC2PWN_INSTANCE_TFVARS" -auto-approve 

    terraform output
    
    cd -
}

ec2pwn-check(){
    # Check for AWS cli
    if ! command -v aws &> /dev/null
    then
        echo "[!] ERR: AWS cli could not be found"
        return 0
    fi
}

ec2pwn-id(){
    EC2PWN_INSTANCE_NAME=$1
    EC2PWN_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$EC2PWN_INSTANCE_NAME" "Name=instance-state-name,Values=running"\
    --output json --query 'Reservations[*].Instances[*].InstanceId' | jq .[0][0] | tr -d '"')
    echo $EC2PWN_INSTANCE_ID
}

ec2pwn-ip(){
    EC2PWN_INSTANCE_NAME=$1
    EC2PWN_INSTANCE_ID=$(ec2pwn-id $EC2PWN_INSTANCE_NAME)

    ec2pwn-check

    aws ec2 describe-instances \
    --filters \
    "Name=instance-state-name,Values=running" \
    "Name=instance-id,Values=$EC2PWN_INSTANCE_ID" \
    --query 'Reservations[*].Instances[*].[PublicIpAddress]' \
    --output text
}

ec2pwn-ssh(){
    EC2PWN_INSTANCE_NAME=$1
    EC2PWN_INSTANCE_PUBLICIP=$(ec2pwn-ip $EC2PWN_INSTANCE_NAME)
    EC2PWN_INSTANCE_SSHKEYS_NAME=ec2pwn_$EC2PWN_INSTANCE_NAME-sshkeys

    ssh -i ~/.ssh/$EC2PWN_INSTANCE_SSHKEYS_NAME -oStrictHostKeyChecking=no kali@$EC2PWN_INSTANCE_PUBLICIP
}

ec2pwn-stop(){
    EC2PWN_INSTANCE_NAME=$1
    EC2PWN_INSTANCE_ID=$(ec2pwn-id $EC2PWN_INSTANCE_NAME)

    ec2pwn-check

    aws ec2 stop-instances --instance-ids $EC2PWN_INSTANCE_ID --output table

    # Remove instance_ip 
    sed -i '/instance_ip/d' ~/.ec2pwn/$EC2PWN_INSTANCE_NAME.config
}

ec2pwn-start(){
    EC2PWN_INSTANCE_NAME=$1
    EC2PWN_INSTANCE_ID=$(ec2pwn-id $EC2PWN_INSTANCE_NAME)

    ec2pwn-check

    aws ec2 start-instances --instance-ids $EC2PWN_INSTANCE_ID --output table
}

ec2pwn-ls(){
    ec2pwn-check
   aws ec2 describe-instances --query 'Reservations[].Instances[].[Tags[?Key==`Name`]| [0].Value,State.Name,PublicIpAddress,InstanceId,InstanceType]'\
   --output table
}   


ec2pwn-rm(){
    EC2PWN_INSTANCE_NAME=$1
    EC2PWN_INSTANCE_SSHKEYS_NAME=ec2pwn_$EC2PWN_INSTANCE_NAME-sshkeys
    EC2PWN_INSTANCE_TFVARS="ec2pwn-$EC2PWN_INSTANCE_NAME-variables.tfvars"

    cd ~/.ec2pwn/terraform && terraform destroy --var-file="$EC2PWN_INSTANCE_TFVARS" && cd - && rm -i -rf ~/.ssh/$EC2PWN_INSTANCE_SSHKEYS_NAME* 
}

ec2pwn-socks(){
    # Works best with proxychains
    # [ProxyList]
    # add proxy here ...
    # meanwhile
    # defaults to "tor"
    # socks4 127.0.0.1 1337
    EC2PWN_INSTANCE_NAME=$1
    EC2PWN_INSTANCE_SSHKEYS_NAME=ec2pwn_$EC2PWN_INSTANCE_NAME-sshkeys
    
    # TODO: Get username dynamically
    ssh -N -i ~/.ssh/$EC2PWN_INSTANCE_SSHKEYS_NAME -D 1337 kali@$(ec2pwn-ip $EC2PWN_INSTANCE_NAME)
}