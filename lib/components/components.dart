import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hmes/constants.dart';
import 'package:rflutter_alert/rflutter_alert.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.buttonText,
    this.isOutlined = false,
    required this.onPressed,
    this.width = 320,
  });

  final String buttonText;
  final bool isOutlined;
  final Function onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPressed();
      },
      child: Material(
        borderRadius: BorderRadius.circular(30),
        elevation: 4,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isOutlined ? Colors.white : Color(0xFF9F7BFF),
            border: Border.all(color: Color(0xFF9F7BFF), width: 2.5),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              buttonText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isOutlined ? Color(0xFF9F7BFF) : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class TopScreenImage extends StatelessWidget {
  const TopScreenImage({super.key, required this.screenImageName});
  final String screenImageName;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.contain,
            image: AssetImage('assets/images/$screenImageName'),
          ),
        ),
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  const ScreenTitle({super.key, required this.title, this.backId});
  final String title;
  final String? backId;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: kTextColor,
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading:
          backId != null
              ? GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, backId!);
                },
                child: Container(
                  margin: const EdgeInsets.all(10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xffF7F8F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/icons/back_arrow.svg',
                    height: 15,
                    width: 15,
                  ),
                ),
              )
              : null,
    );
  }
}

class MiniScreenTitle extends StatelessWidget {
  const MiniScreenTitle({super.key, required this.title, this.backId});
  final String title;
  final String? backId;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: kTextColor,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      leading:
          backId != null
              ? GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, backId!);
                },
                child: Container(
                  margin: const EdgeInsets.all(10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xffF7F8F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    'assets/images/icons/back_arrow.svg',
                    height: 15,
                    width: 15,
                  ),
                ),
              )
              : null,
    );
  }
}

class CustomTextField extends StatelessWidget {
  const CustomTextField({super.key, required this.textField});
  final TextField textField;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(width: 2.5, color: kTextColor),
      ),
      child: textField,
    );
  }
}

class CustomBottomScreen extends StatelessWidget {
  const CustomBottomScreen({
    super.key,
    required this.textButton,
    required this.question,
    this.heroTag = '',
    required this.buttonPressed,
    required this.questionPressed,
  });
  final String textButton;
  final String question;
  final String heroTag;
  final Function buttonPressed;
  final Function questionPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              questionPressed();
            },
            child: Text(question),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Hero(
            tag: heroTag,
            child: CustomButton(
              buttonText: textButton,
              width: 150,
              onPressed: () {
                buttonPressed();
              },
            ),
          ),
        ),
      ],
    );
  }
}

Alert signUpAlert({
  required Function onPressed,
  required String title,
  required String desc,
  required String btnText,
  required BuildContext context,
}) {
  return Alert(
    context: context,
    title: title,
    desc: desc,
    buttons: [
      DialogButton(
        onPressed: () {
          onPressed();
        },
        width: 120,
        child: Text(
          btnText,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    ],
  );
}

Alert showAlert({
  required Function onPressed,
  required String title,
  required String desc,
  required BuildContext context,
}) {
  return Alert(
    context: context,
    type: AlertType.error,
    title: title,
    desc: desc,
    buttons: [
      DialogButton(
        onPressed: () {
          onPressed();
        },
        width: 120,
        child: const Text(
          "OK",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    ],
  );
}
