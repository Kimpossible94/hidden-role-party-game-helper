import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../models/voting.dart';
import '../services/game_service.dart';
import '../screens/game_rules_screen.dart';
import 'home_screen.dart';

class ParticipantScreen extends StatefulWidget {
  final String gameId;

  const ParticipantScreen({super.key, required this.gameId});

  @override
  State<ParticipantScreen> createState() => _ParticipantScreenState();
}

class _ParticipantScreenState extends State<ParticipantScreen> {
  final _gameService = GameService();
  Timer? _timer;
  StreamSubscription? _gameUpdateSubscription;
  StreamSubscription? _infectionNotificationSubscription;
  Game? _game;
  Player? _currentPlayer;
  VotingSession? _currentVotingSession;
  bool _isVotingDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _loadGame();
    _startTimer();
    _setupGameUpdateStream();
    _setupInfectionNotificationListener();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameUpdateSubscription?.cancel();
    _infectionNotificationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadGame() async {
    final game = await _gameService.getGame(widget.gameId);
    if (mounted) {
      final previousVotingSession = _currentVotingSession;
      final previousGame = _game;
      setState(() {
        _game = game;
        _currentPlayer = _game?.getPlayerById(_gameService.currentPlayerId ?? '');
        _currentVotingSession = _currentPlayer != null ? _game?.getActiveVotingForPlayer(_currentPlayer!.id) : null;
      });

      // Gambler가 게임 시작 후 첫 라운드에 팀 선택해야 함
      if (_currentPlayer?.role == Role.gambler &&
          _currentPlayer?.gamblerPrediction == null &&
          _game?.state == GameState.inProgress &&
          _game?.currentRound == 1 &&
          previousGame?.state != GameState.inProgress) {
        _showGamblerPredictionDialog();
      }

      // 새로운 투표 세션이 시작되면 다이얼로그 표시
      if (_currentVotingSession != null &&
          _currentVotingSession!.status == VotingStatus.active &&
          previousVotingSession?.id != _currentVotingSession!.id &&
          !_isVotingDialogShowing) {
        _showVotingDialog();
      }

      // 투표가 완료되거나 만료되면 다이얼로그 닫기
      if (previousVotingSession != null &&
          _currentVotingSession?.status != VotingStatus.active &&
          _isVotingDialogShowing) {
        Navigator.of(context).pop();
        _isVotingDialogShowing = false;
      }
    }
  }

  void _setupGameUpdateStream() {
    _gameUpdateSubscription = _gameService.gameUpdateStream.listen((updatedGame) {
      // 게임이 삭제됨 (호스트가 나감)
      if (updatedGame == null) {
        if (mounted) {
          // 알림 표시
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('방장이 방을 나가서 게임이 종료되었습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
          // 홈 화면으로 이동
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
        return;
      }

      // 현재 게임 ID와 일치하는 업데이트만 처리
      if (updatedGame.id == widget.gameId) {
        setState(() {
          _game = updatedGame;
          _currentPlayer = _game?.getPlayerById(_gameService.currentPlayerId ?? '');
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadGame();
    });
  }

  Future<void> _leaveGame() async {
    await _gameService.leaveGame();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _abdicateLeadership() async {
    final playersInRoom = _game!.getPlayersInRoom(_currentPlayer!.currentRoom)
        .where((p) => p.id != _currentPlayer!.id) // 자신 제외
        .toList();

    if (playersInRoom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리더십을 넘길 다른 플레이어가 없습니다.')),
      );
      return;
    }

    String? selectedPlayerId = await showDialog<String>(
      context: context,
      builder: (context) => _AbdicationDialog(
        players: playersInRoom,
        currentRoom: _currentPlayer!.currentRoom,
      ),
    );

    if (selectedPlayerId != null) {
      await _gameService.requestAbdication(_currentPlayer!.id, selectedPlayerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('하야 요청을 보냈습니다.')),
        );
      }
    }
  }

  Future<void> _initiateImpeachment() async {
    final currentLeader = _game!.getLeaderInRoom(_currentPlayer!.currentRoom);
    if (currentLeader == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('현재 방에 리더가 없습니다.')),
      );
      return;
    }

    if (currentLeader.id == _currentPlayer!.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('자신을 탄핵할 수 없습니다.')),
      );
      return;
    }

