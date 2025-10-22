// services/tao_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/tao_data.dart';

class TaoService {
  static Future<List<TaoData>> loadLocalTaoData() async {
    try {
      print('🔄 [CODEMAGIC DEBUG] Loading local Tao data from JSON...');

      final String data = await rootBundle.loadString('lib/data/tao_data.json');
      print('✅ [CODEMAGIC DEBUG] JSON file loaded, length: ${data.length} chars');

      // Check if prompts exist in the raw JSON
      print('🔍 [CODEMAGIC DEBUG] Checking for prompts in JSON:');
      print('   "Prompt 1" found: ${data.contains("Prompt 1")}');
      print('   "Prompt 2" found: ${data.contains("Prompt 2")}');

      final List<dynamic> jsonList = jsonDecode(data);
      print('📊 [CODEMAGIC DEBUG] Total Tao entries: ${jsonList.length}');

      // Check first 3 entries for prompts
      final checkCount = jsonList.length < 3 ? jsonList.length : 3;
      for (int i = 0; i < checkCount; i++) {
        final json = jsonList[i];
        final hasPrompt1 = (json['Prompt 1']?.toString() ?? '').isNotEmpty;
        final hasPrompt2 = (json['Prompt 2']?.toString() ?? '').isNotEmpty;
        print('🎯 [CODEMAGIC DEBUG] Tao ${json['number']}: Prompt1=$hasPrompt1, Prompt2=$hasPrompt2');
      }

      final List<TaoData> taoDataList = [];

      for (final json in jsonList) {
        try {
          final taoData = TaoData.fromJson(json);
          if (taoData.number > 0) {
            taoDataList.add(taoData);
          }
        } catch (e) {
          print('❌ Error parsing Tao entry: $e');
        }
      }

      taoDataList.sort((a, b) => a.number.compareTo(b.number));
      print('✅ Successfully loaded ${taoDataList.length} Tao entries from local JSON');

      return taoDataList;
    } catch (e) {
      print('❌ [CODEMAGIC DEBUG] Error loading Tao data: $e');
      throw Exception('Failed to load Tao data');
    }
  }

  static List<TaoData> getFallbackData() {
    print('🔄 Using comprehensive fallback data');

    final List<TaoData> fallbackData = [];

    for (int i = 1; i <= 81; i++) {
      fallbackData.add(TaoData(
        number: i,
        title: 'Tao Chapter $i',
        text: _getFallbackTaoText(i),
        notes: 'Sample notes for Tao $i. This is fallback data while we resolve connection issues.',
        audio1: '',
        audio2: '',
        audio3: '',
        prompt1: '', // Add empty prompts for fallback
        prompt2: '', // Add empty prompts for fallback
      ));
    }

    return fallbackData;
  }

  static String _getFallbackTaoText(int chapter) {
    final samples = {
      1: 'The Tao that can be told is not the eternal Tao. The name that can be named is not the eternal name.',
      2: 'When people see some things as beautiful, other things become ugly. When people see some things as good, other things become bad.',
      81: 'True words aren\'t eloquent; eloquent words aren\'t true. Wise men don\'t need to prove their point; men who need to prove their point aren\'t wise.',
    };

    return samples[chapter] ?? 'The Tao Te Ching teaches us about the natural way of the universe. Chapter $chapter offers wisdom about harmony and balance.';
  }
}