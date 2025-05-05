import 'link.dart';
import 'session.dart';

/// A result returned from link search/selection screens.
/// Contains the raw link address (linkId) and the Link object.
class LinkWrapper {
  final String
  linkId; // The unsanitized link address, used as the key in .links map
  final Link link; // The Link object

  LinkWrapper({required this.linkId, required this.link});
}

/// A wrapper for session data returned from selection screens or APIs.
/// Contains the sessionId (document ID or key) and the Session object.
class SessionWrapper {
  final String
  sessionId; // The timestamp of session syart, used as the key in .sessions map
  final Session session; // The Session object

  SessionWrapper({required this.sessionId, required this.session});
}
