import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart' as io;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthFirebaseApi extends AbstractAuthRepository {
  /// An instance of [FirebaseAuth] used to handle authentication operations
  /// such as sign-in, sign-up, and sign-out with Firebase in the application.
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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
  @override
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
      User user, CustomGoogleAuthentication? googleAuth) async {
    final idToken = await user.getIdToken();
    final accessToken = googleAuth?.accessToken;
    await saveAuthentication(accessToken: accessToken, idToken: idToken);
  }

  /// Handles onboarding logic for multi-clinic support.
  /// Checks if the user exists, processes invitations, or creates a new clinic as needed.
  Future<UserModel> _handleMultiClinicOnboarding(User user) async {
    /// A list to store the roles assigned to the user.
    /// 
    /// This list is initialized as empty and is intended to hold instances of [AppRole],
    /// representing the different roles that a user can have within the application.
    List<AppRole> roles = [];

    /// A list to store the permissions assigned to the app user.
    /// 
    /// This list is initialized as empty and can be populated with instances of
    /// [AppPermission] to represent the various permissions granted to the user.
    List<AppPermission> permissions = [];

    /// The unique identifier of the owner, which may be null if not assigned.
    String? ownerId;

    /// A list to store the IDs of clinics associated with the user.
    /// 
    /// This list is initialized as empty and can be populated with clinic IDs
    /// retrieved from a remote source or user input.
    List<String> clinicIds = [];

    /// The ID of the primary clinic, if specified.
    String? primaryClinicId;

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
      // User exists: fetch roles, permissions, ownerId, clinicIds
      final data = userDoc.data() as Map<String, dynamic>?;

      final roleStrings =
          (data?['roles'] as List<dynamic>?)?.cast<String>() ?? [];

      final permissionStrings =
          (data?['permissions'] as List<dynamic>?)?.cast<String>() ?? [];

      /// Converts a list of role strings (`roleStrings`) to a list of [AppRole] enums.
      /// 
      /// For each string in `roleStrings`, attempts to find a matching [AppRole] by name.
      /// If no match is found, defaults to [AppRole.readonly].
      /// 
      /// Returns a list of [AppRole] corresponding to the input strings.
      roles = roleStrings
          .map((s) => AppRole.values
              .firstWhere((r) => r.name == s, orElse: () => AppRole.readonly))
          .toList();

      /// Converts a list of permission strings to a list of [AppPermission] enums.
      /// 
      /// For each string in [permissionStrings], attempts to find the corresponding
      /// [AppPermission] by matching the enum's `name` property. If no match is found,
      /// defaults to the first value in [AppPermission.values].
      permissions = permissionStrings
          .map((s) => AppPermission.values.firstWhere((p) => p.name == s,
              orElse: () => AppPermission.values.first))
          .toList();

      /// Retrieves the 'ownerId' field from the [data] map and assigns it to [ownerId].
      /// 
      /// The value is cast to a [String]? to handle cases where 'ownerId' may be absent or null.
      ownerId = data?['ownerId'] as String?;
      
      /// Retrieves the list of clinic IDs from the provided [data] map.
      /// 
      /// Attempts to cast the 'clinicIds' entry to a `List<String>`. 
      /// If the entry is null or not present, returns an empty list.
      /// 
      /// Example:
      /// ```dart
      /// // Given data = {'clinicIds': ['id1', 'id2']};
      /// // clinicIds will be ['id1', 'id2']
      /// ```
      ///
      /// This ensures `clinicIds` is always a non-null `List<String>`.
      clinicIds = (data?['clinicIds'] as List<dynamic>?)?.cast<String>() ?? [];
      
      /// Retrieves the 'primaryClinicId' value from the [data] map and assigns it to [primaryClinicId].
      /// 
      /// The value is expected to be a [String], but may be `null` if the key does not exist or the value is not a string.
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
        final roleStrings =
            (data?['roles'] as List<dynamic>?)?.cast<String>() ?? [];
        final permissionStrings =
            (data?['permissions'] as List<dynamic>?)?.cast<String>() ?? [];
        roles = roleStrings
            .map((s) => AppRole.values
                .firstWhere((r) => r.name == s, orElse: () => AppRole.readonly))
            .toList();
        permissions = permissionStrings
            .map((s) => AppPermission.values.firstWhere((p) => p.name == s,
                orElse: () => AppPermission.values.first))
            .toList();
        ownerId = data?['ownerId'] as String?;
        clinicIds =
            (data?['clinicIds'] as List<dynamic>?)?.cast<String>() ?? [];
        primaryClinicId = data?['primaryClinicId'] as String?;
      } else {
        // No invitation: sign up as owner (admin) for a new clinic
        final result = await _createOwnerAndClinic(user, userDocRef);
        roles = result['roles'];
        permissions = result['permissions'];
        ownerId = result['ownerId'];
        clinicIds = result['clinicIds'];
        primaryClinicId = result['primaryClinicId'];
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
      roles: roles,
      permissions: permissions,
      clinicIds: clinicIds,
      primaryClinicId: primaryClinicId,
      ownerId: ownerId,
    );
  }

  /// Accepts all invitations for the user, aggregates roles/permissions/clinicIds, and creates the user doc.
  Future<void> _acceptAllInvitationsAndCreateUser(
      User user, QuerySnapshot invitations, DocumentReference docRef) async {
    Set<String> allRoles = {};
    Set<String> allPermissions = {};
    Set<String> allClinicIds = {};
    String? firstOwnerId;
    String? firstClinicId;

    for (final invite in invitations.docs) {
      final inviteData = invite.data() as Map<String, dynamic>?;
      final invitedRoles =
          (inviteData?['roles'] as List<dynamic>?)?.cast<String>() ?? [];
      final invitedPermissions =
          (inviteData?['permissions'] as List<dynamic>?)?.cast<String>() ?? [];
      final invitedClinicId = inviteData?['clinicId'] as String?;
      final invitedBy = inviteData?['invitedBy'] as String?;
      
      /// Assigns the value of [invitedBy] to [firstOwnerId] if [firstOwnerId] is currently null.
      /// 
      /// This ensures that [firstOwnerId] has a value, defaulting to [invitedBy] when not already set.
      firstOwnerId ??= invitedBy;
      
      /// Assigns the value of [invitedClinicId] to [firstClinicId] only if [firstClinicId] is currently null.
      /// 
      /// This ensures that [firstClinicId] has a value, preferring its existing value if set,
      /// or falling back to [invitedClinicId] otherwise.
      firstClinicId ??= invitedClinicId;
      
      /// Adds all elements from the [invitedRoles] collection to the [allRoles] collection.
      /// 
      /// This operation appends the roles that have been invited to the existing list of all roles,
      /// ensuring that the [allRoles] list contains both the original and newly invited roles.
      allRoles.addAll(invitedRoles);
      
      /// Adds all permissions from [invitedPermissions] to the [allPermissions] set.
      /// 
      /// This merges the permissions granted via invitation into the existing set of permissions.
      allPermissions.addAll(invitedPermissions);
      
      /// Adds the [invitedClinicId] to the [allClinicIds] list if it is not null.
      /// 
      /// This ensures that only valid (non-null) clinic IDs are included in the list.
      if (invitedClinicId != null) allClinicIds.add(invitedClinicId);
      
      /// Updates the referenced invite document in Firestore with the provided data.
      /// 
      /// This operation is asynchronous and will complete once the update is successful.
      /// Throws an exception if the update fails.
      await invite.reference.update({
        'status': 'accepted',
        'acceptedAt': Timestamp.fromDate(DateTime.now().toUtc())
      });
    }
    final roles = allRoles
        .map((s) => AppRole.values
            .firstWhere((r) => r.name == s, orElse: () => AppRole.readonly))
        .toList();
    final permissions = allPermissions
        .map((s) => AppPermission.values.firstWhere((p) => p.name == s,
            orElse: () => AppPermission.values.first))
        .toList();
    final ownerId = firstOwnerId ?? '';
    final clinicIds = allClinicIds.toList();
    final primaryClinicId = firstClinicId;
    await docRef.set({
      'roles': roles.map((r) => r.name).toList(),
      'permissions': permissions.map((p) => p.name).toList(),
      'email': user.email,
      'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
      'ownerId': ownerId,
      'clinicIds': clinicIds,
      'primaryClinicId': primaryClinicId,
    });
  }

  /// Creates a new owner/admin user and a new clinic, returns all relevant onboarding info.
  Future<Map<String, dynamic>> _createOwnerAndClinic(
      User user, DocumentReference docRef) async {
    final roles = [AppRole.admin];
    final permissions = <AppPermission>[];
    final ownerId = user.uid;
    final clinicsCollection = FirebaseFirestore.instance.collection('clinics');
    final newClinicRef = clinicsCollection.doc();
    
    /// Sets the initial data for a new clinic in Firestore.
    ///
    /// The data includes:
    /// - `ownerId`: The unique identifier of the clinic owner.
    /// - `createdAt`: The UTC timestamp of clinic creation.
    /// - `name`: The display name of the user, or their email, or 'Clinic' as a fallback.
    /// - `adminEmail`: The email address of the clinic administrator.
    ///
    /// This operation is performed on the reference to the new clinic document.
    await newClinicRef.set({
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
      'name': user.displayName ?? user.email ?? 'Clinic',
      'adminEmail': user.email,
    });

    final clinicIds = [newClinicRef.id];
    final primaryClinicId = newClinicRef.id;
    
    /// Stores user authentication data in Firestore by setting the following fields:
    /// - `roles`: A list of role names assigned to the user.
    /// - `permissions`: A list of permission names granted to the user.
    /// - `email`: The user's email address.
    /// - `createdAt`: The UTC timestamp when the user was created.
    /// - `ownerId`: The ID of the owner associated with the user.
    /// - `clinicIds`: A list of clinic IDs associated with the user.
    /// - `primaryClinicId`: The primary clinic ID for the user.
    await docRef.set({
      'roles': roles.map((r) => r.name).toList(),
      'permissions': permissions.map((p) => p.name).toList(),
      'email': user.email,
      'createdAt': Timestamp.fromDate(DateTime.now().toUtc()),
      'ownerId': ownerId,
      'clinicIds': clinicIds,
      'primaryClinicId': primaryClinicId,
    });
    
    return {
      'roles': roles,
      'permissions': permissions,
      'ownerId': ownerId,
      'clinicIds': clinicIds,
      'primaryClinicId': primaryClinicId,
    };
  }

  /// Saves authentication tokens (accessToken, idToken) to local storage.
  Future<void> saveAuthentication(
      {String? accessToken, String? idToken}) async {
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
  Future<UserModel?> getCurrentUser() async {
    // cast the current user to a UserModel object
    final user = _firebaseAuth.currentUser;
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
      // Optionally, you may want to fetch roles/permissions from Firestore here if needed
    );
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
        // Optionally, you may want to fetch roles/permissions from Firestore here if needed
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
