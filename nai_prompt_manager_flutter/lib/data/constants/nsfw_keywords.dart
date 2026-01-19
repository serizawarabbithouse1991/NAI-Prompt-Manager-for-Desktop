/// NSFWレベル
enum NsfwLevel {
  safe(0, 'Safe', 0xFF22C55E),           // Green - 安全
  suggestive(1, 'Suggestive', 0xFFF59E0B), // Yellow - やや露出
  questionable(2, 'Questionable', 0xFFF97316), // Orange - 疑わしい
  explicit(3, 'Explicit', 0xFFEF4444);   // Red - 明示的

  final int level;
  final String displayName;
  final int colorValue;

  const NsfwLevel(this.level, this.displayName, this.colorValue);

  static NsfwLevel fromLevel(int level) {
    return NsfwLevel.values.firstWhere(
      (e) => e.level == level,
      orElse: () => NsfwLevel.safe,
    );
  }
}

/// NSFWキーワードと重み
class NsfwKeyword {
  final String keyword;
  final double weight;
  final NsfwLevel level;

  const NsfwKeyword(this.keyword, this.weight, this.level);
}

/// NSFWキーワードデータベース
class NsfwKeywordDatabase {
  NsfwKeywordDatabase._();

  /// 全キーワードのマップ（高速検索用）
  static final Map<String, NsfwKeyword> _keywordMap = {
    for (final kw in _allKeywords) kw.keyword: kw,
  };

  /// キーワードを検索
  static NsfwKeyword? find(String keyword) {
    final normalized = keyword.trim().toLowerCase().replaceAll(' ', '_');
    return _keywordMap[normalized];
  }

  /// 複数キーワードを一括検索
  static List<NsfwKeyword> findAll(List<String> keywords) {
    final results = <NsfwKeyword>[];
    for (final keyword in keywords) {
      final found = find(keyword);
      if (found != null) {
        results.add(found);
      }
    }
    return results;
  }

  /// レベル別のキーワード一覧
  static List<NsfwKeyword> getByLevel(NsfwLevel level) {
    return _allKeywords.where((kw) => kw.level == level).toList();
  }

  // ============================================================
  // キーワード定義
  // ============================================================

