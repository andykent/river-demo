doctype 5
html ->
  head ->
    meta charset: 'utf-8'
    title "River.js Twitter Stream Example"
    
    script src: 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js'
    script src: '/CodeMirror/lib/codemirror.js'
    script src: '/CodeMirror/mode/sql/sql.js'

    link rel: 'stylesheet', href: '/CodeMirror/lib/codemirror.css'
    link rel: 'stylesheet', href: '/CodeMirror/mode/sql/sql.css'
    link rel: 'stylesheet', href: '/stylesheets/base.css'
    
    coffeescript ->
      setupEditor = ->
        if $('#query-input').get(0)
          editor = CodeMirror.fromTextArea $('#query-input').get(0), 
            mode:"text/x-sql",
            lineNumbers:true,
            matchBrackets:true,
            indentUnit:1

      $ -> setupEditor()
        
  body ->
    
    form '#query-form', action: '/query', method: 'post', ->
      textarea '#query-input', name: 'query'
      button type:'submit', 'Launch Query'