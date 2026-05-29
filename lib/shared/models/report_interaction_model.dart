import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:civic_scope/core/utils/constants/enums.dart';

class ReportInteraction {
  String reportID;
  ReportStatus reportStatus;
  int upvotes;
  List<Comment> comments;
  DateTime lastModified;

  ReportInteraction(
    this.reportID,
    this.reportStatus,
    this.upvotes,
    this.comments,
    this.lastModified,
  );

  // { reported -> 0, assigned -> 1, underReview -> 2, underWork -> 3, repaired -> 4 }

  Map<String, dynamic> toMap() {
    return {
      "reportID": reportID,
      "status": reportStatus.name,
      "upvotes": upvotes,
      "comments": comments.map((c) => c.toJson()).toList(),
      "modified": lastModified,
    };
  }

  factory ReportInteraction.fromMap(Map<String, dynamic> map) {
    List<Comment> comments = (map["comments"] as List<dynamic>? ?? [])
        .map((item) => Comment.fromMap(item as Map<String, dynamic>))
        .toList();

    return ReportInteraction(
      map["reportID"],
      ReportStatus.fromString(map["status"] as String),
      map["upvotes"],
      comments,
      (map["modified"] as Timestamp).toDate(),
    );
  }

  factory ReportInteraction.fromJson(Map<String, dynamic> json) {
    List<Comment> comments = (json["comments"] as List<dynamic>? ?? [])
        .map((item) => Comment.fromJson(item as Map<String, dynamic>))
        .toList();

    return ReportInteraction(
      json["reportID"],
      ReportStatus.fromString(json["status"] as String),
      json["upvotes"],
      comments,
      DateTime.parse(json["modified"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "reportID": reportID,
      "status": reportStatus.name,
      "upvotes": upvotes,
      "comments": comments.map((c) => c.toJson()).toList(),
      "modified": lastModified.toIso8601String(),
    };
  }
}

class Comment {
  String commentAuthor;
  String comment;

  Comment(this.commentAuthor, this.comment);

  Map<String, dynamic> toMap() => {
    'commentAuthor': commentAuthor,
    'comment': comment,
  };

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(map['commentAuthor'] ?? '', map['comment'] ?? '');
  }

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(json['commentAuthor'] ?? '', json['comment'] ?? '');
  }

  Map<String, dynamic> toJson() => {
    'commentAuthor': commentAuthor,
    'comment': comment,
  };
}
