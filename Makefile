.PHONY: help up down deploy clean verify-cluster verify-vela verify-app serve langfuse minimal robots build-images validate init-ollama

TERRAFORM_DIR := terraform/environments/local
CONTAINER_RUNTIME ?= podman

# App Configuration
APP_NAME_minimal := minimal-app
SERVICE_minimal := express-server
PORT_minimal := 8000
YAML_minimal := examples/minimal/vela.yaml

APP_NAME_robots := robots-app
SERVICE_robots := robots-app
PORT_robots := 7860
YAML_robots := examples/robots/vela.yaml

help:
	@echo "Usage: make <target> [APP=minimal|robots]"
	@echo ""
	@echo "Available targets:"
	@echo "  help                 Display this help message."
	@echo "  down                 Destroy the infrastructure."
	@echo "  validate             Validate Terraform configuration."
	@echo "  up                   Initialize and apply Terraform to spin up the cluster."
	@echo "  init-ollama          Initialize Ollama by pulling the required model."
	@echo "  deploy               Deploy an application. Requires APP parameter."
	@echo "  build-images         Build and load container images for robots app."
	@echo "  verify-cluster       Verify the Kind cluster is running."
	@echo "  verify-vela          Verify Vela system pods are running."
	@echo "  verify-app           Verify an application deployment. Requires APP parameter."
	@echo "  serve                Forward port to the application. Requires APP parameter."
	@echo "  langfuse             Forward port to the Langfuse dashboard."
	@echo "  clean                Alias for down."
	@echo ""
	@echo "Environment:"
	@echo "  - Terraform Directory: $(TERRAFORM_DIR)"
	@echo ""
	@echo "Example: make deploy APP=minimal"

minimal:
	@echo "Deploying and serving minimal app..."
	$(MAKE) up
	$(MAKE) deploy APP=minimal
	$(MAKE) verify-app APP=minimal
	$(MAKE) serve APP=minimal

robots:
	@echo "Deploying and serving robots app..."
	$(MAKE) up
	$(MAKE) deploy APP=robots
	$(MAKE) verify-app APP=robots
	$(MAKE) serve APP=robots

clean: down

down:
	@echo "Destroying infrastructure..."
	export KIND_EXPERIMENTAL_PROVIDER=podman && cd $(TERRAFORM_DIR) && terraform init && terraform destroy -auto-approve

validate:
	@echo "Validating Terraform configuration..."
	cd $(TERRAFORM_DIR) && terraform init -backend=false && terraform validate

up:
	@echo "Initializing and applying Terraform..."
	export KIND_EXPERIMENTAL_PROVIDER=podman && cd $(TERRAFORM_DIR) && terraform init && terraform apply -auto-approve

# Initialize Ollama by pulling the required model
init-ollama:
	@echo "Initializing Ollama..."
	@echo "Waiting for vLLM (Ollama) pod to be ready..."
	@kubectl wait --for=condition=ready pod -l app=vllm -n genai --timeout=300s
	@echo "Checking if model tinyllama exists..."
	@kubectl exec -n genai deployment/vllm -- /bin/sh -c "ollama list | grep -q 'tinyllama' && echo 'Model exists, skipping pull.' || (echo 'Model not found or update needed, pulling...' && ollama pull tinyllama)"

deploy:
	@echo "Deploying $(APP) application..."
	@if [ "$(APP)" = "robots" ]; then $(MAKE) build-images; fi
	kubectl apply -f $(YAML_$(APP))

build-images:
	@echo "Building Robots App and MCP Server images..."
	cd examples/robots/app && $(CONTAINER_RUNTIME) build -t localhost/robots-app:latest .
	cd examples/robots/mcp_server && $(CONTAINER_RUNTIME) build -t localhost/mcp/server:latest .
	@echo "Saving images to archive for Kind loading..."
	$(CONTAINER_RUNTIME) save -o robots-app.tar localhost/robots-app:latest
	$(CONTAINER_RUNTIME) save -o mcp-server.tar localhost/mcp/server:latest
	@echo "Loading images into Kind..."
	kind load image-archive robots-app.tar --name helm4genai-cluster
	kind load image-archive mcp-server.tar --name helm4genai-cluster
	@echo "Cleaning up archives..."
	rm robots-app.tar mcp-server.tar

verify-cluster:
	kubectl cluster-info --context kind-helm4genai-cluster

verify-vela:
	kubectl get pods -n vela-system

verify-app:
	@echo "Waiting for $(APP) application to be ready..."
	@echo "Waiting for pod to be created..."
	@bash -c 'for i in {1..30}; do if kubectl get pod -l app.oam.dev/name=$(APP_NAME_$(APP)) --no-headers 2>/dev/null | grep -q .; then break; fi; echo "Waiting for pod..."; sleep 2; done'
	kubectl wait --for=condition=Ready pod -l app.oam.dev/name=$(APP_NAME_$(APP)) --timeout=120s
	kubectl get application $(APP_NAME_$(APP))
	kubectl get pods -l app.oam.dev/name=$(APP_NAME_$(APP))

serve:
	@echo "Forwarding port $(PORT_$(APP)) for $(APP) App. Open http://localhost:$(PORT_$(APP))."
	@echo "Press Ctrl+C to stop."
	kubectl port-forward service/$(SERVICE_$(APP)) $(PORT_$(APP)):$(PORT_$(APP))

langfuse:
	@echo "Forwarding port 3000 for Langfuse. Open http://localhost:3000."
	@echo "Credentials: admin / admin (or as configured in Terraform)"
	kubectl port-forward -n genai service/langfuse-web 3000:3000

minimal: down validate up
	$(MAKE) deploy APP=minimal
	$(MAKE) verify-vela
	$(MAKE) verify-app APP=minimal
	$(MAKE) serve APP=minimal

robots: down validate
	$(MAKE) up
	$(MAKE) init-ollama
	$(MAKE) deploy APP=robots
	$(MAKE) verify-vela
	$(MAKE) verify-app APP=robots
	$(MAKE) serve APP=robots

# Monitoring & Debugging
status:
	@echo "=== Cluster Nodes ==="
	@kubectl get nodes
	@echo ""
	@echo "=== All Pods ==="
	@kubectl get pods -A
	@echo ""
	@echo "=== All Services ==="
	@kubectl get svc -A
	@echo ""
	@echo "=== Helm Releases ==="
	@helm list -A

watch:
	@echo "Watching All Pods..."
	@kubectl get pods -A --watch

events:
	@echo "=== Recent Cluster Events ==="
	@kubectl get events --sort-by=.metadata.creationTimestamp

logs:
	@echo "Fetching logs for $(APP) (last 50 lines)..."
	@kubectl logs -l app.oam.dev/name=$(APP_NAME_$(APP)) --all-containers=true --tail=50 -f

describe:
	@echo "Describing pods for $(APP)..."
	@kubectl describe pods -l app.oam.dev/name=$(APP_NAME_$(APP))

# Debugging helper to run an ephemeral debug pod
debug-pod:
	@echo "Launching ephemeral debug pod (curl/netshoot)..."
	@kubectl run debug-$(shell date +%s) --rm -i --tty --image nicolaka/netshoot -- /bin/bash

clean: down
