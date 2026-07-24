# The Sentinel Principle — Thesis

**Status:** Draft, chapters 1–7
**Companion to:** [CONOPS.md](./CONOPS.md), [THEORY.md](./THEORY.md), [decisions/](./decisions/)

> Public document. Framework and theory only.

---

## Chapter 1 — Introduction

There is a paradox at the heart of the information age. Never before has humanity possessed greater capacity to collect, transmit, and process information, yet confidence in the integrity of that information appears to be declining. Artificial intelligence systems generate convincing falsehoods with remarkable fluency. Identity fraud continues to increase despite increasingly sophisticated cryptographic mechanisms. Scientific research faces a reproducibility crisis. Organizations struggle to determine which version of information should be regarded as authoritative. Even within highly regulated industries, decisions are frequently made from stale, incomplete, or contradictory data.

These problems are often treated as unrelated. Artificial intelligence researchers investigate hallucinations. Cybersecurity professionals focus on authentication and authorization. Philosophers debate epistemology. Database architects concern themselves with consistency, while systems engineers study resilience and fault tolerance. Each discipline has developed increasingly sophisticated solutions within its own domain.

This thesis begins with a different assumption. It proposes that these diverse failures share a common architectural origin. They are not primarily failures of artificial intelligence, cryptography, governance, or human judgment. They are failures of **epistemic governance**: failures to preserve the integrity of knowledge as information moves from one form to another.

Information rarely exists in a single immutable state. It is continuously transformed. Physical events become observations. Observations become representations. Representations become assertions. Assertions accumulate into knowledge. Knowledge informs decisions, and decisions ultimately shape action in the physical world. Each transformation changes not merely the format of the information, but its epistemic status. A photograph is not a measurement. A measurement is not an assertion. An assertion is not evidence. Evidence is not knowledge. Yet modern information systems routinely promote information across these boundaries with little explicit governance over what has been gained, lost, inferred, or assumed during the transition.

This work argues that the critical problem is not uncertainty itself. Every complex system must operate under uncertainty. Rather, the problem is that uncertainty is often allowed to propagate invisibly. Inferences become treated as observations. Assumptions become stored as facts. Statistical confidence becomes mistaken for truth. The distinction between what was observed, what was inferred, and what was merely predicted gradually disappears until downstream decision-makers can no longer distinguish evidence from interpretation.

The central contribution of this thesis is a theoretical framework for governing these transformations. Rather than treating trust as an intrinsic property of information, or as a subjective confidence held by an observer, this work proposes that trust emerges from accountable governance over transitions between epistemic states. Whenever information crosses a boundary that changes its epistemic status, an independent mechanism should determine whether sufficient integrity has been preserved before that information is permitted to influence downstream reasoning or consequential action. This architectural pattern is referred to throughout this thesis as the **Sentinel Principle**.

Although the Sentinel Principle emerged from practical work in digital identity and verifiable trust systems, it is not limited to those domains. The same pattern appears repeatedly across disciplines. Constitutional governments separate legislative, executive, and judicial authority to prevent unchecked promotion of political power. Scientific communities require independent replication before observations become accepted knowledge. Financial systems employ auditors who do not generate transactions but instead govern their integrity. Safety-critical engineering relies upon redundant monitoring systems that independently verify the state of aircraft, power plants, and medical devices. Even biological organisms employ immune systems that continually evaluate whether observed signals should be incorporated into the organism's internal model of reality.

These systems differ in implementation, but they share a common architectural principle. None assumes that information becomes trustworthy merely because it exists. Each inserts an independent mechanism whose purpose is to govern whether information has earned the right to influence subsequent decisions.

The chapters that follow develop this principle systematically. The discussion begins by examining existing work in ontology, graph theory, distributed trust, cybernetics, event sourcing, and epistemology. It then develops an ontology of trust founded upon five primitive types and immutable assertions before introducing the Binding Problem, which identifies the boundary at which physical reality first enters digital representation. From that foundation, the Sentinel Principle is derived as a general mechanism for preserving epistemic integrity across transformational boundaries. Finally, the theory is applied to contemporary problems in artificial intelligence, digital identity, and distributed governance to demonstrate that these apparently distinct domains are manifestations of the same underlying architectural challenge.

