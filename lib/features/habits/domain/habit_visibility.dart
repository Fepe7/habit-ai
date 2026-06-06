/// Enum de visibilidad para hábitos en el perfil público.
enum HabitVisibility {
  public('public'),
  followers('followers'),
  private('private');

  const HabitVisibility(this.value);
  final String value;

  static HabitVisibility fromString(String? raw) => HabitVisibility.values
      .firstWhere((v) => v.value == raw, orElse: () => HabitVisibility.private);

  bool get isVisibleToAnyone => this != HabitVisibility.private;
}
