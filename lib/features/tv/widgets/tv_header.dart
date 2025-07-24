import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';

class TVHeader extends StatelessWidget {
  final String title;
  final Map<String, dynamic> user;
  final VoidCallback? onLogout;
  final VoidCallback? onBack;

  const TVHeader({
    super.key,
    required this.title,
    required this.user,
    this.onLogout,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // Logo y título
          Row(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Avanze',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    TextSpan(
                      text: '360',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6366F1),
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Container(
                height: 20,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),

              const SizedBox(width: 16),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white70,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Usuario y botones
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Bienvenido, ${user['name'].toString().split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user['position'] ?? 'Supervisor de obra',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    user['name']
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              if (onBack != null)
                ElevatedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Volver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              if (onLogout != null) ...[
                if (onBack != null) const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout, size: 16),
                  label: const Text('Salir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}