// Log Model (Demo)
// In a real app, this would interact with a database

class Log {
    constructor(service, message) {
        this.service = service;
        this.message = message;
        this.timestamp = new Date();
    }
}

module.exports = Log;
