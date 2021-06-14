#!/bin/bash

#definicao de variaveis
Chave="Nome_Chave"
subnet="nome_subrede"

#Criacao de Security Groups
sg=$(aws ec2 create-security-group \
--description "sg-ml" \
--region sa-east-1 \
--group-name sg_ml  \
--description "sg_ml")

#Criacao de regras do segurity groups
aws ec2 authorize-security-group-ingress \
 --group-name sg_ml \
  --region sa-east-1 \
 --to-port 5000 \
 --ip-protocol tcp \
 --cidr-ip 0.0.0.0/0 \
 --from-port 5000


aws ec2 authorize-security-group-ingress \
 --group-name sg_ml \
 --region sa-east-1 \
 --to-port 8000 \
 --ip-protocol tcp \
 --cidr-ip 0.0.0.0/0 \
 --from-port 8000

  aws ec2 authorize-security-group-ingress \
  --group-name sg_ml \
  --region sa-east-1 \
  --to-port 22 \
  --ip-protocol tcp \
  --cidr-ip 0.0.0.0/0 \
  --from-port 22

#Criacao da instancia
  aws ec2 run-instances \
  --image-id "ami-02e2a5679226e293c" \
  --region sa-east-1 \
  --key-name "$Chave" \
  --security-group-ids "$sg" \
  --count 1 \
  --instance-type t2.small \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Nome,Value=app-ml}]'

#Obtencao de id e ip publico da instancia criada
ip=$(aws ec2 describe-instances  --region sa-east-1  --filters "Name=tag:Nome,Values=app-ml" --query "Reservations[].Instances[].PublicIpAddress")
id=$(aws ec2 describe-instances  --region sa-east-1  --filters "Name=tag:Nome,Values=app-ml" --query "Reservations[].Instances[].Instanced")

#Instalacao de pacotes necessarios e subida do servico
ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "sudo apt-get update" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip"sudo apt-get install -y apt-transport-https" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip"sudo apt-get install -y ca-certificates" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip"sudo apt-get install -y curl" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip"sudo apt-get install -y gnupg" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "sudo apt-get install -y lsb-release git" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip"curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "sudo echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian buster stable' | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "sudo apt-get update" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "sudo apt-get install docker-ce docker-ce-cli containerd.io -y" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "git clone https://github.com/meliuz/devops-apps.git" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "sudo chmod +x /usr/local/bin/docker-compose " \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose"
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip " sudo usermod -a -G docker admin"
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "sudo systemctl restart docker"
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "cd /home/admin/devops-apps/ && make build" \
&& ssh -i "$Chave" -o StrictHostKeyChecking=no admin@$ip "cd /home/admin/devops-apps/ && make up  &" \

#Definicao do auto scalling
aws autoscaling  create-launch-configuration \
 --region sa-east-1 \
 --launch-configuration-name teste \
 --instance-id $id \
 --key-name "$Chave" \
 --instance-type t2.small

aws autoscaling create-auto-scaling-group \
--region sa-east-1 \
--auto-scaling-group-name as-ml \
--launch-configuration-name teste \
--vpc-zone-identifier  $subnet \
--max-size 5 --min-size 1

 aws autoscaling put-scaling-policy \
  --region sa-east-1 \
  --auto-scaling-group-name as-ml \
  --policy-name my-step-scale-out-policy \
  --policy-type StepScaling \
  --adjustment-type PercentChangeInCapacity \
  --metric-aggregation-type Average \
  --step-adjustments MetricIntervalLowerBound=10.0,MetricIntervalUpperBound=20.0,ScalingAdjustment=10 \
                     MetricIntervalLowerBound=20.0,MetricIntervalUpperBound=30.0,ScalingAdjustment=20 \
                     MetricIntervalLowerBound=30.0,ScalingAdjustment=30 \
  --min-adjustment-magnitude 1

aws cloudwatch put-metric-alarm --alarm-name Step-Scaling-AlarmHigh-AddCapacity \
--metric-name CPUUtilization --namespace AWS/EC2 --statistic Average \
--period 120 --evaluation-periods 2 --threshold 70 \
--comparison-operator GreaterThanOrEqualToThreshold \
--dimensions "Name=AutoScalingGroupName,Value=as-ml" 

#habilitacao do auto scalling na instancia criada
aws autoscaling attach-instances --instance-ids $id --auto-scaling-group-name as-ml

#Remocao de regra desnecessaria do Security groups
aws ec2 revoke-security-group-ingress \
--group-name "sg_ml" \
--protocol tcp --port 22 --cidr 0.0.0.0/0