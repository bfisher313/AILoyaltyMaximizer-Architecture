# 3. Logical Architecture (Software View)

This section details the logical software architecture of the AI Loyalty Maximizer Suite. It describes the major structural elements, their responsibilities, and how they interact at a high level, independent of specific underlying AWS service implementations (which are detailed in the Physical View). We will utilize the C4 model for its clarity in visualizing and communicating software architecture.

## 3.1. Overview & C4 Model Approach

The C4 model (Context, Containers, Components, and Code) provides a structured way to visualize software architecture at different levels of abstraction. For this document:

* **Level 1: System Context Diagram:** Illustrates how the AI Loyalty Maximizer Suite fits into its operating environment, showing its interactions with users and key external systems.
* **Level 2: Container Diagram:** Zooms into the AI Loyalty Maximizer Suite, breaking it down into its major high-level, independently deployable (or conceptually distinct) services or "containers." These are the main building blocks of the system.
* **Level 3: Component Diagrams:** Zoom into individual containers to show their key internal components or modules. This will be detailed for critical containers.
* **Level 4: Code Diagrams:** (Out of scope for this high-level architectural document) Would show the internal code structure of individual components.

This approach allows us to progressively reveal detail and understand the system from different perspectives.

## 3.2. System Context Diagram (C4 Level 1)

The System Context diagram shows the AI Loyalty Maximizer Suite as a single "black box" and its relationships with external users and systems. It defines the system's boundary and scope at the highest level of abstraction.

**Diagram:**

<p align="center">
  <img src="../diagrams_output/c4_model_renders/structurizr-SystemContext.png" alt="AI Loyalty Maximizer Suite - System Context Diagram" width="974">
</p>

**Description of System Context Diagram Elements:**

* **AI Loyalty Maximizer Suite (System):**
    * This is the core system being designed and documented.
    * Its primary purpose is to provide AI-driven insights, calculations, and advice related to airline loyalty programs.
    * It acts as the central hub for user interaction, data processing, knowledge storage, and decision-making regarding loyalty program optimization.

* **Travel Enthusiast (User Persona):**
    * Represents the primary end-users of the suite.
    * These users interact with the system by submitting natural language queries, providing details about their travel plans or loyalty program memberships, and receiving personalized advice, calculations (for earnings/redemptions), and potential alerts.

* **Data Curator (User Persona):**
    * Represents an administrative or specialized user.
    * This persona is responsible for the manual gathering of source information (e.g., web pages containing loyalty rules, airline partner details, earning charts, award tables from publicly available airline websites or documents).
    * They provide this raw information to the system's ingestion pipeline, effectively acting as the initial human-in-the-loop for populating and updating the knowledge base.

* **Manually Collected Web Pages (S3 Raw Bucket - External Input Source) (External System):**
    * This represents the conceptual upstream data source containing the raw, and potentially varied, information collected by the `Data Curator`.
    * While labeled "S3 Raw Bucket" to indicate its likely initial storage location in the AWS ecosystem for the pipeline, from the C4 Level 1 perspective, it's an external source of information that feeds into the `AI Loyalty Maximizer Suite`.
    * The suite's `Data Ingestion Pipeline Service` (a container within the suite, detailed at Level 2) reads from this external source.

* **Notification Delivery Service (External System):**
    * Represents the external infrastructure or third-party services responsible for delivering notifications (e.g., email alerts, SMS messages, or potential future newsletters) to the `Travel Enthusiast`.
    * The `AI Loyalty Maximizer Suite` would formulate the content of these notifications and then pass them to this external service for actual dispatch and delivery. This could be services like Amazon SES (for email) or Amazon SNS (for SMS) interacting with external carrier networks, or other third-party communication platforms.

## 3.3. Container Diagram (C4 Level 2) - Key Services & Responsibilities

The Container diagram zooms into the "AI Loyalty Maximizer Suite" system boundary, revealing its major logical containers. In the C4 model, a "container" is something like a separately deployable or runnable unit, or a significant, independently manageable component such as a single-page application, a server-side web application, a microservice, a database, a file system, etc. These are the high-level building blocks that collectively deliver the system's functionality.

This diagram illustrates these primary containers, their core responsibilities, and the key technological choices or paradigms associated with them at a high level. It also shows the main pathways of interaction between these containers and with the external systems/users defined in the System Context diagram.

**Diagram:**

![Container Diagram - C4 Level 2 for AI Loyalty Maximizer Suite](../diagrams_output/c4_model_renders/structurizr-Containers.png)

**Container Descriptions:**

1.  **Conversational API (Container)**
    * **Description:** This container serves as the primary, secure entry point for all external user interactions with the AI Loyalty Maximizer Suite. It exposes a well-defined API that client applications (e.g., future web or mobile UIs, chatbots) will use to send user queries and receive responses. Its responsibilities include request validation, authentication/authorization, routing incoming requests to the `LLM Orchestration Service`, and formatting the final responses before sending them back to the client.
    * **Key Technologies (Conceptual):** Amazon API Gateway (for defining and managing the API endpoints, handling traffic, security), AWS Lambda (for backend request/response processing and integration logic).
    * **Primary Interactions:**
      * Receives requests from the `Travel Enthusiast` (via their client application).
      * Forwards processed queries/commands to the `LLM Orchestration Service`.
      * Receives synthesized responses/actions from the `LLM Orchestration Service`.
      * Sends formatted responses back to the `Travel Enthusiast`'s client application.

