import 'package:flutter/material.dart';
import 'package:remote_auth_module/src/domain/entities/country.dart';

class CountrySelectorBottomSheet extends StatelessWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onCountrySelected;

  const CountrySelectorBottomSheet({
    super.key,
    required this.selectedCountry,
    required this.onCountrySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Country',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: Country.all.length,
              itemBuilder: (context, index) {
                final country = Country.all[index];
                final isSelected = country.isoCode == selectedCountry.isoCode;

                return ListTile(
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(country.name),
                  trailing: Text(
                    country.dialCode,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    onCountrySelected(country);
                    Navigator.pop(context);
                  },
                  tileColor:
                      isSelected
                          ? theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.3,
                          )
                          : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
