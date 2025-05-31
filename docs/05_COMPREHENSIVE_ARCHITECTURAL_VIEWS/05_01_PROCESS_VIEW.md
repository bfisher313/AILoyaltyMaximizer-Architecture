
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

### 5.1.2.3. Scenario: Automated Knowledge Base Ingestion Pipeline Flow

This scenario describes the backend process flow when a `Data Curator` submits a new source document (e.g., an HTML page, PDF, or text file containing loyalty program information) to be processed and ingested into the system's knowledge graph.

**Trigger:** The `Data Curator` uploads a file to the designated "Raw Source Data Bucket" on Amazon S3 (e.g., `s3://loyalty-rules-raw-pages/`).

**[🚧 TODO: Insert Process Flow/Activity Diagram for 'Automated Knowledge Base Ingestion Pipeline' here. See GitHub Issue #9 🚧]**

**Sequence of Interactions & Data Flows:**

1.  **S3 Object Creation & Pipeline Initiation:**
    * An `s3:ObjectCreated:*` event in the "Raw Source Data Bucket" triggers an initial AWS Lambda function (e.g., `PipelineTriggerLambda`).
    * This Lambda function performs basic validation (e.g., checks if the file type is expected) and gathers essential metadata (S3 bucket name, object key).
    * It then initiates an execution of the main AWS Step Functions state machine designed for this pipeline, passing the S3 object metadata as input.
    * **Data Flow:** S3 object metadata to Step Functions.

2.  **Step 1: Initial Processing & Dispatch (Orchestrated by Step Functions, executed by Lambda):**
    * The Step Functions state machine invokes an AWS Lambda function (`InitialDispatchLambda` - corresponding to stage 4.6.4).
    * This Lambda:
        * Determines the file type (HTML, PDF, TXT).
        * **If PDF/Image:** Initiates an asynchronous Amazon Textract job (`StartDocumentAnalysis`). The Textract job is configured to send its completion notification (success/failure) to an SNS topic. The Step Functions workflow pauses at this state using the `.waitForTaskToken` integration pattern. A separate "TextractCallbackLambda" (subscribed to the SNS topic) will later send a success/failure signal with the Textract output S3 location back to Step Functions to resume the workflow.
        * **If HTML/TXT:** Performs initial text cleaning (e.g., stripping HTML tags to get raw text) and stages the cleaned text in a designated S3 prefix (e.g., `s3://loyalty-rules-processed-text/`).
    * **Data Flow:** Original S3 object -> `InitialDispatchLambda` -> (if PDF) Textract -> (eventually) Textract JSON output to a new S3 location OR (if HTML/TXT) cleaned text to a new S3 location. The S3 path to this processed content is passed to the next state.

3.  **Step 2: Core Information Extraction (Orchestrated by Step Functions, executed by AWS Glue ETL with LLM):**
    * Step Functions invokes an AWS Glue ETL job (`LoyaltyDataExtractionGlueJob` - corresponding to stage 4.6.5).
    * This Glue job (Python Shell or Spark):
        * Reads the processed content (cleaned text or Textract JSON) from S3.
        * Chunks the content if necessary.
        * Constructs appropriate prompts and invokes an LLM via Amazon Bedrock (conceptually, the `extract_loyalty_info_from_document` MCP tool logic) to extract structured information (entities, rules, dates, conditions) based on predefined target schemas.
        * Parses and validates the LLM's JSON response.
        * Aggregates results if chunking was used.
    * **Data Flow:** Processed text/Textract JSON from S3 -> Glue ETL job -> Prompts/content to Amazon Bedrock -> Structured JSON "facts" from Bedrock -> Glue ETL job.
    * The Glue job writes these extracted structured JSON "facts" to a designated S3 prefix (e.g., `s3://loyalty-rules-llm-extracted-facts/`). This output is passed to the next state.

4.  **Step 3 (Optional): Intermediate Validation (Orchestrated by Step Functions, potentially involving Athena/Lambda):**
    * If this stage (corresponding to 4.6.6) is enabled in the Step Functions workflow:
        * A Lambda function could be invoked to execute predefined Amazon Athena queries against the extracted JSON facts (assuming a Glue Data Catalog table is defined over that S3 location).
        * Based on query results, if validation issues are found, the workflow might:
            * Route to a manual review/correction state (e.g., by sending a notification and waiting for a task token).
            * Flag the data but allow processing to continue with warnings.
            * Route to an error state if critical issues are found.
    * **Data Flow:** Extracted JSON facts from S3 -> (queried by) Athena/Lambda -> Validation results. Validated/flagged JSON facts S3 path passed to the next state.

5.  **Step 4: Graph Transformation (Orchestrated by Step Functions, executed by AWS Glue ETL):**
    * Step Functions invokes another AWS Glue ETL job (`GraphTransformationGlueJob` - corresponding to the transformation part of stage 4.6.7).
    * This Glue job:
        * Reads the (validated) structured JSON facts from S3.
        * Maps these facts to the Amazon Neptune graph schema (nodes and edges).
        * Generates CSV files formatted for Neptune's bulk loader (one set for nodes, one for edges).
    * **Data Flow:** Structured JSON facts from S3 -> Glue ETL job -> Neptune-formatted CSV files.
    * The Glue job writes these CSV files to a designated S3 prefix (e.g., `s3://loyalty-rules-neptune-load-files/`). The S3 path to these load files is passed to the next state.

6.  **Step 5: Neptune Bulk Load Initiation & Monitoring (Orchestrated by Step Functions, executed by Lambda):**
    * Step Functions invokes an AWS Lambda function (`NeptuneLoadInitiatorLambda` - corresponding to the loading part of stage 4.6.7).
    * This Lambda:
        * Initiates an Amazon Neptune bulk load command, pointing to the S3 location of the CSV files.
        * Receives a `loadId` from Neptune.
    * Step Functions then enters a polling loop (or uses a callback pattern if Neptune load can provide one, though polling is common):
        * Periodically invokes another Lambda function (`NeptuneLoadMonitorLambda`) with the `loadId` to check the status of the bulk load job.
        * Continues polling until the load job completes (succeeds or fails).
    * **Data Flow:** S3 path to CSVs -> `NeptuneLoadInitiatorLambda` -> Load command to Neptune. `loadId` -> `NeptuneLoadMonitorLambda` -> Status query to Neptune -> Load status.

7.  **Step 6: Finalization & Logging (Orchestrated by Step Functions):**
    * Based on the Neptune bulk load status:
        * **If successful:** Logs completion, potentially moves the original source file in the raw S3 bucket to an "archive" or "processed" prefix. Sends a success notification (e.g., via SNS).
        * **If failed:** Logs detailed errors (Neptune often provides error logs in S3 for failed bulk loads), moves the original source file to an "error" prefix, and sends a failure notification for investigation.
    * The Step Functions execution completes.

This pipeline demonstrates an automated, resilient, and observable process for transforming diverse source data into a structured knowledge graph, leveraging multiple AWS services in a coordinated manner.

---
*This page is part of the AI Loyalty Maximizer Suite - AWS Reference Architecture. For overall context, please see the [Architecture Overview](../00_ARCHITECTURE_OVERVIEW.md) or the main [README.md](../../../README.md) of this repository.*

---
**(Placeholder for Previous/Next Navigation Links - We'll add these once the next section is started or if this is the last for now)**