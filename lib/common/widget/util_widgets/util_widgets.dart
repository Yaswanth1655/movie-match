import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';


class UtilWidgets {
  //padding
  static Container paddedWidget(
      {required Widget child, double? vertical, double? horizontal}) {
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: horizontal ?? 8, vertical: vertical ?? 8),
        child: child);
  }

//greySpacing
  static Container greySpacing(double height) {
    return Container(
      height: height,
     // color: AppPalette.grey.withOpacity(0.1),
    );
  }

  //pick image
  static Future<XFile?> pickImage(ImageSource imageSource) async {
    XFile? pickedImage;
    pickedImage = await ImagePicker().pickImage(source: imageSource);
    return pickedImage;
  }

  //pick video
  static Future<XFile?> videoPickerFun(ImageSource imageSource) async {
    final pickedVideo = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxDuration: const Duration(seconds: 6));
    return pickedVideo;
  }

  //date picker
  static Future<DateTime?> datePicked(BuildContext context) async {
    DateTime? pickedDate;
    pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      initialDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              // primary: AppPalette.primaryColor, // header background color
              // onPrimary: AppPalette.white, // header text color
              // onSurface: AppPalette.black, // body text color
            ),
          ),
          child: child!,
        );
      },
    );
    return pickedDate;
  }

  //time picker
  static Future<TimeOfDay?> timePicker(BuildContext context) async {
    TimeOfDay? pickedTime;
    pickedTime =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());

    return pickedTime;
  }

  //toast Message
  static toastMessage(String message) {
    Fluttertoast.showToast(
        backgroundColor: Colors.black,
        msg: message,
        toastLength: Toast.LENGTH_LONG);
  }

  //error Widget
  static Center errorWidget() {
    return const Center(
      child: Text(
        'Something Went Wrong !!!',
       // style: TypoRed.red50015,
      ),
    );
  }

  //loading Widget
  static Center loadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
       // color: AppPalette.primaryColor,
      ),
    );
  }

  //internet
  static Container noInterNetWidget() {
    return Container(
      height: double.infinity,
      width: double.infinity,
      alignment: Alignment.center,
   //   child: Lottie.asset('assets/lottiefiles/no_internet.json'),
    );
  }

  static void showPopup(BuildContext context,
      {required Widget widget, bool barrierDismissible = true}) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) => widget,
    );
  }

  // static Future<MediaInfo?> compressVideoFile(XFile file) async {
  //   try {
  //     await VideoCompress.setLogLevel(0);
  //     return VideoCompress.compressVideo(file.path,
  //         quality: VideoQuality.MediumQuality, deleteOrigin: false);
  //   } catch (e) {
  //     VideoCompress.cancelCompression();
  //     rethrow;
  //   }
  // }
}
