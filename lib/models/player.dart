enum Team { red, blue, neutral }

enum Role {
  // 기본 캐릭터들
  bomber,
  president,
  redTeamMember,
  blueTeamMember,

  // 기존 구현 캐릭터들
  doctor,
  engineer,
  hotPotato,
  troubleshooter,
  tinkerer,
  mastermind,

  // 중립 캐릭터들 (홀수 플레이어용)
  gambler,
  mi6,
  clone,
  robot,
  agoraphobe,
  traveler,
  anarchist,

  // 추가 캐릭터들 (룰북 기준)
  agent,
  ahab,
  ambassador,
  angel,
  blind,
  bombBot,
  bouncer,
  butler,
  clown,
  conman,
  coyBoy,
  criminal,
  cupid,
  dealer,
  decoy,
  demon,
  drBoom,
  drunk,
  enforcer,
  eris,
  invincible,
  intern,
  juliet,
  leprechaun,
  maid,
  martyr,
  mayor,
  medic,
  mime,
  minion,
  mistress,
  moby,
  mummy,
  negotiator,
  nuclearTyrant,
  nurse,
  paparazzo,
  paranoid,
  presidentsDaughter,
  privateEye,
  psychologist,
  queen,
  rival,
  romeo,
  security,
  shyGuy,
  sniper,
  spy,
  survivor,
  target,
  thug,
  tuesdayKnight,
  usurper,
  victim,
  wife,
  zombie,
}

enum GameRoom { room1, room2 }

class Player {
  final String id;
  final String name;
  Team? team;
  Role? role;
  GameRoom currentRoom;
  bool isHost;
  bool isLeader;
  bool canInitiateImpeachment; // 탄핵을 발의할 수 있는지
  bool hasAbdicatedThisRound; // 이 라운드에서 하야했는지

  // 역할별 선택/추적 필드
  Team? gamblerPrediction; // Gambler: 예측한 팀
  int hostageCount; // Traveler: 인질로 보내진 횟수
  int impeachmentSuccessCount; // Anarchist: 탄핵 성공 횟수
  int leaderSurvivalCount; // Minion: 자신의 방에서 리더가 탄핵당하지 않은 횟수
  String? sniperTarget; // Sniper: 지목한 타겟 플레이어 ID
  Role? privateEyeGuess; // Private Eye: 예측한 묻힌 카드 역할

  // 좀비 감염 관련 필드
  bool isZombie; // 좀비에게 감염되었는지 여부
  Team? originalTeam; // 감염되기 전 원래 팀 (통계용)

  Player({
    required this.id,
    required this.name,
    this.team,
    this.role,
    required this.currentRoom,
    this.isHost = false,
    this.isLeader = false,
    this.canInitiateImpeachment = true,
    this.hasAbdicatedThisRound = false,
    this.gamblerPrediction,
    this.hostageCount = 0,
    this.impeachmentSuccessCount = 0,
    this.leaderSurvivalCount = 0,
    this.sniperTarget,
    this.privateEyeGuess,
    this.isZombie = false,
    this.originalTeam,
  });

