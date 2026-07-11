class Countdown {
  final String id;
  final String ownerId;
  final String title;
  final DateTime targetDate;
  final DateTime createdAt;

  const Countdown({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.targetDate,
    required this.createdAt,
  });

  bool get isPast => targetDate.isBefore(DateTime.now());

  factory Countdown.fromJson(Map<String, dynamic> json) => Countdown(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        title: json['title'] as String,
        targetDate: DateTime.parse(json['target_date'] as String).toLocal(),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

class CountdownFollow {
  final String id;
  final String userId;
  final String countdownId;
  final bool notify;

  const CountdownFollow({
    required this.id,
    required this.userId,
    required this.countdownId,
    required this.notify,
  });

  factory CountdownFollow.fromJson(Map<String, dynamic> json) =>
      CountdownFollow(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        countdownId: json['countdown_id'] as String,
        notify: json['notify'] as bool? ?? false,
      );
}

class FollowedCountdown {
  final Countdown countdown;
  final CountdownFollow follow;

  const FollowedCountdown({required this.countdown, required this.follow});
}