  /// Suggestive（やや露出）キーワード - weight: 0.1〜0.3
  static const _suggestiveKeywords = [
    // 衣服・露出
    NsfwKeyword('cleavage', 0.2, NsfwLevel.suggestive),
    NsfwKeyword('sideboob', 0.25, NsfwLevel.suggestive),
    NsfwKeyword('underboob', 0.25, NsfwLevel.suggestive),
    NsfwKeyword('midriff', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('navel', 0.1, NsfwLevel.suggestive),
    NsfwKeyword('bare_shoulders', 0.1, NsfwLevel.suggestive),
    NsfwKeyword('bare_legs', 0.1, NsfwLevel.suggestive),
    NsfwKeyword('bare_arms', 0.05, NsfwLevel.suggestive),
    NsfwKeyword('thighs', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('thick_thighs', 0.2, NsfwLevel.suggestive),
    NsfwKeyword('thigh_gap', 0.2, NsfwLevel.suggestive),
    NsfwKeyword('wide_hips', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('huge_breasts', 0.2, NsfwLevel.suggestive),
    NsfwKeyword('large_breasts', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('medium_breasts', 0.1, NsfwLevel.suggestive),
    NsfwKeyword('breasts', 0.1, NsfwLevel.suggestive),
    NsfwKeyword('butt_crack', 0.25, NsfwLevel.suggestive),
    
    // 水着・下着
    NsfwKeyword('bikini', 0.2, NsfwLevel.suggestive),
    NsfwKeyword('swimsuit', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('one-piece_swimsuit', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('underwear', 0.2, NsfwLevel.suggestive),
    NsfwKeyword('bra', 0.2, NsfwLevel.suggestive),
    NsfwKeyword('panties', 0.25, NsfwLevel.suggestive),
    NsfwKeyword('lingerie', 0.25, NsfwLevel.suggestive),
    NsfwKeyword('leotard', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('bodysuit', 0.1, NsfwLevel.suggestive),
    NsfwKeyword('miniskirt', 0.1, NsfwLevel.suggestive),
    NsfwKeyword('short_shorts', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('microskirt', 0.2, NsfwLevel.suggestive),
    
    // ポーズ・シチュエーション
    NsfwKeyword('spread_legs', 0.3, NsfwLevel.suggestive),
    NsfwKeyword('arched_back', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('on_bed', 0.1, NsfwLevel.suggestive),
    NsfwKeyword('lying', 0.05, NsfwLevel.suggestive),
    NsfwKeyword('seductive_smile', 0.2, NsfwLevel.suggestive),
    NsfwKeyword('seductive_pose', 0.25, NsfwLevel.suggestive),
    NsfwKeyword('suggestive_fluid', 0.3, NsfwLevel.suggestive),
    NsfwKeyword('sweat', 0.1, NsfwLevel.suggestive),
    NsfwKeyword('wet', 0.15, NsfwLevel.suggestive),
    NsfwKeyword('wet_clothes', 0.2, NsfwLevel.suggestive),
  ];

  /// Questionable（疑わしい）キーワード - weight: 0.3〜0.6
  static const _questionableKeywords = [
    // 裸体・露出
    NsfwKeyword('nude', 0.5, NsfwLevel.questionable),
    NsfwKeyword('naked', 0.5, NsfwLevel.questionable),
    NsfwKeyword('completely_nude', 0.6, NsfwLevel.questionable),
    NsfwKeyword('topless', 0.5, NsfwLevel.questionable),
    NsfwKeyword('bottomless', 0.5, NsfwLevel.questionable),
    NsfwKeyword('nipples', 0.5, NsfwLevel.questionable),
    NsfwKeyword('areolae', 0.5, NsfwLevel.questionable),
    NsfwKeyword('covered_nipples', 0.35, NsfwLevel.questionable),
    NsfwKeyword('nipple_slip', 0.45, NsfwLevel.questionable),
    NsfwKeyword('no_bra', 0.35, NsfwLevel.questionable),
    NsfwKeyword('no_panties', 0.4, NsfwLevel.questionable),
    NsfwKeyword('naked_towel', 0.4, NsfwLevel.questionable),
    NsfwKeyword('naked_apron', 0.45, NsfwLevel.questionable),
    NsfwKeyword('naked_sheet', 0.4, NsfwLevel.questionable),
    NsfwKeyword('convenient_censoring', 0.45, NsfwLevel.questionable),
    NsfwKeyword('strategic_censoring', 0.45, NsfwLevel.questionable),
    
    // 下着の露出
    NsfwKeyword('panty_pull', 0.45, NsfwLevel.questionable),
    NsfwKeyword('bra_pull', 0.45, NsfwLevel.questionable),
    NsfwKeyword('clothes_lift', 0.4, NsfwLevel.questionable),
    NsfwKeyword('shirt_lift', 0.4, NsfwLevel.questionable),
    NsfwKeyword('skirt_lift', 0.4, NsfwLevel.questionable),
    NsfwKeyword('dress_lift', 0.4, NsfwLevel.questionable),
    NsfwKeyword('undressing', 0.45, NsfwLevel.questionable),
    
    // 体の部位（露出）
    NsfwKeyword('ass', 0.4, NsfwLevel.questionable),
    NsfwKeyword('buttocks', 0.4, NsfwLevel.questionable),
    NsfwKeyword('anus', 0.6, NsfwLevel.questionable),
    NsfwKeyword('cameltoe', 0.5, NsfwLevel.questionable),
    NsfwKeyword('groin', 0.45, NsfwLevel.questionable),
    NsfwKeyword('crotch', 0.45, NsfwLevel.questionable),
    NsfwKeyword('pubic_hair', 0.5, NsfwLevel.questionable),
    
    // シチュエーション
    NsfwKeyword('bathing', 0.3, NsfwLevel.questionable),
    NsfwKeyword('shower', 0.3, NsfwLevel.questionable),
    NsfwKeyword('onsen', 0.35, NsfwLevel.questionable),
    NsfwKeyword('hot_spring', 0.35, NsfwLevel.questionable),
    NsfwKeyword('wardrobe_malfunction', 0.45, NsfwLevel.questionable),
    NsfwKeyword('embarrassed_nude', 0.5, NsfwLevel.questionable),
    NsfwKeyword('exhibitionism', 0.55, NsfwLevel.questionable),
  ];

  /// Explicit（明示的）キーワード - weight: 0.6〜1.0
  static const _explicitKeywords = [
    // 性器
    NsfwKeyword('pussy', 0.9, NsfwLevel.explicit),
    NsfwKeyword('vagina', 0.9, NsfwLevel.explicit),
    NsfwKeyword('vulva', 0.9, NsfwLevel.explicit),
    NsfwKeyword('penis', 0.9, NsfwLevel.explicit),
    NsfwKeyword('testicles', 0.85, NsfwLevel.explicit),
    NsfwKeyword('erection', 0.9, NsfwLevel.explicit),
    NsfwKeyword('foreskin', 0.85, NsfwLevel.explicit),
    NsfwKeyword('clitoris', 0.9, NsfwLevel.explicit),
    NsfwKeyword('labia', 0.85, NsfwLevel.explicit),
    NsfwKeyword('spread_pussy', 0.95, NsfwLevel.explicit),
    NsfwKeyword('gaping', 0.95, NsfwLevel.explicit),
    
    // 性行為
    NsfwKeyword('sex', 0.95, NsfwLevel.explicit),
    NsfwKeyword('sexual_intercourse', 1.0, NsfwLevel.explicit),
    NsfwKeyword('penetration', 0.95, NsfwLevel.explicit),
    NsfwKeyword('vaginal', 0.9, NsfwLevel.explicit),
    NsfwKeyword('anal', 0.9, NsfwLevel.explicit),
    NsfwKeyword('oral', 0.85, NsfwLevel.explicit),
    NsfwKeyword('fellatio', 0.9, NsfwLevel.explicit),
    NsfwKeyword('cunnilingus', 0.9, NsfwLevel.explicit),
    NsfwKeyword('blowjob', 0.9, NsfwLevel.explicit),
    NsfwKeyword('handjob', 0.85, NsfwLevel.explicit),
    NsfwKeyword('footjob', 0.8, NsfwLevel.explicit),
    NsfwKeyword('titfuck', 0.85, NsfwLevel.explicit),
    NsfwKeyword('paizuri', 0.85, NsfwLevel.explicit),
    NsfwKeyword('masturbation', 0.85, NsfwLevel.explicit),
    NsfwKeyword('fingering', 0.85, NsfwLevel.explicit),
    NsfwKeyword('insertion', 0.9, NsfwLevel.explicit),
    NsfwKeyword('dildo', 0.8, NsfwLevel.explicit),
    NsfwKeyword('vibrator', 0.8, NsfwLevel.explicit),
    NsfwKeyword('sex_toy', 0.8, NsfwLevel.explicit),
    
    // 体液
    NsfwKeyword('cum', 0.9, NsfwLevel.explicit),
    NsfwKeyword('semen', 0.9, NsfwLevel.explicit),
    NsfwKeyword('ejaculation', 0.9, NsfwLevel.explicit),
    NsfwKeyword('creampie', 0.95, NsfwLevel.explicit),
    NsfwKeyword('cum_in_pussy', 0.95, NsfwLevel.explicit),
    NsfwKeyword('cum_on_body', 0.9, NsfwLevel.explicit),
    NsfwKeyword('cum_on_face', 0.9, NsfwLevel.explicit),
    NsfwKeyword('cum_in_mouth', 0.95, NsfwLevel.explicit),
    NsfwKeyword('facial', 0.9, NsfwLevel.explicit),
    NsfwKeyword('bukkake', 0.95, NsfwLevel.explicit),
    NsfwKeyword('pussy_juice', 0.85, NsfwLevel.explicit),
    NsfwKeyword('love_juice', 0.85, NsfwLevel.explicit),
    
    // 体位・シチュエーション
    NsfwKeyword('doggy_style', 0.9, NsfwLevel.explicit),
    NsfwKeyword('missionary', 0.9, NsfwLevel.explicit),
    NsfwKeyword('cowgirl_position', 0.9, NsfwLevel.explicit),
    NsfwKeyword('reverse_cowgirl', 0.9, NsfwLevel.explicit),
    NsfwKeyword('standing_sex', 0.9, NsfwLevel.explicit),
    NsfwKeyword('sex_from_behind', 0.9, NsfwLevel.explicit),
    NsfwKeyword('group_sex', 0.95, NsfwLevel.explicit),
    NsfwKeyword('threesome', 0.9, NsfwLevel.explicit),
    NsfwKeyword('orgy', 0.95, NsfwLevel.explicit),
    NsfwKeyword('gangbang', 0.95, NsfwLevel.explicit),
    NsfwKeyword('double_penetration', 0.95, NsfwLevel.explicit),
    NsfwKeyword('after_sex', 0.8, NsfwLevel.explicit),
    NsfwKeyword('implied_sex', 0.7, NsfwLevel.explicit),
    
    // BDSM・フェティッシュ
    NsfwKeyword('bondage', 0.75, NsfwLevel.explicit),
    NsfwKeyword('bdsm', 0.8, NsfwLevel.explicit),
    NsfwKeyword('rope', 0.6, NsfwLevel.explicit),
    NsfwKeyword('shibari', 0.75, NsfwLevel.explicit),
    NsfwKeyword('gag', 0.7, NsfwLevel.explicit),
    NsfwKeyword('blindfold', 0.5, NsfwLevel.explicit),
    NsfwKeyword('slave', 0.7, NsfwLevel.explicit),
    NsfwKeyword('humiliation', 0.75, NsfwLevel.explicit),
    
    // NAI/SD特有タグ
    NsfwKeyword('nsfw', 0.7, NsfwLevel.explicit),
    NsfwKeyword('explicit', 0.8, NsfwLevel.explicit),
    NsfwKeyword('hentai', 0.85, NsfwLevel.explicit),
    NsfwKeyword('porn', 0.9, NsfwLevel.explicit),
    NsfwKeyword('xxx', 0.9, NsfwLevel.explicit),
    NsfwKeyword('r-18', 0.85, NsfwLevel.explicit),
    NsfwKeyword('r18', 0.85, NsfwLevel.explicit),
  ];

  /// 全キーワード
  static const List<NsfwKeyword> _allKeywords = [
    ..._suggestiveKeywords,
    ..._questionableKeywords,
    ..._explicitKeywords,
  ];

  /// キーワード総数
  static int get totalCount => _allKeywords.length;
}
