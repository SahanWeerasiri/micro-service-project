// Consumer Middleware (Demo)
// In a real app, this would check consumer permissions

module.exports = (req, res, next) => {
    // For demo, allow all requests
    next();
};
