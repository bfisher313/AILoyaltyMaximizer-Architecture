# 9. Future Roadmap

This architectural document describes a comprehensive, AI-first system. While the preceding sections detail a robust conceptual design, this section outlines a potential roadmap for its validation through a Proof of Concept (PoC) and lists several areas for future enhancements and evolution of the AI Loyalty Maximizer Suite.

## 9.1. Potential Proof of Concept (PoC)

Before a full-scale implementation, a focused Proof of Concept (PoC) is crucial to validate core technical assumptions, test key integrations, and demonstrate a tangible slice of the AI Loyalty Maximizer Suite's capabilities. This PoC will center on the American Airlines AAdvantage program, focusing on its Loyalty Point and redeemable mile earning structure.

**PoC Objectives:**

* Validate the system's ability to extract relevant flight and fare details from a user-provided itinerary (e.g., uploaded text or simple structured format).
* Demonstrate the accurate calculation of AAdvantage Loyalty Points and redeemable miles for flights on American Airlines and select key Oneworld partners (e.g., British Airways, Qatar Airways) when credited to AAdvantage, considering the user's elite status.
* Test the core GraphRAG pattern: retrieving specific AAdvantage earning rules (including revenue-based for AA-marketed flights and distance/fare-class based for partners) from a minimal Amazon Neptune graph to provide context to an Amazon Bedrock LLM or calculation logic.
* Verify the deployment and interaction of core serverless components (e.g., simplified API, Lambda for orchestration/tool, Neptune, Bedrock).
* Provide insights into the practicalities of modeling AAdvantage partner earning rules in the knowledge graph.

**Suggested PoC Scope:**

* **Use Case:** Calculate AAdvantage Loyalty Point and redeemable mile earnings for a user-uploaded flight itinerary. The user will also specify their current AAdvantage elite status level. The PoC will initially handle itineraries one at a time.
* **Target Program:** American Airlines AAdvantage.
* **Key Components to Implement (Simplified):**
    * **Input Mechanism:** A simple interface (e.g., basic web form for text paste or file upload of an itinerary, plus a dropdown for AAdvantage status selection).
    * **`Conversational API` (Simplified):** An Amazon API Gateway endpoint invoking a single AWS Lambda function to handle the input.
    * **`LLM Orchestration Service` & Itinerary Parsing (Simplified):**
        * The Lambda function will manage the PoC flow.
        * It will pass the itinerary content to an **Amazon Bedrock LLM** with a prompt designed to extract key details: marketing carrier(s), operating carrier(s), flight numbers, origin/destination airports, fare class(es), and crucial ticket price components (base fare, carrier-imposed surcharges, especially for AA-marketed flights).
        * Alternatively, for a very constrained PoC, a simpler non-LLM parser could be attempted if the itinerary format is fixed, but LLM extraction is preferred to test that capability.
    * **`Knowledge Base Service (GraphRAG)` (Minimal):**
        * A small Amazon Neptune cluster.
        * Manually populated with graph data for:
            * American Airlines (AA) and select partners (e.g., British Airways (BA), Qatar Airways (QR)).
            * The AAdvantage Loyalty Program.
            * Relevant airports with geographic coordinates.
            * Fare class mappings (especially for partner airlines).
            * AAdvantage `EarningRule` nodes detailing:
                * Loyalty Point and redeemable mile earning rates for AA-marketed/operated flights (based on fare, status).
                * Loyalty Point and redeemable mile earning rates for selected partner flights (BA, QR) when credited to AAdvantage (based on distance, fare class, status).
            * AAdvantage elite status levels and their associated earning bonuses.
    * **`calculate_flight_earnings` MCP Tool (Adapted for AA PoC):** An AWS Lambda function that:
        * Receives extracted itinerary details and user's AAdvantage status.
        * Queries the minimal Neptune graph for airport coordinates (to calculate distances for partner flights) and the relevant AAdvantage earning rules (for AA and selected partners).
        * Applies the correct AAdvantage earning logic (revenue-based for AA, distance/fare-based for partners) and status bonuses.
        * Returns structured results (Loyalty Points earned, redeemable miles earned).
    * **Output:** Display the calculated earnings to the user.

* **Data Focus for PoC:** Ingesting (manually for the PoC graph) the specific earning rates for American Airlines itself and for crediting flights from at least two key Oneworld partners (e.g., British Airways, Qatar Airways) to the AAdvantage program. This includes how different fare classes on these partners earn Loyalty Points and redeemable miles in AAdvantage.
* **Success Criteria:**
    * Ability to successfully upload or input a sample itinerary for AA, BA, or QR.
    * System correctly extracts key flight and fare information using the LLM.
    * System correctly applies AAdvantage earning rules (including status bonuses and partner-specific rates) based on data retrieved from the Neptune graph.
    * System accurately calculates and displays the expected Loyalty Points and redeemable miles.

This focused PoC provides a robust test of core functionalities with a popular, complex loyalty program, offering significant learning and a compelling demonstration of the proposed architecture's capabilities, especially the synergy between LLM-based information extraction and GraphRAG for rule application.


## 9.2. Future Enhancements

The current architecture provides a strong foundation. Several areas could be enhanced in future iterations to expand the capabilities, user experience, and operational sophistication of the AI Loyalty Maximizer Suite:

