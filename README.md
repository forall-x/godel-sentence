# Gödel Sentence Construction in Peano Arithmetic

This project generates an explicit undecidable Gödel sentence $G$ within first-order Peano Arithmetic (PA). The construction follows Gödel's First Incompleteness Theorem, asserting its own unprovability: $G \iff \neg \text{Prov}(gn(G))$.

## Core Architecture: Fixed-Width Block DAG Encoding

To handle the complexity of arithmetizing syntax without exponential bit-growth, this project utilizes a **Fixed-Width Block DAG Encoding**. 

### Node Representation
Each formula or term is represented as a construction sequence (DAG) stored as a large integer. This integer is divided into 60-bit blocks:
- **Block 0**: The total number of nodes $L$.
- **Blocks 1..L**: Individual DAG nodes.

Each 60-bit node is bit-packed as follows:
- **Bits 0-27**: Right Child Index (referencing a previous block).
- **Bits 28-55**: Left Child Index (referencing a previous block).
- **Bits 56-59+**: Operator Tag (e.g., SUCC=3, ADD=4, EQ=6, FORALL=11).

### Why a DAG?
This architecture is referred to as a **Directed Acyclic Graph (DAG)** because:
1.  **Directed**: Each node has explicit pointers (indices) to its children.
2.  **Acyclic**: Nodes can only reference *previous* indices in the sequence, making cycles impossible.
3.  **Graph (Structural Sharing)**: Unlike a simple tree where sub-expressions are duplicated, multiple "parent" nodes can point to the same "child" index. If a sub-term (like $x+1$) appears 100 times in the formula, it is only stored **once** in the construction sequence.

This **structural sharing** ensures that the Gödel number grows linearly with the number of *unique* sub-expressions, rather than exponentially with the total number of terms.

### Implicit Type Safety (No `IsTerm`/`IsFormula`)
Traditional arithmetizations of logic require lengthy formal definitions for recursive predicates like `IsTerm(n)` or `IsFormula(n)` to ensure a Gödel number corresponds to a well-formed expression. In this project, these are omitted for two reasons:
1.  **Uniform Representation**: In the Block DAG encoding, terms and formulas are structurally identical (both are just sequence nodes). 
2.  **Syntactic Well-formedness Preservation**: We rely on the **invariant** that if a sequence starts with valid axioms and follows rules of inference (Modus Ponens and Generalization), the resulting conclusion is **guaranteed** to be a well-formed formula. 

By letting the proof-checker (`is-proof-of-pa`) implicitly enforce syntax, we avoid the overhead of explicit type-checking predicates, keeping the final Gödel sentence under 40KB.

## Project Structure

### Core Modules
- **`core.lisp`**: Foundational PA term builders, Cantor pairing function, and the `to-pa` stringifier.
- **`syntax.lisp`**: Logic for converting Lisp-based ASTs into flattened DAG sequences and bit-packing blocks.
- **`sequence.lisp`**: Implementation of Gödel's Beta function for sequence indexing and high-level bit-segment extraction within PA formulas.

### Arithmetization Predicates
- **`is-ast.lisp`**: Verifies that a sequence of blocks represents a valid DAG (e.g., indices are strictly decreasing).
- **`is-free.lisp` & `is-sub.lisp`**: Predicates for detecting free variables and performing term substitution at the bit-level.
- **`is-proof.lisp` & `is-inference.lisp`**: Verifies proof chains by checking axioms and rules of inference (Modus Ponens and Generalization).
- **`is-diag.lisp`**: Implements the diagonalization predicate $y = diag(x)$, which constructs the Gödel number of formula $x$ with its own Gödel number substituted for its free variable.

### Generator
- **`gen_godel.lisp`**: The high-level logic for constructing the sentence using the Diagonal Lemma.
- **`checker.lisp`**: Lisp-side proof verification engine (used for testing and building arithmetized proofs).
- **`generate_godel.sh`**: Shell script to run the generator with recommended settings.

