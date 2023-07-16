import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:route_planner/constants/places.dart';

import '../helpers/shared_prefs.dart';
import '../screens/map_screen.dart';

class placesTable extends StatefulWidget {
  const placesTable({Key? key}) : super(key: key);

  @override
  State<placesTable> createState() => _placesTableState();
}

class _placesTableState extends State<placesTable> {
  late String searchQuery;
  List<Map<String, dynamic>> filteredPlaces = [];

  @override
  void initState() {
    super.initState();
    searchQuery = '';
    filterPlaces();
  }

  void filterPlaces() {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredPlaces = List.from(places);
      } else {
        filteredPlaces = places.where((place) {
          final name = place['name'].toString().toLowerCase();
          return name.contains(searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  Widget buildSearchField() {
    return CupertinoTextField(
      prefix: const Padding(
        padding: EdgeInsets.only(left: 15),
        child: Icon(Icons.search),
      ),
      padding: const EdgeInsets.all(15),
      placeholder: 'Search place name',
      style: const TextStyle(color: Colors.white),
      decoration: const BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
      onChanged: (value) {
        setState(() {
          searchQuery = value;
          filterPlaces();
        });
      },
    );
  }

  Widget buildPlacesList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: filteredPlaces.length,
      itemBuilder: (BuildContext context, int index) {
        final place = filteredPlaces[index];
        return SizedBox(
          height: 160, // specify your desired height
          width: 140, // specify your desired width
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  height: 175, // new height
                  width: 140, // new width
                  fit: BoxFit.cover,
                  imageUrl: place['image'],
                ),
                Expanded(
                  child: Container(
                    height: 175,
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Row(
                          children: [
                            cardButtons(
                              Icons.location_on,
                              'Map',
                              index,
                            ),
                            const Spacer(),
                            Text(
                                '${(getDistanceFromSharedPrefs(index) / 1000).toStringAsFixed(2)}km'),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget cardButtons(IconData iconData, String label, int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlacesMap(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(5),
          minimumSize: Size.zero,
        ),
        child: Row(
          children: [
            Icon(iconData, size: 16),
            const SizedBox(width: 2),
            Text(label)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Planner UUM'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildSearchField(),
                const SizedBox(height: 5),
                buildPlacesList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
