# Basic CI CD

## Wymagania

Konto na GitHub (no właśnie! ;)).

Konto w Azure lub zainstalowane IDE (np. VSCode) oraz git lokalnie.

## Cel

Repozytorium zawiera materiały szkoleniowe dla CI/CD z wykorzystaniem GitHub Actions i Azure.

### Moduły Szkoleniowe

#### CI - Continuous Integration (~3 godziny)
- [Zbudowanie CI](./README-ci.md) - podstawowy pipeline CI
- [Dodanie skanów bezpieczeństwa](./README-security.md) - security scanning
- [Publikacja artefaktów](./README-artefakty.md) - Docker Hub integration

#### CD - Continuous Deployment (~12 godzin)
- [Zbudowanie infrastruktury](./README-infra.md) - Terraform + Azure (~2-3h)
- [Deployment na Kubernetes](./README-deployment-kubernetes.md) - AKS + Blue/Green (~3-4h)
- [Deployment na Web App](./README-deployment-webapp.md) - Slot swaps (~2-3h)
- [GitOps z Argo CD](./README-gitops.md) - Automated GitOps workflows (~2h)

**Uwaga:** Moduł GitOps (README-gitops.md) jest przeznaczony dla uczestników średnio-zaawansowanych do zaawansowanych.
