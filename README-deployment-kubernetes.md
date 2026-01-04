# Wdrażanie Aplikacji na Kubernetes z GitHub Actions

## Wymagania

- Konto na GitHub
- Konto Azure z aktywną subskrypcją
- Git zainstalowany lokalnie
- Azure CLI (opcjonalnie)

## Cel

Celem jest zbudowanie kompletnego pipeline'u CI/CD w GitHub Actions, który:
- Buduje aplikację NodeJS
- Tworzy obraz Docker
- Publikuje obraz w Azure Container Registry
- Wdraża aplikację na klaster Kubernetes w Azure

> **💡 Dla zaawansowanych:** Po ukończeniu tego modułu możesz rozszerzyć deployment o GitOps z Argo CD. Zobacz [README-gitops.md](README-gitops.md) aby wdrożyć automatyczne synchronizacje z Git, multi-environment management i zaawansowane wzorce wdrożeń.

## Krok 0 - Przygotowanie Infrastruktury

1. Postępuj zgodnie z instrukcją w dokumencie [README-infra.md](README-infra.md), aby utworzyć wymaganą infrastrukturę w Azure, w tym klaster AKS i Azure Container Registry.

2. Po utworzeniu infrastruktury, sprawdź połączenie z klastrem Kubernetes:

```bash
RG_NAME=<nazwa-resource-group>
AKS_NAME=<nazwa-clustra>

az aks get-credentials --name $AKS_NAME --resource-group $RG_NAME

kubectl get nodes
```

## Krok 1 - Połącz GitHub ze swoją subskrypcją i nadaj odpowiednie role

### 1.1 Identity

Wykonaj kroki z [README-github-azure-auth-simple](./README-github-azure-auth-simple.md).

### 1.2 Zmienne GitHub

1. Przejdź do swojego repozytorium na GitHub
2. Nawiguj do Settings > Secrets and variables > Actions
3. Przejdź do zakładki "Variables"
4. Dodaj następujące zmienne:
   - `ACR_NAME`: Nazwa rejestru kontenerów (bez .azurecr.io)
   - `AZURE_CLUSTER_NAME`: Nazwa klastra AKS
   - `AZURE_RESOURCE_GROUP`: Nazwa grupy zasobów

> **💡 Uwaga:** Workflow używa Managed Identity z OIDC (skonfigurowanej w kroku 1.1) zamiast haseł, co jest zgodne z najlepszymi praktykami Zero Trust.

## Krok 2 - Konfiguracja ACR i wdrożenie zasobów Kubernetes

### 2.1 Podłącz ACR do klastra Kubernetes

Umożliwi to klastrowi AKS pobieranie obrazów z Azure Container Registry bez dodatkowej autoryzacji:

```bash
# Ustaw zmienne środowiskowe
export RG_NAME="<nazwa-resource-group>"
export AKS_NAME="<nazwa-klastra>"
export ACR_NAME="<nazwa-acr>"

# Podłącz ACR do AKS
az aks update --name $AKS_NAME --resource-group $RG_NAME --attach-acr $ACR_NAME
```

### 2.2 Wdróż zasoby Kubernetes

```bash
# Zamień REPLACEME na wartość ACR_NAME we wszystkich manifestach
sed -i "s/REPLACEME/$ACR_NAME/g" infra/weather_app_manifests/*.yaml
```

Zamiast aplikować każdy manifest osobno, użyj pojedynczej komendy dla całego katalogu:

```bash
# Wdróż wszystkie manifesty jedną komendą
kubectl apply -f infra/weather_app_manifests/
```

> **💡 Wskazówka:** Komenda `kubectl apply -f <katalog>/` automatycznie aplikuje wszystkie pliki YAML w katalogu. Jest to prostsze i szybsze niż wykonywanie osobnych komend dla każdego pliku.

Weryfikacja wdrożenia:

