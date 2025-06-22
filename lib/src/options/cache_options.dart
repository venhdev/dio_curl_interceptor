class CacheOptions {
  const CacheOptions({
    this.cacheResponse = false,
    this.cacheError = true,
  });

  // allEnabled factory constructor
  factory CacheOptions.allEnabled() => const CacheOptions(
        cacheResponse: true,
        cacheError: true,
      );

  final bool cacheResponse;
  final bool cacheError;
}
