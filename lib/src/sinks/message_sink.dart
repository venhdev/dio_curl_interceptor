import '../data/models/sender_info.dart';
import 'sink.dart';

/// Sends arbitrary messages — independent of Dio / HTTP / curl events.
/// Peer to [CurlSink]; neither extends the other.
abstract class MessageSink implements Sink {
  Future<void> sendMessage(String content, {SenderInfo? senderInfo});
}
