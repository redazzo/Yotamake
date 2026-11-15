# Module design

A short vocabulary and a few rules for judging whether a module earns its place. Skills read
it when they review or reshape the design of existing code. It adapts the deep-module ideas of John Ousterhout's *A Philosophy of Software
Design* and Michael Feathers' seams.

It works alongside the project's **Architecture** section in `CLAUDE.md`, never instead of
it. There, **Boundaries** are the project's rules about which parts may depend on which. A
**seam**, below, is where one module's interface sits. Keep both words, and don't swap one
for the other.

## Words

- **Module:** anything with an interface and an implementation, at any size: a function, a
  file, a package, a service.
- **Interface:** everything a caller must know to use the module correctly. That is the
  signature, and also its rules about order, its errors, the config it needs and how fast it
  is.
- **Implementation:** the code inside the module.
- **Deep:** a lot of behaviour behind a small interface. **Shallow:** the interface is
  nearly as big as what is behind it, so callers learn almost as much as if they read the
  code.
- **Seam:** a place where behaviour can be changed without editing that place. The
  module's interface sits at one.
- **Adapter:** something that fills a seam, such as the real database client or an
  in-memory fake.
- **Leverage:** what callers gain from a deep module: more behaviour for each thing they
  must learn.
- **Locality:** what maintainers gain from it: a change, a bug or a test sits in one place,
  not spread across the callers.

## Rules

- **The deletion test.** Imagine deleting the module and putting its code back in its
  callers. If the complexity disappears, the module was only passing calls through: a
  candidate to remove or merge. If the same complexity comes back in several callers, the
  module earns its place.
- **The interface is the test surface.** Tests call the module the way its callers do. A
  test that has to reach past the interface into the internals means the module is the
  wrong shape.
- **One adapter is a guess, two make a seam.** Only add a seam (an interface, a port, an
  injected dependency) when two things will fill it, typically the real one and a test one.
  With one, it is extra indirection.
- **Depth is about the interface.** A deep module may be built from small parts inside. They
  stay out of its interface.
- **Replace, don't layer.** Once tests exist at the deepened module's interface, delete the
  old tests on the shallow parts it absorbed. Don't keep both.

## Signs of a shallow module

- To understand one idea, you jump between many small files.
- A function or class only forwards its arguments to another one.
- A pure helper was pulled out to make it testable, but the bugs are in how it is called.
- Two modules always change together, or one reaches into the other's internals.
- Code that is untested, or that can only be tested by reaching past its interface.
- A hidden state machine: the states live in loose flags or a status field, and each caller
  checks and sets them itself. One module should own the states and the moves between them.

## Dependencies, and how to test a deepened module

Sort what the module depends on. The kind decides how its tests reach it:

1. **In-process:** pure code or in-memory state, no input or output. Merge freely and test
   through the new interface. No adapter is needed.
2. **Local stand-in:** something with a local substitute, such as an embedded database or an
   in-memory file system. Test with the stand-in. The seam stays inside the module.
3. **Owned, remote:** the project's own service across a network. Put a port at the seam,
   with a network adapter for production and an in-memory one for tests.
4. **Third-party:** a service you don't control, such as payments or email. Inject it at the
   seam, and give the tests a fake adapter.

A port in a project that has none is a new pattern: the design-conflict stop in
`simple-session`, "Design and reuse", applies.
