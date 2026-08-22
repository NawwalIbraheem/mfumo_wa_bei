import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: const [
        Text(
          'Msaada',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 16),
        _HelpSection(
          question: 'Ninawezaje kutafuta soko?',
          answer:
              'Fungua Masoko, kisha tumia kisanduku cha kutafuta kwa jina la soko au eneo.',
        ),
        _HelpSection(
          question: 'Bei zinawakilisha nini?',
          answer:
              'Bei zinaonyesha makadirio ya bei kwa kilo kwa mchele na maharage kwenye masoko ya Morogoro.',
        ),
        _HelpSection(
          question: 'Ninaripotije bei mpya?',
          answer:
              'Kwenye Nyumbani bonyeza Ripoti Bei, chagua zao, weka bei na jina la soko.',
        ),
        _HelpSection(
          question: 'Kwa nini sioni Admin?',
          answer:
              'Admin huonekana tu kwa akaunti yenye ruhusa za watumiaji, roles au permissions.',
        ),
        SizedBox(height: 14),
        _ContactTile(),
      ],
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: const Color(0xFFE8F5E9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: const Icon(Icons.support_agent, color: Color(0xFF0E7A3B)),
      title: const Text(
        'Unahitaji msaada zaidi?',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: const Text('Wasiliana na msimamizi wa Mfumo wa Bei.'),
    );
  }
}
