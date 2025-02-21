# Skanowanie bezpieczeństwa

## Cel

Celem jest stworzenie automatycznego procesu skanowania bezpieczeństwa aplikacji, który będzie:
- Uruchamiany co tydzień
- Sprawdzał zależności pod kątem podatności
- Skanował obraz Docker
- Tworzył automatyczne PR-y z aktualizacjami bezpieczeństwa

## Krok 1 - Tworzenie workflow

Utwórz plik `.github/workflows/SecurityScans.yml`:

### 1.1 Konfiguracja wyzwalaczy

```yaml
name: Security Scans

on:
  schedule:
    - cron: '0 0 * * 1'  # Uruchomienie w każdy poniedziałek o północy
  workflow_dispatch:     # Możliwość ręcznego uruchomienia
  pull_request:
    branches: [ main ]
```

### 1.2 Dodaj przegląd zależności

Dependency review to narzędzie, które sprawdza zależności pod kątem podatności.

```yaml
jobs:
  dependency-review:
    name: Dependency Review
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Dependency Review
        uses: actions/dependency-review-action@v3
        with:
          fail-on-severity: high
          base-ref: ${{ github.event.pull_request.base.sha }}
          head-ref: ${{ github.event.pull_request.head.sha }}
```

### 1.4 Dodaj skanowanie NPM

Skanowanie NPM to narzędzie, które sprawdza zależności pod kątem podatności.

```yaml
  npm-audit:
    name: NPM Audit
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm audit
        continue-on-error: true
```

### 1.5 Dodaj skanowanie obrazu Docker

Trivy to narzędzie, które sprawdza obraz Docker pod kątem podatności.

Wymuś błąd jeśli zostanie znaleziony obraz z podatnościami, zobacz w dokumentacji [Trivy](https://github.com/aquasecurity/trivy-action).

```yaml
  docker-scan:
    name: Docker Image Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build image
        run: docker build -t weather-app .
      - uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'weather-app'
          format: table
          severity: HIGH,CRITICAL
          ignore-unfixed: true
          exit-code: 1 
```

## Krok 2 - Konfiguracja Security/Quality Scans

### 2.1 Dodaj plik konfiguracyjny

Utwórz plik `.github/dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### 2.2 Włącz Dependabot w repozytorium

1. Wybierz "Settings" > "Code security" i wybierz:
   1.  "Dependabot alerts" > "Enable"
   2.  "Dependabot security updates" > "Configure" - zobacz swój workflow
2. Przejdź do "Settings" > "Code security and analysis"

> Dependabot będzie teraz:
> - Skanował zależności co tydzień
> - Tworzył PR-y z aktualizacjami bezpieczeństwa
> - Monitorował npm, Docker i GitHub Actions

## 2.3 Włącz CodeQL

Włącz CodeQL w repozytorium:

1. Wybierz "Settings" > "Code security and analysis"
2. Włącz "Code scanning alerts"
3. Włącz "CodeQL analysis"

Przejdź do "Security" > "Code scanning" i zobacz wyniki.

## Krok 3 - Testowanie

1. Uruchom workflow ręcznie:
   - Przejdź do Actions
   - Wybierz "Security Scans"
   - Kliknij "Run workflow"

## Krok 4 - Wymuszenie polityk na branchu


Dodaj policy, które wymusza przejście workflow na zielono przed mergem.

## Weryfikacja

Upewnij się, że:
- [x] Workflow uruchamia się automatycznie co tydzień
- [x] Dependabot wykrywa podatności
- [x] NPM Audit sprawdza zależności Node.js
- [x] Trivy skanuje obraz Docker
- [x] CodeQL analizuje kod

> Więcej o bezpieczeństwie w GitHub Actions w [dokumentacji](https://docs.github.com/en/code-security).
