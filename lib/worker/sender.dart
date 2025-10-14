import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ollama_app/worker/clients.dart';

import 'haptic.dart';
import 'reasoning.dart';
import 'setter.dart';
import '../main.dart';

import 'package:ollama_app/l10n/gen/app_localizations.dart';

import 'package:ollama_dart/ollama_dart.dart' as llama;
import 'package:dartx/dartx.dart';
import 'package:uuid/uuid.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
// import 'package:scroll_to_index/scroll_to_index.dart';

List<String> images = [];
Future<List<llama.Message>> getHistory([String? addToSystem]) async {
  var system = prefs?.getString("system") ?? "You are a helpful assistant";
  if (prefs!.getBool("noMarkdown") ?? false) {
    system +=
        "\nYou must not use markdown or any other formatting language in any way!";
  }
  if (addToSystem != null) {
    system += "\n$addToSystem";
  }

  List<llama.Message> history = (prefs!.getBool("useSystem") ?? true)
      ? [llama.Message(role: llama.MessageRole.system, content: system)]
      : [];
  List<llama.Message> history2 = [];
  images = [];
  for (var i = 0; i < messages.length; i++) {
    if (jsonDecode(jsonEncode(messages[i]))["text"] != null) {
      history2.add(llama.Message(
          role: (messages[i].author.id == user.id)
              ? llama.MessageRole.user
              : llama.MessageRole.system,
          content: stripReasoningComment(
              jsonDecode(jsonEncode(messages[i]))["text"] as String),
          images: (images.isNotEmpty) ? images : null));
      images = [];
    } else {
      var uri = jsonDecode(jsonEncode(messages[i]))["uri"] as String;
      String content = (uri.startsWith("data:image/png;base64,"))
          ? uri.removePrefix("data:image/png;base64,")
          : base64.encode(await File(uri).readAsBytes());
      uri = uri.removePrefix("data:image/png;base64,");
      images.add(content);
    }
  }

  history.addAll(history2.reversed.toList());
  return history;
}

List getHistoryString([String? uuid]) {
  uuid ??= chatUuid!;
  List messages = [];
  for (var i = 0; i < (prefs!.getStringList("chats") ?? []).length; i++) {
    if (jsonDecode((prefs!.getStringList("chats") ?? [])[i])["uuid"] == uuid) {
      messages = jsonDecode(
          jsonDecode((prefs!.getStringList("chats") ?? [])[i])["messages"]);
      break;
    }
  }

  if (messages[0]["role"] == "system") {
    messages.removeAt(0);
  }
  for (var i = 0; i < messages.length; i++) {
    if (messages[i]["type"] == "image") {
      messages[i] = {
        "role": messages[i]["role"]!,
        "content": "<${messages[i]["role"]} inserted an image>"
      };
    } else if ((messages[i] as Map).containsKey("content")) {
      messages[i]["content"] =
          stripReasoningComment(messages[i]["content"] as String);
    }
  }

  return messages;
}

Future<String> getTitleAi(List history) async {
  final generated = await ollamaClient
      .generateChatCompletion(
        request: llama.GenerateChatCompletionRequest(
            model: model!,
            messages: [
              const llama.Message(
                  role: llama.MessageRole.system,
                  content:
                      "Generate a three to six word title for the conversation provided by the user. If an object or person is very important in the conversation, put it in the title as well; keep the focus on the main subject. You must not put the assistant in the focus and you must not put the word 'assistant' in the title! Do preferably use title case. Use a formal tone, don't use dramatic words, like 'mystery' Use spaces between words, do not use camel case! You must not use markdown or any other formatting language! You must not use emojis or any other symbols! You must not use general clauses like 'assistance', 'help' or 'session' in your title! \n\n~~User Introduces Themselves~~ -> User Introduction\n~~User Asks for Help with a Problem~~ -> Problem Help\n~~User has a _**big**_ Problem~~ -> Big Problem"),
              llama.Message(
                  role: llama.MessageRole.user,
                  content: "```\n${jsonEncode(history)}\n```")
            ],
            keepAlive: int.parse(prefs!.getString("keepAlive") ?? "300")),
      )
      .timeout(Duration(
          seconds:
              (10.0 * (prefs!.getDouble("timeoutMultiplier") ?? 1.0)).round()));
  var title = generated.message.content;
  title = title.replaceAll("\n", " ");

  var terms = [
    "\"",
    "'",
    "*",
    "_",
    ".",
    ",",
    "!",
    "?",
    ":",
    ";",
    "(",
    ")",
    "[",
    "]",
    "{",
    "}"
  ];
  for (var i = 0; i < terms.length; i++) {
    title = title.replaceAll(terms[i], "");
  }

  title = title.replaceAll(RegExp(r'<.*?>', dotAll: true), "");
  if (title.split(":").length == 2) {
    title = title.split(":")[1];
  }

  while (title.contains("  ")) {
    title = title.replaceAll("  ", " ");
  }
  return title.trim();
}

