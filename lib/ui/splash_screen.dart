import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:route_planner/constants/places.dart';
import 'package:route_planner/helpers/directions_handler.dart';
import 'package:route_planner/main.dart';

import '../screens/home.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  void initState() {
    super.initState();
    initializeLocationAndSave();
  }

  void initializeLocationAndSave() async {
    // Ensure all permissions are collected for Locations
    // declaring 3 variables
    // ? means variable can be null
    Location _location = Location();
    bool? _serviceEnabled;
    PermissionStatus? _permissionGranted;

    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
    }

    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
    }

    // Get capture the current user location
    LocationData _locationData = await _location.getLocation();
    LatLng currentLatLng =
        //! means make sure the latitude and longitude is not null
        LatLng(_locationData.latitude!, _locationData.longitude!);

    // Store the user location in sharedPreferences
    sharedPreferences.setDouble('latitude', _locationData.latitude!);
    sharedPreferences.setDouble('longitude', _locationData.longitude!);

    // Get and store the directions API response in sharedPreferences
    for (int i = 0; i < places.length; i++) {
      Map modifiedResponse = await getDirectionsAPIResponse(currentLatLng, i);
      saveDirectionsAPIResponse(i, json.encode(modifiedResponse));
    }
    // for (int i = 0; i < places.length; i++) {
    //   Map? modifiedResponse = await getDirectionsAPIResponse(currentLatLng, i);
    //   saveDirectionsAPIResponse(i, json.encode(modifiedResponse));
    // }

    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeManagement()),
        (route) => false);
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Material(
  //     color: Colors.white,
  //     child: Center(child: Image.asset('assets/image/splash.png')),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Image.asset('assets/image/splash.png', scale: 0.9),
          const Text("Route Planner UUM",
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 50,
          ),
          const SizedBox(
            height: 35,
            width: 35,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(
            height: 120,
          ),
          const Text("Version 1.0"),
        ]),
      ),
    );
  }
}
