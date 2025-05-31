
# 5.1. Process View (Runtime Behavior & Concurrency)

## 5.1.1. Introduction

The Process View describes the dynamic aspects of the AI Loyalty Maximizer Suite, focusing on how the system's components interact at runtime to achieve its objectives. While the Logical Architecture (Section 3) detailed the static structure (the "what"), this view illustrates the "how" – the sequence of operations, data flows, and concurrency models for key processes.

Understanding these dynamic behaviors is essential for assessing system performance, identifying potential bottlenecks, and ensuring that the architecture can effectively handle concurrent user requests and background tasks. This view will cover key runtime scenarios, the system's approach to concurrency, and how asynchronous operations are managed.

## 5.1.2. Key Runtime Scenarios

This subsection details the step-by-step interactions between the major containers (defined in Section 3.3) for critical system functionalities.

### 5.1.2.1. Scenario: Processing a "Calculate Flight Earnings" User Query

This scenario describes the process flow when a `Travel Enthusiast` queries the system to calculate potential earnings for a specific flight itinerary.

**Trigger:** The `Travel Enthusiast`, via a client application (e.g., web/mobile app), submits a query like "How many miles will I earn if I fly UA flight 123 from SFO to JFK in fare class Q, credited to my MileagePlus account?"

**[🚧 TODO: Insert Sequence Diagram for 'Calculate Flight Earnings Query' here. See GitHub Issue #7 🚧]**

**Sequence of Interactions & Data Flows:**

1.  **User Input to Conversational API:**
    * The client application sends the user's natural language query or structured input (containing flight details like airline, origin, destination, fare class, and target loyalty program) to the `Conversational API` container (realized via Amazon API Gateway and an initial AWS Lambda function).

2.  **Request Forwarding & Initial Processing:**
    * The `Conversational API` receives the request, performs initial validation (e.g., input format checks), and potentially authenticates the user.
    * It then forwards the processed query data to the `LLM Orchestration Service`.

3.  **Intent Recognition & Parameter Extraction (LLM Orchestration Service):**
    * The `LLM Orchestration Service` (acting as the Primary Reasoning Agent, leveraging Amazon Bedrock) receives the query.
    * It uses an LLM to:
        * Recognize the user's intent (e.g., "calculate_flight_earnings").
        * Extract key parameters from the query (e.g., flight segments, fare classes, target loyalty programs). If details are missing, the LLM might formulate a clarifying question to send back to the user (this would involve a return trip through the `Conversational API`).
    * **Data Flow:** Query parameters, user ID.

4.  **User Profile Retrieval (Optional but likely):**
    * If the user is authenticated and has a profile, the `LLM Orchestration Service` may invoke the `get_user_profile` MCP Tool.
    * This tool, managed by the `LLM Orchestration Service`, interacts with the `User Profile Service` (Amazon DynamoDB) to fetch relevant user data, such as existing elite statuses in the target loyalty programs, which might affect earning bonuses.
    * **Data Flow:** User ID to `User Profile Service`; user status/preferences from `User Profile Service` to `LLM Orchestration Service`.

5.  **Earning Rule Retrieval & Conditional Distance Calculation (MCP Tool Invocation):**
    * The `LLM Orchestration Service` determines that the `calculate_flight_earnings` MCP Tool is needed.
    * It prepares the request payload for this tool, including flight segment details (origin/destination airports, carriers, fare class), `ticketPrice` information (if available from the user or a previous step), and target loyalty programs, along with any relevant user context (like elite status).
    * The `calculate_flight_earnings` tool (an AWS Lambda function orchestrated by Step Functions or directly invoked) is executed. This tool will:
        * **a. Retrieve Earning Rules:** First, query the `Knowledge Base Service (GraphRAG)` (Amazon Neptune) to find the applicable `EarningRule`(s) based on operating carrier, marketing carrier, fare class, target loyalty program, and any other initial conditions (e.g., effective dates, general applicability). This involves graph traversals to find relevant rules and partnerships.
        * **b. Determine Calculation Basis:** Analyze the retrieved `EarningRule`(s). Each rule should ideally specify its calculation basis (e.g., "distance-based," "revenue-based," "fixed_amount," "segment-based").
        * **c. Conditional Distance Calculation:**
            * **If** any applicable rule is identified as "distance-based":
                * Query the `Knowledge Base Service (GraphRAG)` again (or ensure initial query included it) to retrieve the geographic coordinates of the origin and destination airports for each relevant flight segment.
                * Calculate the Great Circle Distance for each segment. This calculated distance is then stored for use in the earnings calculation.
            * **Else (if fare-based, fixed, etc.):** The coordinate lookup and distance calculation are skipped for that rule/segment.
    * **Data Flow:**
        * Segment details, fare information (if available), target programs to `calculate_flight_earnings` tool.
        * Initial query parameters (carrier, fare class, program) to `Knowledge Base Service`.
        * `EarningRule`(s) from `Knowledge Base Service` to the tool.
        * (Conditional) Airport codes to `Knowledge Base Service`; airport coordinates from `Knowledge Base Service` to the tool.
        * (Conditional) Calculated distance used internally by the tool.

6.  **Earnings Calculation:**
    * The `calculate_flight_earnings` tool applies the retrieved earning rules (and any user-specific elite bonuses) according to their specified calculation basis:
        * **For distance-based rules:** Uses the calculated Great Circle Distance.
        * **For revenue-based rules:** Uses the relevant components from the `ticketPrice` object in the request (e.g., base fare + carrier-imposed surcharges).
        * **For fixed-amount or segment-based rules:** Applies the defined fixed values.
    * It computes the redeemable rewards currency and elite-qualifying metrics for each target program.
    * **Data Flow:** Internal to the `calculate_flight_earnings` tool, using data retrieved in step 5.

7.  **Response Aggregation & Synthesis (LLM Orchestration Service):**
    * The `calculate_flight_earnings` tool returns the structured earning options (as defined in its MCP response schema) to the `LLM Orchestration Service`.
    * The `LLM Orchestration Service` (using Amazon Bedrock) takes these structured results and synthesizes a natural language response for the user. It may also generate summary advice or highlight key findings.
    * **Data Flow:** Structured earning data to `LLM Orchestration Service`; natural language response generated.

8.  **Response Delivery to User:**
    * The `LLM Orchestration Service` sends the final natural language response (and potentially any structured data for the client app to display) back to the `Conversational API`.
    * The `Conversational API` forwards the response to the user's client application, which then displays it to the `Travel Enthusiast`.

This detailed flow illustrates how multiple containers collaborate, leveraging the knowledge graph and AI, to fulfill a common user request.

---
*This page is part of the AI Loyalty Maximizer Suite - AWS Reference Architecture. For overall context, please see the [Architecture Overview](../00_ARCHITECTURE_OVERVIEW.md) or the main [README.md](../../../README.md) of this repository.*

---
**(Placeholder for Previous/Next Navigation Links - We'll add these once the next section is started or if this is the last for now)**