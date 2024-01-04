import 'package:geolocator/geolocator.dart';

class Location {
  double lon = 0, lat = 0;

  static final Location _instance = Location._internal();

  factory Location() {
    return _instance;
  }

  Location._internal();

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