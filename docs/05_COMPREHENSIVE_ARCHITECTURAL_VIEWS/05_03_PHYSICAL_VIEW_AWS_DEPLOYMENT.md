
# 5.3. Physical View (Deployment Architecture on AWS)

## 5.3.1. Introduction

The Physical View, often referred to as the Deployment View, describes how the logical software components of the AI Loyalty Maximizer Suite are mapped to the physical (or, in this cloud-native architecture, virtualized) infrastructure on Amazon Web Services (AWS). This view details the specific AWS services utilized, the network design within the Virtual Private Cloud (VPC), strategies for ensuring high availability and disaster recovery, and the conceptual approach to managing different deployment environments.

Understanding the physical deployment is crucial for assessing operational aspects, security in depth, scalability mechanisms at the infrastructure level, cost implications, and the overall resilience of the application. This section provides a blueprint for how the suite would be realized and hosted within the AWS ecosystem.

Key aspects covered include:
* Mapping of logical containers (from Section 3.3) to specific AWS services.
* Detailed network architecture within Amazon VPC.
* High Availability (HA) and Disaster Recovery (DR) strategies.
* Conceptual environment strategy (Dev, Staging, Production).

**[🚧 TODO: Insert Detailed AWS Physical Deployment Diagram here. See GitHub Issue #11 🚧]**
*(This diagram will visually represent the VPC, subnets, AWS services, their placement across Availability Zones, and key network flows.)*

## 5.3.2. AWS Service Mapping for Key Containers

This subsection details how the logical C4 Level 2 containers, defined in Section 3.3 (Logical Architecture), are realized using specific Amazon Web Services. The selection of these services is guided by the architectural principles of leveraging serverless and managed services where possible to enhance scalability, reduce operational overhead, and optimize costs.

1.  **Conversational API (Container)**
    * **Primary AWS Services:**
        * **Amazon API Gateway:** Serves as the HTTP endpoint, handling request/response marshalling, authentication/authorization (e.g., via AWS IAM or Amazon Cognito Lambda Authorizers), throttling, and routing.
        * **AWS Lambda:** Provides the backend compute logic for API Gateway, processing incoming user queries, performing initial validation, and forwarding requests to the `LLM Orchestration Service`.
    * **Rationale:** This combination offers a highly scalable, serverless, and cost-effective way to expose and manage the application's entry point.

2.  **LLM Orchestration Service (Container) - Primary Reasoning Agent**
    * **Primary AWS Services:**
        * **Amazon Bedrock:** Provides access to foundational Large Language Models for intent recognition, parameter extraction, response synthesis, and decision-making for MCP tool invocation.
        * **AWS Step Functions (Standard Workflows):** Orchestrates complex conversational flows, manages state across multiple LLM calls and MCP tool invocations, and handles error/retry logic.
        * **AWS Lambda:** Executes the core orchestration logic that interfaces with Bedrock, prepares MCP tool requests, processes tool responses, and integrates with Step Functions. Lambda functions also implement the individual MCP tools.
    * **Rationale:** Bedrock offers managed LLM access. Step Functions provides robust serverless orchestration for complex, multi-step processes. Lambda offers flexible compute for the orchestration logic and tool execution.

3.  **User Profile Service (Container)**
    * **Primary AWS Services:**
        * **Amazon DynamoDB:** A fully managed NoSQL database used to store user profiles, including loyalty program memberships, preferences, and potentially saved results. Chosen for its scalability, low-latency access, and flexible schema.
        * **AWS Lambda:** (If an API layer is created for this service) Provides the logic for creating, reading, updating, and deleting user profile data in DynamoDB, exposed via an internal API Gateway endpoint or directly invoked by other services with appropriate IAM permissions.
    * **Rationale:** DynamoDB is well-suited for user profile stores that require fast key-value lookups and can scale massively. Lambda provides serverless compute for data access.

4.  **Knowledge Base Service (GraphRAG) (Container)**
    * **Primary AWS Services:**
        * **Amazon Neptune:** A fully managed graph database used to store and query the complex relationships within airline loyalty program data.
        * **Amazon S3:** Stores supplementary documents (e.g., detailed T&Cs, articles) that can be used in the Retrieval Augmented Generation (RAG) process to provide additional context to the LLM.
        * **AWS Lambda:** Implements the RAG retrieval logic (querying Neptune, fetching documents from S3, preparing context for the LLM) and potentially exposes an internal interface for this service.
    * **Rationale:** Neptune is optimized for graph traversals. S3 provides durable storage for RAG documents. Lambda offers flexible compute for the RAG logic.

5.  **Data Ingestion Pipeline Service (Container)**
    * **Primary AWS Services (Orchestrated by AWS Step Functions - see 4.6.3):**
        * **Amazon S3:** Serves as the landing zone for raw source documents (HTML, PDF, text), staging for intermediate processed data (Textract output, cleaned text, LLM-extracted JSON), and for Neptune bulk load files (CSVs).
        * **AWS Lambda:** Used for initial S3 event triggering, dispatch logic based on file type, invoking Textract, pre-processing text, calling Bedrock for smaller extraction tasks within Step Functions, initiating Neptune bulk loads, and monitoring load status.
        * **Amazon Textract:** Performs OCR and extracts text, tables, and forms from PDF and image documents.
        * **AWS Glue (ETL Jobs - Python Shell or Spark):** Executes complex data transformation logic, including:
            * Core information extraction from processed text/Textract output by invoking LLMs via Amazon Bedrock.
            * Transformation of extracted JSON "facts" into Neptune-compatible CSV formats.
        * **(Optional) Amazon Athena:** Used for ad-hoc querying and validation of intermediate structured data stored in S3.
    * **Rationale:** This combination of services provides a scalable, serverless, and event-driven pipeline capable of handling diverse data types, performing complex AI-driven transformations, and efficiently loading data into the graph database. AWS Step Functions orchestrates these services into a resilient workflow.

6.  **Notification Service (Container)**
    * **Primary AWS Services:**
        * **Amazon SNS (Simple Notification Service):** Used to fan out notification requests to various endpoints (e.g., email, SMS - though specific endpoint integrations would be built out).
        * **AWS Lambda:** Subscribes to SNS topics (if applicable) or is directly invoked to compose notification messages and interact with specific delivery services (e.g., Amazon SES for email).
    * **Rationale:** SNS provides a decoupled and scalable way to manage notifications. Lambda offers the compute for message formatting and dispatch logic.

This mapping illustrates how the logical architecture translates into a tangible set of cloud services, each chosen for its specific strengths in fulfilling the responsibilities of the corresponding container.
---
*This page is part of the AI Loyalty Maximizer Suite - AWS Reference Architecture. For overall context, please see the [Architecture Overview](../00_ARCHITECTURE_OVERVIEW.md) or the main [README.md](../../../README.md) of this repository.*

---
**(Placeholder for Previous/Next Navigation Links - We'll add these once the content for this page is drafted and we know the next page)**