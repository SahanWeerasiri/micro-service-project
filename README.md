# Microservice Demo Project

This project demonstrates a simple microservice architecture using Node.js, Docker, and Nginx. It includes four services:

- **Auth Service**: Handles user authentication (register/login).
- **Merchant Service**: Merchants can create and sell gift cards.
- **Consumer Service**: Consumers can buy and share gift cards.
- **Log Service**: Centralized logging for all services.

## Structure
Each service has its own folder with:
- `server.js`: Main entry point
- `controllers/`: Business logic
- `models/`: Data models
- `routes/`: API endpoints
- `middleware/`: Request handling logic

## How to Run
1. Make sure Docker is installed.
2. Run `docker-compose up --build` in the project root.
3. Nginx will route requests to the correct service:
   - `/auth/` → Auth Service
   - `/merchant/` → Merchant Service
   - `/consumer/` → Consumer Service
   - `/logs/` → Log Service

## Learning Notes
- Each file is commented to help you understand the flow.
- You can extend each service with real database logic, authentication, etc.
- Nginx acts as a reverse proxy, routing traffic to the correct service container.

---
Feel free to explore and modify the code to deepen your understanding of microservices, Docker, and Nginx!
