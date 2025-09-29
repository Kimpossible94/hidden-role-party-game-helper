import 'player.dart';

enum VotingType {
  leaderElection, // 리더 선출 투표
  impeachmentDecision, // 탄핵 찬성/반대 투표
  newLeaderElection, // 탄핵 후 새 리더 선출 투표
  abdicationRequest, // 하야 요청 수락/거절
}

enum VotingStatus {
  active, // 투표 진행 중
  completed, // 투표 완료
  expired, // 투표 시간 만료
}

class VotingSession {
  final String id;
  final VotingType type;
  final GameRoom room;
  final String? initiatorId; // 투표를 시작한 사람 (탄핵 발의자 등)
  final String? targetPlayerId; // 대상 플레이어 (하야 요청 대상 등)
  final DateTime startTime;
  final int durationSeconds;
  final List<String> eligibleVoterIds; // 투표 가능한 플레이어 ID들
  final Map<String, String> votes; // playerId -> candidateId or "yes"/"no"
  VotingStatus status;
  String? result; // 투표 결과

  VotingSession({
    required this.id,
    required this.type,
    required this.room,
    this.initiatorId,
    this.targetPlayerId,
    required this.startTime,
    this.durationSeconds = 20,
    required this.eligibleVoterIds,
    this.votes = const {},
    this.status = VotingStatus.active,
    this.result,
  });

  bool get isExpired => DateTime.now().difference(startTime).inSeconds >= durationSeconds;

  Duration get remainingTime {
    final elapsed = DateTime.now().difference(startTime);
    final remaining = Duration(seconds: durationSeconds) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool hasVoted(String playerId) => votes.containsKey(playerId);

  int get totalVotes => votes.length;
  int get totalEligibleVoters => eligibleVoterIds.length;

  bool get isAllVotesCompleted => votes.length >= eligibleVoterIds.length;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'room': room.index,
      'initiatorId': initiatorId,
      'targetPlayerId': targetPlayerId,
      'startTime': startTime.millisecondsSinceEpoch,
      'durationSeconds': durationSeconds,
      'eligibleVoterIds': eligibleVoterIds,
      'votes': votes,
      'status': status.index,
      'result': result,
    };
  }

  factory VotingSession.fromJson(Map<String, dynamic> json) {
    return VotingSession(
      id: json['id'],
      type: VotingType.values[json['type']],
      room: GameRoom.values[json['room']],
      initiatorId: json['initiatorId'],
      targetPlayerId: json['targetPlayerId'],
      startTime: DateTime.fromMillisecondsSinceEpoch(json['startTime']),
      durationSeconds: json['durationSeconds'] ?? 20,
      eligibleVoterIds: List<String>.from(json['eligibleVoterIds']),
      votes: Map<String, String>.from(json['votes'] ?? {}),
      status: VotingStatus.values[json['status']],
      result: json['result'],
    );
  }

  VotingSession copyWith({
    String? id,
    VotingType? type,
    GameRoom? room,
    String? initiatorId,
    String? targetPlayerId,
    DateTime? startTime,
    int? durationSeconds,
    List<String>? eligibleVoterIds,
    Map<String, String>? votes,
    VotingStatus? status,
    String? result,
  }) {
    return VotingSession(
      id: id ?? this.id,
      type: type ?? this.type,
      room: room ?? this.room,
      initiatorId: initiatorId ?? this.initiatorId,
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
      startTime: startTime ?? this.startTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      eligibleVoterIds: eligibleVoterIds ?? this.eligibleVoterIds,
      votes: votes ?? this.votes,
      status: status ?? this.status,
      result: result ?? this.result,
    );
  }
}