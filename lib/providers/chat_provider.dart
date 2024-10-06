import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  bool _isChatVisible = false;

  bool get isChatVisible => _isChatVisible;

  void toggleChat() {
    _isChatVisible = !_isChatVisible;
    notifyListeners();
  }
}
