import 'package:flutter/material.dart';

class _Translations {
  final String welcomeTitle, welcomeGreeting, welcomeSubtitle;
  final String login, register, chooseLanguage;
  final String phoneNumber, password, fullName;
  final String confirm, cancel, or;
  final String alreadyHaveAccount, noAccount, forgotPassword;
  final String otpTitle, otpSending, otpEnterCode, otpSentTo, otpValidate;
  final String otpResend, otpResendIn, otpModifyNumber, otpWaiting;
  final String otpInvalidCode, otpExpired, otpTooMany, otpNetworkError;
  final String hello, balance, loyaltyPoints;
  final String history, profile, home;
  final String fuel, carWash, maintenance, otherServices;
  final String promotions, noPromotion;
  final String monthlyExpenses, noTransaction;
  final String scanQr, confirmPayment, amount, paymentSuccess;
  final String product, station, attendant, willBeDebited;
  final String receiptTitle, date, reference, client, amountPaid, thankYou;
  final String print, ok, download;
  final String successStatus, pendingStatus, cancelledStatus;
  final String verified, payment, recharge;
  final String connectToAccount, phoneTab, identifierTab, enterPhone, yourIdentifier;
  final String connect, forgotPasswordQ, noAccountYet, createAccount;
  final String errorSms, unknownError, unexpectedError;
  final String otpVerification, enterSmsCode, validate, back, incorrectCode;
  final String inscription, yourFullName, selectCompany, confirmPassword;
  final String acceptTerms, termsText, termsPoints, iAccept, readPrivacy;
  final String mustSelectCompany, mustAcceptTerms, passwordsMismatch;
  final String enterFullName, enterNumber, enterPassword, min6chars;
  final String chooseCountry, chooseCompany, canChangeLater, acceptConditions;
  final String availableBalance, loyaltyPointsLabel;
  final String statusVerified, statusNotVerified, status;
  final String seeAll, transactions, thisMonth, chooseCompanyPrompt;
  final String wash, fuelMaintenance, other;
  final String profileTitle, informations, preferredCompany, qrCode;
  final String helpCenter, about, logout;
  final String logoutConfirmTitle, logoutConfirmContent, disconnect, appVersion;
  final String editProfile, saveChanges, profileUpdated, updateError, notConnected, readOnly;
  final String registrationSuccess, redirecting, registrationTitle;
  final String required, errorUnknown;
  final String historyTitle, noTransactionYet, noTransactionSub;
  final String paymentLabel, rechargeLabel, corporateLabel;
  final String successLabel, pendingLabel, cashback;
  final String indexMissing, loadingError, createIndexHint;
  final String notificationsTitle, markAllRead, allMarkedRead;
  final String notificationDeleted, noNotification, noNotificationSub;
  final String privacyTitle, contactUs, yesterday;
  final String clientReceiptTitle, downloadReceipt, loyaltyPointsReceiptLabel;
  final String myQrCode, scanQrStation, scanQrTitle, scanQrSub;
  final String notStationQr, invalidQr, paymentSuccessMsg;
  final String insufficientBalance, confirmPaymentTitle, debitedFrom;
  final String annuler, confirmer;
  final String paymentSuccessTitle, receiptNumber, compagnie, paymentMethod;
  final String cashbackEarned, transactionId, downloadingReceipt, share, downloadBtn;
  final String activePromos, expiredPromos, noPromoAvailable, noPromoSub;
  final String seeDetails, expired, validityPeriod, conditions;
  final String alreadyParticipated, participationSuccess, participationError, promoNotFound;
  final String maskCard;
  // ✅ Privacy policy sections
  final String privacyIntro;
  final String privacySection1Title, privacySection1Content;
  final String privacySection2Title, privacySection2Content;
  final String privacySection3Title, privacySection3Content;
  final String privacySection4Title, privacySection4Content;
  final String privacySection5Title, privacySection5Content;
  final String privacySection6Title, privacySection6Content;
  final String privacySection7Title, privacySection7Content;
  final String privacySection8Title, privacySection8Content;
  final String privacyContactEmail;
  // ✅ NOUVEAUX CHAMPS MANQUANTS
  final String fillFormToRegister;
  final String passwordMismatch;
  final String codeSent;
  final String verifyPhone;
  final String verify;
  final String resend;
  final String didntReceiveCode;
  final String codeSentTo;

