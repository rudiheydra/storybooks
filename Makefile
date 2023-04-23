PROJECT_ID=storybooks-384602
ENV=staging
ZONE=us-central1-c

run-local:
	docker-compose up

create-tf-backend-bucket:
	gsutil mb -p $(PROJECT_ID) gs://$(PROJECT_ID)-terraform-state

terraform-create-workspace: 
	cd terraform && \
		terraform workspace new $(ENV)

terraform-init: 
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform init

TF_ACTION?=plan
terraform-action: 
	cd terraform && \
	  terraform workspace select $(ENV) && \
	  terraform $(TF_ACTION) \
	  -var-file="./environments/common.tfvars" \
	  -var-file="./environments/$(ENV)/config.tfvars"
