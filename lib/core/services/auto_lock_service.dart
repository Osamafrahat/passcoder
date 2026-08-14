import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoLockService extends ChangeNotifier {
  Timer? _timer;
  int _timeoutMinutes = 5;
  bool _isLocked = false;
  bool get isLocked => _isLocked;

  int get timeoutMinutes => _timeoutMinutes;

  AutoLockService() {
    _loadTimeout();
  }

  Future<void> _loadTimeout() async {
    final prefs = await SharedPreferences.getInstance();
    _timeoutMinutes = prefs.getInt('auto_lock_minutes') ?? 5;
    notifyListeners();
  }

  Future<void> setTimeout(int minutes) async {
    _timeoutMinutes = minutes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_lock_minutes', minutes);
    notifyListeners();
    resetTimer();
  }

  void startTimer() {
    _timer?.cancel();
    if (_timeoutMinutes <= 0) return;
    _timer = Timer(Duration(minutes: _timeoutMinutes), () {
      _isLocked = true;
      notifyListeners();
    });
  }

  void resetTimer() {
    _isLocked = false;
    startTimer();
    notifyListeners();
  }

  void lockNow() {
    _timer?.cancel();
    _isLocked = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
