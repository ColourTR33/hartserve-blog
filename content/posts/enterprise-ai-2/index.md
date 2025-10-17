---
title: "Enterprise AI Design Patterns: A Field Guide for Architects"
date: 2025-08-30
draft: false
tags: ["RAG", "LLMOps", "Security", "Token Optimization", "Architecture", "AI"]
categories: [architecture]
description: "Practical patterns for enterprise AI: RAG, cost control, security, LLMOps, and change management—with templates and pitfalls."
keywords: ["RAG", "LLMOps", "Security", "Token Optimization", "Architecture"]
cover:
  image: "hero.jpg"     # add hero.jpg next to index.md
  alt: "Enterprise AI Design Patterns"
  caption: "Enterprise architecture - doing the heavy lifting."
  relative: true
showToc: true
series: ["Enterprise AI Design Patterns"]
weight: 2 # 2, 3 for next parts

---
# Enterprise AI Design Patterns

## Executive Summary
Generative AI is not just another software deployment; it is the integration of a non-deterministic, reasoning workforce into existing business processes. Success hinges on more than technical acumen. It requires a strategic approach to grounding models in enterprise data (Context), managing their unpredictable nature, optimizing for cost (Tokens), and securing the new interfaces they create. This series of posts guides architects in navigating these complexities to deliver tangible business value.

## AI Functions & Applications
 - Part 1 - Foundational AI Concepts
 **- Part 2: Architectural Patterns & Implementation**
 - Part 3: Enterprise-Grade Considerations

## Part 2: Architectural Patterns & Implementation
### RAG: Grounding AI in Enterprise Reality
**Retrieval-Augmented Generation (RAG)** is the single most important architectural pattern for enterprise AI. It allows LLMs to answer questions based on specific, private company data without needing to be retrained. It works like an "open-book exam" for the AI and makes the difference between faithfulness and relevancy to help avoid hallucinated synthesis.

##### How to Implement RAG:
1. **Ingestion & Chunking:** Source documents (PDFs, docs, web pages) are broken down into smaller, manageable chunks of text.

2. **Embedding & Indexing:** Each chunk is converted into a numerical representation (an embedding) using an embedding model. These embeddings are stored in a specialized Vector Database. The embedding captures the semantic meaning of the text.

3. **Retrieval:** When a user asks a query, the query is also converted into an embedding. The system then searches the vector database for the text chunks with the most similar embeddings (i.e., the most relevant information).

4. **Augmentation & Generation:** The retrieved text chunks (the Context) are inserted into a prompt along with the user's original Query. This complete prompt is sent to the LLM, which generates an answer based only on the provided information.

##### Considerations:

 - **Chunking Strategy:** The size and overlap of chunks dramatically affect retrieval quality. Too small, and you lose context; too large, and you introduce noise.

 - **Vector Database Selection:** Choose a database that can handle the client's scale and security requirements (e.g., Pinecone, Weaviate, or managed services from cloud providers).

 - **Retrieval Quality:** The success of RAG depends almost entirely on retrieving the right context. Use hybrid search (keyword + semantic) and re-ranking models to improve relevance.

 - **Data Freshness:** Implement a process to keep the vector database in sync with the source documents.

**RAG Go-Live Checklist**

  - Chunk size & overlap tuned with evaluation set

  - Hybrid search (BM25 + vector)

  - Reranker or MMR configured

  - Retrieval filtered by user ACL

  - Prompt window budgeted (context + system + user)

  - Eval: answer faithfulness & context coverage

  - Redaction filter: PII/PCI before display

### Strategic Token Optimisation
Optimising token usage can cut costs by 2-300%, however, it is not just about saving money; it's about improving latency and response quality.

#### Quality Prompts (Prompt Engineering):

 - **Be Concise and Specific:** Remove filler words. Use clear, unambiguous language.

 - **Few-Shot Prompting:** Provide 2-3 examples of the desired input and output format within the prompt. This guides the model better than a lengthy explanation.

#### Pre-formatting and Pre-processing:

Don't send raw data to the model. Clean and summarize context before inserting it into the prompt. Remove HTML tags, boilerplate text, and irrelevant sections.

#### Design Pattern: LLM Cascade:

Use a chain of models for complex tasks. A cheaper, faster model (e.g., Gemini Flash, GPT-3.5 Turbo) can perform initial classification, routing, or summarization. If the task is complex, it can be escalated to a more powerful, expensive model (e.g., Gemini Advanced, GPT-4).

#### Record Token Usage:

**Centralized API Gateway:** Route all AI calls through a central gateway. This is the ideal place to log every request and response.

**Logging Metadata:** For each call, log the timestamp, user/role ID, application name, model used, prompt tokens, completion tokens, and total tokens.

**Dashboarding:** Feed this data into a monitoring dashboard (e.g., Datadog, Grafana) to visualize costs by user, department, and application. This is critical for chargeback models and identifying misuse.

### Managing Long-Term Memory: Context Save Points

An LLM's context window is finite. In a long conversation, early information is forgotten. "Context save points" are a pattern to overcome this.

**How it Works:** After a few conversational turns, use an LLM to create a concise summary of the conversation so far.

**Implementation:** In the next turn, instead of including the full, verbose chat history in the prompt, include only the summary of the previous turns plus the most recent 1-2 exchanges. This keeps the "memory" of the conversation alive without exceeding the token limit.

**Use Cases:** Essential for multi-turn conversational agents, chatbots, and co-pilots that assist with complex, multi-step tasks.
