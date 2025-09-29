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
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gameUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadGame() async {
    final game = await _gameService.getGame(widget.gameId);
    if (mounted) {
      final previousVotingSession = _currentVotingSession;
      setState(() {
        _game = game;
        _currentPlayer = _game?.getPlayerById(_gameService.currentPlayerId ?? '');
        _currentVotingSession = _currentPlayer != null ? _game?.getActiveVotingForPlayer(_currentPlayer!.id) : null;
      });

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
      // 현재 게임 ID와 일치하는 업데이트만 처리
      if (updatedGame?.id == widget.gameId) {
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
        backgroundColor: _currentPlayer!.team == Team.red ? Colors.red[700] : Colors.blue[700],
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
              _currentPlayer!.team == Team.red ? Icons.local_fire_department : Icons.security,
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
        backgroundColor: _currentPlayer!.team == Team.red ? Colors.red[700] : Colors.blue[700],
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