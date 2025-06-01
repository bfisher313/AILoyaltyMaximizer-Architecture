
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

## 5.3.4. High Availability (HA) & Disaster Recovery (DR) Strategy (Conceptual)

Ensuring the AI Loyalty Maximizer Suite remains available to users and resilient to failures is a key architectural consideration. This section outlines the conceptual strategies for High Availability (HA) within a single AWS Region and Disaster Recovery (DR) across regions.

### 5.3.4.1. High Availability (HA) Strategy

The HA strategy focuses on preventing single points of failure and ensuring the system can withstand the failure of individual components or an entire Availability Zone (AZ) within the primary AWS Region.

* **Leveraging Multiple Availability Zones (AZs):**
    * The core principle for HA is the distribution of resources across at least two, preferably three, AZs within the selected AWS Region.
    * **VPC Subnets:** As detailed in the Network Design (Section 5.3.3), public and private subnets are provisioned across multiple AZs.
    * **Amazon Neptune:** The Neptune database cluster will be configured as a Multi-AZ cluster. This involves a primary instance in one AZ and a standby replica in a different AZ, with synchronous data replication. In the event of a primary instance failure or an AZ outage, Neptune automatically fails over to the standby replica. Read replicas can also be placed in different AZs to distribute read load and improve availability.
    * **Amazon DynamoDB:** DynamoDB inherently provides high availability by synchronously replicating data across multiple AZs within a region, ensuring data durability and availability even if one AZ fails.
    * **Amazon S3:** Standard S3 storage classes (e.g., S3 Standard, S3 Intelligent-Tiering) automatically store data redundantly across a minimum of three AZs within a region, providing high durability and availability.
    * **AWS Lambda & Amazon API Gateway:** These services are inherently highly available and fault-tolerant, operating across multiple AZs within an AWS Region by default. API Gateway can route traffic to Lambda functions running in any available AZ.
    * **AWS Step Functions, AWS Glue, Amazon Bedrock, Amazon Textract, Amazon SNS:** These are regional AWS managed services designed for high availability, with their underlying infrastructure distributed across multiple AZs.
    * **NAT Gateways:** Deployed in multiple AZs (one per public subnet associated with an AZ) to ensure outbound internet connectivity for resources in private subnets remains available if one NAT Gateway or AZ fails.

* **Stateless Application Components:**
    * AWS Lambda functions, which form the core of many services (Conversational API, LLM Orchestration, MCP Tools, Data Ingestion steps, Notification Service), are designed to be stateless. This allows requests to be handled by any available function instance in any AZ, facilitating load balancing and failover.

* **Elasticity and Auto-Scaling:**
    * Services like AWS Lambda, API Gateway, DynamoDB (with on-demand capacity), S3, and Step Functions automatically scale to handle varying loads, contributing to overall availability by preventing resource exhaustion.

### 5.3.4.2. Disaster Recovery (DR) Strategy (Conceptual)

While the HA strategy addresses failures within a single AWS Region, the DR strategy considers recovery from larger-scale events that might affect an entire region. For this conceptual architecture, a phased DR approach would be considered, with the initial focus on backup and restore, and more advanced strategies as future enhancements.

* **Recovery Time Objective (RTO) & Recovery Point Objective (RPO):**
    * For a production system, specific RTO (how quickly the service must be restored) and RPO (how much data loss is acceptable) targets would be defined based on business impact analysis. These targets would drive the choice of DR strategy. For this conceptual document, we assume a moderate RTO/RPO allowing for a backup/restore approach initially.

* **Key DR Components:**
    * **Data Backup & Restore:**
        * **Amazon Neptune:** Automated daily snapshots and continuous backups will be enabled. These snapshots can be copied to another AWS Region. In a DR scenario, the infrastructure can be re-provisioned in the DR region using IaC, and the Neptune cluster can be restored from a snapshot.
        * **Amazon DynamoDB:** Point-in-Time Recovery (PITR) will be enabled, allowing restoration to any point in the preceding 35 days. On-demand backups can also be taken and copied to S3 in another region for DR. DynamoDB Global Tables could be considered for live multi-region replication if near-zero RPO/RTO is a future requirement.
        * **Amazon S3:** Critical data in S3 (e.g., raw source documents, processed data, LLM-extracted facts, Neptune load files) can be configured with Cross-Region Replication (CRR) to automatically replicate objects to a bucket in a DR region. S3 Versioning will also be enabled to protect against accidental deletions or overwrites.
    * **Infrastructure as Code (IaC):**
        * The entire infrastructure defined using AWS CDK or CloudFormation (Section 5.2.5) is version-controlled and can be deployed in a DR region to recreate the application environment.
    * **Application Code & Configuration:**
        * Application code (Lambda functions, Glue scripts) is stored in version control (Git) and can be deployed to the DR region via the CI/CD pipeline (Section 5.2.6).
        * Configuration parameters would need to be managed for the DR environment.
    * **DNS Failover (Amazon Route 53):**
        * If the application has a custom domain name, Amazon Route 53 can be used for DNS management. Health checks and DNS failover policies can be configured to redirect traffic to resources in the DR region if the primary region becomes unavailable.

