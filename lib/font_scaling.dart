import 'package:flutter/material.dart';

class FontScaling extends ChangeNotifier {
  double _factor = 1.0;

  double get factor => _factor;

  void setFactor(double newFactor) {
    _factor = newFactor;
    notifyListeners();
  }
}
