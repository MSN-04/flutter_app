class UrlConstants {
  static const String apiUrl = "http://192.168.0.227:1112/api";

  //logincontroller
  static const String loginEndPoint = "/Login";

  //tokencontroller
  static const String saveTokenEndPoint = "/Token";

  //pushcontroller
  static const String pushListEndPoint = "/Push";
  static const String dashboardPushEndPoint = "/Push/dashboard";
  static const String pushReadEndPoint = "/Push/read";
  static const String unreadNotificationsEndPoint = "/Push/unreadCount";

  static const int timeoutDuration = 5000; // milliseconds
  static const String fileDownloadUrl =
      "http://khnt.nkcf.com/TIS.DataService/Download.aspx";
}