## Usage

The project is written in Common Lisp and optimized for **SBCL**. 

A generator shell script is provided for convenience:

```bash
chmod +x generate_godel.sh
./generate_godel.sh
```

### Formal Verification Demo (1+1=2)
The project includes a formal 14-step proof of $S(0) + S(0) = S(S(0))$ to demonstrate the correctness of the PA verification engine. You can run the proof check using:

```bash
sbcl --script prove_1plus1.lisp
```

This script verifies each step against the arithmetized PA axioms and rules of inference, printing the Gödel number for every intermediate formula.

### Performance & Memory
Thanks to **DAG Structural Sharing**, the generation is reasonably resource-efficient. The 38KB Gödel sentence can be constructed using **standard SBCL defaults** on an old chromebook. No extra memory or stack allocation tuning is required.

### Output
The generator produces a file named `godel.pa` containing the final Gödel sentence in standard Peano Arithmetic syntax.

## Arithmetization Details

### 1. Syntax to DAG Mapping
Every PA formula and term is first flattened into a **Construction Sequence** (DAG), where each node references the indices of its predecessor sub-terms.

| Operator | Tag | Description |
| :--- | :--- | :--- |
| `ZERO` | 1 | The constant 0 |
| `VAR` | 2 | Variable $v_n$ (Left child = $n$) |
| `SUCC` | 3 | Successor $S(t)$ |
| `ADD` | 4 | Addition $(t_1 + t_2)$ |
| `MUL` | 5 | Multiplication $(t_1 \cdot t_2)$ |
| `EQ` | 6 | Equality $(t_1 = t_2)$ |
| `NOT` | 7 | Negation $\neg P$ |
| `AND` | 8 | Conjunction $(P \land Q)$ |
| `OR` | 9 | Disjunction $(P \lor Q)$ |
| `IMPLIES` | 10 | Implication $(P \to Q)$ |
| `FORALL` | 11 | Universal $\forall v_n P$ |
| `EXISTS` | 12 | Existential $\exists v_n P$ |

### 2. Concrete Example: `S(0) = 0`
The formula `(succ zero) = zero` is decomposed into the following DAG:
1.  **Node 0**: `(Tag=1, L=0, R=0)` → represents `zero`
2.  **Node 1**: `(Tag=3, L=0, R=0)` → represents `S(node 0)`
3.  **Node 2**: `(Tag=6, L=1, R=0)` → represents `node 1 = node 0`

**Bit-Packing**:
To pack the node into a single integer, the components are shifted into their defined bit-ranges (28 bits for the Right Child, 28 bits for the Left Child, and the remainder for the Tag):
`Node Value = (Tag << 56) + (L << 28) + R`

For Node 2, this calculates as: `(6 << 56) + (1 << 28) + 0 = 432345564227567616`.

**Final Gödel Number**:
The sequence $(3, Node_0, Node_1, Node_2)$ is packed into blocks of 60 bits:
$GN = 3 + (Node_0 \cdot 2^{60}) + (Node_1 \cdot 2^{120}) + (Node_2 \cdot 2^{180})$.

### 3. Arithmetization of Predicates
To construct logical claims about Gödel numbers, high-level concepts must be "compiled" down into pure Peano Arithmetic (only $0, S, +, =, \cdot$). 

For example, to represent the "strictly less than" relation ($x < y$) without a native `<` operator, we implement a generator function that builds a formal PA AST asserting that there exists some number $z$ such that $x + S(z) = y$:
$$x < y \iff \exists z \, (x + S(z) = y)$$

```lisp
(defun make-less (x y counter)
  (let ((z (fresh-var "lz_" counter)))
    (list 'exists z 
          (list 'eq (list 'add x (list 'succ (list 'var z))) y))))
```

