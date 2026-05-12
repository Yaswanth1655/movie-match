class TextFiledValidator {
  static String? fieldValidator({required String value, required String name}) {
    if (value.isEmpty) {
      return "$name field cannot be empty";
    } else {
      return null;
    }
  }

  static String? emailValidator({required String value}) {
    if (value.isEmpty || !value.contains('@') || !value.contains('.')) {
      return "Invalid email";
    } else {
      return null;
    }
  }

  static String? passwordValidator({required String value}) {
    if (value.isEmpty || value.length <= 5) {
      return "Password should consist atleast of 6 characters";
    } else {
      return null;
    }
  }

  static String? phoneValidator({required String value}) {
    //number validator regex
    // RegExp regExp = RegExp(r'^[0-9]+$');
    RegExp regExp = RegExp(r'^[6-9][0-9]{9}$');

    if (value.isEmpty || value.length > 10 || value.length < 10) {
      return "Invalid phone number";
    } else if (!regExp.hasMatch(value)) {
      return "Invalid phone number";
    } else {
      return null;
    }
  }

  //name field in address validator
  static String? validateName(String value, String fieldName) {
    //should not allow special character and does not start with space
    RegExp characterLimitAndNonSpecialSymbol =
        RegExp(r"^[a-zA-Z][a-zA-Z0-9 ]{6,15}$");

    if (value.isEmpty) {
      return "$fieldName cannot be empty";
    } else if (value.length < 7 || value.length > 15) {
      return "$fieldName should of 7 to 16 characters";
    } else if (!characterLimitAndNonSpecialSymbol.hasMatch(value)) {
      return "$fieldName should not start with space or symbol";
    } else {
      return null;
    }
  }

  //email field in address validator
  static String? validateEmail(String value, String fieldName) {
    //should not allow special character and does not start with space
    RegExp validationLimitForEmail =
        RegExp(r'^(?!.*\s).+@[a-zA-Z]+\.[a-zA-Z]+(\.?[a-zA-Z]+)$');

    if (value.isEmpty) {
      return "$fieldName cannot be empty.";
    } else if (!validationLimitForEmail.hasMatch(value)) {
      return "$fieldName should be a valid email.";
    } else {
      return null;
    }
  }

  //house field validator
  static String? validateHouse(String value, String fieldName) {
    //should not allow special character and does not start with space
    if (value.isEmpty) {
      return "$fieldName cannot be empty";
    } else if (value.length > 7) {
      return "$fieldName cannot be more than 7 character";
    } else {
      return null;
    }
  }

  //street field validator
  static String? validateStreet(String value, String fieldName) {
    //should not allow special character and does not start with space
    if (value.isEmpty) {
      return "$fieldName cannot be empty";
    } else if (value.length > 30) {
      return "$fieldName cannot be more than 7 character";
    } else {
      return null;
    }
  }

  //pincode field validator
  static String? validatePincode(String value, String fieldName) {
    //should not allow special character and does not start with space
    if (value.isEmpty) {
      return "$fieldName cannot be empty";
    } else if (value.length != 6) {
      return "$fieldName should be of 6 digits only.";
    } else {
      return null;
    }
  }
}
