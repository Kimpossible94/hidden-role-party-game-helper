import 'player.dart';
import 'voting.dart';

enum GameState {
  waiting,
  starting,
  inProgress,
  break_,
  finished,
}

class GameSettings {
  final int totalRounds;
  final List<int> roundDurationsMinutes; // 각 라운드별 시간 (분)
  final int breakDurationMinutes;

  GameSettings({
    required this.totalRounds,
    required this.roundDurationsMinutes,
    this.breakDurationMinutes = 2,
  }) : assert(roundDurationsMinutes.length == totalRounds);

  // 특정 라운드의 시간을 가져오기 (1-based index)
  int getDurationForRound(int roundNumber) {
    if (roundNumber < 1 || roundNumber > totalRounds) {
      return roundDurationsMinutes.first;
    }
    return roundDurationsMinutes[roundNumber - 1];
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRounds': totalRounds,
      'roundDurationsMinutes': roundDurationsMinutes,
      'breakDurationMinutes': breakDurationMinutes,
    };
  }

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      totalRounds: json['totalRounds'],
      roundDurationsMinutes: List<int>.from(json['roundDurationsMinutes']),
      breakDurationMinutes: json['breakDurationMinutes'] ?? 2,
    );
  }

  // 기존 호환성을 위한 생성자
  factory GameSettings.uniform({
    required int totalRounds,
    required int roundDurationMinutes,
    int breakDurationMinutes = 2,
  }) {
    return GameSettings(
      totalRounds: totalRounds,
      roundDurationsMinutes: List.filled(totalRounds, roundDurationMinutes),
      breakDurationMinutes: breakDurationMinutes,
    );
  }
}

class Game {
  final String id;
  final String hostId;
  final String hostName;
  final GameSettings settings;
  GameState state;
  int currentRound;
  DateTime? roundStartTime;
  Duration? currentRoundDuration;
  List<Player> players;
  String? winnerId;
  List<VotingSession> activeVotingSessions;

  Game({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.settings,
    this.state = GameState.waiting,
    this.currentRound = 0,
    this.roundStartTime,
    this.currentRoundDuration,
    this.players = const [],
    this.winnerId,
    this.activeVotingSessions = const [],
  });

  bool isHost(String playerId) => hostId == playerId;

