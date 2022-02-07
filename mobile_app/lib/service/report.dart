

import 'package:http/http.dart' as http;

class ReportMessage {
  static const String URL =
      'https://script.google.com/macros/s/AKfycbzl9oOj23NFXQIK9LdnyLwQoZmWZxsq7MnewFcE8p-_neGcy1xVr_UtfFojSJZrJFR1/exec';
  static Future<void> reportMessage(
      String message, String toxicity,void Function(String) callback) async {
    try {
      await http.post(Uri.parse(URL), body: {'message':message,'toxicity':toxicity}).then((response) async {
        
        if (response.statusCode == 302) {
          var url = response.headers['location'];
          await http.get(Uri.parse(url!)).then((response) {
            
            callback(response.body);
          });
        } else {
         
          callback(response.body);
        }
      });
    } catch (e) {
      print('EXCEPTIONNNNN $e');
    }
  }
}
