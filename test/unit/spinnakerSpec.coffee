
describe 'spinnaker', ->

  beforeEach module 'spinnaker'
  beforeEach inject ($injector) ->
    @spinnakerSocket = $injector.get 'spinnakerSocket'
    @spinnaker = $injector.get 'spinnaker'
    @CreditCard = @spinnaker 'cc', '/CreditCard/:id:verb', id:'@id.key',
      charge:
        method:'post'
        params: verb:'!charge'
      patch: method: 'PATCH'
      conditionalPut:
        method: 'PUT'
        headers: 'If-None-Match': '*'

    @callback = jasmine.createSpy()

  afterEach ->
    @spinnakerSocket.flush()
    @spinnakerSocket.verifyNoOutstandingExpectation()

  it 'should build resource', ->
    expect(typeof @CreditCard).toBe 'function'
    expect(typeof @CreditCard.get).toBe 'function'
    expect(typeof @CreditCard.save).toBe 'function'
    expect(typeof @CreditCard.remove).toBe 'function'
    expect(typeof @CreditCard['delete']).toBe 'function'
    expect(typeof @CreditCard.query).toBe 'function'

  it 'should default to empty parameters', ->
    @spinnakerSocket.expect('GET', 'URL').respond {}
    @spinnaker('name', 'URL').query()


  it 'should ignore slashes of undefinend parameters', ->
    S = @spinnaker 'Path', '/Path/:a/:b/:c'

    @spinnakerSocket.when('GET', '/Path').respond {}
    @spinnakerSocket.when('GET', '/Path/0').respond {}
    @spinnakerSocket.when('GET', '/Path/false').respond {}
    @spinnakerSocket.when('GET', '/Path').respond {}
    @spinnakerSocket.when('GET', '/Path').respond {}
    @spinnakerSocket.when('GET', '/Path').respond {}
    @spinnakerSocket.when('GET', '/Path/1').respond {}
    @spinnakerSocket.when('GET', '/Path/2/3').respond {}
    @spinnakerSocket.when('GET', '/Path/4/5').respond {}
    @spinnakerSocket.when('GET', '/Path/6/7/8').respond {}

    S.get {}
    S.get a: 0
    S.get a: false
    S.get a: null
    S.get a: undefined
    S.get a: ''
    S.get a: 1
    S.get a: 2, b: 3
    S.get a: 4, c: 5
    S.get a: 6, b: 7, c: 8

  it 'should not ignore leading slashes of undefinend parameters that have non-slash trailing sequence', ->
    R = @spinnaker 'Path', '/Path/:a.foo/:b.bar/:c.baz'

    @spinnakerSocket.when('GET', '/Path/.foo/.bar.baz').respond {}
    @spinnakerSocket.when('GET', '/Path/0.foo/.bar.baz').respond {}
    @spinnakerSocket.when('GET', '/Path/false.foo/.bar.baz').respond {}
    @spinnakerSocket.when('GET', '/Path/.foo/.bar.baz').respond {}
    @spinnakerSocket.when('GET', '/Path/.foo/.bar.baz').respond {}
    @spinnakerSocket.when('GET', '/Path/.foo/.bar.baz').respond {}
    @spinnakerSocket.when('GET', '/Path/1.foo/.bar.baz').respond {}
    @spinnakerSocket.when('GET', '/Path/2.foo/3.bar.baz').respond {}
    @spinnakerSocket.when('GET', '/Path/4.foo/.bar/5.baz').respond {}
    @spinnakerSocket.when('GET', '/Path/6.foo/7.bar/8.baz').respond {}

    R.get {}
    R.get a: 0
    R.get a: false
    R.get a: null
    R.get a: undefined
    R.get a: ''
    R.get a: 1
    R.get a: 2, b: 3
    R.get a: 4, c: 5
    R.get a: 6, b: 7, c: 8

  it 'should create resource', ->
    @spinnakerSocket.expect('POST', '/CreditCard', '{"name":"misko"}').respond id: 123, name: 'misko'

    cc = @CreditCard.save name: 'misko', @callback
    expect(cc.name).toEqual 'misko'
    expect(@callback).not.toHaveBeenCalled()

    @spinnakerSocket.flush()
    expect(cc.id).toEqual 123
    expect(cc.name).toEqual 'misko'
    expect(@callback).toHaveBeenCalled()
