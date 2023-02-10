// TODO: Put public facing types in this file.

import 'dart:convert';
import 'package:http/http.dart' as http;

class AmoApiSettings {
  String redirectUri;
  String clientId;
  String hostUrl;
  String clientSecret;

  AmoApiSettings(
      this.redirectUri, this.clientId, this.hostUrl, this.clientSecret);
}

class Token {
  String? refreshToken;
  String? accessToken;
  String? authorizationCode;
  AmoApiSettings amoApiSettings;

  Token(this.authorizationCode, this.amoApiSettings);

  Token.fromRefresh(this.refreshToken, this.amoApiSettings, [this.accessToken]);

  bool haveRefresh() => refreshToken != null;
}

class AmoApi {
  //get accessToken and refresh token from refresh token
  static Future<Token> getAccessTokenFromRefreshToken(Token token) async {
    String url = "https://${token.amoApiSettings.hostUrl}/oauth2/access_token";

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode({
        'grant_type': 'refresh_token',
        'client_id': token.amoApiSettings.clientId,
        'client_secret': token.amoApiSettings.clientSecret,
        "redirect_uri": token.amoApiSettings.redirectUri,
        'refresh_token': token.refreshToken,
      }),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      String newRefreshToken = data['refresh_token'];
      String accessToken = data['access_token'];

      return Token.fromRefresh(
          newRefreshToken, token.amoApiSettings, accessToken);
    } else {
      throw Exception('Failed to get access token');
    }
  }

  // get refreshToken from authentification code
  static Future<Token> getRefreshToken(Token token) async {
    var authCode = token.authorizationCode;
    if (authCode == null) {
      throw Exception('You haven`t Authorization Code');
    }

    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    String url = "https://${token.amoApiSettings.hostUrl}/oauth2/access_token";

    Map<String, String> body = {
      "grant_type": "authorization_code",
      "client_id": token.amoApiSettings.clientId,
      "client_secret": token.amoApiSettings.clientSecret,
      "code": authCode,
      "redirect_uri": token.amoApiSettings.redirectUri,
    };

    var response = await http.post(Uri.parse(url),
        body: jsonEncode(body), headers: headers);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      String refreshToken = data["refresh_token"];
      return Token.fromRefresh(refreshToken,
          token.amoApiSettings); //returns refresh token from response body
    } else {
      throw Exception(jsonEncode({
        'Error': 'Failed to get refresh token',
        'Responce': response.body,
      })); //throws exception if failed to get refresh token

    }
  }

  //get lead by id
  static Future<Map<String, dynamic>> getLeadById(int id, Token token,
      {bool withContact = false}) async {
    if (token.accessToken == null) {
      throw Exception('Access token is null');
    }
    var url =
        'https://${token.amoApiSettings.hostUrl}/api/v4/leads/$id${withContact ? '?with=contacts' : ''}';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.accessToken}'
    };
    // Make a request to the AmoCRM API to get the lead with the given ID
    var response = await http.get(Uri.parse(url), headers: headers);

    // Parse the response and return the lead data
    if (response.statusCode == 200) {
      var leadData = jsonDecode(response.body);
      return leadData;
    } else {
      throw Exception(jsonEncode({
        'Error': 'Error to get lead',
        'Responce': response.body,
      }));
    }
  }

  //get contact by id
  static Future<Map<String, dynamic>> getContactById(int id, Token token,
      {bool withContact = false}) async {
    if (token.accessToken == null) {
      throw Exception('Access token is null');
    }
    var url = 'https://${token.amoApiSettings.hostUrl}/api/v4/leads/$id';

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token.accessToken}'
    };
    // Make a request to the AmoCRM API to get the contact with the given ID
    var response = await http.get(Uri.parse(url), headers: headers);

    // Parse the response and return the contact data
    if (response.statusCode == 200) {
      var leadData = jsonDecode(response.body);
      return leadData;
    } else {
      throw Exception(jsonEncode({
        'Error': 'Error to get contact',
        'Responce': response.body,
      }));
    }
  }
}
