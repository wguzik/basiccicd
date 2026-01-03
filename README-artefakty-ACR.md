# Budowanie i Publikowanie Obrazów Docker do Azure Container Registry z GitHub Actions

## Wymagania

- Konto na GitHub
- Git zainstalowany lokalnie
- Konto w Azure z aktywną subskrypcją
- Wdrożona infrastruktura Azure z projektu `infra` (zawierająca Azure Container Registry)

## Cel

Celem jest zbudowanie pipeline'u w GitHub Actions, który automatycznie buduje i publikuje obrazy Docker do Azure Container Registry (ACR).

Pipeline powinien spełniać następujące wymagania:

- Uruchamiać się przy commitach do `main` - a więc po domknięciu Pull Requestu
- Budować obraz kontenera i tagować w oparciu o commit i datę merge'a
- Format tagu powinien zawierać pierwsze 8 znaków hasha commita oraz datę (yyyy-MM-dd)
- Przesyłać zbudowany obraz do Azure Container Registry

Zajrzyj do [dokumentacji GitHub Actions](https://docs.github.com/en/actions), aby dowiedzieć się więcej.

## Krok 0 - Fork repozytorium

Wykonaj fork tego repozytorium (przycisk "Fork" w prawym górnym rogu).

> Więcej o forkowaniu w [dokumentacji GitHub](https://docs.github.com/en/get-started/quickstart/fork-a-repo).

Sklonuj repozytorium na swój komputer lub cloud shell.

> Jeżeli już posiadasz fork tego repozytorium dla innego zadania, możesz nowemu nadać nową nazwę, np. `basiccicd-artefakty`.

```bash
git clone https://github.com/your-username/basiccicd
cd basiccicd
```

## Krok 1 - Wdrożenie Infrastruktury Azure (ACR)

Przed konfiguracją pipeline musisz mieć wdrożoną infrastrukturę Azure z projektu `infra`, która zawiera Azure Container Registry.

1. Przejdź do katalogu `infra`:

```bash
cd infra
```

1. Jeśli jeszcze nie wdrożyłeś infrastruktury, postępuj zgodnie z instrukcjami w [README-infra.md](README-infra.md):

```bash
# Skopiuj przykładową konfigurację
cp terraform.tfvars.example terraform.tfvars

# Edytuj terraform.tfvars i uzupełnij wartości
nano terraform.tfvars

# Wdróż infrastrukturę
terraform init
terraform plan
terraform apply
```

1. Po wdrożeniu, pobierz dane uwierzytelniające ACR:

```bash
# Pobierz nazwę ACR z outputów Terraform
ACR_NAME=$(terraform output -raw acr_name)

# Pobierz login server
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)

# Pobierz username (to samo co nazwa ACR)
ACR_USERNAME=$ACR_NAME

# Pobierz hasło
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

# Wyświetl dane (zapisz je bezpiecznie!)
echo "ACR Login Server: $ACR_LOGIN_SERVER"
echo "ACR Username: $ACR_USERNAME"
echo "ACR Password: $ACR_PASSWORD"
```

**UWAGA:** Hasło do ACR jest wrażliwe - nigdy nie commituj go do repozytorium!

1. Wróć do głównego katalogu projektu:

```bash
cd ..
```

## Krok 2 - Konfiguracja Sekretów GitHub

Dodaj dane uwierzytelniające Azure Container Registry do GitHub Secrets:

1. Przejdź do swojego repozytorium na GitHub
2. Nawiguj do Settings > Secrets and variables > Actions
3. Dodaj nowe sekrety repozytorium:
   - `ACR_USERNAME`: Nazwa Azure Container Registry (pobrana w poprzednim kroku)
   - `ACR_PASSWORD`: Hasło pobrane z Azure (z poprzedniego kroku)
   - `ACR_LOGIN_SERVER`: Login server ACR (np. `myproject-dev-acr.azurecr.io`)

## Krok 3 - Konfiguracja Zmiennych Środowiskowych GitHub

Dodaj zmienną środowiskową dla nazwy obrazu:

1. Przejdź do swojego repozytorium na GitHub
2. Nawiguj do Settings > Secrets and variables > Actions
3. Przejdź do zakładki "Variables"
4. Kliknij "New repository variable"
5. Dodaj nową zmienną:
   - Name: `IMAGE_NAME`
   - Value: nazwa-obrazu (np. "weather-app")
   - Kliknij "Add variable"

Ta zmienna będzie używana w workflow do określenia nazwy obrazu w ACR.

## Krok 4 - Tworzenie Workflow

Utwórz nowy branch:

```bash
git checkout -b artifacts-with-acr
```

Utwórz plik `.github/workflows/cd-acr.yml` i postępuj zgodnie z poniższymi krokami.  

Po każdym kroku wykonaj commit i push do repozytorium:

```bash
git add .
git commit -m "Add Docker workflow"
git push
```

### 4.1 Dodaj trigger

```yaml
name: Container image build and push to ACR

on:
  push:
    branches: [ main ]
```

### 4.2 Dodaj Job Budowania Docker

Utwórz job, który będzie:

- Pobierał kod
- Konfigurował Docker Buildx
- Logował się do Azure Container Registry

Sekcja poniżej odpowiada za logowanie się do ACR oraz uruchomienie buildu. Zauważ, że nie podajesz żadnej ścieżki do pliku.

```yaml
jobs:
  docker:
    name: Build and Push Docker Image to ACR
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Azure Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ secrets.ACR_LOGIN_SERVER }}
          username: ${{ secrets.ACR_USERNAME }}
          password: ${{ secrets.ACR_PASSWORD }}
```

Sekcja poniżej odpowiada za wygenerowanie taga, składającego się z fragmentu commit hasha i bieżącej daty.
  
```yaml
      - name: Generate image metadata
        id: meta
        run: |
          echo "DATE=$(date +'%Y-%m-%d')" >> $GITHUB_ENV
          echo "SHA=$(git rev-parse --short=8 HEAD)" >> $GITHUB_ENV

      - name: Build and push to ACR
        uses: docker/build-push-action@v6
        with:
          context: .
          push: true
          tags: ${{ secrets.ACR_LOGIN_SERVER }}/${{ vars.IMAGE_NAME }}:${{ env.SHA }}-${{ env.DATE }}
```

**Wyjaśnienie:**

- `ACR_LOGIN_SERVER` - adres rejestru ACR (np. `myproject-dev-acr.azurecr.io`)
- `IMAGE_NAME` - nazwa obrazu (np. `weather-app`)
- Tag: `{ACR_LOGIN_SERVER}/{IMAGE_NAME}:{SHA}-{DATE}` (np. `myproject-dev-acr.azurecr.io/weather-app:a1b2c3d4-2026-01-03`)

## Krok 5 - Testowanie Workflow

1. Wykonaj commit i push:

```bash
git add .
git commit -m "Add ACR workflow"
git push origin artifacts-with-acr
```

2. Stwórz pull request i go zmerge'uj do `main`.
3. Przejdź do zakładki GitHub Actions, aby monitorować uruchomienie workflow
4. Po pomyślnym zakończeniu, sprawdź swój Azure Container Registry w poszukiwaniu nowego obrazu:

```bash
# Lista obrazów w ACR
az acr repository list --name $ACR_NAME -o table

# Lista tagów dla obrazu weather-app
az acr repository show-tags --name $ACR_NAME --repository weather-app -o table

# Lub sprawdź przez Azure Portal:
# Portal > Container registries > [twój ACR] > Repositories > weather-app
```

## Krok 6 - Weryfikacja Wymagań

Upewnij się, że Twój workflow:

- [x] Uruchamia się przy push do gałęzi main
- [x] Poprawnie buduje obraz Docker
- [x] Taguje obraz hashem commita i datą (format: `{8-char-hash}-{yyyy-MM-dd}`)
- [x] Przesyła obraz do Azure Container Registry

Twój pipeline jest teraz gotowy do automatycznego budowania i publikowania obrazów Docker do ACR!

## Krok 7 - Użycie Obrazu z ACR

Po zbudowaniu obrazu możesz go użyć w swoich deploymentach:

### Lokalne uruchomienie

```bash
# Zaloguj się do ACR
az acr login --name $ACR_NAME

# Pobierz obraz
docker pull ${ACR_LOGIN_SERVER}/weather-app:{TAG}

# Uruchom kontener
docker run -p 3000:3000 ${ACR_LOGIN_SERVER}/weather-app:{TAG}
```

### Deployment do Azure Web App

```bash
# Skonfiguruj Web App do użycia obrazu z ACR
az webapp config container set \
  --name <webapp-name> \
  --resource-group <resource-group> \
  --docker-custom-image-name ${ACR_LOGIN_SERVER}/weather-app:{TAG} \
  --docker-registry-server-url https://${ACR_LOGIN_SERVER} \
  --docker-registry-server-user $ACR_USERNAME \
  --docker-registry-server-password $ACR_PASSWORD
```

### Deployment do AKS

```bash
# AKS może automatycznie pobierać obrazy z ACR w tej samej subskrypcji
# Zaktualizuj deployment.yaml:
# image: {ACR_LOGIN_SERVER}/weather-app:{TAG}

kubectl apply -f deployment.yaml
```

## Struktura Workflow

```mermaid
graph TD
    A[Workflow: CD Artifact - ACR]
    B[Job: docker]
    
    B --> C[Step: Checkout]
    B --> D[Step: Setup Buildx]
    B --> E[Step: ACR Login]
    B --> F[Step: Generate Metadata]
    B --> G[Step: Build and Push to ACR]
    
    C --> H[Action: actions/checkout@v4]
    D --> I[Action: docker/setup-buildx-action@v3]
    E --> J[Action: docker/login-action@v3]
    G --> K[Action: docker/build-push-action@v6]
    
    style A fill:#347d39,stroke:#347d39,color:#ffffff
    style B fill:#347d39,stroke:#347d39,color:#ffffff
    style C fill:#ffffff,stroke:#30363d
    style D fill:#ffffff,stroke:#30363d
    style E fill:#ffffff,stroke:#30363d
    style F fill:#ffffff,stroke:#30363d
    style G fill:#ffffff,stroke:#30363d
    style H fill:#0969da,stroke:#0969da,color:#ffffff
    style I fill:#0969da,stroke:#0969da,color:#ffffff
    style J fill:#0969da,stroke:#0969da,color:#ffffff
    style K fill:#0969da,stroke:#0969da,color:#ffffff
```

## Najczęstsze Problemy

### 1. Błąd autoryzacji ACR

**Problem:** `unauthorized: authentication required`

**Rozwiązanie:**

```bash
# Sprawdź czy admin jest włączony w ACR
az acr update --name $ACR_NAME --admin-enabled true

# Pobierz nowe hasło
az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv

# Zaktualizuj sekret ACR_PASSWORD w GitHub
```

### 2. Nieprawidłowy login server

**Problem:** `Error response from daemon: Get https://myacr.azurecr.io/v2/: unauthorized`

**Rozwiązanie:**

- Sprawdź czy `ACR_LOGIN_SERVER` zawiera pełny adres (np. `myproject-dev-acr.azurecr.io`)
- Nie dodawaj `https://` przed adresem

### 3. Quota przekroczona

**Problem:** `storage quota exceeded`

**Rozwiązanie:**

```bash
# Usuń stare obrazy
az acr repository delete --name $ACR_NAME --repository weather-app --tag {old-tag}

# Lub zwiększ SKU ACR (wymaga dodatkowych kosztów)
az acr update --name $ACR_NAME --sku Standard
```

## Dokumentacja

- [Azure Container Registry Documentation](https://learn.microsoft.com/en-us/azure/container-registry/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)
- [Azure CLI ACR Commands](https://learn.microsoft.com/en-us/cli/azure/acr)

## Powiązane README

- [README-infra.md](README-infra.md) - Wdrażanie infrastruktury Azure z ACR
- [README-deployment-webapp.md](README-deployment-webapp.md) - Deployment do Azure Web App
- [README-deployment-kubernetes.md](README-deployment-kubernetes.md) - Deployment do AKS

> Więcej szczegółów na temat struktury workflow GitHub Actions znajdziesz w [oficjalnej dokumentacji](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions)
