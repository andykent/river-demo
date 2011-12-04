doctype 5
html ->
  head ->
    meta charset: 'utf-8'
    title "River.js Twitter Stream Example"

    script src: 'http://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js'
    script src: '/socket.io/socket.io.js'
    script src: '/CodeMirror/lib/codemirror.js'
    script src: '/CodeMirror/mode/sql/sql.js'

    link rel: 'stylesheet', href: '/CodeMirror/lib/codemirror.css'
    link rel: 'stylesheet', href: '/CodeMirror/mode/sql/sql.css'
    link rel: 'stylesheet', href: '/stylesheets/base.css'
    
    coffeescript ->
      
      class ResultTable
        constructor: (@selector) ->
          @scope = $(@selector)
          @headers = null
        add: (record) ->
          @setHeaders(Object.keys(record)) unless @headers
          rows = ("<td>#{@valueFor(record, col)}</td>" for col in @headers)
          @scope.find('tbody').prepend("<tr class=\"new-row #{@rowIdentifier(record)}\">#{rows.join()}</tr>")
          el = @scope.find('tbody tr').eq(0)
          setTimeout((=> el.removeClass('new-row')), 3000)
          @maybePruneTable()
        remove: (record) ->
          el = @scope.find('tbody').find("tr.#{@rowIdentifier(record)}").eq(-1)
          console.log("MISSED: #{@rowIdentifier(record)}") if el.length is 0
          el.addClass('old-row')
          setTimeout((=> el.remove()), 1000)
        setHeaders: (cols) ->
          @headers = cols
          for col in cols
            @scope.find('thead').append("<th>#{col}</th>")
        rowIdentifier: (record) ->
          if record?._?.uuid?
            record._.uuid
          else
            id = []
            sanitize = (value) -> (value or 'null').toString().replace(/[\s\.,-\/#!$\?%\^&\*;:{}=\-_`~()<>\[\]\+'"]/g, '_')
            keys = Object.keys(record)
            sortedKeys = keys.sort()
            for key in sortedKeys
              id.push(sanitize(key))
              id.push(sanitize(record[key]))
            id.join('-')
        maybePruneTable: ->
          numberOfRows = @scope.find('tbody tr').length
          return if numberOfRows < 2000
          @scope.find('tbody tr').eq(-1).remove()
        valueFor: (record, col) ->
          val = record[col]
          if typeof val is 'object' then '{...}' else val
        
      listenTo = (channel) ->
        socket = io.connect()        
        table = new ResultTable('#results')
        socket.on 'connect', (_) -> socket.emit 'listen', channel
        socket.on 'joined', (msg) -> console.log "*** joined!! -> #{msg}"
        socket.on 'insert', (data) -> table.add(data)
        socket.on 'remove', (data) -> table.remove(data)
      
      queryId = window.location.pathname.split('/')[2]
      
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
        listenTo(queryId)
  body ->
    pre '.query-body', ->
      code query.toString()
    
    table '#results', ->
      thead()
      tbody()
    