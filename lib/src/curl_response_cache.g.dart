// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'curl_response_cache.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedCurlEntryAdapter extends TypeAdapter<CachedCurlEntry> {
  @override
  final int typeId = 0;

  @override
  CachedCurlEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedCurlEntry(
      curlCommand: fields[0] as String,
      responseBody: fields[1] as String?,
      statusCode: fields[2] as int?,
      timestamp: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedCurlEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.curlCommand)
      ..writeByte(1)
      ..write(obj.responseBody)
      ..writeByte(2)
      ..write(obj.statusCode)
      ..writeByte(3)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedCurlEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
