library app_rating;

import 'package:app_rating/strings.dart';
import 'package:flutter/material.dart';
import 'package:open_store/open_store.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRating {
  late BuildContext _context; // context
  late SharedPreferences _prefs; // shared preferences
  final String _prefViewingNumber = "VIEWING_NUMBER";

  int _viewingNumber = 0; // keeps the count of viewing the given page
  // 0 beginning, -1 never show

  late int _frequency; // usage frequency
  // after so many times of usage the user will be prompted to rate the application

  late String _iosAppId; // iOS application ID

  /// Default frequency is 30.
  AppRating(BuildContext context, {String iosAppId = "", int frequency = 30}) {
    //init params
    _context = context;

    if (frequency > 0) {
      _frequency = frequency;
    }

    _iosAppId = iosAppId;
  }

  /// Initialises rating conditions.
  Future<void> initRating() async {
    _prefs = await SharedPreferences.getInstance();
    // read from preferences
    if (_prefs.containsKey(_prefViewingNumber)) {
      _viewingNumber = _prefs.getInt(_prefViewingNumber)!;
    }
    // if smaller than 0, it will never be shown again
    if (_viewingNumber >= 0) {
      _viewingNumber++;
    }

    _checkConditions();
  }

  /// Check whether the conditions are fulfilled.
  void _checkConditions() {
    //if it is not rated yet
    if (_viewingNumber > 0) {
      //check frequency
      if (_viewingNumber % _frequency == 0) {
        //prompt user
        _showPopup();
      } else {
        _saveOnDisk();
      }
    }
  }

  /// Saves on shared preferences.
  Future<void> _saveOnDisk() async {
    await _prefs.setInt(_prefViewingNumber, _viewingNumber);
  }

  /// Shows a dialog as a pop up.
  void _showPopup() {
    AlertDialog alert = AlertDialog(
      title: const Text(Strings.appRating),
      content: const Text(Strings.rateApp),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              //if user does not want to rate yet
              _saveOnDisk();

              Navigator.of(_context).pop();
            },
            child: const Text(Strings.no)),
        TextButton(
            onPressed: () {
              //if user decides to rate it
              _rateApplication();
              //never prompt again
              _viewingNumber = -1;
              //save the situation
              _saveOnDisk();

              Navigator.of(_context).pop();
            },
            child: const Text(Strings.yes)),
      ],
    );

    showDialog(
      context: _context,
      builder: (context) {
        return alert;
      },
    );
  }

  /// Leads user to store's rating panel.
  Future<void> _rateApplication() async {
    final packageName = (await PackageInfo.fromPlatform()).packageName;

    OpenStore.instance.open(
      androidAppBundleId: packageName,
      appStoreId: _iosAppId,
    );
  }
}
