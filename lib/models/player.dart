class Player {
  int? id;
  String name;
  String memo;
  String createAt;

  Player(
      {this.id,
      required this.name,
      required this.memo,
      required this.createAt});

  factory Player.fromMap(Map<String, dynamic> map) => Player(
      id: map["id"],
      name: map["name"],
      memo: map["memo"],
      createAt: map["createAt"]);

  Map<String, dynamic> toMap() =>
      {"id": id, "name": name, "memo": memo, "createAt": createAt};
}
