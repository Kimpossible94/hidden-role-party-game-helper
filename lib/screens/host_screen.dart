import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/player.dart';
import '../services/game_service.dart';
import '../widgets/room_container.dart';
import 'home_screen.dart';

class HostScreen extends StatefulWidget {
  final String gameId;

  const HostScreen({super.key, required this.gameId});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  final _gameService = GameService();
  Timer? _timer;
  StreamSubscription? _gameUpdateSubscription;
  Game? _game;

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
      setState(() {
        _game = game;
      });
    }
  }

  void _setupGameUpdateStream() {
    _gameUpdateSubscription = _gameService.gameUpdateStream.listen((updatedGame) {
      // 현재 게임 ID와 일치하는 업데이트만 처리
      if (updatedGame?.id == widget.gameId) {
        setState(() {
          _game = updatedGame;
        });
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _loadGame();

      if (_game != null && _game!.state == GameState.inProgress) {
        final remaining = _game!.remainingTime;
        if (remaining != null && remaining.inSeconds <= 0) {
          _gameService.endRound();
          _loadGame();
        }
      }
    });
  }

  Future<void> _startGame() async {
    await _gameService.startGame();
    await _loadGame();
  }

  Future<void> _startRound() async {
    await _gameService.startRound();
    await _loadGame();
  }

  Future<void> _endRound() async {
    await _gameService.endRound();
    await _loadGame();
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

  Future<void> _onPlayerMoved(String playerId, GameRoom newRoom) async {
    await _gameService.movePlayer(playerId, newRoom);
    await _loadGame();
  }

  // 진행자는 더 이상 직접 리더를 선출하지 않음
  // 첫 라운드에서 자동으로 투표가 시작됨

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildGameControls() {
    if (_game == null) return const SizedBox();

    switch (_game!.state) {
      case GameState.waiting:
        if (_game!.players.length < 4) {
          return Column(
            children: [
              Text(
                '최소 4명의 플레이어가 필요합니다',
                style: TextStyle(color: Colors.grey[400]),
              ),
              Text(
                '현재: ${_game!.players.length}명',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          );
        }
        return ElevatedButton(
          onPressed: _startGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('게임 시작'),
        );

      case GameState.starting:
        return ElevatedButton(
          onPressed: _startRound,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text('${_game!.currentRound + 1}라운드 시작'),
        );

      case GameState.inProgress:
        return ElevatedButton(
          onPressed: _endRound,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('라운드 종료'),
        );

      case GameState.break_:
        return ElevatedButton(
          onPressed: _startRound,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text('${_game!.currentRound + 1}라운드 시작'),
        );

      case GameState.finished:
        return Column(
          children: [
            Text(
              '게임 종료!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_game!.winnerId != null) ...[
              const SizedBox(height: 8),
              Text(
                '${_game!.winnerId == 'red' ? '빨간팀' : '파란팀'} 승리!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _game!.winnerId == 'red' ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _leaveGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('홈으로'),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_game == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final room1Players = _game!.getPlayersInRoom(GameRoom.room1);
    final room2Players = _game!.getPlayersInRoom(GameRoom.room2);
    final remainingTime = _game!.remainingTime;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('게임 ID: ${widget.gameId}'),
            Text(
              '진행자: ${_game!.hostName}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _leaveGame,
            icon: const Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // 상단 컴팩트 정보 바
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '라운드 ${_game!.currentRound}/${_game!.settings.totalRounds}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (remainingTime != null)
                            Text(
                              '남은 시간: ${_formatTime(remainingTime)}',
                              style: TextStyle(
                                color: remainingTime.inMinutes < 1 ? Colors.red : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          else if (_game!.state == GameState.break_)
                            const Text(
                              '쉬는 시간',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    _buildGameControls(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[900],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '게임 ID:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.gameId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: RoomContainer(
                        room: GameRoom.room1,
                        players: room1Players,
                        onPlayerMoved: _onPlayerMoved,
                        gameState: _game!.state,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: RoomContainer(
                        room: GameRoom.room2,
                        players: room2Players,
                        onPlayerMoved: _onPlayerMoved,
                        gameState: _game!.state,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      '총 ${_game!.players.length}명',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '방1: ${room1Players.length}명',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '방2: ${room2Players.length}명',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


