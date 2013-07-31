describe 'sails app', ->

  it 'creates widgets', ->
    browser().navigateTo '/'

    create = element '#create-widget'
    repeat = repeater 'ul li'

    sleep 2
    expect(repeat.count()).toBe 0

    create.click()
    sleep 2
    expect(repeat.count()).toBe 1

    create.click()
    sleep 2
    expect(repeat.count()).toBe 2

  it 'updates widgets', ->
    browser().navigateTo '/'

    repeat = repeater 'ul li'
    widget = element 'ul li:first-child pre'
    update = element 'ul li:first-child .update-widget'
    orig = null
    updated = null

    sleep 2

    widget.query (el, done) ->
      orig = (new Date JSON.parse(el.text()).updatedAt).getTime()
      done()

    sleep 2

    update.click()

    sleep 2

    widget.query (el, done) ->
      updated = (new Date JSON.parse(el.text()).updatedAt).getTime()
      expect(value: updated).toBeGreaterThan orig
      done()

  it 'destroys widgets', ->
    browser().navigateTo '/'

    repeat = repeater 'ul li'
    destroys = element '.destroy-widget'

    sleep 2

    expect(repeat.count()).toBe 2

    destroys.query (el, done) ->
      el.click()
      done()

    sleep 2

    expect(repeat.count()).toBe 0

  xit 'creates widgets over HTTP', ->
    browser().navigateTo '/'

    create = element '#create-widget-http'
    repeat = repeater 'ul li'

    sleep 2
    expect(repeat.count()).toBe 0

    create.click()
    sleep 2
    expect(repeat.count()).toBe 1

    create.click()
    sleep 2
    expect(repeat.count()).toBe 2

  xit 'updates widgets over HTTP', ->
    browser().navigateTo '/'

    repeat = repeater 'ul li'
    widget = element 'ul li:first-child pre'
    update = element 'ul li:first-child .update-widget-http'
    orig = null
    updated = null

    sleep 2

    widget.query (el, done) ->
      orig = (new Date JSON.parse(el.text()).updatedAt).getTime()
      done()

    sleep 2

    update.click()

    sleep 2

    widget.query (el, done) ->
      updated = (new Date JSON.parse(el.text()).updatedAt).getTime()
      expect(value: updated).toBeGreaterThan orig
      done()

  xit 'destroys widgets over HTTP', ->
    browser().navigateTo '/'

    repeat = repeater 'ul li'
    destroys = element '.destroy-widget-http'

    sleep 2

    expect(repeat.count()).toBe 2

    destroys.query (el, done) ->
      el.click()
      done()

    sleep 2

    expect(repeat.count()).toBe 0