    if (!_currentPlayer!.canInitiateImpeachment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 라운드에서는 더 이상 탄핵을 발의할 수 없습니다.')),
      );
      return;
    }

    final playersInRoom = _game!.getPlayersInRoom(_currentPlayer!.currentRoom);
    if (playersInRoom.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('탄핵 투표를 위해서는 최소 3명이 필요합니다.')),
      );
      return;
    }

    // 탄핵 발의 확인
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('탄핵 발의'),
        content: Text('${currentLeader.name} 리더에 대한 탄핵을 발의하시겠습니까?\n\n방 안의 모든 플레이어가 찬성/반대 투표를 하게 됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('발의'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _gameService.initiateImpeachment(_currentPlayer!.id, _currentPlayer!.currentRoom);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('탄핵 투표를 시작했습니다.')),
        );
      }
    }
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getGameStateText() {
    if (_game == null) return '';

    switch (_game!.state) {
      case GameState.waiting:
        return '게임 시작 대기 중...';
      case GameState.starting:
        return '게임 시작!';
      case GameState.inProgress:
        return '라운드 진행 중';
      case GameState.break_:
        return '휴식 시간';
      case GameState.finished:
        return '게임 종료';
    }
  }

  void _showTeam() {
    if (_currentPlayer?.team == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 팀이 배정되지 않았습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _currentPlayer!.team == Team.red
            ? Colors.red[700]
            : _currentPlayer!.team == Team.blue
                ? Colors.blue[700]
                : Colors.green[700],
        title: Text(
          '당신의 팀',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _currentPlayer!.team == Team.red
                  ? Icons.local_fire_department
                  : _currentPlayer!.team == Team.blue
                      ? Icons.security
                      : Icons.person,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              _currentPlayer!.team!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showRole() {
    if (_currentPlayer?.role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 역할이 배정되지 않았습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: _currentPlayer!.team == Team.red
            ? Colors.red[700]
            : _currentPlayer!.team == Team.blue
                ? Colors.blue[700]
                : Colors.green[700],
        title: Text(
          '당신의 역할',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 좀비 감염 상태 표시
            if (_currentPlayer!.isZombie) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[700]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[500]!, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.coronavirus, color: Colors.green[400], size: 28),
                    const SizedBox(width: 8),
                    const Text(
                      '좀비 감염됨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Icon(
              _getRoleIcon(_currentPlayer!.role!),
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 16),
            Text(
              _currentPlayer!.role!.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _currentPlayer!.role!.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            // 역할별 진행 상황 표시
            if (_currentPlayer!.role == Role.gambler && _currentPlayer!.gamblerPrediction != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      '예측한 팀',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPlayer!.gamblerPrediction!.name,
                      style: TextStyle(
                        color: _currentPlayer!.gamblerPrediction == Team.red ? Colors.red[300] : Colors.blue[300],
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_currentPlayer!.role == Role.traveler) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      '인질로 보내진 횟수',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentPlayer!.hostageCount}회 / ${(_game!.settings.totalRounds / 2).ceil()}회 필요',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_currentPlayer!.role == Role.anarchist) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      '탄핵 성공 횟수',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentPlayer!.impeachmentSuccessCount}회 / ${(_game!.settings.totalRounds / 2).ceil()}회 필요',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_currentPlayer!.role == Role.minion) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    const Text(
                      '리더 생존 횟수',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_currentPlayer!.leaderSurvivalCount}회 / ${_game!.settings.totalRounds}회 중',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }


  void _showGamblerPredictionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          '도박사 - 팀 예측',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '어느 팀이 승리할지 예측하세요.\n예측이 맞으면 승리합니다!',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await _gameService.setGamblerPrediction(Team.red);
                if (mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '빨간팀 승리',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await _gameService.setGamblerPrediction(Team.blue);
                if (mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                '파란팀 승리',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 감염 알림 리스너 설정
  void _setupInfectionNotificationListener() {
    final playerId = _gameService.currentPlayerId;
    if (playerId == null) return;

    _infectionNotificationSubscription = _gameService.getInfectionNotificationsStream(playerId).listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final zombieName = data['zombieName'] as String;

        _showInfectionNotificationDialog(doc.id, zombieName);
      }
    });
  }

  // 감염 알림 다이얼로그
  void _showInfectionNotificationDialog(String notificationId, String zombieName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.coronavirus, color: Colors.green[400], size: 32),
            const SizedBox(width: 8),
            const Text(
              '좀비 감염!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, color: Colors.red[400], size: 64),
            const SizedBox(height: 16),
            Text(
              '$zombieName님에 의해 감염되었습니다.',
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[700]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[500]!, width: 2),
              ),
              child: const Text(
                '이제부터 중립팀인 "좀비"가 되었습니다.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              await _gameService.dismissInfectionNotification(notificationId);
              if (mounted) Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  // 좀비 감염 대상 선택 다이얼로그
  void _showZombieInfectDialog() {
    if (_game == null || _currentPlayer == null) return;

    // 감염 가능한 플레이어 목록 (자신 제외, 이미 좀비인 사람 제외)
    final infectablePlayers = _game!.players.where((p) =>
      p.id != _currentPlayer!.id &&
      !p.isZombie &&
      p.role != Role.zombie
    ).toList();

    if (infectablePlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('감염시킬 수 있는 플레이어가 없습니다.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.coronavirus, color: Colors.green[400], size: 28),
            const SizedBox(width: 8),
            const Text(
              '감염 대상 선택',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '카드를 공유한 플레이어를 선택하세요',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...infectablePlayers.map((player) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showInfectConfirmDialog(player);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(player.name, style: const TextStyle(fontSize: 16)),
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // 좀비가 감염 확인하는 다이얼로그
  void _showInfectConfirmDialog(Player targetPlayer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.coronavirus, color: Colors.green[400], size: 28),
            const SizedBox(width: 8),
            const Text(
              '감염 확인',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${targetPlayer.name}님을 감염시키시겠습니까?',
              style: const TextStyle(color: Colors.white, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[900]?.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[700]!, width: 2),
              ),
              child: const Text(
                '⚠️ 이 작업은 취소할 수 없습니다.\n상대방과 정말 카드를 공유했는지 확인하세요!',
                style: TextStyle(color: Colors.orange, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[400],
            ),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _gameService.infectPlayer(targetPlayer.id, _currentPlayer!.name);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${targetPlayer.name}님을 감염시켰습니다.'),
                    backgroundColor: Colors.green[700],
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('감염시키기'),
          ),
        ],
      ),
    );
  }

  void _showVotingDialog() {
    if (_currentVotingSession == null || _isVotingDialogShowing) return;

    _isVotingDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) => VotingDialog(
        votingSession: _currentVotingSession!,
        currentPlayer: _currentPlayer!,
        game: _game!,
        onVote: _castVote,
      ),
    ).then((_) {
      _isVotingDialogShowing = false;
    });
  }

  Future<void> _castVote(String votingSessionId, String vote) async {
    await _gameService.castVote(votingSessionId, vote);
    // 투표 후 즉시 게임 상태 새로고침
    await _loadGame();
  }

  IconData _getRoleIcon(Role role) {
    switch (role) {
      case Role.bomber:
        return Icons.local_fire_department;
      case Role.president:
        return Icons.account_balance;
      case Role.doctor:
        return Icons.local_hospital;
      case Role.engineer:
        return Icons.build;
      case Role.hotPotato:
        return Icons.whatshot;
      case Role.troubleshooter:
        return Icons.build_circle;
      case Role.tinkerer:
        return Icons.handyman;
      case Role.mastermind:
        return Icons.psychology;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null || _currentPlayer == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final remainingTime = _game!.remainingTime;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_game!.state == GameState.finished && _game!.winnerId != null) ...[
                Icon(
                  Icons.celebration,
                  size: 80,
                  color: _game!.winnerId == 'red' ? Colors.red : Colors.blue,
                ),
                const SizedBox(height: 24),
                Text(
                  '게임 종료!',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_game!.winnerId == 'red' ? '빨간팀' : '파란팀'} 승리!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: _game!.winnerId == 'red' ? Colors.red : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                // 플레이어 이름 표시
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _currentPlayer!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '라운드 ${_game!.currentRound}/${_game!.settings.totalRounds}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (remainingTime != null) ...[
                  Text(
                    _formatTime(remainingTime),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: remainingTime.inMinutes < 1 ? Colors.red : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  _getGameStateText(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _currentPlayer!.currentRoom == GameRoom.room1
                        ? Colors.blue[700]
                        : Colors.orange[700],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.room,
                            color: Colors.white,
                            size: 32,
                          ),
                          if (_currentPlayer!.isLeader) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.military_tech,
                              color: Colors.amber,
                              size: 24,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentPlayer!.isLeader ? '현재 위치 (리더)' : '현재 위치',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentPlayer!.currentRoom.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              // 게임 액션 버튼들
              if (_game!.state != GameState.finished) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showTeam,
                        icon: const Icon(Icons.groups),
                        label: const Text('팀 확인'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showRole,
                        icon: const Icon(Icons.assignment_ind),
                        label: const Text('역할 확인'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 좀비 감염 버튼
                if (_currentPlayer!.role == Role.zombie || _currentPlayer!.isZombie) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showZombieInfectDialog,
                      icon: Icon(Icons.coronavirus, color: Colors.green[400]),
                      label: const Text('플레이어 감염시키기'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // 리더 기능 버튼들
                if (_currentPlayer!.isLeader) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _abdicateLeadership,
                      icon: const Icon(Icons.transfer_within_a_station),
                      label: const Text('리더 하야'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (_game!.getLeaderInRoom(_currentPlayer!.currentRoom) != null &&
                           _currentPlayer!.canInitiateImpeachment) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _initiateImpeachment,
                      icon: const Icon(Icons.how_to_vote),
                      label: const Text('리더 탄핵 투표'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GameRulesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline),
                    label: const Text('게임 룰'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              TextButton.icon(
                onPressed: _leaveGame,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('게임 나가기'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbdicationDialog extends StatefulWidget {
  final List<Player> players;
  final GameRoom currentRoom;

  const _AbdicationDialog({
    required this.players,
    required this.currentRoom,
  });

  @override
  State<_AbdicationDialog> createState() => _AbdicationDialogState();
}

class _AbdicationDialogState extends State<_AbdicationDialog> {
  String? selectedPlayerId;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('리더 하야'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.currentRoom.name}에서 리더십을 넘길 플레이어를 선택하세요:'),
          const SizedBox(height: 16),
          ...widget.players.map((player) => RadioListTile<String>(
                title: Row(
                  children: [
                    if (player.isHost)
                      const Icon(Icons.star, color: Colors.yellow, size: 16),
                    if (player.isHost) const SizedBox(width: 4),
                    Text(player.name),
                    if (player.team != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: player.team == Team.red ? Colors.red : Colors.blue,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          player.team!.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                value: player.id,
                groupValue: selectedPlayerId,
                onChanged: (value) {
                  setState(() {
                    selectedPlayerId = value;
                  });
                },
              )),
          const SizedBox(height: 16),
          const Text(
            '선택한 플레이어에게 하야 요청이 전송되며, 해당 플레이어가 수락하면 리더십이 이전됩니다.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: selectedPlayerId != null
              ? () => Navigator.of(context).pop(selectedPlayerId)
              : null,
          child: const Text('하야 요청'),
        ),
      ],
    );
  }
}

class VotingDialog extends StatefulWidget {
  final VotingSession votingSession;
  final Player currentPlayer;
  final Game game;
  final Function(String, String) onVote;

  const VotingDialog({
    super.key,
    required this.votingSession,
    required this.currentPlayer,
    required this.game,
    required this.onVote,
  });

  @override
  State<VotingDialog> createState() => _VotingDialogState();
}

class _VotingDialogState extends State<VotingDialog> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.votingSession.remainingTime.inSeconds;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds = widget.votingSession.remainingTime.inSeconds;
      });

      if (_remainingSeconds <= 0 || widget.votingSession.status != VotingStatus.active) {
        timer.cancel();
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  String _getVotingTitle(VotingType type) {
    switch (type) {
      case VotingType.leaderElection:
        return '리더 선출 투표';
      case VotingType.impeachmentDecision:
        return '탄핵 찬반 투표';
      case VotingType.newLeaderElection:
        return '새 리더 선출 투표';
      case VotingType.abdicationRequest:
        final leaderName = widget.game.getPlayerById(widget.votingSession.initiatorId ?? '')?.name ?? '리더';
        return '$leaderName의 하야 요청';
    }
  }

  Widget _buildVotingOptions() {
    switch (widget.votingSession.type) {
      case VotingType.leaderElection:
      case VotingType.newLeaderElection:
        return _buildLeaderElectionOptions();
      case VotingType.impeachmentDecision:
        return _buildImpeachmentOptions();
      case VotingType.abdicationRequest:
        return _buildAbdicationOptions();
    }
  }

  Widget _buildLeaderElectionOptions() {
    final candidates = widget.game.getPlayersInRoom(widget.votingSession.room)
        .where((p) => p.id != widget.currentPlayer.id)
        .toList();

    return Column(
      children: candidates.map((candidate) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              widget.onVote(widget.votingSession.id, candidate.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(candidate.name),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildImpeachmentOptions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onVote(widget.votingSession.id, 'yes');
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('찬성'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onVote(widget.votingSession.id, 'no');
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('반대'),
          ),
        ),
      ],
    );
  }

  Widget _buildAbdicationOptions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onVote(widget.votingSession.id, 'accept');
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('수락'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onVote(widget.votingSession.id, 'reject');
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('거절'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasVoted = widget.votingSession.hasVoted(widget.currentPlayer.id);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.how_to_vote,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _getVotingTitle(widget.votingSession.type),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _remainingSeconds <= 5 ? Colors.red[600] : Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_remainingSeconds초',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (hasVoted) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '투표 완료!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.votingSession.totalVotes}/${widget.votingSession.totalEligibleVoters}명 투표함',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildVotingOptions(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}