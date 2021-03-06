# This is the simplest example of using `ccorcos:any-db`.
# The publication is a list of documents where the value is a number.
# Every time the query function is called, it reorders the list before returning it.
# The client simply shows the list.

if Meteor.isServer
  createDoc = (i) ->
    {_id:i, value:i}
  docs = null
  
  DB.publish 
    name: 'numbers'
    ms: 2000, 
    query: (n) ->
      if docs
        i = Random.choice([0...docs.length])
        j = Random.choice([0...docs.length-1])
        doc = docs[i]
        docs.splice(i,1)
        docs.splice(j,0,doc)
        return R.clone(docs)
      else
        docs = R.map(createDoc, [0...n])
        return R.clone(docs)

if Meteor.isClient
  @sub = DB.createSubscription('numbers', 20)

  Template.main.onRendered ->
    @autorun -> sub.start -> console.log "subscription ready"

  Template.main.helpers
    numbers: () -> sub.fetch()
