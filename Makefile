PROJECT_ID=storybooks-terraform-devops
ENV=staging
TF_ACTION?=plan
ZONE=us-central1-c

run-local:
	docker-compose up

###

create-tf-backend-bucket:
	gsutil mb -p $(PROJECT_ID) gs://$(PROJECT_ID)-terraformv2

###

terraform-reinit:
    cd terraform && \
		terraform init -backend-config="bucket=storybooks-terraform-devops-terraformv2" -reconfigure


terraform-create-workspace: 
	cd terraform && \
		terraform workspace new $(ENV)

terraform-init: 
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform init

terraform-action: 
	cd terraform && \
	  terraform workspace select $(ENV) && \
	  terraform $(TF_ACTION) \
	  -var-file="./environments/common.tfvars" \
	  -var-file="./environments/$(ENV)/config.tfvars"
	  
###
SSH_STRING=rudi_heydra@storybooks-vm-$(ENV)
OAUTH_CLIENT_ID=316019523707-6e942l11hshd1cp1o9rqq5av2m6shdmv.apps.googleusercontent.com
OAUTH_CLIENT_SECRET=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

VERSION?=latest
LOCAL_TAG=storybooks-app:$(VERSION)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)

CONTAINER_NAME=storybooks-api
DB_NAME=storybooks

ssh: 
	gcloud compute ssh $(SSH_STRING) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE)

ssh-cmd: 
	@gcloud compute ssh $(SSH_STRING) \
		--project=$(PROJECT_ID) \
		--zone=$(ZONE) \
		--command="$(CMD)"

build:
	docker build -t $(LOCAL_TAG) .

push: 
	gcloud auth configure-docker
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)

deploy:
	$(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_TAG)'
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'
	$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
			-e PORT=3000 \
			-e \"MONGO_URI=mongodb+srv://storybooks-user-$(ENV):fhadFFRGdaldaiHJUTaf@storybooks-$(ENV).9gfjc.mongodb.net/$(DB_NAME)?retryWrites=true&w=majority\" \
			-e GOOGLE_CLIENT_ID=$(OAUTH_CLIENT_ID) \
			-e GOOGLE_CLIENT_SECRET=$(OAUTH_CLIENT_SECRET) \
			$(REMOTE_TAG) \
			'