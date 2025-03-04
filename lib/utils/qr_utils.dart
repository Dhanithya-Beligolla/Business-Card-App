import '../models/user_profile.dart';

class QRUtils {
  static String generateVCard(String email, UserProfile profile) {
    String name = email.split('@')[0];
    String vCard = 'BEGIN:VCARD\n'
        'VERSION:3.0\n'
        'FN:$name\n'
        'EMAIL:$email\n'
        'TEL:${profile.phone ?? ''}\n';
    for (var social in profile.socialProfiles) {
      vCard += 'URL:${social['url']}\n';
    }
    vCard += 'END:VCARD';
    return vCard;
  }
}