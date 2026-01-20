/// Tag Classification Dictionary for NovelAI / Danbooru-style prompts
/// Used for categorizing tags into character, composition, style, and background

/// タグカテゴリの種類
enum TagCategory {
  character,   // キャラクター関連（髪、目、表情、服装）
  composition, // 構図関連（ポーズ、アングル、構図）
  style,       // スタイル関連（品質タグ、アーティスト）
  background,  // 背景関連（背景、シチュエーション）
  misc,        // その他
}

/// タグ分類辞書
class TagDictionary {
  // ============================================
  // Character-related patterns
  // ============================================
  
  static final List<RegExp> _characterPatterns = [
    // Hair
    RegExp(r'\b(hair|ahoge|bangs|ponytail|twintails?|pigtails?|braid|bob cut|hime cut|side ponytail|low ponytail|high ponytail|hair bun|twin braids|french braid|fishtail braid|drill hair|ringlets|curly hair|wavy hair|straight hair|messy hair|short hair|long hair|medium hair|very long hair|shoulder-length hair|hair over (one )?eye|hair between eyes|sidelocks|hair ribbon|hair ornament|hairclip|hairpin|hairband|headband|hair flower|hair bow|scrunchie)\b', caseSensitive: false),
    
    // Hair colors
    RegExp(r'\b(blonde|brunette|redhead|black hair|white hair|silver hair|grey hair|gray hair|blue hair|green hair|pink hair|purple hair|red hair|orange hair|brown hair|multicolored hair|gradient hair|streaked hair|two-tone hair)\b', caseSensitive: false),
    
    // Eyes
    RegExp(r'\b(eyes?|eye color|blue eyes?|red eyes?|green eyes?|brown eyes?|purple eyes?|yellow eyes?|orange eyes?|pink eyes?|heterochromia|multicolored eyes?|gradient eyes?|glowing eyes?|empty eyes?|half-closed eyes?|closed eyes?|one eye closed|wink|narrow eyes?|wide eyes?|tareme|tsurime)\b', caseSensitive: false),
    
    // Face / Expression
    RegExp(r'\b(face|expression|smile|smiling|grin|laugh|crying|tears|blush|blushing|frown|pout|ahegao|angry|sad|happy|surprised|confused|embarrassed|nervous|scared|sleepy|tired|serious|determined|open mouth|closed mouth|parted lips|tongue out|licking lips|drool)\b', caseSensitive: false),
    
    // Body type / Features
    RegExp(r'\b(girl|boy|woman|man|female|male|loli|shota|mature|milf|petite|tall|short|slim|slender|muscular|chubby|curvy|thicc|large breasts?|medium breasts?|small breasts?|flat chest|huge breasts?|cleavage|navel|belly button|abs|midriff|thighs?|legs?|arms?|hands?|feet|barefoot)\b', caseSensitive: false),
    
    // Clothing
    RegExp(r'\b(dress|shirt|blouse|sweater|hoodie|jacket|coat|cardigan|vest|tank top|crop top|t-shirt|uniform|school uniform|sailor uniform|maid|nurse|bikini|swimsuit|lingerie|underwear|bra|panties|stockings|thighhighs?|knee highs?|socks|tights|pantyhose|skirt|miniskirt|pleated skirt|pants|shorts|jeans|leggings|apron|ribbon|bow|tie|necktie|bowtie|scarf|choker|necklace|collar|belt|gloves|hat|cap|crown|tiara|glasses|sunglasses|mask|earrings?|bracelet|ring|watch|bag|purse|boots?|heels?|shoes?|sandals?|slippers?)\b', caseSensitive: false),
    
    // Accessories / Items
    RegExp(r'\b(wings?|tail|horns?|ears|animal ears|cat ears|dog ears|fox ears|rabbit ears|elf ears|pointy ears|halo|demon|angel|kemonomimi|nekomimi|maid headdress|witch hat|santa hat|bunny ears|headphones?|microphone)\b', caseSensitive: false),
    
    // Character actions
    RegExp(r'\b(holding|carrying|sitting|standing|lying|walking|running|jumping|flying|floating|kneeling|crouching|leaning|reaching|pointing|waving|hugging|kissing|dancing|sleeping|eating|drinking|reading|writing|playing|fighting)\b', caseSensitive: false),
  ];

  // ============================================
  // Composition-related patterns
  // ============================================
  
  static final List<RegExp> _compositionPatterns = [
    // Camera angle / View
    RegExp(r"\b(from (above|below|behind|side|front)|bird'?s eye view|worm'?s eye view|dutch angle|low angle|high angle|straight-on|three-quarter view|profile|side view|back view|front view)\b", caseSensitive: false),
    
    // Framing / Shot type
    RegExp(r'\b(portrait|close-?up|face focus|upper body|lower body|full body|cowboy shot|medium shot|wide shot|extreme close-?up|headshot|bust|half body|torso|feet out of frame|head out of frame|cropped)\b', caseSensitive: false),
    
    // Pose
    RegExp(r'\b(pose|posing|spread (legs|arms)|crossed (legs|arms)|hands on hips|hand on hip|arms behind back|arms up|arms down|hands together|hands clasped|peace sign|v sign|finger to mouth|thinking pose|action pose|dynamic pose|fighting stance|sitting pose|lying pose|fetal position|arched back|leaning forward|leaning back|looking (at viewer|away|back|down|up|to the side))\b', caseSensitive: false),
    
    // Depth / Focus
    RegExp(r'\b(depth of field|bokeh|blurry background|blurry foreground|focus|sharp focus|soft focus|motion blur|lens flare)\b', caseSensitive: false),
    
    // Aspect / Layout
    RegExp(r'\b(solo|duo|group|multiple (girls|boys|people)|crowd|1girl|2girls|3girls|1boy|2boys|3boys|multiple views|reference sheet|character sheet)\b', caseSensitive: false),
  ];

