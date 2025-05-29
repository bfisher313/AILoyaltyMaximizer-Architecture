# 2. Business Context & Driving Requirements

Understanding the business context and the specific requirements that drive the design of the AI Loyalty Maximizer Suite is essential. This section outlines the core user needs through user stories and scenarios, defines the key architectural goals (non-functional requirements), and lists the guiding principles that will shape the technical architecture.

## 2.1. Core User Stories & Scenarios (+1 View)

These user stories represent the key functionalities and value propositions of the AI Loyalty Maximizer Suite from the perspective of its target audience. They also serve as the "+1 View" (Scenarios) to validate the architecture against practical use cases.

* **US-001: Award Travel Optimization**
    * **As a** frequent flyer with miles/points across multiple loyalty programs,
    * **I want to** input my desired travel (origin, destination, approximate dates, preferred cabin class, and number of travelers),
    * **So that** the system can intelligently search for award availability, suggest optimal redemption options (including potential point transfers between programs), and highlight the best value based on my available rewards currency.
    * **Scenario Example:** Sarah has 100k Amex MR points, 50k United Miles, and 30k Delta SkyMiles. She wants to fly business class from New York (NYC) to London (LON) for two people next September. The system should analyze transfer options (e.g., Amex to Aeroplan or Flying Blue), check award availability on relevant airlines/alliances, and present her with options ranked by total points cost, fees, and overall value.

* **US-002: Revenue Flight Earnings Calculation**
    * **As a** traveler planning to book a paid flight,
    * **I want to** input my intended flight details (e.g., airline, route, fare class/booking code),
    * **So that** the system can accurately calculate the estimated redeemable miles/points and elite-qualifying metrics (e.g., EQMs, EQSs, EQDs, Loyalty Points, etc.) I will earn across various frequent flyer programs I could credit the flight to.
    * **Scenario Example:** John is booking a Lufthansa flight from Frankfurt (FRA) to Singapore (SIN) in booking class "K". He wants to know how many redeemable miles and status miles/points he would earn if he credits it to Miles & More vs. United MileagePlus vs. Air Canada Aeroplan, considering his existing Star Alliance Gold status with United.

* **US-003: Optimal Crediting Program Advice**
    * **As a** traveler focused on achieving or maintaining a specific elite status (e.g., Star Alliance Gold, Oneworld Sapphire),
    * **I want to** receive advice on which frequent flyer program to credit my revenue flights to,
    * **So that** I can maximize my progress towards my desired elite status tier, considering earning rates, current status, and specific program qualification requirements.

* **US-004: Conversational & Intuitive Interaction**
    * **As a** user,
    * **I want to** interact with the system using natural language queries through a conversational interface (e.g., chatbot),
    * **So that** I can easily ask complex questions and receive clear, understandable answers without needing to navigate complicated menus or forms.

* **US-005: Personalized Experience**
    * **As a** registered user,
    * **I want to** securely store my loyalty program memberships, current elite statuses, and optionally my points balances,
    * **So that** the system can provide personalized advice, track my progress towards goals, and tailor recommendations to my specific situation.

* **US-006: Understanding Complex Loyalty Rules (via GraphRAG)**
    * **As a** travel enthusiast,
    * **I want to** be able to ask the system complex questions about loyalty program rules, partnerships, transfer options, or specific earning/redemption nuances (e.g., "Can I transfer Chase Ultimate Rewards points to an airline that flies to the Maldives with a flat-bed seat, and what are the typical points requirements and best routing options?"),
    * **So that** the system can leverage its knowledge graph and RAG capabilities to provide detailed and accurate answers.

* **US-007: Automated Knowledge Base Updates (Admin/System Perspective)**
    * **As a** system administrator/data curator,
    * **I want to** be able to manually gather relevant web pages (e.g., new earning charts, partner updates) and submit them to an automated ingestion pipeline,
    * **So that** the system's knowledge graph can be updated with the latest information efficiently, minimizing manual data entry into the graph itself.

