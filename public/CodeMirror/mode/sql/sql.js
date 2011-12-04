CodeMirror.defineMode("sql", function(config, parserConfig) {
    var indentUnit  = config.indentUnit,
        keywords    = parserConfig.keywords,
        functions   = parserConfig.functions,
        types       = parserConfig.types,
        operators   = parserConfig.operators,
        multiLineStrings = parserConfig.multiLineStrings;
    var isOperatorChar   = /[+\-*&%=<>!?:\/|]/;

    function chain(stream, state, f) {
        state.tokenize = f;
        return f(stream, state);
    }

    var type;
    function ret(tp, style) {
        type = tp;
        return style;
    }
    
    function tokenBase(stream, state) {
        var ch = stream.next();
        // start of string?
        if (ch == '"' || ch == "'" || ch == "`") {
            return chain(stream, state, tokenString(ch));
        }
        // is it one of the special signs []{}().? 
        else if (/[\[\]{}\(\)\.]/.test(ch)) {
            return ret(ch);
        }
        // Seperator?
        else if(ch == "," || ch == ";") {
            return "separator";
        }
        // start of a number value?
        else if (/\d/.test(ch)) {
            stream.eatWhile(/[\w\.]/)
                return ret("number", "number");
        }
        // multi line comment or simple operator?
        else if (ch == "/") {
            if (stream.eat("*")) {
                return chain(stream, state, tokenComment);
            }
            else {
                stream.eatWhile(isOperatorChar);
                return ret("operator", "operator");
            }
        }
        // single line comment or simple operator?
        else if (ch == "-") {
            if (stream.eat("-")) {
                stream.skipToEnd();
                return ret("comment", "comment");
            } else {
                stream.eatWhile(isOperatorChar);
                return ret("operator", "operator");
            }
        }
        // another single line comment
        else if (ch == '#') {
            stream.skipToEnd();
            return ret("comment", "comment");
        }
        // sql variable?
        else if (ch == "@" || ch == "$") {
            stream.eatWhile(/[\w\d\$_]/);
            return ret("word", "var");
        }
        // is it a operator?
        else if (isOperatorChar.test(ch)) {
            stream.eatWhile(isOperatorChar);
            return ret("operator", "operator");
        }
        // a punctuation?
        else if (/[()]/.test(ch)) {
            return "punctuation";
        } else {
            // get the whole word
            stream.eatWhile(/[\w\$_]/);
            // is it one of the listed keywords?
            if (keywords && keywords.propertyIsEnumerable(stream.current().toLowerCase())) return ret("keyword", "keyword");
            // is it one of the listed functions?
            if (functions && functions.propertyIsEnumerable(stream.current().toLowerCase())) return ret("keyword", "function");
            // is it one of the listed types?
            if (types && types.propertyIsEnumerable(stream.current().toLowerCase())) return ret("keyword", "type");
            // is it one of the listed sqlplus keywords?
            if (operators && operators.propertyIsEnumerable(stream.current().toLowerCase())) return ret("keyword", "operators");
            // default: just a "word"
            return ret("word", "word");
        }

    }

    function tokenString(quote) {
        return function(stream, state) {
            var escaped = false, next, end = false;
            while ((next = stream.next()) != null) {
                if (next == quote && !escaped) {end = true; break;}
                escaped = !escaped && next == "\\";
            }
            if (end || !(escaped || multiLineStrings))
                state.tokenize = tokenBase;
            var style = quote == "`" ? "quoted-word" : "literal";
            return ret("string", style);
        };
    }

    function tokenComment(stream, state) {
        var maybeEnd = false, ch;
        while (ch = stream.next()) {
            if (ch == "/" && maybeEnd) {
                state.tokenize = tokenBase;
                break;
            }
            maybeEnd = (ch == "*");
        }
        return ret("comment", "comment");
    }

    // Interface

    return {
        startState: function(basecolumn) {
            return {
                tokenize: tokenBase,
                indented: 0,
                startOfLine: true
            };
        },

        token: function(stream, state) {
            if (stream.eatSpace()) return null;
            var style = state.tokenize(stream, state);
            return style;
        },
        electricChars: ")"
    };
});

(function() {
    function keywords(str) {
        var obj = {}, words = str.split(" ");
        for (var i = 0; i < words.length; ++i) obj[words[i]] = true;
        return obj;
    }
    var cKeywords = 
        "alter grant revoke primary key table start top " +
        "transaction select update insert delete create describe " +
        "from into values where join inner left natural and " +
        "or in not xor like using on order group by " +
        "asc desc limit offset union all as distinct set " +
        "commit rollback replace view database separator if " +
        "exists null truncate status show lock unique having " +
        "drop procedure begin end delimiter call else leave " + 
        "declare temporary then";


    var cFunctions = 
        "abs acos asin bin ceil conv cos exp floor hex ln log log10 log2 " +
        "negative pmod positive pow rand round sin sqrt unhex size cast " +
        "datediff date_add date_sub day from_unixtime hour minute month second " +
        "to_date unix_timestamp weekofyear year ascii concat context_ngrams " +
        "find_in_set get_json_object lcase length lower lpad ltrim ngrams " +
        "parse_url regexp_extract regexp_replace repeat reverse rpad rtrim " +
        "space sentences split substr trim ucase upper avg count max min sum " +
        "var_pop var_samp stddev_pop stddev_samp covar_pop covar_samp corr " +
        "percentile percentile_approx histogram_numeric collect_set explode";

    var cTypes = 
        "bigint binary bit blob bool char character date " +
        "datetime dec decimal double enum float float4 float8 " +
        "int int1 int2 int3 int4 int8 integer long longblob " +
        "longtext mediumblob mediumint mediumtext middleint nchar " +
        "numeric real set smallint text time timestamp tinyblob " +
        "tinyint tinytext varbinary varchar year";

    var cOperators = 
        ":= < <= == <> > >= like rlike in xor between is not regexp + - * / % & | ^ ~";

    var parserConfig = {
      name:      "sql",
      keywords:  keywords(cKeywords),
      functions: keywords(cFunctions),
      types:     keywords(cTypes),
      operators: keywords(cOperators)
    };
    
    CodeMirror.defineMIME("text/x-sql", parserConfig);
    window.parserConfig = parserConfig; // exported for autocomplete
}());