```bash
# Sprawdź czy wszystkie zasoby zostały utworzone
kubectl get all -n weather-app
```

## Krok 3 - Konfiguracja Wyzwalacza Między Przepływami

### 3.1 Modyfikacja cd-acr.yml

Zmodyfikuj plik `.github/workflows/cd-acr.yml`, aby dodać wyzwalacz dla przepływu wdrażania na Kubernetes po pomyślnym zbudowaniu obrazu Docker w ACR:

```yaml   
      - name: Trigger Kubernetes deployment workflow
        if: success() && github.ref == 'refs/heads/main' && github.event_name == 'push'
        uses: actions/github-script@v6
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            await github.rest.actions.createWorkflowDispatch({
              owner: context.repo.owner,
              repo: context.repo.repo,
              workflow_id: 'cd-kubernetes.yml',
              ref: 'main',
              inputs: {
                image_tag: '${{ env.SHA }}-${{ env.DATE }}'
              }
            })
```

> **💡 Uwaga:** Upewnij się, że w ustawieniach repozytorium (Settings > Actions > General > Workflow permissions) masz włączone "Read and write permissions".

### 3.2 Tworzenie Workflow Deployment

Utwórz nowy branch:

```bash
git checkout -b k8s-deployment
```

Utwórz plik `.github/workflows/cd-kubernetes.yml` z poniższą zawartością:

```yaml
name: CD Kubernetes Deployment

on:
  workflow_dispatch:
    inputs:
      image_tag:
        description: 'Tag obrazu Docker do wdrożenia'
        required: true

env:
  APP_NAME: weather-app
  REGISTRY_NAME: ${{ vars.ACR_NAME }}
  CLUSTER_NAME: ${{ vars.AZURE_CLUSTER_NAME }}
  RESOURCE_GROUP: ${{ vars.AZURE_RESOURCE_GROUP }}

permissions:
  id-token: write
  contents: read

jobs:
  deploy-to-kubernetes:
    name: Deploy to Kubernetes
    runs-on: ubuntu-latest
    
    permissions:
      id-token: write
      contents: read
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        
      - name: Set image tag from input
        id: image-tag
        run: echo "IMAGE_TAG=${{ github.event.inputs.image_tag }}" >> $GITHUB_OUTPUT
        
      - name: Login to Azure
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
          
      - name: Get AKS credentials
        uses: azure/aks-set-context@v3
        with:
          resource-group: ${{ env.RESOURCE_GROUP }}
          cluster-name: ${{ env.CLUSTER_NAME }}
      
      - name: Setup kubectl
        uses: azure/setup-kubectl@v4
          
      - name: Deploy to Kubernetes
        uses: Azure/k8s-deploy@v5
        with:
          action: deploy
          namespace: weather-app
          manifests: |
            infra/weather_app_manifests/deployment.yaml
          images: |
            ${{ vars.ACR_NAME }}.azurecr.io/${{ env.APP_NAME }}:${{ steps.image-tag.outputs.IMAGE_TAG }}
          
      - name: Verify deployment
        run: |
          kubectl get pods,svc,ingress -n weather-app
```

> **💡 Uwaga:** Ten workflow jest uruchamiany automatycznie przez workflow budowania obrazu (`cd-acr.yml`). Możesz również uruchomić go ręcznie z zakładki Actions, podając tag obrazu do wdrożenia.

## Krok 4 - Testowanie Flow Wdrażania

1. Wykonaj commit i push zmian:
```bash
git add .
git commit -m "Add Kubernetes deployment workflow with automated trigger"
git push --set-upstream origin k8s-deployment
```

2. Utwórz Pull Request i przeprowadź merge do main
3. Przepływ `cd-acr.yml` powinien się uruchomić, zbudować i opublikować obraz Docker w ACR
4. Po pomyślnym zakończeniu, automatycznie powinien uruchomić się przepływ `cd-kubernetes.yml`
5. Obserwuj oba przepływy w zakładce Actions na GitHub
6. Po zakończeniu wdrożenia, sprawdź status zasobów w klastrze Kubernetes:

