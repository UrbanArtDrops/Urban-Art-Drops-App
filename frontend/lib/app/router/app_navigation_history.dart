import "package:flutter/foundation.dart";

class AppNavigationHistory extends ChangeNotifier {
  AppNavigationHistory._();

  static final AppNavigationHistory instance = AppNavigationHistory._();

  final List<String> _locations = <String>[];
  int _currentIndex = -1;
  bool _skipNextRecord = false;

  void reset([String? initialLocation]) {
    _locations.clear();
    _currentIndex = -1;
    _skipNextRecord = false;

    final normalizedInitialLocation = _normalize(initialLocation);
    if (normalizedInitialLocation != null) {
      _locations.add(normalizedInitialLocation);
      _currentIndex = 0;
    }

    notifyListeners();
  }

  void record(String? location) {
    final normalizedLocation = _normalize(location);
    if (normalizedLocation == null) {
      return;
    }

    if (_skipNextRecord) {
      _skipNextRecord = false;
      if (_currentIndex >= 0 &&
          _currentIndex < _locations.length &&
          _locations[_currentIndex] == normalizedLocation) {
        notifyListeners();
        return;
      }
    }

    if (_currentIndex >= 0 && _locations[_currentIndex] == normalizedLocation) {
      return;
    }

    if (_currentIndex >= 1 &&
        _currentIndex - 1 < _locations.length &&
        _locations[_currentIndex - 1] == normalizedLocation) {
      _currentIndex -= 1;
      _locations.removeRange(_currentIndex + 1, _locations.length);
      notifyListeners();
      return;
    }

    if (_currentIndex >= 0 && _currentIndex < _locations.length - 1) {
      _locations.removeRange(_currentIndex + 1, _locations.length);
    }

    _locations.add(normalizedLocation);
    _currentIndex = _locations.length - 1;
    notifyListeners();
  }

  bool canGoBack(String? currentLocation) {
    _syncToCurrent(currentLocation);
    return _currentIndex > 0;
  }

  String? beginBackNavigation(String? currentLocation) {
    _syncToCurrent(currentLocation);
    if (_currentIndex <= 0) {
      return null;
    }

    _currentIndex -= 1;
    _skipNextRecord = true;
    notifyListeners();
    return _locations[_currentIndex];
  }

  void _syncToCurrent(String? currentLocation) {
    final normalizedCurrentLocation = _normalize(currentLocation);
    if (normalizedCurrentLocation == null) {
      return;
    }

    if (_currentIndex >= 0 &&
        _currentIndex < _locations.length &&
        _locations[_currentIndex] == normalizedCurrentLocation) {
      return;
    }

    final existingIndex = _locations.lastIndexOf(normalizedCurrentLocation);
    if (existingIndex >= 0) {
      _currentIndex = existingIndex;
      if (_currentIndex < _locations.length - 1) {
        _locations.removeRange(_currentIndex + 1, _locations.length);
      }
      notifyListeners();
      return;
    }

    record(normalizedCurrentLocation);
  }

  String? _normalize(String? location) {
    final trimmed = location?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null) {
      return trimmed;
    }

    final normalizedPath = uri.path.isEmpty ? "/" : uri.path;
    final normalizedUri = uri.replace(path: normalizedPath);
    return normalizedUri.toString();
  }
}
