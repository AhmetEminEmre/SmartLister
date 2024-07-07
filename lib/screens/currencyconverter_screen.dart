import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CurrencyConverterScreen extends StatefulWidget {
  @override
  _CurrencyConverterScreenState createState() => _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen> {
  final TextEditingController _fromAmountController = TextEditingController();
  final TextEditingController _toAmountController = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  bool _isLoading = false;
  Timer? _debounce;

  final List<String> _currencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'INR', 'AUD', 'CAD', 'CHF', 'CNY', 'SEK', 'NZD'
  ];

  @override
  void initState() {
    super.initState();
    _fromAmountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _fromAmountController.removeListener(_onAmountChanged);
    _fromAmountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAmountChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _convertCurrency();
    });
  }

  Future<void> _convertCurrency() async {
    final amount = double.tryParse(_fromAmountController.text.replaceAll(',', '.'));
    if (amount == null) {
      setState(() {
        _toAmountController.text = 'Ungültiger Betrag';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/$_fromCurrency');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data != null && data['rates'] != null) {
        final rate = data['rates'][_toCurrency];
        final result = rate * amount;

        setState(() {
          _toAmountController.text = result.toStringAsFixed(2);
          _isLoading = false;
        });
      } else {
        setState(() {
          _toAmountController.text = 'Fehler bei der Währungsumrechnung: Ungültige Daten';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _toAmountController.text = 'Fehler bei der API-Abfrage: ${response.statusCode} ${response.reasonPhrase}';
        _isLoading = false;
      });
    }
  }

  Widget _buildCurrencyDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF587A6F),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: _currencies.map((currency) {
          return DropdownMenuItem(
            child: Text(currency, style: TextStyle(color: Colors.white)),
            value: currency,
          );
        }).toList(),
        dropdownColor: Color(0xFF587A6F),
        iconEnabledColor: Colors.white,
        underline: SizedBox(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Währungsrechner', style: TextStyle(color: Colors.white)),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF334B46),
      ),
      backgroundColor: Color(0xFF334B46),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrencyDropdown(_fromCurrency, (value) {
                            setState(() {
                              _fromCurrency = value!;
                              _convertCurrency();
                            });
                          }),
                          SizedBox(height: 10),
                          TextField(
                            controller: _fromAmountController,
                            decoration: InputDecoration(
                              labelText: 'Betrag',
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF587A6F)),
                              ),
                              fillColor: Color(0xFF587A6F),
                              filled: true,
                            ),
                            style: TextStyle(color: Colors.white),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.swap_horiz, size: 40, color: Colors.white),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCurrencyDropdown(_toCurrency, (value) {
                            setState(() {
                              _toCurrency = value!;
                              _convertCurrency();
                            });
                          }),
                          SizedBox(height: 10),
                          TextField(
                            controller: _toAmountController,
                            decoration: InputDecoration(
                              labelText: 'Betrag',
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF587A6F)),
                              ),
                              fillColor: Color(0xFF587A6F),
                              filled: true,
                            ),
                            readOnly: true,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isLoading) CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
