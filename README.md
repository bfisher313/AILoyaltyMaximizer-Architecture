# AI Loyalty Maximizer Suite - AWS Reference Architecture

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

## Overview

Welcome to the **AI Loyalty Maximizer Suite** repository! This project presents a comprehensive reference architecture for a conceptual, AI-first application designed for airline travel enthusiasts. The suite aims to provide intelligent, conversational assistance for:

1.  **Award Travel Optimization:** Helping users find the best ways to redeem their rewards currency (miles/points) for flights.
2.  **Revenue Flight Earnings Calculation & Crediting Advisor:** Assisting users in calculating the rewards (miles/points) and elite-qualifying metrics they will earn from paid flights, and advising on the optimal frequent flyer program for crediting.

## Purpose

This repository serves as a **portfolio piece and a detailed architectural blueprint**, showcasing the design of a sophisticated, cloud-native application built primarily on Amazon Web Services (AWS) managed services. It demonstrates advanced concepts in AI application development, solution architecture, and cloud engineering.

The focus is on the architectural design, decision-making processes, and integration of modern technologies to solve a complex, real-world-inspired problem.

## Key Features & Technologies Showcased

* **Artificial Intelligence (AI):** Core of the solution.
* **Large Language Models (LLMs):** Serving as the primary orchestrator for user interaction and tool invocation (e.g., leveraging models via Amazon Bedrock).
* **Model Context Protocol (MCP):** Conceptual framework for LLMs to interact with specialized tools and agents.
* **GraphRAG (Retrieval Augmented Generation with Knowledge Graphs):** Utilizing graph databases (e.g., Amazon Neptune) combined with RAG techniques for accessing and reasoning over complex airline loyalty data.
* **Serverless Architecture:** Prioritizing AWS Lambda, API Gateway, Step Functions, DynamoDB, and S3 for scalability and cost-effectiveness.
* **Cloud-Native on AWS:** Deep integration with a wide array of AWS managed services.
* **Comprehensive Architectural Design:** Including C4 modeling for software views, supplemented by enterprise architectural perspectives (Process, Physical/Deployment, Development).
* **DevOps & Infrastructure as Code (IaC):** Considerations for CI/CD pipelines and managing infrastructure programmatically (e.g., AWS CDK/CloudFormation).

## Architectural Approach

The architecture detailed herein utilizes the **C4 model** (Context, Containers, Components) for its clarity in depicting software structure. This is augmented by broader **enterprise architectural views**—including Process, Physical (Deployment), and Development perspectives—to provide a holistic understanding suitable for complex, scalable systems. This multi-view approach ensures all key concerns, from high-level business drivers to detailed AWS service implementation, are addressed.

---

**(Optional: Consider embedding a high-level System Context Diagram here once created)**
*A high-level System Context diagram illustrating the AI Loyalty Maximizer Suite and its key interactions can be found [here](./diagrams/system_context_c4_high_level.png) (once created).*

---

## Navigating This Repository

The complete architectural documentation is extensive and organized into several files for clarity.

* **Full Architectural Documentation:**
    * The primary, detailed architectural specification can be found in:
        * [`/docs/ARCHITECTURE.md`](./docs/ARCHITECTURE.md) (This will be the main entry point that strings together or links to all other documentation sections).
    * *Alternatively, if you break it down further:*
        * Introduction: [`/docs/01_INTRODUCTION.md`](./docs/01_INTRODUCTION.md)
        * Business Context: [`/docs/02_BUSINESS_CONTEXT_AND_REQUIREMENTS.md`](./docs/02_BUSINESS_CONTEXT_AND_REQUIREMENTS.md)
        * ... and so on for all sections as per our agreed structure.
* **Architectural Diagrams:**
    * All diagrams (C4, AWS deployment, data flows, etc.) are located in the [`/diagrams`](./diagrams) directory.
* **Architecture Decision Records (ADRs):**
    * Key design decisions and their rationale are documented in the [`/adr`](./adr) directory.

## Author

* **[Your Name]**
    * GitHub: `https://github.com/[Your GitHub Username]`
    * LinkedIn: `[Your LinkedIn Profile URL (Optional)]`

## Disclaimer

This is a conceptual portfolio project. The architecture and features described are for demonstration purposes and to showcase design thinking. While inspired by real-world airline loyalty programs, the data models and rules presented are illustrative. Any resemblance to specific, proprietary airline systems or data is coincidental.

## Contributing (Optional)

As this is primarily a personal portfolio project, contributions are not actively sought at this time. However, feedback and suggestions are always welcome via Issues or direct contact.

## License (Optional)

This project is licensed under the MIT License - see the `LICENSE` file for details.
*(Create a `LICENSE` file in your repo if you choose to include this. MIT is a common permissive license.)*
