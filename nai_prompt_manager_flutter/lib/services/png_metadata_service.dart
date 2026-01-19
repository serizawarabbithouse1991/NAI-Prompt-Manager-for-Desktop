import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

import '../data/models/models.dart';

/// PNG Metadata Extractor for NovelAI images
/// Parses tEXt and iTXt chunks from PNG files to extract generation parameters
class PngMetadataService {
  // PNG signature bytes
  static const List<int> _pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

  /// Check if buffer is a valid PNG file
  static bool isPng(Uint8List buffer) {
    if (buffer.length < 8) return false;
    for (var i = 0; i < 8; i++) {
      if (buffer[i] != _pngSignature[i]) return false;
    }
    return true;
  }

  /// Read a 4-byte big-endian unsigned integer
  static int _readUInt32BE(Uint8List buffer, int offset) {
    return (buffer[offset] << 24) |
        (buffer[offset + 1] << 16) |
        (buffer[offset + 2] << 8) |
        buffer[offset + 3];
  }

  /// Extract text chunks (tEXt and iTXt) from PNG buffer
  static Map<String, String> extractPngTextChunks(Uint8List buffer) {
    final textData = <String, String>{};

    if (!isPng(buffer)) {
      return textData;
    }

    var offset = 8; // Skip PNG signature
    final latin1Decoder = const Latin1Decoder();
    final utf8Decoder = const Utf8Decoder(allowMalformed: true);

    while (offset < buffer.length - 12) {
      final length = _readUInt32BE(buffer, offset);
      final chunkTypeBytes = buffer.sublist(offset + 4, offset + 8);
      final chunkType = latin1Decoder.convert(chunkTypeBytes);

      if (chunkType == 'tEXt') {
        // tEXt chunk format: keyword\0text
        final chunkData = buffer.sublist(offset + 8, offset + 8 + length);
        final nullIndex = chunkData.indexOf(0);

        if (nullIndex > 0) {
          final keyword = latin1Decoder.convert(chunkData.sublist(0, nullIndex));
          final text = latin1Decoder.convert(chunkData.sublist(nullIndex + 1));
          textData[keyword] = text;
        }
      } else if (chunkType == 'iTXt') {
        // iTXt chunk format: keyword\0compression_flag\0compression_method\0language_tag\0translated_keyword\0text
        final chunkData = buffer.sublist(offset + 8, offset + 8 + length);
        final nullIndex = chunkData.indexOf(0);

        if (nullIndex > 0) {
          final keyword = utf8Decoder.convert(chunkData.sublist(0, nullIndex));
          final compressionFlag = chunkData[nullIndex + 1];

          if (compressionFlag == 0) {
            // Uncompressed
            var textStart = nullIndex + 3; // Skip null, compression flag, compression method

            // Skip language tag (null-terminated)
            while (textStart < chunkData.length && chunkData[textStart] != 0) {
              textStart++;
            }
            textStart++; // Skip null

            // Skip translated keyword (null-terminated)
            while (textStart < chunkData.length && chunkData[textStart] != 0) {
              textStart++;
            }
            textStart++; // Skip null

            if (textStart < chunkData.length) {
              final text = utf8Decoder.convert(chunkData.sublist(textStart));
              textData[keyword] = text;
            }
          }
        }
      } else if (chunkType == 'IEND') {
        break;
      }

      // Move to next chunk (length + type + data + CRC)
      offset += 12 + length;
    }

    return textData;
  }

