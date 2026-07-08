import 'package:shared_preferences/shared_preferences.dart';

/// Gestiona si el tour de bienvenida ya fue mostrado al usuario.
/// Guarda el estado en SharedPreferences para que solo aparezca una vez.
/// Llamar [resetAll] desde Ajustes para que el tour vuelva a mostrarse.
class TourService {
  static const _keyUser = 'tour_done_user_v1';
  static const _keyHome = 'tour_done_home_v2';
  static const _keyTutor = 'tour_done_tutor_v1';
  static const _keyTutorEmpty = 'tour_done_tutor_empty_v1';

  static Future<bool> needsUserTour() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyUser) ?? false);
  }

  static Future<bool> needsHomeTour() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyHome) ?? false);
  }

  static Future<bool> needsTutorTour() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyTutor) ?? false);
  }

  static Future<bool> needsTutorEmptyTour() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyTutorEmpty) ?? false);
  }

  static Future<void> markUserTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUser, true);
  }

  static Future<void> markHomeTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHome, true);
  }

  static Future<void> markTutorTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTutor, true);
  }

  static Future<void> markTutorEmptyTourDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTutorEmpty, true);
  }

  /// Reinicia todos los tours (útil desde la pantalla de Ajustes).
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyHome);
    await prefs.remove(_keyTutor);
    await prefs.remove(_keyTutorEmpty);
  }
}
