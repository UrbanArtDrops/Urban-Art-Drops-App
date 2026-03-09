import "package:flutter_bloc/flutter_bloc.dart";

sealed class DiscoveryFilterState {
  const DiscoveryFilterState();
}

final class DiscoveryFilterInitial extends DiscoveryFilterState {
  const DiscoveryFilterInitial();
}

final class DiscoveryFilterLocationSet extends DiscoveryFilterState {
  const DiscoveryFilterLocationSet({required this.locationLabel});

  final String locationLabel;
}

class DiscoveryFilterCubit extends Cubit<DiscoveryFilterState> {
  DiscoveryFilterCubit() : super(const DiscoveryFilterInitial());

  void setManualLocation(String locationLabel) {
    final trimmed = locationLabel.trim();
    if (trimmed.isEmpty) {
      emit(const DiscoveryFilterInitial());
      return;
    }

    emit(DiscoveryFilterLocationSet(locationLabel: trimmed));
  }

  void clearLocation() => emit(const DiscoveryFilterInitial());
}
