# Nuvola Client 📚

Un client mobile **non ufficiale** per il registro elettronico Nuvola, sviluppato con Flutter.

> [!WARNING]
> Questo è un client **non ufficiale** e non è affiliato con Madisoft o Nuvola. L'utilizzo di questo client potrebbe violare i termini di servizio. L'utente è responsabile dell'uso di questa applicazione.

## Caratteristiche ✨

- 🔐 **Autenticazione sicura** con credenziali Nuvola
- 📊 **Dashboard** con riepilogo voti, compiti e assenze
- 📝 **Voti** organizzati per materia con calcolo automatico delle medie
- ❌ **Assenze**, ritardi e uscite anticipate con filtri
- 📚 **Compiti** con selezione data e possibilità di marcarli come completati
- 🎨 **Material Design 3** con supporto tema chiaro/scuro
- 💾 **Salvataggio credenziali** sicuro con flutter_secure_storage
- 🔄 **Pull-to-refresh** su tutte le schermate

## Requisiti

- Flutter SDK (>=3.0.0)
- Android Studio / Xcode (per build)
- Account Nuvola valido

## Installazione

### 1. Clona il repository
```bash
cd nuvolareskin
```

### 2. Installa le dipendenze
```bash
flutter pub get
```

### 3. Avvia l'app
```bash
# Debug mode
flutter run

# Release mode (Android)
flutter build apk --release

# Release mode (iOS)
flutter build ios --release
```

## Utilizzo

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

## Struttura del Progetto

```
lib/
├── core/
│   ├── api/
│   │   ├── api_client.dart           # Client HTTP con Dio
│   │   ├── auth_service.dart         # Servizio autenticazione
│   │   └── nuvola_api_service.dart   # Servizio API Nuvola
│   └── constants.dart                # Costanti applicazione
├── models/
│   ├── alunno.dart                   # Modello studente
│   ├── voto.dart                     # Modello voto
│   ├── assenza.dart                  # Modello assenza
│   ├── nota.dart                     # Modello nota
│   └── compito.dart                  # Modello compito
├── providers/
│   └── auth_provider.dart            # Provider autenticazione
├── screens/
│   ├── login_screen.dart             # Schermata login
│   ├── home_screen.dart              # Dashboard
│   ├── voti_screen.dart              # Voti
│   ├── assenze_screen.dart           # Assenze
│   └── compiti_screen.dart           # Compiti
└── main.dart                         # Entry point
```

## API Endpoints Utilizzati

- `POST /login_check` - Autenticazione
- `GET /api-studente/v1/login-from-web` - Ottiene JWT token
- `GET /api-studente/v1/alunni` - Lista studenti
- `GET /api-studente/v1/alunno/{id}/voti` - Voti
- `GET /api-studente/v1/alunno/{id}/assenze` - Assenze
- `GET /api-studente/v1/alunno/{id}/note` - Note
- `GET /api-studente/v1/alunno/{id}/compito/elenco/{date}` - Compiti

## Sviluppi Futuri 🚀

- [ ] Note disciplinari
- [ ] Argomenti delle lezioni
- [ ] Comunicazioni/News dalla scuola
- [ ] Eventi (classe, materia, personali)
- [ ] Pagamenti
- [ ] Notifiche push per nuovi voti/comunicazioni
- [ ] Grafici andamento voti
- [ ] Esportazione dati (PDF, Excel)
- [ ] Supporto multi-studente

## Tecnologie Utilizzate

- **Flutter** - Framework UI cross-platform
- **Dio** - Client HTTP per chiamate API
- **Provider** - State management
- **flutter_secure_storage** - Archiviazione sicura credenziali
- **Material Design 3** - Design system

## Contribuire

Contributi, issue e feature request sono benvenuti!

## Licenza

Questo progetto è fornito "così com'è" senza garanzie di alcun tipo.

## Disclaimer Legale

Questo client non è affiliato, autorizzato, mantenuto, sponsorizzato o endorsato da Madisoft o Nuvola. Tutti i nomi di prodotti, loghi e marchi sono proprietà dei rispettivi proprietari. L'uso di questo client è a proprio rischio e pericolo.

## Supporto

Per domande o problemi, apri una issue su GitHub.

---

**Sviluppato con ❤️ usando Flutter**
