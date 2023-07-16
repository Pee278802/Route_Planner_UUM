import 'package:mapbox_gl/mapbox_gl.dart';

import '../constants/places.dart';

LatLng getLatLngFromplaceData(int index) {
  return LatLng(double.parse(places[index]['coordinates']['latitude']),
      double.parse(places[index]['coordinates']['longitude']));
}
