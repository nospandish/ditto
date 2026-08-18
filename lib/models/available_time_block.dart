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

  Map<String, dynamic> toJson() {
    return {'startMinutes': startMinutes, 'endMinutes': endMinutes};
  }

  factory AvailableTimeBlock.fromJson(Map<String, dynamic> json) {
    return AvailableTimeBlock(
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
    );
  }
}
