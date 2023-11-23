SHELL := /bin/bash

# Create images: Foundry fork testing
images:
	forge test --mt test_construct_images

# Initialize the virtual environment and install dependencies
init:
	python3 -m venv venv
	source venv/bin/activate; pip install -r requirements.txt

# Run the Python script
run:
	source venv/bin/activate; python analysis/visualize.py

