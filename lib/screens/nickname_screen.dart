import 'package:flutter/material.dart';
import 'package:smart/services/userinfo_service.dart';
import '../objects/userinfo.dart';
import 'homepage_screen.dart';

import 'package:smart/services/itemlist_service.dart';
import 'package:smart/services/productgroup_service.dart';
import 'package:smart/services/shop_service.dart';
import 'package:smart/services/template_service.dart';
import 'package:smart/services/userinfo_service.dart';

class NicknameScreen extends StatefulWidget {
  final NicknameService nicknameService;
  final ProductGroupService productGroupService;
  final ShopService shopService;
  final ItemListService itemListService;
  final TemplateService templateService;

  const NicknameScreen({
    super.key,
    required this.nicknameService,
    required this.productGroupService,
    required this.shopService,
    required this.itemListService,
    required this.templateService,
  });

  @override
  _NicknameScreenState createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  Future<void> _saveNickname() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isNotEmpty) {
      await widget.nicknameService.setNickname(nickname);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(
            itemListService: widget.itemListService,
            shopService: widget.shopService,
            userinfoService: widget.nicknameService,
            productGroupService: widget.productGroupService,
            templateService: widget.templateService,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                height: 500,
                child: Image.asset(
                  'lib/img3/NickNameScreen.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "SmartLister",
                style: TextStyle(fontSize: 44, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 7),
              const Text(
                "Dein smarter Begleiter\nfür jeden Einkauf",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    TextField(
                      key: Key('nicknameField'),
                      controller: _nicknameController,
                      decoration: InputDecoration(
                        hintText: "Dein Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        key: Key('continueButton'),
                        onPressed: _saveNickname,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Los gehts",
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
