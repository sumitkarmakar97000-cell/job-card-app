import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _formatEmail(String userId) {
    final cleanId = userId.trim().toLowerCase().replaceAll(' ', '');
    if (cleanId.contains('@')) return cleanId;
    return '$cleanId@jobcard.local';
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Future<UserModel> login(String userId, String password) async {
    final email = _formatEmail(userId);
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password.trim(),
    );

    final uid = credential.user!.uid;
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) {
      await _auth.signOut();
      throw Exception('ইউজার প্রোফাইল পাওয়া যায়নি। Admin-এর সাথে যোগাযোগ করুন।');
    }

    final userModel = UserModel.fromMap(doc.data()!, doc.id);

    if (!userModel.isActive) {
      await _auth.signOut();
      throw Exception('আপনার অ্যাকাউন্টটি Deactive করা হয়েছে। Admin-এর সাথে যোগাযোগ করুন।');
    }

    return userModel;
  }

  Future<void> createUserByAdmin({
    required String userId,
    required String userName,
    required String password,
    String role = 'user',
  }) async {
    FirebaseApp? tempApp;
    try {
      final email = _formatEmail(userId);
      tempApp = await Firebase.initializeApp(
        name: 'UserCreationApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      final userCred = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password.trim(),
      );

      final newUid = userCred.user!.uid;
      final newUser = UserModel(
        uid: newUid,
        userId: userId.trim().toUpperCase(),
        userName: userName.trim(),
        role: role,
        isActive: true,
        selectedCount: 0,
      );

      await _db.collection('users').doc(newUid).set(newUser.toMap());
      await tempAuth.signOut();
    } finally {
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('লগইন সেশন পাওয়া যায়নি।');
    }

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword.trim(),
    );

    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword.trim());
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}
