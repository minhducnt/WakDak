import 'package:firebase_auth/firebase_auth.dart';

import 'package:wakDak/cubit/auth/authCubit.dart';
import 'package:wakDak/data/localDataStore/authLocalDataSource.dart';
import 'package:wakDak/data/repositories/auth/authRemoteDataSource.dart';
import 'package:wakDak/utils/apiBodyParameterLabels.dart';
import 'package:wakDak/utils/apiMessageAndCodeException.dart';
import 'package:wakDak/utils/apiMessageException.dart';

class AuthRepository {
  static final AuthRepository _authRepository = AuthRepository._internal();
  late AuthLocalDataSource _authLocalDataSource;
  late AuthRemoteDataSource _authRemoteDataSource;

  factory AuthRepository() {
    _authRepository._authLocalDataSource = AuthLocalDataSource();
    _authRepository._authRemoteDataSource = AuthRemoteDataSource();
    return _authRepository;
  }
  AuthRepository._internal();
  AuthLocalDataSource get authLocalDataSource => _authLocalDataSource;
  //to get auth detials stored in hive box
  getLocalAuthDetails() {
    return {
      "isLogin": _authLocalDataSource.checkIsAuth(),
      "id": _authLocalDataSource.getId(),
      "ip_address": _authLocalDataSource.getIpAddress(),
      "username": _authLocalDataSource.getName(),
      "email": _authLocalDataSource.getEmail(),
      "mobile": _authLocalDataSource.getMobile(),
      "type": _authLocalDataSource.getType(),
      "image": _authLocalDataSource.getImage(),
      "balance": _authLocalDataSource.getBalance(),
      "rating": _authLocalDataSource.getRating(),
      "no_of_ratings": _authLocalDataSource.getNoOfRatings(),
      "activation_selector": _authLocalDataSource.getActivationSelector(),
      "activation_code": _authLocalDataSource.getActivationCode(),
      "forgotten_password_selector": _authLocalDataSource.getForgottenPasswordSelector(),
      "forgotten_password_code": _authLocalDataSource.getForgottenPasswordCode(),
      "forgotten_password_time": _authLocalDataSource.getForgottenPasswordTime(),
      "remember_selector": _authLocalDataSource.getRememberSelector(),
      "remember_code": _authLocalDataSource.getRememberCode(),
      "created_on": _authLocalDataSource.getCreatedOn(),
      "last_login": _authLocalDataSource.getLastLogin(),
      "active": _authLocalDataSource.getActive(),
      "company": _authLocalDataSource.getCompany(),
      "address": _authLocalDataSource.getAddress(),
      "bonus": _authLocalDataSource.getBonus(),
      "dob": _authLocalDataSource.getDob(),
      "country_code": _authLocalDataSource.getCountryCode(),
      "city": _authLocalDataSource.getCity(),
      "area": _authLocalDataSource.getArea(),
      "street": _authLocalDataSource.getStreet(),
      "pincode": _authLocalDataSource.getPinCode(),
      "serviceable_city": _authLocalDataSource.getServiceableCity(),
      "apikey": _authLocalDataSource.getApikey(),
      "referral_code": _authLocalDataSource.getReferralCode(),
      "friends_code": _authLocalDataSource.getFriendsCode(),
      "fcm_id": _authLocalDataSource.getFcmId(),
      "latitude": _authLocalDataSource.getLatitude(),
      "longitude": _authLocalDataSource.getLongitude(),
      "created_at": _authLocalDataSource.getCreatedAt()
    };
  }

