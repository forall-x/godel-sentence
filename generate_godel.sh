#!/bin/bash
# generate_godel.sh - Robust generator with verification sanity checks and PDF output
set -e

# 1. Check for SBCL presence
if ! command -v sbcl &> /dev/null; then
    echo "Error: sbcl (Steel Bank Common Lisp) is not installed."
    echo "Please install SBCL to run the Godel Arithmetization engine."
    exit 1
fi

# 2. Run Unit Test Suite
echo "Step 1: Running unit tests (sanity check)..."
sbcl --script test_suite.lisp || { echo "FAILED: Unit tests did not pass."; exit 1; }

# 3. Run 1+1=2 Proof Demo
echo "Step 2: Verifying 1+1=2 formal proof (PA-correctness)..."
sbcl --script prove_1plus1.lisp || { echo "FAILED: 1+1=2 formal proof verification failed."; exit 1; }

# 4. Generate Godel Sentence
echo "Step 3: Initializing SBCL for Godel Arithmetization..."
sbcl --load gen_godel.lisp \
     --eval "(make-godel-sentence)" \
     --eval "(sb-ext:exit)" || { echo "FAILED: Godel sentence generation failed."; exit 1; }

# 5. Optional PDF Generation
if command -v pdflatex &> /dev/null; then
    echo "Step 4: Compiling PDF with pdflatex..."
    # Run twice to ensure hyperlinks and alignment are stable
    pdflatex -interaction=batchmode godel.tex > /dev/null
    pdflatex -interaction=batchmode godel.tex > /dev/null
    
    # Clean up standard LaTeX auxiliary files
    rm -f godel.aux godel.log godel.out
    echo "PDF generated: godel.pdf"
else
    echo "Note: pdflatex not found. Skipping PDF generation."
fi

echo "Successfully generated godel.pa, godel.ast, and godel.tex."