  const _Translations({
    required this.welcomeTitle, required this.welcomeGreeting, required this.welcomeSubtitle,
    required this.login, required this.register, required this.chooseLanguage,
    required this.phoneNumber, required this.password, required this.fullName,
    required this.confirm, required this.cancel, required this.or,
    required this.alreadyHaveAccount, required this.noAccount, required this.forgotPassword,
    required this.otpTitle, required this.otpSending, required this.otpEnterCode,
    required this.otpSentTo, required this.otpValidate, required this.otpResend,
    required this.otpResendIn, required this.otpModifyNumber, required this.otpWaiting,
    required this.otpInvalidCode, required this.otpExpired,
    required this.otpTooMany, required this.otpNetworkError,
    required this.hello, required this.balance, required this.loyaltyPoints,
    required this.history, required this.profile, required this.home,
    required this.fuel, required this.carWash, required this.maintenance,
    required this.otherServices, required this.promotions, required this.noPromotion,
    required this.monthlyExpenses, required this.noTransaction,
    required this.scanQr, required this.confirmPayment, required this.amount,
    required this.paymentSuccess, required this.product,
    required this.station, required this.attendant, required this.willBeDebited,
    required this.receiptTitle, required this.date, required this.reference,
    required this.client, required this.amountPaid, required this.thankYou,
    required this.print, required this.ok, required this.download,
    required this.successStatus, required this.pendingStatus, required this.cancelledStatus,
    required this.verified, required this.payment, required this.recharge,
    required this.connectToAccount, required this.phoneTab, required this.identifierTab,
    required this.enterPhone, required this.yourIdentifier, required this.connect,
    required this.forgotPasswordQ, required this.noAccountYet, required this.createAccount,
    required this.errorSms, required this.unknownError, required this.unexpectedError,
    required this.otpVerification, required this.enterSmsCode, required this.validate,
    required this.back, required this.incorrectCode,
    required this.inscription, required this.yourFullName, required this.selectCompany,
    required this.confirmPassword, required this.acceptTerms, required this.termsText,
    required this.termsPoints, required this.iAccept, required this.readPrivacy,
    required this.mustSelectCompany, required this.mustAcceptTerms,
    required this.passwordsMismatch, required this.enterFullName,
    required this.enterNumber, required this.enterPassword, required this.min6chars,
    required this.chooseCountry, required this.chooseCompany, required this.canChangeLater,
    required this.acceptConditions,
    required this.availableBalance, required this.loyaltyPointsLabel,
    required this.statusVerified, required this.statusNotVerified, required this.status,
    required this.seeAll, required this.transactions, required this.thisMonth,
    required this.chooseCompanyPrompt, required this.wash,
    required this.fuelMaintenance, required this.other,
    required this.profileTitle, required this.informations, required this.preferredCompany,
    required this.qrCode, required this.helpCenter, required this.about, required this.logout,
    required this.logoutConfirmTitle, required this.logoutConfirmContent,
    required this.disconnect, required this.appVersion,
    required this.editProfile, required this.saveChanges, required this.profileUpdated,
    required this.updateError, required this.notConnected, required this.readOnly,
    required this.registrationSuccess, required this.redirecting, required this.registrationTitle,
    required this.required, required this.errorUnknown,
    required this.historyTitle, required this.noTransactionYet, required this.noTransactionSub,
    required this.paymentLabel, required this.rechargeLabel, required this.corporateLabel,
    required this.successLabel, required this.pendingLabel, required this.cashback,
    required this.indexMissing, required this.loadingError, required this.createIndexHint,
    required this.notificationsTitle, required this.markAllRead, required this.allMarkedRead,
    required this.notificationDeleted, required this.noNotification, required this.noNotificationSub,
    required this.privacyTitle, required this.contactUs, required this.yesterday,
    required this.clientReceiptTitle, required this.downloadReceipt,
    required this.loyaltyPointsReceiptLabel,
    required this.myQrCode, required this.scanQrStation, required this.scanQrTitle,
    required this.scanQrSub, required this.notStationQr, required this.invalidQr,
    required this.paymentSuccessMsg, required this.insufficientBalance,
    required this.confirmPaymentTitle, required this.debitedFrom,
    required this.annuler, required this.confirmer,
    required this.paymentSuccessTitle, required this.receiptNumber,
    required this.compagnie, required this.paymentMethod, required this.cashbackEarned,
    required this.transactionId, required this.downloadingReceipt,
    required this.share, required this.downloadBtn,
    required this.activePromos, required this.expiredPromos,
    required this.noPromoAvailable, required this.noPromoSub,
    required this.seeDetails, required this.expired,
    required this.validityPeriod, required this.conditions,
    required this.alreadyParticipated, required this.participationSuccess,
    required this.participationError, required this.promoNotFound,
    required this.maskCard,
    required this.privacyIntro,
    required this.privacySection1Title, required this.privacySection1Content,
    required this.privacySection2Title, required this.privacySection2Content,
    required this.privacySection3Title, required this.privacySection3Content,
    required this.privacySection4Title, required this.privacySection4Content,
    required this.privacySection5Title, required this.privacySection5Content,
    required this.privacySection6Title, required this.privacySection6Content,
    required this.privacySection7Title, required this.privacySection7Content,
    required this.privacySection8Title, required this.privacySection8Content,
    required this.privacyContactEmail,
    required this.fillFormToRegister,
    required this.passwordMismatch,
    required this.codeSent,
    required this.verifyPhone,
    required this.verify,
    required this.resend,
    required this.didntReceiveCode,
    required this.codeSentTo,
  });
}