  Player copyWith({
    String? id,
    String? name,
    Team? team,
    Role? role,
    GameRoom? currentRoom,
    bool? isHost,
    bool? isLeader,
    bool? canInitiateImpeachment,
    bool? hasAbdicatedThisRound,
    Team? gamblerPrediction,
    int? hostageCount,
    int? impeachmentSuccessCount,
    int? leaderSurvivalCount,
    String? sniperTarget,
    Role? privateEyeGuess,
    bool? isZombie,
    Team? originalTeam,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      team: team ?? this.team,
      role: role ?? this.role,
      currentRoom: currentRoom ?? this.currentRoom,
      isHost: isHost ?? this.isHost,
      isLeader: isLeader ?? this.isLeader,
      canInitiateImpeachment: canInitiateImpeachment ?? this.canInitiateImpeachment,
      hasAbdicatedThisRound: hasAbdicatedThisRound ?? this.hasAbdicatedThisRound,
      gamblerPrediction: gamblerPrediction ?? this.gamblerPrediction,
      hostageCount: hostageCount ?? this.hostageCount,
      impeachmentSuccessCount: impeachmentSuccessCount ?? this.impeachmentSuccessCount,
      leaderSurvivalCount: leaderSurvivalCount ?? this.leaderSurvivalCount,
      sniperTarget: sniperTarget ?? this.sniperTarget,
      privateEyeGuess: privateEyeGuess ?? this.privateEyeGuess,
      isZombie: isZombie ?? this.isZombie,
      originalTeam: originalTeam ?? this.originalTeam,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'team': team?.index,
      'role': role?.index,
      'currentRoom': currentRoom.index,
      'isHost': isHost,
      'isLeader': isLeader,
      'canInitiateImpeachment': canInitiateImpeachment,
      'hasAbdicatedThisRound': hasAbdicatedThisRound,
      'gamblerPrediction': gamblerPrediction?.index,
      'hostageCount': hostageCount,
      'impeachmentSuccessCount': impeachmentSuccessCount,
      'leaderSurvivalCount': leaderSurvivalCount,
      'sniperTarget': sniperTarget,
      'privateEyeGuess': privateEyeGuess?.index,
      'isZombie': isZombie,
      'originalTeam': originalTeam?.index,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      team: json['team'] != null ? Team.values[json['team']] : null,
      role: json['role'] != null ? Role.values[json['role']] : null,
      currentRoom: GameRoom.values[json['currentRoom']],
      isHost: json['isHost'] ?? false,
      isLeader: json['isLeader'] ?? false,
      canInitiateImpeachment: json['canInitiateImpeachment'] ?? true,
      hasAbdicatedThisRound: json['hasAbdicatedThisRound'] ?? false,
      gamblerPrediction: json['gamblerPrediction'] != null ? Team.values[json['gamblerPrediction']] : null,
      hostageCount: json['hostageCount'] ?? 0,
      impeachmentSuccessCount: json['impeachmentSuccessCount'] ?? 0,
      leaderSurvivalCount: json['leaderSurvivalCount'] ?? 0,
      sniperTarget: json['sniperTarget'],
      privateEyeGuess: json['privateEyeGuess'] != null ? Role.values[json['privateEyeGuess']] : null,
      isZombie: json['isZombie'] ?? false,
      originalTeam: json['originalTeam'] != null ? Team.values[json['originalTeam']] : null,
    );
  }
}

