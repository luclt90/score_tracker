class Game {
  int? id;
  int numberOfPlayers;
  String createAt;

  Game({this.id, required this.numberOfPlayers, required this.createAt});

  factory Game.fromMap(Map<String, dynamic> map) => Game(
      id: map["id"],
      numberOfPlayers: map["numberOfPlayers"],
      createAt: map["createAt"]);

  Map<String, dynamic> toMap() => {
        "id": id,
        "numberOfPlayers": numberOfPlayers,
        "createAt": createAt,
      };
}
