import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _Header(colorScheme: colorScheme, textTheme: textTheme),
          const SizedBox(height: 20),
          _Section(
            icon: Icons.search_off_rounded,
            title: '1. Dati raccolti',
            colorScheme: colorScheme,
            content: 'Volta non raccoglie, archivia né trasmette alcun dato personale a server propri o di terze parti.\n\n'
                'Le credenziali di accesso vengono salvate esclusivamente sul dispositivo locale, '
                'nel keychain sicuro del sistema operativo (iOS Keychain / Android Keystore), '
                'solo se l\'utente attiva l\'opzione "Ricorda credenziali".',
          ),
          _Section(
            icon: Icons.api_rounded,
            title: '2. Accesso ai dati scolastici',
            colorScheme: colorScheme,
            content: 'L\'app si connette esclusivamente alle API ufficiali di Nuvola '
                '(nuvola.madisoft.it) per recuperare, in sola lettura, i dati '
                'dell\'utente autenticato: voti, assenze, compiti.\n\n'
                'Nessun dato viene inviato a server aggiuntivi, condiviso con terze parti '
                'o utilizzato per scopi diversi dalla visualizzazione in-app.',
          ),
          _Section(
            icon: Icons.token_rounded,
            title: '3. Token di sessione',
            colorScheme: colorScheme,
            content: 'Il token JWT rilasciato da Nuvola al termine dell\'autenticazione viene '
                'conservato temporaneamente in memoria per la durata della sessione. '
                'Non viene scritto su disco al di fuori del keychain sicuro.',
          ),
          _Section(
            icon: Icons.code_rounded,
            title: '4. Codice open source',
            colorScheme: colorScheme,
            content: 'Il codice sorgente di Volta è interamente pubblico e liberamente '
                'ispezionabile su GitHub. Chiunque può verificare che l\'app non effettui '
                'operazioni non dichiarate in questa informativa.',
          ),
          _Section(
            icon: Icons.gavel_rounded,
            title: '5. Conformità al GDPR',
            colorScheme: colorScheme,
            content: 'Poiché Volta non tratta né conserva dati personali su propri server, '
                'non agisce in qualità di Titolare del Trattamento ai sensi del '
                'Regolamento (UE) 2016/679 (GDPR).\n\n'
                'Il trattamento dei dati da parte di Nuvola/Madisoft è disciplinato '
                'dalla loro informativa, consultabile al link qui sotto.',
            trailing: _LinkButton(
              label: 'Privacy Policy di Nuvola',
              onTap: () =>
                  _launchUrl('https://nuvola.madisoft.it/privacy-policy'),
            ),
          ),
          _Section(
            icon: Icons.security_rounded,
            title: '6. Sicurezza',
            colorScheme: colorScheme,
            content: '• Credenziali cifrate nel keychain del sistema operativo\n'
                '• Nessun log di dati personali in produzione\n'
                '• Comunicazioni con Nuvola esclusivamente via HTTPS\n'
                '• Nessuna analytics, telemetria o tracciamento',
          ),
          _Section(
            icon: Icons.child_care_rounded,
            title: '7. Minori',
            colorScheme: colorScheme,
            content: 'Volta è progettata per essere utilizzata da studenti, inclusi i minori. '
                'L\'app non raccoglie dati aggiuntivi rispetto a quelli strettamente '
                'necessari per autenticarsi su Nuvola e visualizzare i propri dati scolastici.',
          ),
          _Section(
            icon: Icons.forum_rounded,
            title: '8. Contatti',
            colorScheme: colorScheme,
            content: 'Per domande o segnalazioni relative a questa informativa, '
                'apri una issue nel repository GitHub del progetto.',
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Ultimo aggiornamento: marzo 2026',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _Header({required this.colorScheme, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.shield_rounded,
            size: 36,
            color: colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Privacy Policy',
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Volta — Client non ufficiale per Nuvola',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Nessun dato personale viene trasmesso a terzi',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final ColorScheme colorScheme;
  final Widget? trailing;

  const _Section({
    required this.icon,
    required this.title,
    required this.content,
    required this.colorScheme,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon,
                        size: 20, color: colorScheme.onSecondaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(height: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _LinkButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.open_in_new_rounded, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: color,
            ),
          ),
        ],
      ),
    );
  }
}
