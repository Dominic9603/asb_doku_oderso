# RescueDoc - AI Coding Agent Instructions

## Project Overview

**RescueDoc** ist eine Flutter-App für professionelle Notfallsanitäter-Dokumentation mit strukturierten Einsatzberichten nach deutschem Standard. Die App ist lizenzgekoppelt und speichert Patientendaten lokal in SQLite.

## Architecture

### Core Layers
- **Services** (`lib/core/services/`): Singleton-Services für Datenbank, Lizenzierung
  - `DatabaseService.instance` → SQLite (Hauptquelle für Persistierung)
  - `LicenseService` → Secure Storage für App-Aktivierung
- **Features** (`lib/features/`): Feature-basierte Module mit klaren Grenzen
  - `documentation/` → Mission/Patient/ABCDE-Assessments (Kern-Dokumentation)
  - `medications/` → Medikamenten-Master-Daten
  - `isbar/` → ISBAR Übergabeberichte
  - `authentication/` → License-Aktivierung
- **Shared** (`lib/shared/`): Theme, globale Widgets

### Data Flow Pattern
1. **DatabaseService** (SQLite) → Ground Truth
2. **Repository** abstrakt (Interface) → Query-Logik
   - `MissionRepository` (SQLiteMissionRepository)
   - `MedicationRepository`
   - `ISBARRepository`
3. **Provider** (ChangeNotifier) → App-State, notifyListeners() bei Änderungen
4. **Screen/Widget** → watch/read Provider → notifyListeners()

**Wichtig**: Repositories sind saubere SQLite-Wrapper. Geschäftslogik gehört in Provider, nicht in Repository.

## Database Schema Highlights

- **missions** → Parent (id, status, timestamps)
- **patients** → 1:1 zu Mission
- **abcde_assessments** → Multi-Record pro Mission (Mehrfach-Dokumentation während Einsatz)
- **vital_signs**, **measures** → Zeitbasierte Events
- **medications** → Master-Table (global, nicht pro Mission)
- **isbar_handovers** → 1:1 Übergabebericht pro Mission

**Alle IDs sind UUIDs** (package:uuid). **Timestamps sind Integer** (millisecondsSinceEpoch).

## Key Patterns

### 1. Provider Initialization (`main.dart`)
```dart
// Repositories werden mit DatabaseService erzeugt
final missionRepository = SQLiteMissionRepository(databaseService);
// Provider erhalten Repository im Constructor
ChangeNotifierProvider(
  create: (context) => MissionProvider(missionRepository),
)
```
**Regel**: Jeder Provider hat genau ein Repository.

### 2. Model Layer
- `toMap()` für SQLite-Persistierung
- `fromMap()` Factory-Constructor für Deserialisierung
- Immutability (final fields)
- Beispiel: [lib/features/documentation/models/mission.dart](lib/features/documentation/models/mission.dart#L1)

### 3. State Reloading
Immer `loadAll()` nach `addOrUpdate()`:
```dart
Future<void> addOrUpdateMedication(Medication med) async {
  await _repo.insertMedication(med);
  await loadAll();  // ← Refresh aus DB
  notifyListeners();
}
```

### 4. Documentation Tab Structure (ABCDE)
- **c-Tab** → Critical Bleeding
- **A-Tab** → Airway
- **B-Tab** → Breathing
- **C-Tab** → Circulation
- **D-Tab** → Disability (GCS, Pupillen, Blutzucker)
- **E-Tab** → Exposure/Environment

Jede Tab ist eigenständiges StatefulWidget mit TextController, speichert direkt in `MissionProvider.addOrUpdateABCDE()`.

## Localization & Language

- **Hauptsprache**: Deutsch (de_DE)
- **Fallback**: Englisch (en_US)
- Gesetzt in `app.dart`: `locale: Locale('de', 'DE')`
- Verwende `flutter_localizations` für Material-Strings
- Härtcodierte Strings sind in Deutsch → Kein i18n-System (nur 2 Locales)

## Styling & Theme

- **Theme** in `shared/theme/app_theme.dart` (lightTheme, darkTheme)
- **Colors** zentral in `AppColors` (Primary = Emergency-Orange)
- **Icons** = Material-Icons (Icons.whatever)
- Dark-Mode: `ThemeMode.system` (folgt OS-Setting)

## Important Services

### LicenseService
- Prüft Aktivierung via `isActivated()`
- Speichert Key in **Flutter Secure Storage** (OS-native)
- Validation: `_validateKey()` mit Crypto-Hash
- **Debug**: `generateValidKey()` für Testing

### DatabaseService (Singleton)
- Lazy-Initialize: `DatabaseService.instance.initialize()` in `main()`
- **Nicht** in Tests neu initialisieren ohne Close
- OnCreate-Version: 1 (Migrations in `_onUpgrade()` später)

## Feature-Specific Notes

### Documentation (Mission Feature)
- Mission = Oberste Dokumentations-Unit
- 1 Patient pro Mission (1:1)
- Multiple ABCDE-Assessments (N:1) → Zeitreihe
- Tabs speichern direkt (nicht Draft-Pattern)
- `MissionProvider.latestABCDE` → Letzter Assessment

### Medications
- Master-Table (Datensatz-Verwaltung, nicht pro Mission)
- Suchfunktion: COLLATE NOCASE (case-insensitive)
- Kategorisierung: `sections_csv` (komma-getrennt für A/B/C/D/E Zuordnung)
- Nicht ändern während aktiver Mission (nur Lesen)

### ISBAR Handover
- 1:1 pro Mission (UNIQUE constraint auf mission_id)
- Standalone-Feature (eigener Screen)
- Template für Übergabe an Klinik

## Testing & Build

- **Hive** (lokaler Cache, aktuell minimal genutzt)
- **Flutter Analyze**: `flutter analyze` (linting)
- **Build**: `flutter build apk` (Android) oder `.ipa` (iOS)
- **Test**: `flutter test` (Unit/Widget Tests in `test/` Ordner)

## Common Pitfalls

❌ **Nicht**: Logik in Repositories  
✅ **Ja**: Geschäftslogik in Provider, Repositories sind reine Datenquellen

❌ **Nicht**: Direkter DB-Zugriff in Widgets  
✅ **Ja**: Über Provider.watch/read

❌ **Nicht**: Modelle mit Mutationen (setField(), etc.)  
✅ **Ja**: Immutable Models + neue Instanz erzeugen

❌ **Nicht**: Mehrere Provider pro Feature-Datenquelle  
✅ **Ja**: Ein Provider pro Repository (z.B. MissionProvider nur für Missions)

## Code Generation

- **build_runner**: `flutter pub run build_runner build` (für hive_generator)
- **Hive Models**: `@HiveType()` Annotation (noch nicht vollständig genutzt)

## Next Steps for New Features

1. **Model** schreiben (toMap/fromMap)
2. **Schema** in DatabaseService.\_onCreate() hinzufügen
3. **Repository Interface + Implementation** schreiben (abstrakt + SQLite)
4. **Provider** mit ChangeNotifier + Repository
5. **Screen** + Widgets (Provider.watch/read)
6. **In main.dart** registrieren (Provider hinzufügen)
