// User Model (Demo)
// In a real app, this would interact with a database
const { json } = require('express');
const firestore_db = require('./firestore');
const jsonwebtoken = require('jsonwebtoken');

class User {
    constructor(username) {
        this.username = username;
    }

    async register(password, role) {
        const token = jsonwebtoken.sign({ username: this.username, role: role }, 'your_jwt_secret', { expiresIn: '1h' });
        await firestore_db.collection('users').doc(this.username).set({
            password: password,
            role: role,
            token: token
        });
        console.log(`User ${this.username} registered.`);
        return token;
    }

    async login(password, role) {
        const userDoc = await firestore_db.collection('users').doc(this.username).get();
        if (!userDoc.exists) {
            throw new Error('User does not exist');
        }
        const userData = userDoc.data();
        if (userData.password !== password) {
            throw new Error('Invalid credentials');
        }
        if (role && userData.role !== role) {
            throw new Error('Invalid role for user');
        }
        let token = userData.token;
        let tokenValid = false;
        if (token) {
            try {
                // Will throw if expired or invalid
                jsonwebtoken.verify(token, 'your_jwt_secret');
                tokenValid = true;
            } catch (err) {
                tokenValid = false;
            }
        }
        if (!tokenValid) {
            token = jsonwebtoken.sign({ username: this.username, role: userData.role }, 'your_jwt_secret', { expiresIn: '1h' });
            await firestore_db.collection('users').doc(this.username).update({ token: token });
        }
        console.log(`User ${this.username} logged in.`);
        return token;
    }
    async logout() {
        await firestore_db.collection('users').doc(this.username).update({ token: null });
        console.log(`User ${this.username} logged out.`);
    }
}

module.exports = User;
