import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/firestore_service.dart';
import '../../widgets/empty_states/empty_state.dart';
import '../../widgets/skeletons/shimmer_box.dart';
import '../../widgets/snackbars/app_snackbar.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _firestore = FirestoreService();
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Utilisateurs'),
      ),
      body: Column(
        children: [
          // Filtres
          _buildFilters(),
          // Liste
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestore.streamUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: List.generate(
                      4,
                      (_) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ShimmerBox(height: 76),
                      ),
                    ),
                  );
                }

                var users = snapshot.data ?? [];

                // Filtrer par rôle
                if (_filter != 'all') {
                  users = users
                      .where((u) => (u['role'] ?? 'client') == _filter)
                      .toList();
                }

                if (users.isEmpty) {
                  return const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Aucun utilisateur',
                    subtitle: 'Aucun utilisateur dans cette catégorie.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, i) => _userCard(users[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    const labels = {
      'all': 'Tous',
      'client': 'Clients',
      'admin': 'Admins',
    };

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: labels.entries.map((e) {
          final selected = e.key == _filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.value),
              selected: selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _filter = e.key),
              backgroundColor: Colors.white,
              selectedColor: AppColors.primary,
              side: BorderSide(
                color: selected
                    ? AppColors.primary
                    : Colors.grey.shade300,
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final id = u['id'] as String;
    final fullName = u['fullName'] as String? ?? 'Utilisateur';
    final phone = u['phone'] as String? ?? '';
    final email = u['email'] as String? ?? '';
    final role = u['role'] as String? ?? 'client';
    final points = u['loyaltyPoints'] as int? ?? 0;
    final isAdmin = role == 'admin';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isAdmin
                  ? AppColors.primary.withOpacity(0.15)
                  : Colors.blue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isAdmin ? AppColors.primary : Colors.blue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAdmin ? 'ADMIN' : 'CLIENT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: isAdmin ? AppColors.primary : Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (phone.isNotEmpty)
                  Text(phone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                if (email.isNotEmpty)
                  Text(email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.card_giftcard,
                        size: 11, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '$points pts',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'toggle_role') {
                _toggleRole(id, role, fullName);
              } else if (value == 'delete') {
                _confirmDelete(id, fullName);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_role',
                child: Row(
                  children: [
                    Icon(
                      isAdmin
                          ? Icons.person_outline
                          : Icons.admin_panel_settings,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(isAdmin
                        ? 'Rétrograder en client'
                        : 'Promouvoir en admin'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Supprimer',
                        style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleRole(String userId, String currentRole, String name) {
    final newRole = currentRole == 'admin' ? 'client' : 'admin';
    final action =
        newRole == 'admin' ? 'Promouvoir' : 'Rétrograder';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('$action $name ?'),
        content: Text(
          newRole == 'admin'
              ? '$name aura accès au back-office.'
              : '$name perdra ses droits administrateur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore.updateUserRole(
                userId: userId,
                role: newRole,
              );
              if (mounted) {
                AppSnackbar.success(context, '$action réussi');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String userId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer ?'),
        content: Text(
          'Voulez-vous supprimer le profil de "$name" ?\n\n'
          'Note : le compte Firebase Auth reste actif.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _firestore.deleteUser(userId);
              if (mounted) {
                AppSnackbar.success(context, 'Utilisateur supprimé');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