// ── 🇫🇷 Français ──────────────────────────────────────────────────────────────
const _fr = _Translations(
  welcomeTitle: 'Bienvenue sur GPay', welcomeGreeting: 'Bienvenue',
  welcomeSubtitle: 'Accédez à votre portefeuille ou créez un compte.',
  login: 'Se connecter', register: 'Créer un compte', chooseLanguage: 'Choisir la langue',
  phoneNumber: 'Numéro de téléphone', password: 'Mot de passe', fullName: 'Nom complet',
  confirm: 'Confirmer', cancel: 'Annuler', or: 'ou',
  alreadyHaveAccount: 'Déjà un compte ?', noAccount: 'Pas de compte ?',
  forgotPassword: 'Mot de passe oublié ?',
  otpTitle: 'Vérification', otpSending: 'Envoi du code SMS...',
  otpEnterCode: 'Entrez le code reçu par SMS', otpSentTo: 'Code envoyé au',
  otpValidate: 'Valider', otpResend: 'Renvoyer le code',
  otpResendIn: 'Renvoyer dans', otpModifyNumber: 'Modifier le numéro',
  otpWaiting: 'Patientez quelques secondes',
  otpInvalidCode: 'Code incorrect. Vérifiez et réessayez.',
  otpExpired: 'Code expiré. Demandez un nouveau code.',
  otpTooMany: 'Trop de tentatives. Réessayez plus tard.',
  otpNetworkError: 'Problème réseau. Vérifiez votre connexion.',
  hello: 'Bonjour', balance: 'Solde disponible', loyaltyPoints: 'Points fidélité',
  history: 'Historique', profile: 'Profil', home: 'Accueil',
  fuel: 'Carburant', carWash: 'Lavage', maintenance: 'Entretien Carburant',
  otherServices: 'Autres Services', promotions: 'Promotions',
  noPromotion: 'Aucune promotion en cours',
  monthlyExpenses: 'Dépenses du mois', noTransaction: 'Aucune transaction',
  scanQr: 'Scanner le QR Code', confirmPayment: 'Confirmer le paiement', amount: 'Montant',
  paymentSuccess: 'Paiement effectué avec succès !',
  product: 'Produit', station: 'Station', attendant: 'Pompiste',
  willBeDebited: 'sera débité de votre solde',
  receiptTitle: 'Reçu Client Vente', date: 'Date', reference: 'Référence', client: 'Client',
  amountPaid: 'Montant Payé', thankYou: 'Merci pour votre fidélité',
  print: 'Print', ok: 'Ok', download: 'Télécharger le reçu',
  successStatus: 'Réussi', pendingStatus: 'En attente', cancelledStatus: 'Annulé',
  verified: 'Vérifié', payment: 'Paiement', recharge: 'Recharge',
  connectToAccount: 'Connectez-vous à votre compte',
  phoneTab: 'Téléphone', identifierTab: 'Identifiant',
  enterPhone: 'Entrer numéro téléphone', yourIdentifier: 'Votre identifiant (8 chiffres)',
  connect: 'Se connecter', forgotPasswordQ: 'Mot de passe oublié ?',
  noAccountYet: 'Pas encore de compte ? ', createAccount: 'Créer un compte',
  errorSms: 'Erreur SMS', unknownError: 'Erreur inconnue', unexpectedError: 'Erreur inattendue',
  otpVerification: 'Vérification', enterSmsCode: 'Entrez le code reçu par SMS',
  validate: 'Valider', back: 'Retour', incorrectCode: 'Code incorrect',
  inscription: 'Inscription', yourFullName: 'Votre Nom Complet',
  selectCompany: 'Sélectionnez votre compagnie pétrolière',
  confirmPassword: 'Confirmer mot de passe', acceptTerms: 'Conditions d\'utilisation',
  termsText: 'En créant votre compte, vous acceptez les Conditions Générales de SenPay et l\'utilisation de Cardoil.',
  termsPoints: '• Vos données sont protégées.\n• Toute utilisation frauduleuse entraîne la suspension du compte.',
  iAccept: 'J\'accepte les conditions', readPrivacy: 'Lire la politique de confidentialité →',
  mustSelectCompany: 'Veuillez sélectionner une compagnie',
  mustAcceptTerms: 'Vous devez accepter les conditions',
  passwordsMismatch: 'Les mots de passe ne correspondent pas',
  enterFullName: 'Entrez votre nom complet', enterNumber: 'Entrez votre numéro',
  enterPassword: 'Entrez un mot de passe', min6chars: 'Minimum 6 caractères',
  chooseCountry: 'Choisir un pays', chooseCompany: 'Choisir votre compagnie',
  canChangeLater: 'Vous pourrez en changer plus tard',
  acceptConditions: 'Acceptez les conditions pour continuer',
  availableBalance: 'Solde disponible', loyaltyPointsLabel: 'Points fidélité',
  statusVerified: 'Vérifié', statusNotVerified: 'Non vérifié', status: 'Statut',
  seeAll: 'Voir tout', transactions: 'transaction', thisMonth: 'ce mois',
  chooseCompanyPrompt: 'Choisir une compagnie',
  wash: 'Lavage', fuelMaintenance: 'Entretien\nCarburant', other: 'Autres\nServices',
  profileTitle: 'Profil', informations: 'Informations',
  preferredCompany: 'Compagnie préférée', qrCode: 'Code QR',
  helpCenter: 'Centre d\'aide', about: 'À propos',
  logout: 'Se déconnecter', logoutConfirmTitle: 'Déconnexion',
  logoutConfirmContent: 'Voulez-vous vraiment vous déconnecter ?',
  disconnect: 'Déconnecter', appVersion: '© 2026 Card Oil',
  editProfile: 'Modifier le profil', saveChanges: 'Enregistrer',
  profileUpdated: 'Profil mis à jour avec succès',
  updateError: 'Erreur lors de la mise à jour',
  notConnected: 'Utilisateur non connecté', readOnly: 'Téléphone',
  registrationSuccess: 'Inscription réussie', redirecting: 'Redirection en cours...',
  registrationTitle: 'Inscrire', required: 'Requis', errorUnknown: 'Erreur inconnue',
  historyTitle: 'Historique', noTransactionYet: 'Aucune transaction',
  noTransactionSub: 'Vos transactions apparaîtront ici\naprès votre premier paiement',
  paymentLabel: 'Paiement', rechargeLabel: 'Recharge', corporateLabel: 'Corporate',
  successLabel: 'Réussi', pendingLabel: 'En attente', cashback: 'cashback',
  indexMissing: 'Index Firestore manquant', loadingError: 'Erreur de chargement',
  createIndexHint: 'Créez l\'index dans Firebase Console :\nclient_transactions → clientId + createdAt',
  notificationsTitle: 'Notifications', markAllRead: 'Tout lire',
  allMarkedRead: 'Toutes les notifications marquées comme lues',
  notificationDeleted: 'Notification supprimée',
  noNotification: 'Aucune notification', noNotificationSub: 'Vous recevrez vos notifications ici',
  privacyTitle: 'Politique de confidentialité', contactUs: 'Nous contacter', yesterday: 'Hier',
  clientReceiptTitle: 'Reçu Client Achat', downloadReceipt: 'Télécharger le reçu',
  loyaltyPointsReceiptLabel: 'Points de fidélité:',
  myQrCode: 'Mon QR Code', scanQrStation: 'Scanner un code station',
  scanQrTitle: 'Scanner le QR code',
  scanQrSub: 'Placez le QR code de la station dans le cadre',
  notStationQr: 'Ce QR n\'est pas un code de station',
  invalidQr: 'QR Code invalide', paymentSuccessMsg: 'Paiement effectué avec succès !',
  insufficientBalance: 'Solde insuffisant',
  confirmPaymentTitle: 'Confirmer le paiement',
  debitedFrom: 'sera débité de votre solde',
  annuler: 'Annuler', confirmer: 'Confirmer',
  paymentSuccessTitle: 'Paiement réussi', receiptNumber: 'Numéro de reçu',
  compagnie: 'Compagnie', paymentMethod: 'Méthode de paiement',
  cashbackEarned: 'Cashback gagné', transactionId: 'Transaction ID',
  downloadingReceipt: 'Téléchargement du reçu...', share: 'Partager', downloadBtn: 'Télécharger',
  activePromos: 'Promotions actives', expiredPromos: 'Promotions expirées',
  noPromoAvailable: 'Aucune promotion disponible', noPromoSub: 'Les promotions apparaîtront ici',
  seeDetails: 'Voir les détails', expired: 'Expirée',
  validityPeriod: 'Période de validité', conditions: 'Conditions',
  alreadyParticipated: 'Vous avez déjà participé à cette promotion',
  participationSuccess: 'Participation enregistrée avec succès !',
  participationError: 'Erreur lors de la participation', promoNotFound: 'Promotion introuvable',
  maskCard: 'Masquer la carte',
  privacyIntro: 'Chez Senpay, nous nous engageons à protéger la confidentialité et la sécurité des informations personnelles de nos utilisateurs. Cette politique décrit la manière dont nous collectons, utilisons et protégeons vos informations.',
  privacySection1Title: '1. Informations que nous collectons',
  privacySection1Content: 'Informations personnelles : nom, adresse e-mail, numéro de téléphone lors de la création de compte ou d\'une transaction.\n\nInformations d\'utilisation : comment vous interagissez avec notre application.',
  privacySection2Title: '2. Comment nous utilisons vos informations',
  privacySection2Content: 'Pour fournir nos services, traiter les transactions et gérer votre compte.\n\nPour améliorer nos services et analyser les tendances d\'utilisation.\n\nPour vous envoyer des mises à jour importantes et des notifications.',
  privacySection3Title: '3. Partage d\'informations',
  privacySection3Content: 'Senpay ne partage pas vos informations avec des prestataires de services tiers.',
  privacySection4Title: '4. Sécurité des données',
  privacySection4Content: 'Nous mettons en œuvre des mesures de sécurité standard pour protéger vos informations contre tout accès non autorisé.',
  privacySection5Title: '5. Vos choix',
  privacySection5Content: 'Vous pouvez accéder, mettre à jour ou supprimer vos informations personnelles en contactant notre équipe d\'assistance.',
  privacySection6Title: '6. Confidentialité des enfants',
  privacySection6Content: 'Nos services ne sont pas destinés aux personnes de moins de 18 ans. Nous ne collectons pas sciemment de données auprès de mineurs.',
  privacySection7Title: '7. Modifications de cette politique',
  privacySection7Content: 'Nous nous réservons le droit de mettre à jour cette politique à tout moment. Les changements seront publiés sur notre site.',
  privacySection8Title: '8. Contactez-nous',
  privacySection8Content: 'Pour toute question concernant notre politique de confidentialité :',
  privacyContactEmail: 'contact@senpay.io',
  // ✅ NOUVEAUX
  fillFormToRegister: 'Remplissez le formulaire pour vous inscrire',
  passwordMismatch: 'Les mots de passe ne correspondent pas',
  codeSent: 'Code renvoyé !',
  verifyPhone: 'Vérification du numéro',
  verify: 'Vérifier',
  resend: 'Renvoyer',
  didntReceiveCode: 'Vous n\'avez pas reçu le code ?',
  codeSentTo: 'Code envoyé au',
);

