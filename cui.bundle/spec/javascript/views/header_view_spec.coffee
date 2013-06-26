
describe 'HeaderRenderer', ->
  HeaderRenderer = App.Views.HeaderRenderer
  beforeEach ->
    @model = 
      title: 'title'
    @view = new HeaderRenderer
      model: @model

  it 'should be initialized', ->
    expect(@view).toEqual jasmine.any(HeaderRenderer)

  it 'should render page title', ->
    @model.title = 'page title1'
    expect(@view.render().el).toContainHtml '<h1>page title1</h1>'

  it 'should render left icon', ->
    @model.left_icon = 'arrow-l'
    @model.left_href = ''
    expect(@view.render().el).toContainHtml '''
      <a href='#' data-role="button" data-icon="arrow-l"  data-iconpos="notext"></a>
    '''

  it 'should render right icon', ->
    @model.right_icon = 'gear'
    @model.right_href = 'config'
    expect(@view.render().el).toContainHtml '''
      <a href='#config' data-role="button" data-icon="gear"  data-iconpos="notext" class="ui-btn-right"></a>
    '''

