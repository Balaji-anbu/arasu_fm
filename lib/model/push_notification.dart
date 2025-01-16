import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendPushNotification({
  required String title,
  required String message,
}) async {
  const String oneSignalAppId = '43dcbfa9-f88c-41ce-aa91-8b13eefbbd81';
  const String oneSignalApiKey =
      'os_v2_app_ipol7kpyrra45kurrmj65655qe3pfmzn5odu4yvq4d7n5pcp7btxwtaae7kxyaquxprjl2iskmeqvjcroww4h2shja2lufyqmqnhhri';

  final url = Uri.parse('https://onesignal.com/api/v1/notifications');

  // Construct payload
  final Map<String, dynamic> payload = {
    "app_id": oneSignalAppId,
    "priority": 'high',
    "headings": {"en": title}, // Title of the notification
    "contents": {"en": message}, // Message body
    "included_segments": ["All"], // Send to all devices
  };

  // Make POST request
  final response = await http.post(
    url,
    headers: {
      "Authorization": "Basic $oneSignalApiKey",
      "Content-Type": "application/json",
    },
    body: json.encode(payload),
  );

  if (response.statusCode == 200) {
    print("Notification sent successfully: ${response.body}");
  } else {
    print("Failed to send notification: ${response.body}");
  }
}
