import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:letstransport/brand_colors.dart';
import 'package:letstransport/screens/mainpage.dart';
import 'package:letstransport/screens/registrationpage.dart';
import 'package:letstransport/widgets/ProgressDialog.dart';
import 'package:letstransport/widgets/TaxiButton.dart';

class LoginPage extends StatefulWidget {

  static const String id = 'login';

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  void showSnackBar(String title){
    final snackbar = SnackBar(
        content: Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 15),));
    scaffoldKey.currentState.showSnackBar(snackbar);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;

  var emailController = TextEditingController();
  var passwordController = TextEditingController();

  void login() async {

    //show please wait dialog
    showDialog(
        //to make the dialog non-dismissable
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => ProgressDialog(status: 'Logging you in',)
    );
      final FirebaseUser user = (await _auth.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      ).catchError((ex){

        Navigator.pop(context);
        //catch error and display msg
        PlatformException thisEx = ex;
        showSnackBar(thisEx.message);
      })).user;

      if(user!=null){
        //verify login
        DatabaseReference userRef = FirebaseDatabase.instance.reference().child('users/${user.uid}');

        userRef.once().then((DataSnapshot snapshot){
          
          //to take him to mainpage, check whether user info is existing or not in DB
          if(snapshot.value != null){
            Navigator.pushNamedAndRemoveUntil(context, MainPage.id, (route) => false);
          }
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child:SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                //SizedBox(height: 70,),
                Image(
                  alignment: Alignment.center,
                  height: 250.0,
                  width: 250.0,
                  image: AssetImage('images/logo123.png'),
                ),
                //SizedBox(height: 40,),
                Text('Sign In as a Rider',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: 'Brand-Bold',
                ),
                ),
                Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            labelText: 'Email Address',
                            labelStyle: TextStyle(
                              fontSize: 14.0,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.0,
                            )
                        ),
                        style: TextStyle(fontSize: 14.0),
                      ),

                      SizedBox(height: 10.0,),

                      TextField(
                        controller: passwordController,
                        obscureText: true,  //for password : *****
                        decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              fontSize: 14.0,
                            ),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 10.0,
                            )
                        ),
                        style: TextStyle(fontSize: 14.0),
                      ),
                      SizedBox(height: 40.0,),

                      //click on flutter outline and select raisedbutton and click on extract widget and rename to Taxibutton
                      //cut the taxibutton class code created below and add it to a new file
                      TaxiButton(
                        title: 'LOGIN',
                        color: BrandColors.colorPinkish,
                        onPressed: () async{

                          //check network availability
                          var connectivityResult = await Connectivity().checkConnectivity();
                          if(connectivityResult != ConnectivityResult.mobile && connectivityResult != ConnectivityResult.wifi){
                            showSnackBar('No Internet Connectivity');
                            return;
                          }

                          if(!emailController.text.contains('@')){
                            showSnackBar('Please provide a valid Email Address');
                            return;
                          }

                          if(passwordController.text.length<8){
                            showSnackBar('Password must be at least 8 characters');
                            return;
                          }

                          login();
                        },
                      ),

                    ],
                  ),
                ),
                FlatButton(
                    onPressed: (){
                      Navigator.pushNamedAndRemoveUntil(context, RegistrationPage.id, (route) => false);
                    },
                    child: Text('Don\'t have an account, sign up here')
                ),

              ],
            ),
          ),
      ),
    ),
    );
  }
}


