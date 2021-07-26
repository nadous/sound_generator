import 'dart:async';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';

/// Wave Types
enum WaveForm { sine, square, triangle, sawtooth }

class SoundGenerator {
  static const MethodChannel _channel = const MethodChannel('sound_generator');
  static const EventChannel _onChangeIsPlaying = const EventChannel('io.github.mertguner.sound_generator/onChangeIsPlaying');

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

  /// Release all data
  static void release() => _channel.invokeMethod('release');

  /// Play sound
  static Future<void> start(String uid, double frequency, {WaveForm waveForm = WaveForm.sine}) => _channel.invokeMethod(
        'start',
        {'uid': uid, 'frequency': frequency, 'wave_form': EnumToString.convertToString(waveForm)},
      );

  /// Stop playing sound
  static void stop(String uid) => _channel.invokeMethod('stop', {"uid": uid});

  /// Change frequency of given sound
  static void setFrequency(String uid, double frequency) => _channel.invokeMethod('set_frequency', {'uid': uid, 'frequency': frequency});

  /// Get frequency of given sound
  static Future<double> getFrequency(String uid) async {
    final double frequency = await _channel.invokeMethod('get_frequency', {'uid': uid});
    return frequency;
  }

  /// Change sample rate of all sounds
  static void setSampleRate(double sampleRate) => _channel.invokeMethod('set_sample_rate', {'sample_rate': sampleRate});

  /// Get sample rate
  static Future<int> getSampleRate() async {
    final int sampleRate = await _channel.invokeMethod('set_sample_rate');
    return sampleRate;
  }

  /// Get is Playing data
  static Future<bool> get isPlaying async {
    final bool playing = await _channel.invokeMethod('is_playing');
    return playing;
  }

  /// Set Volume Range from 0 to 1
  static Future<void> setVolume(double volume) => _channel.invokeMethod("set_volume", {"volume": volume});
}