```bash
kubectl get pods,svc,ing -n weather-app
```

W wynikach znajdziesz m.in adres IP, otwórz stronę i zobacz czy widzisz Weather App.

## Krok 5 - Przygotuj obrazy blue/green deployment

- stwórz nowy branch `k8s-blue-green`

- Pobierz obraz blue
  
  Pobierz nazwę obrazu z pipeline, ACR lub przez podejrzenie definicji deploymentu:  

  ```bash
  kubectl get deployment -n weather-app -o=jsonpath='{.items[0].spec.template.spec.containers[0].image}'
  ```

- Podmień definicję kolorów 

  ```bash
  # W katalogu projektu
  cp public/styles-green.css public/styles.css
  
  git add public/styles.css
  
  git commit -m "Aktualizacja stylu na wersję Green"
  
  git push
  ```

- Stwórz pull request. Zauważ, że zmiana spowoduje automatyczne wdrożenie na środowisko - przerwij flow zaraz po zbudowaniu obrazu
- Pobierz nazwę obrazu green - poznasz ją po commit hash

## Krok 6 - Przygotuj zasoby kubernetes pod blue/green
  
 - w plikach
    - `infra/weather_app_manifests/deployment-blue.yaml`
    - `infra/weather_app_manifests/deployment-green.yaml`  
   zmień nazwy obrazów na właściwe

- wdróż zasoby kubernetes

  ```bash
  kubectl apply -f infra/weather_app_manifests/deployment-blue.yaml
  kubectl apply -f infra/weather_app_manifests/deployment-green.yaml
  kubectl apply -f infra/weather_app_manifests/service-blue-green.yaml
  kubectl apply -f infra/weather_app_manifests/ingress-blue-green.yaml
  kubectl apply -f infra/weather_app_manifests/service-green-test.yaml
  ```

- zweryfikuj czy aplikacja jest wdrożona

```bash
kubectl get pods -n weather-app -l version=blue

kubectl get pods -n weather-app -l version=green
```

_- zweryfikuj `<IP>/green` czy widzisz aplikację we właściwej wersji i czy działa - krok nie działa!_

- Lub zrób port forward (tylko lokalna maszyna):

```bash
kubectl -n weather-app port-forward svc/weather-app-green-test 8080:80
```

## Krok 7 - Wskaż na green deployment

- przełącz wskazanie na service

```bash
kubectl patch service weather-app-blue-green -n weather-app -p '{"spec":{"selector":{"version":"green"}}}'
```

- zeskaluj pody blue

```bash
kubectl -n weather-app scale deployment weather-app blue --replicas=0
```

## Krok 8 - Zasymuluj canary deployment

- wskaż na service zarówno blue, jak i green
- zeskaluj liczbę podów w green do 1, a w blue wyskaluj do 4

## Szczegóły Implementacji

Pipeline CI/CD składa się z dwóch oddzielnych workflow:

1. **cd-acr.yml** (Build i Publikacja):
   - Buduje aplikację NodeJS
   - Uruchamia testy
   - Buduje obraz Docker
   - Taguje go z użyciem 8-znakowego hasha commita i daty (YYYY-MM-DD)
   - Publikuje obraz w Azure Container Registry
   - Wyzwala workflow wdrożenia na Kubernetes

2. **cd-kubernetes.yml** (Deployment):
   - Przyjmuje tag obrazu jako parametr wejściowy
   - Loguje się do Azure i uzyskuje dostęp do klastra AKS
   - Wdraża aplikację na Kubernetes używając określonego obrazu
   - WerIP
     - Ingress dla dostępu zewnętrznego
   - Wdraża aplikację i weryfikuje status wdrożenia

### Zaawansowane Funkcje

