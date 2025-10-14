import 'dart:convert';

class ReasoningPayload {
  ReasoningPayload({
    required this.reasoning,
    required this.answer,
    required this.thinkClosed,
    this.durationMs,
  });

  final String reasoning;
  final String answer;
  final bool thinkClosed;
  final int? durationMs;

  ReasoningPayload copyWith({
    String? reasoning,
    String? answer,
    bool? thinkClosed,
    int? durationMs,
  }) {
    return ReasoningPayload(
      reasoning: reasoning ?? this.reasoning,
      answer: answer ?? this.answer,
      thinkClosed: thinkClosed ?? this.thinkClosed,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  Map<String, dynamic> toJson() => {
        "reasoning": reasoning,
        "answer": answer,
        "thinkClosed": thinkClosed,
        if (durationMs != null) "durationMs": durationMs,
      };

  static ReasoningPayload fromJson(Map<String, dynamic> json) {
    return ReasoningPayload(
      reasoning: json["reasoning"] as String? ?? "",
      answer: json["answer"] as String? ?? "",
      thinkClosed: json["thinkClosed"] as bool? ?? false,
      durationMs: json["durationMs"] as int?,
    );
  }
}

ReasoningPayload parseRawAssistantText(String rawText) {
  final lower = rawText.toLowerCase();
  final thinkStart = lower.indexOf("<think>");
  if (thinkStart == -1) {
    return ReasoningPayload(
        reasoning: "", answer: rawText.trim(), thinkClosed: false);
  }

  final thinkEnd = lower.indexOf("</think>", thinkStart + 7);
  final before = rawText.substring(0, thinkStart).trim();

  if (thinkEnd == -1) {
    final reasoning = rawText.substring(thinkStart + 7).trim();
    return ReasoningPayload(
      reasoning: reasoning,
      answer: before,
      thinkClosed: false,
    );
  }

  final reasoning = rawText.substring(thinkStart + 7, thinkEnd).trimRight();
  final after = rawText.substring(thinkEnd + 8).trimLeft();
  final combinedAnswer = [before, after]
      .where((element) => element.trim().isNotEmpty)
      .join(before.isNotEmpty && after.isNotEmpty ? "\n\n" : "");
  return ReasoningPayload(
    reasoning: reasoning,
    answer: combinedAnswer.trim(),
    thinkClosed: true,
  );
}

String encodeReasoningComment(ReasoningPayload payload) {
  final encoded = base64.encode(utf8.encode(jsonEncode(payload.toJson())));
  return "<!--reasoning:$encoded-->";
}

ReasoningPayload? decodeReasoningComment(String text) {
  final regex = RegExp(r'<!--reasoning:([A-Za-z0-9+/=]+)-->', dotAll: true);
  final match = regex.firstMatch(text);
  if (match == null) return null;
  try {
    final decoded = utf8.decode(base64.decode(match.group(1)!));
    return ReasoningPayload.fromJson(jsonDecode(decoded));
  } catch (_) {
    return null;
  }
}

String stripReasoningComment(String text) {
  return text.replaceAll(RegExp(r'<!--reasoning:([A-Za-z0-9+/=]+)-->'), "");
}
