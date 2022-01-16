import 'dart:convert';

import 'package:chat_app/preprocessing/tokenizer.dart';
import 'package:flutter/services.dart';

class EmbeddingBuilder {
  static int maxLength = 20;
  static Map<String, List<double>> embedding = {};

  static Future<Map<String, dynamic>> loadJSON(String path) async {
    var jsonString = await rootBundle.loadString(path);
    Map<String, dynamic> jsonObject = json.decode(jsonString);

    return jsonObject;
  }

  static Future<void> embeddingData() async {
    if (EmbeddingBuilder.embedding.isEmpty) {
      Map<String, dynamic> jsonObject =
          await loadJSON('assets/json/BasicLSTM_embedding.json');
      Iterable<String> keys = jsonObject.keys;
      var data = <String, List<double>>{};
      keys.forEach((key) {
        var array = jsonObject[key];
        var embeddingArray = List.filled(array!.length, 0.0);
        for (var x = 0; x < array.length; x++) {
          embeddingArray[x] = array.elementAt(x);
        }
        data[key] = embeddingArray;
      });
      embedding = data;
    }
  }

  static List<List<double>> tokenize(
      String text, Map<String, List<double>> embeddingData, int embeddingDim) {
    var tokens = Tokenizer.getTokens(text);
    List<List<double>> tokenizedMessage = [];
    late List<double> vector;
    for (var part in tokens) {
      if (embeddingData[part] == null) {
        vector = List.filled(embeddingDim, 0.0);
      } else {
        vector = embeddingData[part]!;
      }
      tokenizedMessage.add(vector);
    }

    return tokenizedMessage;
  }

  static List<List<double>> padsequence(
      List<List<double>> sequence, int embeddingDim) {
    if (sequence.length > maxLength) {
      return sequence.sublist(0, maxLength);
    } else if (sequence.length < maxLength) {
      List<List<double>> array = [];
      array.addAll(sequence);
      for (var i = array.length; i < maxLength; i++) {
        array.add(List.filled(embeddingDim, 0.0));
      }

      return array;
    } else {
      return sequence;
    }
  }

  static List<List<double>> preprocess(
      String text, Map<String, List<double>> embeddingData) {
    var tokenizedArray = tokenize(text, embeddingData, 32);
    var paddedArray = padsequence(tokenizedArray, 32);

    return paddedArray;
  }
}
