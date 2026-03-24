const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// Générer QR Code unique
function generateQRCode(userId) {
  const timestamp = Date.now();
  const data = `${userId}-${timestamp}`;
  const hash = crypto.createHash('sha256').update(data).digest('hex');
  return `QR-USER-${hash.substring(0, 12).toUpperCase()}`;
}

// Trigger: Création utilisateur
exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  const qrCode = generateQRCode(user.uid);
  
  try {
    // Créer document user (si pas déjà créé)
    const userRef = db.collection('users').doc(user.uid);
    const userDoc = await userRef.get();
    
    if (!userDoc.exists) {
      await userRef.set({
        uid: user.uid,
        phone: user.phoneNumber || '',
        email: null,
        qrCode: qrCode,
        userType: 'CLIENT',
        status: 'ACTIVE',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      // Mettre à jour QR code si manquant
      if (!userDoc.data().qrCode) {
        await userRef.update({ qrCode: qrCode });
      }
    }
    
    // Créer wallet
    const walletRef = db.collection('wallets').doc();
    await walletRef.set({
      userId: user.uid,
      balance: 0,
      currency: 'XOF',
      dailyLimit: 100000,
      monthlyLimit: 1000000,
      status: 'ACTIVE',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`User ${user.uid} initialized with QR: ${qrCode}`);
  } catch (error) {
    console.error('Error in onUserCreate:', error);
  }
});