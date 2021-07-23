
import 'package:cab_driver/widgets/NotificationDialog.dart';
import 'package:flutter/material.dart';
import 'package:cab_driver/widgets/ProgressDialog.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cab_driver/globalvariables.dart';
import 'dart:io';
import 'package:cab_driver/datamodels/tripdetails.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

//for configuring firebase messaging(push notifications)
//two imp methods over here: i) initialize method
//ii) firebase reg token
class PushNotificationService {
  final FirebaseMessaging fcm = FirebaseMessaging();
  Future initialize(context) async {
    fcm.configure(
      //this occurs when we receive push notification when our app is in use
      onMessage: (Map<String, dynamic> message) async {
        fetchRideInfo(getRideID(message), context);
      },

      //app is not running; user taps on notification tray and app opens
      //up and triggers the onLaunch switch
      onLaunch: (Map<String, dynamic> message) async {
        fetchRideInfo(getRideID(message), context);
      },

      //app is in background
      onResume: (Map<String, dynamic> message) async {
        fetchRideInfo(getRideID(message), context);
        // getRideID(message);
      },
    );
  }

  //token identfies every single device
  Future<String> getToken() async {
    String token = await fcm.getToken();
    print('token: $token');

    //we'll be using this token to send particular notification to
    //every single driver, we save this in driver's profile db
    DatabaseReference tokenRef = FirebaseDatabase.instance
        .reference()
        .child('drivers/${currentFirebaseUser.uid}/token');
    tokenRef.set(token);
    //subscribe every driver to a particular topic
    fcm.subscribeToTopic('alldrivers');
    fcm.subscribeToTopic('allusers');
  }

  String getRideID(Map<String, dynamic> message) {
    String rideID = '';

    if (Platform.isAndroid) {
      String rideID = message['data']['ride_id'];
      print('ride_id: $rideID');
    }

    return rideID;
  }

  //retrieve ride info
  void fetchRideInfo(String rideID, context) {
    showDialog(
        //to make the dialog non-dismissable
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              status: 'Fetching Details',
            ));
    DatabaseReference rideRef =
        FirebaseDatabase.instance.reference().child('rideRequest/$rideID');
    rideRef.once().then((DataSnapshot snapshot) {
      Navigator.pop(context);
      if (snapshot.value != null) {

        // assetsAudioPlayer.open(
        //   Audio('sounds/alert.mp3'),
        // );
        // assetsAudioPlayer.play();
        var obj = snapshot.value.entries.elementAt(0).value;

        double pickupLat =
            double.parse(obj['location']['longitude'].toString());
        double pickupLng = double.parse(obj['location']['latitude'].toString());
        double destinationLat =
            double.parse(obj['destination']['latitude'].toString());
        double destinationLng =
            double.parse(obj['destination']['longitude'].toString());
        String paymentMethod = obj['payment_method'];
        String pickupAddress = obj['pickup_address'].toString();

        String destinationAddress = obj['destination_address'];

        TripDetails tripDetails = TripDetails();
        tripDetails.rideID = rideID;
        tripDetails.pickupAddress = pickupAddress;
        tripDetails.destinationAddress = destinationAddress;
        tripDetails.pickup = LatLng(pickupLat, pickupLng);
        tripDetails.destination = LatLng(destinationLat, destinationLng);
        tripDetails.paymentMethod = paymentMethod;

        print(tripDetails.destinationAddress);

        showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) => NotificationDialog(tripDetails: tripDetails,),
                  );
      }
    });
  }
}