// ── 🇬🇧 English ────────────────────────────────────────────────────────────────
const _en = _Translations(
  welcomeTitle: 'Welcome to GPay', welcomeGreeting: 'Welcome',
  welcomeSubtitle: 'Access your wallet or create an account.',
  login: 'Sign in', register: 'Create account', chooseLanguage: 'Choose language',
  phoneNumber: 'Phone number', password: 'Password', fullName: 'Full name',
  confirm: 'Confirm', cancel: 'Cancel', or: 'or',
  alreadyHaveAccount: 'Already have an account?', noAccount: 'No account?',
  forgotPassword: 'Forgot password?',
  otpTitle: 'Verification', otpSending: 'Sending SMS code...',
  otpEnterCode: 'Enter the code received by SMS', otpSentTo: 'Code sent to',
  otpValidate: 'Validate', otpResend: 'Resend code',
  otpResendIn: 'Resend in', otpModifyNumber: 'Change number',
  otpWaiting: 'Please wait a few seconds',
  otpInvalidCode: 'Incorrect code. Check and try again.',
  otpExpired: 'Code expired. Request a new code.',
  otpTooMany: 'Too many attempts. Try again later.',
  otpNetworkError: 'Network error. Check your connection.',
  hello: 'Hello', balance: 'Available balance', loyaltyPoints: 'Loyalty points',
  history: 'History', profile: 'Profile', home: 'Home',
  fuel: 'Fuel', carWash: 'Car Wash', maintenance: 'Fuel Maintenance',
  otherServices: 'Other Services', promotions: 'Promotions',
  noPromotion: 'No promotion in progress',
  monthlyExpenses: 'Monthly expenses', noTransaction: 'No transactions yet',
  scanQr: 'Scan QR Code', confirmPayment: 'Confirm payment', amount: 'Amount',
  paymentSuccess: 'Payment successful!',
  product: 'Product', station: 'Station', attendant: 'Attendant',
  willBeDebited: 'will be deducted from your balance',
  receiptTitle: 'Customer Sales Receipt', date: 'Date', reference: 'Reference', client: 'Client',
  amountPaid: 'Amount Paid', thankYou: 'Thank you for your loyalty',
  print: 'Print', ok: 'Ok', download: 'Download receipt',
  successStatus: 'Successful', pendingStatus: 'Pending', cancelledStatus: 'Cancelled',
  verified: 'Verified', payment: 'Payment', recharge: 'Top-up',
  connectToAccount: 'Sign in to your account',
  phoneTab: 'Phone', identifierTab: 'Identifier',
  enterPhone: 'Enter phone number', yourIdentifier: 'Your identifier (8 digits)',
  connect: 'Sign in', forgotPasswordQ: 'Forgot password?',
  noAccountYet: 'No account yet? ', createAccount: 'Create account',
  errorSms: 'SMS error', unknownError: 'Unknown error', unexpectedError: 'Unexpected error',
  otpVerification: 'Verification', enterSmsCode: 'Enter the code received by SMS',
  validate: 'Validate', back: 'Back', incorrectCode: 'Incorrect code',
  inscription: 'Register', yourFullName: 'Your Full Name',
  selectCompany: 'Select your oil company',
  confirmPassword: 'Confirm password', acceptTerms: 'Terms of use',
  termsText: 'By creating your account, you agree to SenPay\'s General Terms and the use of Cardoil.',
  termsPoints: '• Your data is protected.\n• Fraudulent use results in account suspension.',
  iAccept: 'I accept the terms', readPrivacy: 'Read the privacy policy →',
  mustSelectCompany: 'Please select a company',
  mustAcceptTerms: 'You must accept the terms',
  passwordsMismatch: 'Passwords do not match',
  enterFullName: 'Enter your full name', enterNumber: 'Enter your number',
  enterPassword: 'Enter a password', min6chars: 'Minimum 6 characters',
  chooseCountry: 'Choose a country', chooseCompany: 'Choose your company',
  canChangeLater: 'You can change it later',
  acceptConditions: 'Accept the terms to continue',
  availableBalance: 'Available balance', loyaltyPointsLabel: 'Loyalty points',
  statusVerified: 'Verified', statusNotVerified: 'Not verified', status: 'Status',
  seeAll: 'See all', transactions: 'transaction', thisMonth: 'this month',
  chooseCompanyPrompt: 'Choose a company',
  wash: 'Car Wash', fuelMaintenance: 'Fuel\nMaintenance', other: 'Other\nServices',
  profileTitle: 'Profile', informations: 'Information',
  preferredCompany: 'Preferred company', qrCode: 'QR Code',
  helpCenter: 'Help center', about: 'About',
  logout: 'Sign out', logoutConfirmTitle: 'Sign out',
  logoutConfirmContent: 'Do you really want to sign out?',
  disconnect: 'Sign out', appVersion: '© 2026 Card Oil',
  editProfile: 'Edit profile', saveChanges: 'Save',
  profileUpdated: 'Profile updated successfully',
  updateError: 'Update error', notConnected: 'User not connected', readOnly: 'Phone',
  registrationSuccess: 'Registration successful', redirecting: 'Redirecting...',
  registrationTitle: 'Register', required: 'Required', errorUnknown: 'Unknown error',
  historyTitle: 'History', noTransactionYet: 'No transactions yet',
  noTransactionSub: 'Your transactions will appear here\nafter your first payment',
  paymentLabel: 'Payment', rechargeLabel: 'Top-up', corporateLabel: 'Corporate',
  successLabel: 'Successful', pendingLabel: 'Pending', cashback: 'cashback',
  indexMissing: 'Firestore index missing', loadingError: 'Loading error',
  createIndexHint: 'Create index in Firebase Console:\nclient_transactions → clientId + createdAt',
  notificationsTitle: 'Notifications', markAllRead: 'Mark all read',
  allMarkedRead: 'All notifications marked as read',
  notificationDeleted: 'Notification deleted',
  noNotification: 'No notifications', noNotificationSub: 'You will receive your notifications here',
  privacyTitle: 'Privacy Policy', contactUs: 'Contact us', yesterday: 'Yesterday',
  clientReceiptTitle: 'Client Purchase Receipt', downloadReceipt: 'Download receipt',
  loyaltyPointsReceiptLabel: 'Loyalty points:',
  myQrCode: 'My QR Code', scanQrStation: 'Scan station code',
  scanQrTitle: 'Scan QR code',
  scanQrSub: 'Place the station QR code in the frame',
  notStationQr: 'This QR is not a station code',
  invalidQr: 'Invalid QR Code', paymentSuccessMsg: 'Payment successful!',
  insufficientBalance: 'Insufficient balance',
  confirmPaymentTitle: 'Confirm payment',
  debitedFrom: 'will be deducted from your balance',
  annuler: 'Cancel', confirmer: 'Confirm',
  paymentSuccessTitle: 'Payment successful', receiptNumber: 'Receipt number',
  compagnie: 'Company', paymentMethod: 'Payment method',
  cashbackEarned: 'Cashback earned', transactionId: 'Transaction ID',
  downloadingReceipt: 'Downloading receipt...', share: 'Share', downloadBtn: 'Download',
  activePromos: 'Active promotions', expiredPromos: 'Expired promotions',
  noPromoAvailable: 'No promotions available', noPromoSub: 'Promotions will appear here',
  seeDetails: 'See details', expired: 'Expired',
  validityPeriod: 'Validity period', conditions: 'Conditions',
  alreadyParticipated: 'You have already participated in this promotion',
  participationSuccess: 'Participation registered successfully!',
  participationError: 'Error during participation', promoNotFound: 'Promotion not found',
  maskCard: 'Hide card',
  privacyIntro: 'At Senpay, we are committed to protecting the privacy and security of our users\' personal information. This policy describes how we collect, use and protect your information.',
  privacySection1Title: '1. Information we collect',
  privacySection1Content: 'Personal information: name, email address, phone number when creating an account or making a transaction.\n\nUsage information: how you interact with our application.',
  privacySection2Title: '2. How we use your information',
  privacySection2Content: 'To provide our services, process transactions and manage your account.\n\nTo improve our services and analyze usage trends.\n\nTo send you important updates and notifications.',
  privacySection3Title: '3. Information sharing',
  privacySection3Content: 'Senpay does not share your information with third-party service providers.',
  privacySection4Title: '4. Data security',
  privacySection4Content: 'We implement industry-standard security measures to protect your information from unauthorized access.',
  privacySection5Title: '5. Your choices',
  privacySection5Content: 'You can access, update or delete your personal information by contacting our support team.',
  privacySection6Title: '6. Children\'s privacy',
  privacySection6Content: 'Our services are not intended for persons under 18 years of age. We do not knowingly collect data from minors.',
  privacySection7Title: '7. Changes to this policy',
  privacySection7Content: 'We reserve the right to update this policy at any time. Changes will be posted on our website.',
  privacySection8Title: '8. Contact us',
  privacySection8Content: 'For any questions regarding our privacy policy:',
  privacyContactEmail: 'contact@senpay.io',
  fillFormToRegister: 'Fill in the form to register',
  passwordMismatch: 'Passwords do not match',
  codeSent: 'Code resent!',
  verifyPhone: 'Phone verification',
  verify: 'Verify',
  resend: 'Resend',
  didntReceiveCode: 'Didn\'t receive the code?',
  codeSentTo: 'Code sent to',
);

