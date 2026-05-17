import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_defaults.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dr_copilot/src/core/services/error_reporting_service.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/services/remote_config_service.dart';

class AuthFirebaseApi {
  /// An instance of [FirebaseAuth] used to handle authentication operations
  /// such as sign-in, sign-up, and sign-out with Firebase in the application.
  final FirebaseAuth _firebaseAuth;

  AuthFirebaseApi(this._firebaseAuth);

  /// A reference to the 'users' collection in Firestore.
  ///
  /// This collection is used to store and retrieve user-related data
  /// from the Firebase Firestore database.
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  /// A reference to the 'user_invitations' collection in Firestore.
  ///
  /// This collection is used to store and retrieve user invitation-related data
  /// from the Firebase Firestore database.
  final CollectionReference _userInvitations =
      FirebaseFirestore.instance.collection('user_invitations');

  /// Creates an instance of [GoogleSignInHelper] to handle Google sign-in functionality.
  ///
  /// This helper is used to facilitate authentication with Google accounts,
  /// providing methods to sign in, sign out, and manage user sessions via Google.
  final GoogleSignInHelper googleSignInHelper = GoogleSignInHelper();

  /// Handles native Google sign-in for Android and iOS.
  Future<GoogleSignInResult?> _nativeGoogleSignIn() async {
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
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;
      if (user == null) return null;
      final idToken = await user.getIdToken();
      final accessToken = userCredential.credential?.accessToken;
      await saveAuthentication(accessToken: accessToken, idToken: idToken);
      // Use the same onboarding/multi-clinic logic as Google sign-in
      return await _handleMultiClinicOnboarding(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Registers a new user using the provided email and password.
  ///
  /// Returns a [UserModel] if the sign-up is successful, or `null` if it fails.
  ///
  /// Throws an exception if an error occurs during the sign-up process.
  Future<UserModel?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // Check beta status and user count
    final remoteConfig = sl<RemoteConfigService>();
    if (!remoteConfig.isSignupEnabled) {
      throw Exception(
          'Beta access is currently full. Please join the waitlist.');
    }

    // Check dynamic user count limit
    int currentCount = 0;
    try {
      final userCountQuery = await _usersCollection.count().get();
      currentCount = userCountQuery.count ?? 0;
    } catch (e) {
      debugPrint('Error getting user count during Email sign-up: $e');
    }
    if (currentCount >= remoteConfig.maxAllowedUsers) {
      throw Exception(
          'Beta user limit (${remoteConfig.maxAllowedUsers}) reached. Please join the waitlist.');
    }

    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      final User? user = userCredential.user;
      if (user == null) return null;
      final idToken = await user.getIdToken();
      final accessToken = userCredential.credential?.accessToken;
      await saveAuthentication(accessToken: accessToken, idToken: idToken);
      // Use the same onboarding/multi-clinic logic as Google sign-in
      return await _handleMultiClinicOnboarding(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Signs in the user using Google authentication.
  ///
  /// Returns a [UserModel] if the sign-in is successful, or `null` if it fails.
  ///
  /// Throws an exception if an error occurs during the sign-in process.
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInResult? googleResult = await _getGoogleSignInResult();

      /// Checks if the result from the Google sign-in process is null,
      /// which indicates that the user has canceled the sign-in operation.
      /// Returns null in such cases to signify that no authentication was performed.
      if (googleResult == null) {
        // User canceled the sign-in
        return null;
      }

      /// Retrieves the authentication details from the Google sign-in result.
      ///
      /// This typically includes tokens such as `accessToken` and `idToken`
      /// which are used for authenticating the user with Firebase or other services.
      final googleAuth = googleResult.authentication;

      /// Creates an [AuthCredential] for Google sign-in using the provided
      /// [accessToken] and [idToken] obtained from the Google authentication flow.
      ///
      /// The [accessToken] and [idToken] are retrieved from the [googleAuth] object,
      /// which contains the authentication details after a successful Google sign-in.
      /// These credentials are used to authenticate the user with Firebase.
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      /// Signs in a user with the provided [credential] using Firebase Authentication,
      /// and returns a [UserCredential] object containing information about the signed-in user.
      ///
      /// Throws a [FirebaseAuthException] if the sign-in process fails.
      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      /// The [user] property retrieves the authenticated [User] object from the [userCredential].
      /// Returns `null` if the authentication was unsuccessful or no user is associated with the credential.
      final User? user = userCredential.user;
      if (user == null) return null;

      /// Saves the authentication tokens obtained from Google sign-in for the given [user].
      ///
      /// This method stores the tokens from [googleAuth] securely for future authenticated requests.
      ///
      /// Throws an exception if saving the tokens fails.
      await _saveGoogleTokens(user, googleAuth);

      // Check if user is old or new
      final userDoc = await _usersCollection.doc(user.uid).get();
      if (!userDoc.exists) {
        // New User - Check if signups enabled
        final remoteConfig = sl<RemoteConfigService>();
        if (!remoteConfig.isSignupEnabled) {
          await user.delete(); // Clean up the auth record
          throw Exception(
              'Beta access is currently full. Please join the waitlist.');
        }

        // Check dynamic user count limit
        int currentCount = 0;
        try {
          final userCountQuery = await _usersCollection.count().get();
          currentCount = userCountQuery.count ?? 0;
        } catch (e) {
          debugPrint('Error getting user count during Google sign-in: $e');
        }
        if (currentCount >= remoteConfig.maxAllowedUsers) {
          await user.delete();
          throw Exception(
              'Beta user limit (${remoteConfig.maxAllowedUsers}) reached. Please join the waitlist.');
        }
      }

      /// Handles the onboarding process for users associated with multiple clinics.
      ///
      /// This method is called after user authentication to manage any additional
      /// onboarding steps required when a user is linked to more than one clinic.
      ///
      /// Returns a [Future] that completes when the onboarding process is finished.
      return await _handleMultiClinicOnboarding(user);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  /// Handles Google sign-in for all platforms and returns the result.
  Future<GoogleSignInResult?> _getGoogleSignInResult() async {
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
    return googleResult;
  }

  /// Saves authentication tokens after successful Google sign-in.
  Future<void> _saveGoogleTokens(
    User user,
    CustomGoogleAuthentication? googleAuth,
  ) async {
    final idToken = await user.getIdToken();
    final accessToken = googleAuth?.accessToken;
    await saveAuthentication(accessToken: accessToken, idToken: idToken);
  }

  /// Handles onboarding logic for multi-clinic support.
  /// Checks if the user exists, processes invitations, or creates a new clinic as needed.
  Future<UserModel> _handleMultiClinicOnboarding(User user) async {
    /// A list to store the IDs of clinics associated with the user.
    List<String> clinicIds = [];

    /// The ID of the primary clinic, if specified.
    String? primaryClinicId;

    /// List of rich clinic data
    List<Map<String, dynamic>>? richClinics;

    final userDocRef = _usersCollection.doc(user.uid);

    /// Creates a reference to the Firestore document corresponding to the given user's UID
    /// within the users collection.
    ///
    /// This reference can be used to read, update, or delete the user's document in Firestore.
    ///
    /// Example:
    /// ```dart
    /// final docRef = _usersCollection.doc(user.uid);
    /// ```
    final userDoc = await userDocRef.get();

    if (userDoc.exists) {
      // User exists: fetch clinic data
      final data = userDoc.data() as Map<String, dynamic>?;

      // Process rich clinics with timestamp conversion
      richClinics = (data?['clinics'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .map((clinic) {
            if (clinic['joinedAt'] is Timestamp) {
              clinic['joinedAt'] =
                  (clinic['joinedAt'] as Timestamp).toDate().toIso8601String();
            }
            return clinic;
          }).toList() ??
          [];

      // Extract IDs from rich clinics
      final Set<String> allClinicIds = {};
      for (var clinic in richClinics) {
        if (clinic['clinicId'] != null) {
          allClinicIds.add(clinic['clinicId'] as String);
        }
      }

      // Fallback for legacy (if any)
      final legacyIds =
          (data?['clinicIds'] as List<dynamic>?)?.cast<String>() ?? [];
      allClinicIds.addAll(legacyIds);

      clinicIds = allClinicIds.toList();
      primaryClinicId = data?['primaryClinicId'] as String?;
    } else {
      // User not found: check for invitation
      final invitations = await _userInvitations
          .where('email', isEqualTo: user.email)
          .where('status', isEqualTo: 'pending')
          .get();
      if (invitations.docs.isNotEmpty) {
        /// Accepts all pending invitations for the given user and creates the user document in Firestore.
        ///
        /// This method processes the provided list of invitations, marks them as accepted,
        /// and ensures the user document is created or updated accordingly.
        ///
        /// Parameters:
        /// - [user]: The user object representing the authenticated user.
        /// - [invitations]: A list of invitation objects to be accepted.
        /// - [userDocRef]: A reference to the Firestore document for the user.
        ///
        /// Returns a [Future] that completes when all invitations have been accepted and the user document is created.
        await _acceptAllInvitationsAndCreateUser(user, invitations, userDocRef);

        // Fetch the user doc again after creation
        final createdDoc = await userDocRef.get();
        final data = createdDoc.data() as Map<String, dynamic>?;
        richClinics = (data?['clinics'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .map((clinic) {
              if (clinic['joinedAt'] is Timestamp) {
                clinic['joinedAt'] =
                    (clinic['joinedAt'] as Timestamp).toDate().toIso8601String();
              }
              return clinic;
            }).toList() ??
            [];

        final Set<String> allClinicIds = {};
        for (var clinic in richClinics) {
          if (clinic['clinicId'] != null) {
            allClinicIds.add(clinic['clinicId'] as String);
          }
        }
        clinicIds = allClinicIds.toList();
        primaryClinicId = data?['primaryClinicId'] as String?;
      } else {
        // No invitation: sign up as owner (admin) for a new clinic
        final result = await _createOwnerAndClinic(user, userDocRef);
        clinicIds = List<String>.from(result['clinicIds']);
        primaryClinicId = result['primaryClinicId'];
        richClinics = List<Map<String, dynamic>>.from(result['clinics']);
      }
    }
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
      clinicIds: clinicIds,
      clinics: richClinics,
      primaryClinicId: primaryClinicId,
    );
  }

  /// Accepts all invitations for the user, aggregates clinicIds, and creates the user doc.
  Future<void> _acceptAllInvitationsAndCreateUser(
    User user,
    QuerySnapshot invitations,
    DocumentReference docRef,
  ) async {
    Set<String> allClinicIds = {};
    String? firstClinicId;

    for (final invite in invitations.docs) {
      final inviteData = invite.data() as Map<String, dynamic>?;
      final invitedClinicId = inviteData?['clinicId'] as String?;
      final invitedClinicName = inviteData?['clinicName'] as String? ?? 'Clinic';
      final invitedRoles = List<String>.from(inviteData?['roles'] ?? []);
      final invitedRoleStr = invitedRoles.isNotEmpty ? invitedRoles.first : 'doctor';

      firstClinicId ??= invitedClinicId;

      if (invitedClinicId != null) {
        allClinicIds.add(invitedClinicId);

        // Resolve role and default permissions
        final role = AppRole.values.firstWhere(
          (r) => r.name.toLowerCase() == invitedRoleStr.toLowerCase(),
          orElse: () => AppRole.doctor,
        );
        final defaultPermissions = RoleDefaults.getPermissionsForRole(role);
        final defaultPermStrings = defaultPermissions.map((p) => p.name).toList();

        // Retrieve scope associations from invitation document
        final linkedDoctorIds = List<String>.from(inviteData?['linkedDoctorIds'] ?? []);
        final departmentIds = List<String>.from(inviteData?['departmentIds'] ?? []);
        final teamIds = List<String>.from(inviteData?['teamIds'] ?? []);

        // Create the Member record in the Single Source of Truth
        final clinicRef = FirebaseFirestore.instance.collection('clinics').doc(invitedClinicId);
        await clinicRef.collection('members').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'role': role.name,
          'permissions': defaultPermStrings,
          'linkedDoctorIds': linkedDoctorIds,
          'departmentIds': departmentIds,
          'teamIds': teamIds,
          'joinedAt': FieldValue.serverTimestamp(),
        });
      }

      await invite.reference.update({
        'status': 'accepted',
        'acceptedAt': Timestamp.fromDate(DateTime.now().toUtc()),
      });
    }

    final primaryClinicId = firstClinicId;

    // Write minimal user data - backend will handle the rest via invitation acceptance
    // Note: Removed clinicIds field - using only clinics array with map structure
    await docRef.set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
      'primaryClinicId': primaryClinicId,
      'clinics': allClinicIds.map((cid) => {
        'clinicId': cid,
        'clinicName': 'Clinic',
        'joinedAt': Timestamp.fromDate(DateTime.now().toUtc()),
      }).toList(),
    });
  }

  /// Creates a new owner/admin user and a new clinic, returns all relevant onboarding info.
  Future<Map<String, dynamic>> _createOwnerAndClinic(
    User user,
    DocumentReference docRef,
  ) async {
    final clinicsCollection = FirebaseFirestore.instance.collection('clinics');
    final newClinicRef = clinicsCollection.doc();

    // Create clinic with owner
    await newClinicRef.set({
      'ownerId': user.uid,
      'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
      'name': user.displayName ?? user.email ?? 'Clinic',
      'adminEmail': user.email,
    });

    final primaryClinicId = newClinicRef.id;

    // Create user document with clinic membership
    // Note: Removed clinicIds field - using only clinics array with map structure
    await docRef.set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
      'primaryClinicId': primaryClinicId,
      'clinics': [
        {
          'clinicId': newClinicRef.id,
          'clinicName': user.displayName ?? user.email ?? 'Clinic',
          // 'role': 'Admin', // Removed to enforce usage of members subcollection
          'joinedAt': Timestamp.fromDate(DateTime.now().toUtc()),
        },
      ],
    });

    // CRITICAL: Create the Member record in the Single Source of Truth
    // This ensures the new owner has permissions immediately
    try {
      final defaultPermissions = RoleDefaults.getPermissionsForRole(
        AppRole.admin,
      );
      final defaultPermStrings = defaultPermissions.map((p) => p.name).toList();

      await newClinicRef.collection('members').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'role': 'admin', // Owner is always admin
        'permissions': defaultPermStrings,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint('Error creating member record for new owner: $e');
      ErrorReportingService.reportError(e, stack);
      // We might want to rethrow or handle this more gracefully
    }

    return {
      'primaryClinicId': primaryClinicId,
      'clinicIds': [primaryClinicId],
      'clinics': [
        {
          'clinicId': primaryClinicId,
          'clinicName': user.displayName ?? user.email ?? 'Clinic',
          'joinedAt': DateTime.now().toUtc().toIso8601String(),
        },
      ],
    };
  }

