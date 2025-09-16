import 'package:json_annotation/json_annotation.dart';

part 'offline_queue.g.dart';

enum QueueItemStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('completed')
  completed,
  @JsonValue('failed')
  failed,
}

@JsonSerializable()
class OfflineQueueItem {
  final String id;
  final String type; // 'attendance', 'login', etc.
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? processedAt;
  final QueueItemStatus status;
  final String? errorMessage;
  final int retryCount;
  final int maxRetries;

  const OfflineQueueItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.processedAt,
    this.status = QueueItemStatus.pending,
    this.errorMessage,
    this.retryCount = 0,
    this.maxRetries = 3,
  });

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) => _$OfflineQueueItemFromJson(json);
  Map<String, dynamic> toJson() => _$OfflineQueueItemToJson(this);

  OfflineQueueItem copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    DateTime? processedAt,
    QueueItemStatus? status,
    String? errorMessage,
    int? retryCount,
    int? maxRetries,
  }) {
    return OfflineQueueItem(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  bool get canRetry => retryCount < maxRetries && status == QueueItemStatus.failed;
  bool get isPending => status == QueueItemStatus.pending;
  bool get isProcessing => status == QueueItemStatus.processing;
  bool get isCompleted => status == QueueItemStatus.completed;
  bool get isFailed => status == QueueItemStatus.failed;
}
