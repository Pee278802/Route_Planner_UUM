import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:route_planner/main.dart';

import '../constants/places.dart';
import '../requests/mapbox_requests.dart';

Future<Map> getDirectionsAPIResponse(LatLng currentLatLng, int index) async {
  final response = await getWalkingRouteUsingMapbox(
      currentLatLng,
      LatLng(double.parse(places[index]['coordinates']['latitude']),
          double.parse(places[index]['coordinates']['longitude'])));
  Map geometry = response['routes'][0]['geometry'];
  num duration = response['routes'][0]['duration'];
  num distance = response['routes'][0]['distance'];
  print('-------------------${places[index]['name']}-------------------');
  print(distance);
  print(duration);

  Map modifiedResponse = {
    "geometry": geometry,
    "duration": duration,
    "distance": distance,
  };
  return modifiedResponse;
}

// Future<Map?> getDirectionsAPIResponse(LatLng currentLatLng, int index) async {
//   var response = await getCyclingRouteUsingMapbox(
//       currentLatLng,
//       LatLng(double.parse(places[index]['coordinates']['latitude']),
//           double.parse(places[index]['coordinates']['longitude'])));

//   // Check if the response is null or doesn't contain the "routes" key
//   if (response != null &&
//       response.containsKey("routes") &&
//       response["routes"].isNotEmpty) {
//     Map geometry = response['routes'][0]['geometry'];
//     num duration = response['routes'][0]['duration'];
//     num distance = response['routes'][0]['distance'];
//     print(
//         '-------------------${places[index]['name']}-------------------');
//     print(distance);
//     print(duration);

//     Map modifiedResponse = {
//       "geometry": geometry,
//       "duration": duration,
//       "distance": distance,
//     };
//     return modifiedResponse;
//   } else {
//     // Handle the case when the response is null or doesn't contain "routes"
//     return null; // Or you can return an empty Map, depending on your requirements
//   }
// }

void saveDirectionsAPIResponse(int index, String response) {
  sharedPreferences.setString('place--$index', response);
}
