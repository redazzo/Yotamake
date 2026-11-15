# Architecture styles

A short catalogue for the **Style** line in a project's `CLAUDE.md` (Architecture). Skills
read it to name the style a codebase follows, and to turn that style into **Boundaries**,
**Patterns** and design gates.

A style is a set of rules about parts and how they connect. Most systems mix styles: one
between deployable units and another inside each. Write each one on the Style line with the
place it applies, e.g. "modular monolith; hexagonal inside `core/`".

Each entry gives:

- **Fits when:** the qualities it serves.
- **Costs:** what it makes harder.
- **Boundaries:** rules it implies, to copy into the Boundaries line with real paths.
- **Patterns:** recurring choices it needs settled, for the Patterns line.
- **Gate:** what a boundary tool in `scripts/check` checks (dependency-cruiser,
  import-linter, ArchUnit or similar).
- **Signs in code:** how to recognise it in an existing repository.

## Inside one deployable unit

### Layered

- **Fits when:** a team wants a familiar split by technical concern (presentation, business,
  data). Good for simple CRUD applications.
- **Costs:** a feature change touches every layer. Business rules tend to leak into the top
  or bottom layer.
- **Boundaries:** a layer imports only the layer below it (strict) or any lower layer
  (relaxed). Say which. No layer imports one above it.
- **Patterns:** how errors and data cross a layer (exceptions or results; entities or DTOs).
- **Gate:** forbid imports from each lower layer folder to any higher one.
- **Signs in code:** top-level folders such as `controllers/`, `services/`, `repositories/`.

### Modular monolith

- **Fits when:** one deployable unit, but the domain has clear parts that should change
  independently. A common step before services.
- **Costs:** needs discipline: without a gate, modules grow hidden dependencies.
- **Boundaries:** each module is reached only through its public entry point (e.g. its
  `index` file). No module reads another module's tables or internals. No dependency
  cycles between modules.
- **Patterns:** how modules talk (direct calls to the public API, or in-process events).
- **Gate:** forbid imports into another module's internal paths; forbid cycles.
- **Signs in code:** folders by feature or domain (`billing/`, `orders/`), each with its own
  layers inside.

### Hexagonal (ports and adapters), onion, clean

- **Fits when:** business rules must outlive frameworks, databases and delivery channels, and
  must be testable without them.
- **Costs:** more interfaces and mapping code. Overkill for thin CRUD.
- **Boundaries:** the core (domain and use cases) imports no adapter, framework, database or
  network code. Adapters depend on the core's ports, never the other way round.
- **Patterns:** where ports are defined; how adapters are wired in (one composition root).
- **Gate:** forbid imports from the core folder to adapter folders and to framework
  packages.
- **Signs in code:** `domain/`, `ports/`, `adapters/`, `infrastructure/`, `usecases/`.

### Functional core, imperative shell

- **Fits when:** logic can be pure functions of their inputs. Libraries, rule engines,
  calculations, transformations.
- **Costs:** the shell must gather every input up front; awkward for long interactive flows.
- **Boundaries:** core code never reads the clock, environment, files, network or console;
  it takes values as arguments and returns values. Only the shell does input and output.
- **Patterns:** how the shell passes config and time in; how errors are returned.
- **Gate:** forbid I/O modules (e.g. `fs`, `process`, `http`) in the core folder.
- **Signs in code:** a folder of pure functions with no I/O imports, and a thin entry point.

### Pipes and filters

- **Fits when:** data goes through a series of independent steps. ETL, compilers, media and
  text processing, build tools.
- **Costs:** hard for interactive or highly stateful work. Each hop may cost a copy or a
  format change.
- **Boundaries:** a filter knows only its input and output format, never its neighbours. No
  shared state between filters.
- **Patterns:** the format between stages; how errors and bad records are handled.
- **Gate:** forbid imports between filter files; allow only the shared format module.
- **Signs in code:** a pipeline definition that chains stage functions or processes.

### Microkernel (plug-in)

- **Fits when:** a small stable core with many optional or third-party extensions. IDEs,
  browsers, CLIs, rule-based products.
- **Costs:** the plug-in contract is hard to change once others build on it.
- **Boundaries:** the core never imports a plug-in. Plug-ins use only the published plug-in
  API, never core internals, and do not import each other.
- **Patterns:** how plug-ins are found, loaded, versioned and isolated.
- **Gate:** forbid core-to-plug-in imports and plug-in imports of core internals.
- **Signs in code:** a `plugins/` or `extensions/` folder and a registry or loader.

