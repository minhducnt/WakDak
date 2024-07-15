import 'package:hive/hive.dart';

import 'package:wakDak/utils/hiveBoxKey.dart';

class ProfileManagementLocalDataSource {
  String getName() {
    return Hive.box(userDetailsBox).get(nameBoxKey, defaultValue: "");
  }

  String getUserUID() {
    return Hive.box(userDetailsBox).get(userUIdBoxKey, defaultValue: "");
  }

  String getEmail() {
    return Hive.box(userDetailsBox).get(emailBoxKey, defaultValue: "");
  }

  String getMobileNumber() {
    return Hive.box(userDetailsBox).get(mobileNumberBoxKey, defaultValue: "");
  }

  String getProfileUrl() {
    return Hive.box(userDetailsBox).get(profileUrlBoxKey, defaultValue: "");
  }

  String getFirebaseId() {
    return Hive.box(userDetailsBox).get(firebaseIdBoxKey, defaultValue: "");
  }

  String getReferCode() {
    return Hive.box(userDetailsBox).get(referCodeBoxKey, defaultValue: "");
  }

  String getFCMToken() {
    return Hive.box(userDetailsBox).get(fcmTokenBoxKey, defaultValue: "");
  }

  Future<void> setEmail(String email) async {
    Hive.box(userDetailsBox).put(emailBoxKey, email);
  }

  Future<void> setUserUId(String userId) async {
    Hive.box(userDetailsBox).put(userUIdBoxKey, userId);
  }

  Future<void> setName(String name) async {
    Hive.box(userDetailsBox).put(nameBoxKey, name);
  }

  Future<void> serProfileUrl(String profileUrl) async {
    Hive.box(userDetailsBox).put(profileUrlBoxKey, profileUrl);
  }

  Future<void> setMobileNumber(String mobileNumber) async {
    Hive.box(userDetailsBox).put(mobileNumberBoxKey, mobileNumber);
  }

  Future<void> setFirebaseId(String firebaseId) async {
    Hive.box(userDetailsBox).put(firebaseIdBoxKey, firebaseId);
  }

  Future<void> setReferCode(String referCode) async {
    Hive.box(userDetailsBox).put(referCodeBoxKey, referCode);
  }

  Future<void> setFCMToken(String fcmToken) async {
    Hive.box(userDetailsBox).put(fcmTokenBoxKey, fcmToken);
  }
}
