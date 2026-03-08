> **Note for English speakers:** This project is entirely in Italian and there will be no English translation. Nuvola is a digital school register (registro elettronico) used exclusively in Italy, produced by [Madisoft](https://www.madisoft.it). Since the product, its users, and all its content are Italian, the documentation and the app itself are written in Italian only.

---

# Volta

Client mobile **non ufficiale** per il registro elettronico [Nuvola di Madisoft](https://nuvola.madisoft.it), sviluppato con Flutter.

> [!WARNING]
> Questo è un progetto **non ufficiale** e non è in alcun modo affiliato, sponsorizzato o approvato da Madisoft S.r.l. L'utilizzo potrebbe violare i Termini di Servizio di Nuvola. L'utente è l'unico responsabile dell'uso di questa applicazione.

> [!IMPORTANT]
> **Questo progetto potrebbe smettere di funzionare a breve.**
>
> L'accesso tramite credenziali classiche (nome utente e password) è progressivamente incompatibile con il quadro normativo vigente in Italia:
>
> **1. Decreto Semplificazioni (D.L. 76/2020)**
> Il decreto stabilisce che dal 28 febbraio 2021 l'accesso ai servizi online della Pubblica Amministrazione — comprese le istituzioni scolastiche — deve avvenire **esclusivamente tramite SPID, CIE o CNS**. Le credenziali tradizionali potevano essere rilasciate solo fino a quella data e utilizzate fino alla loro naturale scadenza (comunque non oltre il 2021/2022).
> Fonti: [Normattiva](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:decreto.legge:2020-07-16;76) · [G.U. n. 178/2020 (D.L. originale)](https://www.gazzettaufficiale.it/eli/id/2020/07/16/20G00096/s) · [G.U. n. 228/2020 (Legge di conversione)](http://gazzettaufficiale.it/eli/id/2020/09/14/20A04921/sg)
>
> **2. Linee Guida AGID**
> L'Agenzia per l'Italia Digitale (AGID) ha confermato con apposite circolari che il registro elettronico, in quanto servizio della PA, rientra pienamente in questo obbligo, con particolare attenzione alla protezione dei dati personali dei minori.
>
> **3. Circolari del Ministero dell'Istruzione (MIM)**
> Il Ministero ha sollecitato nel tempo i fornitori di software gestionali (Argo, Axios, ClasseViva, Madisoft, ecc.) ad integrare l'autenticazione con identità digitale ("Entra con SPID").
>
> **Nota:** Molte scuole consentono ancora l'accesso con credenziali interne per gli **studenti minorenni** (che non possono ottenere SPID), ma per genitori e personale docente l'identità digitale è ormai lo standard richiesto. Nel momento in cui Madisoft disabiliterà il login classico anche per gli studenti, questa applicazione cesserà di funzionare.
>
> **Il supporto a SPID/CIE non verrà aggiunto.** L'autenticazione tramite SPID e CIE richiede l'integrazione con Identity Provider federati (es. Poste ID, InfoCert, SIELTE, ecc.) tramite protocollo SAML 2.0 o OIDC, con flussi di autorizzazione che passano obbligatoriamente attraverso browser di sistema e redirect verso servizi governativi. Non è tecnicamente possibile replicare questo flusso in un'app non ufficiale senza essere un Service Provider accreditato presso AGID, accreditamento riservato esclusivamente a soggetti giuridici riconosciuti.

---

## Indice

- [Funzionalità](#funzionalità)
- [Screenshot](#screenshot)
- [Requisiti](#requisiti)
- [Installazione](#installazione)
- [Struttura del progetto](#struttura-del-progetto)
- [Dipendenze](#dipendenze)
- [Sicurezza e privacy](#sicurezza-e-privacy)
- [Limitazioni note](#limitazioni-note)
- [Documentazione API](#documentazione-api)
- [Contribuire](#contribuire)
- [Licenza](#licenza)

---

## Funzionalità

| Sezione | Dettagli |
|---|---|
| 🔐 **Autenticazione** | Login con credenziali Nuvola, salvataggio sicuro opzionale con "Ricorda credenziali" |
| 📊 **Dashboard** | Riepilogo voti recenti, compiti, media generale e streak |
| 📝 **Voti** | Voti per materia con media automatica, selezione quadrimestre, grafico andamento |
| ❌ **Assenze** | Elenco assenze, ritardi e uscite con filtri e indicatore giustificazione |
| 📚 **Compiti** | Calendario settimanale, filtri, marcatura locale come completato |
| 🎨 **Tema** | Material Design 3, tema chiaro/scuro/sistema |
| 🔄 **Aggiornamento** | Pull-to-refresh su tutte le schermate |
| 🏆 **Streak** | Sistema di streak per voti consecutivi sufficienti |

---

## Requisiti

- Flutter SDK **3.0.0** o superiore
- Dart **3.0.0** o superiore
- Un account Nuvola (Madisoft) valido
- Per iOS: Xcode 14+ e macOS
- Per Android: Android Studio o SDK Android

---

## Installazione

### 1. Clona il repository

```bash
git clone https://github.com/dddevid/Volta.git
cd Volta
```

### 2. Installa le dipendenze

```bash
flutter pub get
```

### 3. Esegui l'app

```bash
# Modalità debug (dispositivo/emulatore collegato)
flutter run

# Build release Android
flutter build apk --release

# Build release iOS
flutter build ios --release
```

---

## Struttura del progetto

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart           # Client HTTP (Dio) con gestione cookie e JWT
│   │   ├── auth_service.dart         # Flusso di autenticazione Nuvola
│   │   └── nuvola_api_service.dart   # Wrapper per tutti gli endpoint API
│   ├── services/
│   │   └── grade_streak_service.dart # Logica streak voti
│   ├── utils/
│   │   └── ui_utils.dart             # Utilità UI (colori voti, parsing)
│   └── constants.dart                # Costanti globali (URL, chiavi storage)
├── models/
│   ├── alunno.dart                   # Modello studente
│   ├── assenza.dart                  # Modello assenza/ritardo/uscita
│   ├── compito.dart                  # Modello compito
│   ├── frazione_temporale.dart       # Modello quadrimestre/periodo
│   ├── materia_voti.dart             # Modello materia con lista voti e media
│   ├── nota.dart                     # Modello nota disciplinare
│   ├── voto.dart                     # Modello voto singolo
│   └── voto_dettagliato.dart         # Modello voto con dettagli estesi
├── providers/
│   ├── auth_provider.dart            # Stato autenticazione (ChangeNotifier)
│   └── theme_provider.dart           # Stato tema (ChangeNotifier)
└── screens/
    ├── home_screen.dart              # Schermata principale con dashboard
    ├── login_screen.dart             # Schermata login
    ├── voti_screen.dart              # Schermata voti per materia
    ├── assenze_screen.dart           # Schermata assenze
    ├── compiti_screen.dart           # Schermata compiti
    ├── subject_detail_screen.dart    # Dettaglio voti per singola materia
    └── streak_level_up_dialog.dart   # Dialog animato streak
```

---

## Dipendenze

| Pacchetto | Versione | Utilizzo |
|---|---|---|
| `dio` | ^5.4.0 | Client HTTP |
| `cookie_jar` + `dio_cookie_manager` | ^4.0.8 / ^3.1.1 | Gestione cookie sessione |
| `provider` | ^6.1.1 | State management |
| `flutter_secure_storage` | ^9.0.0 | Salvataggio sicuro credenziali |
| `shared_preferences` | ^2.5.3 | Preferenze locali (streak, tema) |
| `fl_chart` | ^1.1.1 | Grafici andamento voti |
| `table_calendar` | ^3.0.9 | Calendario compiti |
| `animated_bottom_navigation_bar` | ^1.4.0 | Barra navigazione animata |
| `google_fonts` | ^6.3.2 | Tipografia |
| `flutter_displaymode` | ^0.7.0 | Refresh rate elevato (Android) |
| `intl` | ^0.19.0 | Formattazione date |
| `html` + `flutter_html` | ^0.15.4 / ^3.0.0-beta.2 | Parsing/rendering HTML |
| `url_launcher` | ^6.2.2 | Apertura link esterni |

---

## Sicurezza e privacy

- Le credenziali vengono salvate **esclusivamente** nel keystore sicuro del dispositivo (`flutter_secure_storage`): Android Keystore su Android, iOS Keychain su iOS.
- Nessun dato personale viene inviato a server di terze parti. Tutte le richieste vanno direttamente agli endpoint ufficiali `nuvola.madisoft.it`.
- I log di debug **non contengono mai** dati personali o risposte JSON dell'API (conformità GDPR).
- Il token JWT ha una scadenza gestita lato client di 28 minuti; alla scadenza viene effettuato un nuovo login automatico con le credenziali salvate.

---

## Limitazioni note

- L'app supporta un solo studente per account (il primo restituito dall'API).
- La marcatura dei compiti come completati è **solo locale** e non viene sincronizzata con Nuvola.
- Il modulo `flutter_displaymode` funziona solo su Android; su iOS viene ignorato silenziosamente.
- Alcune sezioni dell'API Nuvola (pagamenti, eventi classe, argomenti lezione) sono definite nelle costanti ma non ancora esposte nell'interfaccia.

---

## Documentazione API

La documentazione reverse-engineered delle API Nuvola è disponibile nel file [`NUVOLA_API.md`](NUVOLA_API.md).

Copre autenticazione, endpoint, struttura delle risposte e convenzioni comuni ricavate dall'analisi del traffico di rete. Non esiste documentazione pubblica ufficiale da parte di Madisoft.

---

## Contribuire

L'app è un progetto personale. Le pull request sono ben accette, ma tenendo presente che:

- Il codice è in italiano (nomi variabili, messaggi utente).
- Nessuna traduzione in inglese è prevista.
- L'API Nuvola è proprietaria e non documentata ufficialmente; la documentazione reverse-engineered è nel file [`NUVOLA_API.md`](NUVOLA_API.md).

---

## Licenza

Distribuito sotto licenza **MIT**. Vedi `LICENSE` per i dettagli.

Nuvola e il logo Nuvola sono marchi registrati di Madisoft S.r.l. Questo progetto non è affiliato con Madisoft S.r.l.

### Login
1. Apri l'app
2. Inserisci il tuo **username** e **password** di Nuvola
3. (Opzionale) Spunta "Ricorda credenziali" per salvare le credenziali in modo sicuro
4. Premi "Accedi"

### Dashboard
La schermata principale mostra:
- Numero di notifiche non lette
- Totale assenze
- Ultimi 5 voti
- Compiti per oggi

### Voti
Visualizza tutti i voti organizzati per materia. Espandi una materia per vedere:
- Tutti i voti ricevuti
- Data, tipologia e descrizione
- Docente che ha assegnato il voto
- Media calcolata automaticamente

### Assenze
Visualizza tutte le assenze, ritardi e uscite anticipate con:
- Statistiche totali
- Filtri per tipo
- Indicatore di giustificazione

### Compiti
Visualizza i compiti per data selezionata:
- Calendario per selezione data
- Materia, descrizione e data consegna
- Possibilità di marcare come completato (solo locale)

## Sicurezza 🔒

Le credenziali vengono salvate in modo sicuro utilizzando `flutter_secure_storage`:
- Su Android: Android Keystore
- Su iOS: iOS Keychain

Le credenziali **non vengono mai inviate** a server di terze parti, solo agli endpoint ufficiali di Nuvola.

## API Endpoints Utilizzati

- `POST /login_check` - Autenticazione
- `GET /api-studente/v1/login-from-web` - Ottiene JWT token
- `GET /api-studente/v1/alunni` - Lista studenti
- `GET /api-studente/v1/alunno/{id}/voti` - Voti
- `GET /api-studente/v1/alunno/{id}/assenze` - Assenze
- `GET /api-studente/v1/alunno/{id}/note` - Note
- `GET /api-studente/v1/alunno/{id}/compito/elenco/{date}` - Compiti

## Tecnologie Utilizzate

- **Flutter** - Framework UI cross-platform
- **Dio** - Client HTTP per chiamate API
- **Provider** - State management
- **flutter_secure_storage** - Archiviazione sicura credenziali
- **Material Design 3** - Design system

## Supporto

Per domande o problemi, apri una issue su GitHub.

