// Auth Controller
// Handles logic for user registration and login
const ROLES = require('../models/roles');
const User = require('../models/user');
const bcrypt = require('bcrypt');

exports.register = async (req, res) => {
    try {
        const { string: username, string: password, string: role } = req.body;
        if (role !== ROLES.MERCHANT && role !== ROLES.CONSUMER) {
            return res.status(400).json({ message: 'Invalid role specified' });
        }
        let user = new User(username);
        return res.status(201).json({ token: await user.register(bcrypt.hashSync(password, 10), role) });
    } catch (error) {
        return res.status(400).json({ message: 'Invalid request data' });
    }
};

exports.login = async (req, res) => {
    try {
        const { string: username, string: password, string: role } = req.body;
        let user = new User(username);
        return res.status(200).json({ token: await user.login(password, role) });
    } catch (error) {
        return res.status(401).json({ message: error.message });
    }
};

exports.logout = async (req, res) => {
    try {
        const { string: username } = req.body;
        let user = new User(username);
        await user.logout();
        return res.status(200).json({ message: 'User logged out successfully' });
    } catch (error) {
        return res.status(400).json({ message: 'Invalid request data' });
    }
};

exports.verifyToken = (req, res) => {
    if (req.user == null) {
        return res.status(401).json({ message: 'Unauthorized' });
    }
    return res.status(200).json({ message: 'Token is valid', user: req.user });
}