import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gps_app/services/user_location.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:gps_app/services/input_location.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final _key = GlobalKey<ExpandableFabState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  static CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId("source"),
      position: LatLng(37.42796133580664, -122.085749655962)
    )
  };

  void goToMyLocation() async {
    await UserLocation().getMyLocation();
    double lon = UserLocation().lon;
    double lat = UserLocation().lat;

    setState(() {
      _initialPosition = CameraPosition(
        target: LatLng(lat, lon),
        zoom: 15
      );
      _markers = {
        Marker(
          markerId: const MarkerId("source"),
          position: LatLng(lat, lon),
        )
      };
    });

    GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lon),
          zoom: 15,
        )
      )
    );
  }

  Future<void> saveHomeAddress(Map<String, dynamic> place) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setDouble('homeLat', place['geometry']['location']['lat']);
    preferences.setDouble('homeLon', place['geometry']['location']['lng']);
  }

  Future<void> loadHomeAddress() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    double? homeLat = preferences.getDouble('homeLat');
    double? homeLon = preferences.getDouble('homeLon');

    if (homeLat != null && homeLon != null) {
      setState(() {
        _initialPosition = CameraPosition(
            target: LatLng(homeLon, homeLat),
            zoom: 15
        );
        _markers = {
          Marker(
            markerId: const MarkerId("source"),
            position: LatLng(homeLat, homeLon),
          )
        };
      });
      GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(homeLat, homeLon),
            zoom: 15,
          )
        )
      );
    }
  }

  Future<void> goToInputPlace(Map<String, dynamic> place) async {
    final double lat = place['geometry']['location']['lat'];
    final double lon = place['geometry']['location']['lng'];
    final GoogleMapController controller = await _controller.future;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("destination"),
          position: LatLng(lat, lon),
        )
      };
    });

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lon),
          zoom: 15,
        )
      )
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // goToMyLocation();
    loadHomeAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
          children: [
            GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _initialPosition,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: _markers
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
            ),
          ],
        ),
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton: ExpandableFab(
          key: _key,
          type: ExpandableFabType.fan,
          pos: ExpandableFabPos.left,
          distance: 100.0,
          children: [
            FloatingActionButton.small(
              onPressed: () {
                goToMyLocation();
                _key.currentState?.toggle();
              },
              child: const Icon(
                  Icons.my_location
              ),
            ),
            FloatingActionButton.small(
              onPressed: () {
                _searchFocusNode.requestFocus();
                _key.currentState?.toggle();
              },
              child: const Icon(
                  Icons.search
              ),
            ),
            FloatingActionButton.small(
              onPressed: () {
                _key.currentState?.toggle();
              },
              child: const Icon(
                Icons.telegram
              )
            ),
            FloatingActionButton.small(
              onPressed: () async{
                _key.currentState?.toggle();
                var place = await InputLocation().getPlace(_searchController.text);
                saveHomeAddress(place);
              },
              child: const Icon(
                Icons.home
              )
            )
          ],
        ),
    );
  }
}