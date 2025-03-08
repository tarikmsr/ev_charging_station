import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ev_charging_app/core/services/firestore_service.dart';
import 'package:ev_charging_app/core/services/local_storage_service.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorage;

  AuthService(this._firestoreService, this._localStorage);

  static Future<AuthService> init() async {
    final localStorage = await LocalStorageService.init();
    return AuthService(FirestoreService(), localStorage);
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {

    final userId = currentUser?.uid ?? _auth.currentUser?.uid;
    if(userId == null) throw 'User not authenticated - cannot get user data';

    return await _firestoreService.getUserData(userId);
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    await _firestoreService.updateUserData(data);
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmailAndPassword(String email, String password, String? firstName, String? lastName) async {
    try {
      print('Starting email sign up...');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('User created successfully, initializing user data...');
      // Initialize user data in Firestore
      if (userCredential.user != null) {
        await _firestoreService.initializeUserData(
          userId: userCredential.user!.uid,
          email: email,
          firstName: firstName,
          lastName: lastName,
        );

        print('User data initialized, creating demo stations...');

      }

      // Save auth data locally
      final token = await userCredential.user?.getIdToken();
      await _localStorage.saveAuthData(
        token: token,
        userId: userCredential.user?.uid,
        email: userCredential.user?.email,
      );

      return userCredential;
    } catch (e) {
      print('SignUp Error: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            throw 'This email is already registered. Please sign in instead.';
          case 'weak-password':
            throw 'Password is too weak. Please use a stronger password.';
          case 'invalid-email':
            throw 'Invalid email address format.';
          default:
            throw 'Failed to sign up: ${e.message}';
        }
      }
      throw 'An unexpected error occurred during sign up.';
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      print('Starting email sign in...');
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save auth data locally
      final token = await userCredential.user?.getIdToken();
      await _localStorage.saveAuthData(
        token: token,
        userId: userCredential.user?.uid,
        email: userCredential.user?.email,
      );

      // // Initialize demo stations
      // await _firestoreService.initializeDemoStations();
      return userCredential;
    } catch (e) {
      print('SignIn Error: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            throw 'No user found with this email.';
          case 'wrong-password':
            throw 'Wrong password provided.';
          case 'user-disabled':
            throw 'This account has been disabled.';
          case 'invalid-email':
            throw 'Invalid email address format.';
          default:
            throw 'Failed to sign in: ${e.message}';
        }
      }
      throw 'An unexpected error occurred during sign in.';
    }
  }

  // Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('Starting Google sign in...');
      // Begin interactive sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign in aborted by user');
        throw 'Sign in aborted by user';
      }

      print('Getting Google auth credentials...');
      // Obtain auth details from request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('Creating Firebase credential...');
      // Create new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in to Firebase...');
      // Sign in to Firebase with credential
      final userCredential = await _auth.signInWithCredential(credential);

      print('Successfully signed in with Google, initializing user data...');
      // Initialize user data in Firestore if it's a new user
      if (userCredential.user != null) {
        final names = googleUser.displayName?.split(' ') ?? [];
        final firstName = names.isNotEmpty ? names.first : null;
        final lastName = names.length > 1 ? names.last : null;

        await _firestoreService.initializeUserData(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email!,
          firstName: firstName,
          lastName: lastName,
        );
      }

      // Save auth data locally
      final token = await userCredential.user?.getIdToken();
      await _localStorage.saveAuthData(
        token: token,
        userId: userCredential.user?.uid,
        email: userCredential.user?.email,
      );

      return userCredential;
    } catch (e) {
      print('Google SignIn Error: $e');
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            throw 'An account already exists with the same email address but different sign-in credentials.';
          case 'invalid-credential':
            throw 'The credential received is malformed or has expired.';
          case 'operation-not-allowed':
            throw 'Google sign-in is not enabled for this project.';
          case 'user-disabled':
            throw 'This user account has been disabled.';
          case 'user-not-found':
            throw 'No user found for that email.';
          case 'wrong-password':
            throw 'Wrong password.';
          case 'invalid-verification-code':
            throw 'The credential verification code received is invalid.';
          case 'invalid-verification-id':
            throw 'The credential verification ID received is invalid.';
          default:
            throw 'Failed to sign in with Google: ${e.message}';
        }
      } else if (e is String) {
        throw e;
      }
      throw 'An unexpected error occurred during Google sign in.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('Starting sign out...');
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);

      await _localStorage.clearAuthData();

      print('Successfully signed out');
    } catch (e) {
      print('SignOut Error: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Password Reset
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Error Handler
  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'Email is already in use.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'operation-not-allowed':
          return 'Operation not allowed.';
        default:
          return 'An error occurred. Please try again.';
      }
    }
    return e.toString();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return _localStorage.isLoggedIn();
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _localStorage.getUserId();
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _localStorage.getUserEmail();
  }
}
