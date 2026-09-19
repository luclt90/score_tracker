class GameDetail {
  int? id;
  int gameIndex;
  int playerId;
  int score;
  int gameId;
  String? editedAt;

  GameDetail({
    this.id,
    required this.gameIndex,
    required this.playerId,
    required this.gameId,
    required this.score,
    this.editedAt,
  });

  factory GameDetail.fromMap(Map<String, dynamic> map) => GameDetail(
    id: map["id"],
    gameIndex: map["gameIndex"],
    playerId: map["playerId"],
    gameId: map["gameId"],
    score: map["score"],
    editedAt: map["editedAt"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "gameIndex": gameIndex,
    "playerId": playerId,
    "gameId": gameId,
    "score": score,
    "editedAt": editedAt,
  };
}
