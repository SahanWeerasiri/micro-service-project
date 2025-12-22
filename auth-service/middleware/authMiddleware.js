// Auth Middleware (Demo)
// In a real app, this would verify JWT or session
const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
    // check the authorization header
    const authHeader = req.headers['authorization'];
    if (!authHeader) {
        return res.status(401).json({ message: 'Unauthorized' });
    }
    // get the token data
    const token = authHeader.split(' ')[1];
    if (!token) {
        return res.status(401).json({ message: 'Unauthorized' });
    }
    // verify the token
    try {
        const secret = process.env.JWT_SECRET || 'your_jwt_secret'; // Use env var in production
        const decoded = jwt.verify(token, secret);
        req.user = decoded; // Attach user info to request
        next();
    } catch (err) {
        if (err.name === 'TokenExpiredError') {
            return res.status(401).json({ message: 'Token expired' });
        }
        return res.status(401).json({ message: 'Invalid token' });
    }
};
