// Consumer Model (Demo)
// In a real app, this would interact with a database

class Consumer {
    constructor(username) {
        this.username = username;
        this.giftCards = [];
    }
}

module.exports = Consumer;
