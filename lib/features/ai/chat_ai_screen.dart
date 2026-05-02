import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../transactions/providers/transaction_provider.dart';
import '../transactions/domain/transaction.dart';
import 'ai_provider.dart';
import '../../../core/providers/locale_provider.dart';
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
    final currentLocale = ref.read(localeProvider);
    String localeId = currentLocale.languageCode;
    if (localeId == 'fr') localeId = 'fr_FR';
    if (localeId == 'en') localeId = 'en_US';
    if (localeId == 'ar') localeId = 'ar_SA';

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
          localeId: localeId,
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
        : ''; // Masqué pour GitHub

    final transactions = ref.read(transactionsProvider).value ?? [];
    final balance = ref.read(balanceProvider);
    final income = ref.read(totalIncomeProvider);
    final expense = ref.read(totalExpenseProvider);
    final currentLocale = ref.read(localeProvider);

    String languageName = "français";
    if (currentLocale.languageCode == 'en') languageName = "anglais";
    if (currentLocale.languageCode == 'ar') languageName = "arabe";

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

      final txsSummary = transactions.take(30).map((t) => 
        "${t.date.day}/${t.date.month}: ${t.type == TransactionType.income ? '+' : '-'}${t.amount}€ - ${t.title} [${t.category}]"
      ).join("\n");

      final systemPrompt = "Tu es le coach financier de l'app Stouchy. "
          "SOLDE: ${balance}€ | REVENUS: ${income}€ | DÉPENSES: ${expense}€\n"
          "HISTORIQUE RÉCENT :\n$txsSummary\n\n"
          "Réponds toujours en $languageName, de façon concise (max 60 mots). "
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Assistant IA'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              setState(() {
                _displayMessages.clear();
                _displayMessages.add({
                  'role': 'ai',
                  'text': 'Chat réinitialisé. Comment puis-je vous aider ?'
                });
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _displayMessages.length,
              itemBuilder: (context, index) {
                final m = _displayMessages[index];
                final isUser = m['role'] == 'user';
                return FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: _buildMessageBubble(m['text']!, isUser),
                );
              },
            ),
          ),
          if (_isLoading) 
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: LinearProgressIndicator(backgroundColor: Colors.transparent, minHeight: 2),
            ),
          if (_isListening) _buildVoiceWave(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) 
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.auto_awesome, size: 14, color: Colors.white),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (isUser) 
            Container(
              margin: const EdgeInsets.only(left: 8, bottom: 4),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.person, size: 14, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Row(
          children: [
            _CircleIconButton(
              icon: _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Colors.red : AppColors.primary,
              onPressed: _listen,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 50),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: _isListening ? 'J\'écoute...' : 'Posez une question...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _CircleIconButton(
              icon: Icons.send,
              color: AppColors.primary,
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceWave() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 60),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(15, (index) {
          final height = 3.0 + (math.Random().nextDouble() * 25.0 * (1 + _soundLevel.abs() / 10));
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
