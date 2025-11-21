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
        return '에이햅 선장';
      case Role.ambassador:
        return '대사';
      case Role.angel:
        return '천사';
      case Role.blind:
        return '시각장애인';
      case Role.bombBot:
        return '폭탄봇';
      case Role.bouncer:
        return '바운서';
      case Role.butler:
        return '집사';
      case Role.clown:
        return '광대';
      case Role.conman:
        return '사기꾼';
      case Role.coyBoy:
        return '수줍은 소년';
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
        return '닥터 붐';
      case Role.drunk:
        return '술고래';
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
        return '하녀';
      case Role.martyr:
        return '순교자';
      case Role.mayor:
        return '시장';
      case Role.medic:
        return '의무병';
      case Role.mime:
        return '무언극배우';
      case Role.minion:
        return '부하';
      case Role.mistress:
        return '정부';
      case Role.moby:
        return '모비';
      case Role.mummy:
        return '미라';
      case Role.negotiator:
        return '협상가';
      case Role.nuclearTyrant:
        return '핵폭군';
      case Role.nurse:
        return '간호사';
      case Role.paparazzo:
        return '파파라치';
      case Role.paranoid:
        return '편집증 환자';
      case Role.presidentsDaughter:
        return '대통령의 딸';
      case Role.privateEye:
        return '사립탐정';
      case Role.psychologist:
        return '심리학자';
      case Role.queen:
        return '여왕';
      case Role.rival:
        return '경쟁자';
      case Role.romeo:
        return '로미오';
      case Role.security:
        return '경호원';
      case Role.shyGuy:
        return '수줍은이';
      case Role.sniper:
        return '저격수';
      case Role.spy:
        return '스파이';
      case Role.survivor:
        return '생존자';
      case Role.target:
        return '표적';
      case Role.thug:
        return '건달';
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
        return '게임 종료 시 대통령과 같은 방에 있으면 우리 팀 전원 승리. 게임 종료 전에 죽음 상태가 되면 같은 방 사람들에게 죽음을 부여하지 못함.';
      case Role.president:
        return '게임 종료 시 폭탄범과 다른 방에 있으면 우리 팀 전원 승리. 죽음 상태가 되면 우리 팀 패배.';
      case Role.redTeamMember:
        return '일반 멤버. 폭탄범이 승리하면 함께 승리.';
      case Role.blueTeamMember:
        return '일반 멤버. 대통령이 승리하면 함께 승리.';
      case Role.doctor:
        return '의사가 있을 때 추가 승리 조건: 대통령이 게임 종료 전 의사와 카드 공유를 해야 함. 공유하지 않으면 우리 팀 패배.';
      case Role.engineer:
        return '엔지니어가 있을 때 상대 팀 추가 승리 조건: 폭탄범이 게임 종료 전 엔지니어와 카드 공유를 해야 함. 공유하지 않으면 상대 팀 패배.';
      case Role.troubleshooter:
        return '의무병과 동일한 능력 - 자신과 카드 공유한 플레이어의 모든 상태이상을 제거함. 제거 가능: 수줍음, 저주, 경솔함, 죽음, 좀비 등.';
      case Role.tinkerer:
        return '엔지니어의 백업 캐릭터. 엔지니어 카드가 게임에서 제외되면 엔지니어의 모든 역할을 대신 수행함.';
      case Role.mastermind:
        return '게임 종료 시 자신이 속한 방의 리더이면서 동시에 게임 중 반대편 방의 리더였던 적이 있어야 승리.';
      case Role.gambler:
        return '마지막 라운드 종료 시 모든 플레이어가 카드를 공개하기 전에 어느 팀(빨간팀, 파란팀, 또는 둘 다 아님)이 이겼는지 공개적으로 예측해야 함. 맞추면 승리.';
      case Role.mi6:
        return '게임 중 폭탄범과 대통령 둘 다와 카드를 공유하면 승리.';
      case Role.clone:
        return '첫 번째로 카드/색상 공유한 플레이어가 승리하면 함께 승리. 게임 끝까지 공유하지 않으면 패배. (주의: 로봇과 서로 첫 공유 시 둘 다 패배)';
      case Role.robot:
        return '첫 번째로 카드/색상 공유한 플레이어가 승리 목표를 달성하지 못하면 승리. 게임 끝까지 공유하지 않으면 패배. (주의: 복제인간과 서로 첫 공유 시 둘 다 패배)';
      case Role.agoraphobe:
        return '게임 시작 시 배정받은 방에서 단 한 번도 나가지 않으면 승리.';
      case Role.traveler:
        return '과반수 이상의 라운드에서 인질로 다른 방에 보내지면 승리.';
      case Role.anarchist:
        return '과반수 이상의 라운드에서 리더 탄핵을 성공시키면 승리.';
      // 추가 캐릭터들
      case Role.agent:
        return '요원 능력(라운드당 1회) - 한 플레이어에게 카드를 사적으로 공개하고 "당신은 나와 카드를 공유해야 합니다"라고 말하여 강제로 카드 공유 가능. 수줍은이, 수줍은 소년 등에게도 작동.';
      case Role.ahab:
        return '게임 종료 시 모비가 폭탄범과 같은 방에 있고, 자신은 다른 방에 있으면 승리. (모비 사냥꾼)';
      case Role.ambassador:
        return '게임 시작 시 "나는 대사입니다!" 공개 선언. 면역 상태 (모든 능력/상태이상에 면역). 두 방을 자유롭게 이동 가능. 투표/인질/리더 불가. 플레이어 수에 포함되지 않음. 팀 소속에 따라 승리.';
      case Role.angel:
        return '행동 제약: 정직 상태로 시작. 언어로 표현하는 모든 것은 진실이어야 함. 비언어적 표현(제스처, 표정 등)으로는 거짓 전달 가능.';
      case Role.blind:
        return '행동 제약: 실명 상태로 시작. 게임 중 최선을 다해 눈을 뜨지 말아야 함. 짧은 게임이니 괜찮습니다!';
      case Role.bombBot:
        return '게임 종료 시 폭탄범과 같은 방에 있지만 대통령은 없으면 승리. (폭발용으로 설계된 로봇)';
      case Role.bouncer:
        return '바운서 능력 - 자신이 속한 방의 플레이어 수가 반대편 방보다 많을 때, 한 플레이어에게 카드를 사적으로 공개하고 "나가!"라고 말하여 즉시 방을 바꾸게 할 수 있음. 마지막 라운드와 라운드 사이 휴식시간에는 사용 불가.';
      case Role.butler:
        return '게임 종료 시 하녀와 대통령이 모두 같은 방에 있으면 승리.';
      case Role.clown:
        return '행동 제약: 게임 중 최선을 다해 항상 미소를 지어야 함. (연구에 따르면 미소를 지으면 동시에 행복해진다고 합니다!)';
      case Role.conman:
        return '사기꾼 능력 - 플레이어가 색상 공유를 동의하면, 대신 사적 카드 공개를 하게 만듦. 상대방도 반드시 사적 카드 공개를 해야 함.';
      case Role.coyBoy:
        return '수줍음 심리 상태로 시작. 색상 공유만 가능 (카드 공유 불가). 캐릭터 능력에 의한 강제 카드 공유는 가능. 심리학자가 치료 가능.';
      case Role.criminal:
        return '범죄자 능력 - 자신과 카드 공유한 플레이어에게 수줍음 상태이상을 부여함. (수줍음: 카드를 누구에게도 공개할 수 없음)';
      case Role.cupid:
        return '큐피드 능력(게임당 1회): 2명의 플레이어에게 카드를 사적으로 공개하여 사랑 상태 부여. 사랑 상태 플레이어는 원래 승리 조건을 잃고, 게임 종료 시 서로 같은 방에 있어야만 승리.';
      case Role.dealer:
        return '딜러 능력 - 자신과 카드 공유한 플레이어에게 경솔함 상태이상을 부여함. (경솔함: 카드/색상 공유 제안을 절대 거절할 수 없음)';
      case Role.decoy:
        return '마지막 라운드에서 저격수가 자신을 사격하면 승리. (미끼로 승리하면 정말 기분 좋습니다!)';
      case Role.demon:
        return '행동 제약: 거짓말쟁이 상태로 시작. 언어로 표현하는 모든 것은 거짓이어야 함. 비언어적 표현(제스처, 표정 등)으로는 진실 전달 가능. (바지에 불이 붙을 수 있으니 조심하세요!)';
      case Role.drBoom:
        return '폭발 능력: 대통령과 카드 공유 시 같은 방의 모든 사람이 즉시 죽음 상태가 되며 게임이 즉시 종료됨. (주의: 대통령의 딸에게는 작동하지 않음)';
      case Role.drunk:
        return '게임 시작 전 랜덤 캐릭터 카드 1장이 정신차림 카드로 제외됨. 마지막 라운드 시작 시 자신의 술고래 카드를 정신차림 카드와 교환하고 그 역할을 수행해야 함. 교환하지 못하면 패배.';
      case Role.enforcer:
        return '집행관 능력(라운드당 1회) - 2명의 플레이어에게 카드를 사적으로 공개하고 "당신들은 서로 카드를 공개해야 합니다"라고 말하여 강제로 카드 공유시킴. 수줍은이에게도 작동.';
      case Role.eris:
        return '에리스 능력(게임당 1회): 2명의 플레이어에게 카드를 사적으로 공개하여 증오 상태 부여. 증오 상태 플레이어는 원래 승리 조건을 잃고, 게임 종료 시 서로 다른 방에 있어야만 승리.';
      case Role.invincible:
        return '모든 능력과 상태이상에 완전 면역. 어떤 효과도 받지 않음.';
      case Role.intern:
        return '게임 종료 시 대통령과 같은 방에 있으면 승리.';
      case Role.juliet:
        return '게임 종료 시 로미오와 폭탄범이 모두 같은 방에 있으면 승리.';
      case Role.leprechaun:
        return '경솔함 상태로 시작 (카드/색상 공유 거절 불가). 레프러콘 능력: 카드 또는 색상 공유한 플레이어와 즉시 카드를 교환함. 게임 종료 시 레프러콘 역할이면 승리.';
      case Role.maid:
        return '게임 종료 시 집사와 대통령이 모두 같은 방에 있으면 승리.';
      case Role.martyr:
        return '폭탄범의 백업 캐릭터. 폭탄범 카드가 게임에서 제외되면 폭탄범의 모든 역할을 수행함 (대통령과 같은 방 위치, 엔지니어와 카드 공유 등).';
      case Role.mayor:
        return '자신이 속한 방에 짝수 명의 플레이어가 있을 때, 리더 탄핵 투표 시 카드를 공개 공개하여 2표 행사 가능. 반대편 시장도 공개하면 효과 무효.';
      case Role.medic:
        return '의무병 능력 - 자신과 카드 공유한 플레이어의 모든 상태이상을 제거함. 제거 가능: 수줍음, 저주, 경솔함, 죽음, 좀비 등. (자신은 면역 없으며, 반대편 의무병만 자신의 상태이상 제거 가능)';
      case Role.mime:
        return '행동 제약: 게임 중 최선을 다해 어떤 소음도 내지 말아야 함. (무언극을 사랑하는 사람에게 최고. 무언극을 싫어하는 사람은 이 캐릭터를 싫어할 것입니다.)';
      case Role.minion:
        return '자신이 속한 방에서 리더가 단 한 번도 탄핵당하지 않으면 승리.';
      case Role.mistress:
        return '게임 종료 시 대통령과 같은 방에 있고, 아내는 없으면 승리. (제3자의 힘을 느껴보세요!)';
      case Role.moby:
        return '게임 종료 시 에이햅이 폭탄범과 같은 방에 있고, 자신은 다른 방에 있으면 승리. (고래를 위하여!)';
      case Role.mummy:
        return '미라 능력 - 자신과 카드 공유한 플레이어에게 저주 상태이상을 부여함. (저주: 어떤 소음도 낼 수 없음. 언어 능력이 필요한 모든 능력 사용 불가)';
      case Role.negotiator:
        return '노련함 상태로 시작. 카드 공유만 가능 (색상 공유, 공개 공개, 사적 공개 모두 불가). 수줍음 상태 획득 시 아무것도 할 수 없게 됨.';
      case Role.nuclearTyrant:
        return '경솔함 상태로 시작 (카드 공유 거절 불가). 게임 종료 시 대통령과 폭탄범이 자신과 카드 공유하지 않았으면 단독 승리 (다른 모든 플레이어 패배). 둘 중 하나라도 공유했으면 패배.';
      case Role.nurse:
        return '의사의 백업 캐릭터. 의사 카드가 게임에서 제외되면 의사의 역할을 수행함 (대통령과 카드 공유 필수).';
      case Role.paparazzo:
        return '행동 제약: 사적인 대화가 없도록 최선을 다해 방해하고 침범해야 함. 사생활 보호 약속 규칙 사용 시 카드를 공개 공개하여 규칙 무시 가능. (귀찮은 존재가 되세요!)';
      case Role.paranoid:
        return '편집증 심리 상태로 시작. 카드 공유만 가능하며, 게임 중 단 한 번만 카드 공유 가능. 능력에 의한 강제 공유는 횟수에 포함되지 않음. 심리학자가 치료 가능.';
      case Role.presidentsDaughter:
        return '대통령의 백업 캐릭터. 대통령 카드가 게임에서 제외되면 대통령의 모든 역할을 수행함. (부통령이 아닙니다. 조용히 웃으세요.)';
      case Role.privateEye:
        return '마지막 라운드 종료 시 모든 플레이어가 카드를 공개하기 전에 게임에 사용되지 않고 남겨진 역할 카드의 정체를 공개적으로 발표해야 함. 맞추면 승리.';
      case Role.psychologist:
        return '심리 상태이상(수줍음, 편집증 등)을 가진 캐릭터에게 카드를 사적으로 공개하면, 그 캐릭터가 원할 경우 카드 공유 가능. 공유하면 그 플레이어의 심리 상태이상이 제거됨.';
      case Role.queen:
        return '게임 종료 시 대통령과 폭탄범 모두와 다른 방에 있으면 승리. (통치용으로 설계되었습니다.)';
      case Role.rival:
        return '게임 종료 시 대통령과 다른 방에 있으면 승리.';
      case Role.romeo:
        return '게임 종료 시 줄리엣과 폭탄범이 모두 같은 방에 있으면 승리.';
      case Role.security:
        return '태클 능력(게임당 1회) - 카드를 공개적으로 공개하고 한 플레이어를 지목하여 "너는 어디에도 못 간다"라고 말함. 그 플레이어는 이번 라운드에 인질로 선택될 수 없음. 카드는 영구적으로 공개 상태로 남음.';
      case Role.shyGuy:
        return '수줍음 심리 상태로 시작. 카드의 어떤 부분도 누구에게도 공개할 수 없음. 심리학자가 치료 가능.';
      case Role.sniper:
        return '마지막 라운드 종료 시 모든 플레이어가 카드를 공개하기 전에 한 명을 공개적으로 지목하여 사격해야 함. 지목한 플레이어가 표적 역할이면 승리.';
      case Role.spy:
        return '반대 팀 색상의 카드를 가진 스파이. 실제 팀과 카드 색이 다름.';
      case Role.survivor:
        return '게임 종료 시 폭탄범과 다른 방에 있으면 승리.';
      case Role.target:
        return '마지막 라운드 종료 시 저격수가 자신을 사격하지 않으면 승리.';
      case Role.thug:
        return '건달 능력 - 자신과 카드 공유한 플레이어에게 수줍음 상태이상을 부여함. (수줍음: 색상 공유만 가능, 완전한 카드 공유 불가)';
      case Role.tuesdayKnight:
        return '포옹 능력: 폭탄범과 카드 공유 시 대통령을 제외한 같은 방 모든 사람이 즉시 죽음 상태가 되며 게임이 즉시 종료됨. (주의: 순교자에게는 작동하지 않음)';
      case Role.usurper:
        return '찬탈자 능력(게임당 1회, 마지막 라운드 제외) - 카드를 공개적으로 공개하여 즉시 자신이 속한 방의 리더가 됨. 능력 사용한 라운드에는 탄핵당하지 않음. 카드는 영구적으로 공개 상태로 남음.';
      case Role.victim:
        return '게임 종료 시 폭탄범과 같은 방에 있으면 승리.';
      case Role.wife:
        return '게임 종료 시 대통령과 같은 방에 있고, 정부는 없으면 승리. (서약을 지키세요!)';
      case Role.zombie:
        return '좀비 상태로 시작. 카드/색상 공유 시 상대를 좀비로 감염. 좀비 팀 승리 조건: 게임 종료 시 죽음 상태가 아닌 모든 플레이어가 좀비 팀이어야 함. 감염된 플레이어는 "이제 당신도 좀비입니다"라고 알려야 함.';
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