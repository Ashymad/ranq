unit module parse;

use lex;
use codegen;

role Node is export {
    method gen { ... }
}

class Constant does Node {
    has Int $.integer;
    
    method Str() {
        return "Constant( $.integer )"
    }

    method gen() {
        return Immediate.new(integer => $.integer);
    }
}

class Return does Node {
    has Constant $.const;
    
    method Str() {
        return "Return( $.const )"
    }

    method gen() {
        gather {
            take Mov.new(src => $.const.gen, dst => Register.new());
            take Ret.new();
        }
    }
}

class Function does Node {
    has Str $.name;
    has Return $.body;

    method Str() {
        return "Function( name=\"$.name\", body=$.body )"
    }

    method gen() {
        return Subroutine.new(name => $.name, instructions => $.body.gen);
    }
}

class Program does Node {
    has Function $.function;

    method Str() {
        return "Program( $.function )"
    }

    method gen() {
        return Assembly.new(function => $.function.gen);
    }
}

class Parser::UnexpectedToken is Exception {
    has Str $.expected;
    has Str $.found;

    method message() {
        "Expected $.expected, but found $.found"
    }
}

class Parser is export {
    has @.tokens;
    has Int $!idx = 0;

    method chomp($expected) {
        my $tok = @.tokens[$!idx++];
        if ($tok.type == $expected) {
            return $tok.lexeme;
        } else {
            Parser::UnexpectedToken.new(
                expected => $expected.Str,
                found => $tok.type.Str
            ).throw;
        }
    }

    method parse(@tokens) {
        return self.new(tokens => @tokens).program;
    }

    method program() {
        my $fun = self.function;
        self.chomp(t_eof);

        return Program.new(function => $fun);
    }

    method function() {
        self.chomp(t_int);
        my $name = self.chomp(t_ident);
        self.chomp(t_paren_l);
        self.chomp(t_void);
        self.chomp(t_paren_r);
        self.chomp(t_brace_l);
        my $ret = self.return;
        self.chomp(t_brace_r);

        return Function.new(name => $name, body => $ret);
    }

    method return() {
        self.chomp(t_return);
        my $con = self.constant;
        self.chomp(t_semicolon);

        return Return.new(const => $con);
    }

    method constant() {
        return Constant.new(integer => self.chomp(t_const).Int);
    }
}
