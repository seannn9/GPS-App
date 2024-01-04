import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gps_app/services/user_location.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:gps_app/services/input_location.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final _key = GlobalKey<ExpandableFabState>();
  TextEditingController _searchController = TextEditingController();
  FocusNode _searchFocusNode = FocusNode();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  void getMyLocation() async {
    await Location().getMyLocation();
    double lon = Location().lon;
    double lat = Location().lat;
    GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lon),
          zoom: 14.4746,
        )
      )
    );
  }

  Future<void> goToInputPlace(Map<String, dynamic> place) async {
    final double lat = place['geometry']['location']['lat'];
    final double lon = place['geometry']['location']['lng'];
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lon),
          zoom: 14.4746,
        )
      )
    );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _kGooglePlex,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
            Positioned(
              top: 40.0,
              left: 20.0,
              right: 20.0,
              child: Column(
                children: [
                  Container(
                    height: 50.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.white
                    ),
                    child: TextFormField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      style: const TextStyle(
                        color: Colors.black
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                        hintText: "Search",
                        hintStyle: const TextStyle(
                          color: Colors.grey
                        ),
                        border: InputBorder.none,
                        suffixIcon: IconButton(
                          onPressed: () async{
                           var place = await InputLocation().getPlace(_searchController.text);
                           FocusManager.instance.primaryFocus?.unfocus();
                           goToInputPlace(place);
                          },
                          icon: const Icon(
                            Icons.search,
                            color: Colors.blue,
                          ),
                        )
                      ),
                    ),
                  )
                ],
              )
            )
          ],
        ),
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton: ExpandableFab(
          key: _key,
          type: ExpandableFabType.fan,
          pos: ExpandableFabPos.left,
          distance: 75.0,
          children: [
            FloatingActionButton.small(
              onPressed: getMyLocation,
              child: const Icon(
                  Icons.my_location
              ),
            ),
            FloatingActionButton.small(
              onPressed: () {
                _searchFocusNode.requestFocus();
              },
              child: const Icon(
                  Icons.search
              ),
            )
          ],
        )
    );
  }
}