extension RoleExtension on Role {
  String get name {
    switch (this) {
      case Role.bomber:
        return '폭탄범';
      case Role.president:
        return '대통령';
      case Role.redTeamMember:
        return '빨간팀';
      case Role.blueTeamMember:
        return '파란팀';
      case Role.doctor:
        return '의사';
      case Role.engineer:
        return '엔지니어';
      case Role.hotPotato:
        return '뜨거운 감자';
      case Role.troubleshooter:
        return '문제해결사';
      case Role.tinkerer:
        return '수리공';
      case Role.mastermind:
        return '배후의 인물';
      case Role.gambler:
        return '도박사';
      case Role.mi6:
        return 'MI6';
      case Role.clone:
        return '복제인간';
      case Role.robot:
        return '로봇';
      case Role.agoraphobe:
        return '광장공포증';
      case Role.traveler:
        return '여행자';
      case Role.anarchist:
        return '무정부주의자';
      // 추가 캐릭터들
      case Role.agent:
        return '요원';
      case Role.ahab:
        return '아합 선장';
      case Role.ambassador:
        return '대사';
      case Role.angel:
        return '천사';
      case Role.blind:
        return '시각장애인';
      case Role.bombBot:
        return '폭탄로봇';
      case Role.bouncer:
        return '경비원';
      case Role.butler:
        return '집사';
      case Role.clown:
        return '광대';
      case Role.conman:
        return '사기꾼';
      case Role.coyBoy:
        return '수줍은 남자';
      case Role.criminal:
        return '범죄자';
      case Role.cupid:
        return '큐피드';
      case Role.dealer:
        return '딜러';
      case Role.decoy:
        return '미끼';
      case Role.demon:
        return '악마';
      case Role.drBoom:
        return '붐 박사';
      case Role.drunk:
        return '술취한 사람';
      case Role.enforcer:
        return '집행관';
      case Role.eris:
        return '에리스';
      case Role.invincible:
        return '무적자';
      case Role.intern:
        return '인턴';
      case Role.juliet:
        return '줄리엣';
      case Role.leprechaun:
        return '레프러콘';
      case Role.maid:
        return '메이드';
      case Role.martyr:
        return '순교자';
      case Role.mayor:
        return '시장';
      case Role.medic:
        return '의무병';
      case Role.mime:
        return '마임';
      case Role.minion:
        return '부하';
      case Role.mistress:
        return '애인';
      case Role.moby:
        return '모비딕';
      case Role.mummy:
        return '미라';
      case Role.negotiator:
        return '협상가';
      case Role.nuclearTyrant:
        return '핵독재자';
      case Role.nurse:
        return '간호사';
      case Role.paparazzo:
        return '파파라치';
      case Role.paranoid:
        return '편집증';
      case Role.presidentsDaughter:
        return '대통령 딸';
      case Role.privateEye:
        return '사립탐정';
      case Role.psychologist:
        return '심리학자';
      case Role.queen:
        return '여왕';
      case Role.rival:
        return '라이벌';
      case Role.romeo:
        return '로미오';
      case Role.security:
        return '보안요원';
      case Role.shyGuy:
        return '수줍은 남자';
      case Role.sniper:
        return '저격수';
      case Role.spy:
        return '스파이';
      case Role.survivor:
        return '생존자';
      case Role.target:
        return '타겟';
      case Role.thug:
        return '깡패';
      case Role.tuesdayKnight:
        return '화요기사';
      case Role.usurper:
        return '찬탈자';
      case Role.victim:
        return '희생자';
      case Role.wife:
        return '아내';
      case Role.zombie:
        return '좀비';
    }
  }

