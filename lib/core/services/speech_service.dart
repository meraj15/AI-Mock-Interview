import 'dart:async';

// ── Interfaces ────────────────────────────────────────────────────────────────

abstract class SpeechToTextService {
  /// Stream of partial transcript results
  Stream<String> get transcriptStream;
  Future<void> startListening();
  Future<void> stopListening();
  bool get isListening;
}

abstract class TextToSpeechService {
  Future<void> speak(String text);
  Future<void> stop();
  bool get isSpeaking;
  Stream<double> get speakingProgress; // 0.0 → 1.0
}

// ── Mock Implementation ───────────────────────────────────────────────────────

class MockSpeechService implements SpeechToTextService, TextToSpeechService {
  bool _isListening = false;
  bool _isSpeaking = false;
  final _transcriptController = StreamController<String>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  static const _samplePhrases = [
    'I applied Clean Architecture',
    'I applied Clean Architecture to isolate domain logic',
    'I applied Clean Architecture to isolate domain logic from the UI and data layers.',
    'I applied Clean Architecture to isolate domain logic from the UI and data layers. This made our business logic fully testable without running the application.',
  ];

  @override
  bool get isListening => _isListening;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  Stream<double> get speakingProgress => _progressController.stream;

  @override
  Future<void> startListening() async {
    _isListening = true;
    // Stream partial results word by word
    for (int i = 0; i < _samplePhrases.length; i++) {
      if (!_isListening) break;
      await Future.delayed(Duration(milliseconds: 450 + i * 120));
      if (_isListening) {
        _transcriptController.add(_samplePhrases[i]);
      }
    }
    _isListening = false;
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<void> speak(String text) async {
    _isSpeaking = true;
    final words = text.split(' ').length;
    final durationMs = (words * 85).clamp(800, 6000);
    final steps = 20;
    for (int i = 0; i <= steps; i++) {
      if (!_isSpeaking) break;
      await Future.delayed(Duration(milliseconds: durationMs ~/ steps));
      _progressController.add(i / steps);
    }
    _isSpeaking = false;
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    _isListening = false;
  }

  void dispose() {
    _transcriptController.close();
    _progressController.close();
  }
}