### Model–view–controller and its variants

- **Fits when:** a user interface over changing data (MVC, MVP, MVVM).
- **Costs:** controllers or view models grow into "god" objects without care.
- **Boundaries:** the model never imports views or controllers. Views hold no business
  rules.
- **Patterns:** how views learn of model changes (binding, observers, a store).
- **Gate:** forbid imports from model folders to view or controller folders.
- **Signs in code:** `models/`, `views/`, `controllers/` or a framework's equivalents.

## Between deployable units

### Client–server and n-tier

- **Fits when:** many clients share one set of data and rules.
- **Costs:** the server is a bottleneck and a single point of failure without scaling work.
- **Boundaries:** clients reach data only through the server's API, never the database.
- **Patterns:** API style (REST, RPC, GraphQL), versioning, authentication.
- **Gate:** forbid database client packages in client code.
- **Signs in code:** separate client and server apps; an API schema between them.

### Service-based and microservices

- **Fits when:** parts must be deployed, scaled or owned by teams independently.
  Service-based uses a few coarse services; microservices many fine ones.
- **Costs:** network failure, data consistency, observability and operations all get harder.
  Wrong service lines are costly to move.
- **Boundaries:** each service owns its data; no service reads another's database. Services
  talk only through published APIs or events. No shared domain library beyond contracts.
- **Patterns:** sync or async calls; contract and schema versioning; retries, timeouts,
  idempotency; tracing.
- **Gate:** forbid imports across service folders except a contracts package; contract
  tests in CI.
- **Signs in code:** several deployable apps, one per folder or repo, each with its own
  storage config.

### Event-driven

- **Fits when:** parts react to things that happened, with loose coupling and high
  throughput. Integrations, workflows, audit trails.
- **Costs:** flow is hard to follow and debug. Ordering, duplicates and eventual consistency
  must be designed for.
- **Boundaries:** publishers do not know their subscribers. Events go through the broker or
  bus only, never direct calls disguised as events.
- **Patterns:** event naming and schema versioning; at-least-once handling (idempotent
  consumers); broker topology (direct broker or a mediator that runs workflows).
- **Gate:** forbid direct imports between handler modules; validate event schemas.
- **Signs in code:** a message broker client, `events/` or `handlers/` folders,
  subscription config.

### Publish–subscribe and message bus

A form of event-driven where a bus routes messages by topic. Same rules as event-driven.

### Space-based

- **Fits when:** very high, spiky load where a central database would be the bottleneck.
- **Costs:** complex; data lives in replicated in-memory grids and syncs to storage later.
- **Boundaries:** processing units read and write only the data grid, never the database
  directly.
- **Patterns:** grid replication, write-behind to storage, conflict handling.
- **Gate:** forbid database client packages in processing units.
- **Signs in code:** an in-memory data grid product and processing-unit deployables.

### Peer-to-peer

- **Fits when:** no central server is wanted or possible. File sharing, sync, some
  blockchains.
- **Costs:** discovery, trust and consistency are all hard.
- **Boundaries:** every peer uses the same protocol module; no peer assumes a central
  authority.
- **Patterns:** discovery, conflict resolution (e.g. CRDTs), trust.
- **Gate:** protocol conformance tests.
- **Signs in code:** one app that both serves and requests, with discovery code.

## Patterns often listed beside styles

These shape a part of a system rather than all of it. Put them on the Patterns line, or on
the Style line with the place they apply.

- **CQRS:** separate models for writes and reads. Boundary: queries never change state.
- **Event sourcing:** state is rebuilt from a log of events. Boundary: events are never
  changed or deleted; state changes only by appending one.
- **Domain-driven design bounded contexts:** each context has its own model and language.
  Boundary: contexts share no model types; they translate at the edge.
- **REST:** client–server, stateless, cacheable, uniform interface, layered. Boundary: the
  server keeps no client session state between requests.

## Choosing a style

Start from what matters most: change rate, team count, deploy independence, scale, latency,
testability, and the constraints. Name two or three candidate styles, give each one's fit
and cost against those needs, and recommend one. Prefer the simplest style that meets them;
a modular monolith can split into services later, but merging services back is costly. A
choice that is costly to reverse gets an ADR.

## Changing the style

Change the rule before the code, in this order:

1. The ADR, and the Architecture lines in `CLAUDE.md`.
2. The boundary gate in the check command. Turn it on only for code already moved, or add
   it in the last step.
3. The code, moved in steps that each pass the gate.

This is more than one session's work, so it runs as a `multi-session` effort.
