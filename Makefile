.PHONY: help up down deploy-minimal clean verify-cluster verify-vela verify-app forward serve-minimal

TERRAFORM_DIR := terraform/environments/local

help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Available targets:"
	@echo "  help                 Display this help message."
	@echo "  up                   Initialize and apply Terraform to spin up the cluster."
	@echo "  down                 Destroy the infrastructure."
	@echo "  deploy-minimal       Deploy the minimal example application."
	@echo "  verify-cluster       Verify the Kind cluster is running."
	@echo "  verify-vela          Verify Vela system pods are running."
	@echo "  verify-app           Verify the minimal application deployment."
	@echo "  forward              Forward port 8000 to the application."
	@echo "  minimal              Full pipeline for examples/minimal deployment and serving."
	@echo "  clean                Alias for down."
	@echo ""
	@echo "Environment:"
	@echo "  - Terraform Directory: $(TERRAFORM_DIR)"
	@echo ""
	@echo "Example: make up"

down:
	@echo "Destroying infrastructure..."
	export KIND_EXPERIMENTAL_PROVIDER=podman && cd $(TERRAFORM_DIR) && terraform init && terraform destroy -auto-approve

up:
	@echo "Initializing and applying Terraform..."
	export KIND_EXPERIMENTAL_PROVIDER=podman && cd $(TERRAFORM_DIR) && terraform init && terraform apply -auto-approve

deploy-minimal:
	@echo "Deploying minimal application..."
	kubectl apply -f examples/minimal/vela.yaml

verify-cluster:
	kubectl cluster-info --context kind-helm4genai-cluster

verify-vela:
	kubectl get pods -n vela-system

verify-app:
	@echo "Waiting for application to be ready..."
	kubectl wait --for=condition=Ready pod -l app.oam.dev/name=minimal-app --timeout=90s
	kubectl get application minimal-app
	kubectl get pods -l app.oam.dev/name=minimal-app

forward:
	@echo "Forwarding port 8000. Open http://localhost:8000 in your browser."
	@echo "Press Ctrl+C to stop."
	kubectl port-forward service/express-server 8000:8000

minimal: down up verify-cluster deploy-minimal verify-vela verify-app forward

clean: down
