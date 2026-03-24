const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// ============================================
// 1. ON USER CREATE - Initialisation Compte
// ============================================

exports.onUserCreate = functions.auth.user().onCreate(async (user) => {
  const qrCode = generateQRCode(user.uid);
  
  try {
    // Créer document user
    await db.collection('users').doc(user.uid).set({
      uid: user.uid,
      email: user.email,
      phone: user.phoneNumber || '',
      fullName: '',
      qrCode: qrCode,
      userType: 'CLIENT',
      status: 'ACTIVE',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLogin: null,
    });
    
    // Créer wallet
    await db.collection('wallets').add({
      userId: user.uid,
      balance: 0,
      currency: 'XOF',
      dailyLimit: 100000,
      monthlyLimit: 1000000,
      status: 'ACTIVE',
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    console.log(`User ${user.uid} initialized with QR: ${qrCode}`);
  } catch (error) {
    console.error('Error in onUserCreate:', error);
  }
});

function generateQRCode(userId) {
  const timestamp = Date.now();
  const data = `${userId}-${timestamp}`;
  const hash = crypto.createHash('sha256').update(data).digest('hex');
  return `QR-USER-${hash.substring(0, 12).toUpperCase()}`;
}

// ============================================
// 2. RECHARGE CLIENT (Gérant)
// ============================================

exports.rechargeClient = functions.https.onCall(async (data, context) => {
  // Vérifier auth
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const { clientQRCode, amount, paymentMethod, stationId, mobileMoneyProvider } = data;
  
  // Vérifier montant minimum
  if (amount < 5000) {
    throw new functions.https.HttpsError('invalid-argument', 'Montant minimum: 5,000 FCFA');
  }
  
  // Vérifier que c'est un gérant
  const operatorDoc = await db.collection('users').doc(context.auth.uid).get();
  if (!operatorDoc.exists || operatorDoc.data().userType !== 'GERANT') {
    throw new functions.https.HttpsError('permission-denied', 'Only gerants can recharge');
  }
  
  // Trouver le client par QR
  const clientSnapshot = await db.collection('users')
    .where('qrCode', '==', clientQRCode)
    .limit(1)
    .get();
  
  if (clientSnapshot.empty) {
    throw new functions.https.HttpsError('not-found', 'Client not found');
  }
  
  const clientId = clientSnapshot.docs[0].id;
  
  // Récupérer info station
  const stationDoc = await db.collection('stations').doc(stationId).get();
  if (!stationDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Station not found');
  }
  const station = stationDoc.data();
  
  // Transaction atomique
  return db.runTransaction(async (transaction) => {
    // Récupérer wallet
    const walletSnapshot = await db.collection('wallets')
      .where('userId', '==', clientId)
      .limit(1)
      .get();
    
    if (walletSnapshot.empty) {
      throw new functions.https.HttpsError('not-found', 'Wallet not found');
    }
    
    const walletDoc = walletSnapshot.docs[0];
    const wallet = walletDoc.data();
    
    // Créditer wallet
    transaction.update(walletDoc.ref, {
      balance: wallet.balance + amount,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Créer transaction
    const txRef = db.collection('transactions').doc();
    transaction.set(txRef, {
      type: 'RECHARGE',
      clientUserId: clientId,
      operatorUserId: context.auth.uid,
      stationId: stationId,
      amount: amount,
      currency: wallet.currency,
      paymentMethod: paymentMethod,
      mobileMoneyProvider: mobileMoneyProvider || null,
      compagnie: station.compagnie,
      status: 'COMPLETED',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    return {
      success: true,
      transactionId: txRef.id,
      newBalance: wallet.balance + amount,
    };
  });
});

// ============================================
// 3. DEBIT CARBURANT (Pompiste)
// ============================================

exports.debitCarburant = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }
  
  const { clientQRCode, fuelType, liters, pricePerLiter, stationId } = data;
  const totalAmount = liters * pricePerLiter;
  
  // Vérifier que c'est un pompiste
  const operatorDoc = await db.collection('users').doc(context.auth.uid).get();
  if (!operatorDoc.exists || operatorDoc.data().userType !== 'POMPISTE') {
    throw new functions.https.HttpsError('permission-denied', 'Only pompistes can debit');
  }
  
  // Trouver le client
  const clientSnapshot = await db.collection('users')
    .where('qrCode', '==', clientQRCode)
    .limit(1)
    .get();
  
  if (clientSnapshot.empty) {
    throw new functions.https.HttpsError('not-found', 'Client not found');
  }
  
  const clientId = clientSnapshot.docs[0].id;
  const client = clientSnapshot.docs[0].data();
  
  // Récupérer station
  const stationDoc = await db.collection('stations').doc(stationId).get();
  const station = stationDoc.data();
  
  // Transaction atomique
  return db.runTransaction(async (transaction) => {
    // Récupérer wallet
    const walletSnapshot = await db.collection('wallets')
      .where('userId', '==', clientId)
      .limit(1)
      .get();
    
    if (walletSnapshot.empty) {
      throw new functions.https.HttpsError('not-found', 'Wallet not found');
    }
    
    const walletDoc = walletSnapshot.docs[0];
    const wallet = walletDoc.data();
    
    // Vérifier solde
    if (wallet.balance < totalAmount) {
      throw new functions.https.HttpsError(
        'failed-precondition',
        `Solde insuffisant. Disponible: ${wallet.balance}, Requis: ${totalAmount}`
      );
    }
    
    // Débiter
    transaction.update(walletDoc.ref, {
      balance: wallet.balance - totalAmount,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Si client entreprise, incrémenter spending
    if (client.userType === 'CLIENT_ENTREPRISE') {
      transaction.update(walletDoc.ref, {
        currentMonthSpending: admin.firestore.FieldValue.increment(totalAmount),
      });
    }
    
    // Créer transaction
    const txRef = db.collection('transactions').doc();
    transaction.set(txRef, {
      type: 'DEBIT',
      clientUserId: clientId,
      operatorUserId: context.auth.uid,
      stationId: stationId,
      companyId: client.companyId || null,
      amount: totalAmount,
      currency: wallet.currency,
      fuelType: fuelType,
      liters: liters,
      pricePerLiter: pricePerLiter,
      qrCodeScanned: clientQRCode,
      status: 'COMPLETED',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    
    // Calculer points
    const points = calculateLoyaltyPoints(totalAmount, liters);
    
    // Créer/Mettre à jour carte fidélité
    const loyaltySnapshot = await db.collection('loyalty_cards')
      .where('userId', '==', clientId)
      .where('compagnie', '==', station.compagnie)
      .limit(1)
      .get();
    
    if (loyaltySnapshot.empty) {
      // Créer nouvelle carte
      const newCardRef = db.collection('loyalty_cards').doc();
      transaction.set(newCardRef, {
        userId: clientId,
        compagnie: station.compagnie,
        totalPoints: points,
        availablePoints: points,
        tier: 'BRONZE',
        pointsHistory: [{
          points: points,
          earnedAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
          source: 'FUEL_PURCHASE',
        }],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } else {
      // Mettre à jour carte existante
      const cardDoc = loyaltySnapshot.docs[0];
      const card = cardDoc.data();
      const newTotal = card.totalPoints + points;
      const newTier = calculateTier(newTotal);
      
      transaction.update(cardDoc.ref, {
        totalPoints: newTotal,
        availablePoints: card.availablePoints + points,
        tier: newTier,
        pointsHistory: admin.firestore.FieldValue.arrayUnion({
          points: points,
          earnedAt: admin.firestore.FieldValue.serverTimestamp(),
          expiresAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
          source: 'FUEL_PURCHASE',
        }),
      });
    }
    
    // Mettre à jour transaction avec points
    transaction.update(txRef, {
      pointsEarned: points,
    });
    
    return {
      success: true,
      transactionId: txRef.id,
      newBalance: wallet.balance - totalAmount,
      pointsEarned: points,
    };
  });
});

function calculateLoyaltyPoints(amount, liters) {
  const pointsFromAmount = Math.floor(amount / 1000);
  const pointsFromLiters = Math.floor(liters);
  return pointsFromAmount + pointsFromLiters;
}

function calculateTier(totalPoints) {
  if (totalPoints >= 10000) return 'PLATINUM';
  if (totalPoints >= 5000) return 'GOLD';
  if (totalPoints >= 2000) return 'SILVER';
  return 'BRONZE';
}