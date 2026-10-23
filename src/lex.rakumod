unit module lex;

enum TokenType is export <
    t_ident
    t_const
    t_int
    t_void
    t_return
    t_paren_l
    t_paren_r
    t_brace_l
    t_brace_r
    t_semicolon
    t_tilde
    t_minus
    t_decrement
    t_eof
>;

class Token {
    has TokenType $.type is required;
    has Str $.lexeme;
}

class Lexer::UnrecognizedCharacter is Exception {
    has Str $.character;

    method message() {
        return "Could not find a matching token for a string starting with $.character"
    }
}

sub substers(Str $str) {
    gather {
        loop (my $i = $str.chars; $i > 0; $i--) {
            take $str.substr(0, $i);
        }
    }
}

class Lexer is export {
    my %keywords = 'int' => t_int,
                   'void' => t_void,
                   'return' => t_return; 

    my %singles = ';' => t_semicolon,
                  '(' => t_paren_l,
                  ')' => t_paren_r,
                  '{' => t_brace_l,
                  '}' => t_brace_r,
                  '-' => t_minus,
                  '~' => t_tilde,
                  '--' => t_decrement;

    my @boundary = Array.new(%singles.keys.grep({.chars == 1}).map({"\\" ~ $_})).append("\\s");

    has Str $.text is required is rw;

    method push(Str $lexeme, TokenType $type?) {
        $.text .= substr($lexeme.chars);
        with $type {
            take Token.new(type => $type, lexeme => "$lexeme");
        }
    }

    method empty() {
        return $.text.chars == 0;
    }

    method parse(Str $text) {
        my $this = self.new(text => $text);

        gather {
            while (!$this.empty) {
                given $this.text {
                    when rx/^\s+/ {
                        $this.push("$/");
                    }
                    when rx/ ^<[a..zA..Z_]>+<?@boundary> / {
                        if %keywords«"$/"»:exists {
                            $this.push("$/", %keywords«"$/"»);
                        } else {
                            $this.push("$/", t_ident);
                        }
                    }
                    when rx/ ^<[0..9]>+<?@boundary> / {
                        $this.push("$/", t_const);
                    }
                    default {
                        for substers($_.substr(0, 2)) -> $subs {
                            if %singles«"$subs"»:exists {
                                succeed $this.push($subs, %singles«"$subs"»);
                            }
                        }
                        Lexer::UnrecognizedCharacter.new(character => $_).throw;
                    }
                }
            }
            take Token.new(type => t_eof, lexeme => "␄");
        }
    }
}
