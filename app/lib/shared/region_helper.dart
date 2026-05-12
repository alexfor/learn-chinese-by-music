/// Selects the appropriate audio URL based on user region.
///
/// Region 'cn' uses *_url_cn fields (Qiniu), 'global' uses *_url_global (R2).
/// Falls back to whichever URL is available.
class RegionHelper {
  /// Returns the best audio URL for the given region.
  /// Tries the region-specific URL first, falls back to the alternative.
  static String? selectUrl({
    required String? cnUrl,
    required String? globalUrl,
    required String region,
  }) {
    if (region == 'cn') {
      return cnUrl ?? globalUrl;
    }
    return globalUrl ?? cnUrl;
  }
}
