import 'package:flutter/material.dart';

class LiquidGlassProvider extends ChangeNotifier {
  bool _isLiquidGlass = true;

  bool get isLiquidGlass => _isLiquidGlass;

  void toggleLiquidGlass(bool value) {
    _isLiquidGlass = value;
    notifyListeners();
  }
}