  /// Saves authentication tokens (accessToken, idToken) to local storage.
  Future<void> saveAuthentication({
    String? accessToken,
    String? idToken,
  }) async {
    final secureStorage = const FlutterSecureStorage();
    if (accessToken != null) {
      await secureStorage.write(key: 'auth_access_token', value: accessToken);
    }
    if (idToken != null) {
      await secureStorage.write(key: 'auth_id_token', value: idToken);
    }
  }

  /// Signs out the currently authenticated user from the application.
  ///
  /// This method logs the user out of their account and clears any
  /// authentication state associated with the current session.
  ///
  /// Throws an [Exception] if the sign-out process fails.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();

    // Only clear keys in release mode to avoid friction during development/testing
    if (kReleaseMode) {
      const secureStorage = FlutterSecureStorage();

      // Clear Auth Tokens
      await secureStorage.delete(key: 'auth_access_token');
      await secureStorage.delete(key: 'auth_id_token');

      // Clear AI Model Keys
      await secureStorage.delete(key: 'selected_ai_model');
      await secureStorage.delete(key: 'gemini_api_key');
      await secureStorage.delete(key: 'openai_api_key');
      await secureStorage.delete(key: 'claude_api_key');

      // Clear Legacy Keys
      await secureStorage.delete(key: 'geminiApiKey');
      await secureStorage.delete(key: 'chatGptApiKey');
    }
  }

  /// Deletes the currently authenticated user.
  Future<void> deleteCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  /// Returns the current authenticated user as a Firebase [User], or null if not signed in.
  Future<UserModel?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    // Fetch user data from Firestore to get roles and permissions
    try {
      final userDoc = await _usersCollection.doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>?;

        final richClinics = (data?['clinics'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .map((clinic) {
              // Convert Timestamp to ISO String for safe serialization
              if (clinic['joinedAt'] is Timestamp) {
                clinic['joinedAt'] = (clinic['joinedAt'] as Timestamp)
                    .toDate()
                    .toIso8601String();
              }
              return clinic;
            }).toList() ??
            [];

        // Merge IDs
        final Set<String> allClinicIds = {};
        for (var clinic in richClinics) {
          if (clinic['clinicId'] != null) {
            allClinicIds.add(clinic['clinicId'] as String);
          }
        }

        final clinicIds = allClinicIds.toList();
        final primaryClinicId = data?['primaryClinicId'] as String?;

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
          clinicIds: clinicIds,
          clinics: richClinics,
          primaryClinicId: primaryClinicId,
        );
      }
    } catch (e, stack) {
      debugPrint('Error fetching user data from Firestore: $e');
      ErrorReportingService.reportError(e, stack);
    }

    // Fallback to basic user model if Firestore fetch fails
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

  /// Updates the current user's display name and/or photo URL.
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
  Stream<UserModel?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        var userDoc = await _usersCollection.doc(user.uid).get();
        // If logged in but the Firestore user document is still being created/onboarded,
        // retry a few times to prevent the signup/onboarding race condition.
        int retries = 0;
        while (!userDoc.exists && retries < 5) {
          debugPrint('[AuthFirebaseApi] User doc does not exist yet. Retrying in 200ms... (Attempt ${retries + 1}/5)');
          await Future.delayed(const Duration(milliseconds: 200));
          userDoc = await _usersCollection.doc(user.uid).get();
          retries++;
        }

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>?;

          final richClinics = (data?['clinics'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .map((clinic) {
                // Convert Timestamp to ISO String for safe serialization
                if (clinic['joinedAt'] is Timestamp) {
                  clinic['joinedAt'] = (clinic['joinedAt'] as Timestamp)
                      .toDate()
                      .toIso8601String();
                }
                return clinic;
              }).toList() ??
              [];

          // Merge IDs
          final Set<String> allClinicIds = {};
          for (var clinic in richClinics) {
            if (clinic['clinicId'] != null) {
              allClinicIds.add(clinic['clinicId'] as String);
            }
          }

          final clinicIds = allClinicIds.toList();
          final primaryClinicId = data?['primaryClinicId'] as String?;

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
            clinicIds: clinicIds,
            clinics: richClinics,
            primaryClinicId: primaryClinicId,
          );
        }
      } catch (e, stack) {
        debugPrint(
          'Error fetching user data from Firestore in authStateChanges: $e',
        );
        ErrorReportingService.reportError(e, stack);
      }
      // Fallback to basic user model if Firestore fetch fails
      return UserModel.fromFirebaseUser(user);
    });
  }

  /// Checks if a user with the given [email] already exists in the system.
  Future<bool> doesUserExist(String email) async {
    try {
      final querySnapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking user existence: $e');
      throw Exception('Failed to check user existence');
    }
  }

  /// Manually creates a new clinic for the currently authenticated user.
  Future<void> createClinicForUser(String clinicName) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');

    final clinicsCollection = FirebaseFirestore.instance.collection('clinics');
    final newClinicRef = clinicsCollection.doc();

    // Create clinic with owner
    await newClinicRef.set({
      'ownerId': user.uid,
      'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
      'name': clinicName,
      'adminEmail': user.email,
    });

    final primaryClinicId = newClinicRef.id;

    // Update user document
    final userDocRef = _usersCollection.doc(user.uid);
    await userDocRef.update({
      'primaryClinicId': primaryClinicId,
      'clinics': FieldValue.arrayUnion([
        {
          'clinicId': primaryClinicId,
          'clinicName': clinicName,
          'joinedAt': Timestamp.fromDate(DateTime.now().toUtc()),
        }
      ]),
    });

    // Create the Member record in the Single Source of Truth
    final defaultPermissions = RoleDefaults.getPermissionsForRole(AppRole.admin);
    final defaultPermStrings = defaultPermissions.map((p) => p.name).toList();

    await newClinicRef.collection('members').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': 'admin',
      'permissions': defaultPermStrings,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Manually accepts a pending invitation for the currently authenticated user.
  Future<void> acceptInvitationForUser(String invitationId) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) throw Exception('No user is currently signed in.');

    final inviteRef = _userInvitations.doc(invitationId);
    final inviteDoc = await inviteRef.get();
    if (!inviteDoc.exists) throw Exception('Invitation not found.');

    final inviteData = inviteDoc.data() as Map<String, dynamic>?;
    final invitedClinicId = inviteData?['clinicId'] as String?;
    final invitedClinicName = inviteData?['clinicName'] as String? ?? 'Clinic';
    final invitedRoles = List<String>.from(inviteData?['roles'] ?? []);
    final invitedRoleStr = invitedRoles.isNotEmpty ? invitedRoles.first : 'doctor';

    if (invitedClinicId == null) throw Exception('Invalid clinic ID in invitation.');

    // Update invitation status
    await inviteRef.update({
      'status': 'accepted',
      'acceptedAt': Timestamp.fromDate(DateTime.now().toUtc()),
    });

    // Update user document
    final userDocRef = _usersCollection.doc(user.uid);
    await userDocRef.update({
      'primaryClinicId': invitedClinicId,
      'clinics': FieldValue.arrayUnion([
        {
          'clinicId': invitedClinicId,
          'clinicName': invitedClinicName,
          'joinedAt': Timestamp.fromDate(DateTime.now().toUtc()),
        }
      ]),
    });

    // Create the Member record based on role and scopes from invitation!
    final role = AppRole.values.firstWhere(
      (r) => r.name.toLowerCase() == invitedRoleStr.toLowerCase(),
      orElse: () => AppRole.doctor,
    );
    final defaultPermissions = RoleDefaults.getPermissionsForRole(role);
    final defaultPermStrings = defaultPermissions.map((p) => p.name).toList();

    // Retrieve scope associations from invitation document
    final linkedDoctorIds = List<String>.from(inviteData?['linkedDoctorIds'] ?? []);
    final departmentIds = List<String>.from(inviteData?['departmentIds'] ?? []);
    final teamIds = List<String>.from(inviteData?['teamIds'] ?? []);

    final clinicRef = FirebaseFirestore.instance.collection('clinics').doc(invitedClinicId);
    await clinicRef.collection('members').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'role': role.name,
      'permissions': defaultPermStrings,
      'linkedDoctorIds': linkedDoctorIds,
      'departmentIds': departmentIds,
      'teamIds': teamIds,
      'joinedAt': FieldValue.serverTimestamp(),
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
