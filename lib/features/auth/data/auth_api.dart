import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio, {String baseUrl}) = _AuthApi;

  @POST('/auth/login')
  Future<void> login(@Body() Map<String, dynamic> body);

  @POST('/auth/signup')
  Future<void> signup(@Body() Map<String, dynamic> body);

  @GET('/auth/me')
  Future<dynamic> getMe();
}
