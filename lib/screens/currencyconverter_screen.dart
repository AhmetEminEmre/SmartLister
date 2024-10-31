import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

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
        color: const Color(0xFF587A6F),
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        items: _currencies.map((currency) {
          return DropdownMenuItem(
            value: currency,
            child: Text(currency, style: const TextStyle(color: Colors.white)),
          );
        }).toList(),
        dropdownColor: const Color(0xFF587A6F),
        iconEnabledColor: Colors.white,
        underline: const SizedBox(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Währungsrechner', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF334B46),
      ),
      backgroundColor: const Color(0xFF334B46),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                          const SizedBox(height: 10),
                          TextField(
                            controller: _fromAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Betrag',
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF587A6F)),
                              ),
                              fillColor: Color(0xFF587A6F),
                              filled: true,
                            ),
                            style: const TextStyle(color: Colors.white),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.swap_horiz, size: 40, color: Colors.white),
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
                          const SizedBox(height: 10),
                          TextField(
                            controller: _toAmountController,
                            decoration: const InputDecoration(
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
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_isLoading) const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