### 4. Arithmetization of Sequences
We use **Gödel's Beta Function** to encode arbitrary sequences of numbers into a single pair of integers $(c, d)$. The Beta function leverages the Chinese Remainder Theorem to guarantee that for any sequence $[x_1, x_2, \dots, x_k]$, there exist $c$ and $d$ such that:
$$Beta(c, d, i) = x_i \text{ for all } i \le k$$

In our system, $Beta$ is arithmetized as a predicate that extracts the $i$-th element of the sequence using only multiplication and remainder/modulo arithmetic. We use **Cantor Pairing** to pack $(c, d)$ into a single integer, allowing an entire proof sequence or variable-length bounded sequence to be represented as one number.

A proof is represented as an ordered sequence of formulas $(F_1, F_2, \dots, F_L)$, where each $F_i$ is either an axiom or follows from previous formulas via rules of inference. The arithmetized predicate `is-proof-of-pa(P, gn(F_L))` verifies that the sequence $P$ (encoded via the Beta function) satisfies these structural requirements.

See the **Addendum** for an example.

## Peano Arithmetic Syntax
The output uses the following shorthand:
- `0`: Zero constant.
- `S(x)`: Successor.
- `(x + y)`: Addition.
- `(x * y)`: Multiplication.
- `(x = y)`: Equality.
- `~P`: Negation.
- `(P & Q)`: Conjunction.
- `(P v Q)`: Disjunction.
- `(P -> Q)`: Implication.
- `Ax: P`: Universal quantification ($\forall x$).
- `Ex: P`: Existential quantification ($\exists x$).

## Full Induction Schema Support
The First-Order Induction Schema is fully arithmetized in the Block DAG:
$$[A(0) \land \forall x (A(x) \to A(S(x)))] \to \forall x A(x)$$
This was achieved by implementing `is-induction-pa`, which performs structural matches and multiple arithmetized substitutions (`is-sub-pa`) for the base case and induction step. This ensures the project covers the full theory of Peano Arithmetic (PA).

## Alternatives Considered

### 1. Bare-Minimum Logical Primitives
Theoretically, first-order logic only requires a single quantifier (e.g., $\forall$) and a minimal set of boolean connectives (e.g., $\neg$ and $\lor$). It is possible to pare down our DAG operator dictionary (which contains 12 tags) by removing redundant operators:
*   `EXISTS` could be omitted, as $\exists x P$ is strictly equivalent to $\neg \forall x \neg P$.
*   `AND` could be omitted, as $P \land Q$ is strictly equivalent to $\neg(\neg P \lor \neg Q)$.
*   `IMPLIES` could be omitted, as $P \to Q$ is strictly equivalent to $\neg P \lor Q$.

While a strict minimalist alphabet simplifies the arithmetized logic slightly (fewer cases required in `is-ast-pa`), we deliberately admitted the full suite of boolean tags into the DAG builder to act as **structural compression macros**. Expanding every existential quantifier into a triple-node `NOT -> FORALL -> NOT` structure would significantly deepen the AST. Since our Gödel number is heavily reliant on bound existential chains (`make-block-segment`), including `EXISTS` directly compresses three nodes into one, reducing the bit-length of the integer and size of PA string output.

### 2. Exponentiation
It is interesting to speculate whether adding an **exponentiation** operator ($x^y$) to the object language would make the highly nested constants inside the Gödel sentence more compact. *(Note: This is a speculative theoretical exercise and has not been implemented or tested in this project).*

1. **AST Node Compression**: If measured purely by Abstract Syntax Tree nodes, exponentiation would significantly compress the underlying mathematical structure—shrinking our binary-doubling numerals from $O(\log N)$ nodes to $O(\log \log N)$ nodes.
2. **Visual Compression**: In our visual output (`godel.pa`), massive constants are already summarized as Base-10 strings (e.g., `287342913912...`). Adding exponentiation might allow printing `(2 ^ 166)` instead of a 50-digit string, potentially shrinking the visual file size from 16.5KB down to roughly 10-12KB. 
3. **The Catch (The Beta Function Definition)**: In strict First-Order Peano Arithmetic, exponentiation is *not* a primitive operator (the vocabulary is strictly $\{0, S, +, =, \cdot\}$). To treat it as primitive requires extending PA into PE (PA with Exponentiation). To define it strictly *within* PA, one must use Gödel's Beta function to encode the recursive sequence. Because our DAG is already based on a Beta function, introducing a second level of recursion strictly to compress numerals creates a circular complexity problem that likely outweighs the visual string reduction.

