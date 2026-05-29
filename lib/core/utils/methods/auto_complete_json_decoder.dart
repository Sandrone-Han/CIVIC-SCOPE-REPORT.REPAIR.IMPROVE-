// ignore_for_file: prefer_null_aware_operators

import 'dart:convert';

import './auto_complete_predictions.dart';

class PlaceAutoCompleteResponse {
  final String? status;
  final List<AutoCompletePredictions>? predictions;

  PlaceAutoCompleteResponse({this.status, this.predictions});

  factory PlaceAutoCompleteResponse.fromJson(Map<String, dynamic> json) {
    return PlaceAutoCompleteResponse(
      status: json['status'] as String?,
      predictions: json['predictions'] != null
          ? json['predictions']
              .map<AutoCompletePredictions>(
                  (json) => AutoCompletePredictions.fromJson(json))
              .toList()
          : null,
    );
  }

  static PlaceAutoCompleteResponse parseResponse(String responseBody) {
    final parsed = json.decode(responseBody).cast<String, dynamic>();
    return PlaceAutoCompleteResponse.fromJson(parsed);
  }
}
