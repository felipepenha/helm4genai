.PHONY: format lint all

all: format lint generate run-local

format:
	isort .
	black .

lint:
	mypy .

generate:
	uv run baml-cli generate

# Extract model from BAML file
OLLAMA_MODEL := $(shell sed -n 's/^[[:space:]]*model[[:space:]]*"\([^"]*\)".*/\1/p' baml_src/robots.baml)

run-local:
	FETCH_MODE="direct" OLLAMA_MODEL=$(OLLAMA_MODEL) VLLM_API_URL="http://localhost:11434/v1" VLLM_API_KEY="ollama" uv run python app/app.py