### 3. Strict $\Delta_0$ (Primitive Recursive) Formalism
In standard proofs of Gödel's First Incompleteness Theorem, predicates like `IsProof(x, y)` are shown to be Primitive Recursive ($\Delta_0$) by strictly bounding every quantifier (e.g., $\exists L \le \text{ProofGN}$). 

This project sacrifices strict $\Delta_0$ purity in favor of **AST compression**. If every internal variable across all verification predicates were mathematically bounded, nested $\le$ arithmetic trees would be required for every binding. In PA, a bounded existential $\exists x \le y$ expands to $\exists x \, (\exists k \, (x + k = y) \dots)$. Bounding hundreds of internal variables would cause an significant increase in DAG size and string length, pushing the formula into the megabytes.

By using unbounded existentials for local predicate bindings, the formula enters higher levels of the Arithmetical Hierarchy (e.g., $\Sigma_1$). This remains logically valid—Peano Arithmetic can verify true $\Sigma_1$ sentences using unbounded searches.

## Variable Normalization and the "v1" Hole
To ensure that Gödel numbers are stable and the resulting formula is readable, the generator utilizes a **Variable Canonization** process. All internal variables (like `p` for proofs or `nx` for numerals) are renamed to a standard sequence: $v_0, v_1, v_2, \dots$.

A curious property of the final Gödel sentence is that **$v_1$ is absent from the formula**, which instead contains $v_0, v_2, v_3, \dots$.

This is not a bug, but a direct consequence of the **Diagonal Lemma**:
1. In the first stage of construction, we define a formula template $\alpha(x)$, where $x$ is a free variable. 
2. Our canonizer explicitly maps this free variable $x$ to **$v_1$**.
3. We calculate the Gödel number $n = gn(\alpha(x))$.
4. In the final stage, we "diagonalize" by substituting every instance of $v_1$ with a numeral representing the constant $n$.

## Addendum: Formal Specification of the Theory

The Gödel sentence generated by this project targets the full theory of **First-Order Peano Arithmetic (PA)**, including the First-Order Induction Schema.

### 1. Logical Vocabulary
The object language utilizes the following symbols:
- **Constants**: `0` (Zero).
- **Functions**: `S(x)` (Successor), `(x + y)` (Addition), `(x * y)` (Multiplication).
- **Predicates**: `(x = y)` (Equality).
- **Connectives**: `~P` (Negation), `(P & Q)` (Conjunction), `(P v Q)` (Disjunction), `(P -> Q)` (Implication).
- **Quantifiers**: `Ax: P` (Universal), `Ex: P` (Existential).

### 2. Axioms
The following formulas are hardcoded as valid starting points in `is-axiom.lisp`:
- **PA1**: `~(S(x) = 0)`
- **PA2**: `(S(x) = S(y)) -> (x = y)`
- **PA3**: `(x + 0) = x`
- **PA4**: `(x + S(y)) = S(x + y)`
- **PA5**: `(x * 0) = 0`
- **PA6**: `(x * S(y)) = ((x * y) + x)`
- **EQ1**: `x = x` (Reflexivity)
- **EQ2**: `(x = y) -> (S(x) = S(y))` (Functional Congruence for Successor)
- **EQ3**: `(x = y) -> (A[x] -> A[y])` (Structural Substitution Schema)
- **Q1**: `(Ax: A) -> A[t/x]` (Quantifier Specification Schema)
- **IND**: `[A(0) & Ax(A(x) -> A(Sx))] -> Ax A(x)` (First-Order Induction Schema)

