import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import 'package:wakDak/cubit/settings/settingsCubit.dart';

// This class use for connect with sql database and insert data and fetch data from database

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  final String CART_TABLE = 'tblcart';

  final String PID = 'PID';
  final String VID = 'VID';
  final String QTY = 'QTY';
  final String cId = 'cid';
  final String ADDONID = 'ADDONID';
  final String ADDONQTY = 'ADDONQTY';
  final String TOTAL = 'TOTAL';
  final String BRANCHID = 'BRANCHID';

  static Database? _db;

  DatabaseHelper.internal();

  Future<Database?> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await initDb();

    return _db;
  }

  //connect with sql database
  Future<Database> initDb() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "eRestro.db");

    // Check if the database exists
    var exists = await databaseExists(path);
    if (!exists) {
      print("database***Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", "eRestro.db"));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      print("database***Opening existing database");
    }
    // open the database
    var db = await openDatabase(path, readOnly: false);

    return db;
  }

  //insert cart data in table
  Future insertCart(String pid, String vid, String qty, String addOnId, String addOnQty, String total, String branchId, BuildContext context) async {
    var dbClient = await db;
    String? check;

    check = await checkCartItemExists(pid, vid);

    print(check);
    String mcid = "$vid$pid";
    if (check != "0") {
      updateCart(pid, vid, qty, addOnId, addOnQty, total, context);
      await getTotalCartCount(context);
    } else {
      //String query = "INSERT INTO $CART_TABLE ($PID,$VID,$QTY,$ADDONID,$ADDONQTY,$TOTAL,$BRANCHID) SELECT '$pid','$vid','$qty','$addOnId','$addOnQty','$total','$branchId' WHERE NOT EXISTS(SELECT $PID,$VID FROM $CART_TABLE WHERE $PID = '$pid' AND $VID='$vid' AND $ADDONID ='$addOnId')";
      String query =
          "INSERT INTO $CART_TABLE ($PID,$VID,$QTY,$ADDONID,$ADDONQTY,$TOTAL,$BRANCHID,$cId) SELECT '$pid','$vid','$qty','$addOnId','$addOnQty','$total','$branchId','$mcid' WHERE NOT EXISTS(SELECT $PID,$VID FROM $CART_TABLE WHERE $cId ='$mcid')";
      await dbClient!.execute(query);

      print("update:insert-qry->$query");
      await getTotalCartCount(context);
    }
  }

  updateCart(String pid, String vid, String qty, String addOnId, String addOnQty, String total, context) async {
    final db1 = await db;
    Map<String, dynamic> row = {
      DatabaseHelper._instance.QTY: qty,
      DatabaseHelper._instance.ADDONQTY: addOnQty,
      DatabaseHelper._instance.TOTAL: total,
      DatabaseHelper._instance.ADDONID: addOnId,
    };
    db1!.update(CART_TABLE, row, where: "$VID = ? AND $PID = ?", whereArgs: [vid, pid]);
    var updatedata = await checkCartItemExists(pid, vid);
    print("update:$qty----$vid----$updatedata");
  }

  removeCart(String vid, String pid, BuildContext context) async {
    final db1 = await db;

    db1!.rawQuery("DELETE FROM $CART_TABLE WHERE $VID = ? AND $PID = ?", [vid, pid]).then((value) {
    });
    await getTotalCartCount(context);
  }

  clearCart() async {
    final db1 = await db;
    db1!.execute("DELETE FROM $CART_TABLE");
  }

  Future<String?> checkCartItemExists(String pid, String vid) async {
    final db1 = await db;
    var result = await db1!.rawQuery("SELECT * FROM $CART_TABLE WHERE $VID = ? AND $PID = ?", [vid, pid]);

    if (result.isNotEmpty) {
      return result[0][QTY].toString();
    } else {
      return "0";
    }
  }

  Future<String?> checkCartItemTotal(String pid, String vid) async {
    final db1 = await db;
    var result = await db1!.rawQuery("SELECT * FROM $CART_TABLE WHERE $VID = ? AND $PID = ?", [vid, pid]);

    if (result.isNotEmpty) {
      return result[0][TOTAL].toString();
    } else {
      return "0";
    }
  }

  Future<List<String>?> getVariantItemData(String pid, String vid) async {
    final db1 = await db;
    List<String> addOnId = [];
    List<Map> result = await db1!.rawQuery("SELECT * FROM $CART_TABLE WHERE $VID = ? AND $PID = ?", [vid, pid]);
    if (result.isNotEmpty) {
      for (var row in result) {
        addOnId.add(row[ADDONID]);
      }
      return addOnId;
    } else {
      return [];
    }
  }

  Future<Map> getCart() async {
    Map data = {};
    List<String> ids = [];
    List<String> addOnIds = [];
    final db1 = await db;

    List<Map> result = await db1!.query(DatabaseHelper._instance.CART_TABLE);
    print(result.toString());
    for (var row in result) {
      ids.add(row[VID]);
      addOnIds.add(row[ADDONID].toString());
    }
    data[VID] = ids;
    data[ADDONID] = addOnIds;

    return data;
  }

  Future<Map> getCartData() async {
    Map data = {};
    final db1 = await db;

    List<Map> result = await db1!.query(DatabaseHelper._instance.CART_TABLE);
    print(result.toString());
    result.forEach((element) {
      data.addAll({element[VID]: element[ADDONID]});
    });

    return data;
  }

  getTotalCartCount(BuildContext context) async {
    final db1 = await db;

    List<Map> result = await db1!.query(DatabaseHelper._instance.CART_TABLE);
    double? total = 0.0, totalData = 0.0;
    for (int i = 0; i < result.length; i++) {
      total = (double.parse(result[i]["TOTAL"])); 
      totalData = totalData! + total;
    }
    if (result.isNotEmpty) {
      await context.read<SettingsCubit>().setCartCount(result.length.toString());
      await context.read<SettingsCubit>().setCartTotal(totalData.toString());
      await context.read<SettingsCubit>().setBranchId(result[0]["BRANCHID"].toString());
    }
  }

  Future<List<Map>> getOffCart() async {
    final db1 = await db;

    List<Map> result = await db1!.query(DatabaseHelper._instance.CART_TABLE);

    return result;
  }

  //close connection of database
  Future close() async {
    var dbClient = await db;
    return dbClient!.close();
  }
}