The claim advanced by this thesis is intentionally ambitious. It is not that a new security mechanism has been discovered, nor that a new identity architecture has been devised. Rather, it is that trustworthy systems — whether biological, institutional, computational, or social — share a common structural requirement. They must govern the transformation of knowledge itself.

---

## Chapter 2 — Knowledge as Structure

The central argument of this thesis rests upon an assumption that is so deeply embedded within modern information systems that it is rarely examined directly. We tend to think of knowledge as something that can be stored. Databases store knowledge. Documents contain knowledge. Artificial intelligence models are often described as repositories of knowledge distilled from enormous collections of text. Even everyday language reflects this intuition; we speak of "capturing" knowledge, "retrieving" knowledge, or "transferring" knowledge from one person or system to another.

This intuition is useful, but it is incomplete. Information may be stored, transmitted, copied, compressed, encrypted, or deleted. Knowledge behaves differently. Knowledge emerges through relationships between information, evidence, authority, and context. Remove any one of these elements and the informational content may remain unchanged while its epistemic meaning changes dramatically.

Consider the sentence, *Sarah is employed by Acme Corporation.* The sequence of words is perfectly intelligible in isolation. Yet virtually every question that determines whether the sentence should influence a consequential decision lies outside the sentence itself. Who made the claim? When was it made? Under what authority? Does it remain current? Has it been revoked? Is the speaker reporting the claim, disputing it, or merely repeating something they heard? None of these questions alter the syntax of the sentence, yet each fundamentally alters its meaning as evidence.

This distinction between information and knowledge has occupied philosophers for centuries. Classical epistemology has traditionally asked what conditions transform belief into knowledge. Information science has instead focused on how representations may be stored and communicated efficiently. Computer science has largely concentrated on algorithms capable of manipulating those representations. Although these traditions frequently intersect, they often begin from different assumptions regarding what information fundamentally is.

For the purposes of this thesis, knowledge will not be treated as an object that exists independently within a database or document. Instead, **knowledge will be understood as a structured relationship between an assertion and the conditions under which that assertion may justifiably influence action.** This definition shifts attention away from the informational artifact itself toward the processes through which information acquires, maintains, or loses epistemic legitimacy.

Once knowledge is understood relationally rather than atomically, an important consequence follows. The primary architectural problem is no longer storage. It is governance.

Traditional information systems excel at preserving bits. Cryptographic hash functions, distributed consensus algorithms, append-only logs, and error-correcting codes provide increasingly sophisticated mechanisms for ensuring that digital representations remain internally consistent. These technologies answer questions such as whether a document has been altered, whether a message originated from a particular cryptographic key, or whether a sequence of events occurred in a particular order.

They do not answer whether the information deserves to be believed.

The distinction is subtle but profound. **Cryptography governs integrity. It does not govern epistemology.**

This observation appears repeatedly across seemingly unrelated disciplines. A scientific journal may preserve experimental data perfectly while publishing conclusions that later prove irreproducible. A blockchain may permanently record a fraudulent transaction without possessing any mechanism for determining whether the underlying real-world event actually occurred. An artificial intelligence system may produce grammatically flawless explanations whose supporting evidence cannot be recovered. In each case, the computational architecture succeeds while the epistemic architecture fails.

The common failure is not technological. It is structural. The system lacks explicit mechanisms governing how information changes epistemic status.

Understanding this requires abandoning another deeply rooted assumption inherited from traditional database theory. Most operational systems are designed around current state. The present value stored within the system is implicitly treated as authoritative. History, if retained at all, occupies a secondary role in audit tables, transaction logs, or archival storage.

Such systems perform admirably for operational efficiency, yet they obscure the distinction between observation and interpretation. A record stating that an employee is currently active reveals nothing about the sequence of assertions through which that state emerged. It conceals disagreement, revision, uncertainty, and authority beneath the appearance of a single objective fact.

