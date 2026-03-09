import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:urban_art_drops_app/l10n/app_localizations.dart";

import "../../../../shared/widgets/page_shell.dart";
import "../bloc/discovery_filter_cubit.dart";

class DropListPage extends StatelessWidget {
  const DropListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locationController = TextEditingController();

    return BlocProvider(
      create: (_) => DiscoveryFilterCubit(),
      child: BlocBuilder<DiscoveryFilterCubit, DiscoveryFilterState>(
        builder: (context, state) {
          final hasLocation = state is DiscoveryFilterLocationSet;

          return PageShell(
            title: l10n.navDrops,
            body: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.searchSortTitle),
                        const SizedBox(height: 8),
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            labelText: l10n.manualLocationLabel,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                context
                                    .read<DiscoveryFilterCubit>()
                                    .setManualLocation(locationController.text);
                              },
                            ),
                          ),
                        ),
                        if (hasLocation)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(l10n.distanceColumnVisible),
                          ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(l10n.sampleDropTitle),
                    subtitle: Text(l10n.sampleDropSubtitle),
                    trailing: hasLocation
                        ? Text(l10n.distanceValue("2.4"))
                        : null,
                  ),
                ),
                Card(
                  child: ListTile(
                    title: Text(l10n.sampleDropTitleTwo),
                    subtitle: Text(l10n.sampleDropSubtitle),
                    trailing: hasLocation
                        ? Text(l10n.distanceValue("5.1"))
                        : null,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
