/// Zentrale App-Konfiguration
class AppConfig {
  AppConfig._();

  // ==================== LIZENZ-KEYS ====================
  // URL zur keys.json auf GitHub (Raw-URL eines Secret Gist oder Repo)
  // Erstelle ein Secret Gist unter https://gist.github.com
  // Trage hier die Raw-URL ein ("Raw" Button im Gist klicken)
  static const String keysUrl = 'https://gist.githubusercontent.com/Dominic9603/34bb50d8d637916c99703f00de0e35ff/raw/keys.json';

  // ==================== SUPABASE ====================
  // → Erstelle ein kostenloses Projekt unter https://supabase.com
  // → Gehe zu Project Settings → API → dort findest du URL + anon key
  // → Erstelle einen Storage-Bucket namens "einsatzberichte" (nicht-öffentlich)
  static const String supabaseUrl = 'DEINE_SUPABASE_URL'; // z.B. https://abc123.supabase.co
  static const String supabaseAnonKey = 'DEIN_SUPABASE_ANON_KEY';
  static const String storageBucket = 'einsatzberichte';

  // ==================== EMAIL ====================
  // Empfänger-Email wird im Setup-Screen eingegeben und in UserInfo gespeichert

  // ==================== LINK-GÜLTIGKEIT ====================
  // Signed-URL Ablaufzeit in Sekunden (30 Minuten = 1800)
  static const int linkExpirySeconds = 30 * 60;
}
