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
      
      $.fn.codeHighlight = ->
        $.each this, ->
          preview = $(this)
          value = preview.find('code').text()
          CodeMirror ((cm) -> preview.replaceWith(cm)),
            mode: "text/x-sql", 
            lineNumbers: true, 
            value: value,
            readOnly: true

      $ -> 
        $('pre.query-body').codeHighlight()
        setupEditor()
        
  body ->
    h1 "River.js Twitter Stream Demo"
    p "For more info about river, what it is and how it works, please see <a href=\"https://gihtub.com/andykent/river\">the River Github repo</a>."
    form '#query-form', action: '/query', method: 'post', ->
      textarea '#query-input', name: 'query'
      button type:'submit', 'Launch Query'
    
    h2 "Some Simple Examples"
    ul ->
      li ->
        h3 "Tweets mentioning people and containing a URL"
        pre '.query-body', ->
          code "SELECT user.screen_name AS username, text AS tweet FROM tweets WHERE text LIKE '% @%' AND text LIKE '% http%'"
      li ->
        h3 "Tweets counted by source over the last 30 seconds"
        pre '.query-body', ->
          code "SELECT source, COUNT(1) AS seen FROM tweets.win:time(30) GROUP BY source"
        