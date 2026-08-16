abstract class SpeechToTextService {
  Future<void> startListening({required Function(String transcript) onResult});
  Future<void> stopListening();
  bool get isListening;
}

abstract class TextToSpeechService {
  Future<void> speak(String text);
  Future<void> stop();
  bool get isSpeaking;
}

class MockSpeechService implements SpeechToTextService, TextToSpeechService {
  bool _isListening = false;
  bool _isSpeaking = false;

  @override
  bool get isListening => _isListening;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> startListening({required Function(String transcript) onResult}) async {
    _isListening = true;
    await Future.delayed(const Duration(milliseconds: 1800));
    if (_isListening) {
      onResult('I separated the data layer from the UI and made failures recoverable.');
    }
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
  }

  @override
  Future<void> speak(String text) async {
    _isSpeaking = true;
    await Future.delayed(const Duration(milliseconds: 1500));
    _isSpeaking = false;
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
  }
}
