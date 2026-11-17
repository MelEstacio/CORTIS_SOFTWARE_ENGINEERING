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
- **Ktor:** Framework for building the HTTP server, managing routes, and implementing REST