  setLocalAuthDetails({
    bool? authStatus,
    String? id,
    String? ipAddress,
    String? name,
    String? email,
    String? mobile,
    String? type,
    String? image,
    String? balance,
    String? rating,
    String? noOfRatings,
    String? activationSelector,
    String? activationCode,
    String? forgottenPasswordSelector,
    String? forgottenPasswordCode,
    String? forgottenPasswordTime,
    String? rememberSelector,
    String? rememberCode,
    String? createdOn,
    String? lastLogin,
    String? active,
    String? company,
    String? address,
    String? bonus,
    String? dob,
    String? countryCode,
    String? city,
    String? area,
    String? street,
    String? pincode,
    String? serviceableCity,
    String? referralCode,
    String? friendsCode,
    String? fcmId,
    String? latitude,
    String? longitude,
    String? createdAt,
  }) {
    _authLocalDataSource.changeAuthStatus(authStatus);
    _authLocalDataSource.setId(id);
    _authLocalDataSource.setIpAddress(ipAddress);
    _authLocalDataSource.setName(name);
    _authLocalDataSource.setEmail(email);
    _authLocalDataSource.setMobile(mobile);
    _authLocalDataSource.setType(type);
    _authLocalDataSource.setImage(image);
    _authLocalDataSource.setBalance(balance);
    _authLocalDataSource.setRating(rating);
    _authLocalDataSource.setNoOfRatings(noOfRatings);
    _authLocalDataSource.setActivationSelector(activationSelector);
    _authLocalDataSource.setActivationCode(activationCode);
    _authLocalDataSource.setForgottenPasswordSelector(forgottenPasswordSelector);
    _authLocalDataSource.setForgottenPasswordCode(forgottenPasswordCode);
    _authLocalDataSource.setForgottenPasswordTime(forgottenPasswordTime);
    _authLocalDataSource.setRememberSelector(rememberSelector);
    _authLocalDataSource.setRememberCode(rememberCode);
    _authLocalDataSource.setCreatedOn(createdOn);
    _authLocalDataSource.setLastLogin(lastLogin);
    _authLocalDataSource.setActive(active);
    _authLocalDataSource.setCompany(company);
    _authLocalDataSource.setAddress(address);
    _authLocalDataSource.setBonus(bonus);
    _authLocalDataSource.setDob(dob);
    _authLocalDataSource.setCountryCode(countryCode);
    _authLocalDataSource.setCity(city);
    _authLocalDataSource.setArea(area);
    _authLocalDataSource.setStreet(street);
    _authLocalDataSource.setPinCode(pincode);
    _authLocalDataSource.setServiceableCity(serviceableCity);
    _authLocalDataSource.setReferralCode(referralCode);
    _authLocalDataSource.setFriendsCode(friendsCode);
    _authLocalDataSource.setFcmId(fcmId);
    _authLocalDataSource.setLatitude(latitude);
    _authLocalDataSource.setLongitude(longitude);
    _authLocalDataSource.setCreatedAt(createdAt);
  }

  //to add user's data to database. This will be in use when authenticating using phoneNumber
  Future<Map<String, dynamic>> addUserData({
    String? name,
    String? email,
    String? mobile,
    String? countryCode,
    String? fcmId,
    String? friendCode,
    String? referCode,
  }) async {
    final result = await _authRemoteDataSource.addUser(
        name: name,
        email: email,
        mobile: mobile,
        countryCode: countryCode ?? "",
        fcmId: fcmId ?? "",
        friendCode: friendCode ?? "",
        referCode: referCode );
    await _authLocalDataSource.setId(result['id']);
    await _authLocalDataSource.changeAuthStatus(true);
    await _authLocalDataSource.setName(result['username']);
    await _authLocalDataSource.setEmail(result['email']);
    await _authLocalDataSource.setMobile(result['mobile']);
    await _authLocalDataSource.setType(result['type']);
    await _authLocalDataSource.setImage(result['image']);
    await _authLocalDataSource.setActive(result['active']);
    await _authLocalDataSource.setCompany(result['company']);
    await _authLocalDataSource.setAddress(result['address']);
    await _authLocalDataSource.setCountryCode(result['country_code']);
    await _authLocalDataSource.setCity(result['city']);
    await _authLocalDataSource.setArea(result['area']);
    await _authLocalDataSource.setStreet(result['street']);
    await _authLocalDataSource.setPinCode(result['pincode']);
    await _authLocalDataSource.setServiceableCity(result['serviceable_city']);
    await _authLocalDataSource.setReferralCode(result['referral_code']);
    await _authLocalDataSource.setFriendsCode(result['friends_code']);
    await _authLocalDataSource.setFcmId(result['fcm_id']);
    await _authLocalDataSource.setLatitude(result['latitude']);
    await _authLocalDataSource.setLongitude(result['longitude']);
    return Map.from(result);
  }

