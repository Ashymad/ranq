unit module asm;

my $idnt = "        ";

role Node {
    method asm { ... }
    method Str { ... }
}

role Operand does Node { }

our class Immediate does Operand {
    has Int $.integer;

    method Str {
        "Immediate( $.integer )"
    }

    method asm() {
        "\$$.integer"
    }
}

our class Register does Operand {
    method Str {
        "Register()"
    }

    method asm() {
        "%eax"
    }
}

role Instruction does Node { }

our class Mov does Instruction {
    has Operand $.src;
    has Operand $.dst;

    method Str {
        "Mov( src=$.src, dst=$.dst )"
    }

    method asm() {
        $idnt ~ "movl    {$.src.asm}, {$.dst.asm}\n"
    }
}

our class Ret does Instruction {
    method Str {
        "Ret()"
    }

    method asm() {
        $idnt ~ "ret\n"
    }

}

our class Function does Node {
    has Str $.name;
    has @.instructions;

    method Str {
        "Function( name=\"$.name\", instructions=[ {@.instructions.map({.Str}).join(", ")} ] )"
    }

    method asm() {
        [
            $idnt ~ ".globl  " ~ $.name ~ "\n",
            $.name ~ ":\n",
        ].append(@.instructions.map({ $_.asm })).join()
    }
}

our class Program does Node {
    has Function $.function;

    method Str {
        "Program( $.function )"
    }

    method asm() {
        $.function.asm ~ $idnt ~ ".section        .note.GNU-stack,\"\",@progbits\n"
    }
}
