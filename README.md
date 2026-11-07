CORTIS — Fanbase & Artist Platform

A software engineering project designed to explore the development of a digital platform that connects fans, artists, content, events, and commerce within a single ecosystem.

CORTIS began as a web development project inspired by the digital presence of K-pop groups and evolved into a broader software engineering project focused on system design, relational databases, backend development, and data organization.

The project is currently being redesigned around a structured PostgreSQL database and a set of business rules intended to represent a realistic fanbase platform.

🎯 Project Purpose

The goal of CORTIS is to model and eventually implement a platform where fans can interact with artists and their content while accessing features such as:

Artist and group information
Fan accounts
Events and tickets
Products and orders
Loyalty and reward levels
Promotional campaigns
Artist-related releases and activities

Rather than focusing only on the visual interface, the project is being developed with particular attention to how information is structured, related, validated, and processed within the system.

🏗️ System & Database Design

The current development phase focuses on the relational database architecture using PostgreSQL.

The database is being designed through the progression of:

Conceptual Model → Logical Model → Physical Model

The schema incorporates concepts such as:

Primary and foreign keys
Supertype/subtype modeling
Relationship and cardinality analysis
Database normalization
Named constraints
NOT NULL and CHECK constraints
Identity columns
Business rules and data integrity
Many-to-many relationships through associative tables

The model currently includes entities related to:

Artists
├── Groups
└── Members

Debuts

Fans
└── Loyalty Levels

Products

Orders
└── Order Items

Events
└── Tickets

Promotions

The database structure is continuously refined as new business requirements and edge cases are identified.

🐍 Python & Backend

As the project develops, Python will be used as a core technology for building the backend and implementing the application's business logic.

Planned applications include:

- Building RESTful API endpoints
- Implementing business rules and application logic
- Handling requests and responses between the frontend and backend
- Managing user authentication and system operations
- Connecting and interacting with the PostgreSQL database
- Processing features related to products, tickets, orders, payments, and user interactions

💻 Technologies

### Current
- PostgreSQL
- SQL
- Python - backend development and business logic

### Previous / Original Implementation
- HTML5
- CSS3
- JavaScript
- Draw.io - database modeling
- Figma - Design ideation

The original project began as a web-focused implementation and is currently being restructured as a broader software engineering project.

🚧 Project Status

In active development.

The backend will be designed around a RESTful API responsible for handling requests and responses between the frontend, application logic, and database. 
Its planned responsibilities include managing users, products, tickets, orders, payments, and user interactions, 
while applying the business rules that define how these different parts of the system work together.

As the system evolves, the project will also serve as an opportunity to explore the architecture behind applications that manage large volumes of information and transactions.
The goal is to better understand how a system designed to serve a large user base can be structured, maintained, 
and expanded—from database organization and API communication to the implementation of reliable business rules and system operations.

This project is being developed as part of my Computer Science studies 
and serves as a practical environment for applying concepts in software engineering, databases, programming, 
and backend development. Through CORTIS, I aim to explore how the systems behind large-scale digital platforms are designed and maintained, 
and how different technologies work together to support thousands or potentially millions of users and their interactions.