## 2.2. Architectural Goals (Non-Functional Requirements - NFRs)

The architecture must address the following key non-functional requirements to ensure the system is effective, reliable, and sustainable:

* **Accuracy:**
    * The system must provide highly accurate calculations for points/miles earnings and redemption costs based on the ingested rules.
    * Information retrieved from the knowledge graph must be consistent and reflect the underlying data.
* **Scalability:**
    * The system must be able to handle a growing number of users and concurrent queries.
    * The data ingestion pipeline must scale to process an increasing volume of loyalty program information.
    * The knowledge graph (Amazon Neptune) and other data stores must scale to accommodate more programs, rules, and user data.
* **Performance & Responsiveness:**
    * User queries should be processed with acceptable latency, providing a responsive conversational experience.
    * Complex calculations and graph traversals should be optimized for speed.
* **Availability & Resilience:**
    * The user-facing services must be highly available.
    * The system should be resilient to failures in individual components, with appropriate fallback mechanisms or graceful degradation where applicable.
    * Data stores must have robust backup and recovery mechanisms.
* **Security:**
    * User profile data (if stored) must be protected with appropriate access controls and encryption.
    * All communications (data in transit) must be encrypted.
    * Data at rest must be encrypted.
    * The system must be protected against common web vulnerabilities and threats.
* **Maintainability & Extensibility:**
    * The architecture should be modular, allowing individual components to be updated or replaced with minimal impact on the rest of the system.
    * Adding new loyalty programs, rules, or MCP tools should be straightforward.
    * The data ingestion pipeline logic should be adaptable to new source formats (within reason, given the AI-assisted extraction).
* **Cost-Effectiveness:**
    * The AWS infrastructure should be designed to optimize operational costs, leveraging serverless components and appropriate instance sizing where applicable.
    * Resource utilization should be monitored to identify cost-saving opportunities.
* **Usability (for End-Users):**
    * The conversational interface should be intuitive and easy to use.
    * Responses should be clear, concise, and actionable.

## 2.3. Architectural Principles

The design and development of the AI Loyalty Maximizer Suite will be guided by the following architectural principles:

* **AI-First Design:** Core functionalities and user interactions will be designed around AI capabilities (LLMs, agents, GraphRAG).
* **Cloud-Native & Serverless-Preferred:** Leverage AWS managed services extensively, prioritizing serverless options (Lambda, API Gateway, Step Functions, DynamoDB, S3, Bedrock) to enhance scalability, reduce operational overhead, and optimize costs.
* **Modularity & Loose Coupling:** Design components as independent, well-defined services with clear interfaces (e.g., MCP tools) to promote maintainability, testability, and independent scalability.
* **Data-Driven Insights:** The knowledge graph and RAG will be central to providing accurate and contextually relevant information.
* **Automation:** Automate processes where feasible, particularly for data ingestion (post-manual collection), deployment (IaC), and testing (CI/CD).
* **Security by Design:** Integrate security considerations into every layer of the architecture from the outset.
* **Iterative Development:** The architecture should support an agile, iterative approach to development, allowing for incremental delivery of features and capabilities.
* **Scalability for Growth:** Design for future growth in terms of users, data volume, and feature complexity.
* **User-Centricity:** Focus on providing genuine value and a seamless experience for the target audience.
* **Pragmatism:** Make practical technology choices that balance innovation with reliability and maintainability for a portfolio project context.

---
*This page is part of the AI Loyalty Maximizer Suite - AWS Reference Architecture. For overall context, please see the [Architecture Overview](./00_ARCHITECTURE_OVERVIEW.md) or the main [README.md](../../README.md) of this repository.*

---
**Previous:** [Architecture Overview & Document Guide](./00_ARCHITECTURE_OVERVIEW.md)
**Next:** [2. Business Context & Driving Requirements](./02_BUSINESS_CONTEXT_AND_REQUIREMENTS.md)