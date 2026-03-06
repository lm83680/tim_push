import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tim_push/tim_push.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TimPush _timPushPlugin = TimPush();
  late final TimPushListener _timPushListener = TimPushListener(
    onMessageReceived: (TimPushMessage message) {
      debugPrint(
        '[TIMPush] onMessageReceived: id=${message.messageId}, ext=${message.ext}, raw=${message.rawData}',
      );
    },
    onRevokePushMessage: (String messageId) {
      debugPrint('[TIMPush] onRevokePushMessage: messageId=$messageId');
    },
    onNotificationClicked: ({
      required String ext,
      String? userID,
      String? groupID,
    }) {
      debugPrint(
        '[TIMPush] onNotificationClicked: ext=$ext, userID=$userID, groupID=$groupID',
      );
    },
  );
  String _registrationId = 'N/A';
  String _status = 'Idle';

  @override
  void initState() {
    super.initState();
    _addPushListener();
  }

  @override
  void dispose() {
    unawaited(_timPushPlugin.removePushListener(listener: _timPushListener));
    super.dispose();
  }

  Future<void> _addPushListener() async {
    final TimPushResult<void> result = await _timPushPlugin.addPushListener(
      listener: _timPushListener,
    );
    debugPrint(
      '[TIMPush] addPushListener: code=${result.code}, message=${result.message}',
    );
  }

  Future<void> _registerPush() async {
    final TimPushResult<void> result = await _timPushPlugin.registerPush(
      sdkAppId: 0,
      appKey: "xxxx",
      businessId: 0,
    );
    await _timPushPlugin.disablePostNotificationInForeground(disable: true);
    if (!mounted) {
      return;
    }
    setState(() {
      _status = 'registerPush: code=${result.code}, message=${result.message}';
    });
  }

  Future<void> _unregisterPush() async {
    final TimPushResult<void> result = await _timPushPlugin.unRegisterPush();
    if (!mounted) {
      return;
    }
    setState(() {
      _status = 'unRegisterPush: ${result.code}';
    });
  }

  Future<void> _loadRegistrationId() async {
    final TimPushResult<String> result = await _timPushPlugin.getRegistrationID();
    if (!mounted) {
      return;
    }
    setState(() {
      _registrationId = result.data?.isNotEmpty == true ? result.data! : 'Unavailable';
      _status = 'getRegistrationID: ${result.code}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('TIM Push Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('RegistrationID: $_registrationId'),
              const SizedBox(height: 12),
              Text('Status: $_status'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _registerPush,
                child: const Text('registerPush'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _unregisterPush,
                child: const Text('unRegisterPush'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadRegistrationId,
                child: const Text('getRegistrationID'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
