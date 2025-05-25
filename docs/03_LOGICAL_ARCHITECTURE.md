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


**Container Descriptions:**
*(This section will list and describe each container shown in the diagram above. We will draft these descriptions after finalizing the container diagram elements.)*