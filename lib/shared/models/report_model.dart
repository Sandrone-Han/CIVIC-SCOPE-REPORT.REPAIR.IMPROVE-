class Report {
  String id;
  String title;
  String author;
  String category;
  String description;
  String evidenceURL;
  double lati;
  double long;
  DateTime created;

  Report(
    this.id,
    this.title,
    this.author,
    this.category,
    this.description,
    this.evidenceURL,
    this.lati,
    this.long,
    this.created,
  );

  Map<String, String> toMap() {
    return {
      "id": id,
      "title": title,
      "author": author,
      "category": category,
      "description": description,
      "evidenceURL": evidenceURL,
      "latitude": lati.toString(),
      "longitude": long.toString(),
      "created": created.toString(),
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    double longitude = double.parse(map["longitude"]);
    double latitude = double.parse(map["latitude"]);
    DateTime created = DateTime.parse(map["created"]);

    return Report(
      map["id"],
      map["title"],
      map["author"],
      map["category"],
      map["description"],
      map["evidenceURL"],
      latitude,
      longitude,
      created,
    );
  }

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      json['id'],
      json['title'],
      json['author'],
      json['category'],
      json['description'],
      json['evidenceURL'],
      double.parse(json['latitude']),
      double.parse(json['longitude']),
      DateTime.parse(json['created']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'category': category,
      'description': description,
      'evidenceURL': evidenceURL,
      'latitude': lati.toString(),
      'longitude': long.toString(),
      'created': created.toIso8601String(),
    };
  }
}
