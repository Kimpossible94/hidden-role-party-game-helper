enum Team { red, blue }

enum Role {
  bomber,
  president,
  redTeamMember,
  blueTeamMember,
  doctor,
  engineer,
  hotPotato,
  troubleshooter,
  tinkerer,
  mastermind,
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
    }
  }

  String get description {
    switch (this) {
      case Role.bomber:
        return '빨간팀 리더. 대통령과 같은 방에 있으면 승리.';
      case Role.president:
        return '파란팀 리더. 폭탄범과 다른 방에 있으면 승리.';
      case Role.redTeamMember:
        return '빨간팀 일반 멤버.';
      case Role.blueTeamMember:
        return '파란팀 일반 멤버.';
      case Role.doctor:
        return '파란팀. 대통령이 폭탄범과 같은 방에 있어도 치료 가능.';
      case Role.engineer:
        return '파란팀. 폭탄을 해체할 수 있음.';
      case Role.hotPotato:
        return '폭탄범과 같은 팀이 됨. 마지막에 대통령과 같은 방에 있으면 폭발.';
      case Role.troubleshooter:
        return '파란팀. 문제 상황을 해결할 수 있음.';
      case Role.tinkerer:
        return '빨간팀. 폭탄을 수리할 수 있음.';
      case Role.mastermind:
        return '빨간팀. 다른 빨간팀원들을 조종할 수 있음.';
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