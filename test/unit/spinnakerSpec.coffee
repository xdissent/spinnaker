
describe 'spinnaker', ->

  beforeEach module 'spinnaker', (spinnakerProvider) ->
    spinnakerProvider.setTransport spinnakerProvider.httpTransport

  beforeEach inject ($injector) ->
    @spinnaker = $injector.get 'spinnaker'
    @scope = $injector.get '$rootScope'
    @http = $injector.get '$httpBackend'

  afterEach ->
    @http.verifyNoOutstandingExpectation()

  it 'should GET a resource collection', ->
    @http.expect('GET', '/users').respond users: [{id: 1, name: 'banana'}]
    users = @spinnaker '/users'
    @scope.$digest()
    @http.flush()
    expect(users.length).toBe 1

  it 'should GET a single resource', ->
    @http.expect('GET', '/users/1').respond users: [{id: 1, name: 'banana'}]
    user = @spinnaker '/users/1', single: true
    @scope.$digest()
    @http.flush()
    expect(user.name).toBe 'banana'

  it 'should POST a resource collection', ->
    @http.expect('POST', '/users', '{"users":[{"name":"banana"},{"name":"orange"}]}')
      .respond users: [{id: 1, name: 'banana'},{id: 2, name: 'orange'}]
    users = @spinnaker '/users', data: [{name: 'banana'},{name: 'orange'}]
    @scope.$digest()
    @http.flush()
    expect(users.length).toBe 2
    expect(users[0].name).toBe 'banana'
    expect(users[1].name).toBe 'orange'

  it 'should POST a single resource', ->
    @http.expect('POST', '/users', '{"users":[{"name":"banana"}]}')
      .respond users: [{id: 1, name: 'banana'}]
    user = @spinnaker '/users', data: name: 'banana'
    @scope.$digest()
    @http.flush()
    expect(user.name).toBe 'banana'

  it 'should PATCH a single resource', ->
    @http.expect('PATCH', '/users/1', '[{"op":"replace","path":"/users/0/name","value":"BANANA"}]')
      .respond users: [{id: 1, name: 'BANANA'}]
    user = @spinnaker '/users/1', method: 'patch', data: name: 'BANANA'
    @scope.$digest()
    @http.flush()
    expect(user.name).toBe 'BANANA'

  it 'should PATCH a resource collection', ->
    @http.expect('PATCH', '/users', '[{"op":"replace","path":"/users/0/name","value":"BANANA"},{"op":"replace","path":"/users/1/name","value":"ORANGE"}]')
      .respond users: [{id: 1, name: 'BANANA'},{id: 2, name: 'ORANGE'}]
    users = @spinnaker '/users', method: 'patch', data: [{name: 'BANANA'},{name: 'ORANGE'}]
    @scope.$digest()
    @http.flush()
    expect(users.length).toBe 2
    expect(users[0].name).toBe 'BANANA'
    expect(users[1].name).toBe 'ORANGE'

  it 'should DELETE a single resource', ->
    @http.expect('DELETE', '/users/1').respond null
    deleted = false
    @spinnaker('/users/1', method: 'delete').then -> deleted = true
    @scope.$digest()
    @http.flush()
    expect(deleted).toBeTruthy()

  it 'should GET a single resource and populate a link as a string', ->
    @http.expect('GET', '/users/1').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    user = @spinnaker '/users/1', single: true, populate: 'photos'
    @scope.$digest()
    @http.flush()
    expect(user.name).toBe 'banana'
    expect(user.photos.length).toBe 2
    expect(user.photos[0].src).toBe 'b.jpg'

  it 'should GET a resource collection and populate a link as a string', ->
    @http.expect('GET', '/users').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    users = @spinnaker '/users', populate: 'photos'
    @scope.$digest()
    @http.flush()
    expect(users.length).toBe 1
    expect(users[0].photos.length).toBe 2
    expect(users[0].photos[0].src).toBe 'b.jpg'

  it 'should GET a single resource and populate links as an array of strings', ->
    @http.expect('GET', '/users/1').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos', groups: '/users/1/groups'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    @http.expect('GET', '/users/1/groups').respond groups: [{id: 1, name: 'Fruits', links: {users: '/groups/1/users'}}]
    user = @spinnaker '/users/1', single: true, populate: ['photos', 'groups']
    @scope.$digest()
    @http.flush()
    expect(user.name).toBe 'banana'
    expect(user.photos.length).toBe 2
    expect(user.photos[0].src).toBe 'b.jpg'
    expect(user.groups.length).toBe 1
    expect(user.groups[0].name).toBe 'Fruits'

  it 'should GET a resource collection and populate links as an array of strings', ->
    @http.expect('GET', '/users').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos', groups: '/users/1/groups'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    @http.expect('GET', '/users/1/groups').respond groups: [{id: 1, name: 'Fruits', links: {users: '/groups/1/users'}}]
    users = @spinnaker '/users', populate: ['photos', 'groups']
    @scope.$digest()
    @http.flush()
    expect(users.length).toBe 1
    expect(users[0].name).toBe 'banana'
    expect(users[0].photos.length).toBe 2
    expect(users[0].photos[0].src).toBe 'b.jpg'
    expect(users[0].groups.length).toBe 1
    expect(users[0].groups[0].name).toBe 'Fruits'

  it 'should GET a single resource and populate a link as an object', ->
    @http.expect('GET', '/users/1').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    user = @spinnaker '/users/1', single: true, populate: link: 'photos'
    @scope.$digest()
    @http.flush()
    expect(user.name).toBe 'banana'
    expect(user.photos.length).toBe 2
    expect(user.photos[0].src).toBe 'b.jpg'

  it 'should GET a resource collection and populate a link as an object', ->
    @http.expect('GET', '/users').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    users = @spinnaker '/users', populate: link: 'photos'
    @scope.$digest()
    @http.flush()
    expect(users.length).toBe 1
    expect(users[0].photos.length).toBe 2
    expect(users[0].photos[0].src).toBe 'b.jpg'

  it 'should GET a single resource and populate links as an array of objects', ->
    @http.expect('GET', '/users/1').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos', groups: '/users/1/groups'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    @http.expect('GET', '/users/1/groups').respond groups: [{id: 1, name: 'Fruits', links: {users: '/groups/1/users'}}]
    user = @spinnaker '/users/1', single: true, populate: [{link: 'photos'}, {link: 'groups'}]
    @scope.$digest()
    @http.flush()
    expect(user.name).toBe 'banana'
    expect(user.photos.length).toBe 2
    expect(user.photos[0].src).toBe 'b.jpg'
    expect(user.groups.length).toBe 1
    expect(user.groups[0].name).toBe 'Fruits'

  it 'should GET a resource collection and populate links as an array of objects', ->
    @http.expect('GET', '/users').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos', groups: '/users/1/groups'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    @http.expect('GET', '/users/1/groups').respond groups: [{id: 1, name: 'Fruits', links: {users: '/groups/1/users'}}]
    users = @spinnaker '/users', populate: [{link: 'photos'}, {link: 'groups'}]
    @scope.$digest()
    @http.flush()
    expect(users.length).toBe 1
    expect(users[0].name).toBe 'banana'
    expect(users[0].photos.length).toBe 2
    expect(users[0].photos[0].src).toBe 'b.jpg'
    expect(users[0].groups.length).toBe 1
    expect(users[0].groups[0].name).toBe 'Fruits'

  it 'should GET a single resource and populate links as a mixed array', ->
    @http.expect('GET', '/users/1').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos', groups: '/users/1/groups'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    @http.expect('GET', '/users/1/groups').respond groups: [{id: 1, name: 'Fruits', links: {users: '/groups/1/users'}}]
    user = @spinnaker '/users/1', single: true, populate: ['photos', link: 'groups']
    @scope.$digest()
    @http.flush()
    expect(user.name).toBe 'banana'
    expect(user.photos.length).toBe 2
    expect(user.photos[0].src).toBe 'b.jpg'
    expect(user.groups.length).toBe 1
    expect(user.groups[0].name).toBe 'Fruits'

  it 'should GET a resource collection and populate links as a mixed array', ->
    @http.expect('GET', '/users').respond users: [{id: 1, name: 'banana', links: {photos: '/users/1/photos', groups: '/users/1/groups'}}]
    @http.expect('GET', '/users/1/photos').respond photos: [{id: 1, src: 'b.jpg', links: {user: '/users/1'}},{id: 2, src: 'y.jpg', links: {user: '/users/1'}}]
    @http.expect('GET', '/users/1/groups').respond groups: [{id: 1, name: 'Fruits', links: {users: '/groups/1/users'}}]
    users = @spinnaker '/users', populate: ['photos', link: 'groups']
    @scope.$digest()
    @http.flush()
    expect(users.length).toBe 1
    expect(users[0].name).toBe 'banana'
    expect(users[0].photos.length).toBe 2
    expect(users[0].photos[0].src).toBe 'b.jpg'
    expect(users[0].groups.length).toBe 1
    expect(users[0].groups[0].name).toBe 'Fruits'

  it 'should cache compound documents', ->
    @http.expect('GET', '/users/1').respond users: [{id: 1, name: 'banana'}], photos: [{id: 1, src: 'b.jpg', href: '/photos/1'},{id: 2, src: 'y.jpg', href: '/photos/2'}]
    photo = null
    user = @spinnaker '/users/1', single: true
    user.$promise.then =>
      photo = @spinnaker '/photos/1', single: true
    @scope.$digest()
    @http.flush()
    expect(user.name).toBe 'banana'
    expect(photo.src).toBe 'b.jpg'

