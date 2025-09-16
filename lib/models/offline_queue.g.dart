// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_queue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineQueueItem _$OfflineQueueItemFromJson(Map<String, dynamic> json) =>
    OfflineQueueItem(
      id: json['id'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      processedAt: json['processedAt'] == null
          ? null
          : DateTime.parse(json['processedAt'] as String),
      status:
          $enumDecodeNullable(_$QueueItemStatusEnumMap, json['status']) ??
          QueueItemStatus.pending,
      errorMessage: json['errorMessage'] as String?,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$OfflineQueueItemToJson(OfflineQueueItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'data': instance.data,
      'createdAt': instance.createdAt.toIso8601String(),
      'processedAt': instance.processedAt?.toIso8601String(),
      'status': _$QueueItemStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
      'retryCount': instance.retryCount,
      'maxRetries': instance.maxRetries,
    };

const _$QueueItemStatusEnumMap = {
  QueueItemStatus.pending: 'pending',
  QueueItemStatus.processing: 'processing',
  QueueItemStatus.completed: 'completed',
  QueueItemStatus.failed: 'failed',
};