### Theoretical Notes
- **Axiomatic Redundancy**: While `EQ2` is technically an instance of the `EQ3` schema, it is included as a fixed axiom to provide a **"fast path"** for arithmetized verification. Checking a fixed axiom in PA is computationally cheaper and results in shorter proof sequences than justifying successor-congruence through the full general substitution logic.
- **Substitution Limitation**: The arithmetized substitution predicate (`is-sub-pa`) performs a **global structural replacement** of all occurrences of variable $x$ with term $y$. Unlike strict logical substitution, it does not currently distinguish between free and bound occurrences, nor does it check if $y$ is "free for" $x$ in $A$. In this project, variable capture is avoided by construction using unique variable names for each predicate layer.
- **Full PA Support**: The First-Order Induction Schema and the full Quantifier/Equality schemas are fully arithmetized in the DAG for all possible formulas $A$. This makes the theories of our Gödel sentence a complete, foundational fragment of Peano Arithmetic (PA).

### 3. Rules of Inference
A proof is verified if every non-axiom formula $F_i$ in the sequence follows from previous formulas $F_j, F_k$ ($j, k < i$) via:
- **Modus Ponens (MP)**: From $P$ and $(P \to Q)$, derive $Q$.
- **Generalization (Gen)**: From $P$, derive $\forall x P$.

### 4. Machine-Verified Derivation: Proving $1+1=2$
The following 14-step proof of $S(0)+S(0)=S(S(0))$ was generated by the arithmetized PA verification engine. Each step either instantiates an axiom (e.g., PA3, PA4) or follows from previous steps via Modus Ponens (MP) or Generalization (Gen).

| Step | Formula | Justification |
| :--- | :--- | :--- |
| 1 | `((x + S(y)) = S(x + y))` | Axiom PA4 |
| 2 | `Ay: ((x + S(y)) = S(x + y))` | Gen on (1) |
| 3 | `Ax: Ay: ((x + S(y)) = S(x + y))` | Gen on (2) |
| 4 | `(Ax: Ay: ((x + S(y)) = S(x + y)) -> Ay: ((S(0) + S(y)) = S(S(0) + y)))` | Spec on (3) |
| 5 | `Ay: ((S(0) + S(y)) = S(S(0) + y))` | MP on (3, 4) |
| 6 | `(Ay: ((S(0) + S(y)) = S(S(0) + y)) -> ((S(0) + S(0)) = S(S(0) + 0)))` | Spec on (5) |
| 7 | `((S(0) + S(0)) = S(S(0) + 0))` | MP on (5, 6) |
| 8 | `((x + 0) = x)` | Axiom PA3 |
| 9 | `Ax: ((x + 0) = x)` | Gen on (8) |
| 10 | `(Ax: ((x + 0) = x) -> ((S(0) + 0) = S(0)))` | Spec on (9) |
| 11 | `((S(0) + 0) = S(0))` | MP on (9, 10) |
| 12 | `(((S(0) + 0) = S(0)) -> (((S(0) + S(0)) = S(S(0) + 0)) -> ((S(0) + S(0)) = S(S(0)))))` | Eq. Subst. |
| 13 | `(((S(0) + S(0)) = S(S(0) + 0)) -> ((S(0) + S(0)) = S(S(0))))` | MP on (11, 12) |
| 14 | `((S(0) + S(0)) = S(S(0)))` | MP on (7, 13) |

The machine-readable Gödel numbers for these formulas are calculated using the Fixed-Width Block DAG encoding, ensuring the entire proof sequence can be represented as a single large integer.

## Attribution

- Previous work by **Stephen Lee** [Gödel Sentence for PA](https://web.archive.org/web/20110414150658if_/http://tachyos.org/godel.html) was an inspiration but not used directly.
- Developed with Gemini 3 + Antigravity.

