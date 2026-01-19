/// NSFWカテゴリ
enum NSFWCategory {
  drawing('Drawing'),
  hentai('Hentai'),
  neutral('Neutral'),
  porn('Porn'),
  sexy('Sexy');

  final String value;
  const NSFWCategory(this.value);

  static NSFWCategory? fromString(String? value) {
    if (value == null) return null;
    return NSFWCategory.values.cast<NSFWCategory?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// AI生成ソースの種類
enum AISourceType {
  novelai('novelai'),
  a1111('a1111'),
  comfyui('comfyui'),
  dalle('dalle'),
  gemini('gemini'),
  grok('grok'),
  midjourney('midjourney'),
  manual('manual'),
  unknown('unknown');

  final String value;
  const AISourceType(this.value);

  static AISourceType fromString(String? value) {
    if (value == null) return AISourceType.unknown;
    return AISourceType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AISourceType.unknown,
    );
  }
}

/// 表示モード
enum ViewMode {
  grid('grid'),
  list('list');

  final String value;
  const ViewMode(this.value);
}

/// サムネイルサイズ
enum ThumbnailSize {
  small('small', 100),
  medium('medium', 150),
  large('large', 200),
  xlarge('xlarge', 300);

  final String value;
  final int pixels;
  const ThumbnailSize(this.value, this.pixels);
}

/// ソート基準
enum SortBy {
  date('date'),
  name('name'),
  size('size');

  final String value;
  const SortBy(this.value);
}

/// ソート順
enum SortOrder {
  asc('asc'),
  desc('desc');

  final String value;
  const SortOrder(this.value);
}

/// リスト行の高さ
enum ListRowSize {
  compact('compact'),
  normal('normal'),
  comfortable('comfortable');

  final String value;
  const ListRowSize(this.value);
}

/// テーマモード
enum ThemeMode {
  dark('dark'),
  light('light'),
  system('system');

  final String value;
  const ThemeMode(this.value);
}

/// アップロード後の動作
enum PostUploadAction {
  keep('keep'),
  move('move'),
  delete('delete');

  final String value;
  const PostUploadAction(this.value);
}

/// ライセンスプラン
enum Plan {
  free('free'),
  pro('pro');

  final String value;
  const Plan(this.value);
}

/// Danbooruタグカテゴリ
enum DanbooruTagCategory {
  general('general', 0, '#0075f8'),
  artist('artist', 1, '#c00004'),
  copyright('copyright', 3, '#a800aa'),
  character('character', 4, '#00ab2c'),
  meta('meta', 5, '#fd9200');

  final String value;
  final int id;
  final String color;
  const DanbooruTagCategory(this.value, this.id, this.color);

  static DanbooruTagCategory? fromId(int id) {
    return DanbooruTagCategory.values.cast<DanbooruTagCategory?>().firstWhere(
          (e) => e?.id == id,
          orElse: () => null,
        );
  }

  static DanbooruTagCategory? fromString(String? value) {
    if (value == null) return null;
    return DanbooruTagCategory.values.cast<DanbooruTagCategory?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// 画像生成プロバイダー
enum ImageGenProvider {
  a1111('a1111'),
  comfyui('comfyui');

  final String value;
  const ImageGenProvider(this.value);
}

/// リスト表示カラム
enum ListColumn {
  thumbnail('thumbnail'),
  filename('filename'),
  prompt('prompt'),
  negativePrompt('negativePrompt'),
  size('size'),
  resolution('resolution'),
  fileSize('fileSize'),
  createdAt('createdAt'),
  model('model'),
  sampler('sampler'),
  steps('steps'),
  cfgScale('cfgScale'),
  seed('seed'),
  noiseSchedule('noiseSchedule'),
  sourceType('sourceType'),
  tags('tags'),
  rating('rating');

  final String value;
  const ListColumn(this.value);
}