  String get description {
    switch (this) {
      case Role.bomber:
        return '빨간팀 리더. 게임 종료 시 대통령과 같은 방에 있으면 빨간팀 승리.';
      case Role.president:
        return '파란팀 리더. 게임 종료 시 폭탄범과 다른 방에 있으면 파란팀 승리.';
      case Role.redTeamMember:
        return '빨간팀 일반 멤버. 폭탄범이 승리하면 함께 승리.';
      case Role.blueTeamMember:
        return '파란팀 일반 멤버. 대통령이 승리하면 함께 승리.';
      case Role.doctor:
        return '파란팀. 대통령이 죽음 상태가 되어도 치료하여 살릴 수 있음.';
      case Role.engineer:
        return '파란팀. 폭탄범과 카드 공유 시 폭탄을 해체하여 파란팀이 승리하게 만들 수 있음.';
      case Role.hotPotato:
        return '빨간팀. 게임 종료 시 대통령과 같은 방에 있으면 폭발하여 모두 죽음.';
      case Role.troubleshooter:
        return '파란팀. 카드 공유한 플레이어의 모든 상태이상(수줍음, 저주, 경솔함, 죽음 등)을 해제할 수 있음.';
      case Role.tinkerer:
        return '빨간팀. 폭탄범이 엔지니어에게 해체당해도 다시 수리할 수 있음.';
      case Role.mastermind:
        return '빨간팀. 다른 빨간팀원의 행동을 지시하고 조종할 수 있음.';
      case Role.gambler:
        return '중립. 게임 시작 시 어느 팀이 이길지 예측. 맞추면 승리, 틀리면 패배.';
      case Role.mi6:
        return '중립. 게임 중 폭탄범과 대통령 둘 다와 카드를 공유하면 승리.';
      case Role.clone:
        return '중립. 첫 번째로 카드를 공유한 플레이어의 팀이 승리하면 함께 승리.';
      case Role.robot:
        return '중립. 첫 번째로 카드를 공유한 플레이어의 팀이 패배하면 승리.';
      case Role.agoraphobe:
        return '중립. 게임 시작 시 배정받은 방에서 단 한 번도 나가지 않으면 승리.';
      case Role.traveler:
        return '중립. 과반수 이상의 라운드에서 인질로 다른 방에 보내지면 승리.';
      case Role.anarchist:
        return '중립. 과반수 이상의 라운드에서 리더 탄핵을 성공시키면 승리.';
      // 추가 캐릭터들
      case Role.agent:
        return '능력: 라운드당 한 번, 사적으로 카드를 공개하여 상대방과 강제로 카드 공유 가능.';
      case Role.ahab:
        return '빨간팀. 게임 종료 시 모비딕이 폭탄범과 같은 방에 있고 자신은 다른 방에 있으면 승리.';
      case Role.ambassador:
        return '중립. 완전 면역 상태로 두 방을 자유롭게 이동 가능. 투표, 능력, 상태이상 모두 무시됨. 배정된 팀의 승리 조건을 따름.';
      case Role.angel:
        return '행동 제약: 게임 중 항상 진실만 말해야 함. 거짓말 시 패배.';
      case Role.blind:
        return '행동 제약: 게임 중 눈을 감고 있어야 함. 눈을 뜨면 패배.';
      case Role.bombBot:
        return '파란팀. 게임 종료 시 폭탄범과 같은 방에 있지만 대통령은 없으면 승리.';
      case Role.bouncer:
        return '능력: 자신이 속한 방(플레이어가 더 많은 방)에서 다른 플레이어 한 명을 강제로 내보낼 수 있음.';
      case Role.butler:
        return '파란팀. 게임 종료 시 메이드와 대통령 모두와 같은 방에 있으면 승리.';
      case Role.clown:
        return '행동 제약: 게임 중 항상 미소를 지어야 함. 미소를 짓지 않으면 패배.';
      case Role.conman:
        return '능력: 다른 플레이어의 색상 공유 요청을 완전한 카드 공유로 바꿀 수 있음.';
      case Role.coyBoy:
        return '제약: 색상 공유만 가능. 완전한 카드 공유 불가.';
      case Role.criminal:
        return '능력: 카드 공유한 플레이어에게 수줍음 상태이상 부여. 수줍음: 카드를 아무에게도 보여줄 수 없음.';
      case Role.cupid:
        return '능력: 두 플레이어를 사랑 관계로 만들어 게임 종료 시 같은 방에 있게 만듦.';
      case Role.dealer:
        return '능력: 카드 공유한 플레이어에게 경솔함 상태이상 부여. 경솔함: 아무에게나 자동으로 카드를 보여주게 됨.';
      case Role.decoy:
        return '중립. 저격수가 게임 종료 시 자신을 지목하면 승리.';
      case Role.demon:
        return '행동 제약: 게임 중 항상 거짓말만 해야 함. 진실을 말하면 패배.';
      case Role.drBoom:
        return '빨간팀. 대통령과 카드 공유 시 같은 방의 모든 사람에게 죽음 상태이상 부여. 죽음: 게임에서 패배하며 승리 불가 (의사가 치료 가능).';
      case Role.drunk:
        return '중립. 특수: 마지막 라운드 시작 시 무작위 다른 캐릭터 카드와 교체됨. 교체된 역할의 승리 조건을 따름.';
      case Role.enforcer:
        return '능력: 두 플레이어를 지정하여 서로 카드를 공유하도록 강제할 수 있음.';
      case Role.eris:
        return '능력: 두 플레이어를 증오 관계로 만들어 게임 종료 시 서로 다른 방에 있게 만듦.';
      case Role.invincible:
        return '특수: 모든 능력과 상태이상에 완전 면역. 어떤 효과도 받지 않음.';
      case Role.intern:
        return '파란팀. 게임 종료 시 대통령과 같은 방에 있으면 승리.';
      case Role.juliet:
        return '빨간팀. 게임 종료 시 로미오와 폭탄범 모두와 같은 방에 있으면 승리.';
      case Role.leprechaun:
        return '중립. 경솔함 상태이상 보유. 카드 공유한 플레이어와 카드를 교체하며 승리.';
      case Role.maid:
        return '파란팀. 게임 종료 시 집사와 대통령 모두와 같은 방에 있으면 승리.';
      case Role.martyr:
        return '빨간팀. 폭탄범의 백업 역할. 폭탄범이 죽음 상태가 되면 대신함.';
      case Role.mayor:
        return '능력: 자신이 속한 방에 짝수 명의 플레이어가 있을 때 탄핵 투표에서 2표를 행사.';
      case Role.medic:
        return '능력: 카드 공유한 플레이어의 모든 상태이상 제거. 제거 가능: 수줍음, 저주, 경솔함, 죽음, 좀비 등.';
      case Role.mime:
        return '행동 제약: 게임 중 어떤 소음도 내지 않아야 함. 소음 발생 시 패배.';
      case Role.minion:
        return '중립. 자신이 속한 방에서 리더가 탄핵당하지 않으면 승리.';
      case Role.mistress:
        return '파란팀. 게임 종료 시 대통령과 같은 방에 있고 아내는 없으면 승리.';
      case Role.moby:
        return '빨간팀. 게임 종료 시 아합이 폭탄범과 같은 방에 있고 자신은 다른 방에 있으면 승리.';
      case Role.mummy:
        return '능력: 카드 공유한 플레이어에게 저주 상태이상 부여. 저주: 소음을 낼 수 없음 (대화, 소리 금지).';
      case Role.negotiator:
        return '제약: 카드 완전 공유만 가능. 색상 공유 불가.';
      case Role.nuclearTyrant:
        return '중립. 대통령과 폭탄범 둘 다 자신과 카드 공유하지 않으면 단독 승리. 다른 모든 플레이어는 패배.';
      case Role.nurse:
        return '파란팀. 의사의 백업 역할. 의사가 죽음 상태가 되면 대신함.';
      case Role.paparazzo:
        return '행동 제약: 사적 대화를 방해하고 시끄럽게 행동해야 함.';
      case Role.paranoid:
        return '제약: 게임 중 카드 공유를 단 한 번만 할 수 있음.';
      case Role.presidentsDaughter:
        return '파란팀. 대통령의 백업 역할. 대통령이 죽음 상태가 되면 대신함.';
      case Role.privateEye:
        return '중립. 게임 종료 시 게임에 사용되지 않고 남겨진 역할 카드(묻힌 카드)의 정체를 맞추면 승리.';
      case Role.psychologist:
        return '능력: 심리적 상태이상(수줍음, 경솔함, 저주 등)을 가진 플레이어를 치료 가능.';
      case Role.queen:
        return '파란팀. 게임 종료 시 대통령과 폭탄범 모두와 다른 방에 있으면 승리.';
      case Role.rival:
        return '파란팀. 게임 종료 시 대통령과 다른 방에 있으면 승리.';
      case Role.romeo:
        return '빨간팀. 게임 종료 시 줄리엣과 폭탄범 모두와 같은 방에 있으면 승리.';
      case Role.security:
        return '능력: 한 명을 선택하여 이번 라운드에 인질로 보내지지 않도록 보호.';
      case Role.shyGuy:
        return '제약: 수줍음 상태이상 보유. 카드를 누구에게도 공개할 수 없음. (수줍음: 카드를 아무에게도 보여줄 수 없음)';
      case Role.sniper:
        return '중립. 게임 종료 시 타겟 역할을 가진 플레이어를 지목해서 맞추면 승리.';
      case Role.spy:
        return '특수: 반대 팀 색상의 카드를 가진 스파이. 실제 팀과 카드 색이 다름.';
      case Role.survivor:
        return '파란팀. 게임 종료 시 폭탄범과 다른 방에 있으면 승리.';
      case Role.target:
        return '중립. 게임 종료 시 저격수가 자신을 지목하지 않으면 승리.';
      case Role.thug:
        return '능력: 카드 공유한 플레이어에게 수줍음 상태이상 부여. (수줍음: 카드를 아무에게도 보여줄 수 없음)';
      case Role.tuesdayKnight:
        return '빨간팀. 폭탄범과 카드 공유 시 대통령 제외 같은 방 모든 사람에게 죽음 상태이상 부여.';
      case Role.usurper:
        return '능력: 카드를 공개하여 즉시 자신이 속한 방의 리더가 됨.';
      case Role.victim:
        return '빨간팀. 게임 종료 시 폭탄범과 같은 방에 있으면 승리.';
      case Role.wife:
        return '파란팀. 게임 종료 시 대통령과 같은 방에 있고 애인은 없으면 승리.';
      case Role.zombie:
        return '중립. 카드 공유 시 상대방을 좀비로 감염시킬 수 있음. 게임 종료 시 과반수 이상의 플레이어가 좀비면 좀비들만 승리. (감염된 사람도 원래 팀을 잃고 좀비가 됨)';
    }
  }