**A. Enhanced AI & Agentic Capabilities:**
* **Sophisticated Dialogue Management:** Implement more advanced conversational state tracking and multi-turn dialogue capabilities for more natural and context-aware user interactions.
* **Proactive Agents:** Develop agents that can proactively monitor for information and alert users, such as:
    * *Award Deal Monitoring Agent:* Scans for exceptional award availability or fare deals based on user preferences or general opportunities.
    * *Profile Optimization Agent:* Periodically reviews user goals and suggests actions (e.g., strategic flights for status, new card offers if relevant data is available).
* **Increased Agent Autonomy:** Conceptually explore agents with more complex planning and execution capabilities for multi-step tasks based on user delegation (with appropriate safeguards).

**B. Expanded Knowledge Base & Data Ingestion:**
* **Broader Program Coverage:** Incrementally add more airlines, loyalty programs, alliances, and specific rules to the knowledge graph.
* **Advanced Data Extraction:** Further refine LLM prompts and techniques in the ingestion pipeline to handle even more diverse and complex source document formats with higher accuracy. Explore fine-tuning specialized models for specific extraction tasks.
* **Change Detection & Automated Source Monitoring:** Develop mechanisms to detect changes in previously processed source URLs to trigger re-ingestion (beyond just new file uploads).
* **Advanced Rule Versioning:** Implement more sophisticated versioning and lifecycle management for rules within the knowledge graph, allowing for historical queries and clear tracking of changes.

**C. Model Fine-Tuning & Customization (PyTorch/TensorFlow on Amazon SageMaker):**
* **Domain-Specific Language Understanding:** Fine-tune an LLM on a curated corpus of airline loyalty and travel content to improve its nuanced understanding of industry jargon and complex queries.
* **Optimized Information Extraction Models:** For particularly challenging or high-volume document types in the ingestion pipeline, develop or fine-tune specialized models (e.g., using transformer architectures with PyTorch/TensorFlow) for information extraction.
* **Task-Specific Agent Optimization:** For certain well-defined, high-volume internal tasks (e.g., intent classification, tool routing), fine-tuned smaller models might offer performance or cost benefits.

**D. User Experience & Interface:**
* **Rich Web Application / Mobile Application:** Develop dedicated, feature-rich front-end applications for a more polished user experience beyond a basic conversational interface.
* **Advanced Data Visualization:** Implement dashboards and visualizations to help users understand their rewards, potential earnings, **and comparative analysis of different travel or crediting options (such as the tabular breakdown for multi-itinerary earnings).**
* **Full User Account Management:** Securely manage user accounts, including options for users to directly input and track all their loyalty balances, link accounts (if APIs ever become available), and set detailed goals. This would likely involve a relational database like Amazon Aurora for transactional aspects.

**E. Broader Feature Set:**
* **Integration with real-time dynamic award pricing data sources** (acknowledging the significant challenges: API availability, cost, reliability for conceptual awards).
* **Multi-Itinerary Earnings Comparison:**
    * Allow users to submit multiple potential flight itineraries.
    * Provide a comparative analysis, potentially in a tabular format, showing the calculated redeemable rewards and elite-qualifying metrics for each itinerary across selected loyalty programs.
    * This could highlight the pros and cons of each option in terms of rewards accrual and progress towards status, potentially as a premium feature.
* **Deeper Personalization:** Utilize user interaction history and preferences more deeply to tailor advice and suggestions.
* **Community & Sharing Features (Conceptual):** Allow users to (anonymously or with consent) share successful redemption strategies or mileage run ideas.

**F. Operational Excellence & Advanced Cloud Features:**
* **Advanced DR Strategies:** Implement and regularly test more advanced DR strategies like Pilot Light or Warm Standby in a secondary AWS Region.
* **Global Distribution:** For a geographically dispersed user base, consider Amazon CloudFront for API caching/delivery, DynamoDB Global Tables for user profiles, and potentially Neptune Global Database (if available and warranted).
* **Comprehensive Caching Strategies:** Implement caching layers (e.g., Amazon ElastiCache for Redis/Memcached, DAX for DynamoDB) for frequently accessed, relatively static data to improve performance and reduce backend load.
* **Advanced Security Measures:** Full implementation and tuning of Amazon GuardDuty, AWS Security Hub, AWS Network Firewall, and advanced AWS WAF rules.
* **Cost Optimization Maturity:** Implement advanced cost management practices, including Savings Plans, Reserved Instances for stable workloads (e.g., Neptune, core compute), and continuous cost monitoring and refinement.

**G. Integration with External Systems:**
* **Calendar Integration:** Allow users to link their travel plans with their calendars.
* **(Highly Conceptual/Future) Direct Booking Capabilities:** If airline APIs or GDS (Global Distribution System) access ever became feasible and permissible, explore integrations for direct award searches or even assisted bookings.

This roadmap highlights the potential for significant growth and sophistication, building upon the core architectural foundation detailed in this document.

---
*This page is part of the AI Loyalty Maximizer Suite - AWS Reference Architecture. For overall context, please see the [Architecture Overview](./00_ARCHITECTURE_OVERVIEW.md) or the main [README.md](../README.md) of this repository.*

---
**Previous:** [8. Operational Considerations](./08_OPERATIONAL_CONSIDERATIONS.md)
**Next:** [10. Open Questions & Challenges](./10_OPEN_QUESTIONS_CHALLENGES.md)