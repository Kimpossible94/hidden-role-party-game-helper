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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildExpandableSection(
              title: '게임 개요',
              icon: Icons.info,
              children: [
                _buildContentText(
                  '히든 역할 파티 게임은 숨겨진 역할을 가진 파티 게임입니다.\n\n'
                  '플레이어들은 두 개의 방으로 나뉘어 각자의 팀 목표를 달성하기 위해 경쟁합니다.',
                ),
              ],
            ),
            _buildExpandableSection(
              title: '팀 구성',
              icon: Icons.groups,
              children: [
                _buildTeamCard(
                  '빨간팀',
                  Colors.red[700]!,
                  '목표: 폭탄범이 대통령과 같은 방에 있게 하기\n'
                  '승리 조건: 게임 종료 시 폭탄범과 대통령이 같은 방에 있음',
                ),
                const SizedBox(height: 12),
                _buildTeamCard(
                  '파란팀',
                  Colors.blue[700]!,
                  '목표: 폭탄범과 대통령을 분리시키기\n'
                  '승리 조건: 게임 종료 시 폭탄범과 대통령이 다른 방에 있음',
                ),
              ],
            ),
            _buildExpandableSection(
              title: '게임 진행',
              icon: Icons.play_arrow,
              children: [
                _buildContentText(
                  '1. 모든 플레이어가 두 방 중 하나에 배치됩니다\n'
                  '2. 각 플레이어는 팀과 역할을 비밀리에 배정받습니다\n'
                  '3. 여러 라운드에 걸쳐 게임이 진행됩니다\n'
                  '4. 각 라운드마다 제한 시간이 있습니다\n'
                  '5. 라운드 사이에는 휴식 시간이 있어 방을 이동할 수 있습니다\n'
                  '6. 마지막 라운드 종료 후 승부가 결정됩니다',
                ),
              ],
            ),
            _buildExpandableSection(
              title: '역할',
              icon: Icons.assignment_ind,
              children: [
                _buildNestedExpandableSection(
                  title: '빨간팀 역할',
                  children: [
                    _buildRoleCard(Role.bomber),
                    _buildRoleCard(Role.redTeamMember),
                    _buildRoleCard(Role.martyr),
                    _buildRoleCard(Role.tinkerer),
                    _buildRoleCard(Role.mastermind),
                    _buildRoleCard(Role.drBoom),
                    _buildRoleCard(Role.cupid),
                  ],
                ),
                _buildNestedExpandableSection(
                  title: '파란팀 역할',
                  children: [
                    _buildRoleCard(Role.president),
                    _buildRoleCard(Role.blueTeamMember),
                    _buildRoleCard(Role.doctor),
                    _buildRoleCard(Role.engineer),
                    _buildRoleCard(Role.troubleshooter),
                    _buildRoleCard(Role.presidentsDaughter),
                    _buildRoleCard(Role.nurse),
                    _buildRoleCard(Role.tuesdayKnight),
                    _buildRoleCard(Role.eris),
                    _buildRoleCard(Role.bombBot),
                    _buildRoleCard(Role.queen),
                    _buildRoleCard(Role.butler),
                    _buildRoleCard(Role.maid),
                    _buildRoleCard(Role.intern),
                    _buildRoleCard(Role.rival),
                    _buildRoleCard(Role.survivor),
                    _buildRoleCard(Role.wife),
                    _buildRoleCard(Role.mistress),
                  ],
                ),
                _buildNestedExpandableSection(
                  title: '중립 역할',
                  children: [
                    _buildRoleCard(Role.gambler),
                    _buildRoleCard(Role.mi6),
                    _buildRoleCard(Role.clone),
                    _buildRoleCard(Role.robot),
                    _buildRoleCard(Role.agoraphobe),
                    _buildRoleCard(Role.traveler),
                    _buildRoleCard(Role.anarchist),
                    _buildRoleCard(Role.ahab),
                    _buildRoleCard(Role.moby),
                    _buildRoleCard(Role.romeo),
                    _buildRoleCard(Role.juliet),
                    _buildRoleCard(Role.victim),
                    _buildRoleCard(Role.sniper),
                    _buildRoleCard(Role.target),
                    _buildRoleCard(Role.decoy),
                    _buildRoleCard(Role.nuclearTyrant),
                    _buildRoleCard(Role.privateEye),
                    _buildRoleCard(Role.minion),
                    _buildRoleCard(Role.leprechaun),
                    _buildRoleCard(Role.ambassador),
                    _buildRoleCard(Role.drunk),
                    _buildRoleCard(Role.zombie),
                  ],
                ),
                _buildNestedExpandableSection(
                  title: '능력 역할 (팀 랜덤 배정)',
                  children: [
                    _buildRoleCard(Role.agent),
                    _buildRoleCard(Role.bouncer),
                    _buildRoleCard(Role.criminal),
                    _buildRoleCard(Role.dealer),
                    _buildRoleCard(Role.mummy),
                    _buildRoleCard(Role.thug),
                    _buildRoleCard(Role.medic),
                    _buildRoleCard(Role.psychologist),
                    _buildRoleCard(Role.usurper),
                    _buildRoleCard(Role.enforcer),
                    _buildRoleCard(Role.security),
                    _buildRoleCard(Role.conman),
                    _buildRoleCard(Role.spy),
                    _buildRoleCard(Role.mayor),
                  ],
                ),
                _buildNestedExpandableSection(
                  title: '행동 제약 역할 (팀 랜덤 배정)',
                  children: [
                    _buildRoleCard(Role.coyBoy),
                    _buildRoleCard(Role.negotiator),
                    _buildRoleCard(Role.paranoid),
                    _buildRoleCard(Role.shyGuy),
                    _buildRoleCard(Role.angel),
                    _buildRoleCard(Role.demon),
                    _buildRoleCard(Role.blind),
                    _buildRoleCard(Role.clown),
                    _buildRoleCard(Role.mime),
                    _buildRoleCard(Role.paparazzo),
                    _buildRoleCard(Role.invincible),
                  ],
                ),
              ],
            ),
            _buildExpandableSection(
              title: '용어 설명',
              icon: Icons.book,
              children: [
                _buildNestedExpandableSection(
                  title: '카드 공개 방식',
                  children: [
                    _buildTermCard(
                      '카드 공유 (Card Share)',
                      '두 플레이어가 서로 자신의 카드 전체를 보여주는 행위. 양방향 공개.',
                    ),
                    _buildTermCard(
                      '색상 공유 (Color Share)',
                      '카드의 색상(팀)만 보여주는 행위. 10명 이상일 때만 사용 가능.',
                    ),
                    _buildTermCard(
                      '사적 공개 (Private Reveal)',
                      '한 플레이어가 다른 플레이어에게만 일방적으로 자신의 카드를 보여주는 행위. 일방향 공개.',
                    ),
                    _buildTermCard(
                      '공개 공개 (Public Reveal)',
                      '자신의 카드를 같은 방의 모든 사람에게 공개하는 행위.',
                    ),
                  ],
                ),
                _buildNestedExpandableSection(
                  title: '상태이상',
                  children: [
                    _buildTermCard(
                      '수줍음 (Shy)',
                      '카드의 어떤 부분도 누구에게도 공개할 수 없는 상태. 심리학자가 치료 가능.',
                    ),
                    _buildTermCard(
                      '수줍음 심리 (Coy)',
                      '색상 공유만 가능하고 완전한 카드 공유는 불가능한 상태. 심리학자가 치료 가능.',
                    ),
                    _buildTermCard(
                      '편집증 (Paranoid)',
                      '카드 공유만 가능하며, 게임 중 단 한 번만 카드 공유 가능한 상태. 심리학자가 치료 가능.',
                    ),
                    _buildTermCard(
                      '저주 (Cursed)',
                      '어떤 소음도 낼 수 없으며, 언어 능력이 필요한 모든 능력을 사용할 수 없는 상태.',
                    ),
                    _buildTermCard(
                      '경솔함 (Foolish)',
                      '카드/색상 공유 제안을 절대 거절할 수 없는 상태.',
                    ),
                    _buildTermCard(
                      '죽음 (Dead)',
                      '게임에서 제외된 상태. 더 이상 게임에 참여할 수 없음.',
                    ),
                    _buildTermCard(
                      '좀비 (Zombie)',
                      '좀비 팀에 소속된 상태. 카드/색상 공유 시 상대를 감염시킴.',
                    ),
                    _buildTermCard(
                      '정직 (Honest)',
                      '언어로 표현하는 모든 것이 진실이어야 하는 상태.',
                    ),
                    _buildTermCard(
                      '거짓말쟁이 (Liar)',
                      '언어로 표현하는 모든 것이 거짓이어야 하는 상태.',
                    ),
                    _buildTermCard(
                      '실명 (Blind)',
                      '게임 중 최선을 다해 눈을 뜨지 말아야 하는 상태.',
                    ),
                    _buildTermCard(
                      '면역 (Immune)',
                      '모든 능력과 상태이상에 완전 면역인 상태.',
                    ),
                    _buildTermCard(
                      '노련함 (Savvy)',
                      '카드 공유만 가능하고 색상 공유, 공개 공개, 사적 공개 모두 불가능한 상태.',
                    ),
                  ],
                ),
                _buildNestedExpandableSection(
                  title: '특수 상태',
                  children: [
                    _buildTermCard(
                      '사랑 (In Love)',
                      '큐피드에 의해 부여됨. 원래 승리 조건을 잃고, 게임 종료 시 서로 같은 방에 있어야만 승리.',
                    ),
                    _buildTermCard(
                      '증오 (In Hate)',
                      '에리스에 의해 부여됨. 원래 승리 조건을 잃고, 게임 종료 시 서로 다른 방에 있어야만 승리.',
                    ),
                  ],
                ),
                _buildNestedExpandableSection(
                  title: '게임 용어',
                  children: [
                    _buildTermCard(
                      '백업 캐릭터 (Backup Character)',
                      '원본 캐릭터가 게임에서 제외(buried)되면 그 역할을 대신 수행하는 캐릭터. 예: 순교자→폭탄범, 대통령의 딸→대통령',
                    ),
                    _buildTermCard(
                      '게임에서 제외 (Buried)',
                      '홀수 인원일 때 사용되지 않고 남겨진 카드. 사립탐정은 이 카드를 맞춰야 승리.',
                    ),
                    _buildTermCard(
                      '정화 (Cleanse)',
                      '새로운 캐릭터 카드를 받으면 모든 상태이상이 제거되는 규칙.',
                    ),
                  ],
                ),
              ],
            ),
            _buildExpandableSection(
              title: '게임 팁',
              icon: Icons.lightbulb,
              children: [
                _buildContentText(
                  '• 자신의 역할과 팀을 다른 사람들에게 숨기세요\n'
                  '• 다른 플레이어들과 대화하며 정보를 수집하세요\n'
                  '• 상대방을 속이거나 허위 정보를 퍼뜨릴 수 있습니다\n'
                  '• 시간이 제한되어 있으니 효율적으로 움직이세요\n'
                  '• 팀워크가 승부의 열쇠입니다',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(icon, color: Colors.white),
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconColor: Colors.white,
          collapsedIconColor: Colors.white,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNestedExpandableSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      color: Colors.grey[850],
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: Colors.white70,
          collapsedIconColor: Colors.white70,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        height: 1.6,
      ),
    );
  }

  Widget _buildTeamCard(String teamName, Color color, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            teamName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(Role role) {
    Color backgroundColor;
    if (role.defaultTeam == Team.red) {
      backgroundColor = Colors.red[700]!;
    } else if (role.defaultTeam == Team.blue) {
      backgroundColor = Colors.blue[700]!;
    } else {
      backgroundColor = Colors.grey[700]!;
    }

    // 마침표 뒤에 줄바꿈 추가
    final formattedDescription = role.description.replaceAll('. ', '.\n');

    return Container(
      width: double.infinity, // full width
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRoleIcon(role),
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  role.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formattedDescription,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermCard(String term, String description) {
    // 마침표 뒤에 줄바꿈 추가
    final formattedDescription = description.replaceAll('. ', '.\n');

    return Container(
      width: double.infinity, // full width
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            term,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formattedDescription,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
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
      case Role.troubleshooter:
        return Icons.build_circle;
      case Role.tinkerer:
        return Icons.handyman;
      case Role.mastermind:
        return Icons.psychology;
      case Role.martyr:
        return Icons.favorite;
      case Role.presidentsDaughter:
        return Icons.family_restroom;
      case Role.nurse:
        return Icons.medication;
      case Role.medic:
        return Icons.health_and_safety;
      case Role.agent:
        return Icons.shield;
      case Role.enforcer:
        return Icons.gavel;
      case Role.bouncer:
        return Icons.exit_to_app;
      case Role.psychologist:
        return Icons.psychology_alt;
      case Role.gambler:
        return Icons.casino;
      case Role.mi6:
        return Icons.vpn_key;
      case Role.clone:
        return Icons.content_copy;
      case Role.robot:
        return Icons.smart_toy;
      case Role.sniper:
        return Icons.my_location;
      case Role.target:
        return Icons.gps_fixed;
      case Role.decoy:
        return Icons.person_outline;
      case Role.spy:
        return Icons.visibility;
      case Role.drBoom:
        return Icons.warning;
      case Role.tuesdayKnight:
        return Icons.security;
      default:
        return Icons.person;
    }
  }
}