  // ============================================
  // Style-related patterns
  // ============================================
  
  static final List<RegExp> _stylePatterns = [
    // Quality tags
    RegExp(r'\b(masterpiece|best quality|high quality|highest quality|ultra detailed|extremely detailed|very detailed|intricate details?|highly detailed|absurdres|highres|hires|8k|4k|hd|uhd|perfect|beautiful|gorgeous|stunning|amazing|incredible|exquisite)\b', caseSensitive: false),
    
    // Art style
    RegExp(r'\b(anime|manga|illustration|digital art|digital painting|concept art|fanart|official art|key visual|promotional art|cover art|pixiv|artstation|deviantart|realistic|photorealistic|semi-realistic|stylized|cel shaded|flat color|monochrome|grayscale|sketch|lineart|line art|watercolor|oil painting|acrylic|pastel|colored pencil|traditional media)\b', caseSensitive: false),
    
    // Artist tags
    RegExp(r'\b(artist:|by |style of |art by |drawn by )\w+', caseSensitive: false),
    RegExp(r'\b(artist:[\w\s]+)\b', caseSensitive: false),
    
    // Lighting
    RegExp(r'\b(lighting|light|sunlight|moonlight|candlelight|neon|backlighting|backlit|rim lighting|rim light|dramatic lighting|soft lighting|hard lighting|ambient lighting|volumetric lighting|cinematic lighting|studio lighting|natural lighting|artificial lighting|glowing|radiant|luminous|dark|bright|dim|shadowy|contrasting|high contrast|low contrast)\b', caseSensitive: false),
    
    // Color / Mood
    RegExp(r'\b(vibrant|vivid|saturated|desaturated|muted|pastel colors?|warm colors?|cool colors?|complementary colors?|analogous colors?|triadic colors?|monochromatic|sepia|vintage|retro|nostalgic|dreamy|ethereal|dark theme|light theme|colorful|rainbow)\b', caseSensitive: false),
    
    // Negative quality (for reference)
    RegExp(r'\b(lowres|bad anatomy|bad hands|text|error|missing fingers|extra digit|fewer digits|cropped|worst quality|low quality|normal quality|jpeg artifacts|signature|watermark|username|blurry|bad feet|mutation|deformed|ugly|duplicate|morbid|mutilated|poorly drawn|bad proportions|gross proportions|malformed limbs|missing arms|missing legs|extra arms|extra legs|fused fingers|too many fingers|long neck)\b', caseSensitive: false),
  ];

  // ============================================
  // Background-related patterns
  // ============================================
  
  static final List<RegExp> _backgroundPatterns = [
    // Background type
    RegExp(r'\b(background|bg|simple background|white background|black background|grey background|gray background|gradient background|transparent background|blurred background|detailed background|no background|plain background|solid color background)\b', caseSensitive: false),
    
    // Location / Setting
    RegExp(r'\b(indoor|indoors|outdoor|outdoors|interior|exterior|room|bedroom|bathroom|kitchen|living room|classroom|office|hospital|library|cafe|restaurant|bar|club|gym|pool|beach|park|garden|forest|mountain|city|street|alley|rooftop|balcony|window|door|stairs|hallway|corridor)\b', caseSensitive: false),
    
    // Nature / Environment
    RegExp(r'\b(sky|clouds?|sun|moon|stars?|night sky|sunset|sunrise|dawn|dusk|twilight|blue sky|cloudy sky|overcast|rain|raining|rainy|snow|snowing|snowy|winter|spring|summer|autumn|fall|seasons?|weather|storm|thunder|lightning|fog|mist|haze)\b', caseSensitive: false),
    
    // Architecture / Objects
    RegExp(r'\b(building|house|castle|tower|temple|shrine|church|school|train|car|vehicle|boat|ship|airplane|bridge|fence|wall|floor|ceiling|table|chair|bed|sofa|desk|window|curtain|lamp|mirror|picture frame|bookshelf|plant|flower|tree|grass|water|river|lake|ocean|sea|pond)\b', caseSensitive: false),
    
    // Time / Atmosphere
    RegExp(r'\b(day|daytime|night|nighttime|evening|morning|afternoon|midnight|golden hour|blue hour|magic hour)\b', caseSensitive: false),
  ];

  /// タグをカテゴリに分類
  static TagCategory categorizeTag(String tag) {
    final normalizedTag = tag.trim().toLowerCase();
    
    // Check style first (quality tags are important)
    for (final pattern in _stylePatterns) {
      if (pattern.hasMatch(normalizedTag)) {
        return TagCategory.style;
      }
    }
    
    // Check composition
    for (final pattern in _compositionPatterns) {
      if (pattern.hasMatch(normalizedTag)) {
        return TagCategory.composition;
      }
    }
    
    // Check character
    for (final pattern in _characterPatterns) {
      if (pattern.hasMatch(normalizedTag)) {
        return TagCategory.character;
      }
    }
    
    // Check background
    for (final pattern in _backgroundPatterns) {
      if (pattern.hasMatch(normalizedTag)) {
        return TagCategory.background;
      }
    }
    
    // Default to misc
    return TagCategory.misc;
  }

  /// 品質タグのリスト（スタイル要約用）
  static const List<String> qualitySummaryTags = [
    'masterpiece',
    'best quality',
    'high quality',
    'ultra detailed',
    'highly detailed',
    'absurdres',
    'highres',
  ];

  /// 保持すべきタグ（変更しない）
  static const List<String> preserveTags = [
    'masterpiece',
    'best quality',
    'worst quality',
    'low quality',
    'normal quality',
  ];
}
