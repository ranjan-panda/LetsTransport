//dataprovider folder includes : all the files that has to do data handling
import 'package:flutter/cupertino.dart';
import 'package:letstransport/datamodels/address.dart';

//this is the useful information that we want to access anywhere from the app achieving it through provider package
class AppData extends ChangeNotifier {
  //saving pick up address info in provider class
  Address pickupAddress;
  //it's value now available throughout the app

  Address destinationAddress;
  void updatePickupAddress(Address pickup) {
    pickupAddress = pickup;
    //after updating, will now notify all the listeners
    notifyListeners();
  }

  void updateDestinationAddress(Address destination) {
    destinationAddress = destination;
    notifyListeners();
  }
}
