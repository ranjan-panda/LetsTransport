import 'dart:async';
import 'package:cab_driver/brand_colors.dart';
import 'package:cab_driver/globalvariables.dart';
import 'package:cab_driver/helpers/pushnotificationservice.dart';
import 'package:cab_driver/widgets/AvailabilityButton.dart';
import 'package:cab_driver/widgets/confirmsheet.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeTab extends StatefulWidget {
  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  GoogleMapController mapController;
  Completer<GoogleMapController> _controller = Completer();

  Position currentPosition;

  var geoLocator = Geolocator();
  var locationOptions = LocationOptions(
      accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 4);

  String availabilityTitle = 'GO ONLINE';
  Color availabilityColor = BrandColors.colorOrange;

  bool isAvailable = false;

  void getCurrentPosition() async {
    Position position = await Geolocator().getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPosition = position;

    LatLng pos = LatLng(position.latitude, position.longitude);

    mapController.animateCamera(CameraUpdate.newLatLng(pos));
  }

  void getCurrentDriveInfo() async {
    currentFirebaseUser = await FirebaseAuth.instance.currentUser();
    PushNotificationService pushNotificationService = PushNotificationService();

    pushNotificationService.initialize(context);
    pushNotificationService.getToken();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentDriveInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          padding: EdgeInsets.only(top: 135),
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          mapType: MapType.normal,
          initialCameraPosition: googlePlex,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
            mapController = controller;

            getCurrentPosition();
          },
        ),
        Container(
          height: 135,
          width: double.infinity,
          color: BrandColors.colorPrimary,
        ),
        Positioned(
          top: 60,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AvailabilityButton(
                title: availabilityTitle,
                color: availabilityColor,
                onPressed: () {
                  showModalBottomSheet(
                      isDismissible: false,
                      context: context,
                      builder: (BuildContext context) => ConfirmSheet(
                            title: (!isAvailable) ? 'GO ONLINE' : 'GO OFFLINE',
                            subtitle: (!isAvailable)
                                ? 'You are about to become available to receive trip requests'
                                : 'You will stop receiving new trip requests',
                            onPressed: () {
                              if (!isAvailable) {
                                GoOnline();
                                getLocationUpdates();
                                Navigator.pop(context);

                                setState(() {
                                  availabilityColor = BrandColors.colorGreen;
                                  availabilityTitle = 'GO OFFLINE';
                                  isAvailable = true;
                                });
                              } else {
                                GoOffline();
                                Navigator.pop(context);
                                setState(() {
                                  availabilityColor = BrandColors.colorOrange;
                                  availabilityTitle = 'GO ONLINE';
                                  isAvailable = false;
                                });
                              }
                            },
                          ));
                },
              ),
            ],
          ),
        )
      ],
    );
  }

  void GoOnline() {
    Geofire.initialize('driversAvailable');
    //first param is the firebase user id which acts as the key
    // to identify the driver on the location data
    Geofire.setLocation(currentFirebaseUser.uid, currentPosition.latitude,
        currentPosition.longitude);

    //create new db reference; used to know when rider is assigned to us
    tripRequestRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${currentFirebaseUser.uid}/newtrip');

    tripRequestRef.set('waiting');

    //going to listen to events at this particular reference
    tripRequestRef.onValue.listen((event) {});
  }

  //driver's instance from the driversAvailable should be removed
  void GoOffline() {
    Geofire.removeLocation(currentFirebaseUser.uid);
    //disconnect the particular listener
    tripRequestRef.onDisconnect();
    tripRequestRef.remove();
    tripRequestRef = null;
  }

  void getLocationUpdates() {
    //will start listening to location changes
    homeTabPositionStream = geoLocator
        .getPositionStream(locationOptions)
        .listen((Position position) {
      //returns an instance of position
      currentPosition = position;
      //updating location in firebase db, that too only when we are available
      if (isAvailable) {
        Geofire.setLocation(
            currentFirebaseUser.uid, position.latitude, position.longitude);
      }

      //whenever location update, we need our camera to move a little bit
      LatLng pos = LatLng(position.latitude, position.longitude);

      mapController.animateCamera(CameraUpdate.newLatLng(pos));
    });
  }
}
