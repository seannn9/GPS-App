import 'package:geolocator/geolocator.dart';

class UserLocation {
  double lon = 0, lat = 0;

  static final UserLocation _instance = UserLocation._internal();

  factory UserLocation() {
    return _instance;
  }

  UserLocation._internal();

  Future getMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation
      );
      lon = position.longitude;
      lat = position.latitude;
    } catch(e) {
      print(e);
    }
  }

}