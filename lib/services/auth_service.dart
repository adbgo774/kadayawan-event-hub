import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class AuthService {
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    final session = response.session;

    if (user != null && session != null) {
      await _upsertProfile(user, email: user.email);
    }

    return response;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user != null) {
      await _upsertProfile(user, email: user.email);
    }

    return response;
  }

  Future<AuthResponse> signInAsGuest() async {
    final response = await supabase.auth.signInAnonymously();

    final user = response.user;
    if (user != null) {
      await _upsertProfile(
        user,
        email: user.email ?? 'guest@local.dev',
      );
    }

    return response;
  }

  Future<void> signInWithGoogle() async {
    const webClientId =
        '855492609406-saak1uv5abrmc1jbauka8kvbp0rftmpd.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );

    try {
      await googleSignIn.disconnect();
    } catch (_) {}

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final String? idToken = googleAuth.idToken;
    final String? accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw 'Google sign-in failed. No ID token found.';
    }

    final AuthResponse response = await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final user = response.user;
    if (user != null) {
      await _upsertProfile(user, email: user.email);
    }
  }

  Future<void> signOut() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();

    try {
      await googleSignIn.disconnect();
    } catch (_) {}

    await supabase.auth.signOut();
  }

  Future<void> _upsertProfile(
    User user, {
    String? email,
  }) async {
    await supabase.from('profiles').upsert({
      'id': user.id,
      'email': email ?? '',
      'role': 'viewer',
    });
  }
}