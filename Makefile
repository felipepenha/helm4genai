.PHONY: help up down deploy clean verify-cluster verify-app serve minimal robots build-images validate init-ollama generate-baml

generate-baml:
	cd examples/robots && $(MAKE) generate

TERRAFORM_DIR := terraform/environments/local
TERRAFORM_PROD_DIR := terraform/environments/prod
CONTAINER_RUNTIME ?= podman

# App Config
SERVICE_minimal := minimal-app
PORT_minimal := 8000

SERVICE_robots := robots-app
PORT_robots := 7860


# ... (omitted)

down:
	@echo "Destroying infrastructure..."
	export KIND_EXPERIMENTAL_PROVIDER=podman && cd $(TERRAFORM_DIR) && terraform init && terraform destroy -auto-approve

down-prod:
	@echo "Destroying production infrastructure..."
	cd $(TERRAFORM_PROD_DIR) && terraform init && terraform destroy -auto-approve

validate:
	@echo "Validating Terraform configuration..."
	cd $(TERRAFORM_DIR) && terraform init -backend=false && terraform validate

up:
	@echo "Initializing and applying Terraform..."
	export KIND_EXPERIMENTAL_PROVIDER=podman && cd $(TERRAFORM_DIR) && terraform init && terraform apply -auto-approve

OLLAMA_MODEL := $(shell sed -n 's/^[[:space:]]*model[[:space:]]*"\([^"]*\)".*/\1/p' examples/robots/baml_src/robots.baml)

init-ollama:
	@echo "Initializing Ollama..."
	@echo "Waiting for vLLM (Ollama) pod to be ready..."
	@kubectl wait --for=condition=ready pod -l app=vllm -n genai --timeout=300s
	@echo "Checking if model $(OLLAMA_MODEL) exists..."
	@kubectl exec -n genai deployment/vllm -- /bin/sh -c "ollama list | grep -q '$(OLLAMA_MODEL)' && echo 'Model exists, skipping pull.' || (echo 'Model not found or update needed, pulling...' && ollama pull $(OLLAMA_MODEL))"

deploy:
	@echo "Deploying $(APP) application..."
	@if [ "$(APP)" = "robots" ]; then $(MAKE) build-images; fi
	kubectl apply -f examples/$(APP)/k8s/

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

# verify-vela removed

verify-app:
	@echo "Waiting for $(APP) application to be ready..."
	@echo "Waiting for pod to be created..."
	@bash -c 'for i in {1..30}; do if kubectl get pod -l app=$(APP)-app --no-headers 2>/dev/null | grep -q .; then break; fi; echo "Waiting for pod..."; sleep 2; done'
	kubectl wait --for=condition=Ready pod -l app=$(APP)-app --timeout=120s
	kubectl get deployment $(APP)-app
	kubectl get pods -l app=$(APP)-app

serve:
	@echo "Forwarding port $(PORT_$(APP)) for $(APP) App. Open http://localhost:$(PORT_$(APP))."
	@echo "Press Ctrl+C to stop."
	kubectl port-forward service/$(SERVICE_$(APP)) $(PORT_$(APP)):$(PORT_$(APP))

# langfuse removed

minimal: down validate up
	$(MAKE) deploy APP=minimal
	$(MAKE) verify-app APP=minimal
	$(MAKE) serve APP=minimal

robots: down validate generate-baml
	$(MAKE) up
	$(MAKE) init-ollama
	$(MAKE) deploy APP=robots
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
	@kubectl logs -l app=$(APP)-app --all-containers=true --tail=50 -f

describe:
	@echo "Describing pods for $(APP)..."
	@kubectl describe pods -l app=$(APP)-app

# Debugging helper to run an ephemeral debug pod
debug-pod:
	@echo "Launching ephemeral debug pod (curl/netshoot)..."
	@kubectl run debug-$(shell date +%s) --rm -i --tty --image nicolaka/netshoot -- /bin/bash

clean: down
