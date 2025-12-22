// Auth Controller
// Handles logic for user registration and login
const ROLES = require('../models/roles');
const User = require('../models/user');
const bcrypt = require('bcrypt');

// Simple log function (replace with log service integration as needed)
function log(message, meta = {}) {
    console.log(`[AUTH LOG] ${message}`, meta);
}

exports.register = async (req, res) => {
    try {
        const { string: username, string: password, string: role } = req.body;
        if (role !== ROLES.MERCHANT && role !== ROLES.CONSUMER) {
            log('Registration failed: invalid role', { username, role });
            return res.status(400).json({ message: 'Invalid role specified' });
        }
        let user = new User(username);
        const token = await user.register(bcrypt.hashSync(password, 10), role);
        log('User registered', { username, role });
        return res.status(201).json({ token });
    } catch (error) {
        log('Registration error', { error: error.message });
        return res.status(400).json({ message: 'Invalid request data' });
    }
};

exports.login = async (req, res) => {
    try {
        const { string: username, string: password, string: role } = req.body;
        let user = new User(username);
        const token = await user.login(password, role);
        log('User logged in', { username, role });
        return res.status(200).json({ token });
    } catch (error) {
        log('Login error', { error: error.message });
        return res.status(401).json({ message: error.message });
    }
};

exports.logout = async (req, res) => {
    try {
        const { string: username } = req.body;
        let user = new User(username);
        await user.logout();
        log('User logged out', { username });
        return res.status(200).json({ message: 'User logged out successfully' });
    } catch (error) {
        log('Logout error', { error: error.message });
        return res.status(400).json({ message: 'Invalid request data' });
    }
};

exports.verifyToken = (req, res) => {
    if (req.user == null) {
        log('Token verification failed: unauthorized');
        return res.status(401).json({ message: 'Unauthorized' });
    }
    log('Token verified', { user: req.user });
    return res.status(200).json({ message: 'Token is valid', user: req.user });
}