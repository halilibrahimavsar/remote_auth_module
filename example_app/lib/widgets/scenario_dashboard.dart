import 'package:flutter/material.dart';

class ScenarioDashboard extends StatelessWidget {
  final Function(int) onSelect;

  const ScenarioDashboard({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Integration Paths',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select a case below to see how to implement the module in your app.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ScenarioCard(
            title: 'RemoteAuthFlow (Easy)',
            description:
                'Zero-boilerplate. Handles all auth sub-pages automatically.',
            icon: Icons.auto_fix_high,
            color: Colors.blue,
            onTap: () => onSelect(0),
          ),
          const SizedBox(height: 16),
          ScenarioCard(
            title: 'Manual Integration',
            description: 'Full control. Use BLoC logic with custom UI layouts.',
            icon: Icons.settings_input_component,
            color: Colors.orange,
            onTap: () => onSelect(1),
          ),
          const SizedBox(height: 16),
          ScenarioCard(
            title: 'DI & Repository Config',
            description:
                'Learn how to configure Firestore sync and custom parameters.',
            icon: Icons.extension,
            color: Colors.purple,
            onTap: () => onSelect(2),
          ),
          const SizedBox(height: 32),
          Text(
            'UI Templates',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ScenarioCard(
            title: '🌌 Aurora Template',
            description: 'Dark, ethereal design with animated mesh gradients.',
            icon: Icons.auto_awesome,
            color: const Color(0xFF00E5CC),
            onTap: () => onSelect(3),
          ),
          const SizedBox(height: 16),
          ScenarioCard(
            title: '🌊 Wave Template',
            description: 'Clean Material 3 design with liquid wave header.',
            icon: Icons.water,
            color: const Color(0xFF1A237E),
            onTap: () => onSelect(4),
          ),
          const SizedBox(height: 16),
          ScenarioCard(
            title: '⚡ Neon Template',
            description: 'Cyberpunk aesthetic with pulsing neon glow.',
            icon: Icons.bolt,
            color: const Color(0xFF00D4FF),
            onTap: () => onSelect(5),
          ),
          const SizedBox(height: 16),
          ScenarioCard(
            title: '✨ Nova Template',
            description:
                'Elegant space theme with a rotating starry background.',
            icon: Icons.nights_stay,
            color: const Color(0xFFF8B500),
            onTap: () => onSelect(6),
          ),
          const SizedBox(height: 16),
          ScenarioCard(
            title: '💎 Prisma Template',
            description: 'Modern glassmorphism with morphing geometric shapes.',
            icon: Icons.view_in_ar,
            color: const Color(0xFFFF2A5F),
            onTap: () => onSelect(7),
          ),
        ],
      ),
    );
  }
}

class ScenarioCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const ScenarioCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withAlpha(50)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