The alternative explored throughout this thesis begins with a different premise. Rather than treating state as the primary representation of knowledge, it treats **assertions** as the fundamental epistemic artifact. State becomes a continuously reconstructed view derived from a history of accountable assertions. Knowledge therefore acquires temporal depth. Every conclusion becomes traceable to a sequence of identifiable acts of observation, interpretation, correction, and authorization.

This shift has important consequences for how complex systems should be designed. If assertions rather than state become the fundamental unit of knowledge, then the relationships connecting assertions become at least as significant as the assertions themselves. Knowledge is no longer represented as isolated facts but as an evolving network of claims, evidence, authority, and consequence. The resulting structure is naturally understood as a graph rather than as a collection of independent records.

The importance of this observation extends beyond data modeling. Graphs possess properties that tables cannot express naturally. They preserve context without duplication, accommodate multiple simultaneous perspectives, and represent competing or contradictory assertions without requiring immediate reconciliation. More importantly, they reveal that meaning frequently resides not within isolated nodes but within the relationships connecting them.

This insight serves as the conceptual bridge to the ontology developed in the following chapter. Before knowledge can be governed, the architecture must first specify what kinds of things may exist, how those things relate to one another, and what constitutes a legitimate claim regarding those relationships. Only after these foundations have been established does it become possible to ask the central question of this thesis:

**How should those claims be governed as they acquire epistemic authority?**

---

## Chapter 3 — An Ontology of Trust

Every scientific discipline begins by identifying its primitives. Physics distinguishes matter from energy. Chemistry distinguishes elements from compounds. Biology distinguishes organisms from ecosystems. These distinctions are not merely classificatory conveniences; they establish the irreducible concepts upon which all higher-order reasoning depends.

Trust systems require a similar foundation. Before discussing governance, verification, or authority, it is necessary to establish what kinds of things exist within a trust architecture. Without such an ontology, concepts such as identity, credentials, authorization, and reputation remain domain-specific abstractions whose meanings shift across implementations. The objective of this chapter is therefore not to define a particular technology or standard, but to identify the minimum set of primitive concepts necessary to describe trust as a general phenomenon.

The distinction between primitives and derived concepts is fundamental. A primitive cannot be decomposed into simpler concepts within the model itself. Derived concepts emerge through combinations of primitives and their relationships. An ontology succeeds not by maximizing the number of primitive types, but by identifying the smallest set capable of expressing every higher-order construct encountered within the domain.

This thesis proposes five such primitives.

**The Person.** A person is a human individual capable of agency, consent, accountability, and intentional action. Persons are unique among the primitives because they possess moral and legal standing independent of the systems that describe them. A person's digital identity is not the person. It is a representation of the person. Confusing these two has been the source of considerable architectural and ethical error throughout the history of digital identity systems.

**The Entity.** Entities are organizations, institutions, corporations, governments, and other legal constructs capable of exercising authority beyond the lifetime of any individual participant. Unlike persons, entities persist through changing membership. They issue policies, hold assets, enter contracts, and assume institutional responsibility. Most assertions within society ultimately derive their authority from an entity rather than from an individual acting alone.

**The System.** Systems are computational actors capable of producing, storing, transmitting, or evaluating information. Modern trust architectures increasingly rely upon systems as active participants rather than passive repositories. Identity providers, certification authorities, autonomous agents, sensors, and language models all function as systems within the ontology. Their importance lies not in their computational complexity but in their capacity to originate or transform assertions.

**The Process.** Processes represent governed sequences of activity through which trust is established, maintained, or revoked. Identity proofing, background investigations, credential issuance, software deployment, peer review, and elections are all examples of processes. Unlike systems, which execute operations, processes define the normative rules under which those operations acquire legitimacy. A trustworthy outcome cannot be understood independently of the process that produced it.

At this point, many ontologies would appear complete. Persons interact with entities through systems operating under defined processes. For many practical applications this is sufficient. It is also incomplete.

The incompleteness becomes apparent when attempting to describe even the simplest trust claim.

