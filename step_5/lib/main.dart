// Copyright 2016, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:firebase/firebase.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(new MaterialApp(
    title: "Firechat",
    theme: new ThemeData(
      brightness: ThemeBrightness.light,
      primarySwatch: Colors.purple,
      accentColor: Colors.orangeAccent[400]
    ),
    routes: <String, RouteBuilder>{
      '/': (RouteArguments args) => new ChatScreen()
    }
  ));
}

class ChatScreen extends StatefulComponent {
  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  Firebase _firebase;
  String _user;
  List<Map<String, String>> _messages;
  InputValue _currentMessage;

  void initState() {
    _firebase = new Firebase("https://firechat-flutter.firebaseio.com/");
    _user = "Guest${new math.Random().nextInt(1000)}";
    _firebase.onChildAdded.listen((Event event) {
      setState(() => _messages.add(event.snapshot.val()));
    });
    _messages = <Map<String, String>>[];
    _currentMessage = InputValue.empty;
    super.initState();
  }

  Widget _buildDrawer(BuildContext context) {
    return new Drawer(
      child: new Block(children: <Widget>[
        new DrawerHeader(child: new Text(_user ?? '')),
        new DrawerItem(
          icon: 'action/help',
          child: new Text('Help & Feedback'),
          onPressed: () {
            showDialog(
              context: context,
              child: new Dialog(
                title: new Text('Need help?'),
                content: new Text('Email flutter-discuss@googlegroups.com.'),
                actions: <Widget>[
                  new FlatButton(
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                    child: new Text('OK')
                  ),
                ]
              )
            );
          }
        )
      ])
    );
  }

  void _handleMessageChanged(InputValue message) {
    setState(() {
      _currentMessage = message;
    });
  }

  void _handleMessageAdded(InputValue value) {
    Map<String, String> message = {
      'name': _user,
      'text': value.text,
    };
    _firebase.push().set(message);
    setState(() {
      _currentMessage = InputValue.empty;
    });
  }

  bool get _isComposing => _currentMessage.text.length > 0;

  Widget _buildTextComposer() {
    ThemeData themeData = Theme.of(context);
    return new Column(
      children: <Widget>[
        new Row(
          children: <Widget>[
            new Flexible(
              child: new Input(
                value: _currentMessage,
                hintText: 'Enter message',
                keyboardType: KeyboardType.text,
                onSubmitted: _handleMessageAdded,
                onChanged: _handleMessageChanged
              )
            ),
            new Container(
              margin: const EdgeDims.symmetric(horizontal: 4.0),
              child: new IconButton(
                icon: 'content/send',
                onPressed: _isComposing ? () => _handleMessageAdded(_currentMessage) : null,
                color: _isComposing ? themeData.accentColor : themeData.disabledColor
              )
            )
          ]
        )
      ]
    );
  }

  Widget build(BuildContext context) {
    return new Scaffold(
      toolBar: new ToolBar(
        center: new Text("Chatting as $_user")
      ),
      drawer: _buildDrawer(context),
      body: new Column(
        children: [
          new Flexible(
            child: new Block(
              padding: const EdgeDims.symmetric(horizontal: 8.0),
              scrollAnchor: ViewportAnchor.end,
              children: _messages.map((m) => new ChatMessage(m)).toList()
            )
          ),
          _buildTextComposer(),
        ]
      )
    );
  }
}

class ChatMessage extends StatelessComponent {
  ChatMessage(Map<String, String> source)
    : name = source['name'], text = source['text'];
  final String name;
  final String text;

  Widget build(BuildContext context) {
    return new Container(
      margin: const EdgeDims.all(3.0),
      child: new Text("$name: $text")
    );
  }
}
