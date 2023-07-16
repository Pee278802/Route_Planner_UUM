import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:route_planner/helpers/commons.dart';
import 'package:route_planner/helpers/directions_handler.dart';

import '../constants/places.dart';
import '../helpers/shared_prefs.dart';
import '../widgets/carousel_card.dart';

class PlacesMap extends StatefulWidget {
  const PlacesMap({Key? key}) : super(key: key);

  @override
  State<PlacesMap> createState() => _PlacesMapState();
}

class _PlacesMapState extends State<PlacesMap> {
  String currentMapStyle = MapboxStyles.MAPBOX_STREETS;
  late CameraPosition initialCameraPosition;
  late MapboxMapController controller;
  late List<CameraPosition> placeCameraPositions;
  List<Map> carouselData = [];

  int selectedCardIndex = 0;

  void toggleMapStyle() {
    setState(() {
      currentMapStyle = currentMapStyle == MapboxStyles.MAPBOX_STREETS
          ? MapboxStyles.SATELLITE
          : MapboxStyles.MAPBOX_STREETS;
    });
  }

  @override
  void initState() {
    super.initState();
    initialCameraPosition =
        CameraPosition(target: getLatLngFromSharedPrefs(), zoom: 15);

    for (int index = 0; index < places.length; index++) {
      num distance = getDistanceFromSharedPrefs(index) / 1000;
      num duration = getDurationFromSharedPrefs(index) / 60;
      carouselData
          .add({'index': index, 'distance': distance, 'duration': duration});
    }

    // carouselData.sort((a, b) => a['duration'].compareTo(b['duration']));

    carouselItems = List<Widget>.generate(
      places.length,
      (index) => carouselCard(
        carouselData[index]['index'],
        carouselData[index]['distance'],
        carouselData[index]['duration'],
      ),
    );

    placeCameraPositions = List<CameraPosition>.generate(
      places.length,
      (index) => CameraPosition(
        target: getLatLngFromplaceData(carouselData[index]['index']),
        zoom: 15,
      ),
    );
  }

  _addSourceAndLineLayer(int index, bool removeLayer) async {
    controller.animateCamera(
        CameraUpdate.newCameraPosition(placeCameraPositions[index]));

    Map geometry = getGeometryFromSharedPrefs(carouselData[index]['index']);
    final _fills = {
      "type": "FeatureCollection",
      "features": [
        {
          "type": "Feature",
          "id": 0,
          "properties": <String, dynamic>{},
          "geometry": geometry,
        },
      ],
    };

    if (removeLayer) {
      await controller.removeLayer("lines");
      await controller.removeSource("fills");
    }

    await controller.addSource("fills", GeojsonSourceProperties(data: _fills));
    await controller.addLineLayer(
      "fills",
      "lines",
      LineLayerProperties(
        lineColor: Colors.green.toHexStringRGB(),
        lineCap: "round",
        lineJoin: "round",
        lineWidth: 2,
      ),
    );
  }

  _onMapCreated(MapboxMapController controller) {
    this.controller = controller;
  }

  _onStyleLoadedCallback() async {
    for (CameraPosition placeCameraPosition in placeCameraPositions) {
      await controller.addSymbol(
        SymbolOptions(
          geometry: placeCameraPosition.target,
          iconSize: 0.1,
          iconImage: "assets/icon/dkg.png",
        ),
      );
    }

    if (selectedCardIndex < carouselData.length) {
      Location location = Location();
      LocationData locationData = await location.getLocation();
      LatLng userLocation =
          LatLng(locationData.latitude!, locationData.longitude!);
      Map directions =
          await getDirectionsAPIResponse(userLocation, selectedCardIndex);
      saveDirectionsAPIResponse(selectedCardIndex, json.encode(directions));

      setState(() {
        carouselData[selectedCardIndex]['distance'] =
            directions['distance'] / 1000;
        carouselData[selectedCardIndex]['duration'] =
            directions['duration'] / 60;
      });

      _addSourceAndLineLayer(selectedCardIndex, true);
    }
  }

  _updateRouteWithUserLocation() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();

    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData locationData = await location.getLocation();
    LatLng userLocation =
        LatLng(locationData.latitude!, locationData.longitude!);

    Map directions =
        await getDirectionsAPIResponse(userLocation, selectedCardIndex);
    saveDirectionsAPIResponse(selectedCardIndex, json.encode(directions));

    setState(() {
      carouselData[selectedCardIndex]['distance'] =
          directions['distance'] / 1000;
      carouselData[selectedCardIndex]['duration'] = directions['duration'] / 60;
    });

    _addSourceAndLineLayer(selectedCardIndex, true);
  }

  _focusOnUserLocation() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    PermissionStatus permissionGranted = await location.hasPermission();

    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    LocationData locationData = await location.getLocation();
    LatLng userLocation =
        LatLng(locationData.latitude!, locationData.longitude!);

    if (selectedCardIndex < carouselData.length) {
      Map directions =
          await getDirectionsAPIResponse(userLocation, selectedCardIndex);
      saveDirectionsAPIResponse(selectedCardIndex, json.encode(directions));

      setState(() {
        carouselData[selectedCardIndex]['distance'] =
            directions['distance'] / 1000;
        carouselData[selectedCardIndex]['duration'] =
            directions['duration'] / 60;
      });

      _addSourceAndLineLayer(selectedCardIndex, true);
    }

    controller.animateCamera(CameraUpdate.newLatLng(userLocation));
  }

  List<Widget> carouselItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Planner UUM'),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  kBottomNavigationBarHeight,
              child: MapboxMap(
                accessToken: dotenv.env['MAPBOX_ACCESS_TOKEN'],
                initialCameraPosition: initialCameraPosition,
                onMapCreated: _onMapCreated,
                onStyleLoadedCallback: _onStyleLoadedCallback,
                myLocationEnabled: true,
                myLocationTrackingMode: MyLocationTrackingMode.TrackingGPS,
                minMaxZoomPreference: const MinMaxZoomPreference(14, 17),
                styleString: currentMapStyle,
              ),
            ),
            CarouselSlider(
              items: carouselItems,
              options: CarouselOptions(
                height: 100,
                viewportFraction: 0.6,
                initialPage: 0,
                enableInfiniteScroll: false,
                scrollDirection: Axis.horizontal,
                onPageChanged:
                    (int index, CarouselPageChangedReason reason) async {
                  setState(() {
                    selectedCardIndex = index;
                  });
                  _addSourceAndLineLayer(index, true);
                  await _updateRouteWithUserLocation();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'floatingButton1',
            onPressed: _focusOnUserLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'floatingButton2',
            onPressed: toggleMapStyle,
            child: const Icon(Icons.satellite_alt),
          ),
        ],
      ),
    );
  }
}
