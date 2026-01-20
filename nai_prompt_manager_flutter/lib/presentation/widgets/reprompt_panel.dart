import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

import '../../services/prompt_processor_service.dart';
import '../themes/nai_theme.dart';

/// Instant Re-Prompt Panel
/// 画像のプロンプトを解析し、再生成・改変・スタイル固定用に整形して表示
class RePromptPanel extends StatefulWidget {
  final String? positivePrompt;
  final String? negativePrompt;
  final VoidCallback? onCopySuccess;

  const RePromptPanel({
    super.key,
    this.positivePrompt,
    this.negativePrompt,
    this.onCopySuccess,
  });

  @override
  State<RePromptPanel> createState() => _RePromptPanelState();
}

class _RePromptPanelState extends State<RePromptPanel> {
  int _selectedTab = 0;
  ProcessedPrompts? _processedPrompts;
  String? _copiedField;

  @override
  void initState() {
    super.initState();
    _processPrompts();
  }

  @override
  void didUpdateWidget(RePromptPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.positivePrompt != widget.positivePrompt) {
      _processPrompts();
    }
  }

  void _processPrompts() {
    if (widget.positivePrompt != null && widget.positivePrompt!.isNotEmpty) {
      setState(() {
        _processedPrompts = PromptProcessorService.process(widget.positivePrompt!);
      });
    } else {
      setState(() {
        _processedPrompts = null;
      });
    }
  }

  Future<void> _copyToClipboard(String text, String fieldName) async {
    await Clipboard.setData(ClipboardData(text: text));
    setState(() {
      _copiedField = fieldName;
    });
    widget.onCopySuccess?.call();
    
    // 2秒後にコピー状態をリセット
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _copiedField = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_processedPrompts == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.processing, size: 32, color: NaiTheme.text2),
            const SizedBox(height: 12),
            Text(
              'プロンプト情報がありません',
              style: TextStyle(color: NaiTheme.text2, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ヘッダー: スタイル要約
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: NaiTheme.bg1,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(FluentIcons.lightbulb, size: 16, color: NaiTheme.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Instant Re-Prompt',
                    style: TextStyle(
                      color: NaiTheme.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _processedPrompts!.styleSummary,
                style: TextStyle(
                  color: NaiTheme.text2,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // タブ
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: NaiTheme.bg3, width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildTab(0, '再生成'),
              _buildTab(1, '改変'),
              _buildTab(2, 'スタイル'),
            ],
          ),
        ),

        // コンテンツ
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: _buildTabContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? NaiTheme.accent : Colors.transparent,
                width: 2,
              ),
            ),
            color: isSelected ? NaiTheme.bg2.withAlpha(100) : Colors.transparent,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? NaiTheme.accent : NaiTheme.text2,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildRegenerateTab();
      case 1:
        return _buildModifyTab();
      case 2:
        return _buildStyleTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRegenerateTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPromptSection(
          title: 'Positive Prompt（正規化済み）',
          content: _processedPrompts!.forRegeneration,
          fieldName: 'positive',
          color: NaiTheme.success,
        ),
        const SizedBox(height: 16),
        if (widget.negativePrompt != null && widget.negativePrompt!.isNotEmpty)
          _buildPromptSection(
            title: 'Negative Prompt',
            content: widget.negativePrompt!,
            fieldName: 'negative',
            color: NaiTheme.error,
          ),
      ],
    );
  }

  Widget _buildModifyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPromptSection(
          title: 'キャラクター差し替え用',
          content: _processedPrompts!.forModification,
          fieldName: 'modify-positive',
          color: NaiTheme.warning,
          hint: '{{CHAR}} を新しいキャラクター説明に置き換えてください',
        ),
        const SizedBox(height: 16),
        if (widget.negativePrompt != null && widget.negativePrompt!.isNotEmpty)
          _buildPromptSection(
            title: 'Negative Prompt',
            content: widget.negativePrompt!,
            fieldName: 'modify-negative',
            color: NaiTheme.error,
          ),
        const SizedBox(height: 16),
        
        // 分解されたタグ
        _buildDecomposedTags(),
      ],
    );
  }

  Widget _buildStyleTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPromptSection(
          title: 'スタイルタグのみ',
          content: _processedPrompts!.forStyleLock,
          fieldName: 'style',
          color: NaiTheme.accent,
          hint: 'LoRAやスタイルプリセットと組み合わせて使用',
        ),
        const SizedBox(height: 16),
        
        // スタイルタグ一覧
        _buildTagChips(
          'スタイルタグ',
          _processedPrompts!.decomposed.style,
          NaiTheme.accent,
        ),
      ],
    );
  }

  Widget _buildPromptSection({
    required String title,
    required String content,
    required String fieldName,
    required Color color,
    String? hint,
  }) {
    final isCopied = _copiedField == fieldName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: NaiTheme.text1,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: content.isNotEmpty ? () => _copyToClipboard(content, fieldName) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCopied ? NaiTheme.success : NaiTheme.bg3,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCopied ? FluentIcons.check_mark : FluentIcons.copy,
                      size: 12,
                      color: isCopied ? Colors.white : NaiTheme.text1,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isCopied ? 'コピー済み' : 'コピー',
                      style: TextStyle(
                        color: isCopied ? Colors.white : NaiTheme.text1,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(color: NaiTheme.text2, fontSize: 10),
          ),
        ],
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: NaiTheme.bg2,
            borderRadius: BorderRadius.circular(6),
          ),
          constraints: const BoxConstraints(maxHeight: 150),
          child: SingleChildScrollView(
            child: SelectableText(
              content.isEmpty ? '-' : content,
              style: TextStyle(
                color: NaiTheme.text0,
                fontSize: 11,
                height: 1.5,
                fontFamily: 'Consolas, monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecomposedTags() {
    final decomposed = _processedPrompts!.decomposed;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NaiTheme.bg1,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: NaiTheme.bg3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(FluentIcons.view_dashboard, size: 14, color: NaiTheme.text1),
              const SizedBox(width: 6),
              Text(
                '分解されたタグ',
                style: TextStyle(
                  color: NaiTheme.text1,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTagRow('キャラクター', decomposed.character, NaiTheme.success),
          const SizedBox(height: 8),
          _buildTagRow('構図', decomposed.composition, NaiTheme.accentLight),
          const SizedBox(height: 8),
          _buildTagRow('背景', decomposed.background, NaiTheme.warning),
          if (decomposed.misc.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildTagRow('その他', decomposed.misc, NaiTheme.text2),
          ],
        ],
      ),
    );
  }

  Widget _buildTagRow(String label, List<String> tags, Color color) {
    if (tags.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(color: NaiTheme.text2, fontSize: 11),
            ),
          ),
          Text(
            '-',
            style: TextStyle(color: NaiTheme.text2, fontSize: 11),
          ),
        ],
      );
    }

    final fieldName = 'tags-$label';
    final isCopied = _copiedField == fieldName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(color: NaiTheme.text2, fontSize: 11),
          ),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ...tags.take(8).map((tag) => _buildTagChip(tag, color)),
              if (tags.length > 8)
                Text(
                  '+${tags.length - 8}',
                  style: TextStyle(color: NaiTheme.text2, fontSize: 10),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => _copyToClipboard(tags.join(', '), fieldName),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCopied ? NaiTheme.success : NaiTheme.bg3,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              isCopied ? FluentIcons.check_mark : FluentIcons.copy,
              size: 10,
              color: isCopied ? Colors.white : NaiTheme.text2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag, Color color) {
    // 重み構文から基本タグを抽出して表示を短縮
    final displayTag = PromptProcessorService.extractBaseTag(tag);
    final truncated = displayTag.length > 15 
        ? '${displayTag.substring(0, 12)}...' 
        : displayTag;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        truncated,
        style: TextStyle(
          color: color,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildTagChips(String title, List<String> tags, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: NaiTheme.text1,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (tags.isEmpty)
          Text(
            'スタイルタグが検出されませんでした',
            style: TextStyle(color: NaiTheme.text2, fontSize: 11),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) {
              return GestureDetector(
                onTap: () => _copyToClipboard(tag, 'style-tag-$tag'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withAlpha(60)),
                  ),
                  child: Text(
                    PromptProcessorService.extractBaseTag(tag),
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
