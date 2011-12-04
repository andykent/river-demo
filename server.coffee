fs = require('fs')
express = require('express')
CTX = require('river').createContext()
app = express.createServer()
io = require('socket.io').listen(app)

boot = (app) ->
  startTwitterStream()
  app.listen(3000)
  
startTwitterStream = ->
  Twitter = require('ntwitter')
  twit = new Twitter(JSON.parse(fs.readFileSync(__dirname + '/credentials.json')))
  twit.stream 'statuses/sample', (stream) ->
    stream.on 'data', (tweet) -> CTX.push('tweets', tweet)

makeQuery = (q) ->
  query = CTX.addQuery(q)
  query.on 'insert', (newValues) -> io.sockets.in(query.id).emit 'insert', newValues
  query.on 'remove', (oldValues) -> io.sockets.in(query.id).emit 'remove', oldValues
  query
  
getQuery = (id) -> CTX.get(id)


app.configure ->
  app.use express.methodOverride()
  app.use express.bodyParser()
  app.use express.static(__dirname + '/public')
  app.use express.errorHandler(dumpExceptions: true, showStack: true)
  app.set 'view engine', 'coffee'
  app.register '.coffee', require('coffeekup').adapters.express
  app.use app.router
  
app.get '/', (req, res) ->
  res.render 'index', layout: false

app.post '/query', (req, res) ->
  query = makeQuery(req.body.query)
  res.redirect("/query/#{query.id}")

app.get '/query/:queryId', (req, res) ->
  res.render 'query', layout: false, locals: {query: getQuery(req.params.queryId)}

io.sockets.on 'connection', (socket) ->
  console.log "*** connection"
  socket.on 'listen', (queryId) ->
    console.log "*** listen: #{queryId}"
    socket.set 'query', queryId, () ->
      console.log "query #{queryId} saved!"
    socket.join queryId

boot(app)
