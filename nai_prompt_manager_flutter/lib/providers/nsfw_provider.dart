import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/nsfw_service.dart';

/// NsfwServiceの状態
class NsfwServiceState {
  final NsfwService service;
  final bool initialized;
  final bool ollamaAvailable;
  final List<String> availableModels;
  final String? error;

  // 設定
  final String ollamaUrl;
  final String ollamaModel;
  final bool useOllamaForDetection;
  final double nsfwThreshold;

  const NsfwServiceState({
    required this.service,
    this.initialized = false,
    this.ollamaAvailable = false,
    this.availableModels = const [],
    this.error,
    this.ollamaUrl = 'http://localhost:11434',
    this.ollamaModel = 'llava',
    this.useOllamaForDetection = false,
    this.nsfwThreshold = 0.5,
  });

  NsfwServiceState copyWith({
    NsfwService? service,
    bool? initialized,
    bool? ollamaAvailable,
    List<String>? availableModels,
    String? error,
    String? ollamaUrl,
    String? ollamaModel,
    bool? useOllamaForDetection,
    double? nsfwThreshold,
  }) {
    return NsfwServiceState(
      service: service ?? this.service,
      initialized: initialized ?? this.initialized,
      ollamaAvailable: ollamaAvailable ?? this.ollamaAvailable,
      availableModels: availableModels ?? this.availableModels,
      error: error,
      ollamaUrl: ollamaUrl ?? this.ollamaUrl,
      ollamaModel: ollamaModel ?? this.ollamaModel,
      useOllamaForDetection: useOllamaForDetection ?? this.useOllamaForDetection,
      nsfwThreshold: nsfwThreshold ?? this.nsfwThreshold,
    );
  }
}

/// NsfwServiceのNotifier
class NsfwServiceNotifier extends StateNotifier<NsfwServiceState> {
  NsfwServiceNotifier() : super(NsfwServiceState(service: NsfwService()));

  /// サービスを初期化
  Future<void> initialize() async {
    if (state.initialized) return;

    try {
      await state.service.initialize();
      
      // Ollamaの状態を確認
      final ollamaAvailable = await state.service.checkOllamaAvailability();
      List<String> models = [];
      
      if (ollamaAvailable) {
        models = await state.service.getOllamaModels();
      }

      state = state.copyWith(
        initialized: true,
        ollamaAvailable: ollamaAvailable,
        availableModels: models,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        initialized: true,
        error: e.toString(),
      );
    }
  }

  /// Ollama接続を再チェック
  Future<void> recheckOllama() async {
    try {
      final ollamaAvailable = await state.service.checkOllamaAvailability();
      List<String> models = [];
      
      if (ollamaAvailable) {
        models = await state.service.getOllamaModels();
      }

      state = state.copyWith(
        ollamaAvailable: ollamaAvailable,
        availableModels: models,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        ollamaAvailable: false,
        availableModels: [],
        error: e.toString(),
      );
    }
  }

  /// Ollama URLを設定
  Future<void> setOllamaUrl(String url) async {
    state.service.setOllamaUrl(url);
    state = state.copyWith(ollamaUrl: url);
    await recheckOllama();
  }

  /// Ollamaモデルを設定
  void setOllamaModel(String model) {
    state.service.setOllamaModel(model);
    state = state.copyWith(ollamaModel: model);
  }

  /// Ollama使用設定を変更
  void setUseOllama(bool use) {
    state = state.copyWith(useOllamaForDetection: use);
  }

  /// NSFWしきい値を設定
  void setNsfwThreshold(double threshold) {
    state = state.copyWith(nsfwThreshold: threshold);
  }

  /// プロンプトからNSFW判定
  NsfwResult detectFromPrompt(String? prompt) {
    return state.service.detectFromPrompt(prompt);
  }

  /// 画像からNSFW判定（Ollama使用）
  Future<NsfwResult> detectFromImage(Uint8List imageBytes) async {
    return state.service.detectWithOllama(imageBytes);
  }

  /// 統合NSFW判定
  Future<NsfwResult> detect({
    String? prompt,
    Uint8List? imageBytes,
  }) async {
    return state.service.detect(
      prompt: prompt,
      imageBytes: imageBytes,
      useOllama: state.useOllamaForDetection && state.ollamaAvailable,
    );
  }

  /// NSFWかどうかをしきい値で判定
  bool isNsfwByThreshold(NsfwResult result) {
    return result.score >= state.nsfwThreshold;
  }

  @override
  void dispose() {
    state.service.dispose();
    super.dispose();
  }
}

/// NsfwServiceプロバイダー
final nsfwServiceProvider =
    StateNotifierProvider<NsfwServiceNotifier, NsfwServiceState>((ref) {
  final notifier = NsfwServiceNotifier();
  notifier.initialize();
  return notifier;
});

/// プロンプトNSFW判定のショートカット
final promptNsfwResultProvider = Provider.family<NsfwResult, String?>((ref, prompt) {
  final state = ref.watch(nsfwServiceProvider);
  return state.service.detectFromPrompt(prompt);
});
