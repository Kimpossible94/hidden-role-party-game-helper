import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/player.dart';
import 'draggable_player_card.dart';

class RoomContainer extends StatefulWidget {
  final GameRoom room;
  final List<Player> players;
  final Function(String playerId, GameRoom newRoom) onPlayerMoved;
  final GameState gameState;
  const RoomContainer({
    super.key,
    required this.room,
    required this.players,
    required this.onPlayerMoved,
    required this.gameState,
  });

  @override
  State<RoomContainer> createState() => _RoomContainerState();
}

class _RoomContainerState extends State<RoomContainer> {
  bool _isDragOver = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Player>(
      onWillAcceptWithDetails: (details) {
        // 라운드 진행 중에는 방 이동 불가
        if (widget.gameState == GameState.inProgress) {
          return false;
        }
        // 리더는 방 이동 불가
        if (details.data.isLeader) {
          return false;
        }
        return details.data.currentRoom != widget.room;
      },
      onAcceptWithDetails: (details) {
        widget.onPlayerMoved(details.data.id, widget.room);
        setState(() {
          _isDragOver = false;
        });
      },
      onMove: (details) {
        if (!_isDragOver) {
          setState(() {
            _isDragOver = true;
          });
        }
      },
      onLeave: (player) {
        setState(() {
          _isDragOver = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isDragOver
                ? widget.room == GameRoom.room1
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.purple.withValues(alpha: 0.2)
                : Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isDragOver
                  ? widget.room == GameRoom.room1
                      ? Colors.green
                      : Colors.purple
                  : widget.room == GameRoom.room1
                      ? Colors.blue
                      : Colors.orange,
              width: _isDragOver ? 3 : 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.room == GameRoom.room1
                      ? Colors.blue[700]
                      : Colors.orange[700],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.room.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: widget.players.isEmpty
                      ? Center(
                          child: Text(
                            '플레이어가 없습니다',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: widget.players.length,
                          itemBuilder: (context, index) {
                            return DraggablePlayerCard(
                              player: widget.players[index],
                              onTap: () => _showPlayerInfo(widget.players[index]),
                              gameState: widget.gameState,
                            );
                          },
                        ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${widget.players.length}명',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlayerInfo(Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(player.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (player.isHost)
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.yellow, size: 16),
                  SizedBox(width: 4),
                  Text('진행자'),
                ],
              ),
            if (player.isHost) const SizedBox(height: 8),
            if (player.isLeader)
              const Row(
                children: [
                  Icon(Icons.military_tech, color: Colors.amber, size: 16),
                  SizedBox(width: 4),
                  Text('리더'),
                ],
              ),
            if (player.isLeader) const SizedBox(height: 8),
            Text('현재 방: ${player.currentRoom.name}'),
            if (player.team != null) ...[
              const SizedBox(height: 8),
              Text('팀: ${player.team!.name}'),
            ],
            if (player.role != null) ...[
              const SizedBox(height: 8),
              Text('역할: ${player.role!.name}'),
              const SizedBox(height: 4),
              Text(
                player.role!.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}