unit module codegen;

my $idnt = "        ";

role AssemblyNode {
    method asm { ... }
    method Str { ... }
}

role Operand does AssemblyNode { }

class Immediate does Operand is export {
    has Int $.integer;

    method Str {
        "Immediate( $.integer )"
    }

    method asm() {
        "\$$.integer"
    }
}

class Register does Operand is export {
    method Str {
        "Register()"
    }

    method asm() {
        "%eax"
    }
}

role Instruction does AssemblyNode { }

class Mov does Instruction is export {
    has Operand $.src;
    has Operand $.dst;

    method Str {
        "Mov( src=$.src, dst=$.dst )"
    }

    method asm() {
        $idnt ~ "movl    {$.src.asm}, {$.dst.asm}\n"
    }
}

class Ret does Instruction is export {
    method Str {
        "Ret()"
    }

    method asm() {
        $idnt ~ "ret\n"
    }

}

class Subroutine does AssemblyNode is export {
    has Str $.name;
    has @.instructions;

    method Str {
        "Subroutine( name=\"$.name\", instructions=[ {@.instructions} ] )"
    }

    method asm() {
        [
            $idnt ~ ".globl  " ~ $.name ~ "\n",
            $.name ~ ":\n",
        ].append(@.instructions.map({ $_.asm })).join()
    }
}

class Assembly does AssemblyNode is export {
    has Subroutine $.function;

    method Str {
        "Assembly( $.function )"
    }

    method asm() {
        $.function.asm ~ $idnt ~ ".section        .note.GNU-stack,\"\",@progbits\n"
    }
}
