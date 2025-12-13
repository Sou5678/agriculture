import 'package:json_annotation/json_annotation.dart';

part 'detection_result.g.dart';

@JsonSerializable()
class DetectionResult {
  final String disease;
  final double confidence;
  final String severity;
  final String description;
  final List<String> symptoms;
  final List<String> treatment;
  final List<String> prevention;
  final String timestamp;

  DetectionResult({
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.description,
    required this.symptoms,
    required this.treatment,
    required this.prevention,
    required this.timestamp,
  });

  factory DetectionResult.fromJson(Map<String, dynamic> json) =>
      _$DetectionResultFromJson(json);

  Map<String, dynamic> toJson() => _$DetectionResultToJson(this);
}

@JsonSerializable()
class HistoryItem {
  final String id;
  final String imageUri;
  final DetectionResult result;
  final String timestamp;

  HistoryItem({
    required this.id,
    required this.imageUri,
    required this.result,
    required this.timestamp,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) =>
      _$HistoryItemFromJson(json);

  Map<String, dynamic> toJson() => _$HistoryItemToJson(this);
}