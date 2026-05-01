import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../transactions/providers/transaction_provider.dart';
import 'ai_provider.dart';
import '../../../core/theme/app_theme.dart';

class ChatAiScreen extends ConsumerStatefulWidget {
  const ChatAiScreen({super.key});

  @override
  ConsumerState<ChatAiScreen> createState() => _ChatAiScreenState();
}

class _ChatAiScreenState extends ConsumerState<ChatAiScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _displayMessages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _displayMessages.add({
      'role': 'ai',
      'text': 'Bonjour ! Je suis votre coach Stouchy. Je vois vos finances. Une question ?'
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _displayMessages.add({'role': 'user', 'text': text});
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final userKey = ref.read(aiApiKeyProvider);
    final apiKey = (userKey != null && userKey.isNotEmpty)
        ? userKey
        : ''; // REMOVE SECRET FOR GITHUB PUSH

    final balance = ref.read(balanceProvider);
    final income = ref.read(totalIncomeProvider);
    final expense = ref.read(totalExpenseProvider);

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final systemPrompt = "Tu es le coach financier de l'app Stouchy. "
          "Données utilisateur : Solde ${balance}€, Revenus ${income}€, Dépenses ${expense}€. "
          "Réponds toujours en français, de façon concise (max 50 mots).";

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.7,
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['choices'][0]['message']['content'];
        setState(() {
          _displayMessages.add({'role': 'ai', 'text': responseText.trim()});
        });
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Erreur inconnue';
        setState(() {
          _displayMessages.add({
            'role': 'ai',
            'text': 'Erreur ${response.statusCode}: $errorMessage'
          });
        });
      }
    } catch (e) {
      setState(() {
        _displayMessages.add({'role': 'ai', 'text': 'Erreur de connexion : $e'});
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant IA')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _displayMessages.length,
              itemBuilder: (context, index) {
                final m = _displayMessages[index];
                final isUser = m['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                        )
                      ],
                    ),
                    child: Text(
                      m['text']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 32),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Posez une question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}