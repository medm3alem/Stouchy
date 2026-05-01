import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../transactions/providers/transaction_provider.dart';
import '../transactions/domain/transaction.dart';
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
  
  // Voice variables
  late stt.SpeechToText _speech;
  bool _isListening = false;
  double _soundLevel = 0.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
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

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (val) => setState(() => _isListening = false),
      );
      if (available) {
        setState(() {
          _isListening = true;
          _soundLevel = 0.0;
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _messageController.text = val.recognizedWords;
          }),
          onSoundLevelChange: (level) {
            setState(() => _soundLevel = level);
          },
        );
      }
    } else {
      _stopListening();
      if (_messageController.text.isNotEmpty) {
        _sendMessage();
      }
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _soundLevel = 0.0;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_isListening) _stopListening();

    setState(() {
      _displayMessages.add({'role': 'user', 'text': text});
      _messageController.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final userKey = ref.read(aiApiKeyProvider);
    final apiKey = (userKey != null && userKey.isNotEmpty)
        ? userKey
        : ''; // Clé masquée pour GitHub

    final transactions = ref.read(transactionsProvider).value ?? [];
    final balance = ref.read(balanceProvider);
    final income = ref.read(totalIncomeProvider);
    final expense = ref.read(totalExpenseProvider);

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final txsSummary = transactions.take(30).map((t) => 
        "${t.date.day}/${t.date.month}: ${t.type == TransactionType.income ? '+' : '-'}${t.amount}€ - ${t.title} [${t.category}]"
      ).join("\n");

      final systemPrompt = "Tu es le coach financier de l'app Stouchy. "
          "SOLDE: ${balance}€ | REVENUS: ${income}€ | DÉPENSES: ${expense}€\n"
          "HISTORIQUE RÉCENT :\n$txsSummary\n\n"
          "Réponds toujours en français, de façon concise (max 60 mots). "
          "Utilise les noms des transactions pour tes analyses.";

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
          if (_isListening) _buildVoiceWave(),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 32),
            child: Row(
              children: [
                FloatingActionButton.small(
                  heroTag: 'mic',
                  onPressed: _listen,
                  backgroundColor: _isListening ? Colors.red : AppColors.primary,
                  child: Icon(_isListening ? Icons.mic : Icons.mic_none, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _isListening ? 'J\'écoute...' : 'Posez une question...',
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
                  heroTag: 'send',
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

  Widget _buildVoiceWave() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(15, (index) {
          // Animation simple basée sur soundLevel
          final height = 5.0 + (math.Random().nextDouble() * 20.0 * (1 + _soundLevel.abs() / 10));
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }
}
