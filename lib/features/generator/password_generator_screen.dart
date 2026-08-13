import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_password_generator/random_password_generator.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  final RandomPasswordGenerator _passwordGenerator = RandomPasswordGenerator();
  String _generatedPassword = '';
  int _passwordLength = 16;
  bool _includeLetters = true;
  bool _includeUppercase = true;
  bool _includeNumbers = true;
  bool _includeSpecialChars = true;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    final password = _passwordGenerator.randomPassword(
      passwordLength: _passwordLength.toDouble(),
      letters: _includeLetters,
      uppercase: _includeUppercase,
      numbers: _includeNumbers,
      specialChar: _includeSpecialChars,
    );
    setState(() => _generatedPassword = password);
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password copied to clipboard')),
    );
  }

  double _calculateStrength() {
    double strength = 0;
    if (_passwordLength >= 8) strength += 0.25;
    if (_passwordLength >= 12) strength += 0.25;
    if (_passwordLength >= 16) strength += 0.25;
    if (_includeLetters) strength += 0.05;
    if (_includeUppercase) strength += 0.05;
    if (_includeNumbers) strength += 0.05;
    if (_includeSpecialChars) strength += 0.05;
    return strength.clamp(0.0, 1.0);
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.8) return Colors.yellow;
    return Colors.green;
  }

  String _getStrengthLabel(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Fair';
    if (strength < 0.8) return 'Good';
    return 'Strong';
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();
    final strengthColor = _getStrengthColor(strength);
    final strengthLabel = _getStrengthLabel(strength);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Generator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Generated Password',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _generatedPassword,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              'Strength',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 100,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: strength,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: strengthColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              strengthLabel,
                              style: TextStyle(
                                color: strengthColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _generatePassword,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Generate'),
                        ),
                        FilledButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Password Length: $_passwordLength',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(
                          width: 200,
                          child: Slider(
                            value: _passwordLength.toDouble(),
                            min: 8,
                            max: 64,
                            divisions: 56,
                            label: _passwordLength.toString(),
                            onChanged: (value) {
                              setState(() => _passwordLength = value.round());
                              _generatePassword();
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Letters (a-z)'),
                      value: _includeLetters,
                      onChanged: (value) {
                        setState(() => _includeLetters = value);
                        _generatePassword();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Uppercase (A-Z)'),
                      value: _includeUppercase,
                      onChanged: (value) {
                        setState(() => _includeUppercase = value);
                        _generatePassword();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Numbers (0-9)'),
                      value: _includeNumbers,
                      onChanged: (value) {
                        setState(() => _includeNumbers = value);
                        _generatePassword();
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Special Characters (!@#\$...)'),
                      value: _includeSpecialChars,
                      onChanged: (value) {
                        setState(() => _includeSpecialChars = value);
                        _generatePassword();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
