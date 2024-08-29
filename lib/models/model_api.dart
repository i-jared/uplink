class ModelApi {
  final String id; 
  final String name;
  final String endpoint;
  final String apiKey;

  ModelApi({required this.id, required this.name, required this.endpoint, required this.apiKey});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'endpoint': endpoint,
      'apiKey': apiKey,
    };
  }

  factory ModelApi.fromMap(Map<String, dynamic> map) {
    return ModelApi(
      id: map['id'],
      name: map['name'],
      endpoint: map['endpoint'],
      apiKey: map['apiKey'],
    );
  }
}