Consider the statement, *Sarah works for Acme Corporation.*

A person exists. An entity exists. Both may be independently verified. Yet neither contains the essential meaning of the statement. Sarah is not intrinsically employed. Acme is not intrinsically an employer of Sarah. Employment exists only as a structured connection between them. It possesses a beginning, an end, an issuer, conditions of validity, mechanisms of revocation, and evidentiary support. Remove either endpoint and the relationship ceases to exist, yet the relationship cannot be reduced to either endpoint.

This observation motivates the fifth primitive.

**The Relationship** is not metadata attached to two objects. It is itself an independently governable object possessing its own lifecycle, authority, and evidentiary requirements. Relationships begin, evolve, expire, and terminate independently of the nodes they connect. They may be asserted, challenged, superseded, revoked, or delegated. They possess schemas, invariants, and provenance no less significant than those of the entities they connect.

Recognizing relationships as primitives represents a departure from conventional information architecture. Relational databases treat relationships primarily as implementation artifacts — foreign keys, association tables, or join operations. Knowledge graphs improve this representation by elevating edges to first-class constructs, yet many practical implementations continue to regard relationships as derived consequences of node existence rather than as independently governed objects.

Trust systems cannot afford this simplification.

Nearly every consequential question encountered within society concerns relationships rather than isolated objects. Is this physician licensed to practice? Is this employee authorized to access classified information? Is this software system certified to process financial transactions? Has this laboratory been accredited to perform forensic analysis? None of these questions concern intrinsic properties. Each concerns a relationship established under particular authority, for a particular purpose, within a bounded period of time.

Once relationships are recognized as primitive, the architecture itself changes. **Identity becomes topology rather than attribute. Authority becomes path rather than possession. Provenance becomes traversable.** Trust is no longer represented by isolated records but by an interconnected structure whose meaning emerges from the organization of its relationships.

This shift has profound implications. Traditional systems ask whether an object possesses a property. A graph-oriented trust architecture instead asks whether a valid path exists connecting a subject, an authority, supporting evidence, governing process, and intended decision. The unit of reasoning ceases to be the individual record. It becomes the graph itself.

The ontology developed here therefore consists of five primitive types: **Person, Entity, System, Process, and Relationship.** Together they define what may exist within the architecture. They do not yet explain how information enters that architecture, how conflicting claims are represented, or how authority is established.

Every relationship, every credential, every authorization, and every claim must first be asserted.

---

## Chapter 4 — The Assertion Principle

The ontology developed in the previous chapter identifies the kinds of things that may exist within a trust architecture. Yet an ontology alone remains static. It specifies what may exist without explaining how the graph comes to contain information in the first place.

This distinction is easily overlooked because conventional information systems largely conceal the process through which information enters the system. A database simply contains records. An employee appears in a personnel system. A physician appears in a licensing registry. Attention naturally shifts toward the current contents of the database rather than toward the historical sequence of events that produced those contents.

For operational systems, this abstraction is often desirable. Current state is efficient. Payroll software needs to know whether an employee is active today. Access control systems need to know whether authorization currently exists.

Trust systems operate under fundamentally different requirements.

Trust depends not only upon what is currently believed but upon why it is believed, who established that belief, under what authority, through what process, and whether that belief has subsequently been challenged, corrected, or revoked. These questions cannot be answered by examining current state alone. They require access to the history through which current state emerged.

The object of preservation is therefore not state itself, but the assertions from which state is continuously reconstructed. This leads to the **Assertion Principle**:

> Truth within a trust architecture is not represented by mutable state. It is represented by immutable assertions made by accountable actors at identifiable points in time.

The principle intentionally distinguishes truth from correctness. Assertions may ultimately prove accurate or inaccurate. They may later be superseded or contradicted. None of these possibilities alters the fact that the assertion itself occurred. An assertion is therefore best understood as an **event** rather than as a property of an object.

This perspective aligns naturally with event-sourced architectures, in which the authoritative representation of a system consists not of current values but of an append-only sequence of events from which current state may be reconstructed. The contribution of this thesis is to extend that architectural pattern beyond software engineering into the governance of trust itself.

