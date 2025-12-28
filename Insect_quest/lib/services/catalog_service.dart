import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CatalogService {
  late Map<String, dynamic> catalog;

  Future<void> loadCatalog() async {
    final txt = await rootBundle.loadString('assets/catalogs/species_catalog_ga.json');
    catalog = jsonDecode(txt);
  }

  Map<String, dynamic>? findBySpecies(String species) {
    for (final group in catalog["groups"]) {
      for (final entry in group["entries"]) {
        if ((entry["species"] ?? "") == species) {
          return {"group": group["group"], "entry": entry};
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? findByGenus(String genus) {
    for (final group in catalog["groups"]) {
      for (final entry in group["entries"]) {
        // Check explicit genus field
        if ((entry["genus"] ?? "") == genus) {
          return {"group": group["group"], "entry": entry};
        }
        // Check genus from species field (first word of species name)
        final species = entry["species"];
        if (species != null && species.isNotEmpty) {
          final trimmed = species.trim();
          if (trimmed.isNotEmpty) {
            final parts = trimmed.split(" ");
            if (parts.isNotEmpty && parts[0].isNotEmpty && parts[0] == genus) {
              return {"group": group["group"], "entry": entry};
            }
          }
        }
      }
    }
    return null;
  }

  // Simple helper to pick state species when applicable
  List<Map<String, dynamic>> stateSpeciesGeorgia() {
    final res = <Map<String, dynamic>>[];
    for (final group in catalog["groups"]) {
      for (final entry in group["entries"]) {
        final flags = Map<String, dynamic>.from(entry["flags"] ?? {});
        if (flags["state_species"] == true) {
          res.add({"group": group["group"], "entry": entry});
        }
      }
    }
    return res;
  }
}