import 'dart:async';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';

/// Wave Types
enum WaveForm { sine, square, triangle, sawtooth }

class SoundGenerator {
  static const MethodChannel _channel = const MethodChannel('sound_generator');
  static const EventChannel _onChangeIsPlaying = const EventChannel('io.github.mertguner.sound_generator/onChangeIsPlaying');
  static const EventChannel _onOneCycleDataHandler = const EventChannel('io.github.mertguner.sound_generator/onOneCycleDataHandler');

  /// is Playing data changed event
  static bool _onIsPlayingChangedInitialized = false;
  static late Stream<Map<String, dynamic>> _onIsPlayingChanged;
  static Stream<Map<String, dynamic>> get onIsPlayingChanged {
    if (!_onIsPlayingChangedInitialized) {
      _onIsPlayingChanged = _onChangeIsPlaying.receiveBroadcastStream().map<Map<String, dynamic>>((source) => Map.castFrom<dynamic, dynamic, String, dynamic>(source));
      _onIsPlayingChangedInitialized = true;
    }

    return _onIsPlayingChanged;
  }

  /// One cycle data changed event
  static bool _onGetOneCycleDataHandlerInitialized = false;
  static late Stream<List<int>> _onGetOneCycleDataHandler;
  static Stream<List<int>> get onOneCycleDataHandler {
    if (!_onGetOneCycleDataHandlerInitialized) {
      _onGetOneCycleDataHandler = _onOneCycleDataHandler.receiveBroadcastStream().map<List<int>>((value) => new List<int>.from(value));
      _onGetOneCycleDataHandlerInitialized = true;
    }

    return _onGetOneCycleDataHandler;
  }

  /// Play sound
  static Future<void> play(String uid, double frequency, {WaveForm waveForm = WaveForm.sine}) => _channel.invokeMethod(
        'play',
        {'uid': uid, 'frequency': frequency, 'wave_form': EnumToString.convertToString(waveForm)},
      );

  /// Stop playing sound
  static void stop(String uid) => _channel.invokeMethod('stop', {"uid": uid});

  /// Release all data
  static void release() => _channel.invokeMethod('release');

  /// Refresh One Cycle Data
  static void refreshOneCycleData() async => _channel.invokeMethod('refresh_one_cycle_data');

  /// Get is Playing data
  static Future<bool> get isPlaying async {
    final bool playing = await _channel.invokeMethod('is_playing');
    return playing;
  }

  /// Set AutoUpdateOneCycleSample
  static Future<void> setAutoUpdateOneCycleSample(bool autoUpdateOneCycleSample) => _channel.invokeMethod(
        "set_auto_update_one_cycle_sample",
        {"auto_update_one_cycle_sample": autoUpdateOneCycleSample},
      );

  /// Set Balance Range from -1 to 1
  static Future<void> setBalance(double balance) => _channel.invokeMethod("set_balance", {"balance": balance});

  /// Set Volume Range from 0 to 1
  static Future<void> setVolume(double volume) => _channel.invokeMethod("set_volume", {"volume": volume});
}
