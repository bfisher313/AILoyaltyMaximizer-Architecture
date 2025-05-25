workspace "AI Loyalty Maximizer Suite Architecture" "A model of the AI Loyalty Maximizer Suite and its containers." {

    model {
        # Define People (External Users)
        userTE = person "Travel Enthusiast" "Primary end-user querying the suite for advice and alerts." "User Persona"
        userDC = person "Data Curator" "Administrative user responsible for gathering and submitting source information." "User Persona"

        # Define External Software Systems
        extRawData = softwareSystem "Manually Collected Web Pages (S3 Raw Bucket)" "External S3 bucket acting as the input source for raw data (HTML, PDF, text files) gathered by the Data Curator." "External System"
        extNotificationDelivery = softwareSystem "Notification Delivery Service" "External infrastructure (e.g., Email, SMS gateways) used to dispatch notifications to users." "External System"

        # Define Our Software System
        alms = softwareSystem "AI Loyalty Maximizer Suite" "Provides AI-driven insights, calculations, and advice related to airline loyalty programs." {
            # Define Containers within the AI Loyalty Maximizer Suite
            convAPI = container "Conversational API" "Primary entry point for user interactions. Exposes a secure API, handles incoming queries, routes them, and returns responses." "Amazon API Gateway, AWS Lambda"
            llmOrchestrator = container "LLM Orchestration Service" "The 'brain' of the system (Primary Reasoning Agent). Interprets user intent, invokes MCP Tools (Specialized Agents), manages state, and synthesizes responses." "Amazon Bedrock, AWS Step Functions, AWS Lambda" "Primary Reasoning Agent"
            userProfileSvc = container "User Profile Service" "Manages user-specific data (loyalty programs, status, preferences, saved items)." "Amazon DynamoDB, AWS Lambda"
            knowledgeBaseSvc = container "Knowledge Base Service (GraphRAG)" "Provides access to the structured knowledge graph and implements RAG logic." "Amazon Neptune, Amazon S3 (RAG docs), AWS Lambda"
            dataIngestionSvc = container "Data Ingestion Pipeline Service" "Orchestrated services for processing gathered web pages and populating the Knowledge Base Service. Employs Data Processing Agents." "Amazon S3 (staging), AWS Lambda, Amazon Textract, AWS Glue, AWS Step Functions" "Data Processing Agents"
            notificationSvc = container "Notification Service" "Manages and sends out notifications/alerts to users." "Amazon SNS, AWS Lambda"

            # Define relationships between containers
            convAPI -> llmOrchestrator "Forwards User Queries/Commands" "HTTPS/JSON API"
            llmOrchestrator -> userProfileSvc "Gets/Updates User Data via Tools" "Internal API Call"
            llmOrchestrator -> knowledgeBaseSvc "Gets Loyalty Data via RAG Tools" "Internal API Call"
            llmOrchestrator -> convAPI "Returns Synthesized Responses/Actions" "Internal"
            llmOrchestrator -> notificationSvc "Triggers Notifications" "Internal Event/Call"

            dataIngestionSvc -> knowledgeBaseSvc "Updates/Populates Knowledge Graph" "Neptune Bulk Load / Gremlin"
        }

        # Define relationships involving people and external systems
        userTE -> convAPI "Sends Queries/Commands via Client App" "HTTPS/JSON API"
        convAPI -> userTE "Delivers Advice/Alerts to Client App" "HTTPS/JSON API"
        userDC -> extRawData "Manually Gathers & Submits Pages" "File Upload"

        extRawData -> dataIngestionSvc "Source For Data Ingestion Pipeline" "S3 Read Access"
        notificationSvc -> extNotificationDelivery "Sends Processed Notifications To" "API Call (e.g., SMTP, SMS API)"
    }

    views {
        # System Context Diagram
        systemContext alms "SystemContext" "The System Context diagram for the AI Loyalty Maximizer Suite." {
            include *
            autolayout lr
        }

        # Container Diagram for AI Loyalty Maximizer Suite
        container alms "Containers" "The Container diagram for the AI Loyalty Maximizer Suite." {
            include *
            autolayout tb
        }

        styles {
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "External System" {
                background #999999
                color #ffffff
            }
            element "User Persona" {
                shape Person
                background #90ee90
                color #000000
            }
            element "Primary Reasoning Agent" {
                shape Hexagon
            }
            element "Data Processing Agents" {
                shape Hexagon
            }
        }

        theme default
    }
}