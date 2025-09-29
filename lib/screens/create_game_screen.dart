import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/game_service.dart';
import 'host_screen.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _nameController = TextEditingController();
  final _roundsController = TextEditingController(text: '3');
  final _gameService = GameService();
  List<TextEditingController> _roundTimeControllers = [
    TextEditingController(text: '5'),
    TextEditingController(text: '4'),
    TextEditingController(text: '3'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _roundsController.dispose();
    for (final controller in _roundTimeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateRoundControllers(int rounds) {
    // 기존 컨트롤러들 정리
    for (final controller in _roundTimeControllers) {
      controller.dispose();
    }

    // 새로운 컨트롤러들 생성
    _roundTimeControllers = List.generate(
      rounds,
      (index) => TextEditingController(text: '${5 - index > 1 ? 5 - index : 1}'),
    );

    setState(() {});
  }

  Future<void> _createGame() async {
    final totalRounds = int.tryParse(_roundsController.text) ?? 3;

    if (totalRounds < 1 || totalRounds > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('라운드 수는 1~10 사이여야 합니다.')),
      );
      return;
    }

    // 각 라운드 시간 검증
    List<int> roundDurations = [];
    for (int i = 0; i < _roundTimeControllers.length; i++) {
      final duration = int.tryParse(_roundTimeControllers[i].text) ?? 1;
      if (duration < 1 || duration > 30) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${i + 1}라운드 시간은 1~30분 사이여야 합니다.')),
        );
        return;
      }
      roundDurations.add(duration);
    }

    final settings = GameSettings(
      totalRounds: totalRounds,
      roundDurationsMinutes: roundDurations,
    );

    try {
      final gameId = await _gameService.createGame('진행자', settings);

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => HostScreen(gameId: gameId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임 생성 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('새 게임 만들기'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '게임 설정',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _roundsController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final rounds = int.tryParse(value) ?? 3;
                  if (rounds >= 1 && rounds <= 10) {
                    _updateRoundControllers(rounds);
                  }
                },
                decoration: InputDecoration(
                  labelText: '총 라운드 수',
                  labelStyle: const TextStyle(color: Colors.grey),
                  hintText: '3',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '각 라운드별 시간 설정',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: ListView.builder(
                  itemCount: _roundTimeControllers.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              '${index + 1}라운드',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _roundTimeControllers[index],
                              style: const TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                suffixText: '분',
                                suffixStyle: const TextStyle(color: Colors.grey),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Colors.red),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _createGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '게임 방 만들기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}