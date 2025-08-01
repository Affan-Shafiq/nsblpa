import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmailAndPassword(String email, String password, String firstName, String lastName) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      
      if (credential.user != null) {
        // Update the user field immediately
        _user = credential.user;
        
        // Create comprehensive player profile in Firestore
        await _firestore.collection('players').add({
          'userId': credential.user!.uid,
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'profileImageUrl': null,
          'team': 'TBD',
          'position': 'TBD',
          'jerseyNumber': 0,
          'dateOfBirth': DateTime(1990, 1, 1).toIso8601String(), // Default date
          'nationality': 'TBD',
          'memberSince': FieldValue.serverTimestamp(),
          'role': 'player', // Default role for new signups
          
          // Initialize stats
          'stats': {
            'gamesPlayed': 0,
            'pointsPerGame': 0.0,
            'reboundsPerGame': 0.0,
            'assistsPerGame': 0.0,
            'stealsPerGame': 0.0,
            'blocksPerGame': 0.0,
            'fieldGoalPercentage': 0.0,
            'threePointPercentage': 0.0,
            'freeThrowPercentage': 0.0,
            'totalPoints': 0,
            'totalRebounds': 0,
            'totalAssists': 0,
          },
          
          // Initialize empty arrays
          'contractIds': [],
          'endorsementIds': [],
          
          // Initialize finances
          'finances': {
            'currentSeasonEarnings': 0.0,
            'careerEarnings': 0.0,
            'endorsementEarnings': 0.0,
            'contractEarnings': 0.0,
            'yearlyEarnings': [
              {
                'year': 2021,
                'earnings': 0.0,
                'endorsements': 0.0,
                'contracts': 0.0,
              },
              {
                'year': 2022,
                'earnings': 0.0,
                'endorsements': 0.0,
                'contracts': 0.0,
              },
            ],
            'recentTransactions': [],
          },
        });
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        _user = userCredential.user;
        
        // Check if user exists in Firestore, if not create profile
        final querySnapshot = await _firestore
            .collection('players')
            .where('userId', isEqualTo: userCredential.user!.uid)
            .get();
        
        if (querySnapshot.docs.isEmpty) {
          // Create comprehensive player profile in Firestore
          await _firestore.collection('players').add({
            'userId': userCredential.user!.uid,
            'firstName': userCredential.user!.displayName?.split(' ').first ?? '',
            'lastName': userCredential.user!.displayName?.split(' ').skip(1).join(' ') ?? '',
            'email': userCredential.user!.email ?? '',
            'profileImageUrl': userCredential.user!.photoURL,
            'team': 'TBD',
            'position': 'TBD',
            'jerseyNumber': 0,
            'dateOfBirth': DateTime(1990, 1, 1).toIso8601String(), // Default date
            'nationality': 'TBD',
            'memberSince': FieldValue.serverTimestamp(),
            'role': 'player', // Default role for new signups
            
            // Initialize stats
            'stats': {
              'gamesPlayed': 0,
              'pointsPerGame': 0.0,
              'reboundsPerGame': 0.0,
              'assistsPerGame': 0.0,
              'stealsPerGame': 0.0,
              'blocksPerGame': 0.0,
              'fieldGoalPercentage': 0.0,
              'threePointPercentage': 0.0,
              'freeThrowPercentage': 0.0,
              'totalPoints': 0,
              'totalRebounds': 0,
              'totalAssists': 0,
            },
            
            // Initialize empty arrays
            'contractIds': [],
            'endorsementIds': [],
            
            // Initialize finances
            'finances': {
              'currentSeasonEarnings': 0.0,
              'endorsementEarnings': 0.0,
              'contractEarnings': 0.0,
              'careerEarnings': 0.0,
              'yearlyEarnings': [
                {
                  'year': 2021,
                  'earnings': 0.0,
                  'endorsements': 0.0,
                  'contracts': 0.0,
                },
                {
                  'year': 2022,
                  'earnings': 0.0,
                  'endorsements': 0.0,
                  'contracts': 0.0,
                },
              ],
              'recentTransactions': [],
            },
          });
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Error signing in with Google: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      _error = 'Error signing out';
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _auth.sendPasswordResetEmail(email: email);
      
      _isLoading = false;
      notifyListeners();
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      _error = _getErrorMessage(e.code);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'An unexpected error occurred';
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_user != null) {
        await _user!.updateDisplayName(displayName);
        await _user!.updatePhotoURL(photoURL);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error updating profile';
      notifyListeners();
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 