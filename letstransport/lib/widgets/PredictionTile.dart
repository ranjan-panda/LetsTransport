import 'package:flutter/material.dart ';
import 'package:letstransport/brand_colors.dart';
import 'package:letstransport/datamodels/address.dart';
import 'package:letstransport/datamodels/predictions.dart';
import 'package:letstransport/dataprovider/appdata.dart';
import 'package:letstransport/globalvariable.dart';
import 'package:letstransport/helpers/requesthelper.dart';
import 'package:letstransport/widgets/ProgressDialog.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:provider/provider.dart';

class PredictionTile extends StatelessWidget {
  //we want the predictiontile to be custom
  //we will pass the instance of prediciton class, whenever this widget is created
  final Prediction prediction;
  PredictionTile({this.prediction});

  void getPlaceDetatils(String placeID, context) async {
    //add progress bar(while place details request is going on)

    showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) =>
            ProgressDialog(status: 'Please wait...')
    );
    String url =
        'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeID&key=$mapKey';

    var response = await RequestHelper.getRequest(url);

    //when got a response
    Navigator.pop(context);//pop out of show dialog box
    if (response == 'failed') {
      return;
    }

    if (response['status'] == 'OK') {
      Address thisPlace = Address();
      thisPlace.placeName = response['result']['name'];
      thisPlace.placeId = placeID;
      thisPlace.latitude = response ['result']['geometry']['location']['lat'];
      thisPlace.longitude = response ['result']['geometry']['location']['lng'];

      //this address is the dest or the dest we have in mind
      //save this address inside our data provider class(so as to access it from anywhere in app)
      Provider.of<AppData>(context, listen: false)
          .updateDestinationAddress(thisPlace);

      //as soon as we update about our destination to appdata class, we can close this particular screen
      print(thisPlace.placeName);

      Navigator.pop(context,'getDirection');//popped from here to mainpage
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: () {
        getPlaceDetatils(prediction.placeId, context);
      },
      child: Container(
        child: Column(
          children: [
            SizedBox(
              height: 8,
            ),
            Row(children: [
              Icon(
                OMIcons.locationOn,
                color: BrandColors.colorDimText,
              ),
              SizedBox(
                width: 12,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.mainText,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      prediction.secondaryText,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: BrandColors.colorDimText,
                      ),
                    ),
                  ],
                ),
              )
            ]),
            SizedBox(
              height: 8,
            )
          ],
        ),
      ),
    );
  }
}