Future<void> setTitleAi(List history) async {
  try {
    var title = await getTitleAi(history);
    var tmp = (prefs!.getStringList("chats") ?? []);
    for (var i = 0; i < tmp.length; i++) {
      if (jsonDecode((prefs!.getStringList("chats") ?? [])[i])["uuid"] ==
          chatUuid) {
        var tmp2 = jsonDecode(tmp[i]);
        tmp2["title"] = title;
        tmp[i] = jsonEncode(tmp2);
        break;
      }
    }
    prefs!.setStringList("chats", tmp);
  } catch (_) {}
}

Future<String> send(String value, BuildContext context, Function setState,
    {void Function(String currentText, bool done)? onStream,
    String? addToSystem}) async {
  selectionHaptic();
  setState(() {
    sendable = false;
  });

  if (host == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.noHostSelected),
        showCloseIcon: true));
    if (onStream != null) {
      onStream("", true);
    }
    return "";
  }

  if (!chatAllowed || model == null) {
    if (model == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.noModelSelected),
          showCloseIcon: true));
    }
    if (onStream != null) {
      onStream("", true);
    }
    return "";
  }

  bool newChat = false;
  if (chatUuid == null) {
    newChat = true;
    chatUuid = const Uuid().v4();
    prefs!.setStringList(
        "chats",
        (prefs!.getStringList("chats") ?? []).append([
          jsonEncode({
            "title": AppLocalizations.of(context)!.newChatTitle,
            "uuid": chatUuid,
            "messages": []
          })
        ]).toList());
  }

  var history = await getHistory(addToSystem);

  history.add(llama.Message(
      role: llama.MessageRole.user,
      content: value.trim(),
      images: (images.isNotEmpty) ? images : null));
  messages.insert(
      0,
      types.TextMessage(
          author: user, id: const Uuid().v4(), text: value.trim()));

  saveChat(chatUuid!, setState);

  setState(() {});
  chatAllowed = false;

  String text = "";
  String newId = const Uuid().v4();
  final DateTime requestStartedAt = DateTime.now();
  DateTime? reasoningStart;
  DateTime? reasoningEnd;
  String reasoningBuffer = "";

  try {
    if ((prefs!.getString("requestType") ?? "stream") == "stream") {
      final stream = ollamaClient
          .generateChatCompletionStream(
            request: llama.GenerateChatCompletionRequest(
                model: model!,
                messages: history,
                keepAlive: int.parse(prefs!.getString("keepAlive") ?? "300")),
          )
          .timeout(Duration(
              seconds: (30.0 * (prefs!.getDouble("timeoutMultiplier") ?? 1.0))
                  .round()));

      await for (final res in stream) {
        text += (res.message.content);
        final thinkingChunk = res.message.thinking;
        if (thinkingChunk != null && thinkingChunk.isNotEmpty) {
          reasoningBuffer += thinkingChunk;
          reasoningStart ??= DateTime.now();
        }
        final payload = parseRawAssistantText(text);
        final combinedReasoning = payload.reasoning.isNotEmpty
            ? payload.reasoning
            : reasoningBuffer.trimRight();
        String combinedAnswer =
            (payload.answer.isNotEmpty ? payload.answer : text);
        final hasReasoning = combinedReasoning.isNotEmpty;
        final thinkClosed =
            payload.reasoning.isNotEmpty ? payload.thinkClosed : res.done;
        if (hasReasoning && thinkClosed && reasoningEnd == null) {
          reasoningEnd = DateTime.now();
        }
        int? durationMs;
        final start = reasoningStart;
        final end = reasoningEnd;
        if (start != null && end != null) {
          durationMs = end.difference(start).inMilliseconds;
        }
        String messageContent = combinedAnswer;
        if (hasReasoning) {
          final updatedPayload = ReasoningPayload(
            reasoning: combinedReasoning,
            answer: combinedAnswer,
            thinkClosed: thinkClosed,
            durationMs: durationMs,
          );
          messageContent =
              "${updatedPayload.answer}${encodeReasoningComment(updatedPayload)}";
        }
        for (var i = 0; i < messages.length; i++) {
          if (messages[i].id == newId) {
            messages.removeAt(i);
            break;
          }
        }
        if (chatAllowed) return "";
        messages.insert(
            0,
            types.TextMessage(
                author: assistant, id: newId, text: messageContent));
        //TODO: add functionality
        //
        // chatKey!.currentState!.scrollToMessage(messages[1].id,
        //     preferPosition: AutoScrollPosition.end);
        if (onStream != null) {
          onStream(combinedAnswer, false);
        }
        setState(() {});
        heavyHaptic();
      }
      final payload = parseRawAssistantText(text);
      final combinedReasoning = payload.reasoning.isNotEmpty
          ? payload.reasoning
          : reasoningBuffer.trimRight();
      String combinedAnswer = payload.answer.isNotEmpty ? payload.answer : text;
      final hasReasoning = combinedReasoning.isNotEmpty;
      if (hasReasoning) {
        reasoningStart ??= requestStartedAt;
        reasoningEnd ??= DateTime.now();
      }
      int? durationMs;
      final start = reasoningStart;
      final end = reasoningEnd;
      if (start != null && end != null) {
        durationMs = end.difference(start).inMilliseconds;
      }
      final thinkClosed =
          payload.reasoning.isNotEmpty ? payload.thinkClosed : true;
      String finalMessageText = combinedAnswer;
      if (hasReasoning) {
        final finalPayload = ReasoningPayload(
          reasoning: combinedReasoning,
          answer: combinedAnswer,
          thinkClosed: thinkClosed,
          durationMs: durationMs,
        );
        finalMessageText =
            "${finalPayload.answer}${encodeReasoningComment(finalPayload)}";
        text = finalPayload.answer;
      } else {
        text = combinedAnswer;
      }
      for (var i = 0; i < messages.length; i++) {
        if (messages[i].id == newId) {
          messages[i] = types.TextMessage(
              author: assistant, id: newId, text: finalMessageText);
          break;
        }
      }
      setState(() {});
    } else {
      llama.GenerateChatCompletionResponse request;
      final DateTime nonStreamStart = DateTime.now();
      request = await ollamaClient
          .generateChatCompletion(
            request: llama.GenerateChatCompletionRequest(
                model: model!,
                messages: history,
                keepAlive: int.parse(prefs!.getString("keepAlive") ?? "300")),
          )
          .timeout(Duration(
              seconds: (30.0 * (prefs!.getDouble("timeoutMultiplier") ?? 1.0))
                  .round()));
      if (chatAllowed) return "";
      final payload = parseRawAssistantText(request.message.content);
      final thinking = request.message.thinking?.trim() ?? "";
      final combinedReasoning =
          payload.reasoning.isNotEmpty ? payload.reasoning : thinking;
      String assistantMessage =
          payload.answer.isNotEmpty ? payload.answer : request.message.content;
      if (combinedReasoning.isNotEmpty) {
        final durationMs =
            DateTime.now().difference(nonStreamStart).inMilliseconds;
        final finalPayload = ReasoningPayload(
          reasoning: combinedReasoning,
          answer: assistantMessage,
          thinkClosed:
              payload.reasoning.isNotEmpty ? payload.thinkClosed : true,
          durationMs: durationMs,
        );
        assistantMessage =
            "${finalPayload.answer}${encodeReasoningComment(finalPayload)}";
        text = finalPayload.answer;
      } else {
        text = assistantMessage;
      }
      messages.insert(
          0,
          types.TextMessage(
              author: assistant, id: newId, text: assistantMessage));
      setState(() {});
      heavyHaptic();
    }
  } catch (e) {
    for (var i = 0; i < messages.length; i++) {
      if (messages[i].id == newId) {
        messages.removeAt(i);
        break;
      }
    }
    setState(() {
      chatAllowed = true;
      messages.removeAt(0);
      if (messages.isEmpty) {
        var tmp = (prefs!.getStringList("chats") ?? []);
        for (var i = 0; i < tmp.length; i++) {
          if (jsonDecode((prefs!.getStringList("chats") ?? [])[i])["uuid"] ==
              chatUuid) {
            tmp.removeAt(i);
            prefs!.setStringList("chats", tmp);
            break;
          }
        }
        chatUuid = null;
      }
    });
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            // ignore: use_build_context_synchronously
            Text(AppLocalizations.of(context)!.settingsHostInvalid("timeout")),
        showCloseIcon: true));
    return "";
  }
  //TODO: add functionality
  //
  // chatKey!.currentState!
  //     .scrollToMessage(messages[1].id, preferPosition: AutoScrollPosition.end);
  if ((prefs!.getString("requestType") ?? "stream") == "stream") {
    if (onStream != null) {
      onStream(text, true);
    }
  }
  saveChat(chatUuid!, setState);

  if (newChat && (prefs!.getBool("generateTitles") ?? true)) {
    void setTitle() async {
      await setTitleAi(getHistoryString());
      setState(() {});
    }

    setTitle();
  }

  setState(() {});
  chatAllowed = true;
  return text;
}