An assertion possesses six essential characteristics:

1. **An identifiable asserter.** Assertions do not arise spontaneously. They are made by persons, entities, systems, or governed processes capable of assuming responsibility for the claim. Accountability begins with attribution.
2. **A subject.** The subject may be a primitive, a relationship, or even a previous assertion. Assertions therefore operate recursively, allowing claims to support, modify, revoke, or contradict one another without requiring historical revision.
3. **A claim.** The claim describes the relationship being proposed to the ontology. Importantly, it describes a *proposed* state of the world rather than the world's objective condition.
4. **Evidence.** Documents, observations, measurements, prior assertions, governed processes, or cryptographic proofs. Evidence supports an assertion without becoming identical to it. A document may support multiple assertions; an assertion may derive from multiple forms of evidence.
5. **A temporal anchor.** Assertions occur at specific moments. Validity may begin immediately or in future, and consequences may extend indefinitely. Time is a structural property of the graph, not metadata.
6. **Provenance.** Whether established through cryptographic signatures, institutional accountability, or governed procedures, the origin of an assertion must remain inspectable.

Taken together, these characteristics distinguish assertions from conventional database updates. Updating a record replaces one representation with another. Issuing an assertion enlarges the historical record without destroying what preceded it. The architecture therefore **preserves disagreement rather than eliminating it.**

This property has significant consequences for the treatment of error. Traditional systems correct mistakes by modifying records; the previous state disappears. An assertion-based architecture approaches error differently. **Errors are not erased. They are answered.**

If an employer mistakenly records an employee's start date, the architecture does not overwrite the original assertion. It admits a subsequent assertion correcting the earlier claim while preserving the historical relationship between the two. Likewise, if a professional license is suspended, the original grant remains part of the graph. The suspension becomes an additional assertion whose relationship to the original authorization is explicit, inspectable, and temporally bounded.

Yet an important limitation remains.

**Assertions faithfully record what was claimed. They do not establish that the claim deserved to be made.**

A digitally signed assertion proves only that a particular actor issued a particular statement at a particular time. It says nothing about whether the actor possessed appropriate authority, followed an adequate process, interpreted available evidence correctly, or even observed the underlying event accurately. An assertion may be perfectly authentic while simultaneously being entirely mistaken.

This limitation is not an implementation defect. It is a consequence of the distinction between representation and reality.

---

## Chapter 5 — The Binding Problem

The architecture faithfully records assertions. It does not determine whether those assertions were legitimately bound to reality. This distinction represents the boundary upon which every trust architecture ultimately succeeds or fails.

To illustrate, consider an applicant whose employment history, educational credentials, government-issued identity, and professional licenses have all been represented within the trust graph. Every credential has been digitally signed. Every relationship possesses provenance. Every assertion was issued through authorized channels. From the perspective of the architecture, the graph appears internally consistent.

Now suppose that the applicant fraudulently established the original identity years earlier.

Perhaps counterfeit documents were accepted during enrollment. Perhaps an identity proofing officer failed to detect impersonation. Perhaps the governing procedure itself lacked sufficient rigor. Whatever the cause, the consequence is identical. Every assertion derived from that original binding remains internally valid while simultaneously describing the wrong individual.

Nothing within the assertion architecture itself identifies the failure.

**The graph is coherent. Reality is not.**

Cryptographic mechanisms provide extraordinary assurance regarding integrity *after* information has entered a system. Digital signatures establish authorship. Hash functions detect modification. Distributed consensus preserves ordering. These technologies answer whether information has changed. They do not answer whether the information should have entered the system in the first place.

**Cryptography governs representation. Binding governs correspondence.**

The two are frequently conflated because successful binding often precedes successful cryptography. Once an identity has been accepted, every subsequent credential may be perfectly protected despite resting upon an incorrect foundation. The resulting architecture exhibits impeccable internal consistency while faithfully preserving an externally false representation of reality.

