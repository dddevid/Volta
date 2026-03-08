# Privacy Policy — Volta

**Ultimo aggiornamento:** marzo 2026

Volta è un client mobile **open source e non ufficiale** per il registro elettronico Nuvola di Madisoft. Questa informativa descrive come l'app gestisce i dati personali degli utenti.

---

## 1. Dati raccolti

**Volta non raccoglie, archivia né trasmette alcun dato personale a server propri o di terze parti.**

Le credenziali di accesso (username e password) inserite dall'utente vengono salvate **esclusivamente sul dispositivo locale**, all'interno del keychain sicuro del sistema operativo:

- **iOS:** iOS Keychain (cifrato a livello hardware)
- **Android:** Android Keystore (cifrato a livello hardware)

Il salvataggio delle credenziali avviene **solo se l'utente attiva esplicitamente** l'opzione "Ricorda credenziali". In caso contrario, nessuna credenziale viene persistita.

---

## 2. Accesso ai dati scolastici

Volta si connette **esclusivamente** alle API ufficiali di Nuvola (`nuvola.madisoft.it`) per recuperare, in sola lettura, i dati dell'utente autenticato (voti, assenze, compiti, ecc.).

- Nessun dato scolastico viene inviato a server aggiuntivi.
- Nessun dato viene condiviso con terze parti.
- Nessuna analytics, telemetria o sistema di tracciamento è presente nell'app.

---

## 3. Token di autenticazione

Il token JWT rilasciato da Nuvola al termine dell'autenticazione viene conservato temporaneamente in memoria per la durata della sessione. Non viene persistito su disco al di fuori del keychain sicuro.

---

## 4. Codice open source

Il codice sorgente di Volta è **interamente pubblico e liberamente ispezionabile**. Chiunque può verificare che l'app non effettui operazioni non dichiarate in questa informativa.

---

## 5. Conformità al GDPR

Poiché Volta **non tratta né conserva dati personali su propri server**, non agisce in qualità di Titolare del Trattamento ai sensi del Regolamento (UE) 2016/679 (GDPR).

Il trattamento dei dati personali da parte di Nuvola/Madisoft è disciplinato dalla loro informativa sulla privacy, disponibile all'indirizzo:
**[https://nuvola.madisoft.it/privacy-policy](https://nuvola.madisoft.it/privacy-policy)**

---

## 6. Sicurezza

Volta utilizza le seguenti misure di sicurezza:

- Archiviazione delle credenziali nel keychain cifrato del sistema operativo (`flutter_secure_storage`)
- Nessun log di dati personali in produzione
- Comunicazioni con Nuvola tramite HTTPS

---

## 7. Minori

Volta è progettata per essere utilizzata da studenti, inclusi i minori. L'app non raccoglie dati aggiuntivi rispetto a quelli strettamente necessari per autenticarsi su Nuvola e visualizzare i propri dati scolastici.

---

## 8. Modifiche a questa informativa

Eventuali modifiche a questa privacy policy saranno pubblicate nel repository GitHub del progetto. L'uso continuato dell'app dopo la pubblicazione delle modifiche costituisce accettazione delle stesse.

---

## 9. Contatti

Per domande relative a questa informativa, apri una **issue** nel repository GitHub del progetto.
