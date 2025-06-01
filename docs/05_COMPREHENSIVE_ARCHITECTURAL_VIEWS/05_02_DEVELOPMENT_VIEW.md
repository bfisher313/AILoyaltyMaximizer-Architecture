# 5.2. Development View (System Organization & Realization)

## 5.2.1. Introduction

The Development View addresses the architecture from the perspective of the engineers and teams responsible for building, testing, deploying, and maintaining the AI Loyalty Maximizer Suite. It outlines the organization of the software modules, key development practices, and the strategies for managing infrastructure and automating the deployment lifecycle.

This view is crucial for understanding how the system's components are realized as code artifacts and how they are brought into the operational environment. It complements the Logical View (which describes *what* the components are) and the Process View (which describes *how* they interact at runtime) by focusing on the *build-time* and *deployment-time* aspects.

This section will cover:
* Conceptual organization of the source code.
* Key development languages, frameworks, and libraries.
* Strategies for building and packaging deployable artifacts.
* The approach to Infrastructure as Code (IaC) for provisioning and managing cloud resources.
* A conceptual overview of the Continuous Integration/Continuous Deployment (CI/CD) pipeline for automating releases.

## 5.2.2. Source Code Organization (Conceptual)

A well-organized source code repository is essential for maintainability, collaboration, and efficient CI/CD processes. For the AI Loyalty Maximizer Suite, a monorepo approach is proposed for simplicity in this conceptual stage, grouping all related code artifacts within a single version-controlled repository. However, components are designed to be logically distinct, allowing for a potential shift to a poly-repo (multiple repositories) structure if the project were to scale with multiple development teams.

The proposed top-level directory structure (within the main project repository which also contains `/docs`, `/diagrams_src`, `/diagrams_output`, etc.) for the application and infrastructure code might look as follows:

* **`/src/`**: Contains all the application source code for the various services and functions.
    * **`/src/conversational_api/`**: Code for the AWS Lambda function(s) handling requests from API Gateway and interfacing with the LLM Orchestration Service.
    * **`/src/llm_orchestration_service/`**:
        * `/lambda_functions/`: Python code for Lambda functions that implement MCP tools or core orchestration logic if not fully handled by Step Functions.
        * `/step_functions_asl/`: JSON definitions (Amazon States Language) for the Step Functions state machines orchestrating LLM interactions and tool invocations.
    * **`/src/user_profile_service/`**: Code for Lambda functions providing data access logic for the User Profile Service (if an API layer is used beyond direct DynamoDB access from other services).
    * **`/src_knowledge_base_service/`**: Python code for Lambda functions related to the RAG logic or any API exposed by the Knowledge Base Service.
    * **`/src/data_ingestion_pipeline/`**:
        * `/lambda_functions/`: Code for Lambda functions used in the pipeline (e.g., `PipelineTriggerLambda`, `InitialDispatchLambda`, `TextractCallbackLambda`, `NeptuneLoadInitiatorLambda`).
        * `/glue_scripts/`: Python/PySpark scripts for the AWS Glue ETL jobs (e.g., `LoyaltyDataExtractionGlueJob`, `GraphTransformationGlueJob`).
        * `/step_functions_asl/`: JSON definition for the Step Functions state machine orchestrating the data ingestion pipeline.
    * **`/src/notification_service/`**: Code for the Lambda function(s) handling notification logic and interacting with Amazon SNS.
    * **`/src/common_libs/`**: (Optional) Shared Python utility functions, data models (Pydantic models for MCP tools, etc.), or helper classes that might be used across multiple Lambda functions or Glue jobs. These would be packaged appropriately for use.

* **`/iac/`**: Contains all Infrastructure as Code (IaC) definitions.
    * **`/cdk/`** or **`/cloudformation/`**: Subdirectories for AWS CDK application stacks or CloudFormation templates.
    * Scripts would define all the AWS resources (API Gateway, Lambda functions, Step Functions state machines, DynamoDB tables, Neptune cluster, S3 buckets, Glue jobs, IAM roles, VPC configurations, etc.).
    * Organized by stack or service module for clarity (e.g., `vpc_stack.ts`, `api_stack.ts`, `data_pipeline_stack.ts`).

* **`/tests/`**: Contains automated tests.
    * **`/tests/unit/`**: Unit tests for individual Lambda functions, Glue script components, and utility libraries.
    * **`/tests/integration/`**: Integration tests for interactions between components (e.g., API Gateway to Lambda, Step Functions with Lambda).
    * **`/tests/e2e/`**: (Conceptual for this project) End-to-end tests for key user scenarios.

**Key Principles for Code Organization:**

* **Separation of Concerns:** Code for distinct logical services/containers or pipeline stages is kept in separate directories.
* **Clear Naming Conventions:** Consistent naming for files, directories, functions, and variables.
* **Modularity:** Encourage writing small, focused Lambda functions and Glue scripts where possible.
* **IaC for All Resources:** All cloud resources are defined as code to ensure repeatable and version-controlled environments.
* **Configuration Management:** Configuration parameters (e.g., S3 bucket names, LLM model IDs, queue names) would be managed outside the core application code, potentially using environment variables set by IaC, AWS Systems Manager Parameter Store, or AWS Secrets Manager for sensitive values.

This conceptual organization aims to provide a clean, understandable, and maintainable structure for the development and deployment of the AI Loyalty Maximizer Suite.

---
*This page is part of the AI Loyalty Maximizer Suite - AWS Reference Architecture. For overall context, please see the [Architecture Overview](../00_ARCHITECTURE_OVERVIEW.md) or the main [README.md](../../../README.md) of this repository.*

---
**(Placeholder for Previous/Next Navigation Links - We'll add these once the content for this page is drafted and we know the next page)**