  //to login user's data to database. This will be in use when authenticating using phoneNumber
  Future<Map<String, dynamic>> login({String? mobile}) async {
    try {
      setLocalAuthDetails();
      final result = await _authRemoteDataSource.signInUser(mobile: mobile);
      await _authLocalDataSource.setId(result['id']);
      await _authLocalDataSource.changeAuthStatus(true);
      await _authLocalDataSource.setName(result['username']);
      await _authLocalDataSource.setEmail(result['email']);
      await _authLocalDataSource.setMobile(result['mobile']);
      await _authLocalDataSource.setType(result['type']);
      await _authLocalDataSource.setImage(result['image']);
      await _authLocalDataSource.setActive(result['active']);
      await _authLocalDataSource.setCompany(result['company']);
      await _authLocalDataSource.setAddress(result['address']);
      await _authLocalDataSource.setCountryCode(result['country_code']);
      await _authLocalDataSource.setCity(result['city']);
      await _authLocalDataSource.setArea(result['area']);
      await _authLocalDataSource.setStreet(result['street']);
      await _authLocalDataSource.setPinCode(result['pincode']);
      await _authLocalDataSource.setServiceableCity(result['serviceable_city']);
      await _authLocalDataSource.setReferralCode(result['referral_code']);
      await _authLocalDataSource.setFriendsCode(result['friends_code']);
      await _authLocalDataSource.setFcmId(result['fcm_id']);
      await _authLocalDataSource.setLatitude(result['latitude']);
      await _authLocalDataSource.setLongitude(result['longitude']);
      return Map.from(result); //
    } on ApiMessageException catch (e) {
      ApiMessageException apiMessageAndCodeException = e;
      throw ApiMessageException(errorMessage: apiMessageAndCodeException.errorMessage.toString());
    } catch (e) {
      print(e.toString());
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  //to update fcmId user's data to database. This will be in use when authenticating using fcmId
  Future<Map<String, dynamic>> updateFcmId({String? userId, String? fcmId}) async {
    final result = await _authRemoteDataSource.updateFcmId(userId: userId, fcmId: fcmId);
    await _authLocalDataSource.changeAuthStatus(false);
    return Map.from(result); //
  }

  //to delete my account
  Future<bool> deleteMyAccount({String? userId}) async {
    try {
      final result = await _authRemoteDataSource.deleteMyAccount(userId!);
      print(result);
      return result; //
    } on ApiMessageAndCodeException catch (e) {
      ApiMessageAndCodeException apiMessageAndCodeException = e;
      throw ApiMessageAndCodeException(
          errorMessage: apiMessageAndCodeException.errorMessage.toString(), errorStatusCode: apiMessageAndCodeException.errorStatusCode.toString());
    } catch (e) {
      print(e);
      throw ApiMessageAndCodeException(errorMessage: e.toString());
    }
  }

  //refer and earn
  Future<String> geReferAndEarn(String? referCode) async {
    try {
      final result = await _authRemoteDataSource.referEarn(referCode);
      return Map.from(result).toString();
    } catch (e) {
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  Future<void> signOut(AuthProviders authProvider) async {
    _authRemoteDataSource.signOut(authProvider);
    await _authLocalDataSource.changeAuthStatus(false);
    await _authLocalDataSource.setId("");
    await _authLocalDataSource.setName("");
    await _authLocalDataSource.setEmail("");
    await _authLocalDataSource.setMobile("");
    await _authLocalDataSource.setType("");
    await _authLocalDataSource.setImage("");
    await _authLocalDataSource.setActive("");
    await _authLocalDataSource.setCompany("");
    await _authLocalDataSource.setAddress("");
    await _authLocalDataSource.setCountryCode("");
    await _authLocalDataSource.setCity("");
    await _authLocalDataSource.setArea("");
    await _authLocalDataSource.setStreet("");
    await _authLocalDataSource.setPinCode("");
    await _authLocalDataSource.setServiceableCity("");
    await _authLocalDataSource.setReferralCode("");
    await _authLocalDataSource.setFriendsCode("");
    await _authLocalDataSource.setFcmId("");
    await _authLocalDataSource.setLatitude("");
    await _authLocalDataSource.setLongitude("");
    await AuthLocalDataSource.setJwtToken("");
  }

  //First we signin user with given provider then add user details
  Future<Map<String, dynamic>> signInUser(AuthProviders authProvider, String? referCode, String? friendCode) async {
    try {
      final result = await _authRemoteDataSource.socialSignInUser(
        authProvider,
      );
      final user = result['user'] as User;
      var registeredUser = await _authRemoteDataSource.socialLogIn(
        email: user.email ?? "",
        mobile: user.phoneNumber ?? "",
        name: user.displayName ?? "",
        type: getAuthTypeString(authProvider),
        referCode: referCode,
        friendCode: friendCode,
        countryCode: "",
      );
      if (registeredUser[errorKey] == true) {
        registeredUser = _authRemoteDataSource.socialLogIn(email: user.email);
        await _authLocalDataSource.setId(registeredUser[dataKey]['id']);
        await _authLocalDataSource.changeAuthStatus(true);
        await _authLocalDataSource.setName(registeredUser[dataKey]['username']);
        await _authLocalDataSource.setEmail(registeredUser[dataKey]['email']);
        await _authLocalDataSource.setMobile(registeredUser[dataKey]['mobile']);
        await _authLocalDataSource.setType(registeredUser[dataKey]['type']);
        await _authLocalDataSource.setImage(registeredUser[dataKey]['image']);
        await _authLocalDataSource.setActive(registeredUser[dataKey]['active']);
        await _authLocalDataSource.setCompany(registeredUser[dataKey]['company']);
        await _authLocalDataSource.setAddress(registeredUser['address']);
        await _authLocalDataSource.setCountryCode(registeredUser['country_code']);
        await _authLocalDataSource.setCity(registeredUser[dataKey]['city']);
        await _authLocalDataSource.setArea(registeredUser[dataKey]['area']);
        await _authLocalDataSource.setStreet(registeredUser[dataKey]['street']);
        await _authLocalDataSource.setPinCode(registeredUser[dataKey]['pincode']);
        await _authLocalDataSource.setServiceableCity(registeredUser[dataKey]['serviceable_city']);
        await _authLocalDataSource.setReferralCode(registeredUser[dataKey]['referral_code']);
        await _authLocalDataSource.setFriendsCode(registeredUser[dataKey]['friends_code']);
        await _authLocalDataSource.setFcmId(registeredUser[dataKey]['fcm_id']);
        await _authLocalDataSource.setLatitude(registeredUser[dataKey]['latitude']);
        await _authLocalDataSource.setLongitude(registeredUser[dataKey]['longitude']);
        await AuthLocalDataSource.setJwtToken(registeredUser['token'].toString());
      } else {
        await _authLocalDataSource.setId(registeredUser[dataKey]['id']);
        await _authLocalDataSource.changeAuthStatus(true);
        await _authLocalDataSource.setName(registeredUser[dataKey]['username']);
        await _authLocalDataSource.setEmail(registeredUser[dataKey]['email']);
        await _authLocalDataSource.setMobile(registeredUser[dataKey]['mobile']);
        await _authLocalDataSource.setType(registeredUser[dataKey]['type']);
        await _authLocalDataSource.setImage(registeredUser[dataKey]['image']);
        await _authLocalDataSource.setActive(registeredUser[dataKey]['active']);
        await _authLocalDataSource.setCompany(registeredUser[dataKey]['company']);
        await _authLocalDataSource.setAddress(registeredUser['address']);
        await _authLocalDataSource.setCountryCode(registeredUser['country_code']);
        await _authLocalDataSource.setCity(registeredUser[dataKey]['city']);
        await _authLocalDataSource.setArea(registeredUser[dataKey]['area']);
        await _authLocalDataSource.setStreet(registeredUser[dataKey]['street']);
        await _authLocalDataSource.setPinCode(registeredUser[dataKey]['pincode']);
        await _authLocalDataSource.setServiceableCity(registeredUser[dataKey]['serviceable_city']);
        await _authLocalDataSource.setReferralCode(registeredUser[dataKey]['referral_code']);
        await _authLocalDataSource.setFriendsCode(registeredUser[dataKey]['friends_code']);
        await _authLocalDataSource.setFcmId(registeredUser[dataKey]['fcm_id']);
        await _authLocalDataSource.setLatitude(registeredUser[dataKey]['latitude']);
        await _authLocalDataSource.setLongitude(registeredUser[dataKey]['longitude']);
        await AuthLocalDataSource.setJwtToken(registeredUser['token'].toString());
      }

      return registeredUser;
    } catch (e) {
      print(e.toString());
      signOut(authProvider);
      throw ApiMessageException(errorMessage: e.toString());
    }
  }

  String getAuthTypeString(AuthProviders provider) {
    String authType;
    if (provider == AuthProviders.google) {
      authType = "google";
    } else {
      authType = "apple";
    }
    return authType;
  }
}
