
describe 'spinnaker resource API', ->

  beforeEach module 'spinnaker', (spinnakerProvider) ->
    spinnakerProvider.setTransport spinnakerProvider.httpTransport

  beforeEach inject ($injector) ->
    @spinnaker = $injector.get 'spinnaker'
    @scope = $injector.get '$rootScope'
    @http = $injector.get '$httpBackend'
    
    @http.expect('GET', '/users/1').respond users: [{id: 1, name: 'banana', href: '/users/1', links: {profile: '/users/1/profile', photos: '/users/1/photos', group: '/groups/1', tags: '/users/1/tags'}}]
    @user = @spinnaker '/users/1', single: true
    @scope.$digest()
    @http.flush()

  afterEach ->
    @http.verifyNoOutstandingExpectation()

  it 'should have API instance methods', ->
    expect(typeof @user.save).toBe 'function'
    expect(typeof @user.reload).toBe 'function'
    expect(typeof @user.isClean).toBe 'function'
    expect(typeof @user.dirty).toBe 'function'
    expect(typeof @user.dirties).toBe 'function'

  it 'should track changes', ->
    expect(@user.isClean()).toBeTruthy()
    expect(@user.dirty().length).toBe 0
    expect(@user.dirties().name).toBeUndefined()

    @user.name = 'BANANA'
    expect(@user.isClean()).toBeFalsy()
    expect(@user.dirty().length).toBe 1
    expect(@user.dirties().name).toBe 'BANANA'

    @user.name = 'banana'
    expect(@user.isClean()).toBeTruthy()
    expect(@user.dirty().length).toBe 0
    expect(@user.dirties().name).toBeUndefined()

  it 'should save dirty values with a PATCH request', ->
    @http.expect('PATCH', '/users/1', '[{"op":"replace","path":"/users/0/name","value":"BANANA"}]')
      .respond users: [{id: 1, name: 'BANANA', href: '/users/1', links: {profile: '/users/1/profile', photos: '/users/1/photos', group: '/groups/1', tags: '/users/1/tags'}}]
    @user.name = 'BANANA'
    expect(@user.isClean()).toBeFalsy()
    expect(@user.dirty().length).toBe 1
    expect(@user.dirties().name).toBe 'BANANA'
    @user.save()
    @scope.$digest()
    @http.flush()
    expect(@user.name).toBe 'BANANA'
    expect(@user.isClean()).toBeTruthy()
    expect(@user.dirty().length).toBe 0
    expect(@user.dirties().name).toBeUndefined()

  it 'should populate "belongs to" links', ->
    @http.expect('GET', '/groups/1')
      .respond groups: [{id: 1, name: 'Fruits', href: '/groups/1', links: {users: '/groups/1/users'}}]
    @user.populate 'group', single: true
    @scope.$digest()
    @http.flush()
    expect(@user.group).toBeDefined()
    expect(@user.group.name).toBe 'Fruits'

  it 'should populate "has one" links', ->
    @http.expect('GET', '/users/1/profile')
      .respond profiles: [{id: 1, description: 'Yellow', href: '/profiles/1', links: {user: '/users/1'}}]
    @user.populate 'profile', single: true, type: 'profiles'
    @scope.$digest()
    @http.flush()
    expect(@user.profile).toBeDefined()
    expect(@user.profile.description).toBe 'Yellow'

  it 'should populate "has many" links', ->
    @http.expect('GET', '/users/1/photos')
      .respond photos: [{id: 1, src: 'b.jpg', href: '/photos/1', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', href: '/photos/2', links: {user: '/users/1'}}]
    @user.populate 'photos'
    @scope.$digest()
    @http.flush()
    expect(@user.photos).toBeDefined()
    expect(@user.photos.length).toBe 2
    expect(@user.photos[0].src).toBe 'b.jpg'

  it 'should populate "many to many" links', ->
    @http.expect('GET', '/users/1/tags')
      .respond tags: [{id: 1, name: 'yummy', href: '/tags/1', links: {users: '/tags/1/users'}},{id: 2, name: 'natural', href: '/tags/2', links: {users: '/tags/2/users'}}]
    @user.populate 'tags'
    @scope.$digest()
    @http.flush()
    expect(@user.tags).toBeDefined()
    expect(@user.tags.length).toBe 2
    expect(@user.tags[0].name).toBe 'yummy'

  it 'should return promises for populate calls', ->
    @http.expect('GET', '/groups/1')
      .respond groups: [{id: 1, name: 'Fruits', href: '/groups/1', links: {users: '/groups/1/users'}}]
    @http.expect('GET', '/users/1/profile')
      .respond profiles: [{id: 1, description: 'Yellow', href: '/profiles/1', links: {user: '/users/1'}}]
    @user.populate('group', single: true).then => @user.populate 'profile', single: true, type: 'profiles'
    @scope.$digest()
    @http.flush()
    expect(@user.group).toBeDefined()
    expect(@user.group.name).toBe 'Fruits'
    expect(@user.profile).toBeDefined()
    expect(@user.profile.description).toBe 'Yellow'

  it 'should return a value promise if a link is already populated', ->
    @http.expect('GET', '/groups/1')
      .respond groups: [{id: 1, name: 'Fruits', href: '/groups/1', links: {users: '/groups/1/users'}}]
    @user.populate 'group', single: true
    @scope.$digest()
    @http.flush()
    called = false
    @user.populate('group', single: true).then -> called = true
    @scope.$digest()
    expect(called).toBeTruthy()