  Team get defaultTeam {
    switch (this) {
      case Role.bomber:
      case Role.redTeamMember:
      case Role.tinkerer:
      case Role.mastermind:
        return Team.red;
      case Role.president:
      case Role.blueTeamMember:
      case Role.doctor:
      case Role.engineer:
      case Role.troubleshooter:
        return Team.blue;
      case Role.hotPotato:
        return Team.red; // 기본적으로 폭탄범과 같은 팀
      case Role.gambler:
      case Role.mi6:
      case Role.clone:
      case Role.robot:
      case Role.agoraphobe:
      case Role.traveler:
      case Role.anarchist:
        return Team.neutral;
      // 빨간팀 추가 캐릭터들
      case Role.martyr:
      case Role.drBoom:
      case Role.tuesdayKnight:
      case Role.ahab:
      case Role.moby:
      case Role.romeo:
      case Role.juliet:
      case Role.victim:
        return Team.red;
      // 파란팀 추가 캐릭터들
      case Role.bombBot:
      case Role.queen:
      case Role.butler:
      case Role.maid:
      case Role.intern:
      case Role.rival:
      case Role.survivor:
      case Role.wife:
      case Role.mistress:
      case Role.nurse:
      case Role.presidentsDaughter:
        return Team.blue;
      // 진짜 중립 캐릭터들 (독자적 승리 조건)
      case Role.sniper:
      case Role.target:
      case Role.decoy:
      case Role.nuclearTyrant:
      case Role.privateEye:
      case Role.minion:
      case Role.leprechaun:
      case Role.ambassador:
      case Role.drunk:
      case Role.zombie:
        return Team.neutral;
      // 그레이 캐릭터들 (능력형, 양 팀 가능 - 랜덤 배정)
      // 이 역할들은 게임 시작 시 빨간팀 또는 파란팀에 배정되며 소속 팀의 승리 조건을 따름
      case Role.agent:
      case Role.bouncer:
      case Role.criminal:
      case Role.dealer:
      case Role.mummy:
      case Role.thug:
      case Role.medic:
      case Role.psychologist:
      case Role.usurper:
      case Role.enforcer:
      case Role.cupid:
      case Role.eris:
      case Role.security:
      case Role.conman:
      case Role.coyBoy:
      case Role.negotiator:
      case Role.paranoid:
      case Role.angel:
      case Role.demon:
      case Role.blind:
      case Role.clown:
      case Role.mime:
      case Role.paparazzo:
      case Role.invincible:
      case Role.mayor:
      case Role.shyGuy:
      case Role.spy:
        // 일단 중립으로 설정, 역할 배정 시 빨간팀/파란팀으로 재배정됨
        return Team.neutral;
    }
  }
}

extension TeamExtension on Team {
  String get name {
    switch (this) {
      case Team.red:
        return '빨간팀';
      case Team.blue:
        return '파란팀';
      case Team.neutral:
        return '중립';
    }
  }
}

extension GameRoomExtension on GameRoom {
  String get name {
    switch (this) {
      case GameRoom.room1:
        return '방 1';
      case GameRoom.room2:
        return '방 2';
    }
  }
}