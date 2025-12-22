// Log Middleware (Demo)
// In a real app, this could format or filter logs

module.exports = (req, res, next) => {
    // For demo, allow all requests
    next();
};
