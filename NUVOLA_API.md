# Nuvola API — Documentazione reverse-engineered

> **Avvertenza:** questa documentazione è stata ricavata tramite analisi del traffico di rete del sito ufficiale [nuvola.madisoft.it](https://nuvola.madisoft.it). Non esiste documentazione pubblica ufficiale. I dettagli potrebbero cambiare senza preavviso in seguito ad aggiornamenti di Madisoft.

> [!NOTE]
> Tutti i nomi, i cognomi, gli ID e gli altri dati personali presenti negli esempi di richieste e risposte in questo documento sono **completamente fittizi** e generati casualmente. Qualsiasi somiglianza con persone reali è puramente casuale.

---

## Indice

- [Panoramica](#panoramica)
- [Autenticazione](#autenticazione)
- [Convezioni comuni](#convenzioni-comuni)
- [Endpoint](#endpoint)
  - [Studenti](#studenti)
  - [Frazioni temporali (quadrimestri)](#frazioni-temporali-quadrimestri)
  - [Voti](#voti)
  - [Assenze](#assenze)
  - [Compiti](#compiti)
  - [Note disciplinari](#note-disciplinari)
  - [Notifiche](#notifiche)
  - [Pagamenti](#pagamenti)
  - [Argomenti lezione](#argomenti-lezione)
  - [Eventi](#eventi)
- [Modelli di risposta](#modelli-di-risposta)
- [Gestione errori](#gestione-errori)

---

## Panoramica

| Proprietà | Valore |
|---|---|
| Base URL | `https://nuvola.madisoft.it` |
| Prefisso API studente | `/api-studente/v1` |
| Autenticazione | JWT Bearer token |
| Formato risposta | JSON |
| Timeout consigliato | 30 secondi |

---

## Autenticazione

L'autenticazione avviene in 5 fasi sequenziali. Non esiste un endpoint OAuth standard: Nuvola usa una sessione web tradizionale dalla quale viene poi ricavato un JWT.

### Fase 1 — Ottenere il CSRF token

```
GET /login
```

Risposta: pagina HTML. Estrarre il valore dell'input nascosto:

```html
<input name="_csrf_token" value="TOKEN_QUI" />
```

### Fase 2 — Login con credenziali

```
POST /login_check
Content-Type: application/x-www-form-urlencoded
```

**Body (form-urlencoded):**

| Campo | Tipo | Descrizione |
|---|---|---|
| `_csrf_token` | string | Token estratto nella fase 1 |
| `_username` | string | Username Nuvola dell'utente |
| `_password` | string | Password Nuvola dell'utente |

**Risposta attesa:** HTTP `302` (redirect) o `200`. Un HTTP `401`/`403` indica credenziali errate.

> I cookie di sessione vengono impostati automaticamente in questa fase e devono essere mantenuti per le richieste successive.

### Fase 3 — Accesso all'area studente

```
GET /area-studente
```

Necessario per stabilire il contesto di sessione lato server. Non restituisce dati utili.

### Fase 4 — Ottenere il token JWT

```
GET /api-studente/v1/login-from-web
```

**Risposta:**

```json
"eyJhbGciOiJSUzI1NiJ9..."
```

Il token può essere restituito come stringa diretta oppure come oggetto:

```json
{ "token": "eyJhbGciOiJSUzI1NiJ9..." }
```

Il JWT ha una **scadenza effettiva di circa 28 minuti**.

### Fase 5 — Utilizzo del JWT

Tutte le successive chiamate API devono includere l'header:

```
Authorization: Bearer <jwt_token>
```

Il parametro query `contextAlunno=<alunnoId>` è richiesto dalla maggior parte degli endpoint.

---

## Convenzioni comuni

### Struttura risposta standard

La maggior parte degli endpoint restituisce un oggetto con la chiave `valori`:

```json
{
  "listeValori": null,
  "opzioni": [],
  "valori": [ ... ],
  "paginatore": null
}
```

In alcuni casi i dati sono restituiti come array diretto `[...]`.

### Parametri URL

| Placeholder | Descrizione |
|---|---|
| `{id}` | ID numerico dello studente (`alunnoId`) |
| `{frazioneId}` | ID del periodo/quadrimestre |
| `{date}` | Data nel formato `DD-MM-YYYY` |

### Query parameter comune

| Parametro | Tipo | Descrizione |
|---|---|---|
| `contextAlunno` | int | ID studente, richiesto quasi ovunque |

---

## Endpoint

### Studenti

#### Lista studenti

```
GET /api-studente/v1/alunni
```

Restituisce gli studenti associati all'account autenticato (di solito uno solo per account famiglia).

**Risposta:**

```json
{
  "valori": [
    {
      "id": 12345,
      "nome": "Mario",
      "cognome": "Rossi",
      "nomeCompleto": "Mario Rossi",
      "classe": "3A",
      "scuola": "Istituto Esempio"
    }
  ]
}
```

---

### Frazioni temporali (quadrimestri)

#### Lista periodi

```
GET /api-studente/v1/alunno/{id}/frazioni-temporali
     ?contextAlunno={id}
```

Restituisce i periodi dell'anno scolastico (trimestri, quadrimestri, intero anno).

**Risposta:**

```json
{
  "valori": [
    { "id": 258, "nome": "1° QUADRIMESTRE", "corrente": false },
    { "id": 259, "nome": "2° QUADRIMESTRE", "corrente": true },
    { "id": 260, "nome": "INTERO ANNO",     "corrente": false }
  ]
}
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | int | Identificatore del periodo, usato come `{frazioneId}` |
| `nome` | string | Nome leggibile del periodo |
| `corrente` | bool | `true` se è il periodo attuale |

---

### Voti

#### Voti per materia (lista materie con media)

```
GET /api-studente/v1/alunno/{id}/frazione-temporale/{frazioneId}/voti/materie
     ?contextAlunno={id}
```

Restituisce le materie con i rispettivi voti e la media calcolata per il periodo selezionato.

**Risposta:**

```json
{
  "valori": [
    {
      "id": 101,
      "materia": "MATEMATICA",
      "media": "7,50",
      "voti": [
        {
          "id": 9001,
          "data": "2025-11-10",
          "valutazione": "8",
          "valore": "8",
          "tipo": "S",
          "descrizione": "Verifica algebra",
          "docente": "Prof. Bianchi",
          "visibile": true
        }
      ]
    }
  ]
}
```

**Campi materia:**

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | int | ID materia |
| `materia` | string | Nome materia |
| `media` | string | Media con virgola decimale (es. `"7,50"`) |
| `voti` | array | Lista voti della materia |

**Campi voto:**

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | int? | ID voto (può essere assente) |
| `data` | string | Data nel formato `YYYY-MM-DD` |
| `valutazione` | string | Valore grezzo (es. `"8"`, `"7½"`, `"6+"`) |
| `valore` | string | Valore numerico normalizzato |
| `tipo` | string | Tipologia: `S` = scritto, `O` = orale, `P` = pratico |
| `descrizione` | string? | Descrizione/argomento della valutazione |
| `docente` | string? | Nome del docente |
| `visibile` | bool | Se il voto è visibile allo studente |

#### Dettaglio voti per singola materia

```
GET /api-studente/v1/alunno/{id}/frazione-temporale/{frazioneId}/voti/materia/{materiaId}
     ?contextAlunno={id}
```

Restituisce i voti dettagliati di una sola materia.

**Risposta:** medesima struttura di un singolo elemento `valori` dell'endpoint precedente, con eventuali campi aggiuntivi.

#### Lista voti semplice

```
GET /api-studente/v1/alunno/{id}/voti
     ?contextAlunno={id}
```

Endpoint alternativo per ottenere tutti i voti senza raggruppamento per materia.

---

### Assenze

```
GET /api-studente/v1/alunno/{id}/assenze
     ?contextAlunno={id}
```

**Query parameter opzionale:**

| Parametro | Tipo | Descrizione |
|---|---|---|
| `limit` | int | Numero massimo di risultati |

**Risposta:**

```json
{
  "valori": [
    {
      "id": 5001,
      "data": "2025-10-15",
      "tipo": "assenza",
      "giustificata": true,
      "dataGiustificazione": "2025-10-17",
      "motivazione": "Malattia"
    }
  ]
}
```

**Campo `tipo`:**

| Valore | Descrizione |
|---|---|
| `assenza` | Assenza per l'intera giornata |
| `ritardo` | Entrata in ritardo |
| `uscita` | Uscita anticipata |

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | int | ID assenza |
| `data` | string | Data nel formato `YYYY-MM-DD` |
| `tipo` | string | Tipo di evento (vedi tabella sopra) |
| `giustificata` | bool | Se l'assenza è stata giustificata |
| `dataGiustificazione` | string? | Data della giustificazione |
| `motivazione` | string? | Motivazione dichiarata |

---

### Compiti

```
GET /api-studente/v1/alunno/{id}/compito/elenco/{date}
     ?contextAlunno={id}
```

Il parametro `{date}` deve essere nel formato `DD-MM-YYYY` (es. `10-03-2026`).

Restituisce i compiti assegnati per la data specificata.

**Risposta:**

```json
{
  "valori": [
    {
      "id": 7001,
      "materia": "ITALIANO",
      "descrizione": ["Leggere capitolo 5", "Rispondere alle domande"],
      "dataConsegna": "2026-03-12",
      "docente": "Prof.ssa Verdi"
    }
  ]
}
```

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | int? | ID compito (può essere assente) |
| `materia` | string | Nome materia |
| `descrizione` | string \| array | Testo del compito; può essere una stringa o un array di stringhe |
| `dataConsegna` | string | Data di consegna nel formato `YYYY-MM-DD` |
| `docente` | string? | Nome del docente |

> ⚠️ Il campo `descrizione` può essere sia una `string` che un `List<String>`. Il parsing deve gestire entrambi i casi.

---

### Note disciplinari

```
GET /api-studente/v1/alunno/{id}/note
     ?contextAlunno={id}
```

**Query parameter opzionale:**

| Parametro | Tipo | Descrizione |
|---|---|---|
| `limit` | int | Numero massimo di risultati |

**Risposta:**

```json
{
  "valori": [
    {
      "id": 3001,
      "data": "2025-12-01",
      "tipo": "nota",
      "testo": "Comportamento scorretto durante la lezione",
      "docente": "Prof. Neri"
    }
  ]
}
```

**Campo `tipo`:**

| Valore | Descrizione |
|---|---|
| `nota` | Nota disciplinare generica |
| `richiamo` | Richiamo verbale registrato |
| `sospensione` | Sospensione |

---

### Notifiche

#### Conteggio notifiche non lette

```
GET /api-studente/v1/alunno/{id}/notifiche/conteggio
     ?contextAlunno={id}
```

**Risposta:**

```json
{ "count": 3 }
```

---

### Pagamenti

```
GET /api-studente/v1/alunno/{id}/pagamenti
     ?contextAlunno={id}
```

Restituisce i pagamenti (contributi scolastici, gite, ecc.) associati allo studente.

> Endpoint definito ma non ancora implementato nell'interfaccia dell'app.

---

### Argomenti lezione

```
GET /api-studente/v1/alunno/{id}/argomento-lezione/elenco/{date}
     ?contextAlunno={id}
```

Restituisce gli argomenti trattati in classe per la data specificata (formato `DD-MM-YYYY`).

> Endpoint definito ma non ancora implementato nell'interfaccia dell'app.

---

### Eventi

#### Eventi della classe

```
GET /api-studente/v1/alunno/{id}/eventi-classe
     ?contextAlunno={id}
```

#### Eventi per materia

```
GET /api-studente/v1/alunno/{id}/eventi-classe-materia
     ?contextAlunno={id}
```

#### Eventi personali dello studente

```
GET /api-studente/v1/alunno/{id}/eventi-alunno
     ?contextAlunno={id}
```

> Questi endpoint sono definiti nelle costanti ma non ancora implementati nell'interfaccia dell'app.

---

## Modelli di risposta

### Struttura generica

Quasi tutti gli endpoint restituiscono:

```json
{
  "listeValori": null,
  "opzioni": [],
  "valori": [ ... ],
  "paginatore": null
}
```

Alcuni endpoint (specialmente per strutture dati semplici) restituiscono direttamente un array `[...]` o un oggetto singolo.

### Paginazione

Il campo `paginatore` è presente ma risulta `null` nella maggior parte delle risposte osservate. Non è chiaro se la paginazione sia implementata o meno.

---

## Gestione errori

| Codice HTTP | Significato |
|---|---|
| `200` | Successo |
| `302` | Redirect (atteso nella fase di login) |
| `400` | Richiesta malformata |
| `401` | Non autenticato o token scaduto |
| `403` | Accesso negato (credenziali errate o ruolo non autorizzato) |
| `404` | Risorsa non trovata |
| `500` | Errore interno del server Nuvola |

In caso di token JWT scaduto, ripetere le fasi 1–5 del flusso di autenticazione con le credenziali salvate per ottenere un nuovo token.

---

*Documentazione redatta tramite analisi del traffico di rete. Ultimo aggiornamento: marzo 2026.*
