// GiftCard Model (Demo)
// In a real app, this would interact with a database

class GiftCard {
    constructor(id, value, merchant) {
        this.id = id;
        this.value = value;
        this.merchant = merchant;
    }
}

module.exports = GiftCard;
