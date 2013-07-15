describe 'sails app', ->

  it 'lists all widgets', ->
    browser().navigateTo '/app'
    sleep 1
    expect(repeater('ul li').count()).toBe 0