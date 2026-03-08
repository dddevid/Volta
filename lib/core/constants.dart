class AppConstants {
  static const String baseUrl = 'https://nuvola.madisoft.it';

  static const String loginPage = '/login';
  static const String loginCheck = '/login_check';
  static const String salvaRuolo = '/salva-ruolo';
  static const String apiLoginFromWeb = '/api-studente/v1/login-from-web';

  static const String apiAlunni = '/api-studente/v1/alunni';
  static const String apiMenu = '/api-studente/v1/alunno/{id}/menu';
  static const String apiNotificheCount =
      '/api-studente/v1/alunno/{id}/notifiche/conteggio';
  static const String apiNews = '/api-studente/v1/alunno/{id}/help/news';
  static const String apiCompiti =
      '/api-studente/v1/alunno/{id}/compito/elenco/{date}';
  static const String apiArgomenti =
      '/api-studente/v1/alunno/{id}/argomento-lezione/elenco/{date}';
  static const String apiEventiClasse =
      '/api-studente/v1/alunno/{id}/eventi-classe';
  static const String apiEventiMateria =
      '/api-studente/v1/alunno/{id}/eventi-classe-materia';
  static const String apiEventiAlunno =
      '/api-studente/v1/alunno/{id}/eventi-alunno';
  static const String apiAssenze = '/api-studente/v1/alunno/{id}/assenze';
  static const String apiNote = '/api-studente/v1/alunno/{id}/note';
  static const String apiVoti = '/api-studente/v1/alunno/{id}/voti';
  static const String apiFrazioniTemporali =
      '/api-studente/v1/alunno/{id}/frazioni-temporali';
  static const String apiVotiMaterie =
      '/api-studente/v1/alunno/{id}/frazione-temporale/{frazioneId}/voti/materie';
  static const String apiPagamenti = '/api-studente/v1/alunno/{id}/pagamenti';

  static const String storageKeyJwtToken = 'jwt_token';
  static const String storageKeyUsername = 'username';
  static const String storageKeyPassword = 'password';
  static const String storageKeyRememberMe = 'remember_me';
  static const String storageKeySelectedStudent = 'selected_student_id';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const Duration tokenExpiryDuration =
      Duration(minutes: 28);

  static const int primaryColorValue = 0xFF0066CC;
  static const int secondaryColorValue = 0xFFFF9800;
  static const int successColorValue = 0xFF4CAF50;
  static const int errorColorValue = 0xFFF44336;
  static const int scaffoldBackgroundColor = 0xFFF5F5F5;

  static const String appName = 'Volta';
  static const String appVersion = '1.0.0';
}
