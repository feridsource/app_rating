library app_rating;

import 'package:app_rating/strings.dart';
import 'package:flutter/material.dart';
import 'package:open_store/open_store.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppRating {

  late BuildContext context; // context
  late var prefs; // shared preferences
  final String prefViewingNumber = "VIEWING_NUMBER";

  int viewingNumber = 0; // keeps the count of viewing the given page
  // 0 beginning, -1 never show

  late int frequency; // usage frequency
  // after so many times of usage the user will be prompted to rate the application

  late String iosAppId; // iOS application ID


  /// Default frequency is 30.
  AppRating(BuildContext context_, {String iosAppId_ = "", int frequency_ = 30}) {
    //init params
    context = context_;

    if (frequency_ > 0) {
      frequency = frequency_;
    }

    iosAppId = iosAppId_;
  }

  /// Initialises to prompt the user.
  void initRating() {
    //read from preferences
    _readFromDisk();

    //if it is not rated yet
    if (viewingNumber > 0) {
      //check frequency
      if (viewingNumber % frequency == 0) {
        //prompt user
        _showPopup();
      } else {
        _saveOnDisk();
      }
    }
  }

  /// Reads from shared preferences.
  Future<void> _readFromDisk() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs != null) {
      viewingNumber = prefs.getInt(prefViewingNumber);
      // if smaller than 0, it will never be shown again
      if (viewingNumber >= 0) {
        viewingNumber++;
      }
    }
  }

  /// Saves on shared preferences.
  Future<void> _saveOnDisk() async {
    if (prefs != null) {
      await prefs.setInt(prefViewingNumber, viewingNumber);
    }
  }

  /// Shows a dialog as a pop up.
  void _showPopup() {
    AlertDialog alert = AlertDialog(
      title: const Text(strings.appRating),
      content: const Text(strings.rateApp),
      actions: <Widget>[
        TextButton(
            onPressed: () {
              //if user does not want to rate yet
              _saveOnDisk();

              Navigator.of(context).pop();
            },
            child: const Text(strings.no)),
        TextButton(
            onPressed: () {
              //if user decides to rate it
              _rateApplication();
              //never prompt again
              viewingNumber = -1;
              //save the situation
              _saveOnDisk();

              Navigator.of(context).pop();
            },
            child: const Text(strings.yes)),
      ],
    );

    showDialog(
      context: context,
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
      appStoreId: iosAppId,
    );
  }
}
