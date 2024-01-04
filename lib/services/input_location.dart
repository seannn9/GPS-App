import 'package:http/http.dart';
import 'dart:convert';

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
}