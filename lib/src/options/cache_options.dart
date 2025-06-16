class CacheOptions {
  const CacheOptions({
    this.cacheResponse = false,
    this.cacheError = false,
  });

  final bool cacheResponse;
  final bool cacheError;
}
