.PHONY: format lint all

all: format lint

format:
	isort .
	black .

lint:
	mypy .
