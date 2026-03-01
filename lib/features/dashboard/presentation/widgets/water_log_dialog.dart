import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class WaterLogDialog extends StatefulWidget {
  const WaterLogDialog({super.key});

  @override
  State<WaterLogDialog> createState() => _WaterLogDialogState();
}

class _WaterLogDialogState extends State<WaterLogDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final val = int.tryParse(_controller.text);
    if (val != null && val > 0) {
      Navigator.of(context).pop(val);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
    }
  }

  void _addPreset(int amount) {
    final current = int.tryParse(_controller.text) ?? 0;
    final newValue = current + amount;
    setState(() {
      _controller.text = newValue.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log Water'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Amount (ml)',
              border: OutlineInputBorder(),
              suffixText: 'ml',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ActionChip(
                label: const Text('+ 100ml'),
                onPressed: () => _addPreset(100),
              ),
              ActionChip(
                label: const Text('+ 250ml'),
                onPressed: () => _addPreset(250),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Log')),
      ],
    );
  }
}
