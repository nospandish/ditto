class AvailableTimeBlock {
  const AvailableTimeBlock({
    required this.startMinutes,
    required this.endMinutes,
  });

  final int startMinutes;
  final int endMinutes;

  int get durationMinutes => endMinutes - startMinutes;

  bool overlaps(AvailableTimeBlock other) {
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }
}
