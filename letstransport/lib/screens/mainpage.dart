import 'package:letstransport/helpers/firehelper.dart';
import 'package:letstransport/datamodels/nearbydriver.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:letstransport/datamodels/directiondetails.dart';
import 'package:letstransport/dataprovider/appdata.dart';
import 'package:letstransport/globalvariable.dart';
import 'package:letstransport/screens/searchpage.dart';
import 'package:letstransport/styles/styles.dart';
import 'package:letstransport/widgets/BrandDivider.dart';
import 'package:letstransport/widgets/ProgressDialog.dart';
import 'package:letstransport/widgets/TaxiButton.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:letstransport/brand_colors.dart';
import 'dart:io';
import 'package:letstransport/helpers/helpermethods.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  static const String id = 'mainpage';

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  //defining global key to use it for showing items in the drawer when menu button is clicked
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  double searchSheetHeight = (Platform.isIOS) ? 300 : 275;
  double rideDetailsSheetHeight = 0; //{Platform.isAndroid} ? 235 : 260
  double requestingSheetHeight = 0; //(Platform.isAndroid) ? 195 : 220

  Completer<GoogleMapController> _controller = Completer();
  GoogleMapController
      mapController; //creating new instance of googlemapcontroller
  double mapBottomPadding = 0;

  List<LatLng> polylineCoordinates = [];
  //we can have more than one polyline displayed on our map at the same time
  //if we have more than one polyline, we will add each of the polyline inside the set
  //in the end we will assign this set to the map, and then our polylines will show up
  Set<Polyline> _polylines = {};
  Set<Marker> _Markers = {};
  Set<Circle> _Circles = {};

  BitmapDescriptor nearbyIcon;
  //instance of current position
  var geoLocator = Geolocator();
  Position currentPosition;

  DirectionDetails tripDirectiondetails;

  //boolean var to control when we can open drawer
  bool drawerCanOpen = true;

  DatabaseReference rideRef;

  bool nearbyDriversKeysLoaded = false;

  //method to retrieve current location
  void setupPositionLocator() async {
    Position position = await geoLocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPosition = position;

    //after getting the current location we need to move the map to this location
    LatLng pos = LatLng(position.latitude, position.longitude);
    //new camerapostion object(how far we want it to be zoomed)
    CameraPosition cp = CameraPosition(target: pos, zoom: 14);
    mapController.animateCamera(CameraUpdate.newCameraPosition(cp));

    startGeofireListener();
  }

  //method to set searchSheetHeight as 0 and rideDetailsSheetHeight as 235 or 260
  void showDetailSheet() async {
    await getDirection();

    setState(() {
      searchSheetHeight = 0;
      rideDetailsSheetHeight = (Platform.isAndroid) ? 235 : 260;
      mapBottomPadding = (Platform.isAndroid) ? 240 : 230;
      drawerCanOpen = false;
    });
  }

  void showRequestingSheet() {
    setState(() {
      rideDetailsSheetHeight = 0;
      requestingSheetHeight = (Platform.isAndroid) ? 195 : 220;
      mapBottomPadding = (Platform.isAndroid) ? 200 : 190;

      drawerCanOpen = true;
    });
    createRideRequest();
  }

  void createMarker() {
    if (nearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'images/car_android.png')
          .then((icon) {
        nearbyIcon = icon;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    HelperMethods.getCurrentUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    createMarker();
    return Scaffold(
        key: scaffoldKey,
        drawer: Container(
            width: 250,
            color: Colors.white,
            child: Drawer(
              child: ListView(
                padding: EdgeInsets.all(0),
                children: [
                  Container(
                    color: Colors.white,
                    height: 160,
                    child: DrawerHeader(
                      decoration: BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'images/user_icon.png',
                            height: 60,
                            width: 60,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Ranjan',
                                style: TextStyle(
                                    fontSize: 20, fontFamily: 'Brand-Bold'),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Text('View Profile')
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  BrandDivider(),
                  SizedBox(
                    height: 10,
                  ),
                  ListTile(
                    leading: Icon(OMIcons.cardGiftcard),
                    title: Text('Free Rides', style: kDrawerItemStyle),
                  ),
                  ListTile(
                    leading: Icon(OMIcons.creditCard),
                    title: Text('Payments', style: kDrawerItemStyle),
                  ),
                  ListTile(
                    leading: Icon(OMIcons.history),
                    title: Text('Ride History', style: kDrawerItemStyle),
                  ),
                  ListTile(
                    leading: Icon(OMIcons.contactSupport),
                    title: Text('Support', style: kDrawerItemStyle),
                  ),
                  ListTile(
                    leading: Icon(OMIcons.info),
                    title: Text('About', style: kDrawerItemStyle),
                  ),
                ],
              ),
            )),

        //as shown in the mainpage, the widgets will on top of each other
        //thatswhy used stack
        body: Stack(
          children: [
            GoogleMap(
              //padding the google map to get in the buttons onto the map
              padding: EdgeInsets.only(bottom: mapBottomPadding),
              mapType: MapType.normal,
              myLocationButtonEnabled: true,
              initialCameraPosition: googlePlex,

              //for the blue dot set below three to true
              myLocationEnabled: true,
              zoomGesturesEnabled: true,
              zoomControlsEnabled: true,
              polylines: _polylines,
              markers: _Markers,
              circles: _Circles,
              //below function executes as soon as our map is ready
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
                /*
                controller is the instance of the GoogleMapController
                and with this controller we can make futher changes to our google map(add markers or change camera position)
                 */
                //global mapcontroller == instance of the map created
                mapController = controller;

                setState(() {
                  mapBottomPadding = (Platform.isAndroid) ? 280 : 270;
                });

                //calling the function as soon as our map is ready
                setupPositionLocator();
              },
            ),

            //wrapping container with positioned to place it at bottom

            ///MenuBotton
            Positioned(
              top: 44,
              left: 20,
              child: GestureDetector(
                onTap: () {
                  if (drawerCanOpen) {
                    scaffoldKey.currentState.openDrawer();
                  } else {
                    resetApp();
                  }
                },
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 5.0,
                              spreadRadius: 0.5,
                              offset: Offset(
                                0.7,
                                0.7,
                              ))
                        ]),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: Icon(
                        (drawerCanOpen) ? Icons.menu : Icons.arrow_back,
                        color: Colors.black87,
                      ),
                    )),
              ),
            ),

            /// SearchSheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSize(
                vsync: this,
                duration: new Duration(milliseconds: 150),
                curve: Curves.easeIn,
                child: Container(
                  height: searchSheetHeight,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15)),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15.0,
                            spreadRadius: 0.5,
                            offset: Offset(
                              0.7,
                              0.7,
                            ))
                      ]),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Nice to see you!',
                          style: TextStyle(fontSize: 10.0),
                        ),
                        Text(
                          'Where are you going?',
                          style:
                              TextStyle(fontSize: 18, fontFamily: 'Brand-Bold'),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        GestureDetector(
                          onTap: () async {
                            //as soon as searchpage is closed, it will give a response
                            var response = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SearchPage()));

                            if (response == 'getDirection') {
                              showDetailSheet();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 5.0,
                                      spreadRadius: 0.5,
                                      offset: Offset(
                                        0.7,
                                        0.7,
                                      ))
                                ]),
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.blueAccent,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text('Search Destination'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 22,
                        ),
                        Row(
                          children: [
                            Icon(
                              OMIcons.home,
                              color: BrandColors.colorDimText,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add Home'),
                                SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  'Your Residential Address',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: BrandColors.colorDimText),
                                )
                              ],
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        BrandDivider(),
                        SizedBox(
                          height: 16,
                        ),
                        Row(
                          children: [
                            Icon(
                              OMIcons.workOutline,
                              color: BrandColors.colorDimText,
                            ),
                            SizedBox(
                              width: 12,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add Work'),
                                SizedBox(
                                  height: 3,
                                ),
                                Text(
                                  'Your Office Address',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: BrandColors.colorDimText),
                                )
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            ///RideDetails Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSize(
                vsync: this,
                duration: new Duration(
                  milliseconds: 150,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 15.0, //soften the shadow
                          spreadRadius: 0.5, //extend the shadow
                          offset: Offset(
                              0.7, //Move to right 10 horizontally
                              0.7 //Move to botttom 10 vertically
                              ))
                    ],
                  ),
                  height: rideDetailsSheetHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: BrandColors.colorAccent1,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Image.asset(
                                  'images/taxi.png',
                                  height: 70,
                                  width: 70,
                                ),
                                SizedBox(
                                  width: 16,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Taxi',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontFamily: 'Brand-Bold')),
                                    Text(
                                        (tripDirectiondetails != null)
                                            ? tripDirectiondetails.distanceText
                                            : '',
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: BrandColors.colorTextLight)),
                                  ],
                                ),
                                Expanded(child: Container()),
                                Text(
                                  (tripDirectiondetails != null)
                                      ? '\$${HelperMethods.estimateFares(tripDirectiondetails)}'
                                      : '',
                                  style: TextStyle(
                                      fontSize: 18, fontFamily: 'Brand-Bold'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 22,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(FontAwesomeIcons.moneyBillAlt,
                                  size: 18, color: BrandColors.colorTextLight),
                              SizedBox(
                                width: 16,
                              ),
                              Text('Cash'),
                              SizedBox(
                                width: 5,
                              ),
                              Icon(Icons.keyboard_arrow_down,
                                  color: BrandColors.colorTextLight, size: 16),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: TaxiButton(
                            title: 'REQUEST CAB',
                            color: BrandColors.colorGreen,
                            onPressed: () {
                              showRequestingSheet();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            ///Request Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedSize(
                vsync: this,
                duration: new Duration(milliseconds: 150),
                curve: Curves.easeIn,
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15.0,
                              spreadRadius: 0.5,
                              offset: Offset(
                                0.7,
                                0.7,
                              ))
                        ]),
                    height: requestingSheetHeight,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextLiquidFill(
                                text: 'Requesting a Ride...',
                                waveColor: BrandColors.colorTextSemiLight,
                                boxBackgroundColor: Colors.white,
                                textStyle: TextStyle(
                                    fontSize: 22.0, fontFamily: 'Brand-Bold'),
                                boxHeight: 40.0,
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            GestureDetector(
                              onTap: () {
                                cancelRequest();
                                resetApp();
                              },
                              child: Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                      width: 1.0,
                                      color: BrandColors.colorLightGray),
                                ),
                                child: Icon(Icons.close, size: 25),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: double.infinity,
                              child: Text(
                                'Cancel Ride',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            )
                          ]),
                    )),
              ),
            ),
          ],
        ));
  }

  Future<void> getDirection() async {
    //getting pickup and destination address from data provider class
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;

    //retrieve coordiantes of pickup and destination

    var pickLatLng = LatLng(pickup.latitude, pickup.longitude);
    var destinationLatLng = LatLng(destination.latitude, destination.longitude);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) =>
          ProgressDialog(status: 'Please wait...'),
    );
    var thisDetails =
        await HelperMethods.getDirectionDetails(pickLatLng, destinationLatLng);

    setState(() {
      tripDirectiondetails = thisDetails;
    });
    Navigator.pop(context); //popping off progress dialog

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> results =
        polylinePoints.decodePolyline(thisDetails.encodedPoints);

    polylineCoordinates.clear();
    if (results.isNotEmpty) {
      //loop through all PointLatLng points and convert them
      //to a list of LatLng, required by the Polyline
      //will add to the list of polyline coordinates

      results.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    _polylines
        .clear(); //clearing before adding new ones(just making sure everything runs fine)
    setState(() {
      //creating instance of polyline
      Polyline polyline = Polyline(
        polylineId: PolylineId('polyid'),
        color: Color.fromARGB(255, 95, 109, 237),
        points: polylineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      //now add this polyline instance in the set
      _polylines.add(polyline);
    });

    //make polyline to fit into the map

    LatLngBounds bounds;

    if (pickLatLng.latitude > destinationLatLng.latitude &&
        pickLatLng.longitude > destinationLatLng.longitude) {
      bounds =
          LatLngBounds(southwest: destinationLatLng, northeast: pickLatLng);
    } else if (pickLatLng.longitude > destinationLatLng.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
          northeast: LatLng(destinationLatLng.latitude, pickLatLng.longitude));
    } else if (pickLatLng.latitude > destinationLatLng.latitude) {
      bounds = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, pickLatLng.longitude),
        northeast: LatLng(pickLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      bounds =
          LatLngBounds(southwest: pickLatLng, northeast: destinationLatLng);
    }

    mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 70));

    Marker pickupMarker = Marker(
      markerId: MarkerId('pickup'),
      position: pickLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: pickup.placeName, snippet: 'My Location'),
    );

    Marker destinationMarker = Marker(
      markerId: MarkerId('destination'),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow:
          InfoWindow(title: destination.placeName, snippet: 'Destination'),
    );

    //add into the markers set
    setState(() {
      _Markers.add(pickupMarker);
      _Markers.add(destinationMarker);
    });

    Circle pickupCircle = Circle(
      circleId: CircleId('pickup'),
      strokeColor: Colors.green,
      strokeWidth: 3,
      radius: 12,
      center: pickLatLng,
      fillColor: BrandColors.colorGreen,
    );

    Circle destinationCircle = Circle(
        circleId: CircleId('destination'),
        strokeColor: BrandColors.colorAccentPurple,
        strokeWidth: 3,
        radius: 12,
        center: destinationLatLng,
        fillColor: BrandColors.colorAccentPurple);

    //add to the circle set

    setState(() {
      _Circles.add(pickupCircle);
      _Circles.add(destinationCircle);
    });
  }

  void startGeofireListener() {
    Geofire.initialize('driversAvailable');
    //range of 20 km
    Geofire.queryAtLocation(
            currentPosition.latitude, currentPosition.longitude, 20)
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire
              .onKeyEntered: //triggered whenever a new key matches our query
            NearbyDriver nearbyDriver = NearbyDriver();
            //map['latitude'] & map['longitude'] format of geofire
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];

            FireHelper.nearbyDriverList.add(nearbyDriver);
            if (nearbyDriversKeysLoaded) {
              updateDriversOnMap();
            }
            break;

          case Geofire.onKeyExited: //triggered when key(driver) is removed
            FireHelper.removeFromList(map['key']);

            updateDriversOnMap();
            break;

          case Geofire
              .onKeyMoved: //triggered when location is updated of the moving driver
            // Update your key's location
            NearbyDriver nearbyDriver = NearbyDriver();
            nearbyDriver.key = map['key'];
            nearbyDriver.latitude = map['latitude'];
            nearbyDriver.longitude = map['longitude'];

            FireHelper.updateNearbyLocation(nearbyDriver);
            updateDriversOnMap();
            break;

          case Geofire
              .onGeoQueryReady: //triggered when initial data has been completely loaded
            nearbyDriversKeysLoaded = true;
            updateDriversOnMap();
            break;
        }
      }
    });
  }

  //add markers on map to display nearby drivers
  void updateDriversOnMap() {
    setState(() {
      _Markers.clear();
    });
    Set<Marker> tempMarkers = Set<Marker>();

    //retrieve lat and long of nearby drivers available
    //these lat and long will prove to be the positions of the markers
    for (NearbyDriver driver in FireHelper.nearbyDriverList) {
      LatLng driverPosition = LatLng(driver.latitude, driver.longitude);

      //create new marker
      Marker thisMarker = Marker(
        markerId: MarkerId('driver${driver.key}'),
        position: driverPosition,
        icon: nearbyIcon,
        //need roation to be randomized b/w 0 to 360
        rotation: HelperMethods.generateRandomNumber(360),
      );

      //look for all nearby drivers and add their markers in this tempMarkers
      tempMarkers.add(thisMarker);
    }

    setState(() {
      _Markers = tempMarkers;
    });
  }

  //put necessary info about trip and save it in a separate table in a firebase db
  void createRideRequest() {
    //reference where the info about this trip is going to be saved
    rideRef = FirebaseDatabase.instance.reference().child('rideRequest').push();

    //info about trip
    var pickup = Provider.of<AppData>(context, listen: false).pickupAddress;
    var destination =
        Provider.of<AppData>(context, listen: false).destinationAddress;
    Map pickupMap = {
      'latitude': pickup.latitude.toString(),
      'longitude': pickup.longitude.toString(),
    };

    Map destinationMap = {
      'latitude': destination.latitude.toString(),
      'longitude': destination.longitude.toString(),
    };

    //map assembling all info for this trip
    Map rideMap = {
      'created_at': DateTime.now().toString(),
      'rider_name': currentUserInfo.fullName,
      'rider_phone': currentUserInfo.phone,
      'pickup_address': pickup.placeName,
      'destination_address': destination.placeName,
      'location': pickupMap,
      'destination': destinationMap,
      'payment_method': 'card',
      'driver_id': 'waiting',
    };

    //set this map to rife reference
    rideRef.set(rideMap);
  }

  //cancelling a ride request
  void cancelRequest() {
    rideRef.remove();
  }

  //method to reset our app; will check if drawerCanOpen is true or false
  //to determine which method to call when we click menu button
  resetApp() {
    setState(() {
      polylineCoordinates.clear();
      _polylines.clear();
      _Markers.clear();
      _Circles.clear();
      rideDetailsSheetHeight = 0;
      requestingSheetHeight = 0;
      searchSheetHeight = (Platform.isAndroid) ? 275 : 300;
      mapBottomPadding = (Platform.isAndroid) ? 280 : 270;

      drawerCanOpen = true;
      setupPositionLocator();
    });
  }

  //wrap searchsheet and ridedetailsheet inside an animatedsize
  //whenever we draw polyline on the map, we will set the height
  //of the searchsheet as 0
  //simple animation will be played when it is being hidden

}
