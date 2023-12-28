ACCESS_KEY="$1"
SECRET_KEY="$2"
TOKEN="$3"

cd Terraform

export TF_VAR_access_key="$ACCESS_KEY"
export TF_VAR_secret_key="$SECRET_KEY"
export TF_VAR_token="$TOKEN"

terraform init
terraform destroy -auto-approve