
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

### 5.1.2.2. Scenario: Processing a "Strategic Award Pathway Analysis" User Query

This scenario describes the process flow when a `Travel Enthusiast` queries the system to understand strategic options for using their existing rewards currency (miles/points) for a specific travel goal, focusing on identifying potential programs, transfer opportunities, and conceptual redemption values.

**Trigger:** The `Travel Enthusiast`, via a client application, submits a query like "What are my best options to use 150,000 Amex points and 80,000 United miles for a business class trip from New York to Paris for two people next May?"

**[🚧 TODO: Insert Sequence Diagram for 'Strategic Award Pathway Analysis Query' here. See GitHub Issue #8 🚧]**

**Sequence of Interactions & Data Flows:**

1.  **User Input to Conversational API:**
    * The client application sends the user's natural language query or structured input to the `Conversational API` container. This input includes travel parameters (origin, destination, dates, cabin class, travelers) and details of their available rewards currency.

2.  **Request Forwarding & Initial Processing:**
    * The `Conversational API` receives the request, performs basic validation, and potentially authenticates the user.
    * It then forwards the processed query data to the `LLM Orchestration Service`.

3.  **Intent Recognition & Parameter Extraction (LLM Orchestration Service):**
    * The `LLM Orchestration Service` (Primary Reasoning Agent, using Amazon Bedrock) receives the query.
    * It uses an LLM to:
        * Recognize the user's intent (e.g., "analyze_award_redemption_strategies" or "find_award_pathways").
        * Extract key parameters: origin, destination, travel preferences, and specified rewards balances.
        * If necessary, formulate clarifying questions for the user.
    * **Data Flow:** Query parameters, user ID.

4.  **User Profile Retrieval (Complementary Rewards Data):**
    * The `LLM Orchestration Service` may invoke the `get_user_profile` MCP Tool to fetch any additional stored rewards balances or travel preferences from the `User Profile Service` that could be relevant to the analysis.
    * **Data Flow:** User ID to `User Profile Service`; user rewards/preferences from `User Profile Service` to `LLM Orchestration Service`.

5.  **Strategic Pathway Analysis (MCP Tool Invocation - e.g., `analyze_award_redemption_strategies`):**
    * The `LLM Orchestration Service` determines the need for the `analyze_award_redemption_strategies` MCP Tool.
    * It prepares the request payload, including all travel parameters and consolidated user rewards information.
    * The `analyze_award_redemption_strategies` tool (an AWS Lambda function, potentially orchestrated by Step Functions for complex internal logic) is executed. This tool performs the core analysis:
        * **a. Identify Relevant Airline Programs:** Queries the `Knowledge Base Service (GraphRAG)` (Amazon Neptune) to find airline loyalty programs that serve the route or have strong partner networks for the route.
        * **b. Analyze Transfer Partnerships:** For each of the user's rewards currencies (e.g., Amex MR, Chase UR, specific airline miles), it queries the `Knowledge Base Service (GraphRAG)` to find direct and indirect transfer partners relevant to the identified airline programs, including transfer ratios and any known conditions or minimums.
        * **c. Retrieve Conceptual Award Costs & Rules:** For promising airline programs (accessible directly or via transfer), it queries the `Knowledge Base Service (GraphRAG)` for:
            * Information from fixed award charts (if applicable to the program/route/partner).
            * Known "sweet spot" redemptions or typical point ranges for the specified route and cabin class (based on curated data in the graph).
            * Key redemption rules, typical taxes/fees patterns, and notes on programs known for dynamic pricing (flagging them for the user to check live).
        * **d. Pathway Generation:** The tool synthesizes this information to generate potential strategic pathways, e.g., "Transfer X Amex points to Airline Program Y to target an award on Partner Airline Z, which typically costs around P points for this route."
    * **Data Flow:** Travel parameters, user rewards data to the tool; queries to `Knowledge Base Service`; program details, transfer rules, fixed/conceptual award costs, sweet spot info from `Knowledge Base Service` to the tool.

6.  **Option Collation & Prioritization (Internal to MCP Tool or LLM Orchestrator):**
    * The `analyze_award_redemption_strategies` tool collates the identified pathways and strategies.
    * It might apply some initial filtering or prioritization based on factors like the total conceptual points cost, number of transfers, or known program value.
    * **Data Flow:** Internal processing of generated strategies.

7.  **Response Aggregation & Synthesis (LLM Orchestration Service):**
    * The `analyze_award_redemption_strategies` tool returns a structured response to the `LLM Orchestration Service`. This response details the identified programs, transfer options, conceptual costs, and any important caveats (e.g., "Program X uses dynamic pricing; check live rates").
    * The `LLM Orchestration Service` (using Amazon Bedrock) takes this structured information and synthesizes a user-friendly natural language explanation. The response will focus on empowering the user with strategic options to investigate further, rather than guaranteeing availability at a specific price.
    * **Data Flow:** Structured strategic options and caveats to `LLM Orchestration Service`; natural language advice generated.

8.  **Response Delivery to User:**
    * The `LLM Orchestration Service` sends the final natural language advice (and potentially structured data outlining the strategies) back to the `Conversational API`.
    * The `Conversational API` forwards this to the user's client application.

This scenario now accurately reflects the system's capability to provide strategic guidance based on its knowledge graph, acknowledging the limitations around live dynamic award pricing by focusing on empowering the user with information to conduct their own targeted searches.

---
*This page is part of the AI Loyalty Maximizer Suite - AWS Reference Architecture. For overall context, please see the [Architecture Overview](../00_ARCHITECTURE_OVERVIEW.md) or the main [README.md](../../../README.md) of this repository.*

---
**(Placeholder for Previous/Next Navigation Links - We'll add these once the next section is started or if this is the last for now)**