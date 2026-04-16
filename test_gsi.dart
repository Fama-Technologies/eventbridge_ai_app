import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  GoogleSignInAccount? account;
  var auth = await account!.authentication;
  print(auth.idToken);
}
