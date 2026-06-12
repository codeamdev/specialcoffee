import 'package:hive/hive.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/constants/app_constants.dart';

part 'settings_provider.g.dart';

class AppSettings {
  const AppSettings({this.learningMode = true});

  final bool learningMode;

  AppSettings copyWith({bool? learningMode}) =>
      AppSettings(learningMode: learningMode ?? this.learningMode);
}

@Riverpod(keepAlive: true)
class SettingsNotifier extends _$SettingsNotifier {
  static const _kLearningMode = 'learning_mode';

  Box<dynamic> get _box => Hive.box<dynamic>(AppConstants.hiveBoxPreferences);

  @override
  AppSettings build() {
    final mode = _box.get(_kLearningMode, defaultValue: true) as bool;
    return AppSettings(learningMode: mode);
  }

  Future<void> setLearningMode(bool value) async {
    await _box.put(_kLearningMode, value);
    state = state.copyWith(learningMode: value);
  }
}

/// Acceso rápido al modo aprendizaje — úsalo con `ref.watch(learningModeProvider)`.
@riverpod
bool learningMode(Ref ref) =>
    ref.watch(settingsProvider).learningMode;
