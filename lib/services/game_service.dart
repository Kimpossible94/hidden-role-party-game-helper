import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/voting.dart';

enum JoinGameResult {
  success,
  gameNotFound,
  gameAlreadyStarted,
}

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, Game> _games = {};
  String? _currentGameId;
  String? _currentPlayerId;

  // 실시간 업데이트를 위한 스트림 컨트롤러
  final _gameUpdateController = StreamController<Game?>.broadcast();
  Stream<Game?> get gameUpdateStream => _gameUpdateController.stream;

  // Firestore 리스너 관리
  StreamSubscription? _currentGameListener;

  Game? get currentGame => _currentGameId != null ? _games[_currentGameId] : null;
  String? get currentPlayerId => _currentPlayerId;
  bool get isHost => currentGame?.hostId == _currentPlayerId;

  Future<String> createGame(String hostName, GameSettings settings) async {
    final gameId = _generateGameId();
    final hostId = _generatePlayerId();

    final game = Game(
      id: gameId,
      hostId: hostId,
      hostName: hostName,
      settings: settings,
      players: [], // 진행자는 참가자 목록에 포함하지 않음
    );

    // Firestore에 게임 저장
    await _firestore.collection('games').doc(gameId).set(game.toJson());

    _games[gameId] = game;
    _currentGameId = gameId;
    _currentPlayerId = hostId;

    // 실시간 리스너 설정
    _setupGameListener(gameId);

    return gameId;
  }

  Future<JoinGameResult> joinGame(String gameId, String playerName) async {
    try {
      // Firestore에서 게임 조회
      final doc = await _firestore.collection('games').doc(gameId).get();

      if (!doc.exists) {
        return JoinGameResult.gameNotFound;
      }

      final game = Game.fromJson(doc.data()!);

      if (game.state != GameState.waiting) {
        return JoinGameResult.gameAlreadyStarted;
      }

      final playerId = _generatePlayerId();
      final room1Count = game.getPlayersInRoom(GameRoom.room1).length;
      final room2Count = game.getPlayersInRoom(GameRoom.room2).length;

      final assignedRoom = room1Count <= room2Count ? GameRoom.room1 : GameRoom.room2;

      final player = Player(
        id: playerId,
        name: playerName,
        currentRoom: assignedRoom,
      );

      // 플레이어를 게임에 추가하고 Firestore 업데이트
      game.addPlayer(player);
      await _firestore.collection('games').doc(gameId).update(game.toJson());

      _games[gameId] = game;
      _currentGameId = gameId;
      _currentPlayerId = playerId;

      // 실시간 리스너 설정
      _setupGameListener(gameId);

      return JoinGameResult.success;
    } catch (e) {
      // Join game error: $e
      return JoinGameResult.gameNotFound;
    }
  }

  Future<void> startGame() async {
    if (currentGame == null || !isHost) return;

    _assignTeamsAndRoles();
    currentGame!.state = GameState.starting;

    await _updateGameInFirestore();
  }

  void _assignTeamsAndRoles() {
    final game = currentGame!;
    final players = List<Player>.from(game.players);
    final playerCount = players.length;
    final useExtended = game.settings.useExtendedCharacters;

    if (playerCount < 6 && !useExtended) {
      _assignBasicRoles(players);
    } else {
      _assignExtendedRoles(players);
    }

    game.players = players;
  }

  void _assignBasicRoles(List<Player> players) {
    players.shuffle();

    final isOddPlayerCount = players.length % 2 == 1;
    final redTeamSize = (players.length / 2).floor(); // 홀수일 때 파란팀이 한 명 적음
    final blueTeamSize = players.length - redTeamSize - (isOddPlayerCount ? 1 : 0);

    int playerIndex = 0;

    // 빨간팀 할당
    for (int i = 0; i < redTeamSize; i++) {
      if (i == 0) {
        players[playerIndex] = players[playerIndex].copyWith(team: Team.red, role: Role.bomber);
      } else {
        players[playerIndex] = players[playerIndex].copyWith(team: Team.red, role: Role.redTeamMember);
      }
      playerIndex++;
    }

    // 파란팀 할당
    for (int i = 0; i < blueTeamSize; i++) {
      if (i == 0) {
        players[playerIndex] = players[playerIndex].copyWith(team: Team.blue, role: Role.president);
      } else {
        players[playerIndex] = players[playerIndex].copyWith(team: Team.blue, role: Role.blueTeamMember);
      }
      playerIndex++;
    }

    // 홀수일 때 중립 역할 할당
    if (isOddPlayerCount) {
      final neutralRoles = [Role.gambler, Role.mi6, Role.clone, Role.agoraphobe];
      neutralRoles.shuffle();
      players[playerIndex] = players[playerIndex].copyWith(
        team: Team.neutral,
        role: neutralRoles.first,
      );
    }
  }

  void _assignExtendedRoles(List<Player> players) {
    players.shuffle();

    final playerCount = players.length;
    final isOddPlayerCount = playerCount % 2 == 1;
    final useExtended = currentGame?.settings.useExtendedCharacters ?? false;

    // 중립 역할을 먼저 선택 (홀수일 때)
    Role? neutralRole;
    if (isOddPlayerCount) {
      List<Role> neutralRoles;
      if (useExtended) {
        neutralRoles = [
          Role.gambler,
          Role.mi6,
          Role.clone,
          Role.robot,
          Role.agoraphobe,
          Role.traveler,
          Role.anarchist,
          Role.sniper,
          Role.target,
          Role.privateEye,
          Role.drunk,
          Role.nuclearTyrant,
        ];
      } else {
        neutralRoles = [
          Role.gambler,
          Role.mi6,
          Role.clone,
          Role.agoraphobe,
        ];
      }
      neutralRoles.shuffle();
      neutralRole = neutralRoles.first;
    }

    // 팀별 역할 리스트
    List<Role> redRoles = [Role.bomber]; // 폭탄범은 필수
    List<Role> blueRoles = [Role.president]; // 대통령은 필수

    if (useExtended) {
      // 확장 빨간팀 캐릭터들
      redRoles.addAll([
        Role.martyr,
        Role.tinkerer,
        Role.mastermind,
        Role.drBoom,
        Role.tuesdayKnight,
        Role.doctor, // 확장 모드에서도 doctor 포함
      ]);

      // 확장 파란팀 캐릭터들
      blueRoles.addAll([
        Role.troubleshooter,
        Role.nurse,
        Role.presidentsDaughter,
        Role.bombBot,
        Role.queen,
        Role.engineer, // 확장 모드에서도 engineer 포함
      ]);

      // 특수 양팀 가능 캐릭터들 (랜덤 배정)
      final specialRoles = [
        Role.hotPotato,
        Role.spy,
        Role.zombie,
        Role.psychologist,
        Role.criminal,
        Role.medic,
        Role.mummy,
        Role.agent,
        Role.enforcer,
        Role.usurper,
        Role.shyGuy,
      ];
      specialRoles.shuffle();

      // 특수 역할을 팀에 균등 분배
      for (int i = 0; i < specialRoles.length; i++) {
        if (i % 2 == 0) {
          redRoles.add(specialRoles[i]);
        } else {
          blueRoles.add(specialRoles[i]);
        }
      }
    } else {
      // 기본 캐릭터만 사용
      redRoles.addAll([
        Role.doctor,
        Role.tinkerer,
        Role.mastermind,
        Role.hotPotato,
      ]);

      blueRoles.addAll([
        Role.engineer,
        Role.troubleshooter,
      ]);
    }

    // 폭탄범과 대통령을 제외하고 나머지 역할 섞기
    final redRolesWithoutBomber = redRoles.skip(1).toList()..shuffle();
    final blueRolesWithoutPresident = blueRoles.skip(1).toList()..shuffle();

    // 다시 합치기 (폭탄범과 대통령을 맨 앞에)
    redRoles = [Role.bomber, ...redRolesWithoutBomber];
    blueRoles = [Role.president, ...blueRolesWithoutPresident];

    // 팀 인원 계산 (홀수면 중립 1명 빼기)
    final teamPlayerCount = isOddPlayerCount ? playerCount - 1 : playerCount;
    final redTeamSize = teamPlayerCount ~/ 2;
    final blueTeamSize = teamPlayerCount - redTeamSize;

    int playerIndex = 0;

    // 빨간팀 할당 (폭탄범 필수)
    for (int i = 0; i < redTeamSize; i++) {
      final role = i < redRoles.length ? redRoles[i] : Role.redTeamMember;
      players[playerIndex] = players[playerIndex].copyWith(
        team: Team.red,
        role: role,
      );
      playerIndex++;
    }

    // 파란팀 할당 (대통령 필수)
    for (int i = 0; i < blueTeamSize; i++) {
      final role = i < blueRoles.length ? blueRoles[i] : Role.blueTeamMember;
      players[playerIndex] = players[playerIndex].copyWith(
        team: Team.blue,
        role: role,
      );
      playerIndex++;
    }

    // 홀수일 때 중립 역할 할당
    if (isOddPlayerCount && neutralRole != null) {
      players[playerIndex] = players[playerIndex].copyWith(
        team: Team.neutral,
        role: neutralRole,
      );
    }
  }

  Future<void> startRound() async {
    if (currentGame == null || !isHost) return;
    currentGame!.startRound();
    await _updateGameInFirestore();
  }

  Future<void> castVote(String votingSessionId, String vote) async {
    if (currentGame == null || _currentPlayerId == null) return;
    currentGame!.castVote(_currentPlayerId!, votingSessionId, vote);
    await _updateGameInFirestore();
  }

  Future<void> endRound() async {
    if (currentGame == null || !isHost) return;
    currentGame!.endRound();
    await _updateGameInFirestore();
  }

  Future<void> movePlayer(String playerId, GameRoom newRoom) async {
    if (currentGame == null || !isHost) return;
    currentGame!.movePlayer(playerId, newRoom);
    await _updateGameInFirestore();
  }

  Future<void> setLeader(String playerId, GameRoom room) async {
    if (currentGame == null || !isHost) return;
    currentGame!.setLeader(playerId, room);
    await _updateGameInFirestore();
  }

  Future<void> setGamblerPrediction(Team prediction) async {
    if (currentGame == null || _currentPlayerId == null) return;

    final playerIndex = currentGame!.players.indexWhere((p) => p.id == _currentPlayerId);
    if (playerIndex != -1 && currentGame!.players[playerIndex].role == Role.gambler) {
      currentGame!.players[playerIndex] = currentGame!.players[playerIndex].copyWith(
        gamblerPrediction: prediction,
      );
      await _updateGameInFirestore();
    }
  }

  // 좀비 감염 실행 (좀비가 확인 후 바로 감염)
  Future<void> infectPlayer(String targetPlayerId, String zombieName) async {
    if (currentGame == null || _currentPlayerId == null) return;

    final zombieIndex = currentGame!.players.indexWhere((p) => p.id == _currentPlayerId);
    if (zombieIndex == -1) return;

    final zombie = currentGame!.players[zombieIndex];
    // 좀비 역할이거나 이미 감염된 사람만 감염 가능
    if (zombie.role != Role.zombie && !zombie.isZombie) return;

    final targetIndex = currentGame!.players.indexWhere((p) => p.id == targetPlayerId);
    if (targetIndex == -1) return;

    final target = currentGame!.players[targetIndex];
    // 이미 좀비인 사람은 감염할 수 없음
    if (target.isZombie || target.role == Role.zombie) return;

    // 원래 팀 저장 후 좀비로 전환
    currentGame!.players[targetIndex] = target.copyWith(
      isZombie: true,
      originalTeam: target.team, // 원래 팀 저장
      team: Team.neutral, // 중립 팀으로 변경
      role: Role.zombie, // 역할도 좀비로 변경
    );

    await _updateGameInFirestore();

    // 타겟 플레이어에게 알림 전송 (Firestore에 임시 저장)
    await _firestore.collection('games').doc(_currentGameId).collection('infectionNotifications').add({
      'zombieName': zombieName,
      'targetId': targetPlayerId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 감염 알림 스트림 (특정 플레이어에 대한)
  Stream<QuerySnapshot> getInfectionNotificationsStream(String playerId) {
    if (_currentGameId == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('games')
        .doc(_currentGameId)
        .collection('infectionNotifications')
        .where('targetId', isEqualTo: playerId)
        .snapshots();
  }

  // 감염 알림 삭제
  Future<void> dismissInfectionNotification(String notificationId) async {
    if (_currentGameId == null) return;

    await _firestore
        .collection('games')
        .doc(_currentGameId)
        .collection('infectionNotifications')
        .doc(notificationId)
        .delete();
  }

  Future<void> requestAbdication(String fromPlayerId, String toPlayerId) async {
    if (currentGame == null || _currentPlayerId != fromPlayerId) return;

    final currentPlayer = currentGame!.getPlayerById(fromPlayerId);
    if (currentPlayer == null || !currentPlayer.isLeader) return;

    final targetPlayer = currentGame!.getPlayerById(toPlayerId);
    if (targetPlayer == null || targetPlayer.currentRoom != currentPlayer.currentRoom) return;

    // 하야 요청 투표 세션 생성
    final votingSession = VotingSession(
      id: '${currentGame!.id}_abdication_${fromPlayerId}_${DateTime.now().millisecondsSinceEpoch}',
      type: VotingType.abdicationRequest,
      room: currentPlayer.currentRoom,
      initiatorId: fromPlayerId,
      targetPlayerId: toPlayerId,
      startTime: DateTime.now(),
      durationSeconds: 20,
      eligibleVoterIds: [toPlayerId], // 대상자만 투표 가능
    );

    currentGame!.activeVotingSessions = [...currentGame!.activeVotingSessions, votingSession];
    await _updateGameInFirestore();
  }

  Future<void> initiateImpeachment(String initiatorId, GameRoom room) async {
    if (currentGame == null || _currentPlayerId != initiatorId) return;

    final initiator = currentGame!.getPlayerById(initiatorId);
    if (initiator == null || initiator.currentRoom != room || !initiator.canInitiateImpeachment) return;

    final currentLeader = currentGame!.getLeaderInRoom(room);
    if (currentLeader == null || currentLeader.id == initiatorId) return;

    // 탄핵 발의자의 권한 제거
    final initiatorIndex = currentGame!.players.indexWhere((p) => p.id == initiatorId);
    if (initiatorIndex != -1) {
      currentGame!.players[initiatorIndex] = currentGame!.players[initiatorIndex]
          .copyWith(canInitiateImpeachment: false);
    }

    // 탄핵 찬반 투표 세션 생성
    final playersInRoom = currentGame!.getPlayersInRoom(room);
    final eligibleVoters = playersInRoom.where((p) => p.id != currentLeader.id).map((p) => p.id).toList();

    final votingSession = VotingSession(
      id: '${currentGame!.id}_impeachment_${room.name}_${DateTime.now().millisecondsSinceEpoch}',
      type: VotingType.impeachmentDecision,
      room: room,
      initiatorId: initiatorId,
      startTime: DateTime.now(),
      durationSeconds: 20,
      eligibleVoterIds: eligibleVoters,
    );

    currentGame!.activeVotingSessions = [...currentGame!.activeVotingSessions, votingSession];
    await _updateGameInFirestore();
  }

  Future<void> leaveGame() async {
    if (currentGame != null && _currentPlayerId != null) {
      if (isHost) {
        // 호스트가 떠나면 게임 삭제
        await _firestore.collection('games').doc(_currentGameId!).delete();
        _games.remove(_currentGameId);
      } else {
        // 일반 플레이어가 떠나면 플레이어만 제거
        currentGame!.removePlayer(_currentPlayerId!);
        await _updateGameInFirestore();
      }
    }

    _currentGameListener?.cancel();
    _currentGameId = null;
    _currentPlayerId = null;
  }

  String _generateGameId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  String _generatePlayerId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
           Random().nextInt(1000).toString();
  }


  List<Game> getAllGames() {
    return _games.values.toList();
  }

  // 디버그용 메서드들
  List<String> getAllGameIds() {
    return _games.keys.toList();
  }

  String getDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln('=== 게임 서비스 디버그 정보 ===');
    buffer.writeln('활성 게임 수: ${_games.length}');
    buffer.writeln('현재 게임 ID: $_currentGameId');
    buffer.writeln('현재 플레이어 ID: $_currentPlayerId');
    buffer.writeln('호스트 여부: $isHost');
    buffer.writeln('');
    buffer.writeln('모든 게임 ID:');
    for (final gameId in _games.keys) {
      final game = _games[gameId]!;
      buffer.writeln('- $gameId (호스트: ${game.hostName}, 플레이어: ${game.players.length}명, 상태: ${game.state})');
    }
    return buffer.toString();
  }

  // Firebase 관련 메소드들
  Future<void> _updateGameInFirestore() async {
    if (_currentGameId == null || currentGame == null) return;

    try {
      await _firestore.collection('games').doc(_currentGameId!).update(currentGame!.toJson());
    } catch (e) {
      // Failed to update game in Firestore: $e
    }
  }

  void _setupGameListener(String gameId) {
    _currentGameListener?.cancel();

    _currentGameListener = _firestore
        .collection('games')
        .doc(gameId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final updatedGame = Game.fromJson(snapshot.data()!);
        final previousGame = _games[gameId];

        _games[gameId] = updatedGame;

        // 만료된 투표 세션 처리
        _processExpiredVotingSessions(updatedGame);

        // 변경사항이 있으면 스트림에 알림
        if (previousGame == null ||
            previousGame.players.length != updatedGame.players.length ||
            previousGame.state != updatedGame.state ||
            previousGame.currentRound != updatedGame.currentRound ||
            previousGame.activeVotingSessions.length != updatedGame.activeVotingSessions.length) {
          _gameUpdateController.add(updatedGame);
        }
      } else {
        // 게임이 삭제됨 (호스트가 나감) - 참가자들을 자동으로 내보냄
        _games.remove(gameId);
        _currentGameListener?.cancel();
        _currentGameId = null;
        _currentPlayerId = null;

        // null을 전송하여 UI에 게임 종료를 알림
        _gameUpdateController.add(null);
      }
    });
  }

  Future<void> _processExpiredVotingSessions(Game game) async {
    bool hasExpiredSessions = false;

    for (final session in game.activeVotingSessions) {
      if (session.status == VotingStatus.active && session.isExpired) {
        hasExpiredSessions = true;
        break;
      }
    }

    if (hasExpiredSessions) {
      game.processExpiredVotingSessions();
      _games[game.id] = game;

      // 호스트인 경우에만 Firebase에 업데이트
      if (isHost) {
        await _updateGameInFirestore();
      }
    }
  }

  Future<Game?> getGame(String gameId) async {
    // 로컬 캐시 확인
    if (_games.containsKey(gameId)) {
      return _games[gameId];
    }

    // Firestore에서 조회
    try {
      final doc = await _firestore.collection('games').doc(gameId).get();
      if (doc.exists) {
        final game = Game.fromJson(doc.data()!);
        _games[gameId] = game;
        return game;
      }
    } catch (e) {
      // Failed to get game from Firestore: $e
    }

    return null;
  }

  void dispose() {
    _currentGameListener?.cancel();
    _gameUpdateController.close();
  }
}