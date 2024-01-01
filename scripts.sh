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
GATEKEEPER_DNS=$(terraform output -raw gatekeeper_dns)
PROXY_DNS=$(terraform output -raw proxy_dns)
TRUSTED_DNS=$(terraform output -raw trusted_host_dns)

ssh -o StrictHostKeyChecking=no -i vockey2.pem ubuntu@$STANDALONE_DNS ls

#Send the DNS to the ips.sh file
echo "MASTER_DNS=$MASTER_DNS" > ips.sh
echo "SLAVE_1_DNS=$SLAVE_1_DNS" >> ips.sh
echo "SLAVE_2_DNS=$SLAVE_2_DNS" >> ips.sh
echo "SLAVE_3_DNS=$SLAVE_3_DNS" >> ips.sh
echo "STANDALONE_DNS=$STANDALONE_DNS" >> ips.sh
echo "GATEKEEPER_DNS=$GATEKEEPER_DNS" >> ips.sh
echo "PROXY_DNS=$PROXY_DNS" >> ips.sh
echo "TRUSTED_DNS=$TRUSTED_DNS" >> ips.sh

DNS=($MASTER_DNS $SLAVE_1_DNS $SLAVE_2_DNS $SLAVE_3_DNS)
for i in "${DNS[@]}"
do
    scp -o StrictHostKeyChecking=no -i vockey2.pem ips.sh ubuntu@$i:/tmp/ips.sh
done

sleep 3m
cd ..
#Log into the master node and run the master.sh script and write it to a log file
ssh -o StrictHostKeyChecking=no -i Terraform/vockey2.pem ubuntu@$MASTER_DNS 'bash -s' < benchmarking/master.sh > master.log
ssh -o StrictHostKeyChecking=no -i Terraform/vockey2.pem ubuntu@$STANDALONE_DNS 'bash -s' < benchmarking/standalone.sh > standalone.log
cd Terraform

for ((i=1; i<=50; i++))
do
    curl -X POST -H "Content-Type: application/json" -d '{"sql": "INSERT INTO direct_table DEFAULT VALUES"}' http://$GATEKEEPER_DNS/direct
    curl -X POST -H "Content-Type: application/json" -d '{"sql": "INSERT INTO customized_table DEFAULT VALUES"}' http://$GATEKEEPER_DNS/customized
    curl -X POST -H "Content-Type: application/json" -d '{"sql": "INSERT INTO random_table DEFAULT VALUES"}' http://$GATEKEEPER_DNS/random
    sleep 5  # Adjust the sleep duration (in seconds) between requests
done

#Destroy the instances
#terraform destroy -auto-approve
