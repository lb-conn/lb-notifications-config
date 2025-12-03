.PHONY: help build-dev build-qa build-staging build-prd validate-dev validate-qa validate-staging validate-prd validate-all render-dev render-qa render-staging render-prd clean

# Default target
help:
	@echo "LB Notifications Config - Makefile Commands"
	@echo ""
	@echo "Build Commands:"
	@echo "  make build-dev        - Build DEV environment manifests"
	@echo "  make build-qa         - Build QA environment manifests"
	@echo "  make build-staging    - Build STAGING environment manifests"
	@echo "  make build-prd        - Build PRD environment manifests"
	@echo ""
	@echo "Validation Commands:"
	@echo "  make validate-dev     - Validate DEV environment"
	@echo "  make validate-qa      - Validate QA environment"
	@echo "  make validate-staging - Validate STAGING environment"
	@echo "  make validate-prd     - Validate PRD environment"
	@echo "  make validate-all     - Validate all environments"
	@echo ""
	@echo "Render Commands (save to files):"
	@echo "  make render-dev       - Render DEV to rendered/dev.yaml"
	@echo "  make render-qa        - Render QA to rendered/qa.yaml"
	@echo "  make render-staging   - Render STAGING to rendered/staging.yaml"
	@echo "  make render-prd       - Render PRD to rendered/prd.yaml"
	@echo ""
	@echo "Utility Commands:"
	@echo "  make clean            - Remove rendered files"
	@echo "  make check-tools      - Check if required tools are installed"

# Check if required tools are installed
check-tools:
	@echo "Checking required tools..."
	@command -v kustomize >/dev/null 2>&1 || { echo "✗ kustomize is not installed. Install with: brew install kustomize"; exit 1; }
	@echo "✓ kustomize is installed"
	@command -v kubectl >/dev/null 2>&1 || { echo "✗ kubectl is not installed. Install with: brew install kubectl"; exit 1; }
	@echo "✓ kubectl is installed"
	@command -v kubeval >/dev/null 2>&1 || { echo "⚠ kubeval is not installed (optional but recommended). Install with: brew install kubeval"; }
	@echo "✓ All required tools are installed"

# Build commands
build-dev:
	@echo "Building DEV environment..."
	@kustomize build environments/dev

build-qa:
	@echo "Building QA environment..."
	@kustomize build environments/qa

build-staging:
	@echo "Building STAGING environment..."
	@kustomize build environments/staging

build-prd:
	@echo "Building PRD environment..."
	@kustomize build environments/prd

# Validation commands
validate-dev: check-tools
	@echo "Validating DEV environment..."
	@kustomize build environments/dev > /dev/null && echo "✓ DEV kustomize build successful" || { echo "✗ DEV kustomize build failed"; exit 1; }
	@if command -v kubeval >/dev/null 2>&1; then \
		kustomize build environments/dev | kubeval --strict > /dev/null && echo "✓ DEV Kubernetes validation passed" || { echo "✗ DEV Kubernetes validation failed"; exit 1; }; \
	else \
		echo "⚠ kubeval not installed, skipping Kubernetes schema validation"; \
	fi
	@echo "✓ DEV environment validated successfully"

validate-qa: check-tools
	@echo "Validating QA environment..."
	@kustomize build environments/qa > /dev/null && echo "✓ QA kustomize build successful" || { echo "✗ QA kustomize build failed"; exit 1; }
	@if command -v kubeval >/dev/null 2>&1; then \
		kustomize build environments/qa | kubeval --strict > /dev/null && echo "✓ QA Kubernetes validation passed" || { echo "✗ QA Kubernetes validation failed"; exit 1; }; \
	else \
		echo "⚠ kubeval not installed, skipping Kubernetes schema validation"; \
	fi
	@echo "✓ QA environment validated successfully"

validate-staging: check-tools
	@echo "Validating STAGING environment..."
	@kustomize build environments/staging > /dev/null && echo "✓ STAGING kustomize build successful" || { echo "✗ STAGING kustomize build failed"; exit 1; }
	@if command -v kubeval >/dev/null 2>&1; then \
		kustomize build environments/staging | kubeval --strict > /dev/null && echo "✓ STAGING Kubernetes validation passed" || { echo "✗ STAGING Kubernetes validation failed"; exit 1; }; \
	else \
		echo "⚠ kubeval not installed, skipping Kubernetes schema validation"; \
	fi
	@echo "✓ STAGING environment validated successfully"

validate-prd: check-tools
	@echo "Validating PRD environment..."
	@kustomize build environments/prd > /dev/null && echo "✓ PRD kustomize build successful" || { echo "✗ PRD kustomize build failed"; exit 1; }
	@if command -v kubeval >/dev/null 2>&1; then \
		kustomize build environments/prd | kubeval --strict > /dev/null && echo "✓ PRD Kubernetes validation passed" || { echo "✗ PRD Kubernetes validation failed"; exit 1; }; \
	else \
		echo "⚠ kubeval not installed, skipping Kubernetes schema validation"; \
	fi
	@echo "✓ PRD environment validated successfully"

validate-all: validate-dev validate-qa validate-staging validate-prd
	@echo ""
	@echo "✓ All environments validated successfully!"

# Render commands (save to files)
render-dev:
	@mkdir -p rendered
	@echo "Rendering DEV environment to rendered/dev.yaml..."
	@kustomize build environments/dev > rendered/dev.yaml
	@echo "✓ DEV rendered to rendered/dev.yaml"

render-qa:
	@mkdir -p rendered
	@echo "Rendering QA environment to rendered/qa.yaml..."
	@kustomize build environments/qa > rendered/qa.yaml
	@echo "✓ QA rendered to rendered/qa.yaml"

render-staging:
	@mkdir -p rendered
	@echo "Rendering STAGING environment to rendered/staging.yaml..."
	@kustomize build environments/staging > rendered/staging.yaml
	@echo "✓ STAGING rendered to rendered/staging.yaml"

render-prd:
	@mkdir -p rendered
	@echo "Rendering PRD environment to rendered/prd.yaml..."
	@kustomize build environments/prd > rendered/prd.yaml
	@echo "✓ PRD rendered to rendered/prd.yaml"

# Clean rendered files
clean:
	@echo "Cleaning rendered files..."
	@rm -rf rendered
	@echo "✓ Cleaned rendered files"

# Dry-run apply (requires kubectl and cluster access)
dry-run-dev:
	@echo "Dry-running DEV environment..."
	@kustomize build environments/dev | kubectl apply --dry-run=client -f -
	@echo "✓ DEV dry-run completed"

dry-run-qa:
	@echo "Dry-running QA environment..."
	@kustomize build environments/qa | kubectl apply --dry-run=client -f -
	@echo "✓ QA dry-run completed"

dry-run-staging:
	@echo "Dry-running STAGING environment..."
	@kustomize build environments/staging | kubectl apply --dry-run=client -f -
	@echo "✓ STAGING dry-run completed"

dry-run-prd:
	@echo "Dry-running PRD environment..."
	@kustomize build environments/prd | kubectl apply --dry-run=client -f -
	@echo "✓ PRD dry-run completed"

