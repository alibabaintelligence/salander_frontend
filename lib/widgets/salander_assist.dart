import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/gemini_services.dart';

class SalanderAssistChat extends StatefulWidget {
  final Function onClose;
  final String section;

  const SalanderAssistChat({Key? key, required this.onClose, this.section = ''})
      : super(key: key);

  @override
  _SalanderAssistChatState createState() => _SalanderAssistChatState();
}

class _SalanderAssistChatState extends State<SalanderAssistChat> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 8,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildMessageList()),
          if (_isLoading) LinearProgressIndicator(),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 21, 21, 21),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            size: 19.0,
            color: Color.fromARGB(255, 255, 225, 106),
          ),
          SizedBox(width: 14.0),
          Text(
            'Run Analysis',
            style: GoogleFonts.sora(
              color: Color.fromARGB(255, 255, 225, 106),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: Colors.white,
            ),
            onPressed: widget.onClose as void Function()?,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return _messages[index];
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                hintText: "Ask SalanderAssist...",
                iconColor: Colors.white,
                border: InputBorder.none,
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () => _handleSubmitted(_textController.text),
          ),
        ],
      ),
    );
  }

  void _handleSubmitted(String text) async {
    if (text.isEmpty) return;
    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUserMessage: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response =
          await _geminiService.getResponse(text, section: widget.section);
      setState(() {
        _messages.add(ChatMessage(text: response, isUserMessage: false));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error getting response: $e');
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          text: "Sorry, I couldn't process that request. Please try again.",
          isUserMessage: false,
        ));
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUserMessage;

  const ChatMessage({Key? key, required this.text, required this.isUserMessage})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  isUserMessage ? 'You' : 'SalanderAssist',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: EdgeInsets.only(top: 5.0),
                  padding: EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: isUserMessage ? Colors.blue[700] : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      margin: EdgeInsets.only(right: 16.0),
      child: CircleAvatar(
        child: Text(isUserMessage ? 'U' : 'SA'),
        backgroundColor: isUserMessage ? Colors.blue[300] : Colors.grey[600],
      ),
    );
  }
}