At some point every digital architecture encounters the physical world. Documents must be examined. Faces must be compared. Measurements must be observed. Human judgment, institutional authority, or governed procedures must determine whether an observation deserves to become an assertion. The transition from observation to assertion is an **irreversible transformation**: reality is compressed into representation, and subsequent systems inherit the consequences without direct access to the original event.

This boundary is the **binding boundary**.

Binding should not be understood narrowly as identity proofing. Every consequential assertion requires binding:

- An employer binds an individual to an employment relationship.
- A physician binds clinical observations to a diagnosis.
- A laboratory binds measurements to analytical conclusions.
- A regulator binds inspections to certifications.
- A sensor binds physical phenomena to digital measurements.
- A language model binds textual observations to semantic interpretations.

### Three classes of binding failure

| Class | Description | Correct response |
|---|---|---|
| **Fraudulent** | Correspondence intentionally corrupted — counterfeit documents, impersonation, fabricated evidence | Attribution and accountability |
| **Negligent** | Evidence available and process existed, but the responsible actor failed to execute with care | Oversight and training |
| **Structural** | Neither fraud nor negligence. The governing procedure itself is inadequate for the epistemic burden placed on it | Redesign of the governing process |

These categories matter because they require fundamentally different responses. Without distinguishing among them, architectures frequently respond by strengthening cryptographic mechanisms that protect representations while leaving the binding process unchanged. The consequence is predictable: **systems become increasingly effective at preserving incorrect information.**

The Binding Problem cannot be solved by stronger encryption, more sophisticated databases, or larger language models. It cannot even be solved by perfect event sourcing. These technologies operate downstream of the binding boundary. They assume the transformation from observation to assertion has already occurred.

---

## Chapter 6 — The Sentinel Principle

Confidence in a decision cannot exceed confidence in the chain of transformations upon which that decision depends. If uncertainty is introduced during any transformation and is neither detected nor governed, every subsequent conclusion inherits that uncertainty regardless of how internally consistent the remaining architecture may appear.

Two inadequate answers present themselves.

**Self-validation.** Each transformational component validates its own output. Identity proofing systems score their own confidence. Machine learning models estimate their own uncertainty. Although practical, this suffers a structural limitation: *a component cannot independently distinguish errors introduced during its own transformation from errors already present in its inputs.* More importantly, it cannot provide independent evidence that its own reasoning was appropriate. **Confidence is not evidence of correctness.**

**Deferred evaluation.** Postpone judgement until the final decision, absorbing uncertainty from every previous stage. Contemporary large language models illustrate this. Once multiple transformations have been composed, their individual contributions to uncertainty become difficult to separate. Errors become difficult to attribute, diagnose, or correct.

If transformational boundaries are the points at which epistemic integrity may be gained or lost, then governance should occur at those boundaries rather than after the fact.

> **The Sentinel Principle.** Whenever information crosses a boundary that changes its epistemic status, an independent governance mechanism should evaluate whether sufficient epistemic integrity has been preserved before permitting that information to influence downstream reasoning or consequential action.

A sentinel is not responsible for producing knowledge, nor for making decisions. Its function is narrower: **it governs transitions.**

This separates the principle from conventional validation. Validation asks whether a result satisfies predefined criteria. A sentinel asks whether the *process* through which that result was produced preserved sufficient integrity for the intended consequence. The object of governance is not the conclusion but the transformation that produced it.

An observation becomes a measurement when recorded according to an agreed procedure. A measurement becomes an assertion when an accountable actor claims it represents some aspect of reality. Assertions become evidence only when evaluated within the context of a particular question. Evidence contributes to knowledge when its provenance, coherence, and authority justify reliance. Knowledge informs decisions, which produce actions whose consequences return to the physical world.

None of these transitions is automatic. Each requires assumptions regarding authority, context, interpretation, or relevance.

The role of the sentinel is not to eliminate uncertainty — uncertainty is unavoidable. It is to **preserve the distinction between what is known, what is inferred, and what remains uncertain.** In practical terms, a sentinel prevents an architecture from promoting inference into evidence without explicit justification.

### Independence

