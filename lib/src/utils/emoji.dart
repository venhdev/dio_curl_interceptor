class EmojiC extends Emoji {
  EmojiC(this.enabled);

  final bool enabled;

  String get info => enabled ? Emoji.info : '';

  String get success => enabled ? Emoji.success : '';

  String get redirect => enabled ? Emoji.redirect : '';

  String get error => enabled ? Emoji.error : '';

  String get alert => enabled ? Emoji.alert : '';

  String get warning => enabled ? Emoji.warning : '';

  String get question => enabled ? Emoji.question : '';

  String get loading => enabled ? Emoji.loading : '';

  String get clock => enabled ? Emoji.clock : '';

  String get doc => enabled ? Emoji.doc : '';

  String get teapot => enabled ? Emoji.teapot : '';

  String get unknown => enabled ? Emoji.unknown : '';

  String get get => enabled ? Emoji.get : '';

  String get post => enabled ? Emoji.post : '';

  String get put => enabled ? Emoji.put : '';

  String get patch => enabled ? Emoji.patch : '';

  String get delete => enabled ? Emoji.delete : '';

  String get curl => enabled ? Emoji.link : '';
  String get requestHeaders => enabled ? Emoji.requestHeaders : '';
  String get requestBody => enabled ? Emoji.requestBody : '';
  String get responseHeaders => enabled ? Emoji.responseHeaders : '';
  String get responseBody => enabled ? Emoji.responseBody : '';

  String get package => enabled ? Emoji.package : '';

  String get link => enabled ? Emoji.link : '';

  String get document => enabled ? Emoji.document : '';

  String get image => enabled ? Emoji.image : '';

  String get audio => enabled ? Emoji.audio : '';

  String get video => enabled ? Emoji.video : '';

  String get folder => enabled ? Emoji.folder : '';

  String get database => enabled ? Emoji.database : '';

  String get cloud => enabled ? Emoji.cloud : '';

  String get star => enabled ? Emoji.star : '';

  String get gear => enabled ? Emoji.gear : '';

  String get pin => enabled ? Emoji.pin : '';

  String get lightBulb => enabled ? Emoji.lightBulb : '';

  String get lock => enabled ? Emoji.lock : '';

  String get key => enabled ? Emoji.key : '';

  String get tag => enabled ? Emoji.tag : '';
}

class Emoji {
  // status codes
  static const String info = 'ℹ️'; // 1xx
  static const String success = '✅'; // 2xx
  static const String redirect = '🔄'; // 3xx
  static const String error = '❌'; // 4xx
  static const String alert = '🚨'; // 5xx
  static const String warning = '⚠️';
  static const String question = '❓';
  static const String loading = '⏳';
  static const String clock = '⏱️'; // response time
  static const String doc = '📄'; // response body
  static const String teapot = '☕'; // 418
  static const String unknown = question; // 418

  // request methods
  static const String get = '🔍'; // GET
  static const String post = '📤'; // POST
  static const String put = '📥'; // PUT
  static const String patch = '📝'; // PATCH
  static const String delete = '🗑️'; // DELETE

  // request headers
  static const String requestHeaders = '⬆️'; // Request Headers
  static const String requestBody = '📦'; // Request Body
  static const String responseHeaders = '⬇️'; // Response Headers
  static const String responseBody = '📥'; // Response Body

  // misc
  static const String package = '📦'; // Package
  static const String link = '🔗'; // Link
  static const String document = '🧾'; // Document
  static const String image = '🖼️'; // Image
  static const String audio = '🔊'; // Audio
  static const String video = '📹'; // Video
  static const String folder = '📁'; // Folder
  static const String database = '🗃️'; // Database
  static const String cloud = '☁️'; // Cloud
  static const String star = '⭐️'; // Star
  static const String gear = '⚙️'; // Gear
  static const String pin = '📌'; // Pin
  static const String lightBulb = '💡'; // Light bulb
  static const String lock = '🔒'; // Lock
  static const String key = '🔑'; // Key
  static const String tag = '🏷️'; // Tag
}