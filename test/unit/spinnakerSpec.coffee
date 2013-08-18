
describe 'spinnaker', ->

  beforeEach module 'spinnaker'
  beforeEach inject ($injector) ->
    @spinnakerMock = $injector.get 'spinnakerMock'
    @spinnaker = $injector.get 'spinnaker'

  afterEach ->
    @spinnakerMock.flush()
    @spinnakerMock.verifyNoOutstandingExpectation()

  it 'should build resource', ->
    Widget = @spinnaker 'widget'
    expect(typeof Widget).toBe 'function'
    expect(typeof Widget.get).toBe 'function'
    expect(typeof Widget.create).toBe 'function'
    expect(typeof Widget.save).toBe 'function'
    expect(typeof Widget.destroy).toBe 'function'
    expect(typeof Widget.query).toBe 'function'

  it 'should default to empty parameters', ->
    @spinnakerMock.expect('GET', 'URL').respond {}
    @spinnaker('name', 'URL').query()


  it 'should ignore slashes of undefinend parameters', ->
    S = @spinnaker 'Path', '/Path/:a/:b/:c'

    @spinnakerMock.when('GET', '/Path').respond {}
    @spinnakerMock.when('GET', '/Path/0').respond {}
    @spinnakerMock.when('GET', '/Path/false').respond {}
    @spinnakerMock.when('GET', '/Path').respond {}
    @spinnakerMock.when('GET', '/Path').respond {}
    @spinnakerMock.when('GET', '/Path').respond {}
    @spinnakerMock.when('GET', '/Path/1').respond {}
    @spinnakerMock.when('GET', '/Path/2/3').respond {}
    @spinnakerMock.when('GET', '/Path/4/5').respond {}
    @spinnakerMock.when('GET', '/Path/6/7/8').respond {}

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

  # Nope! =)
  xit 'should not ignore leading slashes of undefinend parameters that have non-slash trailing sequence', ->
    S = @spinnaker 'Path', '/Path/:a.foo/:b.bar/:c.baz'

    @spinnakerMock.when('GET', '/Path/.foo/.bar.baz').respond {}
    @spinnakerMock.when('GET', '/Path/0.foo/.bar.baz').respond {}
    @spinnakerMock.when('GET', '/Path/false.foo/.bar.baz').respond {}
    @spinnakerMock.when('GET', '/Path/.foo/.bar.baz').respond {}
    @spinnakerMock.when('GET', '/Path/.foo/.bar.baz').respond {}
    @spinnakerMock.when('GET', '/Path/.foo/.bar.baz').respond {}
    @spinnakerMock.when('GET', '/Path/1.foo/.bar.baz').respond {}
    @spinnakerMock.when('GET', '/Path/2.foo/3.bar.baz').respond {}
    @spinnakerMock.when('GET', '/Path/4.foo/.bar/5.baz').respond {}
    @spinnakerMock.when('GET', '/Path/6.foo/7.bar/8.baz').respond {}

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

  it 'should create resource', ->
    Widget = @spinnaker 'widget'
    @spinnakerMock.expect('POST', '/widget', name: 'misko').respond id: 123, name: 'misko'

    cb = jasmine.createSpy()
    w = Widget.save name: 'misko', cb
    expect(w.name).toEqual 'misko'
    expect(cb).not.toHaveBeenCalled()

    @spinnakerMock.flush()
    expect(w.id).toEqual 123
    expect(w.name).toEqual 'misko'
    expect(cb).toHaveBeenCalled()


  it 'should handle errors', ->
    Widget = @spinnaker 'widget'
    @spinnakerMock.expect('POST', '/widget', name: 'misko').respond status: 503

    cbSuccess = jasmine.createSpy()
    cbError = jasmine.createSpy()
    w = Widget.save name: 'misko', cbSuccess, cbError
    expect(cbSuccess).not.toHaveBeenCalled()
    expect(cbError).not.toHaveBeenCalled()

    @spinnakerMock.flush()
    expect(cbSuccess).not.toHaveBeenCalled()
    expect(cbError).toHaveBeenCalled()