  /// Parse NovelAI Comment JSON
  static Map<String, dynamic>? _parseNovelAIComment(String commentStr) {
    try {
      return jsonDecode(commentStr) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Extract model name from Source string
  /// Example: "Stable Diffusion XL C1E1DE52" -> "Stable Diffusion XL"
  static String _extractModelName(String source) {
    // NovelAI format: "Stable Diffusion XL C1E1DE52" or similar
    // Remove the hash at the end if present
    final match = RegExp(r'^(.+?)\s+[A-F0-9]{8}$', caseSensitive: false).firstMatch(source);
    return match?.group(1) ?? source;
  }

  /// Extract NovelAI metadata from PNG buffer
  static NovelAIMetadata? extractNovelAIMetadata(Uint8List buffer) {
    final textChunks = extractPngTextChunks(buffer);

    if (textChunks.isEmpty) {
      return null;
    }

    Map<String, dynamic>? comment;
    if (textChunks.containsKey('Comment')) {
      comment = _parseNovelAIComment(textChunks['Comment']!);
    }

    return NovelAIMetadata(
      title: textChunks['Title'],
      description: textChunks['Description'],
      source: textChunks['Source'],
      software: textChunks['Software'],
      comment: comment,
      rawMetadata: textChunks,
    );
  }

  /// Convert extracted metadata to prompt data format for database
  static ParsedPromptData? convertToPromptData(NovelAIMetadata metadata) {
    final comment = metadata.comment;

    // Positive prompt: Description field contains the main prompt
    String? positivePrompt = metadata.description;

    // If Comment has a prompt field, prefer that (more accurate)
    if (comment != null && comment['prompt'] != null) {
      positivePrompt = comment['prompt'] as String;
    }

    // Negative prompt: can be in 'uc' or 'uncond' field of Comment
    String? negativePrompt;
    if (comment != null) {
      negativePrompt = comment['uc'] as String? ?? comment['uncond'] as String?;
    }

    // Model from Source field
    final model = metadata.source != null ? _extractModelName(metadata.source!) : null;

    // Other parameters from Comment
    final sampler = comment?['sampler'] as String?;
    final steps = comment?['steps'] as int?;
    final cfgScale = (comment?['scale'] as num?)?.toDouble();
    final seed = comment?['seed'] as int?;
    final width = comment?['width'] as int?;
    final height = comment?['height'] as int?;
    final noiseSchedule = comment?['noise_schedule'] as String?;

    // Convert raw metadata to string map
    final rawMetadata = metadata.rawMetadata.map(
      (key, value) => MapEntry(key, value.toString()),
    );

    return ParsedPromptData(
      positivePrompt: positivePrompt,
      negativePrompt: negativePrompt,
      model: model,
      sampler: sampler,
      steps: steps,
      cfgScale: cfgScale,
      seed: seed,
      width: width,
      height: height,
      noiseSchedule: noiseSchedule,
      rawMetadata: rawMetadata,
      sourceType: AISourceType.novelai,
    );
  }

  /// Extract and convert PNG metadata in one step
  static ParsedPromptData? extractPromptDataFromPng(Uint8List buffer) {
    final metadata = extractNovelAIMetadata(buffer);
    if (metadata == null) {
      return null;
    }
    return convertToPromptData(metadata);
  }

  /// Detect AI source type from metadata
  static AISourceType detectSourceType(Map<String, String> metadata) {
    // NovelAI detection
    if (metadata.containsKey('Software') && 
        metadata['Software']!.toLowerCase().contains('novelai')) {
      return AISourceType.novelai;
    }
    if (metadata.containsKey('Source') && 
        metadata['Source']!.contains('Stable Diffusion')) {
      return AISourceType.novelai;
    }
    if (metadata.containsKey('Comment')) {
      try {
        final comment = jsonDecode(metadata['Comment']!);
        if (comment is Map && comment.containsKey('noise_schedule')) {
          return AISourceType.novelai;
        }
      } catch (_) {}
    }

    // A1111 detection
    if (metadata.containsKey('parameters')) {
      return AISourceType.a1111;
    }

    // ComfyUI detection
    if (metadata.containsKey('prompt') && metadata.containsKey('workflow')) {
      return AISourceType.comfyui;
    }

    return AISourceType.unknown;
  }

  /// Calculate file hash (SHA-256) for duplicate detection
  static String calculateFileHash(Uint8List buffer) {
    final digest = sha256.convert(buffer);
    return digest.toString();
  }

  /// Get image dimensions from PNG header
  static ({int width, int height})? getImageDimensions(Uint8List buffer) {
    if (!isPng(buffer) || buffer.length < 24) {
      return null;
    }

    // IHDR chunk should be immediately after signature
    // Check chunk type is IHDR
    final chunkType = String.fromCharCodes(buffer.sublist(12, 16));
    if (chunkType != 'IHDR') {
      return null;
    }

    final width = _readUInt32BE(buffer, 16);
    final height = _readUInt32BE(buffer, 20);

    return (width: width, height: height);
  }
}

/// NovelAI metadata structure
class NovelAIMetadata {
  final String? title;
  final String? description;
  final String? source;
  final String? software;
  final Map<String, dynamic>? comment;
  final Map<String, String> rawMetadata;

  const NovelAIMetadata({
    this.title,
    this.description,
    this.source,
    this.software,
    this.comment,
    required this.rawMetadata,
  });
}
