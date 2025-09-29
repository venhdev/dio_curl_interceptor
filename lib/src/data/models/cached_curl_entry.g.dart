// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_curl_entry.dart';

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
      url: fields[4] as String?,
      duration: fields[5] as int?,
      responseHeaders: (fields[6] as Map?)?.map((dynamic k, dynamic v) =>
          MapEntry(k as String, (v as List).cast<String>())),
      method: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CachedCurlEntry obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.curlCommand)
      ..writeByte(1)
      ..write(obj.responseBody)
      ..writeByte(2)
      ..write(obj.statusCode)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.url)
      ..writeByte(5)
      ..write(obj.duration)
      ..writeByte(6)
      ..write(obj.responseHeaders)
      ..writeByte(7)
      ..write(obj.method);
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
