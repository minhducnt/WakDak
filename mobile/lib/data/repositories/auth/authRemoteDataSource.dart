import 'dart:io';
import 'dart:math';

import 'package:apple_sign_in_safety/apple_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart' as fcm;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/data/localDataStore/authLocalDataSource.dart';
import 'package:wakDak/utils/api.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';
import 'package:wakDak/utils/apiMessageException.dart';
import 'package:wakDak/utils/constants.dart';
import 'package:wakDak/utils/string.dart';

class AuthRemoteDataSource {
  int count = 1;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

// To addUser
  Future<dynamic> addUser(
      {String? name,
      String? email,
      String? mobile,
      String? countryCode,
      String? fcmId,
      String? friendCode,
      String? referCode}) async {
    try {
      String fcmToken = await getFCMToken();
      // Body of post request
      final body = {
        nameKey: name,
        emailKey: email,
        mobileKey: mobile,
        countryCodeKey: countryCode ?? "",
        referralCodeKey: referCode ?? "",
        fcmIdKey: fcmToken,
        friendCodeKey: friendCode ?? ""
      };
      final result = await Api.post(body: body, url: Api.registerUserUrl, token: false, errorCode: false);
      AuthLocalDataSource.setJwtToken(result['token']);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  // To addUser
  Future<dynamic> socialLogIn(
      {String? name, String? email, String? mobile, String? countryCode, String? fcmId, String? friendCode, String? referCode, String? type}) async {
    try {
      // referEarn();
      String fcmToken = await getFCMToken();
      //body of post request
      final body = {
        nameKey: name!.trim() == "" ? "User" : name,
        emailKey: email,
        mobileKey: mobile,
        countryCodeKey: countryCode ?? "",
        referralCodeKey: referCode ?? "",
        fcmIdKey: fcmToken,
        friendCodeKey: friendCode ?? "",
        typeKey: type ?? "",
      };
      final result = await Api.post(body: body, url: Api.signUpUrl, token: false, errorCode: false);
      AuthLocalDataSource.setJwtToken(result['token']);
      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  final chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  Random rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));

  // To referEarn
  Future referEarn(String? referCode) async {
    try {
      // Body of post request
      final body = {referralCodeKey: referCode};
      final result = await Api.post(body: body, url: Api.validateReferCodeUrl, token: false, errorCode: false);
      if (!result[errorKey]) {
        referCode = referCode;
      } else {
        if (count < 5) referEarn(referCode);
        count++;
      }

      return result;
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  // To loginUser
  Future<dynamic> signInUser({String? mobile}) async {
    try {
      String fcmToken = await getFCMToken();
      // Body of post request
      final body = {mobileKey: mobile, fcmIdKey: fcmToken};
      final result = await Api.post(body: body, url: Api.loginUrl, token: false, errorCode: false);
      if (result[errorKey] == true) {
        throw ApiMessageException(errorMessage: result[messageKey]);
      }
      AuthLocalDataSource.setJwtToken(result['token']);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  // To delete my account
  Future<bool> deleteMyAccount(String userId) async {
    try {
      final body = {
        userIdKey: userId,
      };
      final result = await Api.post(body: body, url: Api.deleteMyAccountUrl, token: true, errorCode: true);
      if (result[errorKey]) {
        // If user does not exist means
        if (result['message'] == tokenExpireCode) {
          return false;
        }
        throw ApiMessageAndCodeException(errorMessage: result[messageKey], errorStatusCode: result[statusCodeKey].toString());
      }
      return true;
    } catch (e) {
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  // To update fcmId of user's
  Future<dynamic> updateFcmId({String? userId, String? fcmId}) async {
    try {
      // Body of post request
      final body = {userIdKey: userId, fcmIdKey: fcmId};
      final result = await Api.post(body: body, url: Api.updateFcmUrl, token: true, errorCode: false);
      return result[dataKey];
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  Future<String> getFCMToken() async {
    try {
      return await fcm.FirebaseMessaging.instance.getToken() ?? "";
    } catch (e) {
      return "";
    }
  }

  // SignIn user will accept AuthProvider (enum)
  Future<Map<String, dynamic>> socialSignInUser(
      AuthProviders authProvider 
      ) async {
    // user credential contains information of signing user and is user new or not
    Map<String, dynamic> result = {};

    try {
      if (authProvider == AuthProviders.google) {
        UserCredential userCredential = await signInWithGoogle();

        result['user'] = userCredential.user!;
        result['isNewUser'] = userCredential.additionalUserInfo!.isNewUser;
      } else if (authProvider == AuthProviders.phone) {
      } else if (authProvider == AuthProviders.apple) {
        UserCredential userCredential = await signInWithApple();
        result['user'] = _firebaseAuth.currentUser!;
        result['isNewUser'] = userCredential.additionalUserInfo!.isNewUser;
      }
      return result;
    } on SocketException catch (_) {
      throw ApiMessageException(errorMessage: StringsRes.noInternet);
    }
    // firebase auth errors
    on FirebaseAuthException catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    } on ApiMessageException catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  // signIn using google account
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw ApiMessageException(errorMessage: defaultErrorMessage);
    }
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
    return userCredential;
  }

  Future<UserCredential> signInWithApple() async {
    try {
      final AuthorizationResult appleResult = await AppleSignIn.performRequests([
        const AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
      ]);

      if (appleResult.status == AuthorizationStatus.authorized) {
        final appleIdCredential = appleResult.credential!;
        final oAuthProvider = OAuthProvider('apple.com');
        final credential = oAuthProvider.credential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken!),
          accessToken: String.fromCharCodes(appleIdCredential.authorizationCode!),
        );
        final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
        if (userCredential.additionalUserInfo!.isNewUser) {
          final user = userCredential.user!;
          final String givenName = appleIdCredential.fullName!.givenName ?? "";

          final String familyName = appleIdCredential.fullName!.familyName ?? "";
          await user.updateDisplayName("$givenName $familyName");
          await user.reload();
        }

        return userCredential;
      } else if (appleResult.status == AuthorizationStatus.error) {
        throw ApiMessageException(errorMessage: defaultErrorMessage);
      } else {
        throw ApiMessageException(errorMessage: defaultErrorMessage);
      }
    } catch (error) {
      throw ApiMessageException(errorMessage: error.toString());
    }
  }

  Future<void> signOut(AuthProviders? authProvider) async {
    _firebaseAuth.signOut();
    if (authProvider == AuthProviders.google) {
      _googleSignIn.signOut();
    } else if (AuthProviders.apple == AuthProviders.apple) {}
  }
}