1. **Zarządzanie sekretami**:
   - Klucz API jest przechowywany jako sekret Kubernetes
   - Service Principal jest przechowywany w GitHub Secrets

2. **Optymalizacja buildów**:
   - Wykorzystanie Docker Buildx i cache'owania w GitHub Actions
   - Przekazywanie tylko niezbędnych plików jako artefaktów

3. **Zarządzanie zasobami Kubernetes**:
   - Ustawienie limitów zasobów dla kontenerów
   - Konfiguracja readiness i liveness probes
   - Użycie replicas dla wysokiej dostępności

4. **Obsługa błędów**:
   - Weryfikacja statusu wdrożenia z timeoutem
   - Idempotentne tworzenie namespaces i sekretów

## Diagram Workflow

```Kompletny Diagram Przepływu CI/CD

```mermaid
graph TD
    A[Push do main] --> B[Workflow: CD ACR - Build & Push]
    B --> C[Build i publikacja obrazu Docker]
    C --> D[Trigger workflow_dispatch]
    D --> E[Workflow: CD Kubernetes Deployment]
    E --> F[Pobierz credentials AKS]
    F --> G[Wdrożenie na Kubernetes]
    G --> H[Weryfikacja wdrożenia]
    
    style A fill:#f9f,stroke:#333,stroke-width:2px
    style B fill:#347d39,stroke:#347d39,color:#ffffff
    style C fill:#ffffff,stroke:#30363d
    style D fill:#ff9900,stroke:#ff9900,color:#ffffff
    style E fill:#347d39,stroke:#347d39,color:#ffffff
    style F fill:#ffffff,stroke:#30363d
    style G fill:#ffffff,stroke:#30363d
    style H
## Najczęstsze Problemy

1. **Problem z poświadczeniami**: Upewnij się, że Service Principal ma odpowiednie uprawnienia do ACR i AKS.
2. **Błędy budowania**: Sprawdź logi w GitHub Actions, aby zobaczyć szczegóły błędów.
3. **Problemy z Ingress**: Sprawdź, czy kontroler Ingress jest poprawnie zainstalowany w klastrze.
4. **Timeout podczas wdrożenia**: Może być spowodowany problemami z zasobami klastra lub błędami w konfiguracji.

## Weryfikacja Wdrożenia

Po zakończeniu wdrożenia możesz zweryfikować działanie aplikacji:

1. Znajdź adres Ingress:
```bash
kubectl get ingress weather-app-ingress -n weather-app
```

2. Otwórz przeglądarkę i przejdź pod adres podany w kolumnie ADDRESS
3. Możesz również sprawdzić logi aplikacji:
```bash
kubectl logs -l app=weather-app -n weather-app
```

## Następne Kroki

### Automatyzacja z GitOps (Zaawansowane)

W tym module używaliśmy `kubectl apply` w GitHub Actions do wdrażania aplikacji. Alternatywnym, bardziej zaawansowanym podejściem jest **GitOps z Argo CD**, które oferuje:

**Deklaratywne zarządzanie** - Git jako single source of truth  
**Automatyczna synchronizacja** - Argo CD wykrywa zmiany w repo i automatycznie aktualizuje klaster  
**Self-healing** - Automatyczne cofanie ręcznych zmian w klastrze  
**Multi-environment** - Łatwe zarządzanie dev/staging/prod  
**Drift detection** - Wykrywanie różnic między Git a klastrem  
**Rollback** - Łatwy powrót do poprzednich wersji

Aby wdrożyć GitOps, zobacz **[README-gitops.md](README-gitops.md)** (~2h, poziom średnio-zaawansowany).

## Dokumentacja

- [GitHub Actions](https://docs.github.com/en/actions)
- [Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Docker Buildx](https://docs.docker.com/engine/reference/commandline/buildx/)
- [GitOps with Argo CD](https://argo-cd.readthedocs.io/) - dla zaawansowanych
