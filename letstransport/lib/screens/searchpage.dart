import 'package:flutter/material.dart';
import 'package:letstransport/brand_colors.dart';
import 'package:letstransport/datamodels/predictions.dart';
import 'package:letstransport/dataprovider/appdata.dart';
import 'package:letstransport/helpers/requesthelper.dart';
import 'package:letstransport/widgets/BrandDivider.dart';
import 'package:letstransport/widgets/predictiontile.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:provider/provider.dart';
import 'package:letstransport/globalvariable.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  var pickupController = TextEditingController();
  var destinationController = TextEditingController();

  //we want to automatically give focus to destination textField : use FocusNode
  var focusDestination = FocusNode();

  bool focused = false;

  //we want this method to be called just once(when our build method is called)
  void setFocus() {
    //to prevent calling this method more than once, we will use a boolean flag
    if (!focused) {
      FocusScope.of(context).requestFocus(focusDestination);
      focused = true;
    }
  }

  //create new instance of list of predictions
  List<Prediction> destinationPredictionList = [];
  void searchPlace(String placeName) async {
    if (placeName.length > 1) {
      String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=123254251&components=country:in';
      var response = await RequestHelper.getRequest(url);

      if (response == 'failed') {
        return;
      }

      //status is the last value we get in the json request, if successful it gives 'OK'
      if (response['status'] == 'OK') {
        //selecting predictions from the request (and we have 5 of them)
        var predictionJson = response['predictions'];

        //now convert this var predictionJson into a list; and the list will be of type prediction class
        var thisList = (predictionJson as List)
            .map((e) => Prediction.fromJson(e))
            .toList();
        
        //after providing different search query, content of predictionlist should also change
        //hence we have to update our list on every search query(hence used setState)
        setState(() {
          destinationPredictionList = thisList;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    setFocus();

    String address =
        Provider.of<AppData>(context).pickupAddress.placeName ?? '';
    pickupController.text = address;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 210,
              decoration: BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5.0,
                  spreadRadius: 0.5,
                  offset: Offset(0.7, 0.7),
                ),
              ]),
              child: Padding(
                padding:
                    EdgeInsets.only(left: 24, top: 48, right: 24, bottom: 20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    Stack(
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.arrow_back)),
                        Center(
                          child: Text('Set Destination',
                              style: TextStyle(
                                  fontSize: 20, fontFamily: 'Brand-Bold')),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 18,
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'images/pickicon.png',
                          height: 16,
                          width: 16,
                        ),
                        SizedBox(
                          width: 18,
                        ),
                        Expanded(
                          child: Container(
                              decoration: BoxDecoration(
                                color: BrandColors.colorLightGrayFair,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: TextField(
                                    controller: pickupController,
                                    decoration: InputDecoration(
                                      hintText: 'Pickup location',
                                      fillColor: BrandColors.colorLightGrayFair,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          left: 10, top: 8, bottom: 8),
                                    )),
                              )),
                        )
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Image.asset(
                          'images/desticon.png',
                          height: 16,
                          width: 16,
                        ),
                        SizedBox(
                          width: 18,
                        ),
                        Expanded(
                          child: Container(
                              decoration: BoxDecoration(
                                color: BrandColors.colorLightGrayFair,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: TextField(
                                    onChanged: (value) {
                                      searchPlace(value);
                                    },
                                    focusNode: focusDestination,
                                    controller: destinationController,
                                    decoration: InputDecoration(
                                      hintText: 'Where to?',
                                      fillColor: BrandColors.colorLightGrayFair,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          left: 10, top: 8, bottom: 8),
                                    )),
                              )),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            (destinationPredictionList.length > 0) ?
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8,horizontal: 16),
              child: ListView.separated(
                padding: EdgeInsets.all(0),
                itemBuilder:(context, index){
                  return PredictionTile(prediction: destinationPredictionList[index],);
                }, 
                separatorBuilder: (BuildContext context, int index) => BrandDivider(), 
                itemCount: destinationPredictionList.length,
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                ),
            ) : Container(),
         ],
        ),
      ),
    );
  }
}
