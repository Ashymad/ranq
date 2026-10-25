unit module tok;

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

class Token is export {
    has TokenType $.type is required;
    has Str $.lexeme;
}
