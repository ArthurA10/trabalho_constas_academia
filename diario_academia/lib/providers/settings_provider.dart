import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  final bool useLbs;
  final int defaultRestTime; // Em segundos

  AppSettings({this.useLbs = false, this.defaultRestTime = 60});

  AppSettings copyWith({bool? useLbs, int? defaultRestTime}) {
    return AppSettings(
      useLbs: useLbs ?? this.useLbs,
      defaultRestTime: defaultRestTime ?? this.defaultRestTime,
    );
  }
}

// 1. Trocamos StateNotifier por Notifier
class SettingsNotifier extends Notifier<AppSettings> {
  
  // 2. Usamos o método obrigatório build() em vez do super()
  @override
  AppSettings build() {
    _loadSettings(); // Dispara o carregamento no fundo
    return AppSettings(); // Retorna o estado inicial imediato
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final useLbs = prefs.getBool('useLbs') ?? false;
    final defaultRestTime = prefs.getInt('defaultRestTime') ?? 60;
    
    // Atualiza o estado quando os dados terminarem de carregar
    state = AppSettings(useLbs: useLbs, defaultRestTime: defaultRestTime);
  }

  Future<void> toggleUnit(bool useLbs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useLbs', useLbs);
    state = state.copyWith(useLbs: useLbs);
  }

  Future<void> updateRestTime(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('defaultRestTime', seconds);
    state = state.copyWith(defaultRestTime: seconds);
  }
}

// 3. Trocamos StateNotifierProvider por NotifierProvider
final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(() {
  return SettingsNotifier();
});