// ── 🇸🇦 العربية ──────────────────────────────────────────────────────────────
const _ar = _Translations(
  welcomeTitle: 'مرحباً بك في GPay', welcomeGreeting: 'مرحباً',
  welcomeSubtitle: 'ادخل إلى محفظتك أو أنشئ حساباً.',
  login: 'تسجيل الدخول', register: 'إنشاء حساب', chooseLanguage: 'اختر اللغة',
  phoneNumber: 'رقم الهاتف', password: 'كلمة المرور', fullName: 'الاسم الكامل',
  confirm: 'تأكيد', cancel: 'إلغاء', or: 'أو',
  alreadyHaveAccount: 'هل لديك حساب؟', noAccount: 'ليس لديك حساب؟',
  forgotPassword: 'نسيت كلمة المرور؟',
  otpTitle: 'التحقق', otpSending: 'جارٍ إرسال رمز SMS...',
  otpEnterCode: 'أدخل الرمز المستلم عبر SMS', otpSentTo: 'تم إرسال الرمز إلى',
  otpValidate: 'تحقق', otpResend: 'إعادة إرسال الرمز',
  otpResendIn: 'إعادة الإرسال خلال', otpModifyNumber: 'تعديل الرقم',
  otpWaiting: 'يرجى الانتظار لحظات',
  otpInvalidCode: 'الرمز غير صحيح. تحقق وحاول مجدداً.',
  otpExpired: 'انتهت صلاحية الرمز. اطلب رمزاً جديداً.',
  otpTooMany: 'محاولات كثيرة جداً. حاول لاحقاً.',
  otpNetworkError: 'خطأ في الشبكة. تحقق من اتصالك.',
  hello: 'مرحباً', balance: 'الرصيد المتاح', loyaltyPoints: 'نقاط الولاء',
  history: 'السجل', profile: 'الملف الشخصي', home: 'الرئيسية',
  fuel: 'الوقود', carWash: 'غسيل السيارة', maintenance: 'صيانة الوقود',
  otherServices: 'خدمات أخرى', promotions: 'العروض',
  noPromotion: 'لا توجد عروض حالياً',
  monthlyExpenses: 'مصاريف الشهر', noTransaction: 'لا توجد معاملات بعد',
  scanQr: 'مسح رمز QR', confirmPayment: 'تأكيد الدفع', amount: 'المبلغ',
  paymentSuccess: 'تمت عملية الدفع بنجاح!',
  product: 'المنتج', station: 'المحطة', attendant: 'عامل المحطة',
  willBeDebited: 'سيتم خصمه من رصيدك',
  receiptTitle: 'إيصال العميل', date: 'التاريخ', reference: 'المرجع', client: 'العميل',
  amountPaid: 'المبلغ المدفوع', thankYou: 'شكراً لولائك',
  print: 'طباعة', ok: 'موافق', download: 'تحميل الإيصال',
  successStatus: 'ناجح', pendingStatus: 'قيد الانتظار', cancelledStatus: 'ملغي',
  verified: 'موثق', payment: 'دفع', recharge: 'شحن',
  connectToAccount: 'سجّل دخولك إلى حسابك',
  phoneTab: 'الهاتف', identifierTab: 'المعرّف',
  enterPhone: 'أدخل رقم الهاتف', yourIdentifier: 'معرّفك (8 أرقام)',
  connect: 'تسجيل الدخول', forgotPasswordQ: 'نسيت كلمة المرور؟',
  noAccountYet: 'ليس لديك حساب؟ ', createAccount: 'إنشاء حساب',
  errorSms: 'خطأ في الرسالة', unknownError: 'خطأ غير معروف', unexpectedError: 'خطأ غير متوقع',
  otpVerification: 'التحقق', enterSmsCode: 'أدخل الرمز المستلم عبر SMS',
  validate: 'تأكيد', back: 'رجوع', incorrectCode: 'الرمز غير صحيح',
  inscription: 'التسجيل', yourFullName: 'اسمك الكامل',
  selectCompany: 'اختر شركة النفط الخاصة بك',
  confirmPassword: 'تأكيد كلمة المرور', acceptTerms: 'شروط الاستخدام',
  termsText: 'بإنشاء حسابك، فإنك توافق على الشروط العامة لـ SenPay واستخدام Cardoil.',
  termsPoints: '• بياناتك محمية.\n• أي استخدام احتيالي سيؤدي إلى تعليق الحساب.',
  iAccept: 'أوافق على الشروط', readPrivacy: 'قراءة سياسة الخصوصية →',
  mustSelectCompany: 'يرجى اختيار شركة', mustAcceptTerms: 'يجب قبول الشروط',
  passwordsMismatch: 'كلمتا المرور غير متطابقتين',
  enterFullName: 'أدخل اسمك الكامل', enterNumber: 'أدخل رقمك',
  enterPassword: 'أدخل كلمة المرور', min6chars: 'الحد الأدنى 6 أحرف',
  chooseCountry: 'اختر بلداً', chooseCompany: 'اختر شركتك',
  canChangeLater: 'يمكنك تغييرها لاحقاً', acceptConditions: 'اقبل الشروط للمتابعة',
  availableBalance: 'الرصيد المتاح', loyaltyPointsLabel: 'نقاط الولاء',
  statusVerified: 'موثق', statusNotVerified: 'غير موثق', status: 'الحالة',
  seeAll: 'عرض الكل', transactions: 'معاملة', thisMonth: 'هذا الشهر',
  chooseCompanyPrompt: 'اختر شركة',
  wash: 'الغسيل', fuelMaintenance: 'صيانة\nالوقود', other: 'خدمات\nأخرى',
  profileTitle: 'الملف الشخصي', informations: 'المعلومات',
  preferredCompany: 'الشركة المفضلة', qrCode: 'رمز QR',
  helpCenter: 'مركز المساعدة', about: 'حول التطبيق',
  logout: 'تسجيل الخروج', logoutConfirmTitle: 'تسجيل الخروج',
  logoutConfirmContent: 'هل تريد فعلاً تسجيل الخروج؟',
  disconnect: 'خروج', appVersion: '© 2026 Card Oil',
  editProfile: 'تعديل الملف الشخصي', saveChanges: 'حفظ',
  profileUpdated: 'تم تحديث الملف بنجاح',
  updateError: 'خطأ في التحديث', notConnected: 'المستخدم غير متصل', readOnly: 'الهاتف',
  registrationSuccess: 'تم التسجيل بنجاح', redirecting: 'جارٍ إعادة التوجيه...',
  registrationTitle: 'التسجيل', required: 'مطلوب', errorUnknown: 'خطأ غير معروف',
  historyTitle: 'السجل', noTransactionYet: 'لا توجد معاملات بعد',
  noTransactionSub: 'ستظهر معاملاتك هنا\nبعد أول عملية دفع',
  paymentLabel: 'دفع', rechargeLabel: 'شحن', corporateLabel: 'مؤسسي',
  successLabel: 'ناجح', pendingLabel: 'قيد الانتظار', cashback: 'استرداد نقدي',
  indexMissing: 'فهرس Firestore مفقود', loadingError: 'خطأ في التحميل',
  createIndexHint: 'أنشئ الفهرس في Firebase Console:\nclient_transactions → clientId + createdAt',
  notificationsTitle: 'الإشعارات', markAllRead: 'تحديد الكل كمقروء',
  allMarkedRead: 'تم تحديد جميع الإشعارات كمقروءة',
  notificationDeleted: 'تم حذف الإشعار',
  noNotification: 'لا توجد إشعارات', noNotificationSub: 'ستصلك إشعاراتك هنا',
  privacyTitle: 'سياسة الخصوصية', contactUs: 'اتصل بنا', yesterday: 'أمس',
  clientReceiptTitle: 'إيصال شراء العميل', downloadReceipt: 'تحميل الإيصال',
  loyaltyPointsReceiptLabel: 'نقاط الولاء:',
  myQrCode: 'رمز QR الخاص بي', scanQrStation: 'مسح رمز المحطة',
  scanQrTitle: 'مسح رمز QR', scanQrSub: 'ضع رمز QR الخاص بالمحطة في الإطار',
  notStationQr: 'هذا الرمز ليس رمز محطة',
  invalidQr: 'رمز QR غير صالح', paymentSuccessMsg: 'تمت عملية الدفع بنجاح!',
  insufficientBalance: 'الرصيد غير كافٍ',
  confirmPaymentTitle: 'تأكيد الدفع', debitedFrom: 'سيتم خصمه من رصيدك',
  annuler: 'إلغاء', confirmer: 'تأكيد',
  paymentSuccessTitle: 'تمت عملية الدفع بنجاح', receiptNumber: 'رقم الإيصال',
  compagnie: 'الشركة', paymentMethod: 'طريقة الدفع',
  cashbackEarned: 'استرداد نقدي', transactionId: 'معرّف المعاملة',
  downloadingReceipt: 'جارٍ تحميل الإيصال...', share: 'مشاركة', downloadBtn: 'تحميل',
  activePromos: 'العروض النشطة', expiredPromos: 'العروض المنتهية',
  noPromoAvailable: 'لا توجد عروض متاحة', noPromoSub: 'ستظهر العروض هنا',
  seeDetails: 'عرض التفاصيل', expired: 'منتهي الصلاحية',
  validityPeriod: 'فترة الصلاحية', conditions: 'الشروط',
  alreadyParticipated: 'لقد شاركت بالفعل في هذا العرض',
  participationSuccess: 'تم تسجيل مشاركتك بنجاح!',
  participationError: 'خطأ أثناء المشاركة', promoNotFound: 'العرض غير موجود',
  maskCard: 'إخفاء البطاقة',
  privacyIntro: 'في Senpay، نلتزم بحماية خصوصية وأمان المعلومات الشخصية لمستخدمينا. تصف هذه السياسة كيفية جمع معلوماتك واستخدامها وحمايتها.',
  privacySection1Title: '1. المعلومات التي نجمعها',
  privacySection1Content: 'المعلومات الشخصية: الاسم والبريد الإلكتروني ورقم الهاتف عند إنشاء حساب أو إجراء معاملة.\n\nمعلومات الاستخدام: كيفية تفاعلك مع تطبيقنا.',
  privacySection2Title: '2. كيفية استخدام معلوماتك',
  privacySection2Content: 'لتقديم خدماتنا ومعالجة المعاملات وإدارة حسابك.\n\nلتحسين خدماتنا وتحليل اتجاهات الاستخدام.\n\nلإرسال التحديثات المهمة والإشعارات إليك.',
  privacySection3Title: '3. مشاركة المعلومات',
  privacySection3Content: 'لا تشارك Senpay معلوماتك مع مزودي خدمات خارجيين.',
  privacySection4Title: '4. أمان البيانات',
  privacySection4Content: 'نطبق تدابير أمنية قياسية لحماية معلوماتك من الوصول غير المصرح به.',
  privacySection5Title: '5. خياراتك',
  privacySection5Content: 'يمكنك الوصول إلى معلوماتك الشخصية أو تحديثها أو حذفها عن طريق الاتصال بفريق الدعم.',
  privacySection6Title: '6. خصوصية الأطفال',
  privacySection6Content: 'خدماتنا غير مخصصة للأشخاص دون سن 18 عامًا. لا نجمع بيانات من القاصرين عن قصد.',
  privacySection7Title: '7. تغييرات على هذه السياسة',
  privacySection7Content: 'نحتفظ بالحق في تحديث هذه السياسة في أي وقت. سيتم نشر التغييرات على موقعنا.',
  privacySection8Title: '8. اتصل بنا',
  privacySection8Content: 'لأي أسئلة تتعلق بسياسة الخصوصية:',
  privacyContactEmail: 'contact@senpay.io',
  fillFormToRegister: 'أكمل النموذج للتسجيل',
  passwordMismatch: 'كلمتا المرور غير متطابقتين',
  codeSent: 'تم إعادة إرسال الرمز!',
  verifyPhone: 'التحقق من الرقم',
  verify: 'تحقق',
  resend: 'إعادة إرسال',
  didntReceiveCode: 'لم تستلم الرمز؟',
  codeSentTo: 'تم إرسال الرمز إلى',
);

