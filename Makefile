# Makefile

# Vars
ARGOCD_VERSION ?= v2.0.5
ARGOCD_NAMESPACE ?= argocd
CROSSPLANE_NAMESPACE ?= crossplane-system
CROSSPLANE_VERSION ?= latest

# Start a minikube cluster
minikube-cluster:
	minikube start

install-argocd:
	# Install ArgoCD
	kubectl create namespace $(ARGOCD_NAMESPACE)
	kubectl apply -n $(ARGOCD_NAMESPACE) -f https://raw.githubusercontent.com/argoproj/argo-cd/$(ARGOCD_VERSION)/manifests/install.yaml

	# Wait for ArgoCD server to be ready
	kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $(ARGOCD_NAMESPACE)

## Install crossplane
install-crossplane:
	# Add the Crossplane Helm repository
	helm repo add crossplane-stable https://charts.crossplane.io/stable
	helm repo update

	# Install the Crossplane Helm chart
	if [ "$(CROSSPLANE_VERSION)" = "latest" ]; then \
		helm install crossplane \
		--namespace $(CROSSPLANE_NAMESPACE) \
		--create-namespace crossplane-stable/crossplane \
		--set provider.packages='{xpkg.upbound.io/upbound/provider-aws:v0.40.0,xpkg.upbound.io/upbound/provider-gcp:v0.36.0,xpkg.upbound.io/crossplane-contrib/provider-openstack:v0.1.7}'; \
	else \
		helm install crossplane \
		--namespace $(CROSSPLANE_NAMESPACE) \
		--create-namespace crossplane-stable/crossplane \
		--version $(CROSSPLANE_VERSION) \
		--set provider.packages='{xpkg.upbound.io/upbound/provider-aws:v0.40.0,xpkg.upbound.io/upbound/provider-gcp:v0.36.0,xpkg.upbound.io/crossplane-contrib/provider-openstack:v0.1.7}'; \
	fi

	kubectl get providers

argocd-port-forward-ui:
	kubectl port-forward --address 0.0.0.0 svc/argocd-server -n argocd 8080:443

argocd-show-admin-password:
	argocd admin initial-password -n argocd

## All-in-one target
all: minikube-cluster install-argocd install-crossplane
