import 'package:flutter/material.dart';
import '../models/player.dart';

class GameRulesScreen extends StatelessWidget {
  const GameRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('게임 룰'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                title: '게임 개요',
                icon: Icons.info,
                content: '''Two Rooms and a Boom은 숨겨진 역할을 가진 파티 게임입니다.

플레이어들은 두 개의 방으로 나뉘어 각자의 팀 목표를 달성하기 위해 경쟁합니다.''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: '팀 구성',
                icon: Icons.groups,
                content: '''• 빨간팀 (Red Team)
  - 목표: 폭탄범이 대통령과 같은 방에 있게 하기
  - 승리 조건: 게임 종료 시 폭탄범과 대통령이 같은 방에 있음

• 파란팀 (Blue Team)
  - 목표: 폭탄범과 대통령을 분리시키기
  - 승리 조건: 게임 종료 시 폭탄범과 대통령이 다른 방에 있음''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: '게임 진행',
                icon: Icons.play_arrow,
                content: '''1. 모든 플레이어가 두 방 중 하나에 배치됩니다
2. 각 플레이어는 팀과 역할을 비밀리에 배정받습니다
3. 여러 라운드에 걸쳐 게임이 진행됩니다
4. 각 라운드마다 제한 시간이 있습니다
5. 라운드 사이에는 휴식 시간이 있어 방을 이동할 수 있습니다
6. 마지막 라운드 종료 후 승부가 결정됩니다''',
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: '주요 역할',
                icon: Icons.assignment_ind,
                content: '',
              ),
              const SizedBox(height: 16),
              _buildRoleCard(Role.bomber),
              _buildRoleCard(Role.president),
              _buildRoleCard(Role.doctor),
              _buildRoleCard(Role.engineer),
              _buildRoleCard(Role.hotPotato),
              _buildRoleCard(Role.troubleshooter),
              _buildRoleCard(Role.tinkerer),
              _buildRoleCard(Role.mastermind),
              const SizedBox(height: 24),
              _buildSection(
                title: '게임 팁',
                icon: Icons.lightbulb,
                content: '''• 자신의 역할과 팀을 다른 사람들에게 숨기세요
• 다른 플레이어들과 대화하며 정보를 수집하세요
• 상대방을 속이거나 허위 정보를 퍼뜨릴 수 있습니다
• 시간이 제한되어 있으니 효율적으로 움직이세요
• 팀워크가 승부의 열쇠입니다''',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleCard(Role role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: role.defaultTeam == Team.red ? Colors.red[700] : Colors.blue[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRoleIcon(role),
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                role.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role.defaultTeam.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            role.description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
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
}