// ═══════════════════════════════════════════════════════════════════════════
class AppLocalizations {
  final Locale locale;
  late final _Translations _t;

  AppLocalizations(this.locale) {
    switch (locale.languageCode) {
      case 'en': _t = _en; break;
      case 'ar': _t = _ar; break;
      default:   _t = _fr;
    }
  }

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      AppLocalizations(const Locale('fr'));

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isRtl => locale.languageCode == 'ar';
  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;

  // ── Tous les getters ────────────────────────────────────────────────────
  String get welcomeTitle         => _t.welcomeTitle;
  String get welcomeGreeting      => _t.welcomeGreeting;
  String get welcomeSubtitle      => _t.welcomeSubtitle;
  String get login                => _t.login;
  String get register             => _t.register;
  String get chooseLanguage       => _t.chooseLanguage;
  String get phoneNumber          => _t.phoneNumber;
  String get password             => _t.password;
  String get fullName             => _t.fullName;
  String get confirm              => _t.confirm;
  String get cancel               => _t.cancel;
  String get or                   => _t.or;
  String get alreadyHaveAccount   => _t.alreadyHaveAccount;
  String get noAccount            => _t.noAccount;
  String get forgotPassword       => _t.forgotPassword;
  String get otpTitle             => _t.otpTitle;
  String get otpSending           => _t.otpSending;
  String get otpEnterCode         => _t.otpEnterCode;
  String get otpSentTo            => _t.otpSentTo;
  String get otpValidate          => _t.otpValidate;
  String get otpResend            => _t.otpResend;
  String get otpResendIn          => _t.otpResendIn;
  String get otpModifyNumber      => _t.otpModifyNumber;
  String get otpWaiting           => _t.otpWaiting;
  String get otpInvalidCode       => _t.otpInvalidCode;
  String get otpExpired           => _t.otpExpired;
  String get otpTooMany           => _t.otpTooMany;
  String get otpNetworkError      => _t.otpNetworkError;
  String get hello                => _t.hello;
  String get balance              => _t.balance;
  String get loyaltyPoints        => _t.loyaltyPoints;
  String get history              => _t.history;
  String get profile              => _t.profile;
  String get home                 => _t.home;
  String get fuel                 => _t.fuel;
  String get carWash              => _t.carWash;
  String get maintenance          => _t.maintenance;
  String get otherServices        => _t.otherServices;
  String get promotions           => _t.promotions;
  String get noPromotion          => _t.noPromotion;
  String get monthlyExpenses      => _t.monthlyExpenses;
  String get noTransaction        => _t.noTransaction;
  String get scanQr               => _t.scanQr;
  String get confirmPayment       => _t.confirmPayment;
  String get amount               => _t.amount;
  String get paymentSuccess       => _t.paymentSuccess;
  String get product              => _t.product;
  String get station              => _t.station;
  String get attendant            => _t.attendant;
  String get willBeDebited        => _t.willBeDebited;
  String get receiptTitle         => _t.receiptTitle;
  String get date                 => _t.date;
  String get reference            => _t.reference;
  String get client               => _t.client;
  String get amountPaid           => _t.amountPaid;
  String get thankYou             => _t.thankYou;
  String get print                => _t.print;
  String get ok                   => _t.ok;
  String get download             => _t.download;
  String get successStatus        => _t.successStatus;
  String get pendingStatus        => _t.pendingStatus;
  String get cancelledStatus      => _t.cancelledStatus;
  String get verified             => _t.verified;
  String get payment              => _t.payment;
  String get recharge             => _t.recharge;
  String get connectToAccount     => _t.connectToAccount;
  String get phoneTab             => _t.phoneTab;
  String get identifierTab        => _t.identifierTab;
  String get enterPhone           => _t.enterPhone;
  String get yourIdentifier       => _t.yourIdentifier;
  String get connect              => _t.connect;
  String get forgotPasswordQ      => _t.forgotPasswordQ;
  String get noAccountYet         => _t.noAccountYet;
  String get createAccount        => _t.createAccount;
  String get errorSms             => _t.errorSms;
  String get unknownError         => _t.unknownError;
  String get unexpectedError      => _t.unexpectedError;
  String get otpVerification      => _t.otpVerification;
  String get enterSmsCode         => _t.enterSmsCode;
  String get validate             => _t.validate;
  String get back                 => _t.back;
  String get incorrectCode        => _t.incorrectCode;
  String get inscription          => _t.inscription;
  String get yourFullName         => _t.yourFullName;
  String get selectCompany        => _t.selectCompany;
  String get confirmPassword      => _t.confirmPassword;
  String get acceptTerms          => _t.acceptTerms;
  String get termsText            => _t.termsText;
  String get termsPoints          => _t.termsPoints;
  String get iAccept              => _t.iAccept;
  String get readPrivacy          => _t.readPrivacy;
  String get mustSelectCompany    => _t.mustSelectCompany;
  String get mustAcceptTerms      => _t.mustAcceptTerms;
  String get passwordsMismatch    => _t.passwordsMismatch;
  String get enterFullName        => _t.enterFullName;
  String get enterNumber          => _t.enterNumber;
  String get enterPassword        => _t.enterPassword;
  String get min6chars            => _t.min6chars;
  String get chooseCountry        => _t.chooseCountry;
  String get chooseCompany        => _t.chooseCompany;
  String get canChangeLater       => _t.canChangeLater;
  String get acceptConditions     => _t.acceptConditions;
  String get availableBalance     => _t.availableBalance;
  String get loyaltyPointsLabel   => _t.loyaltyPointsLabel;
  String get statusVerified       => _t.statusVerified;
  String get statusNotVerified    => _t.statusNotVerified;
  String get status               => _t.status;
  String get seeAll               => _t.seeAll;
  String get transactions         => _t.transactions;
  String get thisMonth            => _t.thisMonth;
  String get chooseCompanyPrompt  => _t.chooseCompanyPrompt;
  String get wash                 => _t.wash;
  String get fuelMaintenance      => _t.fuelMaintenance;
  String get other                => _t.other;
  String get profileTitle         => _t.profileTitle;
  String get informations         => _t.informations;
  String get preferredCompany     => _t.preferredCompany;
  String get qrCode               => _t.qrCode;
  String get helpCenter           => _t.helpCenter;
  String get about                => _t.about;
  String get logout               => _t.logout;
  String get logoutConfirmTitle   => _t.logoutConfirmTitle;
  String get logoutConfirmContent => _t.logoutConfirmContent;
  String get disconnect           => _t.disconnect;
  String get appVersion           => _t.appVersion;
  String get editProfile          => _t.editProfile;
  String get saveChanges          => _t.saveChanges;
  String get profileUpdated       => _t.profileUpdated;
  String get updateError          => _t.updateError;
  String get notConnected         => _t.notConnected;
  String get readOnly             => _t.readOnly;
  String get registrationSuccess  => _t.registrationSuccess;
  String get redirecting          => _t.redirecting;
  String get registrationTitle    => _t.registrationTitle;
  String get requiredField        => _t.required;
  String get errorUnknown         => _t.errorUnknown;
  String get historyTitle         => _t.historyTitle;
  String get noTransactionYet     => _t.noTransactionYet;
  String get noTransactionSub     => _t.noTransactionSub;
  String get paymentLabel         => _t.paymentLabel;
  String get rechargeLabel        => _t.rechargeLabel;
  String get corporateLabel       => _t.corporateLabel;
  String get successLabel         => _t.successLabel;
  String get pendingLabel         => _t.pendingLabel;
  String get cashback             => _t.cashback;
  String get indexMissing         => _t.indexMissing;
  String get loadingError         => _t.loadingError;
  String get createIndexHint      => _t.createIndexHint;
  String get notificationsTitle   => _t.notificationsTitle;
  String get markAllRead          => _t.markAllRead;
  String get allMarkedRead        => _t.allMarkedRead;
  String get notificationDeleted  => _t.notificationDeleted;
  String get noNotification       => _t.noNotification;
  String get noNotificationSub    => _t.noNotificationSub;
  String get privacyTitle         => _t.privacyTitle;
  String get contactUs            => _t.contactUs;
  String get yesterday            => _t.yesterday;
  String get clientReceiptTitle   => _t.clientReceiptTitle;
  String get downloadReceipt      => _t.downloadReceipt;
  String get loyaltyPointsReceiptLabel => _t.loyaltyPointsReceiptLabel;
  String get myQrCode             => _t.myQrCode;
  String get scanQrStation        => _t.scanQrStation;
  String get scanQrTitle          => _t.scanQrTitle;
  String get scanQrSub            => _t.scanQrSub;
  String get notStationQr         => _t.notStationQr;
  String get invalidQr            => _t.invalidQr;
  String get paymentSuccessMsg    => _t.paymentSuccessMsg;
  String get insufficientBalance  => _t.insufficientBalance;
  String get confirmPaymentTitle  => _t.confirmPaymentTitle;
  String get debitedFrom          => _t.debitedFrom;
  String get annuler              => _t.annuler;
  String get confirmer            => _t.confirmer;
  String get paymentSuccessTitle  => _t.paymentSuccessTitle;
  String get receiptNumber        => _t.receiptNumber;
  String get compagnie            => _t.compagnie;
  String get paymentMethod        => _t.paymentMethod;
  String get cashbackEarned       => _t.cashbackEarned;
  String get transactionId        => _t.transactionId;
  String get downloadingReceipt   => _t.downloadingReceipt;
  String get share                => _t.share;
  String get downloadBtn          => _t.downloadBtn;
  String get activePromos         => _t.activePromos;
  String get expiredPromos        => _t.expiredPromos;
  String get noPromoAvailable     => _t.noPromoAvailable;
  String get noPromoSub           => _t.noPromoSub;
  String get seeDetails           => _t.seeDetails;
  String get expired              => _t.expired;
  String get validityPeriod       => _t.validityPeriod;
  String get conditions           => _t.conditions;
  String get alreadyParticipated  => _t.alreadyParticipated;
  String get participationSuccess => _t.participationSuccess;
  String get participationError   => _t.participationError;
  String get promoNotFound        => _t.promoNotFound;
  String get maskCard             => _t.maskCard;
  String get privacyIntro         => _t.privacyIntro;
  String get privacySection1Title => _t.privacySection1Title;
  String get privacySection1Content => _t.privacySection1Content;
  String get privacySection2Title => _t.privacySection2Title;
  String get privacySection2Content => _t.privacySection2Content;
  String get privacySection3Title => _t.privacySection3Title;
  String get privacySection3Content => _t.privacySection3Content;
  String get privacySection4Title => _t.privacySection4Title;
  String get privacySection4Content => _t.privacySection4Content;
  String get privacySection5Title => _t.privacySection5Title;
  String get privacySection5Content => _t.privacySection5Content;
  String get privacySection6Title => _t.privacySection6Title;
  String get privacySection6Content => _t.privacySection6Content;
  String get privacySection7Title => _t.privacySection7Title;
  String get privacySection7Content => _t.privacySection7Content;
  String get privacySection8Title => _t.privacySection8Title;
  String get privacySection8Content => _t.privacySection8Content;
  String get privacyContactEmail  => _t.privacyContactEmail;
  // ✅ NOUVEAUX GETTERS
  String get fillFormToRegister   => _t.fillFormToRegister;
  String get passwordMismatch     => _t.passwordMismatch;
  String get codeSent             => _t.codeSent;
  String get verifyPhone          => _t.verifyPhone;
  String get verify               => _t.verify;
  String get resend               => _t.resend;
  String get didntReceiveCode     => _t.didntReceiveCode;
  String get codeSentTo           => _t.codeSentTo;

  // Helpers
  String transactionCount(int count) =>
      '$count ${_t.transactions}${count > 1 && locale.languageCode == 'fr' ? 's' : ''} ${_t.thisMonth}';
  String helloUser(String firstName) => '${_t.hello}, $firstName';
  String cashbackLine(double v) => '+${v.toStringAsFixed(0)} FCFA ${_t.cashback}';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();
  @override bool isSupported(Locale locale) => ['fr', 'en', 'ar'].contains(locale.languageCode);
  @override Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class AppLocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr');
  Locale get locale => _locale;
  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }
  static const supportedLocales = [Locale('fr'), Locale('en'), Locale('ar')];
  static const languageNames = {
    'fr': '🇫🇷 Français', 'en': '🇬🇧 English', 'ar': '🇸🇦 العربية',
  };
}