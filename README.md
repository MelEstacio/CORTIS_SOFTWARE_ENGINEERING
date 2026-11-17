# CORTIS: Fanbase & Artist Platform

A software engineering project designed to explore the development of a digital platform that connects fans, artists, content, events, and commerce within a single ecosystem.

CORTIS began as a web development project inspired by the digital presence of K-pop groups and evolved into a broader software engineering project focused on system design, relational databases, backend development, and data organization.

The project is currently being redesigned around a structured PostgreSQL database, a Kotlin-based backend, and a set of business rules intended to represent a realistic fanbase platform.

## Project Purpose

The goal of CORTIS is to model and eventually implement a platform where fans can interact with artists and their content while accessing features such as:

- Artist and group information
- Fan accounts and profiles
- Events and ticket management
- Products and orders
- Loyalty and reward levels
- Promotional campaigns
- Artist-related releases and activities

Rather than focusing exclusively on the visual interface, the project emphasizes how information is structured, related, validated, and processed within a software system.

The objective is to understand how different components of a digital platform interact, from database organization and backend operations to the business rules that govern user interactions and transactions.

## System & Database Design

The current development phase focuses on the relational database architecture using PostgreSQL.

The database is being designed through the progression of:

**Conceptual Model → Logical Model → Physical Model**

The schema incorporates relational database concepts and data integrity mechanisms, including:

- Primary and foreign keys
- Supertype/subtype modeling
- Relationship and cardinality analysis
- Database normalization
- Named constraints
- NOT NULL and CHECK constraints
- Identity columns
- Business rules and data integrity
- Many-to-many relationships through associative tables

The current database model includes entities related to:

```text
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
```

The database structure is continuously refined as new business requirements, relationships, and edge cases are identified.

This process aims to ensure consistency, reduce data redundancy, and establish a reliable foundation for the application's backend operations.

## Kotlin & Backend Development

Kotlin is the primary programming language for backend development, with Ktor serving as the framework for building the application's server-side architecture.

The backend follows a RESTful API architecture, providing communication between the frontend, application logic, and PostgreSQL database.

The project uses the following libraries and technologies for backend development and database interaction:

- **Kotlin:** Primary programming language for backend development and business logic.
- **Ktor:** Framework for building the HTTP server, managing routes, and implementing RESTful API endpoints.
- **Exposed:** Kotlin SQL framework used for database interaction, table definitions, and query management.
- **HikariCP:** JDBC connection pooling for efficient database connection management.
- **PostgreSQL:** Relational database management and data persistence.

Planned backend responsibilities include:

- Building RESTful API endpoints using Ktor
- Implementing business rules and application logic with Kotlin
- Handling HTTP requests and responses
- Managing user authentication and authorization
- Performing database operations through Exposed
- Configuring and managing database connection pools with HikariCP
- Implementing data validation and error handling
- Processing operations related to products, tickets, orders, payments, and user interactions
- Organizing backend components to support maintainability, modularity, and future scalability

The intention is to develop a modular backend architecture in which different responsibilities are separated into well-defined components.

This approach will help make the application easier to maintain, test, and expand as new features and business requirements are introduced.

## Technologies

### Current

- **Kotlin:** Backend development and business logic
- **Ktor:** HTTP server and RESTful API development
- **Exposed:** SQL framework and database interaction
- **HikariCP:** JDBC connection pooling
- **PostgreSQL:** Relational database management
- **SQL:** Database modeling, queries, and data manipulation

### Previous / Original Implementation

- HTML5
- CSS3
- JavaScript
- Draw.io: Database modeling
- Figma: Design ideation

The original project began as a web-focused implementation and is currently being restructured into a broader software engineering project, with greater emphasis on backend architecture, database design, and system organization.

## Project Status

In active development.

The backend is being designed around a RESTful API responsible for handling communication between the frontend, application logic, and database.

Built with Kotlin and Ktor, the backend will manage users, products, tickets, orders, payments, and user interactions while enforcing the business rules that define how these different parts of the system work together.

The database layer uses PostgreSQL, with Exposed handling SQL interactions and HikariCP managing JDBC connection pooling.

As the system evolves, the project will also serve as an opportunity to explore the architecture behind applications that manage large volumes of information and transactions.

The goal is to better understand how a system designed to serve a large user base can be structured, maintained, and expanded, from relational database organization and API communication to the implementation of reliable business rules and backend operations.

This project is being developed as part of my Computer Science studies and serves as a practical environment for applying concepts in software engineering, relational databases, programming, and backend development.

Through CORTIS, I aim to explore how the systems behind large-scale digital platforms are designed and maintained, and how different technologies work together to support thousands or potentially millions of users and their interactions.
