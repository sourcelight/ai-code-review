# Guida al Sistema di Code Review AI

## 📋 Indice

1. [Introduzione](#introduzione)
2. [Architettura del Sistema](#architettura-del-sistema)
3. [Flusso Operativo Dettagliato](#flusso-operativo-dettagliato)
4. [Regole di Revisione](#regole-di-revisione)
5. [Configurazione](#configurazione)
6. [Esempi Pratici](#esempi-pratici)
7. [Risoluzione Problemi](#risoluzione-problemi)

---

## Introduzione

Il sistema di **Code Review AI** automatizza la revisione del codice utilizzando **Claude Sonnet 4** di Anthropic. Ogni volta che viene creata o aggiornata una Pull Request su GitHub, il sistema:

✅ Analizza le modifiche al codice  
✅ Applica regole specifiche per React, Java e Security  
✅ Genera un commento di revisione dettagliato  
✅ Identifica problemi critici, medi e minori  

**Costo stimato:** €0,10 - €0,30 per revisione

---

## Architettura del Sistema

### Diagramma Generale

```
┌─────────────────────────────────────────────────────────────────┐
│                         GITHUB REPOSITORY                        │
│                                                                   │
│  Developer → Push Code → Pull Request Created/Updated            │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Trigger
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GITHUB ACTIONS WORKFLOW                     │
│                  (.github/workflows/ai-review.yml)               │
│                                                                   │
│  Step 1: Checkout del codice                                     │
│  Step 2: Calcola il diff (modifiche rispetto al branch base)    │
│  Step 3: Carica le regole di revisione                          │
│  Step 4: Chiama API Anthropic con Claude                        │
│  Step 5: Pubblica commento con la revisione                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ API Call
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ANTHROPIC CLAUDE API                        │
│                     (claude-sonnet-4-6)                          │
│                                                                   │
│  Riceve: Diff + Regole di Revisione                             │
│  Analizza: Codice secondo le linee guida                        │
│  Ritorna: Revisione strutturata in markdown                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ Response
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    COMMENTO SULLA PULL REQUEST                   │
│                                                                   │
│  🤖 AI Code Review                                               │
│  ├─ Overall Assessment                                           │
│  ├─ Critical Issues                                              │
│  ├─ Medium Issues                                                │
│  ├─ Minor Issues                                                 │
│  ├─ Suggested Improvements                                       │
│  └─ Positive Observations                                        │
└─────────────────────────────────────────────────────────────────┘
```

### Componenti Principali

```
Repository Structure:
│
├── .github/
│   ├── workflows/
│   │   ├── ai-review.yml              ← Workflow principale (ATTIVO)
│   │   └── ai-review-debug.yml        ← Workflow debug (solo manuale)
│   │
│   └── ai-review/                      ← Regole di revisione
│       ├── react-review.md            ← Regole React/TypeScript
│       ├── java-review.md             ← Regole Java/Spring Boot
│       └── security-review.md         ← Regole di sicurezza OWASP
│
├── backend/                            ← Codice Java da revisionare
├── frontend/                           ← Codice React da revisionare
└── CLAUDE.md                           ← Documentazione del progetto
```

---

## Flusso Operativo Dettagliato

### Passo 1: Trigger del Workflow

```
Developer Actions                    GitHub Actions Trigger
─────────────────                    ──────────────────────

git checkout -b feature/nuova-funzione
git add .
git commit -m "Aggiunta feature X"
git push origin feature/nuova-funzione
                                     
Apre Pull Request su GitHub    →    workflow: ai-review.yml
                                     trigger: pull_request
                                     types: [opened, synchronize, reopened]
```

**Eventi che attivano il workflow:**
- `opened` - PR appena creata
- `synchronize` - Nuovi commit aggiunti alla PR
- `reopened` - PR riaperta dopo chiusura

### Passo 2: Checkout e Calcolo Diff

```yaml
# Step nel workflow: Get PR diff

┌──────────────────────────────────────┐
│  git fetch origin main               │  ← Scarica il branch base
│  git diff origin/main...HEAD         │  ← Calcola le differenze
└──────────────────────────────────────┘
                 │
                 ▼
         ┌──────────────┐
         │  DIFF OUTPUT │
         └──────────────┘
                 │
                 ▼
    +++ frontend/src/Login.tsx
    @@ -15,6 +15,10 @@
    +  const [error, setError] = useState('');
    +  
    +  if (!email) {
    +    setError('Email required');
    +  }
```

**Cosa contiene il diff:**
- File modificati
- Linee aggiunte (+)
- Linee rimosse (-)
- Contesto delle modifiche

### Passo 3: Caricamento Regole

```
File di Regole                      Caricamento in Memoria
──────────────                      ──────────────────────

react-review.md     →  REACT_RULES     (variabile ambiente)
java-review.md      →  JAVA_RULES      (variabile ambiente)
security-review.md  →  SECURITY_RULES  (variabile ambiente)
```

**Struttura di una regola (esempio):**

```markdown
## Gestione Errori

### Cosa verificare:
- [ ] Try-catch attorno alle chiamate async
- [ ] Messaggi di errore user-friendly
- [ ] Stati di loading gestiti

### Esempio Corretto:
```typescript
try {
  const data = await api.get('/endpoint');
  setData(data);
} catch (error) {
  setError('Impossibile caricare i dati');
}
```

### Passo 4: Costruzione del Prompt per Claude

```
┌────────────────────────────────────────────────────────────────┐
│                      PROMPT COMPLETO                            │
├────────────────────────────────────────────────────────────────┤
│                                                                  │
│  "You are an expert code reviewer."                             │
│                                                                  │
│  ## React Frontend Review Guidelines                            │
│  [Contenuto di react-review.md]                                │
│                                                                  │
│  ## Java Backend Review Guidelines                              │
│  [Contenuto di java-review.md]                                 │
│                                                                  │
│  ## Security Review Guidelines                                  │
│  [Contenuto di security-review.md]                             │
│                                                                  │
│  ## Pull Request Diff                                           │
│  ```diff                                                        │
│  [Output del git diff]                                          │
│  ```                                                            │
│                                                                  │
│  Please provide review in this format:                          │
│  - Overall Assessment                                           │
│  - Critical Issues                                              │
│  - Medium Issues                                                │
│  - Minor Issues                                                 │
│  - Suggested Improvements                                       │
│  - Positive Observations                                        │
└────────────────────────────────────────────────────────────────┘
```

### Passo 5: Chiamata API Anthropic

```
Request                                Response
───────                                ────────

POST https://api.anthropic.com/v1/messages
Headers:
  - content-type: application/json
  - x-api-key: [ANTHROPIC_API_KEY]
  - anthropic-version: 2023-06-01

Body:                                  {
{                                        "id": "msg_...",
  "model": "claude-sonnet-4-6",         "type": "message",
  "max_tokens": 4096,                   "content": [{
  "messages": [{                          "type": "text",
    "role": "user",                       "text": "# Code Review Summary\n\n
    "content": "[prompt]"                          ## Overall Assessment\n
  }]                                               The changes improve..."
}                                       }]
                                      }
                                      
                                      ↓
                                      
                            Estrazione del testo della review
                            con jq: .content[0].text
```

### Passo 6: Pubblicazione Commento

```
Review Text                         GitHub Comment API
───────────                         ──────────────────

# Code Review Summary              POST /repos/{owner}/{repo}/issues/{pr_number}/comments
                                   
## Overall Assessment      →       Body: "🤖 AI Code Review\n\n[review_text]"
[...]                              
                                   Result: Commento pubblicato sulla PR
## Critical Issues                 visibile a tutti i membri del team
[...]
```

---

## Regole di Revisione

### Come Funzionano le Regole

Le regole sono file **Markdown** che istruiscono Claude su cosa verificare. Claude legge queste regole prima di analizzare il codice.

```
┌─────────────────────┐
│   DEVELOPER CREA    │
│   REGOLE CUSTOM     │
│   IN .md FILE       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  WORKFLOW CARICA    │
│  REGOLE IN MEMORIA  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  CLAUDE APPLICA LE  │
│  REGOLE AL CODICE   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  REPORT GENERATO    │
│  SECONDO LE REGOLE  │
└─────────────────────┘
```

### Struttura Regole

#### 1. **React Review** (`.github/ai-review/react-review.md`)

```markdown
# React/TypeScript Best Practices

## 1. Hooks Usage
- Verifica che useState/useEffect siano usati correttamente
- Controlla le dependency arrays
- Evita hooks condizionali

## 2. Type Safety
- Tutti i props devono avere tipi TypeScript
- Evitare 'any' type
- Usare interface per oggetti complessi

## 3. Error Handling
- Try-catch per operazioni async
- Gestione stati di errore nell'UI
- Loading states per fetch API
```

#### 2. **Java Review** (`.github/ai-review/java-review.md`)

```markdown
# Java/Spring Boot Best Practices

## 1. Dependency Injection
- Usare constructor injection (NO @Autowired su field)
- Preferire final per le dipendenze

## 2. Business Logic
- Logica business solo nei service
- Controller devono essere thin
- Usare DTO per API contracts

## 3. SOLID Principles
- Single Responsibility
- Open/Closed Principle
- Dependency Inversion
```

#### 3. **Security Review** (`.github/ai-review/security-review.md`)

```markdown
# Security Best Practices (OWASP)

## 1. Injection Attacks
- SQL Injection: usare prepared statements
- XSS: sanitizzare input utente
- Command Injection: validare parametri

## 2. Authentication
- JWT token validation
- Password hashing con BCrypt
- Session management sicuro

## 3. Secrets Management
- NO hardcoded API keys
- Usare environment variables
- NO secrets in repository
```

### Personalizzazione delle Regole

**Esempio: Aggiungere una nuova regola**

```markdown
<!-- Modifica: .github/ai-review/java-review.md -->

## Logging Standards

### Cosa verificare:
- [ ] Usare SLF4J come logging facade
- [ ] Log level appropriato (DEBUG, INFO, WARN, ERROR)
- [ ] NO System.out.println in produzione
- [ ] Log delle eccezioni con stack trace

### Esempio:
```java
// ❌ SBAGLIATO
System.out.println("User logged in: " + userId);

// ✅ CORRETTO
log.info("User logged in: {}", userId);
```
```

**Le modifiche sono effettive immediatamente** alla prossima PR!

---

## Configurazione

### Prerequisiti

#### 1. API Key Anthropic

```
Step 1: Registrati su console.anthropic.com
Step 2: Vai su API Keys
Step 3: Crea una nuova chiave (sk-ant-api03-...)
Step 4: Copia la chiave (108 caratteri)
```

#### 2. Configurazione GitHub Secrets

```
Repository GitHub
  └── Settings
      └── Secrets and variables
          └── Actions
              └── New repository secret
                  ├─ Name: ANTHROPIC_API_KEY
                  └─ Value: [tua chiave API]
```

#### 3. Permessi GitHub Actions

```
Repository Settings
  └── Actions
      └── General
          └── Workflow permissions
              ├─ ✅ Read and write permissions
              └─ ✅ Allow GitHub Actions to create and approve pull requests
```

### File Configurazione

**`.github/workflows/ai-review.yml`** (principale)

```yaml
name: AI Code Review

on:
  pull_request:
    types: [opened, synchronize, reopened]

permissions:
  pull-requests: write
  contents: read

jobs:
  ai-review:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
      - name: Get PR diff
      - name: Load review rules
      - name: Run AI Code Review
      - name: Post review comment
```

---

## Esempi Pratici

### Esempio 1: Feature Branch con Bug di Sicurezza

**Codice nella PR:**

```java
// backend/src/main/java/com/example/UserController.java
@GetMapping("/user/{id}")
public User getUser(@PathVariable String id) {
    String query = "SELECT * FROM users WHERE id = " + id; // ❌ SQL Injection!
    return jdbcTemplate.queryForObject(query, User.class);
}
```

**Review AI generata:**

```markdown
## 🤖 AI Code Review

### Overall Assessment
La PR introduce una vulnerabilità critica di SQL Injection nel metodo getUser.

### Critical Issues ⚠️

#### 1. SQL Injection Vulnerability (UserController.java:15)
**Problema:** Concatenazione diretta di parametro utente nella query SQL
**Rischio:** Un attaccante può eseguire query SQL arbitrarie
**Fix suggerito:**
```java
@GetMapping("/user/{id}")
public User getUser(@PathVariable Long id) {
    String query = "SELECT * FROM users WHERE id = ?";
    return jdbcTemplate.queryForObject(query, User.class, id);
}
```

### Positive Observations ✅
- Uso corretto di @PathVariable
- Separazione controller/service rispettata
```

### Esempio 2: Frontend React con Type Safety Issues

**Codice nella PR:**

```typescript
// frontend/src/components/UserProfile.tsx
export const UserProfile = ({ user }: any) => {  // ❌ any type
  const [data, setData] = useState();  // ❌ tipo non specificato
  
  useEffect(() => {
    fetch('/api/user')
      .then(res => res.json())
      .then(data => setData(data));  // ❌ no error handling
  }, []);  // ✅ dependency array ok
  
  return <div>{user.name}</div>;
}
```

**Review AI generata:**

```markdown
## 🤖 AI Code Review

### Medium Issues ⚠️

#### 1. Type Safety - any type usage (UserProfile.tsx:1)
**Problema:** Props definiti con `any` perdono i vantaggi di TypeScript
**Fix suggerito:**
```typescript
interface UserProfileProps {
  user: {
    name: string;
    email: string;
  };
}

export const UserProfile = ({ user }: UserProfileProps) => {
```

#### 2. Missing useState type (UserProfile.tsx:2)
**Problema:** `useState()` senza tipo esplicito
**Fix suggerito:**
```typescript
const [data, setData] = useState<User | null>(null);
```

#### 3. No error handling (UserProfile.tsx:5)
**Problema:** Fetch senza gestione errori
**Fix suggerito:**
```typescript
try {
  const res = await fetch('/api/user');
  if (!res.ok) throw new Error('Failed to fetch');
  const data = await res.json();
  setData(data);
} catch (error) {
  setError('Unable to load user data');
}
```
```

### Esempio 3: Workflow Completo

```
┌──────────────────────────────────────────────────────────────────┐
│  TIMELINE COMPLETA DI UNA PR REVIEW                               │
└──────────────────────────────────────────────────────────────────┘

10:00:00  Developer: git push origin feature/auth-fix
10:00:05  GitHub: PR #42 creata
10:00:06  GitHub Actions: Workflow 'AI Code Review' triggered
10:00:10  GitHub Actions: Checkout completato
10:00:12  GitHub Actions: Diff calcolato (2.5 KB)
10:00:13  GitHub Actions: Regole caricate (12 KB totali)
10:00:15  GitHub Actions: Chiamata API Anthropic...
10:00:35  Anthropic: Review generata (4.2 KB)
10:00:36  GitHub Actions: Review estratta con jq
10:00:38  GitHub Actions: Commento pubblicato su PR #42
10:00:39  Developer: Notifica ricevuta - "🤖 AI Code Review posted"

TEMPO TOTALE: ~40 secondi
COSTO: ~€0.15
```

---

## Risoluzione Problemi

### Problema 1: Workflow non parte

**Sintomi:**
- PR creata ma nessun workflow nelle Actions
- Tab Actions vuoto

**Diagnosi:**
```bash
# Verifica che il file workflow esista
ls .github/workflows/ai-review.yml

# Verifica che sia nel branch main
git branch
git checkout main
git log --oneline .github/workflows/ai-review.yml
```

**Soluzione:**
```bash
# Il workflow deve essere nel branch main per attivarsi
git checkout main
git add .github/workflows/ai-review.yml
git commit -m "Add AI review workflow"
git push origin main
```

### Problema 2: "ANTHROPIC_API_KEY not set"

**Sintomi:**
```
ERROR: ANTHROPIC_API_KEY is not set
Error: Process completed with exit code 1.
```

**Soluzione:**
```
1. Vai su: Repository → Settings → Secrets and variables → Actions
2. Clicca: "New repository secret"
3. Name: ANTHROPIC_API_KEY
4. Value: sk-ant-api03-... (la tua chiave completa, 108 caratteri)
5. Clicca: "Add secret"
6. Ri-esegui il workflow
```

### Problema 3: "Permission denied" nel posting del commento

**Sintomi:**
```
Error: Resource not accessible by integration
RequestError: Bad credentials
```

**Soluzione:**
```
Settings → Actions → General → Workflow permissions
  
  ○ Read repository contents and packages permissions
  ● Read and write permissions  ← Seleziona questo
  
  ☑ Allow GitHub Actions to create and approve pull requests
```

### Problema 4: Review vuota o "null"

**Sintomi:**
- Workflow completa con successo
- Ma commento contiene "null" o è vuoto

**Diagnosi:**
```yaml
# Controlla i log del workflow step "Run AI Code Review"
# Cerca queste righe:
Review extracted successfully (0 characters)  ← Problema!
# Dovrebbe essere:
Review extracted successfully (4521 characters)  ← OK
```

**Soluzione:**
```bash
# Verifica il formato delle regole
cat .github/ai-review/react-review.md

# Assicurati che i file non siano vuoti
ls -lh .github/ai-review/

# Se i file sono corrotti, ripristinali
git checkout main -- .github/ai-review/
```

### Problema 5: "invalid x-api-key"

**Sintomi:**
```
ERROR: API returned error type: authentication_error
Error message: invalid x-api-key
```

**Causa più comune:**
- Chiave API copiata male (107 caratteri invece di 108)
- Spazi extra all'inizio/fine
- Chiave scaduta o revocata

**Soluzione:**
```bash
# Test locale della chiave
$apiKey = "sk-ant-api03-..."
Write-Host "Lunghezza chiave: $($apiKey.Length) caratteri"
# Deve essere esattamente 108 caratteri

# Testa la chiave
curl -H "x-api-key: $apiKey" `
     -H "anthropic-version: 2023-06-01" `
     https://api.anthropic.com/v1/models

# Se ricevi errore, la chiave non è valida
# Genera una nuova chiave su console.anthropic.com
```

### Problema 6: Workflow troppo lento (> 2 minuti)

**Cause possibili:**
- Diff molto grande (>100 KB)
- Regole molto lunghe
- API Anthropic sovraccarica

**Ottimizzazioni:**
```yaml
# Limita i file analizzati
on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - 'backend/**'
      - 'frontend/**'
      - '!**/*.md'  # Escludi markdown
      - '!**/test/**'  # Escludi test

# Riduci max_tokens se le review sono troppo lunghe
max_tokens: 2048  # invece di 4096
```

---

## Monitoraggio e Costi

### Dashboard Utilizzo API

Controlla i costi su: [console.anthropic.com](https://console.anthropic.com)

```
Dashboard
  └── Usage
      ├── Tokens Used
      │   ├─ Input: ~5,000 tokens per review
      │   └─ Output: ~1,500 tokens per review
      │
      └── Costs
          ├─ Input: $3 / 1M tokens
          ├─ Output: $15 / 1M tokens
          └─ Media per review: ~€0.15
```

### Stima Costi Mensile

```
Scenario 1: Team piccolo (10 PR/mese)
  10 PR × €0.15 = €1.50/mese

Scenario 2: Team medio (50 PR/mese)
  50 PR × €0.15 = €7.50/mese

Scenario 3: Team grande (200 PR/mese)
  200 PR × €0.15 = €30/mese
```

---

## Best Practices

### 1. Mantenere Regole Aggiornate

```bash
# Ogni mese, revisiona le regole
cd .github/ai-review

# Aggiungi nuovi pattern scoperti durante code review manuali
# Rimuovi regole obsolete
# Aggiorna esempi con codice reale del progetto
```

### 2. Combinare AI Review + Human Review

```
┌────────────────────┐
│   AI Review        │  ← Prima passata: trova problemi comuni
│   (automatica)     │     (security, type safety, best practices)
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   Human Review     │  ← Seconda passata: logica business,
│   (manuale)        │     architettura, edge cases
└────────────────────┘
```

### 3. Iterazione sulle Regole

```markdown
<!-- Inizia con regole semplici -->
## Error Handling
- Verifica try-catch

<!-- Aggiungi dettagli nel tempo -->
## Error Handling
- Try-catch per operazioni async
- Error boundaries in React
- Logging degli errori
- Retry logic per network failures
- Fallback UI per errori critici
```

### 4. Feedback Loop

```
Developer legge AI review
    ↓
Identifica falsi positivi
    ↓
Aggiorna regole per essere più specifiche
    ↓
AI review migliora nelle PR successive
```

---

## Conclusione

Il sistema di AI Code Review automatizza la revisione del codice applicando regole personalizzabili attraverso Claude Sonnet 4 di Anthropic.

**Vantaggi:**
✅ Revisione automatica e immediata  
✅ Consistenza nelle code review  
✅ Risparmio tempo del team  
✅ Cattura problemi comuni prima della review umana  
✅ Regole personalizzabili per il tuo progetto  

**Flusso completo:**
```
Push → PR → Workflow → Diff → Rules → Claude → Review → Comment
```

**File chiave:**
- `.github/workflows/ai-review.yml` - Orchestrazione
- `.github/ai-review/*.md` - Regole personalizzabili
- `ANTHROPIC_API_KEY` - Autenticazione API

**Prossimi passi:**
1. Testa con una PR di prova
2. Personalizza le regole per il tuo team
3. Monitora i costi su console.anthropic.com
4. Itera sulle regole basandoti sul feedback

---

**Domande? Problemi?** Consulta la sezione [Risoluzione Problemi](#risoluzione-problemi) o controlla i log su GitHub Actions.
