enum TradeStatus {
  listed,
  pending,
  cancelled,
  completed,
}

class Trade {
  final String id;
  final String offeredCaptureId;
  final String offeredByUserId;
  final String? requestedCaptureId; // null for coin-only offers
  final int coinsOffered;
  final int coinsRequested;
  final TradeStatus status;
  final DateTime createdAt;
  final String? acceptedByUserId;
  final DateTime? acceptedAt;

  Trade({
    required this.id,
    required this.offeredCaptureId,
    required this.offeredByUserId,
    this.requestedCaptureId,
    required this.coinsOffered,
    required this.coinsRequested,
    required this.status,
    required this.createdAt,
    this.acceptedByUserId,
    this.acceptedAt,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "offeredCaptureId": offeredCaptureId,
        "offeredByUserId": offeredByUserId,
        "requestedCaptureId": requestedCaptureId,
        "coinsOffered": coinsOffered,
        "coinsRequested": coinsRequested,
        "status": status.name,
        "createdAt": createdAt.toIso8601String(),
        "acceptedByUserId": acceptedByUserId,
        "acceptedAt": acceptedAt?.toIso8601String(),
      };

  static Trade fromJson(Map<String, dynamic> m) => Trade(
        id: m["id"],
        offeredCaptureId: m["offeredCaptureId"],
        offeredByUserId: m["offeredByUserId"],
        requestedCaptureId: m["requestedCaptureId"],
        coinsOffered: m["coinsOffered"],
        coinsRequested: m["coinsRequested"],
        status: TradeStatus.values.firstWhere((e) => e.name == m["status"]),
        createdAt: DateTime.parse(m["createdAt"]),
        acceptedByUserId: m["acceptedByUserId"],
        acceptedAt: m["acceptedAt"] != null ? DateTime.parse(m["acceptedAt"]) : null,
      );

  Trade copyWith({
    String? id,
    String? offeredCaptureId,
    String? offeredByUserId,
    String? requestedCaptureId,
    int? coinsOffered,
    int? coinsRequested,
    TradeStatus? status,
    DateTime? createdAt,
    String? acceptedByUserId,
    DateTime? acceptedAt,
  }) {
    return Trade(
      id: id ?? this.id,
      offeredCaptureId: offeredCaptureId ?? this.offeredCaptureId,
      offeredByUserId: offeredByUserId ?? this.offeredByUserId,
      requestedCaptureId: requestedCaptureId ?? this.requestedCaptureId,
      coinsOffered: coinsOffered ?? this.coinsOffered,
      coinsRequested: coinsRequested ?? this.coinsRequested,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedByUserId: acceptedByUserId ?? this.acceptedByUserId,
      acceptedAt: acceptedAt ?? this.acceptedAt,
    );
  }
}
