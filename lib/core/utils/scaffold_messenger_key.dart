import 'package:flutter/material.dart';

/// Globaler ScaffoldMessenger-Key für app-weite SnackBars.
/// Wird in [MaterialApp.scaffoldMessengerKey] registriert (app.dart).
/// Nutzung in Widgets: scaffoldMessengerKey.currentState?.showSnackBar(...)
/// → Keine InheritedWidget-Dependency, kein _dependents.isEmpty Fehler.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
