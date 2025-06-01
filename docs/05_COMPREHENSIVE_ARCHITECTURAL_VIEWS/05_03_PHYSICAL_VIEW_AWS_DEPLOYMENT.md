
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

## 5.3.3. Network Design

A well-architected network foundation is critical for security, scalability, and manageability. The AI Loyalty Maximizer Suite will be deployed within a custom Amazon Virtual Private Cloud (VPC), providing a logically isolated section of the AWS Cloud.

**[🚧 TODO: Insert Detailed Network Diagram here, showing VPC, Subnets, Route Tables, Gateways, Endpoints, and Security Group interactions. See GitHub Issue #12m 🚧]**

### 5.3.3.1. Amazon VPC Strategy

* **Primary Region:** The system will be deployed within a single primary AWS Region (e.g., `us-east-1` or `us-west-2`), chosen based on factors like latency to users, service availability, and cost. A multi-region strategy for Disaster Recovery is a future consideration (see Section 5.3.4).
* **Single VPC Design:** For the current scope, a single VPC is deemed sufficient to host all application resources. This simplifies network management while still allowing for strong segmentation using subnets and security groups.
* **VPC CIDR Block:** A non-overlapping IP address range will be selected for the VPC (e.g., `10.0.0.0/16`), providing ample IP address space for current and future resources.

### 5.3.3.2. Subnet Design

To ensure high availability and network segmentation, subnets will be distributed across multiple Availability Zones (AZs) within the chosen AWS Region (typically 2-3 AZs).

* **Public Subnets:**
    * **Purpose:** To host resources that require direct inbound or outbound internet connectivity, such as NAT Gateways or Application Load Balancers (ALBs), if ALBs were to be used in front of API Gateway for specific purposes like WAF integration or custom domain handling at the edge (though API Gateway often handles this directly).
    * **Distribution:** At least one public subnet per utilized AZ.
    * **Routing:** Associated with a route table that directs internet-bound traffic (`0.0.0.0/0`) to an Internet Gateway (IGW).
* **Private Subnets (Application Tier):**
    * **Purpose:** To host the majority of the application resources, including AWS Lambda functions (when configured to access VPC resources or require controlled outbound access), AWS Fargate tasks (if used), and interface VPC endpoints for AWS services. These resources do not have direct inbound internet access.
    * **Distribution:** At least one application private subnet per utilized AZ for HA.
    * **Routing:** Associated with a route table that directs internet-bound traffic (`0.0.0.0/0`) to NAT Gateways (located in the public subnets) for controlled outbound internet access (e.g., for Lambda/Glue to access external APIs if not using VPC endpoints, or for OS updates if using EC2-based services).
* **Private Subnets (Data Tier - Isolated):**
    * **Purpose:** To host data stores like Amazon Neptune database instances and Amazon ElastiCache (if used for caching). These subnets are designed for maximum security with no direct internet access (inbound or outbound).
    * **Distribution:** At least one data private subnet per utilized AZ for HA of Neptune (Multi-AZ deployment).
    * **Routing:** Associated with a route table that does *not* have a route to an Internet Gateway or NAT Gateway. Access to AWS services will be exclusively through VPC Endpoints.

### 5.3.3.3. Routing & Internet Access

* **Internet Gateway (IGW):** Attached to the VPC to allow communication between resources in public subnets and the internet.
* **NAT Gateways:** Deployed in each public subnet (one per AZ for redundancy and HA) and assigned Elastic IP addresses. Private subnets requiring outbound internet access will have routes pointing to these NAT Gateways. This allows resources in private subnets to access external services (e.g., third-party APIs, software repositories) without exposing them to direct inbound internet connections.
* **Route Tables:** Custom route tables will be created and associated with each subnet to precisely control traffic flow.

### 5.3.3.4. Security Groups (SGs)

* **Role:** Act as stateful virtual firewalls at the resource level (e.g., for Lambda functions, Neptune instances, Glue connections, VPC endpoints).
* **Principle of Least Privilege:** Inbound and outbound rules will be strictly defined to allow only necessary traffic. For example:
    * The Security Group for Amazon Neptune will only allow inbound traffic on the database port from the Security Groups associated with the application Lambda functions (e.g., those in the `Knowledge Base Service` or `LLM Orchestration Service` that query the graph).
    * Lambda function Security Groups will allow outbound traffic to required AWS service endpoints (via VPC Endpoints) and specific external APIs if necessary (via NAT Gateway).
    * Security Groups for public-facing resources (like NAT Gateways, or ALBs if used) will be configured accordingly.

### 5.3.3.5. Network ACLs (NACLs)

* **Role:** Act as stateless firewalls at the subnet level, providing an additional, optional layer of defense.
* **Strategy:** NACLs will be kept relatively broad initially, allowing all traffic between application and data tier subnets within the VPC by default, and relying more heavily on the granular control of Security Groups. Specific deny rules can be added to NACLs for known malicious IPs or to enforce broader network segmentation policies if required.

### 5.3.3.6. VPC Endpoints (AWS PrivateLink & Gateway Endpoints)

To enhance security and reduce data transfer costs by keeping traffic within the AWS network, VPC Endpoints will be extensively used:

* **Gateway Endpoints:**
    * **Amazon S3:** For private access to S3 buckets from within the VPC (e.g., for Lambda functions, Glue jobs accessing raw data, processed data, or Neptune load files).
    * **Amazon DynamoDB:** For private access to DynamoDB tables (e.g., the `User Profile Service`).
* **Interface Endpoints (AWS PrivateLink):**
    * **AWS Lambda:** For invoking Lambda functions privately.
    * **Amazon API Gateway (Private API Endpoints):** If internal services need to call API Gateway endpoints privately.
    * **Amazon Bedrock:** For private communication with LLMs.
    * **AWS Step Functions:** For private interaction with state machines.
    * **AWS Glue:** For private access to Glue service endpoints (e.g., for Glue jobs to communicate with the Glue service).
    * **Amazon CloudWatch Logs:** For sending logs privately from resources within the VPC.
    * **Amazon SNS:** For private publishing or subscribing to topics.
    * **Amazon Textract:** For private calls to the Textract service.
    * **Amazon ECR (if using container images for Lambda):** For private pulling of container images.
    * **AWS KMS:** For private access to encryption keys.
* **Placement:** Interface endpoints will be provisioned in the private application subnets, with DNS resolution enabled, allowing resources in those subnets to access AWS services using their standard public DNS names but over private connections.

This network design aims to create a secure, segmented, and highly available foundation for the AI Loyalty Maximizer Suite, utilizing best practices for AWS networking.

---
*This page is part of the AI Loyalty Maximizer Suite - AWS Reference Architecture. For overall context, please see the [Architecture Overview](../00_ARCHITECTURE_OVERVIEW.md) or the main [README.md](../../../README.md) of this repository.*

---
**(Placeholder for Previous/Next Navigation Links - We'll add these once the content for this page is drafted and we know the next page)**