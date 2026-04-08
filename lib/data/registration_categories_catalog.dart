/// Canonical category + subcategory labels for student registration.
/// The app filters `GET /api/categories` to this order and naming; the backend
/// should return matching records with real UUID `id` values.
class RegistrationCategoriesCatalog {
  RegistrationCategoriesCatalog._();

  static String _norm(String s) {
    return s
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }

  static Iterable<String> _candidateNames(Map<String, dynamic> map) sync* {
    for (final key in ['name_ar', 'name', 'name_en']) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        yield value;
      }
    }
  }

  /// Categories in display order (Arabic labels).
  static const List<({String displayName, Set<String> matchKeys})>
      categorySpecs = [
    (displayName: 'بشري', matchKeys: {'بشري', 'البشري'}),
    (displayName: 'اسنان', matchKeys: {'اسنان', 'أسنان', 'الاسنان', 'الأسنان'}),
    (
      displayName: 'علاج طبيعي',
      matchKeys: {'علاج طبيعي', 'العلاج الطبيعي'}
    ),
    (displayName: 'صيدله', matchKeys: {'صيدله', 'صيدلة', 'الصيدلة'}),
    (displayName: 'تمريض', matchKeys: {'تمريض', 'التمريض'}),
    (displayName: 'علوم', matchKeys: {'علوم', 'العلوم'}),
    (displayName: 'تربية', matchKeys: {'تربية', 'التربية'}),
  ];

  /// Subcategories (academic years) in display order.
  static const List<({String displayName, Set<String> matchKeys})>
      subcategorySpecs = [
    (displayName: 'الأولى', matchKeys: {'الأولى', 'الاولى'}),
    (displayName: 'الثانية', matchKeys: {'الثانية'}),
    (displayName: 'الثالثة', matchKeys: {'الثالثة'}),
    (
      displayName: 'الرابعة',
      matchKeys: {'الرابعة', 'الرايعة', 'الرابعه'}
    ),
    (displayName: 'الخامسة', matchKeys: {'الخامسة'}),
    (displayName: 'السادسة', matchKeys: {'السادسة'}),
  ];

  static bool _matchesAnyCandidate(
    Map<String, dynamic> item,
    Set<String> keys,
  ) {
    final normalizedKeys = keys.map(_norm).toSet();
    for (final candidate in _candidateNames(item)) {
      if (normalizedKeys.contains(_norm(candidate))) {
        return true;
      }
    }
    return false;
  }

  static List<Map<String, dynamic>> _rawSubcategories(
    Map<String, dynamic> category,
  ) {
    for (final key in ['subcategories', 'sub_categories', 'children']) {
      final raw = category[key];
      if (raw is List) {
        return raw
            .map((e) => e is Map<String, dynamic>
                ? e
                : Map<String, dynamic>.from(e as Map))
            .toList();
      }
    }
    return [];
  }

  /// Returns subcategories in canonical order; uses API `id` when matched.
  static List<Map<String, dynamic>> filterSubcategories(
    List<Map<String, dynamic>> rawSubs,
  ) {
    final out = <Map<String, dynamic>>[];
    for (final spec in subcategorySpecs) {
      Map<String, dynamic>? match;
      for (final subcategory in rawSubs) {
        if (_matchesAnyCandidate(subcategory, spec.matchKeys)) {
          match = subcategory;
          break;
        }
      }
      if (match == null) continue;

      final copy = Map<String, dynamic>.from(match);
      copy['name'] = spec.displayName;
      copy['name_ar'] = spec.displayName;
      out.add(copy);
    }
    return out;
  }

  static List<Map<String, dynamic>> _orderBasedSubcategories(
    List<Map<String, dynamic>> rawSubs,
  ) {
    final sorted = [...rawSubs];
    sorted.sort((a, b) {
      final ao = int.tryParse(a['order']?.toString() ?? '') ?? 9999;
      final bo = int.tryParse(b['order']?.toString() ?? '') ?? 9999;
      return ao.compareTo(bo);
    });

    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < subcategorySpecs.length && i < sorted.length; i++) {
      final copy = Map<String, dynamic>.from(sorted[i]);
      copy['name'] = subcategorySpecs[i].displayName;
      copy['name_ar'] = subcategorySpecs[i].displayName;
      out.add(copy);
    }
    return out;
  }

  /// Filters and orders categories from the API for registration pickers.
  static List<Map<String, dynamic>> filterApiCategories(
    List<Map<String, dynamic>> raw,
  ) {
    final out = <Map<String, dynamic>>[];
    for (final spec in categorySpecs) {
      Map<String, dynamic>? match;
      for (final category in raw) {
        if (_matchesAnyCandidate(category, spec.matchKeys)) {
          match = category;
          break;
        }
      }
      if (match == null) continue;

      final copy = Map<String, dynamic>.from(match);
      copy['name'] = spec.displayName;
      copy['name_ar'] = spec.displayName;

      final subcategories = filterSubcategories(_rawSubcategories(copy));
      copy['subcategories'] = subcategories;
      copy['sub_categories'] = subcategories;
      copy.remove('children');

      out.add(copy);
    }

    // Perfect name match (ideal backend state).
    if (out.length == categorySpecs.length) {
      return out;
    }

    // Fallback: map by endpoint order while preserving backend IDs.
    // This keeps register usable even if names have encoding/normalization issues.
    final sorted = [...raw];
    sorted.sort((a, b) {
      final ao = int.tryParse(a['order']?.toString() ?? '') ?? 9999;
      final bo = int.tryParse(b['order']?.toString() ?? '') ?? 9999;
      return ao.compareTo(bo);
    });

    final orderedOut = <Map<String, dynamic>>[];
    for (var i = 0; i < categorySpecs.length && i < sorted.length; i++) {
      final copy = Map<String, dynamic>.from(sorted[i]);
      copy['name'] = categorySpecs[i].displayName;
      copy['name_ar'] = categorySpecs[i].displayName;

      final rawSubs = _rawSubcategories(copy);
      var subcategories = filterSubcategories(rawSubs);
      if (subcategories.length != subcategorySpecs.length && rawSubs.isNotEmpty) {
        subcategories = _orderBasedSubcategories(rawSubs);
      }

      copy['subcategories'] = subcategories;
      copy['sub_categories'] = subcategories;
      copy.remove('children');
      orderedOut.add(copy);
    }

    return orderedOut;
  }

  /// Emergency fallback list (from backend seed) so register remains usable
  /// when category fetching/parsing fails on-device.
  static List<Map<String, dynamic>> seededFallbackCategories() {
    return [
      {
        'id': '9f4c0f41-06d0-4c84-962e-53cb2f7f0a11',
        'name': 'بشري',
        'name_ar': 'بشري',
        'subcategories': _seededSubs(
          '17a6786f-6738-4725-9707-e0d1dd7bea6b',
          '2a868970-f3a3-4c18-b425-c5d2538d69c9',
          '38bf4fbb-7603-4882-91db-0183fd4f2a66',
          '0c796897-8ee5-4d0a-a4b2-65720f80eeea',
          '83a26b5d-53f4-4bd9-b5f9-f8547f74ccdd',
          'cc30ea67-150f-4b95-aeca-6b58e17f56f7',
        ),
      },
      {
        'id': '2cceba4b-6f2e-4d3f-a90a-1b33ec4aa0f2',
        'name': 'اسنان',
        'name_ar': 'اسنان',
        'subcategories': _seededSubs(
          'bc95ec3c-c9f2-462f-ba1b-f340f70ca9b7',
          '1bdb6ec0-9328-4b15-8fb0-a7b55c1aa34b',
          '2f88f2fc-3584-4d7f-b0f8-ca8eefe31f64',
          '5c5ed993-a29f-44cb-9a41-0f92fda9c9f0',
          '77ffdab6-a3b9-410f-8ed9-a5c7c38c4ad5',
          'a8f3ce2c-4d1d-425e-b9da-0ed828551bb9',
        ),
      },
      {
        'id': '2d5d9d8f-1938-4578-bf12-7a5186409ea7',
        'name': 'علاج طبيعي',
        'name_ar': 'علاج طبيعي',
        'subcategories': _seededSubs(
          '8c3dbc8f-496f-4743-9931-0bc2dcf07f0d',
          '7d67d8a4-61ec-4ca4-b6a1-05223b3ceb7d',
          '73fe33e5-d194-486f-b76d-c2d5eef8fab9',
          '76ba9de4-2daf-4ad8-8e8f-246955173fa3',
          '18b5f4e5-2378-4505-a328-308e2f1d1831',
          '4bc34f59-8613-4e98-a8d8-9a66d5504ff4',
        ),
      },
      {
        'id': '80e5d975-5101-4c44-8f32-641f3ec099f9',
        'name': 'صيدله',
        'name_ar': 'صيدله',
        'subcategories': _seededSubs(
          '53d52373-2b45-45a4-b2c3-c9f6afd77d43',
          'be4a1145-77d9-4724-99a3-45a8d48889a2',
          'db4dba77-46ef-4562-9814-c83e8d7b66d0',
          '98b311eb-7275-4128-b5e2-c3ae749f95e4',
          '5d655f3a-9724-412a-bcc4-805945f4a07e',
          'cc96c0d3-7c61-4c03-b7be-8a07176fd37b',
        ),
      },
      {
        'id': '34c35ef4-84f6-430f-8612-4fca1f51420b',
        'name': 'تمريض',
        'name_ar': 'تمريض',
        'subcategories': _seededSubs(
          'ee5c8fcb-ef73-4e59-89ef-5664e770b432',
          '12f8f64a-4df4-4a88-bf83-f8cd4cc1e9f9',
          '500f5e77-0bb0-49fb-a867-8cb7f326f4ca',
          '18ab9e21-db97-4f4a-b514-f9930f7a4caf',
          '5f56f272-2de4-4110-91cf-f50b8065dca9',
          '68e5d5f6-62b5-4918-82dd-c9157295a8ca',
        ),
      },
      {
        'id': 'c73fd860-07a8-46e3-b6f6-9f90726f8a53',
        'name': 'علوم',
        'name_ar': 'علوم',
        'subcategories': _seededSubs(
          '461d78de-83c3-4235-b9a1-ff66b153f2bc',
          '7eeb8f50-f98f-47b1-81bf-24de57fd9582',
          '1746237a-b5d8-4c42-b95e-73f1724c5c4f',
          '40f3c57b-2d4b-490a-b328-5522de62f707',
          'd3fb79c6-7fa6-4022-b415-6449c56be5eb',
          '03a2ed3b-f57f-4e3d-bf44-4cc38afcb66c',
        ),
      },
      {
        'id': '8d34345e-8e91-4a96-9ff5-446e45f644d1',
        'name': 'تربية',
        'name_ar': 'تربية',
        'subcategories': _seededSubs(
          '6bff3cdc-6a6d-4af7-9564-7a93b20d7bab',
          '454dac07-58e4-4c87-97ee-479bd9aa73c4',
          'a2adbd89-08dc-4460-9c1d-4b6622fdf3dd',
          '03bbd77d-8d84-401f-a227-9d687ec2fdfa',
          'f0f69995-3ac0-4edf-9fd3-b4cda4b7dd61',
          '8ea9e172-04ab-4a08-b906-e3ff3eef5008',
        ),
      },
    ].map((category) {
      final copy = Map<String, dynamic>.from(category);
      copy['sub_categories'] = copy['subcategories'];
      return copy;
    }).toList();
  }

  static List<Map<String, dynamic>> _seededSubs(
    String id1,
    String id2,
    String id3,
    String id4,
    String id5,
    String id6,
  ) {
    return [
      {'id': id1, 'name': 'الأولى', 'name_ar': 'الأولى'},
      {'id': id2, 'name': 'الثانية', 'name_ar': 'الثانية'},
      {'id': id3, 'name': 'الثالثة', 'name_ar': 'الثالثة'},
      {'id': id4, 'name': 'الرابعة', 'name_ar': 'الرابعة'},
      {'id': id5, 'name': 'الخامسة', 'name_ar': 'الخامسة'},
      {'id': id6, 'name': 'السادسة', 'name_ar': 'السادسة'},
    ];
  }
}
