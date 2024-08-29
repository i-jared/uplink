import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uplink/screens/create_api.dart';
import 'package:uplink/screens/history.dart';
import 'package:uplink/state/api_bloc.dart';
import 'package:uplink/screens/call.dart';
import 'package:uplink/state/call_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final apibloc = context.watch<ApiBloc>();
    final apistate = apibloc.state;
    final selectedApi = apibloc.selectedApi;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        leading: Builder(
          builder: (context) => IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              }),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text('Settings',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
                title: const Text('Add Model'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AddApiScreen()));
                }),
            ListTile(title: const Text('Voice Models'), onTap: () {}),
            ListTile(
                title: const Text('History'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const HistoryScreen()));
                }),
          ],
        ),
      ),
      body: apistate.isLoading
          ? _buildLoading()
          : apistate.apis.isEmpty
              ? _buildEmpty(context)
              : _buildBody(apibloc, apistate),
      floatingActionButton: FloatingActionButton.large(
        disabledElevation: 0,
        backgroundColor: selectedApi == null ? Colors.grey[200] : null,
        foregroundColor: selectedApi == null ? Colors.grey[500] : null,
        onPressed: selectedApi == null
            ? null
            : () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => BlocProvider<CallBloc>(
                        create: (context) => CallBloc(modelApi: selectedApi),
                        child: CallScreen(callerName: selectedApi.name))));
              },
        child: const Icon(Icons.call),
      ),
    );
  }

  Widget _buildLoading() {
    return const SizedBox.shrink();
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
        child: ElevatedButton(
      child: const Text('Add API Key'),
      onPressed: () {
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddApiScreen()));
      },
    ));
  }

  Widget _buildBody(ApiBloc apibloc, ApiState apistate) {
    final contacts = apistate.apis;
    final selectedApi = apibloc.selectedApi;
    final showDeleteButtons = apibloc.state is EditingApiState;
    return ListView.builder(
      itemCount: apistate.apis.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onLongPress: () {
            apibloc.add(EditingApiEvent());
          },
          child: ListTile(
            title: Text(contacts[index].name,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: selectedApi?.id == contacts[index].id
                        ? FontWeight.bold
                        : null)),
            onTap: () {
              apibloc.add(SelectApiEvent(api: contacts[index]));
              if (showDeleteButtons) {
                apibloc.add(StopEditingApiEvent());
              } else {
                apibloc.add(SelectApiEvent(api: contacts[index]));
              }
            },
            trailing: showDeleteButtons
                ? IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      if (selectedApi?.id == contacts[index].id) {
                        apibloc.add(SelectApiEvent(api: null));
                      }
                      apibloc.add(RemoveApiEvent(id: contacts[index].id));
                      apibloc.add(StopEditingApiEvent());
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}
