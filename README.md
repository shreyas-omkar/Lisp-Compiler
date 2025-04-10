#  Lisp Compiler v0.1 (Zig)

This is a minimal Lisp interpreter/compiler written in [Zig](https://ziglang.org/).  
It supports basic arithmetic expressions and demonstrates the core steps of interpreting a Lisp-like language: **tokenization, parsing, and evaluation**.

---

##  Features

- Fully working tokenizer, parser, and evaluator
- Supports:
  - Nested expressions
  - Arithmetic operations: `+`, `-`, `*`, `/`, `%`
- Basic error handling:
  - Unbalanced parentheses
  - Extra tokens
  - Division/modulo by zero
  - Invalid operators or operands

---

##  Project Structure

```bash
.
├── main.zig           # Entry point with REPL-style loop
├── tokeniser.zig      # Tokenizes raw Lisp code into token list
├── parser.zig         # Parses token list into AST
├── evaluator.zig      # Evaluates AST and computes result
├── ast.zig            # AST type definitions
├── .gitignore
└── README.md
```
---

##  How To Run
Prerequisites : 
- Make sure you have Zig installed. Tested with `0.11.0+`
- If not get it from [Zig](https://ziglang.org/download/)
- Clone or Download the Project
  
    ``` bash
    git clone https://github.com/shreyas-omkar/Lisp-Compiler
    cd Lisp-Compiler
    ```
    
- Run the Interpreter
  
    ``` bash
  zig run main.zig
    ```
    
- Try Lisp Expressions
  
    ``` bash
  list> ( + 1 2 )
  3

  list> ( * 2 ( + 3 4 ) )
  14

    ```

- To Exit

   ``` bash
  list> exit

    ```
---

##  Version Roadmap

### ✅ v0.1 (current)
- Core interpreter with basic math
- Tokenizer, Parser, AST Builder, Evaluator
- Interactive REPL

### 🔜 v0.2 (planned)
- `define` (variables)
- `lambda` functions
- `if` conditionals
- Scoping & environments

---

##  Why Zig?

-  Low-level control + high performance  
-  Simple, C-like syntax  
-  Excellent for learning how compilers/interpreters work  
-  Fast, safe, and minimal — perfect for building from scratch

---

##  Author

**Shreyas Hegde (aka Shaggy)**  
Built for fun, learning, and eventual world domination.  
Feel free to fork, star, or contribute!

---


