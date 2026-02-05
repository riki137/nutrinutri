import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nutrinutri/core/services/google_user_info.dart';

class SyncSection extends StatelessWidget {
  const SyncSection({
    super.key,
    required this.currentUser,
    required this.isSyncing,
    required this.onSignIn,
    required this.onSignOut,
    required this.onSync,
    this.webSignInButton,
  });
  final GoogleUserInfo? currentUser;
  final bool isSyncing;
  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final VoidCallback onSync;
  final Widget? webSignInButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data Synchronization',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        const Text(
          'Sync your diary with Google Drive.',
          style: TextStyle(color: Colors.grey),
        ),
        const Gap(16),
        if (currentUser == null)
          if (webSignInButton != null)
            Center(child: webSignInButton!)
          else
            FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.grey),
              ),
            )
        else ...[
          ListTile(
            leading: CircleAvatar(
              backgroundImage: currentUser!.photoUrl != null
                  ? NetworkImage(currentUser!.photoUrl!)
                  : null,
              child: currentUser!.photoUrl == null
                  ? const Icon(Icons.account_circle)
                  : null,
            ),
            title: Text(currentUser!.name ?? currentUser!.email),
            subtitle: currentUser!.name != null
                ? Text(currentUser!.email)
                : const Text('Connected to Google Drive'),
            trailing: IconButton(
              icon: const Icon(Icons.logout),
              onPressed: onSignOut,
            ),
          ),
          const Gap(8),
          FilledButton.icon(
            onPressed: isSyncing ? null : onSync,
            icon: isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
          ),
        ],
      ],
    );
  }
}
