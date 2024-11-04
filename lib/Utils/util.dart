import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';

class Util {
  static String formatDate(String dateString) {
    try {
      DateFormat inputFormat = DateFormat('MM/dd/yyyy HH:mm:ss');
      DateFormat outputFormat = DateFormat('yyyy/MM/dd/ HH시mm분');

      // 입력 문자열을 DateTime으로 파싱 후 원하는 형식으로 변환
      DateTime dateTime = inputFormat.parse(dateString);
      return outputFormat.format(dateTime);
    } catch (e) {
      return '시간 정보 없음';
    }
  }

  static void showAlert(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: const Color(0xFF004A99),
      textColor: Colors.white,
    );
  }

  static void showErrorAlert(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }

  static IconData getIcon(String iconName) {
    switch (iconName) {
      case 'email':
        return Icons.email;
      case 'alarm':
        return Icons.alarm;
      case 'home':
        return Icons.home;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'search':
        return Icons.search;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'account_circle':
        return Icons.account_circle;
      case 'settings':
        return Icons.settings;
      case 'camera':
        return Icons.camera;
      case 'call':
        return Icons.call;
      case 'chat':
        return Icons.chat;
      case 'map':
        return Icons.map;
      case 'lock':
        return Icons.lock;
      case 'visibility':
        return Icons.visibility;
      case 'cloud':
        return Icons.cloud;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'flag':
        return Icons.flag;
      case 'bookmark':
        return Icons.bookmark;
      case 'info':
        return Icons.info;
      case 'help':
        return Icons.help;
      case 'person':
        return Icons.person;
      case 'phone':
        return Icons.phone;
      case 'print':
        return Icons.print;
      case 'attach_file':
        return Icons.attach_file;
      case 'directions':
        return Icons.directions;
      case 'translate':
        return Icons.translate;
      case 'send':
        return Icons.send;
      case 'photo':
        return Icons.photo;
      case 'music_note':
        return Icons.music_note;
      case 'notifications':
        return Icons.notifications;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'thumb_up':
        return Icons.thumb_up;
      case 'pause':
        return Icons.pause;
      case 'play_arrow':
        return Icons.play_arrow;
      case 'download':
        return Icons.download;
      case 'upload':
        return Icons.upload;
      case 'location_on':
        return Icons.location_on;
      case 'wifi':
        return Icons.wifi;
      case 'bluetooth':
        return Icons.bluetooth;
      case 'folder':
        return Icons.folder;
      case 'work':
        return Icons.work;
      case 'zoom_in':
        return Icons.zoom_in;
      case 'battery_full':
        return Icons.battery_full;
      case 'flash_on':
        return Icons.flash_on;
      case 'flight':
        return Icons.flight;
      case 'movie':
        return Icons.movie;
      case 'build':
        return Icons.build;
      case 'explore':
        return Icons.explore;
      case 'save':
        return Icons.save;
      case 'school':
        return Icons.school;
      case 'money':
        return Icons.money;
      case 'eco':
        return Icons.eco;
      case 'dashboard':
        return Icons.dashboard;
      case 'event':
        return Icons.event;
      case 'restaurant':
        return Icons.restaurant;
      case 'sports':
        return Icons.sports;
      case 'security':
        return Icons.security;
      case 'local_library':
        return Icons.local_library;
      case 'thumb_down':
        return Icons.thumb_down;
      case 'account_balance':
        return Icons.account_balance;
      case 'business':
        return Icons.business;
      case 'face':
        return Icons.face;
      case 'brightness':
        return Icons.brightness_5;
      case 'alarm_add':
        return Icons.alarm_add;
      case 'bolt':
        return Icons.bolt;
      case 'holiday_village':
        return Icons.holiday_village;
      default:
        return Icons.notifications;
    }
  }

  static Future<bool> showConfirmDialog(
      BuildContext context, String message) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.white,
              title: const Text(
                "새로운 메세지가 도착했습니다.",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004A99),
                ),
              ),
              content: Text(
                message,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    "취소",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004A99),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "확인",
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  static Future<void> markNotificationAsRead() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int unreadCount = prefs.getInt('unread_notifications') ?? 0;
    if (unreadCount > 0) {
      unreadCount--;
      prefs.setInt('unread_notifications', unreadCount);
      updateBadge(unreadCount);
    }
  }
}
