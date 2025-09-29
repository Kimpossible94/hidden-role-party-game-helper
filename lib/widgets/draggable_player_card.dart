import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/player.dart';

class DraggablePlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  final GameState gameState;

  const DraggablePlayerCard({
    super.key,
    required this.player,
    this.onTap,
    required this.gameState,
  });

  @override
  Widget build(BuildContext context) {
    // 라운드 진행 중이거나 리더인 경우 드래그 비활성화
    if (gameState == GameState.inProgress || player.isLeader) {
      return GestureDetector(
        onTap: onTap,
        child: _buildCard(),
      );
    }

    return Draggable<Player>(
      data: player,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: _buildCard(isDragging: true),
      ),
      childWhenDragging: _buildCard(isDragging: false, opacity: 0.5),
      child: GestureDetector(
        onTap: onTap,
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard({bool isDragging = false, double opacity = 1.0}) {
    Color cardColor = Colors.grey[800]!;
    Color textColor = Colors.white;

    // 리더이거나 라운드 진행 중일 때 약간 어둡게 표시
    bool isDragDisabled = gameState == GameState.inProgress || player.isLeader;

    if (player.team != null) {
      cardColor = player.team == Team.red ? Colors.red[700]! : Colors.blue[700]!;
      if (isDragDisabled && !isDragging) {
        cardColor = cardColor.withValues(alpha: 0.7);
      }
    } else if (isDragDisabled && !isDragging) {
      cardColor = cardColor.withValues(alpha: 0.7);
    }

    return Opacity(
      opacity: opacity,
      child: Container(
        width: isDragging ? 120 : double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8),
          border: player.isHost
              ? Border.all(color: Colors.yellow, width: 2)
              : player.isLeader
                  ? Border.all(color: Colors.amber, width: 2)
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (player.isHost)
                  const Icon(
                    Icons.star,
                    color: Colors.yellow,
                    size: 16,
                  ),
                if (player.isHost) const SizedBox(width: 4),
                if (player.isLeader)
                  const Icon(
                    Icons.military_tech,
                    color: Colors.amber,
                    size: 16,
                  ),
                if (player.isLeader) const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    player.name,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (player.team != null && player.role != null) ...[
              const SizedBox(height: 4),
              Text(
                player.role!.name,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}