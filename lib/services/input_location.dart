import 'dart:developer';

import 'package:http/http.dart';
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:gps_app/services/user_location.dart';

class InputLocation {
  final String key = 'AIzaSyCDFIZrPYdUO7la8j3khAgVQFbGQ7ld9Pk';

  Future<String> getPlaceId(String input) async {
    Uri url = Uri.parse('https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$input&inputtype=textquery&key=$key');
    Response response = await get(url);
    var data = response.body;
    String placeId = jsonDecode(data)['candidates'][0]['place_id'];
    return placeId;
  }

  Future<Map<String, dynamic>> getPlace(String input) async {
    final placeId = await getPlaceId(input);
    Uri url = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$key');
    Response response = await get(url);
    var data = response.body;
    Map<String, dynamic> place = jsonDecode(data)['result'];
    return place;
  }

  Future <Map<String, dynamic>> getDirection(String source, String destination) async{
    Uri url = Uri.parse('https://maps.googleapis.com/maps/api/directions/json?origin=$source&destination=$destination&key=$key');
    Response response = await get(url);
    var data = response.body;
    var results = {
      'bounds_ne': jsonDecode(data)['routes'][0]['bounds']['northeast'],
      'bounds_sw': jsonDecode(data)['routes'][0]['bounds']['southwest'],
      'start_location': jsonDecode(data)['routes'][0]['legs'][0]['start_location'],
      'end_location': jsonDecode(data)['routes'][0]['legs'][0]['end_location'],
      'polyline': jsonDecode(data)['routes'][0]['overview_polyline']['points'],
      'polyline_decoded' : PolylinePoints().decodePolyline(jsonDecode(data)['routes'][0]['overview_polyline']['points']),
      'distance' : jsonDecode(data)['routes'][0]['legs'][0]['distance.text'],
      'duration' : jsonDecode(data)['routes'][0]['legs'][0]['duration.text']
    };
    return results;

  }
}