* **Conceptual DR Strategies (Phased Approach):**
    1.  **Backup and Restore (Initial):** The simplest DR approach, relying on restoring data backups and redeploying infrastructure and application code in a DR region. This typically has higher RTO/RPO.
    2.  **Pilot Light (Future Consideration):** A minimal version of the core infrastructure (e.g., a small Neptune cluster, replicated S3 data) is kept running in the DR region. In a disaster, this core can be scaled up, and the full application deployed. This reduces RTO compared to pure backup/restore.
    3.  **Warm Standby (Future Consideration):** A scaled-down but fully functional version of the system runs in the DR region, with data being actively replicated (e.g., Neptune cross-region replicas if available, DynamoDB Global Tables, S3 CRR). Failover is quicker, reducing RTO/RPO further.
    4.  **Multi-Site Active-Active (Future Consideration - High Complexity/Cost):** Running the full application in multiple regions simultaneously. This offers the lowest RTO/RPO but is the most complex and costly to implement and manage. Not envisioned for the initial architecture.

This HA/DR strategy aims to provide a resilient platform by leveraging AWS regional capabilities and standard recovery patterns. The specific DR approach would be refined based on business continuity requirements for a production deployment.

## 5.3.5. Environment Strategy (Conceptual)

To support a structured development, testing, and release process for the AI Loyalty Maximizer Suite, a multi-environment strategy is essential. This approach allows for changes to be developed and validated in isolated environments before being promoted to production, minimizing risks and ensuring stability.

**Proposed Environments:**

* **Development (Dev):**
    * **Purpose:** Used by developers for day-to-day development, experimentation, and unit testing. Data in this environment would typically be synthetic, sample data, or a heavily anonymized subset of production data (if applicable and compliant with data privacy).
    * **Characteristics:** May have scaled-down resources to optimize costs. CI/CD will deploy feature branches or development branches to this environment frequently.
* **Staging/Testing (Staging/Test):**
    * **Purpose:** A stable environment that closely mirrors production. Used for integration testing, end-to-end testing, user acceptance testing (UAT), and performance testing before a production release.
    * **Characteristics:** Should use a configuration as close to production as possible. Data might be a sanitized and anonymized snapshot of production data or a larger, more realistic synthetic dataset. Deployments are typically triggered after successful builds and tests on a main development or release branch.
* **Production (Prod):**
    * **Purpose:** The live environment used by end-users (`Travel Enthusiast`, `Data Curator`).
    * **Characteristics:** Highest levels of availability, security, monitoring, and performance. Deployments to production are carefully controlled, often requiring manual approvals, and follow successful validation in the staging environment. Uses real user data and the complete knowledge graph.

**Isolation Strategies within AWS:**

The primary goal is to achieve strong isolation between these environments to prevent interference and ensure security.

* **Separate AWS Accounts (Preferred Best Practice):**
    * **Approach:** Each environment (Dev, Staging, Prod) would reside in its own dedicated AWS account. This provides the strongest level of isolation for resources, security (IAM policies, security groups), networking (VPCs can be completely separate), and billing.
    * **Management:** AWS Organizations can be used to centrally manage multiple accounts, apply Service Control Policies (SCPs), and consolidate billing.
* **Separate VPCs within a Single Account (Alternative):**
    * **Approach:** If managing multiple AWS accounts is not feasible initially, environments can be isolated by deploying each into its own dedicated Virtual Private Cloud (VPC) within a single AWS account.
    * **Considerations:** Requires careful IAM policy design to ensure resources in one environment's VPC cannot improperly access resources in another. Network peering or Transit Gateway would be needed if controlled communication between VPCs is required (though generally, strong isolation is preferred).
* **Resource Naming and Tagging Conventions:**
    * Regardless of the account/VPC strategy, a consistent naming convention (e.g., `dev-loyalty-api-lambda`, `prod-loyalty-neptune-cluster`) and resource tagging strategy (e.g., `Environment:Dev`, `Environment:Prod`, `Project:AIMaximizer`) will be strictly enforced for all AWS resources. This aids in identification, cost allocation, automation, and access control.

**Promotion Process:**

* Changes (application code and infrastructure code) will be promoted through the environments sequentially (Dev -> Staging -> Prod) via the CI/CD pipeline (as described in Section 5.2.6).
* Each stage in the pipeline will deploy to the corresponding environment and run appropriate automated tests. Manual approvals will gate promotions to production.

**Data Management Across Environments:**

* Each environment will have its own independent instances of data stores (Amazon Neptune, Amazon DynamoDB, Amazon S3 buckets for pipeline staging).
* Processes will be established for managing test data in non-production environments, ensuring that sensitive production data is not used directly in Dev or Staging without appropriate sanitization or anonymization.

This multi-environment strategy, managed through IaC and CI/CD, provides a robust framework for developing, testing, and releasing the AI Loyalty Maximizer Suite in a controlled and reliable manner.

---
*This page is part of the AI Loyalty Maximizer Suite - AWS Reference Architecture. For overall context, please see the [Architecture Overview](../00_ARCHITECTURE_OVERVIEW.md) or the main [README.md](../../../README.md) of this repository.*

---
**Previous:** [5.2. Development View (System Organization & Realization)](./05_02_DEVELOPMENT_VIEW.md)
**Next:** [6. Cross-Cutting Concerns](../../06_CROSS_CUTTING_CONCERNS.md)