2.  **LLM Orchestration Service (Container)**
  * **Description:** This container is the central intelligence and "brain" of the system, acting as the **Primary Reasoning Agent**. It receives user queries from the `Conversational API`, interprets user intent, breaks down complex requests into manageable tasks, and determines the sequence of operations or tools (MCP Tools/Specialized Agents) needed. It manages conversational state (if required for multi-turn dialogues), invokes the appropriate tools, and synthesizes their outputs into coherent, context-aware responses or actions.
  * **Key Technologies (Conceptual):** Amazon Bedrock (for accessing and running Large Language Models), AWS Step Functions (for orchestrating complex workflows involving multiple LLM calls and tool invocations), AWS Lambda (for hosting core orchestration logic and invoking tools).
  * **Primary Interactions:**
    * Receives user queries/commands from the `Conversational API`.
    * Invokes various specialized tools/agents to:
      * Fetch user-specific data from the `User Profile Service`.
      * Retrieve loyalty program information and perform RAG operations via the `Knowledge Base Service (GraphRAG)`.
    * Sends triggers/requests to the `Notification Service`.
    * Returns synthesized responses or action directives to the `Conversational API`.

3.  **User Profile Service (Container)**
  * **Description:** This container is responsible for managing and persisting all user-specific data. This includes details of a user's loyalty program memberships, current elite statuses, rewards currency balances (if the user provides them), saved travel preferences, and potentially a history of analyzed itineraries or saved "mileage run" ideas. It provides an interface for other services to securely access and update this information.
  * **Key Technologies (Conceptual):** Amazon DynamoDB (as a scalable, flexible NoSQL database for user profiles), AWS Lambda (to implement a data access API layer for this service if needed, or for direct access by other internal services with appropriate IAM permissions).
  * **Primary Interactions:**
    * Queried by the `LLM Orchestration Service` to retrieve user data for personalization and context.
    * Updated (e.g., new program added, preferences changed) based on actions initiated by the `LLM Orchestration Service` (originating from user input via the `Conversational API`).

4.  **Knowledge Base Service (GraphRAG) (Container)**
  * **Description:** This container houses the core knowledge of the AI Loyalty Maximizer Suite. It includes the graph database representing airline loyalty programs, partner relationships, earning rules, redemption options, and fare class details. Crucially, it also encapsulates the Retrieval Augmented Generation (RAG) logic, enabling the system to retrieve relevant information from the graph (and potentially supplementary documents in S3) to provide rich context to the LLM for generating accurate and detailed answers.
  * **Key Technologies (Conceptual):** Amazon Neptune (as the graph database), Amazon S3 (for storing unstructured documents or detailed rule texts for RAG), AWS Lambda (for implementing RAG retrieval logic, graph query execution, and providing an interface to this service).
  * **Primary Interactions:**
    * Queried by specialized tools/agents (invoked by the `LLM Orchestration Service`) to fetch specific loyalty data, perform graph traversals, or retrieve contextual information for RAG.
    * Receives data updates (new rules, program changes) from the `Data Ingestion Pipeline Service`.

5.  **Data Ingestion Pipeline Service (Container)**
  * **Description:** This container comprises an orchestrated set of services responsible for the automated processing of manually gathered source information (HTML pages, PDFs, text files) to populate and maintain the `Knowledge Base Service`. It acts as a collection of **Data Processing Agents**. The pipeline includes stages for initial data validation and pre-processing, OCR (using Amazon Textract for image-based documents), advanced information extraction (leveraging LLMs via Amazon Bedrock to parse semi-structured content and identify entities/relationships like effective dates), data transformation into graph format, optional validation (e.g., using Amazon Athena on intermediate structured data), and finally, loading the data into the Neptune graph database.
  * **Key Technologies (Conceptual):** Amazon S3 (for various staging areas: raw, processed text, Textract output, LLM output, Neptune load files), AWS Lambda (for individual processing steps and triggers), Amazon Textract, AWS Glue (for complex ETL, Python-based parsing, and LLM integration for extraction), AWS Step Functions (for orchestrating the entire multi-step pipeline).
  * **Primary Interactions:**
    * Reads raw data from the `Manually Collected Web Pages (S3 Raw Bucket - External Input Source)` which is supplied by the `Data Curator`.
    * Writes processed and transformed data into the `Knowledge Base Service` (specifically, by preparing load files for Amazon Neptune or directly interacting with it).

6.  **Notification Service (Container)**
  * **Description:** This container is responsible for managing and dispatching outbound notifications and alerts to users. These could include alerts for award availability, reminders, or future newsletters. It decouples the notification logic from the core `LLM Orchestration Service`.
  * **Key Technologies (Conceptual):** Amazon SNS (Simple Notification Service) (for fanning out messages to different endpoints like email, SMS), AWS Lambda (for composing notification content and interacting with SNS).
  * **Primary Interactions:**
    * Receives triggers or notification requests from the `LLM Orchestration Service`.
    * Publishes messages to the `Notification Delivery Service (External)` (e.g., by sending an email via SES, an SMS via SNS, or interfacing with another external gateway).

*(End of Container Descriptions)*