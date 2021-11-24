import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/data_store.dart';
import '../data/user.dart' as user;

class SignInWidget extends StatefulWidget {
  final bool isSignUp;

  const SignInWidget({Key? key, required this.isSignUp}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SignInWidgetState();
}

class _SignInWidgetState extends State<SignInWidget> {
  final _formKey = GlobalKey<FormState>();
  late bool _isSignUp = widget.isSignUp;
  String _errorMessage = '';
  bool _isLoading = false;
  String _email = "";
  String _username = "";
  String _password = "";
  String _confirmPassword = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
        _isSignUp ? "Sign Up" : "Sign In",
      )),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  constraints: const BoxConstraints(minWidth: 100, maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        _emailInput(),
                        _nameInput(),
                        _passwordInput(),
                        _confirmPasswordInput(),
                        _errorMessageWidget(),
                        _submitButton(),
                        _switchButton(),
                      ],
                    ),
                  ),
                ),
              ],
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
          ),
          _loadingIndicator(),
        ],
      ),
    );
  }

  Widget _loadingIndicator() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return const SizedBox(height: 0, width: 0);
  }

  Widget _errorMessageWidget() {
    if (_errorMessage.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.only(top: 8),
        alignment: Alignment.center,
        child: Text(_errorMessage, style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.red)),
      );
    } else {
      return Container(height: 0);
    }
  }

  Widget _emailInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: const InputDecoration(
          hintText: 'Email',
          icon: Icon(Icons.mail, color: Colors.grey),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => _email = value!.trim(),
      ),
    );
  }

  Widget _nameInput() {
    if (!_isSignUp) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextFormField(
        maxLines: 1,
        autofocus: false,
        decoration: const InputDecoration(
          hintText: 'Username',
          icon: Icon(Icons.person, color: Colors.grey),
        ),
        validator: (value) => value == null || value.trim().length < 5 ? 'Username is too short' : null,
        onSaved: (value) => _username = value!.trim(),
      ),
    );
  }

  Widget _passwordInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: const InputDecoration(
          hintText: 'Password',
          icon: Icon(Icons.lock, color: Colors.grey),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Password can't be empty";
          } else if (value.length < 6) {
            return "Password is too short.";
          }
        },
        onSaved: (value) => _password = value!,
        onFieldSubmitted: _isSignUp
            ? null
            : (value) {
                _validateAndSubmit();
              },
      ),
    );
  }

  Widget _confirmPasswordInput() {
    if (!_isSignUp) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: const InputDecoration(
          hintText: 'Confirm Password',
          icon: Icon(Icons.lock, color: Colors.grey),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Password can't be empty";
          } else if (value.length < 6) {
            return "Password is too short.";
          }
        },
        onSaved: (value) => _confirmPassword = value!,
      ),
    );
  }

  Widget _submitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
      child: SizedBox(
        height: 40,
        width: double.infinity,
        child: ElevatedButton(
          child: Text(_isSignUp ? 'Create account' : 'Login'),
          onPressed: _validateAndSubmit,
        ),
      ),
    );
  }

  Widget _switchButton() {
    return TextButton(
      child: Text(_isSignUp ? 'Have an account? Sign in' : 'Create an account'),
      onPressed: () {
        _resetForm();
        setState(() {
          _isSignUp = !_isSignUp;
        });
      },
    );
  }

  void _resetForm() {
    if (_formKey.currentState != null) {
      _formKey.currentState!.reset();
    }
    _errorMessage = '';
  }

  void _validateAndSubmit() async {
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });
    if (_validateAndSave()) {
      String userId = '';
      try {
        if (_isSignUp) {
          if (_password != _confirmPassword) {
            setState(() {
              _isLoading = false;
              _errorMessage = 'Passwords do not match!';
            });
          } else {
            print('trying to create new user...');
            userId = await DataStore.auth.signUp(_email, _password);
            print('userId: $userId');
            user.User.newUser(userId, _username);
            print('created user!!');
            Navigator.of(context).pop();
          }
        } else {
          userId = await DataStore.auth.signIn(_email, _password);
          Navigator.of(context).pop();
        }
      } on FirebaseAuthException catch (e) {
        print('error message: ${e.code}, ${e.message}');
        setState(() {
          _isLoading = false;
          switch (e.code) {
            case 'invalid-email':
              _errorMessage = 'Invalid email address';
              break;
            case 'user-not-found':
              _errorMessage = 'Account not found';
              break;
            case 'wrong-password':
              _errorMessage = 'Incorrect password';
              break;
            default:
              _errorMessage = e.message ?? "Internal Error";
          }
        });
      }
    } else {
      _isLoading = false;
    }
  }

  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form != null && form.validate()) {
      form.save();
      return true;
    }
    return false;
  }
}
