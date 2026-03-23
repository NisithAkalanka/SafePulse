import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide Help flow role: **Requester** (post/need help) vs **Helper** (offer help).
/// Persisted so the choice survives restarts.
class HelpRoleModeService {
  HelpRoleModeService._();
  static final HelpRoleModeService instance = HelpRoleModeService._();

  static const _key = 'safepulse_help_is_helper_mode';

  /// `true` = Helper mode (browse & offer help). `false` = Requester mode (create requests).
  final ValueNotifier<bool> isHelperMode = ValueNotifier<bool>(false);

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    isHelperMode.value = p.getBool(_key) ?? false;
  }

  Future<void> setHelperMode(bool helper) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, helper);
    isHelperMode.value = helper;
  }

  /// Toggle between helper ↔ requester.
  Future<void> toggle() async {
    await setHelperMode(!isHelperMode.value);
  }
}
