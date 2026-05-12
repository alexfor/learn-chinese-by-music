def generate_download_url(song: dict, file_type: str, region: str) -> str | None:
    """Return the appropriate CDN URL based on file type and user region.

    file_type: 'full' | 'accompaniment' | 'vocal'
    region: 'cn' | 'global'
    """
    suffix = "_cn" if region == "cn" else "_global"
    url_key = f"{file_type}_song_url{suffix}" if file_type == "full" else f"{file_type}_url{suffix}"

    # Map file_type to actual column names
    column_map = {
        ("full", "cn"): "full_song_url_cn",
        ("full", "global"): "full_song_url_global",
        ("accompaniment", "cn"): "accompaniment_url_cn",
        ("accompaniment", "global"): "accompaniment_url_global",
        ("vocal", "cn"): "vocal_url_cn",
        ("vocal", "global"): "vocal_url_global",
    }

    column = column_map.get((file_type, region))
    if not column:
        return None

    return song.get(column) or None