  Player? getPlayerById(String playerId) {
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      return null;
    }
  }

  List<Player> getPlayersInRoom(GameRoom room) {
    return players.where((p) => p.currentRoom == room).toList();
  }

  Player? getLeaderInRoom(GameRoom room) {
    return getPlayersInRoom(room).where((p) => p.isLeader).firstOrNull;
  }

  List<Player> getNonLeaderPlayersInRoom(GameRoom room) {
    return getPlayersInRoom(room).where((p) => !p.isLeader).toList();
  }

  void setLeader(String playerId, GameRoom room) {
    // 해당 방의 기존 리더 제거
    final currentLeader = getLeaderInRoom(room);
    if (currentLeader != null) {
      final currentLeaderIndex = players.indexWhere((p) => p.id == currentLeader.id);
      if (currentLeaderIndex != -1) {
        players[currentLeaderIndex] = players[currentLeaderIndex].copyWith(isLeader: false);
      }
    }

    // 새로운 리더 설정
    final playerIndex = players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1 && players[playerIndex].currentRoom == room) {
      players[playerIndex] = players[playerIndex].copyWith(isLeader: true);
    }
  }

  void removeLeader(GameRoom room) {
    final leader = getLeaderInRoom(room);
    if (leader != null) {
      final leaderIndex = players.indexWhere((p) => p.id == leader.id);
      if (leaderIndex != -1) {
        players[leaderIndex] = players[leaderIndex].copyWith(isLeader: false);
      }
    }
  }


  // 투표 관련 메서드들
  VotingSession? getActiveVotingForPlayer(String playerId) {
    final player = getPlayerById(playerId);
    if (player == null) return null;

    return activeVotingSessions
        .where((session) => session.status == VotingStatus.active)
        .where((session) => session.eligibleVoterIds.contains(playerId))
        .firstOrNull;
  }

  void castVote(String playerId, String votingSessionId, String vote) {
    final sessionIndex = activeVotingSessions.indexWhere((s) => s.id == votingSessionId);
    if (sessionIndex == -1) return;

    final session = activeVotingSessions[sessionIndex];
    if (session.status != VotingStatus.active || session.hasVoted(playerId)) return;

    final newVotes = Map<String, String>.from(session.votes);
    newVotes[playerId] = vote;

    final updatedSession = session.copyWith(votes: newVotes);
    activeVotingSessions[sessionIndex] = updatedSession;

    // 모든 사람이 투표했으면 즉시 완료 처리
    if (updatedSession.isAllVotesCompleted) {
      final result = _calculateVotingResult(updatedSession);
      final completedSession = updatedSession.copyWith(
        status: VotingStatus.completed,
        result: result,
      );
      activeVotingSessions[sessionIndex] = completedSession;
      _applyVotingResult(completedSession);
    }
  }

  void processExpiredVotingSessions() {
    final updatedSessions = <VotingSession>[];

    for (final session in activeVotingSessions) {
      if (session.status == VotingStatus.active && session.isExpired) {
        // 투표 시간 만료 - 결과 계산
        final result = _calculateVotingResult(session);
        final completedSession = session.copyWith(
          status: VotingStatus.completed,
          result: result,
        );
        updatedSessions.add(completedSession);

        // 결과 적용
        _applyVotingResult(completedSession);
      } else {
        updatedSessions.add(session);
      }
    }

    activeVotingSessions = updatedSessions;
  }

  String _calculateVotingResult(VotingSession session) {
    switch (session.type) {
      case VotingType.leaderElection:
        return _calculateLeaderElectionResult(session);
      case VotingType.impeachmentDecision:
        return _calculateImpeachmentDecisionResult(session);
      case VotingType.newLeaderElection:
        return _calculateLeaderElectionResult(session);
      case VotingType.abdicationRequest:
        return _calculateAbdicationRequestResult(session);
    }
  }

  String _calculateLeaderElectionResult(VotingSession session) {
    if (session.votes.isEmpty) return 'no_votes';

    // 득표수 계산
    final voteCounts = <String, int>{};
    for (final candidateId in session.votes.values) {
      voteCounts[candidateId] = (voteCounts[candidateId] ?? 0) + 1;
    }

    // 최다 득표자들 찾기
    final maxVotes = voteCounts.values.reduce((a, b) => a > b ? a : b);
    final winners = voteCounts.entries
        .where((entry) => entry.value == maxVotes)
        .map((entry) => entry.key)
        .toList();

    if (winners.length == 1) {
      return winners.first;
    } else {
      // 동점자 중 랜덤 선택
      winners.shuffle();
      return winners.first;
    }
  }

  String _calculateImpeachmentDecisionResult(VotingSession session) {
    final yesVotes = session.votes.values.where((vote) => vote == 'yes').length;
    final threshold = (session.totalEligibleVoters / 2).ceil();

    return yesVotes >= threshold ? 'approved' : 'rejected';
  }

  String _calculateAbdicationRequestResult(VotingSession session) {
    return session.votes.values.first == 'accept' ? 'accepted' : 'rejected';
  }

  void _applyVotingResult(VotingSession session) {
    switch (session.type) {
      case VotingType.leaderElection:
        if (session.result != null && session.result != 'no_votes') {
          setLeader(session.result!, session.room);
        }
        break;
      case VotingType.impeachmentDecision:
        if (session.result == 'approved') {
          // 탄핵 성공 - 새 리더 선출 투표 시작
          _startNewLeaderElectionAfterImpeachment(session);
        }
        break;
      case VotingType.newLeaderElection:
        if (session.result != null && session.result != 'no_votes') {
          setLeader(session.result!, session.room);
        }
        break;
      case VotingType.abdicationRequest:
        if (session.result == 'accepted' && session.initiatorId != null && session.targetPlayerId != null) {
          // 하야 수락 - 리더십 이전
          removeLeader(session.room);
          setLeader(session.targetPlayerId!, session.room);

          // 기존 리더를 하야 처리
          final initiatorIndex = players.indexWhere((p) => p.id == session.initiatorId);
          if (initiatorIndex != -1) {
            players[initiatorIndex] = players[initiatorIndex].copyWith(hasAbdicatedThisRound: true);
          }
        }
        break;
    }
  }

  void _startNewLeaderElectionAfterImpeachment(VotingSession impeachmentSession) {
    final playersInRoom = getPlayersInRoom(impeachmentSession.room);
    if (playersInRoom.isEmpty) return;

    // 현재 리더 제거
    removeLeader(impeachmentSession.room);

    final votingSession = VotingSession(
      id: '${id}_new_leader_${impeachmentSession.room.name}_${DateTime.now().millisecondsSinceEpoch}',
      type: VotingType.newLeaderElection,
      room: impeachmentSession.room,
      startTime: DateTime.now(),
      durationSeconds: 20,
      eligibleVoterIds: playersInRoom.map((p) => p.id).toList(),
    );

    activeVotingSessions = [...activeVotingSessions, votingSession];
  }

  Duration? get remainingTime {
    if (roundStartTime == null || currentRoundDuration == null) return null;

    final elapsed = DateTime.now().difference(roundStartTime!);
    final remaining = currentRoundDuration! - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isRoundActive {
    return state == GameState.inProgress && remainingTime != null && remainingTime! > Duration.zero;
  }

  bool get canStartNextRound {
    return state == GameState.break_ ||
           state == GameState.starting ||
           (state == GameState.waiting && currentRound == 0);
  }

  void startRound() {
    if (canStartNextRound) {
      currentRound++;
      state = GameState.inProgress;
      roundStartTime = DateTime.now();
      currentRoundDuration = Duration(minutes: settings.getDurationForRound(currentRound));

      // 새 라운드 시작 시 모든 플레이어의 라운드별 제한 초기화
      _resetRoundSpecificLimitations();

      // 첫 라운드이고 리더가 없으면 리더 선출 투표 시작
      if (currentRound == 1) {
        _startLeaderElectionForFirstRound();
      }
    }
  }

  void _resetRoundSpecificLimitations() {
    for (int i = 0; i < players.length; i++) {
      players[i] = players[i].copyWith(
        canInitiateImpeachment: true,
        hasAbdicatedThisRound: false,
      );
    }
  }

  void _startLeaderElectionForFirstRound() {
    // 방 1 리더 선출 투표
    final room1Players = getPlayersInRoom(GameRoom.room1);
    if (room1Players.length >= 2) {
      _startLeaderElection(GameRoom.room1);
    }

    // 방 2 리더 선출 투표
    final room2Players = getPlayersInRoom(GameRoom.room2);
    if (room2Players.length >= 2) {
      _startLeaderElection(GameRoom.room2);
    }
  }

  void _startLeaderElection(GameRoom room) {
    final playersInRoom = getPlayersInRoom(room);
    if (playersInRoom.isEmpty) return;

    final votingSession = VotingSession(
      id: '${id}_leader_election_${room.name}_${DateTime.now().millisecondsSinceEpoch}',
      type: VotingType.leaderElection,
      room: room,
      startTime: DateTime.now(),
      durationSeconds: 20,
      eligibleVoterIds: playersInRoom.map((p) => p.id).toList(),
    );

    activeVotingSessions = [...activeVotingSessions, votingSession];
  }

  void endRound() {
    if (currentRound >= settings.totalRounds) {
      state = GameState.finished;
      _determineWinner();
    } else {
      state = GameState.break_;
      roundStartTime = null;
      currentRoundDuration = null;
    }
  }

  void _determineWinner() {
    final bomber = players.where((p) => p.role == Role.bomber).firstOrNull;
    final president = players.where((p) => p.role == Role.president).firstOrNull;

    if (bomber == null || president == null) return;

    if (bomber.currentRoom == president.currentRoom) {
      winnerId = 'red';
    } else {
      winnerId = 'blue';
    }
  }

  void movePlayer(String playerId, GameRoom newRoom) {
    final playerIndex = players.indexWhere((p) => p.id == playerId);
    if (playerIndex != -1) {
      players[playerIndex] = players[playerIndex].copyWith(currentRoom: newRoom);
    }
  }

  void addPlayer(Player player) {
    if (!players.any((p) => p.id == player.id)) {
      players = [...players, player];
    }
  }

  void removePlayer(String playerId) {
    players = players.where((p) => p.id != playerId).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'settings': settings.toJson(),
      'state': state.index,
      'currentRound': currentRound,
      'roundStartTime': roundStartTime?.millisecondsSinceEpoch,
      'currentRoundDuration': currentRoundDuration?.inMilliseconds,
      'players': players.map((p) => p.toJson()).toList(),
      'winnerId': winnerId,
      'activeVotingSessions': activeVotingSessions.map((v) => v.toJson()).toList(),
    };
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      hostId: json['hostId'],
      hostName: json['hostName'],
      settings: GameSettings.fromJson(json['settings']),
      state: GameState.values[json['state']],
      currentRound: json['currentRound'],
      roundStartTime: json['roundStartTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['roundStartTime'])
          : null,
      currentRoundDuration: json['currentRoundDuration'] != null
          ? Duration(milliseconds: json['currentRoundDuration'])
          : null,
      players: (json['players'] as List).map((p) => Player.fromJson(p)).toList(),
      winnerId: json['winnerId'],
      activeVotingSessions: (json['activeVotingSessions'] as List? ?? [])
          .map((v) => VotingSession.fromJson(v))
          .toList(),
    );
  }

  Game copyWith({
    String? id,
    String? hostId,
    String? hostName,
    GameSettings? settings,
    GameState? state,
    int? currentRound,
    DateTime? roundStartTime,
    Duration? currentRoundDuration,
    List<Player>? players,
    String? winnerId,
    List<VotingSession>? activeVotingSessions,
  }) {
    return Game(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      settings: settings ?? this.settings,
      state: state ?? this.state,
      currentRound: currentRound ?? this.currentRound,
      roundStartTime: roundStartTime ?? this.roundStartTime,
      currentRoundDuration: currentRoundDuration ?? this.currentRoundDuration,
      players: players ?? this.players,
      winnerId: winnerId ?? this.winnerId,
      activeVotingSessions: activeVotingSessions ?? this.activeVotingSessions,
    );
  }
}