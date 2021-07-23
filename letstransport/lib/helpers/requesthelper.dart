import 'dart:convert';
import 'package:http/http.dart' as http;

class RequestHelper{

  //method for getting response from get request
  //is static since we want to use it everywhere in the app, without initializing its object
  //return type we have kept as dynamic(we know it will be string, still kept as dynamic)
  //method is async hence return type is future
  static Future<dynamic> getRequest(String url) async {
    http.Response response = await http.get(url);

    try{
      //if success
      if(response.statusCode == 200){
        String data = response.body;
        var decodeData = jsonDecode(data);
        return decodeData;
      }
      else{
        return 'failed';
      }
    }
    catch(e){
      return 'failed';
    }
  }
}