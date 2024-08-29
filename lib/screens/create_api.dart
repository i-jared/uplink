import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uplink/state/api_bloc.dart';

class AddApiScreen extends StatefulWidget {
  const AddApiScreen({super.key});

  @override
  AddApiScreenState createState() => AddApiScreenState();
}

class AddApiScreenState extends State<AddApiScreen> {
  final textController = TextEditingController();
  final apiController = TextEditingController();
  final endpointController = TextEditingController();

  bool get _isFormValid =>
      textController.text.isNotEmpty &&
      apiController.text.isNotEmpty &&
      endpointController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add API'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    var apistate = context.read<ApiBloc>();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'API Name',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: endpointController,
            decoration: const InputDecoration(
              hintText: 'Endpoint',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: apiController,
            decoration: const InputDecoration(
              hintText: 'API Key',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isFormValid
                ? () {
                    apistate.add(CreateApiEvent(
                        name: textController.text,
                        endpoint: endpointController.text,
                        apiKey: apiController.text));
                    Navigator.pop(context, textController.text);
                  }
                : null,
            child: const Text('SUBMIT'),
          ),
        ],
      ),
    );
  }
}
