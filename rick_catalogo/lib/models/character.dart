//Representa um personagem retornado pela Rick e Morty API.
// https://rickandmortyapi.com/documentation
class Character {
  final int id;
  final String name;
  final String status; // Alive, Dead, unknown
  final String species;
  final String type;
  final String gender;
  final String imageUrl;
  final String originName;
  final String locationName;

  Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.type,
    required this.gender,
    required this.imageUrl,
    required this.originName,
    required this.locationName,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Sem nome',
      status: json['status'] as String? ?? 'unknown',
      species: json['species'] as String? ?? 'Desconhecida',
      type: (json['type'] as String?)?.isNotEmpty == true
          ? json['type'] as String
          : '—',
      gender: json['gender'] as String? ?? 'unknown',
      // Alguns itens podem não trazer imagem: tratamos como string vazia
      // para a UI decidir exibir um placeholder (RF01)
      imageUrl: json['image'] as String? ?? '',
      originName: (json['origin'] as Map<String, dynamic>?)?['name'] as String? ??
          'Desconhecida',
      locationName:
          (json['location'] as Map<String, dynamic>?)?['name'] as String? ??
              'Desconhecida',
    );
  }

  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'name': name,
        'status': status,
        'species': species,
        'type': type,
        'gender': gender,
        'image': imageUrl,
        'origin': {'name': originName},
        'location': {'name': locationName},
      };
}