Sentinels are necessarily independent of the transformations they govern. If the same mechanism both performs a transformation and certifies its adequacy, then no independent evidence regarding the quality of that transformation exists.

Independence is not solely organizational. It is an **epistemic requirement**: the evaluator must possess information unavailable to the transformation itself, or apply criteria distinct from those used to generate it. Otherwise the architecture merely repeats the original reasoning rather than governing it.

### Trust, redefined

Traditional accounts describe trust as confidence, reputation, probability, or authority. Within this framework:

> Trust is the disposition produced when the architecture preserves accountability over every consequential epistemic transition. A conclusion is trustworthy not because it is certain, but because every transformation contributing to that conclusion remains inspectable, attributable, and independently governed.

---

## Chapter 7 — Sentinel Architectures

### 7.1 Sentinel functions

A sentinel is identified not by who it is, but by what role it performs within a chain of epistemic transformations. A radiologist reviewing an image, a compiler performing static analysis, a quality inspector rejecting defective components, and a certificate authority validating key ownership all function as sentinels. Each performs different work and governs a different transformation. The commonality lies in the function: **a sentinel evaluates whether the output of one stage has satisfied the conditions required for admission into the next.**

### 7.2 Sentinel chains

No consequential decision depends upon a single sentinel; architectures compose them into chains.

In commercial aviation a pilot observes weather, instruments observe aircraft state, independent sensors verify altitude, air traffic control verifies separation, and maintenance records verify airworthiness. None independently establishes that the aircraft may fly safely. Collectively they create an architecture in which multiple transformations are governed before a decision is reached.

The pattern generalises. Employment screening depends upon identity proofing, educational verification, employment verification, record verification, and adjudication. Scientific publication depends upon experimental procedure, statistical analysis, peer review, editorial review, and replication. Software deployment depends upon compilation, automated testing, code review, security scanning, and operational monitoring.

**Trustworthy decisions arise from governed chains rather than isolated acts of validation.**

### 7.3 Sentinel independence

A sentinel must remain independent of the transformation whose integrity it governs. This need not imply organisational independence — a compiler and a static analysis tool may run on the same machine; a physician and a radiologist may belong to the same hospital. Architectural independence concerns **function rather than ownership**: the mechanism responsible for producing an assertion should not be solely responsible for determining that the assertion satisfies the conditions for advancement.

### 7.4 Failure modes

| Failure | Description |
|---|---|
| **No sentinel** | Information passes from one transformation to the next without independent governance |
| **Insufficient authority** | The sentinel identifies a problem but cannot prevent propagation |
| **Insufficient evidence** | The sentinel cannot distinguish a trustworthy transformation from an untrustworthy one |
| **Ceremonial governance** | The sentinel exists organisationally but performs no meaningful evaluation |

These differ operationally, but each produces the same architectural consequence: **information acquires greater epistemic authority than the governing process justifies.**

### 7.5 Human and computational sentinels

Many contemporary systems assume that larger models, more parameters, or additional training data will reduce uncertainty sufficiently that independent governance becomes unnecessary. The Sentinel Principle argues the opposite: **greater computational capability increases the importance of independent governance**, because more complex transformations become increasingly difficult to inspect after the fact.

Computational sentinels are not replacements for human judgment, nor the reverse. They govern different transformations. The appropriate architecture depends upon where uncertainty is introduced.

### 7.6 Semantic sentinels

Language introduces another class of transformational boundary. A sentence presented to a language model is not itself a decision. It must first be interpreted. Names become entities. Actions become relationships. Temporal references become ordered events. Context becomes implied structure. Only after these transformations have occurred can reasoning begin.

**The interpretation itself therefore constitutes a binding process.** If semantic interpretation changes the authority with which information will influence subsequent reasoning, then semantic interpretation also requires governance.

This extends the Sentinel Principle into artificial intelligence. Language models should not reason directly over ungoverned semantic interpretation. Instead, interpretation should itself be subjected to sentinel functions responsible for governing **identity resolution, action interpretation, and contextual reconstruction** before downstream reasoning occurs.
