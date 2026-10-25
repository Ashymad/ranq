unit module parse;

use tok;
use asm;

class UnexpectedToken is Exception {
    has Str $.expected;
    has Str $.found;

    method message() {
        "Expected $.expected, but found $.found"
    }
}


sub chomp($tokens is rw, $expected) {
    my $tok = $tokens.pull-one;
    if ($tok.type == $expected) {
        return $tok.lexeme;
    } else {
        UnexpectedToken.new(
            expected => $expected.Str,
            found => $tok.type.Str
        ).throw;
    }
}

role Node  {
    method gen { ... }
    method Str { ... }
    method parse { ... }
}

class Constant does Node {
    has Int $.integer;
    
    method Str() {
        "Constant( $.integer )"
    }

    method gen() {
        asm::Immediate.new(integer => $.integer);
    }

    method parse($tokens is rw) {
        return Constant.new(integer => chomp($tokens, t_const).Int);
    }
}

class Return does Node {
    has Constant $.const;
    
    method Str() {
        return "Return( $.const )"
    }

    method gen() {
        gather {
            take asm::Mov.new(src => $.const.gen, dst => asm::Register.new());
            take asm::Ret.new();
        }
    }

    method parse($tokens is rw) {
        chomp($tokens, t_return);

        my $con = Constant.parse($tokens);

        chomp($tokens, t_semicolon);

        return self.new(const => $con);
    }

}


class Function does Node {
    has Str $.name;
    has Return $.body;

    method Str() {
        return "Function( name=\"$.name\", body=$.body )"
    }

    method gen() {
        return asm::Function.new(name => $.name, instructions => $.body.gen);
    }

    method parse($tokens is rw) {
        chomp($tokens, t_int);
        my $name = chomp($tokens, t_ident);

        chomp($tokens, t_paren_l);
        chomp($tokens, t_void);
        chomp($tokens, t_paren_r);
        chomp($tokens, t_brace_l);

        my $ret = Return.parse($tokens);
        chomp($tokens, t_brace_r);

        return self.new(name => $name, body => $ret);
    }
}

class Program does Node {
    has Function $.function;

    method Str() {
        return "Program( $.function )"
    }

    method gen() {
        return asm::Program.new(function => $.function.gen);
    }

    method parse($tokens is rw) {
        my $fun = Function.parse($tokens);
        chomp($tokens, t_eof);
        return self.new(function => $fun);
    }
}

class Parser is export {
    method parse(@tokens) {
        my $tokens = @tokens.iterator;
        return Program.parse($tokens);
    }
}

