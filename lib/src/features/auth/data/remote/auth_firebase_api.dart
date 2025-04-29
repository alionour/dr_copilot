import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';

class AuthFirebaseApi extends AbstractAuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Creates an instance of [GoogleSignInHelper] to handle Google sign-in functionality.
  ///
  /// This helper is used to facilitate authentication with Google accounts,
  /// providing methods to sign in, sign out, and manage user sessions via Google.
  final GoogleSignInHelper googleSignInHelper = GoogleSignInHelper();

  /// Handles native Google sign-in for Android and iOS.
  Future<GoogleSignInResult?> _nativeGoogleSignIn() async {
    final GoogleSignInHelper googleSignInHelper = GoogleSignInHelper();
    final account = await googleSignInHelper.signIn();
    if (account == null) return null;
    final authentication = await account.authentication;
    return GoogleSignInResult(
      account: CustomGoogleSignInAccount(
        displayName: account.displayName,
        email: account.email,
        id: account.id,
        photoUrl: account.photoUrl,
        originalAccount: account,
      ),
      authentication: CustomGoogleAuthentication(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
        originalAuthentication: authentication,
      ),
    );
  }

  /// Handles web Google sign-in.
  Future<GoogleSignInResult?> _webGoogleSignIn() async {
    final GoogleSignInHelper googleSignInHelper = GoogleSignInHelper();
    final account = await googleSignInHelper.signIn();
    if (account == null) return null;
    final authentication = await account.authentication;
    return GoogleSignInResult(
      account: CustomGoogleSignInAccount(
        displayName: account.displayName,
        email: account.email,
        id: account.id,
        photoUrl: account.photoUrl,
        originalAccount: account,
      ),
      authentication: CustomGoogleAuthentication(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
        originalAuthentication: authentication,
      ),
    );
  }

  /// Handles Google sign-in for all platforms (Windows/Linux).
  Future<GoogleSignInResult?> _allPlatformsGoogleSignIn() async {
    final GoogleSignInHelper googleSignInHelper = GoogleSignInHelper();
    final authentication = await googleSignInHelper.signInAllPlatforms();
    if (authentication == null) return null;
    return GoogleSignInResult(
      account: null,
      authentication: CustomGoogleAuthentication(
        accessToken: authentication.accessToken,
        idToken: authentication.idToken,
        originalAuthentication: authentication,
      ),
    );
  }

  /// Logs in a user using the provided email and password.
  ///
  /// Returns a [UserModel] representing the authenticated user upon successful login.
  ///
  /// Throws an exception if authentication fails.
  @override
  Future<UserModel?> loginWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;

      /// Checks if the [user] object is not null, indicating that a user is currently authenticated.
      /// This condition is typically used to perform actions only when a user is signed in.
      /// This condition is typically used to perform actions that require a valid authenticated user.
      ///
      /// Typically used to verify authentication state before proceeding with user-specific operations.
      if (user != null) {
        // Save tokens after successful login
        final idToken = await user.getIdToken();
        final accessToken = userCredential.credential?.accessToken;
        await saveAuthentication(accessToken: accessToken, idToken: idToken);
        return UserModel(
          uid: user.uid,
          email: user.email,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Registers a new user using the provided email and password.
  ///
  /// Returns a [UserModel] if the sign-up is successful, or `null` if it fails.
  ///
  /// Throws an exception if an error occurs during the sign-up process.
  @override
  Future<UserModel?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final User? user = userCredential.user;
      if (user != null) {
        // Save tokens after successful sign up
        final idToken = await user.getIdToken();
        final accessToken = userCredential.credential?.accessToken;
        await saveAuthentication(accessToken: accessToken, idToken: idToken);
        return UserModel(
          uid: user.uid,
          email: user.email,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Signs in the user using Google authentication.
  ///
  /// Returns a [UserModel] if the sign-in is successful, or `null` if it fails.
  ///
  /// Throws an exception if an error occurs during the sign-in process.
  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      /// Holds the result of a Google Sign-In operation, or null if the sign-in has not been attempted or failed.
      ///
      /// [GoogleSignInResult] typically contains information about the user's authentication status,
      /// credentials, and any associated user data returned from the Google Sign-In process.
      GoogleSignInResult? googleResult;

      /// Checks if the current platform is either Android or iOS.
      ///
      /// This condition is typically used to execute platform-specific code
      /// for mobile devices, ensuring that the following logic only runs
      /// on Android or iOS platforms.
      if (io.Platform.isAndroid || io.Platform.isIOS) {
        /// Initiates the native Google Sign-In process and awaits the result.
        ///
        /// Returns the result of the Google authentication flow, which may include
        /// user credentials or authentication tokens depending on the implementation.
        ///
        /// Throws an exception if the sign-in process fails or is cancelled by the user.
        googleResult = await _nativeGoogleSignIn();
      } else if (kIsWeb) {
        /// Initiates the Google Sign-In process for web platforms and assigns the result to [googleResult].
        ///
        /// This asynchronous operation attempts to authenticate the user using their Google account.
        /// The result of the sign-in attempt is stored in [googleResult], which can be used for further authentication logic.
        ///
        /// Throws an exception if the sign-in process fails.
        googleResult = await _webGoogleSignIn();
      } else if (io.Platform.isWindows || io.Platform.isLinux) {
        /// Initiates the Google sign-in process across all supported platforms and
        /// assigns the result to [googleResult].
        ///
        /// This asynchronous operation attempts to authenticate the user using
        /// Google Sign-In and returns the authentication result.
        ///
        /// Throws an exception if the sign-in process fails.
        googleResult = await _allPlatformsGoogleSignIn();
      }

      if (googleResult == null) {
        // User canceled the sign-in
        return null;
      }
      final googleAuth = googleResult.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      /// The [UserCredential] object returned after a successful authentication operation,
      /// such as sign-in or sign-up, containing information about the authenticated user
      /// and additional authentication details.
      /// Signs in a user with the provided [credential] using Firebase Authentication.
      ///
      /// This method attempts to authenticate the user by passing the given
      /// [AuthCredential] to Firebase. If the sign-in is successful, the user's
      /// authentication state will be updated accordingly. If the sign-in fails,
      /// an exception will be thrown.
      ///
      /// Throws a [FirebaseAuthException] if the sign-in process fails.
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user != null) {
        // Save tokens after successful Google sign in
        final idToken = await user.getIdToken();
        final accessToken = googleAuth?.accessToken;
        await saveAuthentication(accessToken: accessToken, idToken: idToken);
        return UserModel(
          uid: user.uid,
          displayName: user.displayName,
          email: user.email,
          photoURL: user.photoURL,
          emailVerified: user.emailVerified,
          isAnonymous: user.isAnonymous,
          metadata: user.metadata,
          phoneNumber: user.phoneNumber,
          providerData: user.providerData,
          refreshToken: user.refreshToken,
          tenantId: user.tenantId,
        );
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Saves authentication tokens (accessToken, idToken) to local storage.
  Future<void> saveAuthentication(
      {String? accessToken, String? idToken}) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) {
      await prefs.setString('auth_access_token', accessToken);
    }
    if (idToken != null) {
      await prefs.setString('auth_id_token', idToken);
    }
  }

  /// Signs out the currently authenticated user from the application.
  ///
  /// This method logs the user out of their account and clears any
  /// authentication state associated with the current session.
  ///
  /// Throws an [Exception] if the sign-out process fails.
  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Deletes the currently authenticated user.
  @override
  Future<void> deleteCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  /// Returns the current authenticated user as a Firebase [User], or null if not signed in.
  @override
  Future<User?> getCurrentUser() async {
    return _firebaseAuth.currentUser;
  }

  /// Updates the current user's display name and/or photo URL.
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      await user.reload();
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  /// Returns a [Stream] that emits the current [UserModel] whenever the authentication
  /// state changes.
  ///
  /// The stream emits `null` if the user is signed out, and a [UserModel] object
  /// when the user is signed in. This can be used to listen for login, logout,
  /// or user changes in real-time.
  ///
  /// Example usage:
  /// ```dart
  /// authFirebaseApi.authStateChanges().listen((user) {
  ///   if (user == null) {
  ///     // User is signed out
  ///   } else {
  ///     // User is signed in
  ///   }
  /// });
  /// ```
  @override
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((user) {
      if (user == null) return null;
      return UserModel(
        uid: user.uid,
        displayName: user.displayName,
        email: user.email,
        photoURL: user.photoURL,
        emailVerified: user.emailVerified,
        isAnonymous: user.isAnonymous,
        metadata: user.metadata,
        phoneNumber: user.phoneNumber,
        providerData: user.providerData,
        refreshToken: user.refreshToken,
        tenantId: user.tenantId,
      );
    });
  }
}

// Custom class to represent a Google sign-in account (platform-agnostic)
class CustomGoogleSignInAccount {
  final String? displayName;
  final String? email;
  final String? id;
  final String? photoUrl;
  final dynamic
      originalAccount; // Holds the original GoogleSignInAccount or null

  CustomGoogleSignInAccount({
    this.displayName,
    this.email,
    this.id,
    this.photoUrl,
    this.originalAccount,
  });
}

// Custom class to represent Google authentication credentials (platform-agnostic)
class CustomGoogleAuthentication {
  final String? accessToken;
  final String? idToken;
  final dynamic
      originalAuthentication; // Holds the original authentication object

  CustomGoogleAuthentication({
    this.accessToken,
    this.idToken,
    this.originalAuthentication,
  });
}

// Custom class to hold Google sign-in result
/// Represents the result of a Google sign-in operation.
///
/// Contains the signed-in account information and authentication details.
///
/// [account] - The user's Google account information.
/// [authentication] - The authentication credentials associated with the account.
class GoogleSignInResult {
  final CustomGoogleSignInAccount? account;
  final CustomGoogleAuthentication? authentication;
  GoogleSignInResult({required this.account, required this.authentication});
}
