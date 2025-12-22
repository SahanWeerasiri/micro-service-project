// Auth Middleware (Demo)
// In a real app, this would verify JWT or session

module.exports = (req, res, next) => {
    // For demo, allow all requests
    next();
};
