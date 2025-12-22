// models/firestore.js
const admin = require('firebase-admin');
const serviceAccount = require('../service-key.json');

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
module.exports = db;