ACCESS_KEY="$1"
SECRET_KEY="$2"
TOKEN="$3"

cd Terraform

export TF_VAR_access_key="$ACCESS_KEY"
export TF_VAR_secret_key="$SECRET_KEY"
export TF_VAR_token="$TOKEN"

terraform init
terraform apply -auto-approve

MASTER_DNS=$(terraform output -raw cluster_master_dns)
SLAVE_1_DNS=$(terraform output -json cluster_slave_dns | jq -r '.[0]')
SLAVE_2_DNS=$(terraform output -json cluster_slave_dns | jq -r '.[1]')
SLAVE_3_DNS=$(terraform output -json cluster_slave_dns | jq -r '.[2]')

echo "Master DNS: $MASTER_DNS"
echo "Slave 1 DNS: $SLAVE_1_DNS"
echo "Slave 2 DNS: $SLAVE_2_DNS"
echo "Slave 3 DNS: $SLAVE_3_DNS"

## SSH into master to execute master.sh
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$MASTER_DNS 'bash -s' < master.sh $MASTER_DNS $SLAVE_1_DNS $SLAVE_2_DNS $SLAVE_3_DNS