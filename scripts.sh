ACCESS_KEY="$1"
SECRET_KEY="$2"
TOKEN="$3"

cd Terraform

export TF_VAR_access_key="$ACCESS_KEY"
export TF_VAR_secret_key="$SECRET_KEY"
export TF_VAR_token="$TOKEN"

#Create key pair to access the instances

terraform init
terraform apply -auto-approve

STANDALONE_DNS=$(terraform output -raw standalone_dns)
MASTER_DNS=$(terraform output -raw cluster_master_dns)
SLAVE_1_DNS=$(terraform output -json cluster_slave_dns | jq -r '.[0]')
SLAVE_2_DNS=$(terraform output -json cluster_slave_dns | jq -r '.[1]')
SLAVE_3_DNS=$(terraform output -json cluster_slave_dns | jq -r '.[2]')

ssh -o StrictHostKeyChecking=no -i vockey2.pem ubuntu@$STANDALONE_DNS ls

#Send the DNS to the ips.sh file
echo "MASTER_DNS=$MASTER_DNS" > ips.sh
echo "SLAVE_1_DNS=$SLAVE_1_DNS" >> ips.sh
echo "SLAVE_2_DNS=$SLAVE_2_DNS" >> ips.sh
echo "SLAVE_3_DNS=$SLAVE_3_DNS" >> ips.sh

#Show the DNS
cat ips.sh

#Copy the ips.sh file to the master
scp -o StrictHostKeyChecking=no -i vockey2.pem ips.sh ubuntu@$MASTER_DNS:/tmp/ips.sh
scp -o StrictHostKeyChecking=no -i vockey2.pem ips.sh ubuntu@$SLAVE_1_DNS:/tmp/ips.sh
scp -o StrictHostKeyChecking=no -i vockey2.pem ips.sh ubuntu@$SLAVE_2_DNS:/tmp/ips.sh
scp -o StrictHostKeyChecking=no -i vockey2.pem ips.sh ubuntu@$SLAVE_3_DNS:/tmp/ips.sh
#wait 5 minutes for the instances to be ready
sleep 5m


#Run master file /home/ubuntu/CloudTP3/benchmarking/standalone.sh
ssh -o StrictHostKeyChecking=no -i vockey2.pem ubuntu@$STANDALONE_DNS '/home/ubuntu/CloudTP3/benchmarking/standalone.sh'
ssh -o StrictHostKeyChecking=no -i vockey2.pem ubuntu@$MASTER_DNS '/home/ubuntu/CloudTP3/benchmarking/standalone.sh'

#Kill the instances
terraform destroy -auto-approve