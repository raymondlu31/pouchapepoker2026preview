/// Data model for an I-Ching Trigram (8 Gua).
/// The 'binary' string is the sequence of 1s (Yang) and 0s (Yin),
/// read from bottom to top (Round 1 result is the first digit, bottom line).
class Gua8Details {
  final String binary;           // e.g., '111'
  final String symbol;             // trigram symbol ☰ ☱ ☲ ☳ ☴ ☵ ☶ ☷
  final String name_zh;          // 卦名 (e.g., 乾)
  final String name_pinyin_std;  // standard Pinyin (e.g., qian)
  final String name_pinyin_trad; // traditional Pinyin (e.g., Ch'ien)
  final String nature_zh;        // 代表自然现象 (e.g., 天)
  final String nature_en;        // English version (e.g., Heaven)

  const Gua8Details({
    required this.binary,
    required this.symbol,
    required this.name_zh,
    required this.name_pinyin_std,
    required this.name_pinyin_trad,
    required this.nature_zh,
    required this.nature_en,
  });

  @override
  String toString() => '$name_zh $symbol ($name_pinyin_std - $nature_en)';
}

/// A static class to hold and provide all 8 Gua mappings.
class Gua8Data {
  /// Maps a 3-bit binary string (e.g., '111') to the corresponding Trigram (8 Gua).
  /// Sorted by binary value (000 to 111).
  static const Map<String, Gua8Details> Gua8Map = {
    '000': Gua8Details(
      binary: '000',
      symbol: "☷",
      name_zh: "坤",
      name_pinyin_std: "kun",
      name_pinyin_trad: "K'un",
      nature_zh: "地",
      nature_en: "Earth",
    ),
    '001': Gua8Details(
      binary: '001',
      symbol: "☶",
      name_zh: "艮",
      name_pinyin_std: "gen",
      name_pinyin_trad: "Ken",
      nature_zh: "山",
      nature_en: "Mountain",
    ),
    '010': Gua8Details(
      binary: '010',
      symbol: "☵",
      name_zh: "坎",
      name_pinyin_std: "kan",
      name_pinyin_trad: "K'an",
      nature_zh: "水",
      nature_en: "Water",
    ),
    '011': Gua8Details(
      binary: '011',
      symbol: "☴",
      name_zh: "巽",
      name_pinyin_std: "xun",
      name_pinyin_trad: "Sun",
      nature_zh: "风",
      nature_en: "Wind",
    ),
    '100': Gua8Details(
      binary: '100',
      symbol: "☳",
      name_zh: "震",
      name_pinyin_std: "zhen",
      name_pinyin_trad: "Chen",
      nature_zh: "雷",
      nature_en: "Thunder",
    ),
    '101': Gua8Details(
      binary: '101',
      symbol: "☲",
      name_zh: "离",
      name_pinyin_std: "li",
      name_pinyin_trad: "Li",
      nature_zh: "火",
      nature_en: "Fire",
    ),
    '110': Gua8Details(
      binary: '110',
      symbol: "☱",
      name_zh: "兑",
      name_pinyin_std: "dui",
      name_pinyin_trad: "Tui",
      nature_zh: "泽",
      nature_en: "Lake",
    ),
    '111': Gua8Details(
      binary: '111',
      symbol: "☰",
      name_zh: "乾",
      name_pinyin_std: "qian",
      name_pinyin_trad: "Ch'ien",
      nature_zh: "天",
      nature_en: "Heaven",
    ),
  };

  /// Retrieves the 8 Gua details based on the 3-round binary result.
  static Gua8Details? get8Gua(String binary) {
    // Expects a 3-character binary string ('110')
    if (binary.length != 3 || !Gua8Map.containsKey(binary)) {
      return null;
    }
    return Gua8Map[binary];
  }
}