// Merchant Middleware (Demo)
// In a real app, this would check merchant permissions

module.exports = (req, res, next) => {
    // For demo, allow all requests
    next();
};
