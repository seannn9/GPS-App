import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gps_app/services/user_location.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:gps_app/services/input_location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  final _key = GlobalKey<ExpandableFabState>();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Set<Polyline> _polylines = Set<Polyline>();
  int _polylineCounter = 1;

  bool _showDestinationSearch = false;
  bool _showTrackingFab = false;

  Location _locationController = new Location();
  LatLng? _currentPosition = null;

  StreamSubscription<LocationData>? _locationSubscription;
  bool _isLocationUpdateActive = false;

  String? _currentAddress;

  // shows the destination search bar and the toggle FAB (getLocationUpdate)
  void clickGpsButton() {
    stopLocationUpdates();
    setState(() {
      _showDestinationSearch = !_showDestinationSearch;
      _showTrackingFab = _showDestinationSearch;
    });

    if (!_showDestinationSearch) {
      _markers.removeWhere((marker) => marker.markerId.value == "source");
    }
  }

  // processes the direction api to make a polyline
  void setPolyline(List<PointLatLng> points) {
    _polylines.clear();
    final String polylineIdVal = 'polyline$_polylineCounter';
    _polylineCounter++;

    _polylines.add(
      Polyline(polylineId: PolylineId(polylineIdVal),
      width: 4,
      color: Colors.blue,
      points: points.map(
          (point) => LatLng(point.latitude, point.longitude)
      ).toList(),
    ));
  }

  // initial camera position if user doesn't have a home saved
  static CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  // initial markers if no home is saved
  Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId("source"),
      position: LatLng(37.42796133580664, -122.085749655962)
    )
  };

  // gets the user's current location using geolocator
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
          markerId: const MarkerId("user"),
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

  // enables user to set their current location as home (what the app defaults to when opening)
  Future<void> saveCurrentLocationAsHome(double lat, double lon) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setDouble('homeLat', lat);
    preferences.setDouble('homeLon', lon);
  }

  // enables user to save any address as home
  Future<void> saveHomeAddress(Map<String, dynamic> place) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.setDouble('homeLat', place['geometry']['location']['lat']);
    preferences.setDouble('homeLon', place['geometry']['location']['lng']);
  }

  // loads whatever location is stored in home (initState)
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

  // goes to the location that the user inputs
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

  // shows the polyline between the source and the location
  Future<void> startGpsRoute(double sLat, double sLon, double dLat, double dLon, Map<String, dynamic> boundsNe, Map<String, dynamic> boundsSw) async{
    final GoogleMapController controller = await _controller.future;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId("source"),
          position: LatLng(sLat, sLon),
        ),
        Marker(
          markerId: const MarkerId("destination"),
          position: LatLng(dLat, dLon)
        )
      };
    });

    await controller.animateCamera(
        CameraUpdate.newLatLngBounds(LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng'])
        ), 25)
    );
  }

  // For updating the location of the user (marker) in the map
  Future<void> getLocationUpdate() async{
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    var directions = await InputLocation().getDirection(_searchController.text, _destinationController.text);

    _serviceEnabled = await _locationController.serviceEnabled();
    if (_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationSubscription?.cancel();

    _locationSubscription = _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _markers = {
            Marker(
              markerId: const MarkerId("user"),
              position: _currentPosition!,
            ),
            if (_showDestinationSearch)
              if (_searchController.text.isEmpty)
                Marker(
                    markerId: const MarkerId("source"),
                    position: _currentPosition!,
                ),
              if (_searchController.text.isNotEmpty)
                Marker(
                  markerId: const MarkerId("source"),
                  position: LatLng(directions['start_location']['lat'], directions['start_location']['lng'])
                ),
            Marker(
              markerId: const MarkerId("destination"),
              position: LatLng(directions['end_location']['lat'], directions['end_location']['lng'])
            )
          };
          print(_currentPosition);
        });
      }
    });
  }

  // Stop the live updates from getLocationUpdate
  void stopLocationUpdates() {
    _locationSubscription?.cancel();
  }

  // Updates the FAB's icon and function (start and stop location update)
  void toggleLocationUpdate() {
    if (_isLocationUpdateActive) {
      stopLocationUpdates();
    } else {
      getLocationUpdate();
    }

    setState(() {
      _isLocationUpdateActive = !_isLocationUpdateActive;
    });
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
              markers: _markers,
              polylines: _polylines,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
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
                        hintText: _showDestinationSearch ? "Origin" : "Search",
                        hintStyle: const TextStyle(
                          color: Colors.grey
                        ),
                        border: InputBorder.none,
                        suffixIcon: _showDestinationSearch ? null :
                        IconButton(
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
                  ),
                  if (_showDestinationSearch)
                    Container(
                      height: 50.0,
                      margin: const EdgeInsets.only(top: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.0),
                        color: Colors.white,
                      ),
                      child: TextFormField(
                        controller: _destinationController,
                        style: const TextStyle(
                          color: Colors.black
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                          hintText: "Destination",
                          hintStyle: const TextStyle(
                            color: Colors.grey
                          ),
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            onPressed: () async{
                              if (_searchController.text.isEmpty) {
                                await UserLocation().getMyLocation();
                                double lat = UserLocation().lat;
                                double lon = UserLocation().lon;
                                _currentAddress = "$lat,$lon";
                              } else {
                                _currentAddress = _searchController.text;
                              }
                              var directions = await InputLocation().getDirection(_currentAddress!, _destinationController.text);
                              FocusManager.instance.primaryFocus?.unfocus();
                              startGpsRoute(directions['start_location']['lat'], directions['start_location']['lng'],
                                  directions['end_location']['lat'], directions['end_location']['lng'],
                                  directions['bounds_ne'], directions['bounds_sw']);
                              setPolyline(directions['polyline_decoded']);
                            },
                            icon: const Icon(
                              Icons.directions
                            ),
                          )
                        ),
                      )
                    ),
                ],
              )
            ),
            if (_showTrackingFab)
              Container(
                margin: const EdgeInsets.all(15.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    backgroundColor: _isLocationUpdateActive? Colors.red: Colors.green,
                    onPressed: () {
                      toggleLocationUpdate();
                    },
                    child: _isLocationUpdateActive? const Icon(Icons.exit_to_app)
                        : const Icon(Icons.telegram)
                  )
                ),
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
                if (_showDestinationSearch) {
                  clickGpsButton();
                  if (_isLocationUpdateActive) {
                    setState(() {
                      _isLocationUpdateActive = !_isLocationUpdateActive;
                    });
                  }
                }
                _searchFocusNode.requestFocus();
                _key.currentState?.toggle();
              },
              child: const Icon(
                  Icons.search
              ),
            ),
            FloatingActionButton.small(
              onPressed: () {
                clickGpsButton();
                _polylines.clear();
                _markers.removeWhere((marker) => marker.markerId.value == "destination");
                _key.currentState?.toggle();
              },
              child: const Icon(
                Icons.directions
              )
            ),
            FloatingActionButton.small(
              onPressed: () async{
                _key.currentState?.toggle();
                if (_searchController.text.isEmpty) {
                  await UserLocation().getMyLocation();
                  saveCurrentLocationAsHome(UserLocation().lat, UserLocation().lon);
                } else {
                  var place = await InputLocation().getPlace(_searchController.text);
                  saveHomeAddress(place);
                }
                _searchController.clear();
                _destinationController.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    content: AwesomeSnackbarContent(
                      title: 'Success!',
                      message: 'Successfully set location as home address',
                      contentType: ContentType.success,
                    )
                  )
                );
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