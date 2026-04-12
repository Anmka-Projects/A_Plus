/// Medical category tiles on the home screen — slugs must match backend `category_slug` / categories.slug.
enum MedicalTrack {
  doctor,
  dentist,
  physiotherapist,
  pharmacist,
  nurse,
  scientist;

  /// Stable API slug (see docs/BACKEND_HOME_MEDICAL_CATEGORY_COURSES.md).
  String get slug => name;
}
